#!/usr/bin/env python3
"""
Hackathon provisioner — thin API layer in front of Gitea.
Handles account creation, team management, and access control.

The admin token stays on the server. Clients never see it.
Enforces @bubble.io email domain server-side.
"""

import base64
import json
import os
import secrets
import threading
import time
import traceback
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlencode
from urllib.request import Request, urlopen
from urllib.error import HTTPError

GITEA = os.environ["GITEA_INTERNAL_URL"]       # http://gitea:3000 (Docker internal)
GITEA_EXT = os.environ["GITEA_EXTERNAL_URL"]    # http://<public-ip>:3000
TOKEN = os.environ["ADMIN_TOKEN"]
ORG = os.environ.get("GITEA_ORG", "hackathon")
TEMPLATE = os.environ.get("TEMPLATE_REPO", "_template")
DOMAIN = os.environ.get("ALLOWED_DOMAIN", "bubble.io")
SLACK_TOKEN = os.environ.get("SLACK_BOT_TOKEN", "")

# In-memory verification code store: email -> (code, expires_at)
CODES = {}
CODES_LOCK = threading.Lock()
CODE_TTL = 600  # 10 minutes


def store_code(email: str, code: str) -> None:
    now = time.time()
    with CODES_LOCK:
        CODES[email] = (code, now + CODE_TTL)
        # Opportunistic GC of expired codes
        for e in list(CODES.keys()):
            if CODES[e][1] < now:
                del CODES[e]


def verify_code(email: str, code: str) -> bool:
    with CODES_LOCK:
        entry = CODES.get(email)
        if not entry:
            return False
        stored, expires = entry
        if time.time() > expires:
            del CODES[email]
            return False
        if stored != code:
            return False
        # Single-use
        del CODES[email]
        return True


def slack_api(method: str, **params) -> dict:
    """Call a Slack Web API method."""
    if not SLACK_TOKEN:
        return {"ok": False, "error": "slack_not_configured"}
    url = f"https://slack.com/api/{method}"
    body = urlencode({k: v for k, v in params.items() if v is not None}).encode()
    req = Request(url, data=body, method="POST", headers={
        "Authorization": f"Bearer {SLACK_TOKEN}",
        "Content-Type": "application/x-www-form-urlencoded",
    })
    try:
        with urlopen(req, timeout=10) as r:
            return json.loads(r.read())
    except Exception as e:
        return {"ok": False, "error": f"slack_request_failed: {e}"}


def send_verification_dm(email: str, code: str) -> tuple:
    """Send a verification DM via Slack. Returns (success, error_msg)."""
    lookup = slack_api("users.lookupByEmail", email=email)
    if not lookup.get("ok"):
        err = lookup.get("error", "unknown")
        if err == "users_not_found":
            return False, "That email isn't in the Bubble Slack workspace"
        return False, f"Slack lookup failed: {err}"

    user_id = lookup["user"]["id"]

    # Open a DM channel
    im = slack_api("conversations.open", users=user_id)
    if not im.get("ok"):
        return False, f"Could not open DM: {im.get('error', 'unknown')}"

    channel = im["channel"]["id"]

    text = (
        f":lock: Your Bubble Hackathon verification code is *{code}*\n"
        f"Paste it into the terminal prompt. It expires in 10 minutes."
    )
    post = slack_api("chat.postMessage", channel=channel, text=text)
    if not post.get("ok"):
        return False, f"Could not send DM: {post.get('error', 'unknown')}"

    return True, ""


def api(method, path, data=None):
    url = f"{GITEA}/api/v1{path}"
    body = json.dumps(data).encode() if data else None
    req = Request(url, data=body, method=method, headers={
        "Authorization": f"token {TOKEN}",
        "Content-Type": "application/json",
    })
    try:
        with urlopen(req) as r:
            return json.loads(r.read()) if r.status != 204 else {}
    except HTTPError as e:
        try:
            return json.loads(e.read())
        except Exception:
            return {"error": str(e)}
    except Exception as e:
        return {"error": str(e)}


def user_api(method, path, username, password, data=None):
    """Call Gitea API with user basic auth (not admin token)."""
    url = f"{GITEA}/api/v1{path}"
    body = json.dumps(data).encode() if data else None
    cred = base64.b64encode(f"{username}:{password}".encode()).decode()
    req = Request(url, data=body, method=method, headers={
        "Authorization": f"Basic {cred}",
        "Content-Type": "application/json",
    })
    try:
        with urlopen(req) as r:
            return json.loads(r.read()) if r.status != 204 else {}
    except HTTPError:
        return {}
    except Exception:
        return {}


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass

    def send_json(self, code, obj):
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(obj).encode())

    def body(self):
        n = int(self.headers.get("Content-Length", 0))
        return json.loads(self.rfile.read(n)) if n else {}

    # --- Routes ---

    def _safe(self, fn):
        """Run a handler, converting any uncaught exception into a JSON 500.
        Without this, an exception drops the connection and the client sees
        an empty response body (which looks like a generic 'parse error')."""
        try:
            fn()
        except Exception as e:
            traceback.print_exc()
            try:
                self.send_json(500, {"error": f"internal error: {type(e).__name__}: {e}"})
            except Exception:
                pass

    def do_GET(self):
        if self.path == "/health":
            self._safe(lambda: self.send_json(200, {"ok": True}))
        elif self.path == "/teams":
            self._safe(self.get_teams)
        else:
            self._safe(lambda: self.send_json(404, {"error": "not found"}))

    def do_POST(self):
        if self.path == "/request-code":
            self._safe(self.request_code)
        elif self.path == "/provision":
            self._safe(self.provision)
        elif self.path == "/create-team":
            self._safe(self.create_team)
        elif self.path == "/join-team":
            self._safe(self.join_team)
        else:
            self._safe(lambda: self.send_json(404, {"error": "not found"}))

    # --- Handlers ---

    def request_code(self):
        """Send a 6-digit verification code via Slack DM."""
        d = self.body()
        email = d.get("email", "").strip().lower()

        if not email.endswith(f"@{DOMAIN}"):
            self.send_json(403, {"error": f"Only @{DOMAIN} emails allowed"})
            return

        if not SLACK_TOKEN:
            self.send_json(500, {"error": "Slack verification not configured on this server"})
            return

        code = f"{secrets.randbelow(900000) + 100000}"  # 6-digit, 100000-999999

        ok, err = send_verification_dm(email, code)
        if not ok:
            self.send_json(403, {"error": err})
            return

        store_code(email, code)
        self.send_json(200, {"status": "Code sent via Slack DM"})

    def provision(self):
        """Create account for a @bubble.io user, return git credentials.

        Requires a valid verification code obtained via /request-code.
        """
        d = self.body()
        email = d.get("email", "").strip().lower()
        name = d.get("name", "").strip()
        code = d.get("code", "").strip()

        if not email.endswith(f"@{DOMAIN}"):
            self.send_json(403, {"error": f"Only @{DOMAIN} emails allowed"})
            return

        # Verification is REQUIRED — this proves the user owns the email.
        if not verify_code(email, code):
            self.send_json(403, {"error": "Invalid or expired verification code"})
            return

        username = email.split("@")[0].replace(".", "-").replace("+", "-").lower()
        password = secrets.token_hex(16)

        # Create or update user
        existing = api("GET", f"/users/{username}")
        if "login" in existing:
            # User exists — reset password so we can mint a new token.
            # Gitea's PATCH requires source_id and login_name.
            patch_result = api("PATCH", f"/admin/users/{username}", {
                "source_id": 0,
                "login_name": username,
                "password": password,
                "must_change_password": False,
            })
            if "error" in patch_result and "login" not in patch_result:
                self.send_json(500, {"error": f"password reset failed: {patch_result.get('error', 'unknown')}"})
                return
        else:
            result = api("POST", "/admin/users", {
                "username": username,
                "email": email,
                "full_name": name,
                "password": password,
                "must_change_password": False,
                "visibility": "limited",
            })
            if "error" in result and "login" not in result:
                self.send_json(500, {"error": f"account creation failed: {result.get('error', 'unknown')}"})
                return

        # Add to org
        api("PUT", f"/orgs/{ORG}/members/{username}")

        # Rotate personal access token
        user_api("DELETE", f"/users/{username}/tokens/hackathon-cli",
                 username, password)
        tok = user_api("POST", f"/users/{username}/tokens",
                       username, password,
                       {"name": "hackathon-cli", "scopes": ["all"]})
        user_token = tok.get("sha1", "")

        if not user_token:
            self.send_json(500, {"error": "token creation failed"})
            return

        self.send_json(200, {
            "username": username,
            "token": user_token,
            "git_url": GITEA_EXT,
        })

    def create_team(self):
        """Create a repo from template + a Gitea team for access control."""
        d = self.body()
        team_name = d.get("team", "").strip()
        username = d.get("username", "").strip()

        if not team_name or not username:
            self.send_json(400, {"error": "team and username required"})
            return

        # Check if exists
        existing = api("GET", f"/repos/{ORG}/{team_name}")
        if "name" in existing:
            self.send_json(409, {"error": "team already exists"})
            return

        # Generate from template. git_content=true is REQUIRED to actually
        # copy the template's files into the new repo.
        gen_result = api("POST", f"/repos/{ORG}/{TEMPLATE}/generate", {
            "owner": ORG,
            "name": team_name,
            "private": True,
            "description": d.get("description", f"Hackathon: {team_name}"),
            "default_branch": "main",
            "git_content": True,
        })
        if "name" not in gen_result:
            self.send_json(500, {"error": f"repo creation failed: {gen_result.get('message', gen_result.get('error', 'unknown'))}"})
            return

        # Create Gitea team for per-repo access
        team = api("POST", f"/orgs/{ORG}/teams", {
            "name": f"team-{team_name}",
            "permission": "write",
            "units": ["repo.code", "repo.issues"],
            "includes_all_repositories": False,
        })
        tid = team.get("id")
        if tid:
            api("PUT", f"/teams/{tid}/repos/{ORG}/{team_name}")
            api("PUT", f"/teams/{tid}/members/{username}")

        self.send_json(200, {"team": team_name})

    def join_team(self):
        """Add a user to an existing team's access group."""
        d = self.body()
        team_name = d.get("team", "").strip()
        username = d.get("username", "").strip()

        if not team_name or not username:
            self.send_json(400, {"error": "team and username required"})
            return

        # Find the Gitea team
        teams = api("GET", f"/orgs/{ORG}/teams")
        tid = None
        if isinstance(teams, list):
            for t in teams:
                if t.get("name") == f"team-{team_name}":
                    tid = t["id"]
                    break
        if tid:
            api("PUT", f"/teams/{tid}/members/{username}")

        self.send_json(200, {"team": team_name, "username": username})

    def get_teams(self):
        """List hackathon teams (excludes internal repos)."""
        repos = api("GET", f"/orgs/{ORG}/repos?limit=100")
        names = sorted(r["name"] for r in repos if not r["name"].startswith("_")) \
            if isinstance(repos, list) else []
        self.send_json(200, {"teams": names})


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    print(f"Provisioner listening on :{port}", flush=True)
    ThreadingHTTPServer(("0.0.0.0", port), Handler).serve_forever()
