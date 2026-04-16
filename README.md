# Bubble Hackathon 2026

## Quick Start

Open your terminal and run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/bubble-hackathon-2026/setup/main/setup.sh)
```

This walks you through creating or joining a hackathon team.

### Prerequisites

Install these before running the setup script (one time):

1. **Node.js** — Download from [nodejs.org](https://nodejs.org/) (LTS version)
2. **GitHub CLI** — Run `brew install gh` in your terminal
3. **Claude Code** — Run `npm install -g @anthropic-ai/claude-code` in your terminal

### What the Setup Does

1. Checks your tools are installed
2. Logs you into GitHub (opens a browser window)
3. Lets you create a new team or join an existing one
4. Clones your team's project to `~/hackathon/<team-name>/`
5. Installs dependencies

After setup, `cd` into your project and run `claude` to start building!

### Talking to Claude

Once you're in Claude Code, just talk naturally:

- **"I want to build ..."** — describe your idea and Claude starts coding
- **"deploy this"** — get a shareable link (uses Vercel, free)
- **"save my work"** — commit and push your changes
- **"get my teammate's changes"** — pull the latest code
- **"make it look like Bubble"** — Claude uses the design reference in the project

---

## Admin Guide

### Architecture

- **GitHub org** (`bubble-hackathon-2026`): Free org, separate from Bubble production. One private repo per team, created from a template.
- **Template repo** (`_template`): Next.js + Tailwind starter with CLAUDE.md that makes Claude Code handle git, deployment, and collaboration invisibly.
- **This repo** (`setup`): Public. Hosts the setup script and all admin tooling.
- **Hosting**: Vercel free tier. Teams deploy via `npx vercel` (Claude handles it).

### Initial Setup

1. Create the GitHub org at github.com/organizations/plan (free plan, named `bubble-hackathon-2026`)
2. Ensure gh CLI has admin scope: `gh auth refresh -h github.com -s admin:org`
3. Clone this repo and run: `bash admin/bootstrap.sh`

### Invite Participants

```bash
# By GitHub username
bash admin/invite-users.sh octocat janedoe bobsmith

# From a file (one username or email per line)
bash admin/invite-users.sh --from-file participants.txt
```

Users without GitHub accounts need to create one at github.com first.

### Update Bubble Design Context

Add screenshots and design tokens to `template-overlay/context/`:
- `context/bubble-overview.md` — Design tokens, colors, fonts, patterns
- `context/screenshots/` — Bubble UI screenshots

Then re-run `bash admin/bootstrap.sh` to update the template. Only affects newly created teams.

### Teardown (post-hackathon)

```bash
bash admin/teardown.sh
```

Archives repos locally (optional), then deletes them. Delete the org via GitHub settings. Total: ~5 minutes.

### Cost

$0. GitHub Free org + Vercel free tier. Nothing to cancel.

### File Structure

```
├── setup.sh                  # User-facing setup script (curl target)
├── config.sh                 # Shared config (org name, etc.)
├── admin/
│   ├── bootstrap.sh          # Create org repos + config
│   ├── invite-users.sh       # Invite users to org
│   └── teardown.sh           # Post-hackathon cleanup
└── template-overlay/
    ├── CLAUDE.md              # Claude Code instructions (the key file)
    └── context/
        ├── README.md          # Guide for contributors
        ├── bubble-overview.md # Product context + design tokens
        └── screenshots/       # Bubble UI screenshots
```
