#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Bubble Hackathon 2026 — Teardown
#
# Archives repos locally (optional), then destroys the Gitea server.
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$REPO_ROOT/config.sh"

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${BOLD}Bubble Hackathon 2026 — Teardown${NC}"
echo ""

if [ -z "${GITEA_URL:-}" ]; then
    echo "No Gitea server configured (config.sh is empty). Nothing to tear down."
    exit 0
fi

SERVER_IP=$(echo "$GITEA_URL" | sed 's|http[s]*://||' | cut -d: -f1)

# --- List repos ---

repos=$(curl -sf "$GITEA_URL/api/v1/orgs/$GITEA_ORG/repos?limit=100" \
    -H "Authorization: token $GITEA_ADMIN_TOKEN" 2>/dev/null \
    | python3 -c "
import sys, json
repos = json.load(sys.stdin)
for r in sorted(repos, key=lambda x: x['name']):
    print(r['name'])
" 2>/dev/null || echo "")

if [ -n "$repos" ]; then
    count=$(echo "$repos" | wc -l | xargs)
    echo "Found $count repo(s) on the Gitea server:"
    echo "$repos" | while read -r r; do echo "  - $r"; done
    echo ""
else
    echo "No repos found on the server."
    echo ""
fi

# --- Archive option ---

read -r -p "Download an archive of all repos before destroying the server? (y/n): " archive
if [[ "$archive" =~ ^[Yy] ]]; then
    archive_dir="$HOME/hackathon-archive-$(date +%Y%m%d)"
    mkdir -p "$archive_dir"
    echo "Archiving to $archive_dir..."

    if [ -n "$repos" ]; then
        echo "$repos" | while read -r repo; do
            echo -n "  Cloning $repo... "
            git clone "$GITEA_URL/$GITEA_ORG/$repo.git" "$archive_dir/$repo" --quiet 2>/dev/null && echo "done" || echo "failed"
        done
    fi
    echo ""
    echo -e "${GREEN}Archive saved to: $archive_dir${NC}"
    echo ""
fi

# --- Confirm destruction ---

echo -e "${RED}${BOLD}This will destroy the Gitea server at $GITEA_URL${NC}"
echo -e "${RED}${BOLD}All repositories, accounts, and data will be permanently deleted.${NC}"
echo ""
read -r -p "Type 'destroy' to confirm: " confirm

if [ "$confirm" != "destroy" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Destroying Gitea server..."

# Stop and remove containers + volumes
ssh -o StrictHostKeyChecking=no "root@$SERVER_IP" "
    cd ~ && docker compose down -v 2>&1 || true
    docker system prune -af 2>&1 || true
" 2>/dev/null

echo -e "${GREEN}Gitea server destroyed.${NC}"
echo ""
echo "Remaining cleanup:"
echo "  - Delete the VM ($SERVER_IP) from your cloud provider's dashboard"
echo "  - Remove local project files: rm -rf \$HOME/hackathon"
echo "  - Optionally delete the GitHub setup repo:"
echo "    gh repo delete $GITHUB_ORG/$GITHUB_SETUP_REPO --yes"
echo "    (then delete the GitHub org at github.com/organizations/$GITHUB_ORG/settings/profile)"
echo ""
