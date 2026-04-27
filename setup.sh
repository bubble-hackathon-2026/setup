#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Bubble Hackathon 2026 — Team Setup
#
# Usage (shared via internal Slack — the server IP is the secret):
#   bash <(curl -fsSL https://raw.githubusercontent.com/bubble-hackathon-2026/setup/main/setup.sh) SERVER_IP
#
# Only prerequisite: Claude Code.
# Node.js and git are auto-installed if missing.
# ============================================================================

SERVER_IP="${1:-}"
GITEA_ORG="hackathon"
HACKATHON_DIR="$HOME/hackathon"

# --- Colors & helpers ---

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "  ${GREEN}+${NC} $1"; }
warn()  { echo -e "  ${YELLOW}!${NC} $1"; }
fail()  { echo -e "  ${RED}x${NC} $1"; }
step()  { echo -e "\n${BOLD}$1${NC}"; }

# --- HTTP helper ---
# Populates globals RESP_STATUS, RESP_BODY, CURL_EXIT, CURL_STDERR.
# Returns 0 iff curl exited cleanly (any HTTP status); non-zero iff transport failed.
post_json() {
    local endpoint="$1"
    local payload="$2"
    local body_file stderr_file
    body_file=$(mktemp)
    stderr_file=$(mktemp)

    set +e
    RESP_STATUS=$(curl -sS --connect-timeout 10 --max-time 60 \
        --retry 2 --retry-delay 2 \
        -X POST "$PROVISIONER$endpoint" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        -o "$body_file" \
        -w "%{http_code}" \
        2>"$stderr_file")
    CURL_EXIT=$?
    set -e

    RESP_BODY=$(cat "$body_file" 2>/dev/null || echo "")
    CURL_STDERR=$(cat "$stderr_file" 2>/dev/null || echo "")
    rm -f "$body_file" "$stderr_file"

    [ "$CURL_EXIT" -eq 0 ]
}

# Print a diagnostic block the user can paste back to organizers.
# Called when we get an unexpected, unparseable response from the provisioner.
fail_diag() {
    local endpoint="$1"
    fail "Unable to validate. Please try again in a moment."
    echo ""
    echo "  See below for technical details (share with a hackathon organizer"
    echo "  if this keeps happening):"
    echo ""
    echo "  ----- diagnostic info -----"
    echo "  endpoint:    $endpoint"
    echo "  http status: ${RESP_STATUS:-<none>}"
    echo "  curl exit:   ${CURL_EXIT:-<none>}"
    if [ -n "${CURL_STDERR:-}" ]; then
        echo "  curl stderr:"
        printf '%s\n' "$CURL_STDERR" | head -c 500 | sed 's/^/    /'
        echo ""
    fi
    if [ -n "${RESP_BODY:-}" ]; then
        echo "  response body:"
        printf '%s\n' "$RESP_BODY" | head -c 500 | sed 's/^/    /'
        echo ""
    fi
    echo "  ---------------------------"
    exit 1
}

# Try to extract .error from a JSON blob. Empty string if not JSON or no .error.
# Uses node (auto-installed above) rather than python3, which isn't guaranteed
# on macOS when the user already had git installed from a source other than
# Xcode CLI tools (e.g., Homebrew) — /usr/bin/python3 is a shim that only
# works if CLI tools are present.
extract_error() {
    node -e 'try{const o=JSON.parse(process.argv[1]);process.stdout.write((o.error||"")+"\n")}catch{}' -- "$1" 2>/dev/null || true
}

# Try to extract a named string field. Empty string if not JSON or missing.
extract_field() {
    node -e 'try{const o=JSON.parse(process.argv[1]);process.stdout.write((o[process.argv[2]]||"")+"\n")}catch{}' -- "$1" "$2" 2>/dev/null || true
}

# If stdin is piped (curl | bash), reopen terminal for interactive input
if [ ! -t 0 ]; then
    exec < /dev/tty
fi

echo ""
echo -e "${BOLD}========================================${NC}"
echo -e "${BOLD}   Bubble Hackathon 2026 — Setup${NC}"
echo -e "${BOLD}========================================${NC}"

# --- Get server IP ---

if [ -z "$SERVER_IP" ]; then
    echo ""
    echo "  Enter the hackathon server address (from the Slack message)."
    read -r -p "  Server IP: " SERVER_IP
fi

[ -z "$SERVER_IP" ] && { fail "Server IP is required."; exit 1; }

# Strip protocol/port if someone pasted a full URL
SERVER_IP=$(echo "$SERVER_IP" | sed 's|http[s]*://||' | cut -d: -f1)

GITEA_URL="http://$SERVER_IP:3000"
PROVISIONER="http://$SERVER_IP:8080"

# --- Auto-install prerequisites ---

step "Checking prerequisites..."

# Git — comes with Xcode CLT on macOS.
# IMPORTANT: /usr/bin/git is a shim that exists even when Command Line Tools
# aren't installed — it just prompts the install dialog on first use. So
# `command -v git` isn't enough; we also check that CLT is actually active.
# (A Homebrew/non-Apple git at a different path is trusted as-is.)
git_is_real() {
    local git_path
    git_path=$(command -v git 2>/dev/null) || return 1
    [ "$git_path" != "/usr/bin/git" ] && return 0
    xcode-select -p &>/dev/null
}

if git_is_real; then
    info "Git"
else
    warn "Git not available — installing Xcode Command Line Tools..."
    echo "  A dialog will appear. Click 'Install' and agree to the terms."
    echo "  This takes several minutes; leave the dialog running."
    xcode-select --install 2>/dev/null || true
    echo ""
    printf "  Waiting for install to complete"
    # Poll up to ~20 minutes (120 * 10s). CLT installs can be slow on
    # fresh machines or slow connections.
    for _ in $(seq 1 120); do
        if git_is_real; then
            echo ""
            info "Git installed"
            break
        fi
        printf "."
        sleep 10
    done
    if ! git_is_real; then
        echo ""
        fail "Command Line Tools install didn't complete in time."
        echo "  If you cancelled the dialog, re-run this script."
        echo "  If it's still installing, wait for it to finish, then re-run."
        exit 1
    fi
fi

# Node.js — auto-install via macOS .pkg if missing
if command -v node &>/dev/null; then
    info "Node.js ($(node --version))"
else
    warn "Node.js not found — installing (you may be asked for your Mac password)..."
    curl -fsSL "https://nodejs.org/dist/v22.15.0/node-v22.15.0.pkg" -o /tmp/node-installer.pkg
    sudo installer -pkg /tmp/node-installer.pkg -target / 2>/dev/null
    rm -f /tmp/node-installer.pkg
    export PATH="/usr/local/bin:$PATH"
    if command -v node &>/dev/null; then
        info "Node.js installed ($(node --version))"
    else
        fail "Install failed. Download manually from https://nodejs.org and re-run."
        exit 1
    fi
fi

# Claude Code
if command -v claude &>/dev/null; then
    info "Claude Code"
else
    warn "Claude Code not found — install after setup:"
    echo -e "       ${BLUE}curl -fsSL https://claude.ai/install.sh | bash${NC}"
fi

# --- Check server ---

step "Connecting to hackathon server..."

if ! curl -sf "$PROVISIONER/health" &>/dev/null; then
    fail "Cannot reach the hackathon server at $SERVER_IP"
    echo "  Make sure you have the right IP from the Slack message."
    exit 1
fi
info "Server reachable"

# --- Identify the user ---

step "Who are you?"
echo ""
read -r -p "  Your name (e.g., Jane Smith): " user_name
read -r -p "  Your @bubble.io email: " user_email

# --- Verify identity via Slack DM ---

step "Verifying your email..."

if ! post_json "/request-code" "{\"email\": \"$user_email\"}"; then
    fail_diag "POST /request-code"
fi

if [ "$RESP_STATUS" != "200" ]; then
    code_error=$(extract_error "$RESP_BODY")
    if [ -n "$code_error" ]; then
        fail "$code_error"
        exit 1
    fi
    fail_diag "POST /request-code"
fi

info "Check Slack — we just sent you a DM with an 8-digit code"
echo ""
read -r -p "  Enter the code: " verify_code

# --- Create account (provisioner verifies the code) ---

step "Setting up your account..."

if ! post_json "/provision" "{\"name\": \"$user_name\", \"email\": \"$user_email\", \"code\": \"$verify_code\"}"; then
    fail_diag "POST /provision"
fi

if [ "$RESP_STATUS" != "200" ]; then
    prov_error=$(extract_error "$RESP_BODY")
    if [ -n "$prov_error" ]; then
        fail "$prov_error"
        exit 1
    fi
    fail_diag "POST /provision"
fi

username=$(extract_field "$RESP_BODY" "username")
user_token=$(extract_field "$RESP_BODY" "token")

if [ -z "$user_token" ] || [ -z "$username" ]; then
    fail_diag "POST /provision"
fi

info "Account ready: $username"

server_host="$SERVER_IP:3000"
# Build the clone URL with inline credentials. We embed creds in the URL
# rather than using a credential helper — macOS's osxkeychain helper
# overrides credential.helper=store globally, and caches stale tokens.
# Inline creds bypass all credential helpers and work reliably.
repo_url_base="http://$username:$user_token@$server_host/$GITEA_ORG"

git config --global user.name "$user_name" 2>/dev/null || true
git config --global user.email "$user_email" 2>/dev/null || true

info "Git configured"

# --- New team or join ---

slugify() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//'
}

# Write Claude Code project-local settings so the auto-mode classifier doesn't
# interrupt routine hackathon actions (push to main, npm install, npx vercel).
# defaultMode=acceptEdits auto-accepts file edits so non-technical users
# aren't prompted to review generated code.
# Written to settings.local.json (per-user, gitignored) so it's trusted
# by Claude Code's anti-prompt-injection rules.
write_claude_settings() {
    local dir="$1"
    mkdir -p "$dir/.claude"
    cat > "$dir/.claude/settings.local.json" << 'CLAUDEEOF'
{
  "autoMode": {
    "environment": [
      "This is a hackathon prototype repo on an internal Gitea server.",
      "Throwaway prototypes — no production code or customer data.",
      "No branch protection, no PR review — direct work on main is expected."
    ],
    "allow": [
      "Direct push to main in this repo is the expected workflow.",
      "npx vercel deployments are allowed — prototypes are meant to be shared via public demo URLs.",
      "npm install and npx for any package is part of normal hackathon iteration.",
      "git commit, push, pull, stash, rebase — all normal collaboration actions."
    ]
  },
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Bash(git push:*)",
      "Bash(git pull:*)",
      "Bash(git commit:*)",
      "Bash(git add:*)",
      "Bash(git stash:*)",
      "Bash(git rebase:*)",
      "Bash(git merge:*)",
      "Bash(git checkout:*)",
      "Bash(git reset:*)",
      "Bash(npm:*)",
      "Bash(npx:*)"
    ]
  }
}
CLAUDEEOF
    # Ensure the local settings file is gitignored (templates from before
    # this fix won't have it in .gitignore yet).
    if [ -f "$dir/.gitignore" ] && ! grep -qF '.claude/settings.local.json' "$dir/.gitignore"; then
        printf '\n# Claude Code per-user settings\n.claude/settings.local.json\n' >> "$dir/.gitignore"
    fi
}

step "What would you like to do?"
echo "  1) Start a new team"
echo "  2) Join an existing team"
echo ""
read -r -p "  Enter 1 or 2: " choice

team_slug=""

# --- Create new team ---

if [ "$choice" = "1" ]; then
    echo ""
    while true; do
        read -r -p "  Team name: " raw_name
        team_slug=$(slugify "$raw_name")
        [ -z "$team_slug" ] && { fail "Enter a name using letters, numbers, or hyphens."; continue; }

        result=$(curl -s -X POST "$PROVISIONER/create-team" \
            -H "Content-Type: application/json" \
            -d "{\"team\": \"$team_slug\", \"username\": \"$username\", \"token\": \"$user_token\"}" 2>/dev/null || echo '{}')

        err=$(extract_error "$result")
        if [ "$err" = "team already exists" ]; then
            warn "Team '$team_slug' already exists."
            read -r -p "  Join it instead? (y/n): " yn
            if [[ "$yn" =~ ^[Yy] ]]; then
                choice="2"
                break
            fi
            continue
        elif [ -n "$err" ]; then
            fail "$err"
            continue
        fi

        info "Team created"
        break
    done

    if [ "$choice" = "1" ]; then
        mkdir -p "$HACKATHON_DIR"
        if [ -d "$HACKATHON_DIR/$team_slug" ]; then
            rm -rf "$HACKATHON_DIR/$team_slug"
        fi
        if ! git clone "$repo_url_base/$team_slug.git" "$HACKATHON_DIR/$team_slug" 2>&1; then
            fail "Could not clone the new repo. Contact a hackathon organizer."
            exit 1
        fi

        cd "$HACKATHON_DIR/$team_slug"
        # Wire pre-commit hook directly (we no longer rely on npm's `prepare`
        # lifecycle script for this — see --ignore-scripts below).
        git config core.hooksPath .githooks 2>/dev/null || true
        write_claude_settings "$HACKATHON_DIR/$team_slug"
        echo "  Installing dependencies (takes a moment)..."
        # --ignore-scripts: refuse to run any package's lifecycle scripts
        # (preinstall/install/postinstall/prepare). A malicious commit by an
        # attacker who has joined the team can otherwise inject RCE here.
        npm install --silent --ignore-scripts 2>/dev/null || warn "npm install had warnings (usually fine)"
        info "Ready"
    fi
fi

# --- Join existing team ---

if [ "$choice" = "2" ]; then
    if [ -z "$team_slug" ]; then
        echo ""
        teams_json=$(curl -sf -H "Authorization: token $user_token" "$PROVISIONER/teams" 2>/dev/null || echo '{"teams":[]}')
        teams=$(node -e 'try{const o=JSON.parse(process.argv[1]);(o.teams||[]).forEach(t=>console.log(t))}catch{}' -- "$teams_json" 2>/dev/null || echo "")

        if [ -z "$teams" ]; then
            fail "No teams exist yet. Choose option 1 to start one."
            exit 1
        fi

        echo -e "  ${BOLD}Available teams:${NC}"
        echo "$teams" | while read -r t; do echo "    - $t"; done
        echo ""

        while true; do
            read -r -p "  Team to join: " raw_name
            team_slug=$(slugify "$raw_name")
            echo "$teams" | grep -qx "$team_slug" && break
            fail "Team '$team_slug' not found. Try again."
        done
    fi

    step "Joining team '$team_slug'..."

    join_resp=$(curl -s -X POST "$PROVISIONER/join-team" \
        -H "Content-Type: application/json" \
        -d "{\"team\": \"$team_slug\", \"username\": \"$username\", \"token\": \"$user_token\"}" 2>/dev/null || echo '{}')
    join_err=$(extract_error "$join_resp")
    if [ -n "$join_err" ]; then
        fail "$join_err"
        exit 1
    fi

    info "Added to team"

    mkdir -p "$HACKATHON_DIR"
    if [ -d "$HACKATHON_DIR/$team_slug" ]; then
        warn "Directory exists — pulling latest..."
        cd "$HACKATHON_DIR/$team_slug"
        # Update remote URL with fresh creds before pulling
        git remote set-url origin "$repo_url_base/$team_slug.git" 2>/dev/null || true
        git pull --rebase origin main 2>/dev/null || true
        # Idempotent: ensure pre-commit hook is wired even on re-runs of
        # setup.sh against a directory that pre-dates this fix.
        git config core.hooksPath .githooks 2>/dev/null || true
        write_claude_settings "$HACKATHON_DIR/$team_slug"
    else
        if ! git clone "$repo_url_base/$team_slug.git" "$HACKATHON_DIR/$team_slug" 2>&1; then
            fail "Could not clone the repo. Contact a hackathon organizer."
            exit 1
        fi
        cd "$HACKATHON_DIR/$team_slug"
        git config core.hooksPath .githooks 2>/dev/null || true
        write_claude_settings "$HACKATHON_DIR/$team_slug"
        echo "  Installing dependencies (takes a moment)..."
        # --ignore-scripts blocks every package's lifecycle scripts. A
        # teammate's malicious commit can otherwise inject RCE on first
        # install.
        npm install --silent --ignore-scripts 2>/dev/null || warn "npm install had warnings (usually fine)"
    fi

    info "Ready"
fi

# --- Done ---

echo ""
echo -e "${GREEN}${BOLD}========================================${NC}"
echo -e "${GREEN}${BOLD}   You're all set!${NC}"
echo -e "${GREEN}${BOLD}========================================${NC}"
echo ""
echo -e "  ${BOLD}Team:${NC}    $team_slug"
echo -e "  ${BOLD}Project:${NC} $HACKATHON_DIR/$team_slug"
echo ""
echo -e "${BOLD}Next steps — copy and paste each command into this Terminal window:${NC}"
echo ""

step_num=1

if ! command -v claude &>/dev/null; then
    echo -e "  ${BOLD}$step_num.${NC} Install Claude Code (takes ~30 seconds):"
    echo ""
    echo -e "     ${BLUE}curl -fsSL https://claude.ai/install.sh | bash${NC}"
    echo ""
    step_num=$((step_num + 1))
fi

echo -e "  ${BOLD}$step_num.${NC} Go to your project folder:"
echo ""
echo -e "     ${BLUE}cd $HACKATHON_DIR/$team_slug${NC}"
echo ""
step_num=$((step_num + 1))

echo -e "  ${BOLD}$step_num.${NC} Start Claude Code:"
echo ""
echo -e "     ${BLUE}claude${NC}"
echo ""
step_num=$((step_num + 1))

echo -e "  ${BOLD}$step_num.${NC} Tell Claude what you want to build! Try something like:"
echo ""
echo -e "     ${BLUE}I want to build a dashboard for tracking onboarding — make it look like Bubble${NC}"
echo ""
echo -e "     Other useful things to say to Claude:"
echo -e "       \"deploy this\"                   - get a shareable link"
echo -e "       \"save my work\"                  - commit & push"
echo -e "       \"get my teammate's changes\"     - pull the latest from teammates"
echo ""
echo -e "  ${YELLOW}Stuck? Ask a hackathon organizer or post in #hackathon on Slack.${NC}"
echo ""
