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

# Usernames that /provision must never create or password-reset, even if the
# requested @bubble.io email maps here. Belt-and-suspenders alongside the
# is_admin check on the existing Gitea user.
RESERVED_USERNAMES = {
    u.strip().lower()
    for u in os.environ.get("RESERVED_USERNAMES", "hackathon-admin").split(",")
    if u.strip()
}

MAX_TEAMS_PER_USER = int(os.environ.get("MAX_TEAMS_PER_USER", "2"))
MAX_CODE_ATTEMPTS = int(os.environ.get("MAX_CODE_ATTEMPTS", "5"))

# In-memory verification code store: email -> (code, expires_at, attempts)
CODES = {}
CODES_LOCK = threading.Lock()
CODE_TTL = 600  # 10 minutes


def store_code(email: str, code: str) -> None:
    now = time.time()
    with CODES_LOCK:
        CODES[email] = (code, now + CODE_TTL, 0)
        # Opportunistic GC of expired codes
        for e in list(CODES.keys()):
            if CODES[e][1] < now:
                del CODES[e]


def verify_code(email: str, code: str) -> bool:
    """Check a submitted code. Wrong attempts are counted; after
    MAX_CODE_ATTEMPTS the entry is invalidated so the attacker has to start
    a fresh /request-code (which sends another DM to the victim and is
    visible in Slack)."""
    with CODES_LOCK:
        entry = CODES.get(email)
        if not entry:
            return False
        stored, expires, attempts = entry
        if time.time() > expires:
            del CODES[email]
            return False
        if stored != code:
            attempts += 1
            if attempts >= MAX_CODE_ATTEMPTS:
                del CODES[email]
            else:
                CODES[email] = (stored, expires, attempts)
            return False
        # Single-use on success
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


def gitea_user_for_token(token: str):
    """Resolve a Gitea PAT to its owning user. Returns None on any failure."""
    if not token:
        return None
    url = f"{GITEA}/api/v1/user"
    req = Request(url, headers={"Authorization": f"token {token}"})
    try:
        with urlopen(req, timeout=10) as r:
            return json.loads(r.read())
    except Exception:
        return None


def find_team_membership(username: str, target_team_name: str):
    """Walk the org's team-* teams once. Returns
    (target_team_id_or_None, already_in_target_bool, total_team_memberships)."""
    teams = api("GET", f"/orgs/{ORG}/teams?limit=100")
    if not isinstance(teams, list):
        return (None, False, 0)
    target_tid = None
    already_in_target = False
    total = 0
    target_full = f"team-{target_team_name}" if target_team_name else None
    for t in teams:
        name = t.get("name", "")
        tid = t.get("id")
        if not name.startswith("team-") or tid is None:
            continue
        member = api("GET", f"/teams/{tid}/members/{username}")
        is_member = isinstance(member, dict) and "login" in member
        if is_member:
            total += 1
        if target_full and name == target_full:
            target_tid = tid
            already_in_target = is_member
    return (target_tid, already_in_target, total)


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

    def authed_user(self):
        """Resolve a request's Authorization: token <pat> header to a Gitea
        login. Returns the username (str) or None. Used to gate endpoints
        that should not be reachable to unauthenticated outsiders."""
        h = self.headers.get("Authorization", "")
        if not h.lower().startswith("token "):
            return None
        token = h.split(None, 1)[1].strip()
        u = gitea_user_for_token(token)
        return u.get("login") if isinstance(u, dict) else None

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
        """Send an 8-digit verification code via Slack DM."""
        d = self.body()
        email = d.get("email", "").strip().lower()

        if not email.endswith(f"@{DOMAIN}"):
            self.send_json(403, {"error": f"Only @{DOMAIN} emails allowed"})
            return

        if not SLACK_TOKEN:
            self.send_json(500, {"error": "Slack verification not configured on this server"})
            return

        # 8-digit code (10000000-99999999, ~90M keyspace). Combined with the
        # MAX_CODE_ATTEMPTS cap and 10-min TTL this makes brute force
        # structurally impossible — best-case ~5e-8 per code window.
        code = f"{secrets.randbelow(90000000) + 10000000}"

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

        # Reserved-username guard: never password-reset the Gitea admin (or
        # any name in RESERVED_USERNAMES). The username transform above means
        # an attacker who controls hackathon-admin@bubble.io (or any local
        # part that collapses to the same login) would otherwise take over
        # the site admin via the existing-user branch below.
        if username in RESERVED_USERNAMES:
            self.send_json(403, {"error": "This account is reserved."})
            return

        # Create or update user
        existing = api("GET", f"/users/{username}")
        if "login" in existing:
            # Belt-and-suspenders: if Gitea reports this account as a site
            # admin, refuse regardless of the static reserved list.
            if existing.get("is_admin") is True:
                self.send_json(403, {"error": "This account is reserved."})
                return
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
        """Create a repo from template + a Gitea team for access control.
        Caller must present the Gitea PAT they got from /provision; we use
        it to confirm they actually own `username`."""
        d = self.body()
        team_name = d.get("team", "").strip()
        username = d.get("username", "").strip()
        token = d.get("token", "").strip()

        if not team_name or not username or not token:
            self.send_json(400, {"error": "team, username, and token required"})
            return

        token_user = gitea_user_for_token(token)
        if not token_user or token_user.get("login", "").lower() != username.lower():
            self.send_json(403, {"error": "Invalid token for this user"})
            return

        # Cap teams *before* creating the repo so we don't leave orphan repos.
        _, _, current_team_count = find_team_membership(username, None)
        if current_team_count >= MAX_TEAMS_PER_USER:
            self.send_json(403, {
                "error": f"You're already in {MAX_TEAMS_PER_USER} teams (max). "
                         f"Leave one before creating another."
            })
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
        """Add a user to an existing team's access group.
        Caller must present the Gitea PAT they got from /provision; we use
        it to confirm they actually own `username`. Re-joining a team you're
        already in is a no-op (idempotent for re-runs of setup.sh)."""
        d = self.body()
        team_name = d.get("team", "").strip()
        username = d.get("username", "").strip()
        token = d.get("token", "").strip()

        if not team_name or not username or not token:
            self.send_json(400, {"error": "team, username, and token required"})
            return

        token_user = gitea_user_for_token(token)
        if not token_user or token_user.get("login", "").lower() != username.lower():
            self.send_json(403, {"error": "Invalid token for this user"})
            return

        target_tid, already_in_target, current_team_count = \
            find_team_membership(username, team_name)

        if target_tid is None:
            self.send_json(404, {"error": "team not found"})
            return

        # Allow re-join (no-op). Only block when joining would push past the
        # cap, which by definition means a NEW team membership.
        if not already_in_target and current_team_count >= MAX_TEAMS_PER_USER:
            self.send_json(403, {
                "error": f"You're already in {MAX_TEAMS_PER_USER} teams (max). "
                         f"Leave one before joining another."
            })
            return

        api("PUT", f"/teams/{target_tid}/members/{username}")
        self.send_json(200, {"team": team_name, "username": username})

    def get_teams(self):
        """List hackathon teams (excludes internal repos).

        Authenticated: callers must present a Gitea PAT they got from
        /provision. setup.sh has a token by the time it reaches the
        join-team flow that consumes this list, so requiring auth here
        costs nothing UX-wise and removes the only unauthenticated
        recon endpoint."""
        if not self.authed_user():
            self.send_json(401, {"error": "auth required"})
            return
        repos = api("GET", f"/orgs/{ORG}/repos?limit=100")
        names = sorted(r["name"] for r in repos if not r["name"].startswith("_")) \
            if isinstance(repos, list) else []
        self.send_json(200, {"teams": names})


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    print(f"Provisioner listening on :{port}", flush=True)
    ThreadingHTTPServer(("0.0.0.0", port), Handler).serve_forever()
