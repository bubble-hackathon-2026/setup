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
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.request import Request, urlopen
from urllib.error import HTTPError

GITEA = os.environ["GITEA_INTERNAL_URL"]       # http://gitea:3000 (Docker internal)
GITEA_EXT = os.environ["GITEA_EXTERNAL_URL"]    # http://<public-ip>:3000
TOKEN = os.environ["ADMIN_TOKEN"]
ORG = os.environ.get("GITEA_ORG", "hackathon")
TEMPLATE = os.environ.get("TEMPLATE_REPO", "_template")
DOMAIN = os.environ.get("ALLOWED_DOMAIN", "bubble.io")


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

    def do_GET(self):
        if self.path == "/health":
            self.send_json(200, {"ok": True})
        elif self.path == "/teams":
            self.get_teams()
        else:
            self.send_json(404, {"error": "not found"})

    def do_POST(self):
        if self.path == "/provision":
            self.provision()
        elif self.path == "/create-team":
            self.create_team()
        elif self.path == "/join-team":
            self.join_team()
        else:
            self.send_json(404, {"error": "not found"})

    # --- Handlers ---

    def provision(self):
        """Create account for a @bubble.io user, return git credentials."""
        d = self.body()
        email = d.get("email", "").strip().lower()
        name = d.get("name", "").strip()

        if not email.endswith(f"@{DOMAIN}"):
            self.send_json(403, {"error": f"Only @{DOMAIN} emails allowed"})
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
    HTTPServer(("0.0.0.0", port), Handler).serve_forever()
