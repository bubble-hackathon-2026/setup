# Bubble Hackathon 2026

## Quick Start

Open your terminal and run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/bubble-hackathon-2026/setup/main/setup.sh)
```

That's it. The script will:

1. Check your tools (Git, Node.js)
2. Ask for your name and @bubble.io email (no accounts to create!)
3. Let you create a new team or join an existing one
4. Clone your team's project and install dependencies

Then `cd` into your project and run `claude` to start building.

### Prerequisites

Install these before running the setup script (one time):

1. **Node.js** — Download from [nodejs.org](https://nodejs.org/) (LTS version)
2. **Claude Code** — Run `npm install -g @anthropic-ai/claude-code` in your terminal

That's all. No GitHub account needed.

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

- **Gitea server**: Self-hosted on a small VM ($12/month). Private git repos, per-team access control, auto-provisioned accounts via @bubble.io email. No GitHub accounts needed.
- **GitHub** (`bubble-hackathon-2026/setup`): Public repo that hosts only the setup script. Users curl from here. No login needed.
- **Template repo** (`_template` on Gitea): Next.js + Tailwind starter with CLAUDE.md and Bubble design context.
- **Hosting**: Vercel free tier. Teams deploy via `npx vercel` (Claude handles it).

### Initial Setup

1. **Create a VM** with Docker installed.
   - DigitalOcean: Create a droplet using the "Docker" marketplace image ($12/month, 1GB RAM).
   - Open ports 3000 (HTTP) and 2222 (git SSH) in the firewall.
   - Make sure you can `ssh root@<IP>`.

2. **Run bootstrap:**
   ```bash
   bash admin/bootstrap.sh <SERVER_IP>
   ```
   This deploys Gitea, creates the template repo, and pushes the setup script to GitHub.
   Save the admin credentials it prints — you'll need them for teardown.

3. **Share the setup command** in Slack:
   ```
   bash <(curl -fsSL https://raw.githubusercontent.com/bubble-hackathon-2026/setup/main/setup.sh)
   ```
   No invites needed — anyone with a @bubble.io email can self-provision.

### Security

- **Accounts**: Auto-created, restricted to @bubble.io emails. No self-registration.
- **Repos**: Private. Per-team access control (teams can only write to their own repo).
- **Secrets**: Pre-commit hook blocks commits containing API keys/tokens. CLAUDE.md instructs Claude to use `.env.local` for secrets.
- **Vercel**: Deployed prototypes are public by URL (security by obscurity). Secrets go in via `vercel env add`.
- **Server**: Temporary — destroyed after the hackathon. No persistent data.

### Update Bubble Design Context

Edit files in `template-overlay/context/`, then re-run `bash admin/bootstrap.sh <IP>` to update the template. Only affects newly created teams.

### Teardown

```bash
bash admin/teardown.sh
```

Archives repos (optional), destroys the Gitea server. Then delete the VM from your cloud dashboard. Total: ~5 minutes.

### Cost

| Item | Cost |
|------|------|
| VM (DigitalOcean 1GB) | ~$12/month |
| Vercel free tier | $0 |
| Claude Code | Existing licenses |
| **Total** | **~$12** |
