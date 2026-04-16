#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Bubble Hackathon 2026 — Bootstrap (Gitea)
#
# Sets up a Gitea server on a remote VM, creates the template repo,
# and pushes the updated setup script to GitHub for distribution.
#
# Usage:
#   bash admin/bootstrap.sh                    # prompts for server IP
#   bash admin/bootstrap.sh 203.0.113.10       # use this IP directly
#
# Prerequisites:
#   - A Linux VM with Docker installed and SSH access as root
#     (DigitalOcean "Docker" marketplace image works great — $12/month)
#   - gh CLI authenticated (for pushing the setup script to GitHub)
#   - Port 3000 (HTTP) and 2222 (SSH) open on the VM
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

ADMIN_USER="hackathon-admin"
ADMIN_PASS=$(openssl rand -hex 16)
ADMIN_EMAIL="hackathon-admin@bubble.io"

echo ""
echo -e "${BOLD}Bubble Hackathon 2026 — Bootstrap${NC}"
echo ""

# --- Get server IP ---

SERVER_IP="${1:-}"
if [ -z "$SERVER_IP" ]; then
    echo "Enter the IP address of your server (a Linux VM with Docker installed)."
    echo "Tip: Create a DigitalOcean droplet using the 'Docker' marketplace image."
    echo ""
    read -r -p "  Server IP: " SERVER_IP
fi

if [ -z "$SERVER_IP" ]; then
    fail "Server IP is required."
fi

GITEA_URL="http://$SERVER_IP:3000"
GITEA_SSH_HOST="$SERVER_IP"
GITEA_SSH_PORT="2222"

step "Testing SSH connection to $SERVER_IP..."
if ! ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "root@$SERVER_IP" "echo ok" &>/dev/null; then
    fail "Cannot SSH to root@$SERVER_IP. Make sure the VM is running and you have SSH access."
fi
info "SSH connected"

# --- Deploy Gitea ---

step "Deploying Gitea on the server..."

# Copy docker-compose.yml
scp -o StrictHostKeyChecking=no "$SCRIPT_DIR/server/docker-compose.yml" "root@$SERVER_IP:~/docker-compose.yml" 2>/dev/null
info "Docker Compose file uploaded"

# Start Gitea
ssh -o StrictHostKeyChecking=no "root@$SERVER_IP" "
    export GITEA_URL='$GITEA_URL'
    export GITEA_DOMAIN='$SERVER_IP'
    cd ~ && docker compose up -d 2>&1 | tail -3
" 2>/dev/null
info "Gitea container started"

# Wait for Gitea to be ready
echo "  Waiting for Gitea to start..."
for i in $(seq 1 60); do
    if curl -sf "$GITEA_URL/api/v1/version" &>/dev/null; then
        break
    fi
    sleep 2
done

if ! curl -sf "$GITEA_URL/api/v1/version" &>/dev/null; then
    fail "Gitea didn't start within 120 seconds. Check: ssh root@$SERVER_IP 'docker logs gitea'"
fi
info "Gitea is running at $GITEA_URL"

# --- Create admin user ---

step "Creating admin user..."

# Create admin via Gitea CLI inside the container
ssh -o StrictHostKeyChecking=no "root@$SERVER_IP" "
    docker exec gitea gitea admin user create \
        --username '$ADMIN_USER' \
        --password '$ADMIN_PASS' \
        --email '$ADMIN_EMAIL' \
        --admin \
        --must-change-password=false \
        2>&1
" 2>/dev/null | grep -v "^$" || true
info "Admin user created: $ADMIN_USER"

# Get API token
ADMIN_TOKEN=$(curl -sf -X POST "$GITEA_URL/api/v1/users/$ADMIN_USER/tokens" \
    -u "$ADMIN_USER:$ADMIN_PASS" \
    -H "Content-Type: application/json" \
    -d '{"name":"bootstrap","scopes":["all"]}' | python3 -c "import sys,json; print(json.load(sys.stdin)['sha1'])")

if [ -z "$ADMIN_TOKEN" ]; then
    fail "Could not create admin API token."
fi
info "Admin API token generated"

# --- Create organization ---

step "Creating hackathon organization..."

curl -sf -X POST "$GITEA_URL/api/v1/orgs" \
    -H "Authorization: token $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$GITEA_ORG\",\"visibility\":\"private\",\"description\":\"Bubble Hackathon 2026\"}" \
    >/dev/null 2>&1 || true

info "Organization '$GITEA_ORG' created"

# --- Create template repo ---

step "Creating template repo..."

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"

# Scaffold Next.js project
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
mkdir -p context/screenshots
touch context/screenshots/.gitkeep
cat "$REPO_ROOT/template-overlay/.gitignore-extra" >> .gitignore

# Create .env.example
cat > .env.example << 'ENVEOF'
# Copy this file to .env.local and fill in your values.
# .env.local is gitignored — your secrets stay on your machine.
#
# Example:
# OPENAI_API_KEY=sk-...
# NEXT_PUBLIC_MAP_KEY=pk-...
ENVEOF

# Add prepare script for git hooks
node -e "
const pkg = require('./package.json');
pkg.scripts = pkg.scripts || {};
pkg.scripts.prepare = 'git config core.hooksPath .githooks 2>/dev/null || true';
require('fs').writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
"

info "Template assembled"

# Create the repo on Gitea
curl -sf -X POST "$GITEA_URL/api/v1/orgs/$GITEA_ORG/repos" \
    -H "Authorization: token $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"$GITEA_TEMPLATE_REPO\",\"private\":true,\"description\":\"Hackathon starter template\",\"template\":true,\"default_branch\":\"main\"}" \
    >/dev/null 2>&1 || true

# Push template files
git init -b main
git add -A
git commit -m "Initial hackathon template" --quiet
git remote add origin "$GITEA_URL/$GITEA_ORG/$GITEA_TEMPLATE_REPO.git"

# Use admin credentials for push
git -c "http.extraHeader=Authorization: token $ADMIN_TOKEN" push -u origin main --force 2>/dev/null

info "Template repo ready at $GITEA_URL/$GITEA_ORG/$GITEA_TEMPLATE_REPO"

# --- Update config.sh with server details ---

step "Saving configuration..."

cd "$REPO_ROOT"

cat > config.sh << CFGEOF
#!/usr/bin/env bash
# Shared configuration for hackathon tooling.
# Generated by admin/bootstrap.sh — re-run bootstrap to update.

# GitHub (hosts the setup script only)
GITHUB_ORG="$GITHUB_ORG"
GITHUB_SETUP_REPO="$GITHUB_SETUP_REPO"

# Gitea server
GITEA_URL="$GITEA_URL"
GITEA_SSH="ssh://git@$GITEA_SSH_HOST:$GITEA_SSH_PORT"
GITEA_ADMIN_TOKEN="$ADMIN_TOKEN"
GITEA_ORG="$GITEA_ORG"
GITEA_TEMPLATE_REPO="$GITEA_TEMPLATE_REPO"

# Local
HACKATHON_DIR="\$HOME/hackathon"
CFGEOF

info "config.sh updated with server details"

# --- Push setup script to GitHub ---

step "Pushing updated setup script to GitHub..."

git add -A
git diff --cached --quiet || git commit -m "Update config with Gitea server at $SERVER_IP" --quiet
git push origin main 2>/dev/null || warn "Could not push to GitHub (non-critical)"

info "Setup script updated on GitHub"

# --- Done ---

echo ""
echo -e "${GREEN}${BOLD}========================================${NC}"
echo -e "${GREEN}${BOLD}   Bootstrap complete!${NC}"
echo -e "${GREEN}${BOLD}========================================${NC}"
echo ""
echo "  Gitea:     $GITEA_URL"
echo "  Admin:     $ADMIN_USER / $ADMIN_PASS"
echo "  API token: $ADMIN_TOKEN"
echo ""
echo -e "  ${YELLOW}Save these credentials somewhere safe — they won't be shown again.${NC}"
echo ""
echo "  Share this command with participants:"
echo ""
echo -e "  ${BLUE}bash <(curl -fsSL https://raw.githubusercontent.com/$GITHUB_ORG/$GITHUB_SETUP_REPO/main/setup.sh)${NC}"
echo ""
echo "  Or if they don't want to curl, they can clone and run:"
echo -e "  ${BLUE}git clone https://github.com/$GITHUB_ORG/$GITHUB_SETUP_REPO.git && bash $GITHUB_SETUP_REPO/setup.sh${NC}"
echo ""
