#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Bubble Hackathon 2026 — Team Setup
#
# Run this with:
#   bash <(curl -fsSL https://raw.githubusercontent.com/bubble-hackathon-2026/setup/main/setup.sh)
# ============================================================================

ORG="bubble-hackathon-2026"
TEMPLATE_REPO="_template"
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

check "Git"        git  "Run: xcode-select --install"
check "Node.js"    node "Install from https://nodejs.org (LTS)"
check "GitHub CLI" gh   "Run: brew install gh   (or https://cli.github.com)"

if command -v claude &>/dev/null; then
    info "Claude Code"
else
    warn "Claude Code not found — you can install it after setup:"
    echo -e "       ${BLUE}npm install -g @anthropic-ai/claude-code${NC}"
fi

if [ "$missing" -eq 1 ]; then
    echo ""
    echo -e "${RED}Install the missing items above, then re-run this script.${NC}"
    exit 1
fi

# --- GitHub auth ---

step "Checking GitHub login..."

if gh auth status &>/dev/null 2>&1; then
    gh_user=$(gh api user --jq '.login' 2>/dev/null)
    info "Logged in as ${BOLD}$gh_user${NC}"
else
    warn "Not logged in. A browser window will open — sign in to GitHub and authorize the CLI."
    echo ""
    gh auth login --web
    gh_user=$(gh api user --jq '.login' 2>/dev/null)
    info "Logged in as ${BOLD}$gh_user${NC}"
fi

# --- Org membership ---

step "Checking hackathon org access..."

in_org=false
if gh api "orgs/$ORG/members/$gh_user" --silent &>/dev/null 2>&1; then
    in_org=true
fi

if [ "$in_org" = false ]; then
    # Try to accept a pending invite
    state=$(gh api "user/memberships/orgs/$ORG" --jq '.state' 2>/dev/null || echo "none")
    if [ "$state" = "pending" ]; then
        warn "You have a pending invite — accepting it now..."
        gh api -X PATCH "user/memberships/orgs/$ORG" -f state=active --silent &>/dev/null
        in_org=true
        info "Invite accepted!"
    fi
fi

if [ "$in_org" = false ]; then
    fail "You're not a member of the ${BOLD}$ORG${NC} GitHub org."
    echo ""
    echo "  Ask a hackathon organizer to invite your GitHub username: ${BOLD}$gh_user${NC}"
    echo "  Then re-run this script."
    exit 1
fi

info "You're a member of $ORG"

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

        if gh repo view "$ORG/$team_slug" &>/dev/null 2>&1; then
            warn "Team '$team_slug' already exists."
            read -r -p "  Join it instead? (y/n): " yn
            if [[ "$yn" =~ ^[Yy] ]]; then
                choice="2"  # fall through to join
                break
            fi
            continue
        fi

        break
    done

    if [ "$choice" = "1" ]; then
        step "Creating team '$team_slug'..."

        mkdir -p "$HACKATHON_DIR"

        # Remove stale local directory from a previous failed attempt
        if [ -d "$HACKATHON_DIR/$team_slug" ]; then
            warn "Removing stale local directory from a previous attempt..."
            rm -rf "$HACKATHON_DIR/$team_slug"
        fi

        # Create repo from template and clone
        (cd "$HACKATHON_DIR" && gh repo create "$ORG/$team_slug" \
            --template "$ORG/$TEMPLATE_REPO" \
            --private \
            --clone 2>/dev/null)

        info "GitHub repo created: $ORG/$team_slug"

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
        teams=$(gh repo list "$ORG" --limit 100 --json name --jq '.[].name' 2>/dev/null \
            | grep -v '^_\|^setup$' | sort || true)

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

            if gh repo view "$ORG/$team_slug" &>/dev/null 2>&1; then
                break
            fi
            fail "Team '$team_slug' not found. Try again (see list above)."
        done
    fi

    step "Joining team '$team_slug'..."

    mkdir -p "$HACKATHON_DIR"

    if [ -d "$HACKATHON_DIR/$team_slug" ]; then
        warn "Directory exists — pulling latest changes..."
        cd "$HACKATHON_DIR/$team_slug"
        git pull --rebase origin main 2>/dev/null || true
    else
        (cd "$HACKATHON_DIR" && gh repo clone "$ORG/$team_slug" 2>/dev/null)
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
echo -e "    \"save my work\"                 — commit & push to GitHub"
echo -e "    \"get my teammate's changes\"    — pull latest"
echo ""
