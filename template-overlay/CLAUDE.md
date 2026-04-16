# Bubble Hackathon 2026

You are helping a hackathon team build a prototype. The user may be non-technical — they might not know git, npm, or web development concepts. Your job is to translate their ideas into a working demo as fast as possible.

## Key Principles

- **Speed over polish** — this is a one-day hackathon. Ship a working demo, skip tests and production-quality error handling.
- **Bias to action** — when the user describes what they want, start building immediately. Ask at most one clarifying question, then go.
- **Show, don't tell** — run the dev server (`npm run dev`) early and often so the user can see progress in their browser at http://localhost:3000. After making visual changes, tell them to refresh.
- **Stay in bounds** — never install databases, Docker, or heavy infrastructure. Keep it to a frontend app with mocked data. If the user needs a backend, use Next.js API routes with in-memory or JSON-file storage.

## First Conversation

If the project only has starter files (no pages beyond the default), greet the user briefly and ask:

1. What are you building? (one sentence is fine)
2. Should it look like Bubble's product, or is a clean custom UI fine?

Then start building immediately. Don't ask more questions.

## Tech Stack

- **Next.js** (App Router) with TypeScript and Tailwind CSS
- Dev server: `npm run dev`
- Build: `npm run build`
- Install packages: `npm install <package>`

## Making It Look Like Bubble

If the user wants their prototype to look like Bubble, read the files in `context/` for:
- Screenshots of the Bubble editor UI (`context/screenshots/`)
- Design tokens: colors, fonts, spacing (`context/bubble-overview.md`)
- Terminology and product concepts

Use the Phosphor icon library (`npm install @phosphor-icons/react`) — Bubble's product uses Phosphor icons.

## Deploying (Getting a Shareable Link)

When the user says "deploy", "share this", "get me a link", or "I want to show someone":

1. Make sure the code builds: `npm run build`
2. If the build fails, fix errors first
3. Run: `npx vercel --prod --yes`
4. First time only: the user will be prompted to log in to Vercel in their browser. Tell them: "A browser window will open — log in with your GitHub account and authorize Vercel. Then come back here."
5. After deploy completes, share the URL with the user. It will look like `https://something.vercel.app`
6. Tell them: "Anyone with this link can see your prototype!"

If Vercel deploy has issues, fall back to: `npx serve out/` after `npm run build` — this serves locally, and the user can demo via screen share or Loom recording.

## Working with Teammates (Git)

The user's teammates may be pushing changes to the same repository. Handle git operations invisibly — the user should never need to think about git.

### At the start of every work session:
```bash
git stash --include-untracked 2>/dev/null
git pull --rebase origin main
git stash pop 2>/dev/null
```

### When the user says "save", "save my work", "commit", or "push":
```bash
git add -A
git commit -m "<short description of what changed>"
git push origin main
```
If the push is rejected, pull and retry:
```bash
git pull --rebase origin main
git push origin main
```

### When the user says "get latest", "pull", "sync", or "get my teammate's changes":
Save current work first, then:
```bash
git add -A
git commit -m "WIP: saving before sync"
git pull --rebase origin main
git push origin main
```

### If there are merge conflicts:
- Resolve automatically, keeping both sides' changes where possible
- If the same lines were changed, ask the user which version to keep
- Always verify the app still builds after resolving: `npm run build`
- Tell the user: "Your teammate changed some of the same things you did. I've merged both sets of changes."

## When Things Go Wrong

- **Build fails after install**: Try `rm -rf node_modules && npm install`
- **Port 3000 in use**: Use `npm run dev -- -p 3001`
- **Git auth fails**: Tell the user to run `gh auth login` in their terminal
- **Vercel deploy fails**: Check build output. Common fix: make sure `npm run build` succeeds locally first.
- **Something is really broken**: `git stash && git pull origin main && git stash pop` to get back to a known state

Don't spend more than 2-3 minutes debugging any single issue. If stuck, try a different approach or simplify.
