#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Bubble Hackathon 2026 — Team Setup
#
# Run this with:
#   bash <(curl -fsSL https://raw.githubusercontent.com/bubble-hackathon-2026/setup/main/setup.sh)
#
# The only prerequisite is Claude Code. Everything else is auto-installed.
# ============================================================================

# --- Load config (local file or fetch from GitHub) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null)" && pwd 2>/dev/null || echo ".")"
if [ -f "$SCRIPT_DIR/config.sh" ]; then
    source "$SCRIPT_DIR/config.sh"
else
    eval "$(curl -fsSL "https://raw.githubusercontent.com/bubble-hackathon-2026/setup/main/config.sh" 2>/dev/null)"
fi

if [ -z "${GITEA_URL:-}" ]; then
    echo "Error: Hackathon server not configured yet. Ask a hackathon organizer to run bootstrap first."
    exit 1
fi

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

# --- Prerequisites: auto-install what's missing ---

step "Checking prerequisites..."

# Git — comes with Xcode CLT on macOS
if command -v git &>/dev/null; then
    info "Git"
else
    warn "Git not found — installing Xcode Command Line Tools..."
    echo "  A dialog may appear. Click 'Install' and wait for it to finish."
    xcode-select --install 2>/dev/null || true
    echo ""
    echo -e "  ${BOLD}Press Enter once the installation is complete...${NC}"
    read -r
    if command -v git &>/dev/null; then
        info "Git installed"
    else
        fail "Git still not found. Please restart your terminal and re-run this script."
        exit 1
    fi
fi

# Node.js — needed for the project (npm install, npm run dev, deploy)
if command -v node &>/dev/null; then
    info "Node.js ($(node --version))"
else
    warn "Node.js not found — installing..."
    echo "  You may be asked for your computer password."
    NODE_PKG_URL="https://nodejs.org/dist/v22.15.0/node-v22.15.0.pkg"
    curl -fsSL "$NODE_PKG_URL" -o /tmp/node-installer.pkg
    sudo installer -pkg /tmp/node-installer.pkg -target / 2>/dev/null
    rm -f /tmp/node-installer.pkg
    # Add to PATH for this session (installer puts it in /usr/local/bin)
    export PATH="/usr/local/bin:$PATH"
    if command -v node &>/dev/null; then
        info "Node.js installed ($(node --version))"
    else
        fail "Node.js installation failed. Install manually from https://nodejs.org and re-run."
        exit 1
    fi
fi

# Claude Code — check but don't block (they can install after)
if command -v claude &>/dev/null; then
    info "Claude Code"
else
    warn "Claude Code not found — install it after setup:"
    echo -e "       ${BLUE}npm install -g @anthropic-ai/claude-code${NC}"
fi

# --- Check Gitea server ---

step "Connecting to hackathon server..."

if ! curl -sf "$GITEA_URL/api/v1/version" &>/dev/null; then
    fail "Cannot reach the hackathon server at $GITEA_URL"
    echo "  Check your internet connection. If the problem persists, contact a hackathon organizer."
    exit 1
fi
info "Server reachable"

# Fetch the admin token from the Gitea server (NOT stored in this script)
GITEA_ADMIN_TOKEN=$(curl -sf "$GITEA_URL/$GITEA_ORG/_config/raw/branch/main/token" 2>/dev/null || echo "")
if [ -z "$GITEA_ADMIN_TOKEN" ]; then
    fail "Could not fetch server config. Contact a hackathon organizer."
    exit 1
fi

# --- Identify the user ---

step "Who are you?"
echo ""

read -r -p "  Your name (e.g., Jane Smith): " user_name
read -r -p "  Your @bubble.io email: " user_email

# Validate email domain
if [[ ! "$user_email" == *@bubble.io ]]; then
    fail "Please use your @bubble.io email address."
    exit 1
fi

# Derive a username from email (part before @)
username=$(echo "$user_email" | cut -d@ -f1 | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')

# --- Create or get Gitea account ---

step "Setting up your account..."

user_exists=$(curl -sf "$GITEA_URL/api/v1/users/$username" \
    -H "Authorization: token $GITEA_ADMIN_TOKEN" 2>/dev/null \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('login',''))" 2>/dev/null || echo "")

user_password=$(openssl rand -hex 12)

if [ -z "$user_exists" ]; then
    curl -sf -X POST "$GITEA_URL/api/v1/admin/users" \
        -H "Authorization: token $GITEA_ADMIN_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"username\": \"$username\",
            \"email\": \"$user_email\",
            \"full_name\": \"$user_name\",
            \"password\": \"$user_password\",
            \"must_change_password\": false,
            \"visibility\": \"limited\"
        }" >/dev/null 2>&1
    info "Account created: $username"
else
    curl -sf -X PATCH "$GITEA_URL/api/v1/admin/users/$username" \
        -H "Authorization: token $GITEA_ADMIN_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"password\": \"$user_password\", \"must_change_password\": false}" >/dev/null 2>&1
    info "Account found: $username"
fi

# Create a personal access token
user_token=""
# Delete existing token if any, then create fresh
curl -sf -X DELETE "$GITEA_URL/api/v1/users/$username/tokens/hackathon-cli" \
    -u "$username:$user_password" >/dev/null 2>&1 || true

user_token=$(curl -sf -X POST "$GITEA_URL/api/v1/users/$username/tokens" \
    -u "$username:$user_password" \
    -H "Content-Type: application/json" \
    -d '{"name":"hackathon-cli","scopes":["all"]}' \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('sha1',''))" 2>/dev/null || echo "")

if [ -z "$user_token" ]; then
    fail "Could not create access token. Contact a hackathon organizer."
    exit 1
fi

# Configure git credentials for this server
git_credential_url=$(echo "$GITEA_URL" | sed "s|://|://$username:$user_token@|")
git config --global credential.helper store 2>/dev/null || true

cred_file="$HOME/.git-credentials"
touch "$cred_file"
server_host=$(echo "$GITEA_URL" | sed 's|http[s]*://||')
grep -v "$server_host" "$cred_file" > "${cred_file}.tmp" 2>/dev/null || true
echo "$git_credential_url" >> "${cred_file}.tmp"
mv "${cred_file}.tmp" "$cred_file"
chmod 600 "$cred_file"

git config --global user.name "$user_name" 2>/dev/null || true
git config --global user.email "$user_email" 2>/dev/null || true

info "Git credentials configured"

# Add user to hackathon org
curl -sf -X PUT "$GITEA_URL/api/v1/orgs/$GITEA_ORG/members/$username" \
    -H "Authorization: token $GITEA_ADMIN_TOKEN" >/dev/null 2>&1 || true

# --- New team or join ---

step "What would you like to do?"
echo "  1) Start a new team"
echo "  2) Join an existing team"
echo ""
read -r -p "  Enter 1 or 2: " choice

slugify() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//'
}

team_slug=""

# --- Create new team ---

if [ "$choice" = "1" ]; then
    echo ""
    while true; do
        read -r -p "  Team name: " raw_name
        team_slug=$(slugify "$raw_name")

        if [ -z "$team_slug" ]; then
            fail "Enter a name using letters, numbers, or hyphens."
            continue
        fi

        if curl -sf "$GITEA_URL/api/v1/repos/$GITEA_ORG/$team_slug" \
            -H "Authorization: token $GITEA_ADMIN_TOKEN" &>/dev/null; then
            warn "Team '$team_slug' already exists."
            read -r -p "  Join it instead? (y/n): " yn
            if [[ "$yn" =~ ^[Yy] ]]; then
                choice="2"
                break
            fi
            continue
        fi
        break
    done

    if [ "$choice" = "1" ]; then
        step "Creating team '$team_slug'..."

        # Create repo from template
        curl -sf -X POST "$GITEA_URL/api/v1/repos/$GITEA_ORG/$GITEA_TEMPLATE_REPO/generate" \
            -H "Authorization: token $GITEA_ADMIN_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{
                \"owner\": \"$GITEA_ORG\",
                \"name\": \"$team_slug\",
                \"private\": true,
                \"description\": \"Hackathon project: $raw_name\",
                \"default_branch\": \"main\"
            }" >/dev/null 2>&1

        info "Repository created"

        # Create a Gitea team for access control
        team_id=$(curl -sf -X POST "$GITEA_URL/api/v1/orgs/$GITEA_ORG/teams" \
            -H "Authorization: token $GITEA_ADMIN_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{
                \"name\": \"team-$team_slug\",
                \"permission\": \"write\",
                \"units\": [\"repo.code\",\"repo.issues\"],
                \"includes_all_repositories\": false
            }" 2>/dev/null \
            | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null || echo "")

        if [ -n "$team_id" ]; then
            curl -sf -X PUT "$GITEA_URL/api/v1/teams/$team_id/repos/$GITEA_ORG/$team_slug" \
                -H "Authorization: token $GITEA_ADMIN_TOKEN" >/dev/null 2>&1 || true
            curl -sf -X PUT "$GITEA_URL/api/v1/teams/$team_id/members/$username" \
                -H "Authorization: token $GITEA_ADMIN_TOKEN" >/dev/null 2>&1 || true
            info "Access control configured"
        fi

        # Clone
        mkdir -p "$HACKATHON_DIR"
        [ -d "$HACKATHON_DIR/$team_slug" ] && rm -rf "$HACKATHON_DIR/$team_slug"
        git clone "$GITEA_URL/$GITEA_ORG/$team_slug.git" "$HACKATHON_DIR/$team_slug" 2>/dev/null

        cd "$HACKATHON_DIR/$team_slug"
        echo "  Installing dependencies (this takes a moment)..."
        npm install --silent 2>/dev/null
        info "Dependencies installed"
    fi
fi

# --- Join existing team ---

if [ "$choice" = "2" ]; then
    if [ -z "$team_slug" ]; then
        echo ""
        teams=$(curl -sf "$GITEA_URL/api/v1/orgs/$GITEA_ORG/repos?limit=100" \
            -H "Authorization: token $GITEA_ADMIN_TOKEN" 2>/dev/null \
            | python3 -c "
import sys, json
repos = json.load(sys.stdin)
for r in sorted(repos, key=lambda x: x['name']):
    if not r['name'].startswith('_'):
        print(r['name'])
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
            if curl -sf "$GITEA_URL/api/v1/repos/$GITEA_ORG/$team_slug" \
                -H "Authorization: token $GITEA_ADMIN_TOKEN" &>/dev/null; then
                break
            fi
            fail "Team '$team_slug' not found. Try again (see list above)."
        done
    fi

    step "Joining team '$team_slug'..."

    # Add user to the team's access group
    team_id=$(curl -sf "$GITEA_URL/api/v1/orgs/$GITEA_ORG/teams" \
        -H "Authorization: token $GITEA_ADMIN_TOKEN" 2>/dev/null \
        | python3 -c "
import sys, json
for t in json.load(sys.stdin):
    if t['name'] == 'team-$team_slug':
        print(t['id'])
        break
" 2>/dev/null || echo "")

    if [ -n "$team_id" ]; then
        curl -sf -X PUT "$GITEA_URL/api/v1/teams/$team_id/members/$username" \
            -H "Authorization: token $GITEA_ADMIN_TOKEN" >/dev/null 2>&1 || true
        info "Added to team"
    fi

    mkdir -p "$HACKATHON_DIR"

    if [ -d "$HACKATHON_DIR/$team_slug" ]; then
        warn "Directory exists — pulling latest changes..."
        cd "$HACKATHON_DIR/$team_slug"
        git pull --rebase origin main 2>/dev/null || true
    else
        git clone "$GITEA_URL/$GITEA_ORG/$team_slug.git" "$HACKATHON_DIR/$team_slug" 2>/dev/null
        cd "$HACKATHON_DIR/$team_slug"
        echo "  Installing dependencies (this takes a moment)..."
        npm install --silent 2>/dev/null
    fi

    info "Project ready"
fi

# --- Success ---

echo ""
echo -e "${GREEN}${BOLD}========================================${NC}"
echo -e "${GREEN}${BOLD}   You're all set!${NC}"
echo -e "${GREEN}${BOLD}========================================${NC}"
echo ""
echo -e "  Project: ${BOLD}$HACKATHON_DIR/$team_slug${NC}"
echo ""
echo -e "  ${BOLD}To start building:${NC}"
echo -e "    cd $HACKATHON_DIR/$team_slug"
if command -v claude &>/dev/null; then
    echo -e "    claude"
else
    echo -e "    npm install -g @anthropic-ai/claude-code"
    echo -e "    claude"
fi
echo ""
echo -e "  ${BOLD}Things you can say to Claude:${NC}"
echo -e "    \"I want to build ...\"         — start building"
echo -e "    \"deploy this\"                  — get a shareable link"
echo -e "    \"save my work\"                 — commit & push"
echo -e "    \"get my teammate's changes\"    — pull latest"
echo ""
