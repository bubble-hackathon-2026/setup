#!/usr/bin/env bash
# Install the leaderboard cron on the hackathon droplet.
#
# Usage (from repo root):
#   admin/leaderboard/install.sh
#
# Reads SERVER_IP, GITEA_URL, ADMIN_TOKEN from .admin-credentials. The first
# time it runs it walks you through Vercel setup interactively and saves the
# resulting VERCEL_TOKEN / VERCEL_PROJECT (and VERCEL_TEAM_ID, if applicable)
# back to .admin-credentials so subsequent runs are non-interactive.
#
# Idempotent: re-run any time you change generate.py.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CREDS="$REPO_ROOT/.admin-credentials"

red()    { printf '\033[0;31m%s\033[0m\n' "$*"; }
green()  { printf '\033[0;32m%s\033[0m\n' "$*"; }
blue()   { printf '\033[0;34m%s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }
fail()   { red "ERROR: $*" >&2; exit 1; }
step()   { blue "→ $*"; }
info()   { green "  ✓ $*"; }
warn()   { yellow "  ! $*"; }

[ -f "$CREDS" ] || fail "Missing $CREDS"
# shellcheck disable=SC1091
source "$CREDS"

: "${SERVER_IP:?SERVER_IP must be set in .admin-credentials}"
: "${GITEA_URL:?GITEA_URL must be set in .admin-credentials}"
: "${ADMIN_TOKEN:?ADMIN_TOKEN must be set in .admin-credentials}"

VERCEL_TOKEN="${VERCEL_TOKEN:-}"
VERCEL_PROJECT="${VERCEL_PROJECT:-hackathon-leaderboard}"
VERCEL_TEAM_ID="${VERCEL_TEAM_ID:-}"

# --- Helpers ---------------------------------------------------------------

# In-place update or append KEY=VAL in the credentials file. Uses python so
# we don't have to deal with sed quoting around tokens that may contain `&`,
# `/`, or other delimiters.
update_cred() {
    local key="$1" val="$2"
    python3 - "$key" "$val" "$CREDS" <<'PY'
import sys, re, os
key, val, path = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    text = f.read()
line = f"{key}={val}"
if re.search(rf'(?m)^{re.escape(key)}=', text):
    text = re.sub(rf'(?m)^{re.escape(key)}=.*$', line, text)
else:
    if not text.endswith("\n"):
        text += "\n"
    text += line + "\n"
with open(path, "w") as f:
    f.write(text)
os.chmod(path, 0o600)
PY
}

vercel_api() {
    # vercel_api METHOD PATH [json-body]
    local method="$1" path="$2" body="${3:-}"
    local args=(-sS -X "$method" -H "Authorization: Bearer $VERCEL_TOKEN")
    if [ -n "$body" ]; then
        args+=(-H "Content-Type: application/json" --data-raw "$body")
    fi
    # Append teamId if we have one and the URL doesn't already include a query.
    local url="https://api.vercel.com$path"
    if [ -n "$VERCEL_TEAM_ID" ]; then
        if [[ "$url" == *\?* ]]; then url="$url&teamId=$VERCEL_TEAM_ID"
        else url="$url?teamId=$VERCEL_TEAM_ID"; fi
    fi
    curl "${args[@]}" "$url"
}

open_url() {
    if command -v open >/dev/null 2>&1; then open "$1" 2>/dev/null || true
    elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$1" 2>/dev/null || true
    fi
}

py() { python3 -c "$@"; }

# --- Vercel setup ----------------------------------------------------------

setup_vercel() {
    step "Checking Vercel credentials..."

    if [ -n "$VERCEL_TOKEN" ]; then
        if curl -sf -o /dev/null -H "Authorization: Bearer $VERCEL_TOKEN" \
            "https://api.vercel.com/v2/user"; then
            info "Existing Vercel token works"
        else
            warn "Saved Vercel token is invalid or expired — will re-prompt"
            VERCEL_TOKEN=""
        fi
    fi

    if [ -z "$VERCEL_TOKEN" ]; then
        cat <<'EOF'

  Vercel needs a personal access token (one-time setup).

    1. We'll open https://vercel.com/account/tokens in your browser.
    2. Click "Create Token":
         Name:        hackathon-leaderboard
         Scope:       Full Account     (or a specific Team if your
                                        projects live under one)
         Expiration:  any — token is stored only in .admin-credentials
    3. Copy the token (Vercel shows it once) and paste it below.

EOF
        open_url "https://vercel.com/account/tokens"
        # shellcheck disable=SC2162
        read -r -s -p "  Paste Vercel token: " VERCEL_TOKEN
        echo
        VERCEL_TOKEN="$(printf '%s' "$VERCEL_TOKEN" | tr -d '[:space:]')"
        [ -z "$VERCEL_TOKEN" ] && fail "Empty token"

        if ! curl -sf -o /dev/null -H "Authorization: Bearer $VERCEL_TOKEN" \
            "https://api.vercel.com/v2/user"; then
            fail "Vercel rejected that token. Double-check at https://vercel.com/account/tokens"
        fi
        info "Token validated"
    fi

    # Identify the user and any teams they have access to.
    local who username teams_json team_count
    who=$(curl -sf -H "Authorization: Bearer $VERCEL_TOKEN" "https://api.vercel.com/v2/user")
    username=$(printf '%s' "$who" | py 'import json,sys;print(json.load(sys.stdin)["user"]["username"])')
    teams_json=$(curl -sf -H "Authorization: Bearer $VERCEL_TOKEN" "https://api.vercel.com/v2/teams")
    team_count=$(printf '%s' "$teams_json" | py 'import json,sys;print(len(json.load(sys.stdin).get("teams",[])))')

    if [ -z "$VERCEL_TEAM_ID" ] && [ "$team_count" -gt 0 ]; then
        echo
        echo "  This token has access to $team_count team(s). Pick where to host the leaderboard:"
        echo "    0) Personal ($username)"
        printf '%s' "$teams_json" | py '
import json,sys
ts = json.load(sys.stdin).get("teams",[])
for i,t in enumerate(ts, start=1):
    print("    %d) %s  (%s)" % (i, t["name"], t["slug"]))
'
        local choice
        # shellcheck disable=SC2162
        read -r -p "  Choose [0]: " choice
        choice="${choice:-0}"
        if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 0 ] || [ "$choice" -gt "$team_count" ]; then
            fail "Invalid choice: $choice"
        fi
        if [ "$choice" -gt 0 ]; then
            VERCEL_TEAM_ID=$(printf '%s' "$teams_json" | py "
import json,sys
print(json.load(sys.stdin)['teams'][$choice - 1]['id'])
")
            info "Using team scope (id=$VERCEL_TEAM_ID)"
        else
            info "Using personal scope ($username)"
        fi
    else
        info "Using $([ -n "$VERCEL_TEAM_ID" ] && echo "team scope (id=$VERCEL_TEAM_ID)" || echo "personal scope ($username)")"
    fi

    # Persist token + scope before touching projects so a re-run picks up here.
    update_cred VERCEL_TOKEN "$VERCEL_TOKEN"
    update_cred VERCEL_PROJECT "$VERCEL_PROJECT"
    [ -n "$VERCEL_TEAM_ID" ] && update_cred VERCEL_TEAM_ID "$VERCEL_TEAM_ID"

    # Create or confirm the project.
    step "Ensuring Vercel project '$VERCEL_PROJECT' exists..."
    local code
    code=$(curl -sS -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $VERCEL_TOKEN" \
        "https://api.vercel.com/v9/projects/$VERCEL_PROJECT$([ -n "$VERCEL_TEAM_ID" ] && echo "?teamId=$VERCEL_TEAM_ID")")
    case "$code" in
        200) info "Project already exists" ;;
        404)
            local resp
            resp=$(vercel_api POST "/v11/projects" "{\"name\":\"$VERCEL_PROJECT\"}")
            if printf '%s' "$resp" | grep -q '"error"'; then
                echo "$resp" >&2
                fail "Couldn't create Vercel project"
            fi
            info "Project created"
            ;;
        *) fail "Unexpected response from Vercel ($code) when checking project" ;;
    esac

    # Hobby teams default to "Standard Protection" (SSO gate). The leaderboard
    # is meant to be public, so always disable it. PATCH is a no-op if already
    # null, so this is safe to re-run.
    step "Disabling deployment SSO protection (public leaderboard)..."
    vercel_api PATCH "/v9/projects/$VERCEL_PROJECT" '{"ssoProtection":null}' >/dev/null
    info "Project is publicly accessible"
}

# Returns the shortest production alias on .vercel.app for the project, or
# empty if there isn't one yet. Vercel auto-assigns several aliases per
# production deploy (bare project name, scope-suffixed variants); we pick the
# shortest as the stable URL.
production_alias() {
    vercel_api GET "/v9/projects/$VERCEL_PROJECT" | python3 -c '
import json, sys
p = json.load(sys.stdin)
# targets.production.alias is the canonical, time-stable alias list. The
# latestDeployments view is eventually consistent and may be partial right
# after a deploy.
aliases = ((p.get("targets") or {}).get("production") or {}).get("alias") or []
public = [a for a in aliases if a.endswith(".vercel.app")]
public.sort(key=len)
print(public[0] if public else "")
' 2>/dev/null
}

setup_vercel

# --- Droplet install -------------------------------------------------------

SSH_CTRL="/tmp/ssh-leaderboard-$$"
SSH_OPTS=(-o StrictHostKeyChecking=no -o ControlMaster=auto -o "ControlPath=$SSH_CTRL" -o ControlPersist=2m)
cleanup() { ssh "${SSH_OPTS[@]}" -O exit "root@$SERVER_IP" 2>/dev/null || true; rm -f "$SSH_CTRL"; }
trap cleanup EXIT
rssh() { ssh "${SSH_OPTS[@]}" "root@$SERVER_IP" "$@"; }
rscp() { scp "${SSH_OPTS[@]}" "$@"; }

step "Connecting to $SERVER_IP..."
rssh -o ConnectTimeout=10 "echo ok" >/dev/null || fail "Cannot SSH to root@$SERVER_IP"
info "SSH up"

step "Creating /opt/leaderboard..."
rssh "install -d -m 0755 /opt/leaderboard"
info "Directory ready"

step "Uploading generate.py..."
rscp "$SCRIPT_DIR/generate.py" "root@$SERVER_IP:/opt/leaderboard/generate.py" >/dev/null
rssh "chmod 0755 /opt/leaderboard/generate.py"
info "Script uploaded"

step "Writing /opt/leaderboard/env (creds, mode 0600)..."
{
    printf 'GITEA_URL=%s\n'      "http://localhost:3000"
    printf 'GITEA_TOKEN=%s\n'    "$ADMIN_TOKEN"
    printf 'VERCEL_TOKEN=%s\n'   "$VERCEL_TOKEN"
    printf 'VERCEL_PROJECT=%s\n' "$VERCEL_PROJECT"
    [ -n "$VERCEL_TEAM_ID" ] && printf 'VERCEL_TEAM_ID=%s\n' "$VERCEL_TEAM_ID"
} | rssh "umask 077 && cat >/opt/leaderboard/env"
rssh "chmod 0600 /opt/leaderboard/env && chown root:root /opt/leaderboard/env"
info "Env file written"

step "Writing /opt/leaderboard/run.sh..."
rssh "cat >/opt/leaderboard/run.sh <<'RUNEOF'
#!/usr/bin/env bash
set -e
set -a; . /opt/leaderboard/env; set +a
cd /opt/leaderboard
exec /usr/bin/python3 generate.py
RUNEOF
chmod 0755 /opt/leaderboard/run.sh"
info "Wrapper written"

step "Installing cron entry (every 10 minutes)..."
rssh "cat >/etc/cron.d/hackathon-leaderboard <<'CRONEOF'
# Hackathon leaderboard — refresh every 10 minutes.
# Managed by admin/leaderboard/install.sh; do not edit by hand.
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
*/10 * * * * root /opt/leaderboard/run.sh >>/var/log/hackathon-leaderboard.log 2>&1
CRONEOF
chmod 0644 /etc/cron.d/hackathon-leaderboard
touch /var/log/hackathon-leaderboard.log
chmod 0640 /var/log/hackathon-leaderboard.log"
info "Cron installed at /etc/cron.d/hackathon-leaderboard"

step "Running once now to verify..."
set +e
output=$(rssh "/opt/leaderboard/run.sh 2>&1")
status=$?
set -e
echo "$output" | sed 's/^/    /'
[ $status -eq 0 ] || fail "Test run failed (exit $status). See output above."

deploy_url=$(echo "$output" | sed -n 's|^Deployed: ||p' | tail -1)

# Vercel takes a few seconds to propagate all production aliases after a
# deploy. Poll until the shortest alias appears (or give up after ~10s and
# print whatever we have).
stable_alias=""
for _ in 1 2 3 4 5; do
    candidate=$(production_alias)
    if [ -n "$candidate" ] && [ -z "$stable_alias" ] || \
       { [ -n "$candidate" ] && [ "${#candidate}" -lt "${#stable_alias}" ]; }; then
        stable_alias="$candidate"
    fi
    [ -n "$stable_alias" ] && [ "${#stable_alias}" -lt 40 ] && break
    sleep 2
done
green ""
green "Done. Cron will refresh the leaderboard every 10 minutes."
[ -n "$deploy_url" ] && green "  Latest deploy: $deploy_url"
if [ -n "$stable_alias" ]; then
    green "  Stable URL:    https://$stable_alias"
else
    yellow "  Stable URL:    (couldn't fetch project alias — check Vercel dashboard)"
fi
green "  Tail logs:     ssh root@$SERVER_IP 'tail -f /var/log/hackathon-leaderboard.log'"
