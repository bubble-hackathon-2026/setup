#!/usr/bin/env python3
"""
Hackathon leaderboard generator.

Pulls team data from the local Gitea API, renders a single static
index.html, and publishes it to Vercel as a production deployment.

Designed to run as a cron job on the same droplet that hosts Gitea.
Uses stdlib only — no pip install required.

Required environment:
    GITEA_URL          e.g. http://localhost:3000
    GITEA_TOKEN        admin token with read access
    VERCEL_TOKEN       Vercel personal token
    VERCEL_PROJECT     Vercel project name (created on first deploy)

Optional:
    GITEA_ORG          default "hackathon"
    TEMPLATE_REPO      default "_template" (excluded from leaderboard)
    ADMIN_LOGIN        default "hackathon" (commits by this user are scaffold)
    VERCEL_TEAM_ID     if the Vercel project lives under a team
    OUTPUT_HTML        if set, also write the HTML to this path
"""

import base64
import html
import json
import os
import sys
import time
from urllib.parse import urlencode
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

GITEA = os.environ["GITEA_URL"].rstrip("/")
GITEA_TOKEN = os.environ["GITEA_TOKEN"]
VERCEL_TOKEN = os.environ.get("VERCEL_TOKEN", "")
VERCEL_PROJECT = os.environ.get("VERCEL_PROJECT", "")
VERCEL_TEAM_ID = os.environ.get("VERCEL_TEAM_ID", "")
ORG = os.environ.get("GITEA_ORG", "hackathon")
TEMPLATE_REPO = os.environ.get("TEMPLATE_REPO", "_template")
ADMIN_LOGIN = os.environ.get("ADMIN_LOGIN", "hackathon")
OUTPUT_HTML = os.environ.get("OUTPUT_HTML", "")


def gitea(path, params=None):
    url = f"{GITEA}/api/v1{path}"
    if params:
        url += "?" + urlencode(params)
    req = Request(url, headers={"Authorization": f"token {GITEA_TOKEN}"})
    with urlopen(req, timeout=30) as r:
        return json.loads(r.read()), dict(r.headers)


def gitea_paged(path, params=None, page_size=50, max_pages=20):
    """Iterate all pages of a Gitea list endpoint."""
    out = []
    page = 1
    while page <= max_pages:
        p = dict(params or {})
        p["page"] = page
        p["limit"] = page_size
        data, _ = gitea(path, p)
        if not data:
            break
        out.extend(data)
        if len(data) < page_size:
            break
        page += 1
    return out


def list_team_repos():
    """All repos in the org except the template."""
    repos = gitea_paged(f"/orgs/{ORG}/repos")
    return [r for r in repos if r["name"] != TEMPLATE_REPO and not r.get("empty")]


def team_members(repo_name):
    """Members of the Gitea team that owns this repo (team-<repo>)."""
    try:
        team, _ = gitea(f"/orgs/{ORG}/teams/search", {"q": f"team-{repo_name}"})
        teams = team.get("data", []) if isinstance(team, dict) else team
        match = next((t for t in teams if t["name"] == f"team-{repo_name}"), None)
        if not match:
            return []
        members = gitea_paged(f"/teams/{match['id']}/members")
        return [m.get("full_name") or m["login"] for m in members]
    except HTTPError:
        return []


def is_scaffold_commit(c):
    """True for the template's initial commit and any other admin-authored work.

    The scaffold "Initial commit" has no mapped Gitea user (author is None) and
    a git-level author name of 'hackathon' with no email. Participant commits
    always carry a real Gitea login plus a bubble.io email.
    """
    author = c.get("author") or {}
    if author.get("login") == ADMIN_LOGIN:
        return True
    if author.get("login"):
        return False
    git_name = ((c.get("commit") or {}).get("author") or {}).get("name", "")
    return git_name == ADMIN_LOGIN


def repo_stats(repo_name):
    """Returns (commit_count, net_loc) — admin scaffold commits excluded."""
    commits = gitea_paged(
        f"/repos/{ORG}/{repo_name}/commits",
        {"stat": "true", "files": "false"},
        page_size=50,
        max_pages=10,
    )
    n_commits = 0
    loc = 0
    for c in commits:
        if is_scaffold_commit(c):
            continue
        n_commits += 1
        s = c.get("stats") or {}
        loc += int(s.get("additions", 0)) - int(s.get("deletions", 0))
    return n_commits, max(loc, 0)


def collect():
    teams = []
    for repo in list_team_repos():
        name = repo["name"]
        members = team_members(name)
        commits, loc = repo_stats(name)
        teams.append(
            {
                "name": name,
                "members": members,
                "commits": commits,
                "loc": loc,
            }
        )
    teams.sort(key=lambda t: (-t["commits"], -t["loc"], t["name"]))
    return teams


HTML_TEMPLATE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Bubble Hackathon 2026 — Live Leaderboard</title>
<style>
  :root {
    --bubble-blue: #0072F5;
    --bubble-blue-dark: #0057c2;
    --bubble-purple: #7B5BFF;
    --bubble-pink: #FF4D8D;
    --ink: #0B1020;
    --ink-2: #2A3047;
    --paper: #F7F8FC;
    --card: #ffffff;
    --rule: #E6E9F2;
  }
  * { box-sizing: border-box; }
  html, body { margin: 0; padding: 0; }
  body {
    font: 16px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", Inter, Roboto, sans-serif;
    color: var(--ink);
    background: var(--paper);
    min-height: 100vh;
  }
  header {
    background: linear-gradient(135deg, var(--bubble-blue) 0%, var(--bubble-purple) 60%, var(--bubble-pink) 100%);
    color: white;
    padding: 56px 24px 80px;
    position: relative;
    overflow: hidden;
  }
  header::before {
    content: "";
    position: absolute;
    inset: 0;
    background-image: radial-gradient(circle at 20% 30%, rgba(255,255,255,0.18) 0, transparent 40%),
                      radial-gradient(circle at 80% 70%, rgba(255,255,255,0.12) 0, transparent 35%);
    pointer-events: none;
  }
  .wrap { max-width: 1080px; margin: 0 auto; padding: 0 24px; position: relative; }
  .eyebrow {
    font-size: 13px; letter-spacing: 0.18em; text-transform: uppercase;
    opacity: 0.9; font-weight: 600;
  }
  h1 {
    font-size: clamp(36px, 6vw, 64px);
    margin: 8px 0 4px;
    font-weight: 800;
    letter-spacing: -0.02em;
    line-height: 1.05;
  }
  .tagline { opacity: 0.92; font-size: 18px; margin-top: 8px; }
  main { max-width: 1080px; margin: -48px auto 64px; padding: 0 24px; position: relative; }
  .card {
    background: var(--card);
    border-radius: 16px;
    box-shadow: 0 12px 40px rgba(11, 16, 32, 0.08), 0 2px 8px rgba(11, 16, 32, 0.04);
    overflow: hidden;
  }
  .meta {
    display: flex; align-items: center; justify-content: space-between;
    padding: 18px 24px; border-bottom: 1px solid var(--rule);
    color: var(--ink-2); font-size: 14px;
  }
  .pulse { display: inline-flex; align-items: center; gap: 8px; }
  .dot {
    width: 8px; height: 8px; border-radius: 50%; background: #21C97A;
    box-shadow: 0 0 0 0 rgba(33, 201, 122, 0.7); animation: pulse 1.6s infinite;
  }
  @keyframes pulse {
    0%   { box-shadow: 0 0 0 0 rgba(33, 201, 122, 0.55); }
    70%  { box-shadow: 0 0 0 10px rgba(33, 201, 122, 0); }
    100% { box-shadow: 0 0 0 0 rgba(33, 201, 122, 0); }
  }
  table { width: 100%; border-collapse: collapse; }
  thead th {
    text-align: left; font-size: 12px; letter-spacing: 0.08em;
    text-transform: uppercase; color: var(--ink-2);
    padding: 14px 24px; background: #FBFCFF;
    border-bottom: 1px solid var(--rule);
  }
  tbody td { padding: 18px 24px; border-bottom: 1px solid var(--rule); vertical-align: top; }
  tbody tr:last-child td { border-bottom: none; }
  tbody tr:hover { background: #FAFBFF; }
  .rank {
    width: 56px; font-variant-numeric: tabular-nums;
    font-weight: 700; color: var(--ink-2);
  }
  .rank.top1 { color: #C99A2C; }
  .rank.top2 { color: #8A8FA3; }
  .rank.top3 { color: #B5783E; }
  .rank.top1::before, .rank.top2::before, .rank.top3::before {
    content: "🏆 "; margin-right: 2px;
  }
  .rank.top2::before { content: "🥈 "; }
  .rank.top3::before { content: "🥉 "; }
  .team {
    font-weight: 700; font-size: 17px; letter-spacing: -0.01em;
  }
  .members { color: var(--ink-2); font-size: 14px; margin-top: 4px; }
  .members .pill {
    display: inline-block; padding: 2px 10px; border-radius: 999px;
    background: #EEF2FF; color: #3949AB; margin: 2px 4px 2px 0;
    font-size: 12px; font-weight: 500;
  }
  .num {
    font-variant-numeric: tabular-nums;
    font-weight: 700; font-size: 18px; text-align: right; white-space: nowrap;
  }
  .num.dim { color: var(--ink-2); font-weight: 600; font-size: 16px; }
  .empty { padding: 48px 24px; text-align: center; color: var(--ink-2); }
  footer {
    text-align: center; color: var(--ink-2); font-size: 13px;
    padding: 24px; opacity: 0.85;
  }
  @media (max-width: 600px) {
    header { padding: 40px 20px 64px; }
    main { margin-top: -36px; padding: 0 12px; }
    thead th, tbody td { padding: 12px 14px; }
    .num { font-size: 16px; }
    .team { font-size: 15px; }
    .members { font-size: 13px; }
  }
</style>
</head>
<body>
  <header>
    <div class="wrap">
      <div class="eyebrow">Live Leaderboard</div>
      <h1>Bubble Hackathon 2026</h1>
      <div class="tagline">Real-time view of every team's progress, refreshed every 10 minutes.</div>
    </div>
  </header>
  <main>
    <div class="card">
      <div class="meta">
        <span><strong>__TEAM_COUNT__</strong> teams · <strong>__COMMIT_TOTAL__</strong> commits · <strong>__LOC_TOTAL__</strong> lines of code</span>
        <span class="pulse"><span class="dot"></span>Updated __UPDATED__</span>
      </div>
      __TABLE__
    </div>
    <footer>Built with <span style="color:var(--bubble-pink)">♥</span> on Bubble · ranked by commits, then lines of code</footer>
  </main>
</body>
</html>
"""


def render_html(teams):
    if not teams:
        body = '<div class="empty">No teams yet — check back soon.</div>'
    else:
        rows = []
        for i, t in enumerate(teams, start=1):
            rank_cls = f"top{i}" if i <= 3 else ""
            members_html = (
                "".join(f'<span class="pill">{html.escape(m)}</span>' for m in t["members"])
                if t["members"]
                else '<span style="opacity:0.5">no members yet</span>'
            )
            rows.append(
                f'<tr>'
                f'<td class="rank {rank_cls}">{i}</td>'
                f'<td>'
                f'  <div class="team">{html.escape(t["name"])}</div>'
                f'  <div class="members">{members_html}</div>'
                f'</td>'
                f'<td class="num">{t["commits"]:,}</td>'
                f'<td class="num dim">{t["loc"]:,}</td>'
                f'</tr>'
            )
        body = (
            "<table>"
            "<thead><tr>"
            "<th>#</th><th>Team</th>"
            '<th style="text-align:right">Commits</th>'
            '<th style="text-align:right">Lines</th>'
            "</tr></thead>"
            f"<tbody>{''.join(rows)}</tbody>"
            "</table>"
        )

    total_commits = sum(t["commits"] for t in teams)
    total_loc = sum(t["loc"] for t in teams)
    updated = time.strftime("%b %-d, %Y · %-I:%M %p UTC", time.gmtime())

    return (
        HTML_TEMPLATE
        .replace("__TABLE__", body)
        .replace("__TEAM_COUNT__", f"{len(teams):,}")
        .replace("__COMMIT_TOTAL__", f"{total_commits:,}")
        .replace("__LOC_TOTAL__", f"{total_loc:,}")
        .replace("__UPDATED__", updated)
    )


def deploy_to_vercel(html_str):
    """Deploy a single index.html to Vercel as a production deployment."""
    if not VERCEL_TOKEN or not VERCEL_PROJECT:
        print("VERCEL_TOKEN/VERCEL_PROJECT not set — skipping deploy", file=sys.stderr)
        return None

    payload = {
        "name": VERCEL_PROJECT,
        "target": "production",
        "files": [
            {
                "file": "index.html",
                "data": base64.b64encode(html_str.encode("utf-8")).decode("ascii"),
                "encoding": "base64",
            }
        ],
        "projectSettings": {"framework": None},
    }
    qs = f"?teamId={VERCEL_TEAM_ID}" if VERCEL_TEAM_ID else ""
    req = Request(
        f"https://api.vercel.com/v13/deployments{qs}",
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {VERCEL_TOKEN}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urlopen(req, timeout=60) as r:
            resp = json.loads(r.read())
            return resp.get("url") or resp.get("alias", [None])[0]
    except HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        print(f"Vercel deploy failed: HTTP {e.code} — {body}", file=sys.stderr)
        raise


def main():
    teams = collect()
    page = render_html(teams)
    if OUTPUT_HTML:
        with open(OUTPUT_HTML, "w") as f:
            f.write(page)
    url = deploy_to_vercel(page)
    if url:
        print(f"Deployed: https://{url}")
    print(f"Teams: {len(teams)} · commits: {sum(t['commits'] for t in teams)} · loc: {sum(t['loc'] for t in teams)}")


if __name__ == "__main__":
    main()
