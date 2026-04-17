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

# Git — comes with Xcode CLT on macOS
if command -v git &>/dev/null; then
    info "Git"
else
    warn "Git not found — installing Xcode Command Line Tools..."
    echo "  A dialog may appear. Click 'Install' and wait for it to finish."
    xcode-select --install 2>/dev/null || true
    echo ""
    echo -e "  Press Enter once the installation is complete..."
    read -r
    if command -v git &>/dev/null; then
        info "Git installed"
    else
        fail "Git still not found. Restart your terminal and re-run this script."
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
    echo -e "       ${BLUE}npm install -g @anthropic-ai/claude-code${NC}"
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

code_result=$(curl -s -X POST "$PROVISIONER/request-code" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"$user_email\"}" 2>/dev/null || echo '{"error":"cannot reach server"}')

code_error=$(echo "$code_result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('error',''))" 2>/dev/null || echo "parse error")
if [ -n "$code_error" ]; then
    fail "$code_error"
    exit 1
fi

info "Check Slack — we just sent you a DM with a 6-digit code"
echo ""
read -r -p "  Enter the code: " verify_code

# --- Create account (provisioner verifies the code) ---

step "Setting up your account..."

provision_result=$(curl -s -X POST "$PROVISIONER/provision" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"$user_name\", \"email\": \"$user_email\", \"code\": \"$verify_code\"}" 2>/dev/null || echo '{"error":"cannot reach server"}')

# Check for errors
error=$(echo "$provision_result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('error',''))" 2>/dev/null || echo "parse error")
if [ -n "$error" ]; then
    fail "$error"
    exit 1
fi

username=$(echo "$provision_result" | python3 -c "import sys,json; print(json.load(sys.stdin)['username'])" 2>/dev/null)
user_token=$(echo "$provision_result" | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])" 2>/dev/null)

if [ -z "$user_token" ]; then
    fail "Account setup failed. Contact a hackathon organizer."
    exit 1
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
            -d "{\"team\": \"$team_slug\", \"username\": \"$username\"}" 2>/dev/null || echo '{}')

        err=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('error',''))" 2>/dev/null || echo "")
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
        write_claude_settings "$HACKATHON_DIR/$team_slug"
        echo "  Installing dependencies (takes a moment)..."
        npm install --silent 2>/dev/null || warn "npm install had warnings (usually fine)"
        info "Ready"
    fi
fi

# --- Join existing team ---

if [ "$choice" = "2" ]; then
    if [ -z "$team_slug" ]; then
        echo ""
        teams_json=$(curl -sf "$PROVISIONER/teams" 2>/dev/null || echo '{"teams":[]}')
        teams=$(echo "$teams_json" | python3 -c "
import sys, json
for t in json.load(sys.stdin).get('teams', []):
    print(t)
" 2>/dev/null || echo "")

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

    curl -s -X POST "$PROVISIONER/join-team" \
        -H "Content-Type: application/json" \
        -d "{\"team\": \"$team_slug\", \"username\": \"$username\"}" >/dev/null 2>&1

    info "Added to team"

    mkdir -p "$HACKATHON_DIR"
    if [ -d "$HACKATHON_DIR/$team_slug" ]; then
        warn "Directory exists — pulling latest..."
        cd "$HACKATHON_DIR/$team_slug"
        # Update remote URL with fresh creds before pulling
        git remote set-url origin "$repo_url_base/$team_slug.git" 2>/dev/null || true
        git pull --rebase origin main 2>/dev/null || true
        write_claude_settings "$HACKATHON_DIR/$team_slug"
    else
        if ! git clone "$repo_url_base/$team_slug.git" "$HACKATHON_DIR/$team_slug" 2>&1; then
            fail "Could not clone the repo. Contact a hackathon organizer."
            exit 1
        fi
        cd "$HACKATHON_DIR/$team_slug"
        write_claude_settings "$HACKATHON_DIR/$team_slug"
        echo "  Installing dependencies (takes a moment)..."
        npm install --silent 2>/dev/null || warn "npm install had warnings (usually fine)"
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
    echo -e "     ${BLUE}npm install -g @anthropic-ai/claude-code${NC}"
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
