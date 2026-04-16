#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Invite users to the hackathon GitHub org
#
# Usage:
#   bash invite-users.sh username1 username2 ...
#   bash invite-users.sh --from-file users.txt
#
# users.txt should have one GitHub username or email per line.
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/config.sh"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ $# -eq 0 ]; then
    echo "Usage: bash invite-users.sh <username1> [username2] ..."
    echo "       bash invite-users.sh --from-file <file>"
    echo ""
    echo "Each argument is a GitHub username or email address."
    exit 1
fi

users=()

if [ "$1" = "--from-file" ]; then
    if [ -z "${2:-}" ] || [ ! -f "$2" ]; then
        echo "File not found: ${2:-<none>}"
        exit 1
    fi
    while IFS= read -r line; do
        line=$(echo "$line" | xargs)  # trim whitespace
        [ -z "$line" ] && continue
        [[ "$line" =~ ^# ]] && continue  # skip comments
        users+=("$line")
    done < "$2"
else
    users=("$@")
fi

echo "Inviting ${#users[@]} user(s) to $HACKATHON_ORG..."
echo ""

success=0
failed=0

for user in "${users[@]}"; do
    # Determine if it's an email or username
    if [[ "$user" == *@* ]]; then
        result=$(gh api -X POST "orgs/$HACKATHON_ORG/invitations" \
            -f email="$user" \
            -f role=direct_member \
            --jq '.id' 2>&1) || true
    else
        # Get user ID first
        user_id=$(gh api "users/$user" --jq '.id' 2>/dev/null || echo "")
        if [ -z "$user_id" ]; then
            echo -e "  ${RED}x${NC} $user — GitHub user not found"
            ((failed++))
            continue
        fi
        result=$(gh api -X POST "orgs/$HACKATHON_ORG/invitations" \
            -F invitee_id="$user_id" \
            -f role=direct_member \
            --jq '.id' 2>&1) || true
    fi

    if [[ "$result" =~ ^[0-9]+$ ]]; then
        echo -e "  ${GREEN}+${NC} $user — invited"
        ((success++))
    elif echo "$result" | grep -qi "already a member"; then
        echo -e "  ${YELLOW}!${NC} $user — already a member"
        ((success++))
    elif echo "$result" | grep -qi "already invited"; then
        echo -e "  ${YELLOW}!${NC} $user — already invited (pending)"
        ((success++))
    else
        echo -e "  ${RED}x${NC} $user — failed: $result"
        ((failed++))
    fi
done

echo ""
echo "Done. $success succeeded, $failed failed."
