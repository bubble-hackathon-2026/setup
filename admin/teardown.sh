#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Bubble Hackathon 2026 — Teardown
#
# Deletes all hackathon repos and optionally the org.
# Run after the hackathon to clean up.
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/config.sh"

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${BOLD}Bubble Hackathon 2026 — Teardown${NC}"
echo ""

# List all repos
repos=$(gh repo list "$HACKATHON_ORG" --limit 200 --json name --jq '.[].name' 2>/dev/null | sort)

if [ -z "$repos" ]; then
    echo "No repos found in $HACKATHON_ORG. Nothing to clean up."
    exit 0
fi

count=$(echo "$repos" | wc -l | xargs)
echo "Found $count repo(s) in $HACKATHON_ORG:"
echo "$repos" | while read -r r; do echo "  - $r"; done
echo ""

# --- Archive option ---

read -r -p "Download an archive of all repos before deleting? (y/n): " archive
if [[ "$archive" =~ ^[Yy] ]]; then
    archive_dir="$HOME/hackathon-archive-$(date +%Y%m%d)"
    mkdir -p "$archive_dir"
    echo "Archiving to $archive_dir..."

    echo "$repos" | while read -r repo; do
        echo -n "  Cloning $repo... "
        gh repo clone "$HACKATHON_ORG/$repo" "$archive_dir/$repo" -- --quiet 2>/dev/null && echo "done" || echo "failed"
    done
    echo ""
    echo -e "${GREEN}Archive saved to: $archive_dir${NC}"
    echo ""
fi

# --- Confirm deletion ---

echo -e "${RED}${BOLD}This will permanently delete all $count repos in $HACKATHON_ORG.${NC}"
read -r -p "Type the org name to confirm: " confirm

if [ "$confirm" != "$HACKATHON_ORG" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Deleting repos..."

echo "$repos" | while read -r repo; do
    echo -n "  Deleting $HACKATHON_ORG/$repo... "
    gh repo delete "$HACKATHON_ORG/$repo" --yes 2>/dev/null && echo "done" || echo "failed"
done

echo ""
echo -e "${GREEN}All repos deleted.${NC}"
echo ""
echo "To delete the org itself, go to:"
echo "  https://github.com/organizations/$HACKATHON_ORG/settings/profile"
echo "  (scroll to bottom -> Delete this organization)"
echo ""
echo "To remove local project files:"
echo "  rm -rf $HACKATHON_DIR"
echo ""
