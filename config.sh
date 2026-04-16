#!/usr/bin/env bash
# Shared configuration for hackathon tooling.
# The admin token is NOT stored here (this file is on a public GitHub repo).
# It's served from the Gitea server and fetched at runtime by setup.sh.

# GitHub (hosts the setup script only — public, no login needed)
GITHUB_ORG="bubble-hackathon-2026"
GITHUB_SETUP_REPO="setup"

# Gitea server (BOOTSTRAP fills in GITEA_URL)
GITEA_URL=""
GITEA_ORG="hackathon"
GITEA_TEMPLATE_REPO="_template"

# Local
HACKATHON_DIR="$HOME/hackathon"
