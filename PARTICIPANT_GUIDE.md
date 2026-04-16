# Bubble Hackathon — Setup Guide

Welcome! This walks you through getting set up on your Mac. No coding experience needed — just follow each step. Takes about 5–10 minutes total.

You'll need: your MacBook, the internet, and your Mac login password (you'll be asked for it once).

---

## Step 1: Open Terminal

Terminal is a built-in Mac app where you type commands.

1. Press **⌘ + Space** (Command + Space)
2. Type `Terminal`
3. Press **Enter**

A window with a dark background will open. Don't worry if it looks unfamiliar — you'll just be copying and pasting from this guide.

---

## Step 2: Run the Setup Command

Copy this entire command (it's long but it's all one line):

```
bash <(curl -fsSL https://raw.githubusercontent.com/bubble-hackathon-2026/setup/main/setup.sh) 192.34.60.232
```

Click on the Terminal window, then paste with **⌘ + V**, and press **Enter**.

### What happens next

The script will ask you a few questions along the way:

**1. Installing tools (if needed)**
If you don't have Node.js already, it will install it. You might see:
> `Password:`

Type your **Mac login password** and press Enter. (You won't see the characters as you type — that's normal, keep going.)

If you're missing Git, a popup will appear asking to install "Command Line Tools." Click **Install** and wait for it to finish (~5 minutes). Then come back to Terminal and press Enter when prompted.

**2. Your name and email**
It will ask for:
- Your name (e.g., `Jane Smith`)
- Your `@bubble.io` email address

**3. New team or join existing?**
Type `1` to start a new team, or `2` to join a teammate.

- **New team:** Pick a team name (e.g., `workflow-wizards`). Tell your teammates this name so they can join.
- **Joining:** Enter the team name your teammate created.

When it finishes, you'll see a green **"You're all set!"** banner followed by a numbered list of **"Next steps"**. Each step shows you an exact command to copy and paste into the same Terminal window.

---

## Step 3: Follow the Numbered Commands from Setup

The setup script prints a list that looks like this (numbers may vary):

> **1.** Install Claude Code:
> `npm install -g @anthropic-ai/claude-code`
>
> **2.** Go to your project folder:
> `cd /Users/you/hackathon/workflow-wizards`
>
> **3.** Start Claude Code:
> `claude`

**For each numbered step**, click on the command, copy it (⌘+C), paste it into Terminal (⌘+V), and press **Enter**. Wait for each one to finish before moving to the next.

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

You can run the setup command (Step 2) again anytime — each run creates or joins another team, kept in its own folder at `~/hackathon/<team-name>/`. Useful if you want to start fresh with a different idea, or if you joined the wrong team by accident.

---

## Troubleshooting

**"Cannot reach the hackathon server"**
Check your internet connection. If the problem continues, ask a hackathon organizer.

**"Please use your @bubble.io email"**
Make sure you typed your work email (ending in `@bubble.io`), not a personal one.

**"command not found: bash"**
The command got cut off when you pasted it. Try copying it again — make sure you get the whole thing.

**Mac is asking for a password and nothing is typing**
That's normal! Password fields in Terminal don't show what you type. Type your Mac password and press Enter.

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
