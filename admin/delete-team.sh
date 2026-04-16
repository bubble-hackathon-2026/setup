#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Delete a hackathon team — removes the Gitea repo, the access team,
# and the local clone. Useful for cleaning up test teams.
#
# Usage:
#   bash admin/delete-team.sh team-name
#   bash admin/delete-team.sh team-name --yes   # skip confirmation
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$REPO_ROOT/config.sh"

[ -f "$REPO_ROOT/.admin-credentials" ] || { echo "Missing .admin-credentials — run bootstrap first."; exit 1; }
source "$REPO_ROOT/.admin-credentials"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TEAM="${1:-}"
SKIP_CONFIRM=false
[ "${2:-}" = "--yes" ] && SKIP_CONFIRM=true

if [ -z "$TEAM" ]; then
    echo "Usage: bash admin/delete-team.sh TEAM_NAME [--yes]"
    echo ""
    echo "Available teams:"
    curl -sf "$GITEA_URL/api/v1/orgs/$GITEA_ORG/repos?limit=100" \
        -H "Authorization: token $ADMIN_TOKEN" 2>/dev/null \
        | python3 -c "
import sys, json
for r in sorted(json.load(sys.stdin), key=lambda x: x['name']):
    if not r['name'].startswith('_'):
        print(f\"  - {r['name']}\")
" 2>/dev/null || echo "  (could not list)"
    exit 1
fi

# Check if repo exists
if ! curl -sf "$GITEA_URL/api/v1/repos/$GITEA_ORG/$TEAM" \
    -H "Authorization: token $ADMIN_TOKEN" &>/dev/null; then
    echo -e "${YELLOW}Team '$TEAM' not found on the server.${NC}"
    # Still try to clean up local dir
    if [ -d "$HOME/hackathon/$TEAM" ]; then
        echo "Local directory exists at $HOME/hackathon/$TEAM"
        read -r -p "Remove it? (y/n): " yn
        [[ "$yn" =~ ^[Yy] ]] && rm -rf "$HOME/hackathon/$TEAM" && echo "Removed."
    fi
    exit 0
fi

# Confirm
if [ "$SKIP_CONFIRM" = false ]; then
    echo -e "${RED}This will permanently delete:${NC}"
    echo "  - Repo: $GITEA_URL/$GITEA_ORG/$TEAM"
    echo "  - Gitea team: team-$TEAM"
    [ -d "$HOME/hackathon/$TEAM" ] && echo "  - Local directory: $HOME/hackathon/$TEAM"
    echo ""
    read -r -p "Type the team name to confirm: " confirm
    if [ "$confirm" != "$TEAM" ]; then
        echo "Aborted."
        exit 1
    fi
fi

# Delete the repo
echo -n "Deleting repo... "
if curl -sf -X DELETE "$GITEA_URL/api/v1/repos/$GITEA_ORG/$TEAM" \
    -H "Authorization: token $ADMIN_TOKEN" &>/dev/null; then
    echo -e "${GREEN}done${NC}"
else
    echo -e "${RED}failed${NC}"
fi

# Find and delete the Gitea team
team_id=$(curl -sf "$GITEA_URL/api/v1/orgs/$GITEA_ORG/teams" \
    -H "Authorization: token $ADMIN_TOKEN" 2>/dev/null \
    | python3 -c "
import sys, json
for t in json.load(sys.stdin):
    if t['name'] == 'team-$TEAM':
        print(t['id'])
        break
" 2>/dev/null || echo "")

if [ -n "$team_id" ]; then
    echo -n "Deleting Gitea team... "
    if curl -sf -X DELETE "$GITEA_URL/api/v1/teams/$team_id" \
        -H "Authorization: token $ADMIN_TOKEN" &>/dev/null; then
        echo -e "${GREEN}done${NC}"
    else
        echo -e "${RED}failed${NC}"
    fi
fi

# Remove local directory
if [ -d "$HOME/hackathon/$TEAM" ]; then
    echo -n "Removing local directory... "
    rm -rf "$HOME/hackathon/$TEAM"
    echo -e "${GREEN}done${NC}"
fi

echo ""
echo -e "${GREEN}Team '$TEAM' deleted.${NC}"
