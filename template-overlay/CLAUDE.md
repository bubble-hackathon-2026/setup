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
2. Is the goal for the prototype to look like it lives *inside* the Bubble editor (e.g., pitching a new editor feature or redesigning an existing editor surface), or is a clean custom UI fine for the demo?

Then start building immediately. Don't ask more questions.

## Tech Stack

- **Next.js** (App Router) with TypeScript and Tailwind CSS
- Dev server: `npm run dev`
- Build: `npm run build`
- Install packages: `npm install <package>`

## Is This A Bubble-Editor Prototype?

Hackathon projects split into two types, and the distinction matters a lot for how you build:

- **Bubble-editor prototypes** — mocking up a new editor feature (e.g., "add a Disable Step toggle to workflow steps", "redesign the Data tab privacy rules"), a redesign of an existing editor surface, or anything where the demo is meant to feel like *"this could actually ship in the Bubble editor tomorrow."* For these, the prototype has to match Bubble's visual language precisely.
- **Everything else** — user-facing apps (marketplaces, internal tools, AI tools, dashboards), Bubble plugins with their own UI, marketing pages, new product concepts not tied to the editor's look. For these, a clean custom UI is fine — *do not* force Bubble editor styling.

If the user was explicit in the first conversation, trust what they said. If you're unsure — or if they said "make it look like Bubble" without distinguishing the editor vs. a generic Bubble-built app — ask one short follow-up: *"Quick check: is this meant to look like it's inside the Bubble editor (cobalt + purple chips + dense panels), or is it a Bubble-style end-user app?"* The user may not know the editor kit exists, so ask once rather than guess.

### If yes — use the editor kit

Read **`context/bubble-editor-kit/INDEX.md`** before writing any UI code. The kit has the authoritative design language (tokens, components, icons, typography), deep dives on each editor surface (Design tab, Workflow editor, Data tab, etc.), and annotated screenshots. Following the kit is the difference between "almost looks like Bubble" and "looks like Bubble."

Key non-negotiables from the kit (full list in the INDEX):
- Open Sans 12px/16px (not Inter, not 14px), Phosphor icons (`@phosphor-icons/react`), cobalt-70 `#0C29AB` primary, purple `#79059A` for dynamic data, 4px radii dominant, no gradients, no dark mode.
- Use correct Bubble vocabulary: **Data Type** (not table), **Thing** (not record), **Workflow** (not automation), **Element** (not component), **Custom Event** (not helper).
- Before calling the prototype done, re-open 1-2 screenshots from the target surface and fix the top 3-5 visual gaps.

### If no — skip the kit entirely

Don't read anything in `context/bubble-editor-kit/`. Don't import the Bubble design tokens. Build whatever UI best fits the product idea. The kit will just make a non-editor prototype feel wrong.

### General UI tips (both types)

- **If the user pastes a screenshot**, use it as a direct visual reference — match it literally before iterating.
- Phosphor icons work well for both types: `npm install @phosphor-icons/react`.

## Deploying (Getting a Shareable Link)

When the user says "deploy", "share this", "get me a link", or "I want to show someone":

1. Make sure the code builds: `npm run build`
2. If the build fails, fix errors first
3. Run: `npx vercel --prod --yes`
4. First time only: the user will be prompted to log in to Vercel in their browser. Tell them: "A browser window will open — log in with your GitHub account and authorize Vercel. Then come back here."
5. After deploy completes, share the URL with the user. It will look like `https://something.vercel.app`
6. Tell them: "Anyone with this link can see your prototype!"

### Environment Variables on Vercel

If the app needs API keys in production (not just locally), add them to Vercel:
```bash
npx vercel env add SECRET_NAME production
```
This prompts for the value interactively (secure, not shown in terminal history). After adding env vars, redeploy: `npx vercel --prod --yes`

If Vercel deploy has issues, fall back to: `npx serve out/` after `npm run build` — this serves locally, and the user can demo via screen share or Loom recording.

## Secrets & API Keys

NEVER put API keys, passwords, tokens, or other secrets directly in code files. This is critical — even in a hackathon prototype.

**The safe pattern:**
1. Put secrets in `.env.local` (this file is gitignored and never committed):
   ```
   OPENAI_API_KEY=sk-abc123...
   MY_API_SECRET=xyz...
   ```
2. Access them in code via `process.env.OPENAI_API_KEY`
3. For Next.js client-side code, prefix with `NEXT_PUBLIC_`: `NEXT_PUBLIC_MAP_KEY=...`

**If the user pastes an API key into the chat**, put it in `.env.local` — never in a source file. Tell them: "I've stored your key safely in .env.local so it won't be shared or uploaded."

**If you see a secret already in a source file**, move it to `.env.local` immediately and replace the reference with `process.env.KEY_NAME`.

A pre-commit hook will block commits that appear to contain secrets. If it fires, help the user move the secret to `.env.local`.

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
git status  # sanity-check: make sure no .env or credential files are staged
git commit -m "<short description of what changed>"
git push origin main
```
If `git status` shows any `.env` files or files that might contain secrets staged, unstage them with `git reset HEAD <file>` before committing.
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
