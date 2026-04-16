#!/usr/bin/env bash
# Shared configuration for hackathon tooling.
# This file is on a PUBLIC GitHub repo — no secrets, no server addresses.

# GitHub (hosts the setup script only — public, no login needed)
GITHUB_ORG="bubble-hackathon-2026"
GITHUB_SETUP_REPO="setup"

# Gitea org and template names (the server URL is passed at runtime, not stored here)
GITEA_ORG="hackathon"
GITEA_TEMPLATE_REPO="_template"

# Local
HACKATHON_DIR="$HOME/hackathon"
