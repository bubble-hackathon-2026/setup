#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Bubble Hackathon 2026 — Bootstrap
#
# One-time setup: creates the GitHub org's repos and configuration.
# Run from the root of the bubble-hackathon-2026/ directory.
#
# Prerequisites:
#   - gh CLI authenticated with an account that owns the org
#   - The GitHub org must already exist (create at github.com/organizations/plan)
#   - Token needs admin:org scope: gh auth refresh -h github.com -s admin:org
#
# This script:
#   1. Configures org settings (member permissions)
#   2. Creates the _template repo (Next.js + Tailwind + CLAUDE.md + context)
#   3. Pushes this entire directory to the public 'setup' repo on GitHub
#   4. Turns the local directory into a git clone of the setup repo
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$REPO_ROOT/config.sh"

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "  ${GREEN}+${NC} $1"; }
warn() { echo -e "  ${YELLOW}!${NC} $1"; }
fail() { echo -e "  ${RED}x${NC} $1"; exit 1; }
step() { echo -e "\n${BOLD}$1${NC}"; }

echo ""
echo -e "${BOLD}Bubble Hackathon 2026 — Bootstrap${NC}"
echo ""

# --- Verify org exists ---

step "Verifying GitHub org '$HACKATHON_ORG'..."
if ! gh api "orgs/$HACKATHON_ORG" --silent &>/dev/null 2>&1; then
    fail "Org '$HACKATHON_ORG' not found. Create it first at: https://github.com/organizations/plan"
fi
info "Org exists"

# --- Configure org settings ---

step "Configuring org settings..."

# Allow all members to create private repos and have write access by default
gh api -X PATCH "orgs/$HACKATHON_ORG" \
    -f default_repository_permission=write \
    -F members_can_create_private_repositories=true \
    --silent 2>/dev/null || true

info "Member permissions set (write access, can create repos)"

# --- Create template repo ---

step "Creating template repo..."

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"

# Scaffold Next.js project (pipe yes to auto-accept any unexpected prompts)
echo "  Scaffolding Next.js project (this takes a moment)..."
yes "" | npx --yes create-next-app@latest hackathon-template \
    --typescript \
    --tailwind \
    --eslint \
    --app \
    --no-src-dir \
    --import-alias "@/*" \
    --use-npm \
    2>/dev/null || true

if [ ! -d hackathon-template ]; then
    fail "create-next-app failed. Check your Node.js installation and try again."
fi
cd hackathon-template

# Overlay hackathon files
cp "$REPO_ROOT/template-overlay/CLAUDE.md" .
cp -r "$REPO_ROOT/template-overlay/context" .
cp -r "$REPO_ROOT/template-overlay/.githooks" .

# Add .gitkeep for screenshots directory
mkdir -p context/screenshots
touch context/screenshots/.gitkeep

# Append extra .gitignore entries (secrets, credentials, IDE, OS)
cat "$REPO_ROOT/template-overlay/.gitignore-extra" >> .gitignore

# Create .env.example to show the safe pattern for secrets
cat > .env.example << 'ENVEOF'
# Copy this file to .env.local and fill in your values.
# .env.local is gitignored — your secrets stay on your machine.
#
# Example:
# OPENAI_API_KEY=sk-...
# NEXT_PUBLIC_MAP_KEY=pk-...
ENVEOF

# Add "prepare" script to package.json so git hooks auto-install on npm install
node -e "
const pkg = require('./package.json');
pkg.scripts = pkg.scripts || {};
pkg.scripts.prepare = 'git config core.hooksPath .githooks 2>/dev/null || true';
require('fs').writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
"

info "Next.js + Tailwind + hackathon overlay assembled"

# Initialize git and push
git init -b main
git add -A
git commit -m "Initial hackathon template" --quiet

# Create the repo on GitHub (or update if exists)
if gh repo view "$HACKATHON_ORG/$HACKATHON_TEMPLATE_REPO" &>/dev/null 2>&1; then
    info "Template repo already exists — updating..."
    git remote add origin "https://github.com/$HACKATHON_ORG/$HACKATHON_TEMPLATE_REPO.git"
    git push --force origin main 2>/dev/null
else
    gh repo create "$HACKATHON_ORG/$HACKATHON_TEMPLATE_REPO" \
        --private \
        --source . \
        --push \
        --description "Hackathon starter template — do not edit directly" \
        2>/dev/null
fi

# Mark as template repo
gh api -X PATCH "repos/$HACKATHON_ORG/$HACKATHON_TEMPLATE_REPO" \
    -F is_template=true \
    --silent 2>/dev/null || true

info "Template repo ready: $HACKATHON_ORG/$HACKATHON_TEMPLATE_REPO"

# Restrict _template to admin-only writes (others inherit org read via default_repository_permission)
# On GitHub Free we can't use branch protection, but we can remove the default team permission
# and rely on the creator (admin) having push access.
# The org default gives write, so we override at the repo level by removing the "all members" permission.
# This isn't possible on GitHub Free without Teams — noted as a known limitation.

# --- Push this admin repo to the setup repo on GitHub ---

step "Creating setup repo (pushing admin tooling to GitHub)..."

cd "$REPO_ROOT"

# Ensure .gitkeep exists for screenshots
mkdir -p template-overlay/context/screenshots
touch template-overlay/context/screenshots/.gitkeep

# Initialize git if not already a repo
if [ ! -d .git ]; then
    git init -b main
    git add -A
    git commit -m "Hackathon admin tooling and setup script" --quiet
fi

# Create or update the remote repo
if gh repo view "$HACKATHON_ORG/$HACKATHON_SETUP_REPO" &>/dev/null 2>&1; then
    info "Setup repo already exists — updating..."

    # Ensure remote is set
    if ! git remote get-url origin &>/dev/null 2>&1; then
        git remote add origin "https://github.com/$HACKATHON_ORG/$HACKATHON_SETUP_REPO.git"
    fi

    # Commit any uncommitted changes
    git add -A
    git diff --cached --quiet || git commit -m "Update hackathon tooling" --quiet

    git push --force origin main 2>/dev/null
else
    # Stage everything and commit if needed
    git add -A
    git diff --cached --quiet || git commit -m "Hackathon admin tooling and setup script" --quiet

    gh repo create "$HACKATHON_ORG/$HACKATHON_SETUP_REPO" \
        --public \
        --source . \
        --push \
        --description "Hackathon setup — run the script to get started" \
        2>/dev/null
fi

info "Setup repo ready: $HACKATHON_ORG/$HACKATHON_SETUP_REPO (public)"
info "This directory is now a clone of the setup repo"

# --- Done ---

echo ""
echo -e "${GREEN}${BOLD}Bootstrap complete!${NC}"
echo ""
echo "  Template repo: https://github.com/$HACKATHON_ORG/$HACKATHON_TEMPLATE_REPO"
echo "  Setup repo:    https://github.com/$HACKATHON_ORG/$HACKATHON_SETUP_REPO"
echo ""
echo "  Next steps:"
echo "    1. Invite users:  bash admin/invite-users.sh user1 user2 ..."
echo "    2. Share the setup command with participants:"
echo ""
echo -e "       ${BLUE}bash <(curl -fsSL https://raw.githubusercontent.com/$HACKATHON_ORG/$HACKATHON_SETUP_REPO/main/setup.sh)${NC}"
echo ""
