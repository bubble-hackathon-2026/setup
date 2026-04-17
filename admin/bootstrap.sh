#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Bubble Hackathon 2026 — Bootstrap
#
# Sets up Gitea + provisioner on a remote VM, creates the template repo,
# and pushes the setup script to GitHub for distribution.
#
# Usage:
#   bash admin/bootstrap.sh                    # prompts for server IP
#   bash admin/bootstrap.sh 203.0.113.10       # use this IP directly
#
# Prerequisites:
#   - A Linux VM with Docker installed and SSH access as root
#     (DigitalOcean "Docker" marketplace image works — $12/month)
#   - gh CLI authenticated (for pushing setup script to GitHub)
#   - Ports 3000, 8080, and 2222 open on the VM
#
# Security model:
#   - The Gitea admin token NEVER leaves the server.
#   - A provisioner service (port 8080) handles account creation.
#   - It enforces @bubble.io email domain server-side.
#   - The server IP is NOT stored in the public GitHub repo.
#   - It's shared only via internal Slack.
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
    echo "Tip: DigitalOcean 'Docker' marketplace image, \$12/month."
    echo ""
    read -r -p "  Server IP: " SERVER_IP
fi

[ -z "$SERVER_IP" ] && fail "Server IP is required."

# --- Get Slack bot token (for email verification via DM) ---

SLACK_BOT_TOKEN="${SLACK_BOT_TOKEN:-}"
# Read from existing credentials file if present and not in env
if [ -z "$SLACK_BOT_TOKEN" ] && [ -f "$REPO_ROOT/.admin-credentials" ]; then
    SLACK_BOT_TOKEN=$(grep -E '^SLACK_BOT_TOKEN=' "$REPO_ROOT/.admin-credentials" 2>/dev/null | cut -d= -f2- || echo "")
fi

if [ -z "$SLACK_BOT_TOKEN" ]; then
    echo ""
    echo "Slack bot token needed for email verification (participants will get"
    echo "a DM with a code to prove they own their @bubble.io email)."
    echo ""
    echo "To get one: https://api.slack.com/apps -> Create New App -> From scratch"
    echo "  Workspace: bubble-app"
    echo "  Scopes (Bot Token Scopes): chat:write, users:read.email, im:write"
    echo "  Then: Install to Workspace -> copy 'Bot User OAuth Token' (starts with xoxb-)"
    echo ""
    read -r -p "  Slack bot token (xoxb-...): " SLACK_BOT_TOKEN
fi

[ -z "$SLACK_BOT_TOKEN" ] && fail "Slack bot token is required."

if [[ ! "$SLACK_BOT_TOKEN" =~ ^xoxb- ]]; then
    warn "Token doesn't start with 'xoxb-' — is that really a bot token?"
fi

GITEA_URL="http://$SERVER_IP:3000"
PROVISIONER_URL="http://$SERVER_IP:8080"

# SSH connection multiplexing — reuses one TCP connection across all commands.
# Prevents UFW's default SSH rate-limiting (6 conns per 30s) from blocking us.
SSH_CTRL="/tmp/ssh-hackathon-$$"
SSH_OPTS=(-o StrictHostKeyChecking=no -o ControlMaster=auto -o "ControlPath=$SSH_CTRL" -o ControlPersist=10m)
cleanup_ssh() { ssh "${SSH_OPTS[@]}" -O exit "root@$SERVER_IP" 2>/dev/null || true; rm -f "$SSH_CTRL"; }
trap cleanup_ssh EXIT

rssh() { ssh "${SSH_OPTS[@]}" "root@$SERVER_IP" "$@"; }
rscp() { scp "${SSH_OPTS[@]}" "$@"; }

step "Testing SSH connection to $SERVER_IP..."
if ! rssh -o ConnectTimeout=10 "echo ok" &>/dev/null; then
    fail "Cannot SSH to root@$SERVER_IP. Make sure the VM is running and you have SSH access."
fi
info "SSH connected (multiplexed)"

# --- Disable UFW SSH rate-limiting (prevents connection refused during bootstrap) ---

step "Configuring server firewall..."
rssh "command -v ufw >/dev/null && { ufw delete limit ssh 2>/dev/null; ufw allow ssh 2>/dev/null; } || true" &>/dev/null
info "Firewall configured"

# --- Upload server files ---

step "Uploading server configuration..."
rscp \
    "$SCRIPT_DIR/server/docker-compose.yml" \
    "$SCRIPT_DIR/server/provisioner.py" \
    "root@$SERVER_IP:~/"
info "Files uploaded"

# --- Start Gitea (without provisioner first — need admin token) ---

step "Starting Gitea..."

rssh "
    export GITEA_URL='$GITEA_URL'
    export GITEA_DOMAIN='$SERVER_IP'
    export ADMIN_TOKEN='placeholder'
    cd ~ && docker compose up -d gitea 2>&1 | tail -3
"

echo "  Waiting for Gitea..."
# Note: Gitea returns 403 on /api/v1/version when REQUIRE_SIGNIN_VIEW=true.
# 403 still means the server is up — we only care that it's responding.
is_up() {
    local code
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$GITEA_URL/api/v1/version" 2>/dev/null)
    # Match any 2xx/3xx/4xx response (valid HTTP reply). 000/5xx = not ready.
    [[ "$code" =~ ^[234][0-9][0-9]$ ]]
}
for _ in $(seq 1 60); do
    is_up && break
    sleep 2
done
is_up || fail "Gitea didn't start. Check: ssh root@$SERVER_IP 'docker logs gitea'"
info "Gitea running at $GITEA_URL"

# --- Create admin user + token ---

step "Creating admin user..."

# Run as 'git' user inside the container — Gitea refuses to run as root.
set +e
create_output=$(rssh "
    docker exec -u git gitea gitea admin user create \
        --username '$ADMIN_USER' \
        --password '$ADMIN_PASS' \
        --email '$ADMIN_EMAIL' \
        --admin \
        --must-change-password=false 2>&1
" 2>&1)
create_status=$?
set -e

if [ $create_status -ne 0 ] && ! echo "$create_output" | grep -qi "already exists\|successfully created\|new user"; then
    echo "$create_output"
    fail "SSH or admin creation failed (exit $create_status)"
fi

if echo "$create_output" | grep -qi "already exists"; then
    warn "Admin user already exists — will reuse"
elif echo "$create_output" | grep -qi "successfully created\|new user"; then
    info "Admin user created: $ADMIN_USER"
else
    echo "$create_output"
    fail "Admin user creation failed (see output above)"
fi

# Create admin API token
token_response=$(curl -sf -X POST "$GITEA_URL/api/v1/users/$ADMIN_USER/tokens" \
    -u "$ADMIN_USER:$ADMIN_PASS" \
    -H "Content-Type: application/json" \
    -d '{"name":"admin","scopes":["all"]}' 2>&1 || echo "")

ADMIN_TOKEN=$(echo "$token_response" | python3 -c "
import sys, json
try:
    print(json.loads(sys.stdin.read()).get('sha1', ''))
except Exception:
    pass
" 2>/dev/null)

if [ -z "$ADMIN_TOKEN" ]; then
    echo "Token API response: $token_response"
    fail "Could not create admin token. The admin user may not have the expected password."
fi
info "Admin token generated"

# --- Start provisioner with the real token ---

step "Starting provisioner service..."

rssh "
    export GITEA_URL='$GITEA_URL'
    export GITEA_DOMAIN='$SERVER_IP'
    export ADMIN_TOKEN='$ADMIN_TOKEN'
    export SLACK_BOT_TOKEN='$SLACK_BOT_TOKEN'
    cd ~ && docker compose up -d 2>&1 | tail -3
"

# Wait for provisioner
for _ in $(seq 1 30); do
    curl -sf "$PROVISIONER_URL/health" &>/dev/null && break
    sleep 1
done
curl -sf "$PROVISIONER_URL/health" &>/dev/null || fail "Provisioner didn't start."
info "Provisioner running at $PROVISIONER_URL"

# --- Create organization ---

step "Creating hackathon organization..."

curl -sf -X POST "$GITEA_URL/api/v1/orgs" \
    -H "Authorization: token $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$GITEA_ORG\",\"visibility\":\"private\"}" \
    >/dev/null 2>&1 || true

info "Organization '$GITEA_ORG' created"

# --- Create template repo ---

step "Creating template repo..."

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"

echo "  Scaffolding Next.js project (takes a moment)..."
yes "" | npx --yes create-next-app@latest hackathon-template \
    --typescript --tailwind --eslint --app --no-src-dir \
    --import-alias "@/*" --use-npm 2>/dev/null || true

[ ! -d hackathon-template ] && fail "create-next-app failed."
cd hackathon-template

# Overlay hackathon files
cp "$REPO_ROOT/template-overlay/CLAUDE.md" .
cp -r "$REPO_ROOT/template-overlay/context" .
cp -r "$REPO_ROOT/template-overlay/.githooks" .
cat "$REPO_ROOT/template-overlay/.gitignore-extra" >> .gitignore

cat > .env.example << 'ENVEOF'
# Copy this file to .env.local and fill in your values.
# .env.local is gitignored — your secrets stay on your machine.
#
# OPENAI_API_KEY=sk-...
# NEXT_PUBLIC_MAP_KEY=pk-...
ENVEOF

node -e "
const pkg = require('./package.json');
pkg.scripts = pkg.scripts || {};
pkg.scripts.prepare = 'git config core.hooksPath .githooks 2>/dev/null || true';
require('fs').writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
"

# Create repo on Gitea
curl -sf -X POST "$GITEA_URL/api/v1/orgs/$GITEA_ORG/repos" \
    -H "Authorization: token $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"$GITEA_TEMPLATE_REPO\",\"private\":true,\"template\":true,\"default_branch\":\"main\"}" \
    >/dev/null 2>&1 || true

git init -b main && git add -A && git commit -m "Initial hackathon template" --quiet
git remote add origin "$GITEA_URL/$GITEA_ORG/$GITEA_TEMPLATE_REPO.git"
git -c "http.extraHeader=Authorization: token $ADMIN_TOKEN" push -u origin main --force 2>/dev/null

info "Template repo ready"

# --- Save admin credentials locally (NOT pushed to GitHub) ---

step "Saving credentials..."

cd "$REPO_ROOT"

cat > .admin-credentials << ADMEOF
# Hackathon admin credentials — DO NOT COMMIT
# Generated $(date)
SERVER_IP=$SERVER_IP
GITEA_URL=$GITEA_URL
PROVISIONER_URL=$PROVISIONER_URL
ADMIN_USER=$ADMIN_USER
ADMIN_PASS=$ADMIN_PASS
ADMIN_TOKEN=$ADMIN_TOKEN
SLACK_BOT_TOKEN=$SLACK_BOT_TOKEN
ADMEOF
chmod 600 .admin-credentials

info "Admin credentials saved in .admin-credentials (gitignored)"

# --- Push setup script to GitHub (no secrets) ---

step "Pushing setup script to GitHub..."

git add -A
git diff --cached --quiet || git commit -m "Update setup script" --quiet
git push origin main 2>/dev/null || warn "Could not push to GitHub"

info "Setup script on GitHub (no server info — just the script)"

# --- Done ---

echo ""
echo -e "${GREEN}${BOLD}========================================${NC}"
echo -e "${GREEN}${BOLD}   Bootstrap complete!${NC}"
echo -e "${GREEN}${BOLD}========================================${NC}"
echo ""
echo "  Gitea:        $GITEA_URL"
echo "  Provisioner:  $PROVISIONER_URL"
echo "  Admin login:  $ADMIN_USER / $ADMIN_PASS"
echo ""
echo -e "  ${BOLD}Share this command in Slack:${NC}"
echo ""
echo -e "  ${BLUE}bash <(curl -fsSL https://raw.githubusercontent.com/$GITHUB_ORG/$GITHUB_SETUP_REPO/main/setup.sh) $SERVER_IP${NC}"
echo ""
echo -e "  ${BOLD}Security:${NC}"
echo "  - The admin token stays on the server (never in GitHub)"
echo "  - The server IP is only in the Slack message above"
echo "  - The provisioner enforces @bubble.io emails server-side"
echo "  - Credentials saved locally in .admin-credentials"
echo ""
