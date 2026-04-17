# Bubble — User Personas

Bubble is used by a wide range of people, most of whom don't write
code for a living. Understanding who they are helps you design
prototypes that match how they actually work.

These personas are synthesized from the product patterns and workflows
described in Bubble's core documentation. Each person cares about
different parts of the platform — pages, data types, workflows, the
API Connector, plugins, privacy rules, responsive layouts, versioning,
and the Data and Workflow APIs.

---

## 1. Solo Founders / Entrepreneurs

### Who they are
Individuals building a product idea from scratch, often without a
technical co-founder or engineering budget. They're idea-driven, lean,
and focused on getting something in front of users as fast as
possible. They learn Bubble by doing — often via the in-editor
property editor, in-depth article series, and the debugger.

### What they typically build
- Marketplaces and directories with User accounts, listings (custom
  data types), and search pages.
- Early-stage SaaS products with authentication, a dashboard, and
  CRUD workflows over a handful of data types.
- Social apps with feeds built out of repeating groups and privacy
  rules on user-generated content.
- AI-powered experiences using the API Connector to call external
  language-model or image APIs and display results in groups.
- Landing pages and waitlists before the main app is ready.

### Pain points
- Deciding the right database structure before the product direction
  is fully clear — data type choices ripple into every workflow.
- Learning which things belong in frontend workflows vs. backend/API
  workflows, especially around long-running operations.
- Setting up responsive layouts correctly on the first try using
  Row/Column container layouts and breakpoints.
- Remembering to write privacy rules before going live so sensitive
  data isn't exposed in the JSON the page ships to the browser.
- Hitting workload limits on their plan as usage grows and needing to
  optimize.

### What they value most in Bubble
- Visual WYSIWYG building with immediate preview.
- Being able to ship a working product without hiring engineers.
- A clear separation between Development and Live versions, so they
  can experiment safely and deploy when ready.
- The plugin marketplace (Stripe, Google, social login, chart.js,
  rich text editor) covering most common needs out of the box.
- The API Connector for plugging into anything that isn't already a
  plugin.

---

## 2. Agencies

### Who they are
Professional teams — small to mid-sized shops — who build Bubble apps
as a service for external clients. They ship many apps a year, reuse
patterns aggressively, and care about maintainability and handoff.
Often have certified Bubble developers on staff.

### What they typically build
- Full MVPs for client startups: authentication, dashboards, payment
  flows, admin backends.
- Internal business tools for mid-market clients.
- White-labeled products deployed across multiple clients, often
  using the sub-apps feature so the parent app can push updates to
  child apps.
- Templates for the marketplace they resell to other builders.
- Complex multi-role apps with carefully layered privacy rules,
  option sets for statuses, and custom events for shared logic.

### Pain points
- Keeping apps clean and maintainable as scope grows — avoiding
  "spaghetti workflows" and duplicated logic.
- Coordinating collaborators and permissions across the team using
  the Settings > Collaboration controls.
- Handling client database migrations when data types change.
- Communicating the difference between an "API workflow" (a unit of
  server-side work) and the "Workflow API" (the feature that exposes
  it over HTTP) to clients.
- Managing Bubble engine version upgrades without breaking live
  client apps.

### What they value most in Bubble
- Reusable elements, custom events, and option sets for building
  standards once and applying everywhere.
- Sub-apps for operating the same product for many clients.
- Version control with branches and save points for safe rollouts.
- The ability to export and import apps as JSON for archiving and
  starter kits.
- Collaborator access controls so designers, builders, and clients
  each see the right slice of the app.

---

## 3. Internal Tools Teams

### Who they are
Builders inside a larger company — ops managers, product ops, RevOps,
analysts, and sometimes embedded engineers — responsible for internal
workflow software. They already have systems of record (CRMs,
databases, spreadsheets) and need to glue them together with UI that
non-technical teams can use.

### What they typically build
- Admin dashboards pulling data from the Bubble database or external
  APIs via the API Connector.
- Approval and review workflows with role-based access using privacy
  rules and conditional formatting.
- Data-entry forms backed by Bubble data types, often with CSV
  upload for bulk imports.
- Scheduled jobs — nightly reports, reminder emails — built as
  recurring API workflows.
- Integrations that sync data between Bubble and services like
  Airtable, Slack, Zapier, or an in-house Postgres via the SQL
  Database Connector plugin.

### Pain points
- Connecting to internal systems that don't have plug-and-play
  Bubble plugins; they often spend time in the API Connector.
- Managing large tables of data and keeping repeating groups
  performant (tuning sorting, Unsorted views, search constraints).
- Getting privacy rules right for multi-role internal apps where
  different teams see different slices.
- Handing off ownership when the original builder leaves the
  company.

### What they value most in Bubble
- Fast prototyping for internal workflows that would be
  over-engineered as full engineering projects.
- The API Connector + Data API + Workflow API together, enabling
  two-way integration with existing infrastructure.
- Option sets for structured, editable-by-admins configuration
  without code deploys.
- CSV import/export and bulk actions for moving data in and out.
- The logs tab and the debugger for root-causing issues without
  DevTools skills.

---

## 4. Citizen Developers

### Who they are
Employees in non-engineering roles (marketing, operations, HR, finance)
who build tools for themselves and their teams. They're comfortable
with spreadsheets and low-code tools, but generally don't write JS or
SQL. They often learn Bubble in evenings and weekends.

### What they typically build
- Team directories, onboarding checklists, and process trackers.
- Forms that collect responses into a Bubble database and display
  them in repeating groups.
- Simple client portals with login, file uploads via the file
  uploader element, and privacy rules tying files to the uploading
  user.
- Event sign-ups, lightweight CRMs, and inventory trackers.
- Learning-by-doing projects that follow Bubble Academy videos and
  the Bubble Introduction Series.

### Pain points
- Choosing among container layout types (Row, Column, Fixed, Align
  to parent) when designing their first responsive page.
- Understanding dynamic expressions — especially long chains with
  operators like `:filtered`, `:sorted`, and `:first item`.
- Knowing when to use a custom state vs. a data type field vs. a
  URL parameter.
- Fear of "breaking the live version" — which is exactly what the
  Development version is there to prevent.

### What they value most in Bubble
- The WYSIWYG Design tab letting them build a real UI visually.
- The in-product learning materials and video lessons baked into
  reference entries.
- The element tree and property editor as discoverable,
  self-explanatory interfaces.
- Bubble-made plugins covering common use cases (calendar, charts,
  star ratings, share buttons) without custom work.
- Being able to preview the app instantly and run it as a specific
  user to see how it looks to others.

---

## 5. Students / Learners

### Who they are
People learning to build software for the first time. Could be
bootcamp students, computer science learners picking up no-code as a
shipping skill, career-switchers exploring product work, or hobbyists
building side projects. Experience levels range from total beginner
to intermediate.

### What they typically build
- Tutorials and practice apps: to-do lists, recipe managers, quiz
  games.
- Portfolio projects modeled on existing products (Airbnb clones,
  Twitter clones, Uber-for-X clones).
- Hackathon entries that demonstrate an idea in a weekend.
- Small-scale community tools for clubs, cohorts, or classmates.
- Experiments with the API Connector and AI APIs to build chatbots
  and content generators.

### Pain points
- Wrapping their head around the Bubble vocabulary: data type vs.
  thing, field vs. property, workflow vs. action, event vs. action
  step.
- Differentiating frontend workflows (run in the browser) from
  backend workflows (run on the server), and knowing when each is
  appropriate.
- Writing their first dynamic expression without getting lost in
  operators.
- Navigating the editor's many tabs and sub-tabs before they know
  where each setting lives.

### What they value most in Bubble
- Beginner-friendly reference material with experience-level labels
  (beginner / intermediate / advanced).
- The Bubble Academy videos embedded throughout the docs.
- The visual debugger that shows values flowing through a workflow
  step by step.
- A forgiving development environment with an isolated dev database.
- A clear path from "I built something that works" to "I published
  it live" via Deploy to live.

---

## Persona Comparison

| Persona | Primary use case | Primary value they get from Bubble |
|---|---|---|
| Solo Founders / Entrepreneurs | Ship an MVP for a new product idea without hiring engineers | Full-stack app creation with visual building and a live preview |
| Agencies | Deliver client apps at scale with reusable patterns and safe rollouts | Collaboration, sub-apps, reusable elements, version control |
| Internal Tools Teams | Build bespoke internal workflows glued to existing systems | API Connector, Data API, Workflow API, role-based privacy rules |
| Citizen Developers | Create team tools and forms without writing code | Visual Design tab, Bubble-made plugins, run-as-user preview |
| Students / Learners | Learn app development by shipping real projects | Approachable editor, in-product learning materials, Development version safety |
