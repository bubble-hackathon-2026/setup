#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Bubble Hackathon 2026 — Team Setup (Gitea)
#
# Run this with:
#   bash <(curl -fsSL https://raw.githubusercontent.com/bubble-hackathon-2026/setup/main/setup.sh)
# ============================================================================

# --- Load config (either local or fetch from GitHub) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null)" && pwd 2>/dev/null || echo ".")"
if [ -f "$SCRIPT_DIR/config.sh" ]; then
    source "$SCRIPT_DIR/config.sh"
else
    # Fetch config from GitHub when running via curl
    eval "$(curl -fsSL "https://raw.githubusercontent.com/bubble-hackathon-2026/setup/main/config.sh" 2>/dev/null)"
fi

if [ -z "${GITEA_URL:-}" ]; then
    echo "Error: Gitea server not configured. Ask a hackathon organizer to run bootstrap first."
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

# --- Prerequisites ---

step "Checking prerequisites..."

missing=0

check() {
    local label=$1 cmd=$2 help=$3
    if command -v "$cmd" &>/dev/null; then
        info "$label"
    else
        fail "$label — $help"
        missing=1
    fi
}

check "Git"     git  "Run: xcode-select --install"
check "Node.js" node "Install from https://nodejs.org (LTS)"

if command -v claude &>/dev/null; then
    info "Claude Code"
else
    warn "Claude Code not found — install it after setup:"
    echo -e "       ${BLUE}npm install -g @anthropic-ai/claude-code${NC}"
fi

if [ "$missing" -eq 1 ]; then
    echo ""
    echo -e "${RED}Install the missing items above, then re-run this script.${NC}"
    exit 1
fi

# --- Check Gitea server ---

step "Connecting to hackathon server..."

if ! curl -sf "$GITEA_URL/api/v1/version" &>/dev/null; then
    fail "Cannot reach the hackathon server at $GITEA_URL"
    echo "  Check your internet connection and try again."
    echo "  If the problem persists, contact a hackathon organizer."
    exit 1
fi
info "Server reachable"

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

# Derive a username from email (everything before @)
username=$(echo "$user_email" | cut -d@ -f1 | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')

# --- Create or get Gitea account ---

step "Setting up your account..."

# Check if user already exists
user_exists=$(curl -sf "$GITEA_URL/api/v1/users/$username" \
    -H "Authorization: token $GITEA_ADMIN_TOKEN" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('login',''))" 2>/dev/null || echo "")

if [ -z "$user_exists" ]; then
    # Create user
    user_password=$(openssl rand -hex 12)
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
    # User exists — generate a fresh password so we can get a token
    user_password=$(openssl rand -hex 12)
    curl -sf -X PATCH "$GITEA_URL/api/v1/admin/users/$username" \
        -H "Authorization: token $GITEA_ADMIN_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"password\": \"$user_password\", \"must_change_password\": false}" >/dev/null 2>&1

    info "Account found: $username"
fi

# Create a personal access token for this user
user_token=$(curl -sf -X POST "$GITEA_URL/api/v1/users/$username/tokens" \
    -u "$username:$user_password" \
    -H "Content-Type: application/json" \
    -d '{"name":"hackathon-cli","scopes":["all"]}' 2>/dev/null \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('sha1',''))" 2>/dev/null || echo "")

# If token creation failed (name conflict), delete and recreate
if [ -z "$user_token" ]; then
    curl -sf -X DELETE "$GITEA_URL/api/v1/users/$username/tokens/hackathon-cli" \
        -u "$username:$user_password" >/dev/null 2>&1 || true
    user_token=$(curl -sf -X POST "$GITEA_URL/api/v1/users/$username/tokens" \
        -u "$username:$user_password" \
        -H "Content-Type: application/json" \
        -d '{"name":"hackathon-cli","scopes":["all"]}' \
        | python3 -c "import sys,json; print(json.load(sys.stdin).get('sha1',''))" 2>/dev/null || echo "")
fi

if [ -z "$user_token" ]; then
    fail "Could not create access token. Contact a hackathon organizer."
    exit 1
fi

# Configure git credentials for this server
git_credential_url=$(echo "$GITEA_URL" | sed "s|://|://$username:$user_token@|")
git config --global credential.helper store 2>/dev/null || true

# Remove old entries for this server, add new one
cred_file="$HOME/.git-credentials"
touch "$cred_file"
grep -v "$(echo "$GITEA_URL" | sed 's|http[s]*://||')" "$cred_file" > "${cred_file}.tmp" 2>/dev/null || true
echo "$git_credential_url" >> "${cred_file}.tmp"
mv "${cred_file}.tmp" "$cred_file"
chmod 600 "$cred_file"

# Configure git identity
git config --global user.name "$user_name" 2>/dev/null || true
git config --global user.email "$user_email" 2>/dev/null || true

info "Git credentials configured"

# --- Add user to hackathon org ---

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

        # Check if repo exists
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

        # Fork from template via API
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

        # Create a team in Gitea for access control
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

        # Add repo to team
        if [ -n "$team_id" ]; then
            curl -sf -X PUT "$GITEA_URL/api/v1/teams/$team_id/repos/$GITEA_ORG/$team_slug" \
                -H "Authorization: token $GITEA_ADMIN_TOKEN" >/dev/null 2>&1 || true

            # Add user to team
            curl -sf -X PUT "$GITEA_URL/api/v1/teams/$team_id/members/$username" \
                -H "Authorization: token $GITEA_ADMIN_TOKEN" >/dev/null 2>&1 || true

            info "Access control configured"
        fi

        # Clone
        mkdir -p "$HACKATHON_DIR"
        if [ -d "$HACKATHON_DIR/$team_slug" ]; then
            rm -rf "$HACKATHON_DIR/$team_slug"
        fi
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
        # List teams
        teams=$(curl -sf "$GITEA_URL/api/v1/orgs/$GITEA_ORG/repos" \
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
teams = json.load(sys.stdin)
for t in teams:
    if t['name'] == 'team-$team_slug':
        print(t['id'])
        break
" 2>/dev/null || echo "")

    if [ -n "$team_id" ]; then
        curl -sf -X PUT "$GITEA_URL/api/v1/teams/$team_id/members/$username" \
            -H "Authorization: token $GITEA_ADMIN_TOKEN" >/dev/null 2>&1 || true
        info "Added to team access"
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
