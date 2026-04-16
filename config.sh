#!/usr/bin/env bash
# Shared configuration for hackathon tooling.
# Values marked BOOTSTRAP are filled in by admin/bootstrap.sh — don't edit manually.

# GitHub (used only for hosting the setup script — public, no account needed)
GITHUB_ORG="bubble-hackathon-2026"
GITHUB_SETUP_REPO="setup"

# Gitea server (BOOTSTRAP — filled by admin/bootstrap.sh)
GITEA_URL=""
GITEA_SSH=""
GITEA_ADMIN_TOKEN=""
GITEA_ORG="hackathon"
GITEA_TEMPLATE_REPO="_template"

# Local
HACKATHON_DIR="$HOME/hackathon"
