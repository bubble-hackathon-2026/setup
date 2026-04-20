# Bubble Hackathon — Setup Guide (Windows)

Welcome! This walks you through getting set up on your Windows PC. No coding experience needed — just follow each step. Takes about 5–10 minutes total.

You'll need: your Windows laptop, the internet, and a couple of clicks on permission dialogs that may pop up while things install.

> **On a Mac?** Use [PARTICIPANT_GUIDE.md](./PARTICIPANT_GUIDE.md) instead.

---

## Step 1: Open PowerShell

PowerShell is a built-in Windows app where you type commands.

1. Press **Windows key + X** (hold the Windows key, then press X)
2. Click **Terminal** or **Windows PowerShell** — either one works
3. A window with a dark or blue background will open

If you don't see either option in the menu, click **Start**, type `powershell`, and click the app that appears.

---

## Step 2: Run the Setup Command

Copy this entire command (it's long — make sure you get all of it on one line):

```
& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/bubble-hackathon-2026/setup/main/setup.ps1'))) 192.34.60.232
```

Click on the PowerShell window, paste with **Ctrl + V** (or right-click in the window), and press **Enter**.

### What happens next

The script will work through a few steps and ask some questions along the way:

**1. Installing tools (if needed)**
If Git or Node.js aren't already on your PC, they'll install automatically. A Windows permission dialog may appear asking for approval — click **Yes**. Each install takes about a minute.

If installation fails (rare), the script will tell you which installer to download manually and ask you to re-run the command.

**2. Your name and email**
It will ask for:
- Your name (e.g., `Jane Smith`)
- Your `@bubble.io` email address

**3. Slack verification code**
You'll get a Slack DM with a 6-digit code. Copy it back into PowerShell and press Enter.

**4. New team or join existing?**
Type `1` to start a new team, or `2` to join a teammate.

- **New team:** Pick a team name (e.g., `workflow-wizards`). Tell your teammates this name so they can join.
- **Joining:** Enter the team name your teammate created.

When it finishes, you'll see a green **"You're all set!"** banner followed by a numbered list of **"Next steps"**. Each step shows you an exact command to copy and paste into the same PowerShell window.

---

## Step 3: Follow the Numbered Commands from Setup

The setup script prints a list that looks like this (numbers may vary):

> **1.** Install Claude Code:
> `irm https://claude.ai/install.ps1 | iex`
>
> **2.** Go to your project folder:
> `cd 'C:\Users\you\hackathon\workflow-wizards'`
>
> **3.** Start Claude Code:
> `claude`

**For each numbered step**, click the command, copy it (Ctrl+C), paste it into PowerShell (Ctrl+V), and press **Enter**. Wait for each one to finish before moving to the next.

When Claude Code starts, you'll see a friendly prompt asking what you'd like to do.

---

## Step 4: Talk to Claude

Just type what you want in plain English. Some things to try:

- **"I want to build a dashboard for tracking customer onboarding. Make it look like Bubble's editor."**
- **"Show me what it looks like in the browser"** — Claude will run the app so you can see it
- **"Deploy this so I can show my team"** — Claude gives you a link anyone can open
- **"Save my work"** — saves your progress and syncs with your teammates
- **"Get my teammate's latest changes"** — pulls in what they've been doing

Claude will ask questions when it needs clarification, and will show you your app as you build it so you can give visual feedback.

### Starting Over or Joining a Different Team

You can run the Step 2 command again anytime — each run creates or joins another team, kept in its own folder at `C:\Users\you\hackathon\<team-name>\`. Useful if you want to start fresh with a different idea, or if you joined the wrong team by accident.

---

## Troubleshooting

**"Cannot reach the hackathon server"**
Check your internet connection. If the problem continues, ask a hackathon organizer.

**"Please use your @bubble.io email"**
Make sure you typed your work email (ending in `@bubble.io`), not a personal one.

**"running scripts is disabled on this system"**
This shouldn't happen with the command above (it runs in memory, not as a file). If you see it anyway, open a new PowerShell window and try again — and double-check you pasted the full command on one line.

**The install step failed (winget isn't available)**
Install the tools manually, then re-run the Step 2 command:
- Node.js LTS: https://nodejs.org (download and run the installer — defaults are fine)
- Git for Windows: https://git-scm.com/download/win (download and run — defaults are fine)

**A "Windows wants to make changes" dialog keeps popping up**
That's normal — it's asking for permission to install Node.js and Git. Click **Yes** each time.

**Claude Code does something weird or gets stuck**
Type `/clear` to reset the conversation, or ask Claude "start over with a simpler version." Don't spend more than a few minutes on any one issue — just try a different approach.

**Anything else**
Post in #offsite-hackathon in Slack, or find a nearby organizer — we'll get you unstuck.

---

## Tips for a Great Demo

- **Build something you'd actually use.** The best prototypes solve real problems.
- **Use screenshots.** If you see something on the web that looks the way you want, take a screenshot and drag it into Claude Code — it'll copy the style.
- **Iterate fast.** Don't try to get it perfect on the first try. Build, look at it, refine.
- **Deploy early.** Run "deploy this" once you have something working, so you always have a shareable link even if things break later.

Good luck and have fun!
