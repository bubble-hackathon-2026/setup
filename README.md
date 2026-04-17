# Bubble Hackathon 2026

## Quick Start

A hackathon organizer will share a command in Slack that looks like:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/bubble-hackathon-2026/setup/main/setup.sh) SERVER_IP
```

Paste it into your terminal. It will:
1. Install Node.js if you don't have it (may ask for your Mac password)
2. Ask for your name and @bubble.io email
3. Let you create a new team or join an existing one
4. Set up your project

**On Windows?** See [WINDOWS_SETUP.md](./WINDOWS_SETUP.md) for the PowerShell equivalent.

Then `cd ~/hackathon/<team-name>` and run `claude` to start building.

**Only prerequisite:** Install Claude Code first: `npm install -g @anthropic-ai/claude-code`
(If you don't have npm yet, run the setup command first — it installs Node.js for you — then install Claude Code.)

### Talking to Claude

- **"I want to build ..."** — describe your idea and Claude starts coding
- **"deploy this"** — get a shareable link
- **"save my work"** — commit and push
- **"get my teammate's changes"** — pull latest
- **"make it look like Bubble"** — uses the design reference in the project

---

## Admin Guide

### Security Model

- **Barrier**: You need the server IP to do anything. It's only shared in internal Slack.
- **Enforcement**: A provisioner service (port 8080) sits in front of Gitea and enforces @bubble.io emails **server-side**. The admin token never leaves the server.
- **Per-team access**: Each team gets a private repo. A Gitea team controls who can read/write it. Users can only access repos they've been added to.
- **Public GitHub repo**: Contains only the setup script. No server addresses, no tokens, no secrets.
- **Secrets in code**: Pre-commit hook blocks common credential patterns. CLAUDE.md instructs Claude to use `.env.local`.

### Architecture

```
Internet
  |
  +-- GitHub (public) -----> setup.sh (no secrets)
  |
  +-- Server (IP only in Slack)
        |
        +-- :8080  Provisioner  (enforces @bubble.io, creates accounts/teams)
        +-- :3000  Gitea        (git repos, private, per-team access)
        +-- :2222  Gitea SSH    (alternative git access)
```

### Setup

1. **Create a VM** with Docker: DigitalOcean "Docker" marketplace image ($12/month). Open ports 3000, 8080, 2222.

2. **Run bootstrap:**
   ```bash
   bash admin/bootstrap.sh SERVER_IP
   ```
   This deploys Gitea + provisioner, creates the template repo, and pushes the setup script to GitHub. Admin credentials are saved locally in `.admin-credentials`.

3. **Share in Slack:**
   ```
   bash <(curl -fsSL https://raw.githubusercontent.com/bubble-hackathon-2026/setup/main/setup.sh) SERVER_IP
   ```

No invites needed. Anyone with a @bubble.io email and the server IP can self-provision.

### Teardown

```bash
bash admin/teardown.sh
```

### Cost

~$12 total (one small VM for the duration of the hackathon).
