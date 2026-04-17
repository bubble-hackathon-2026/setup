# Workflow Editor — Design & UX

> Read this alongside `context/bubble-editor-kit/product-surfaces/workflow-editor/README.md` (functional description) and `context/bubble-editor-kit/reference/design-language.md` (global tokens and components). The screenshots in `screenshots/` are the authoritative visual reference.

---

## Layout Anatomy — the 3-panel shell

The Workflow Editor uses a rigid three-panel layout that sets the editor's rhythm:

- **Left sidebar (~200px wide, white bg)** — Workflow navigator. Tree of events grouped by type ("On this page", "An element is clicked", "Custom event"), each with a numeric count badge and expand/collapse carets.
- **Center canvas (flex, white bg)** — The actual flow, rendered as stacked cards connected by vertical arrows. Has its own header strip with the workflow name, view-mode toggle (flow view vs compact list), and "Add notes" button, plus a zoom control pinned to the bottom-left.
- **Right properties panel (~310px wide, white bg)** — Dynamically populated for the selected node. Sections collapse with triangular carets. A BETA pill + overflow (⋯) menu sit in its header.

The outermost chrome (44px top menu bar, 40px left icon rail) persists from every other tab. Consistency across modes is the hidden strength.

---

## Core Interaction Vocabulary

What a user can do in the Workflow Editor, grouped by intent.

### Manage events
- Create a new event with **+ New** (primary cobalt button, top-right of the sidebar).
- Choose an event trigger from a 3-category picker:
  - **General** — user logged in/out, page loaded, schedule, error
  - **Elements** — element-specific triggers (e.g. "Button X is clicked")
  - **Custom** — reusable named flows, callable from anywhere
- Rename inline — the event name doubles as an editable textbox.
- Expand/collapse event groups via caret; each group shows a count badge.
- Filter/search events through the small filter icon at the top of the sidebar.

### Build a flow
- Add a step by clicking the `+` button below the last step (or between steps on hover — dashed insertion slot pattern).
- Pick an action from a two-level menu: 10 top-level categories (Account, Navigation, Data (Things), API Connections, Email, Payment, Analytics, Element Actions, Plugins, Custom Events, Backend Workflows), each revealing a flyout submenu.
- Search any action via the "Search for an action" input pinned at the top of the picker.
- Reorder steps via drag handle (`⋮⋮`) which appears on hover at the left edge.
- Delete / duplicate / add notes via the `⋯` kebab menu that appears on hover.
- Switch between **flow view** (vertical cards with arrows) and **compact view** (dense numbered list) using the icon toggles in the canvas header.
- Zoom in/out via the `— 100% +` pill at the bottom-left of the canvas.

### Configure a step
- Clicking a step loads its properties into the right panel, with **Properties** and **Only when** sections by default.
- Required empty fields show a subtle red/pink outline (red-40 `#F9B3A9`) — never a harsh error color or an inline error message.
- Toggle "Add a breakpoint in debug mode" on any step.
- Add a conditional expression via the "Only when" **Add** chip — opens the signature dynamic-data picker.
- "Expand ↖" link in the bottom-right of the condition area opens a large editor.

### Contextual help
- The `⋯` header menu surfaces "Add notes", "Reveal element" (jumps to the triggering element in the Design tab), and "Tutorials" — embedded, non-intrusive learning.

---

## Signature Patterns

These are the building blocks unique to (or most characteristic of) the Workflow Editor.

### Step cards

| Prop | Value |
|---|---|
| Width | ~336px |
| Height | 40px |
| Radius | 8px |
| Background (default) | cobalt-20 `#EBF3FF` |
| Border (selected) | 1px cobalt-70 `#0C29AB` |
| Caption (top label) | 10px / 16px / 600 / gray-60 `#8A8A8A`, e.g. "Step 1" or "Element Event" |
| Title (main label) | 12px / 16px / 400 / gray-80 `#1A1A1A`, e.g. "Send password reset email" |
| Icon tile | Soft square, left side, slightly darker blue-gray fill, conveys action category |
| Connector | Vertical `↓` arrow centered between cards, thin 1px gray-40 `#C7C7C7` |

Cards are stacked with generous vertical whitespace between. The stacked caption + title + icon-tile is THE workflow visual primitive.

### Action picker menu
- White popover, 4px radius, menu shadow (`0 2px 8px rgba(0,0,0,.10), 0 1px 2px rgba(0,0,0,.10)`).
- Search input docked at the top.
- Category rows: 16×16 monochrome icon + label + right-pointing caret.
- Hover fills the row with a gray-10 tint.
- Submenu opens beside the parent, row-aligned. Two levels is the hard ceiling — no deeper nesting.

### Dynamic data picker

The "Add" chip in conditions (and elsewhere) triggers this popover:

- Search field at the top
- Sections with UPPERCASE gray labels: `DATA SOURCES`, `ELEMENTS`, `BREAKPOINTS ON THIS PAGE`
- Items are plain text rows (no icons). Single-click inserts them as a **token chip** (see the global design-language doc — expression chips are the most signature Bubble primitive).

This picker is the connective tissue for the whole "no-code expression" feel of Bubble.

### Property panel form grammar
- **Section headers** — 12px / 16px / **700** / gray-80, with a small triangular collapse caret on the left.
- **Field labels** — 12px / 16px / 400 / gray-70 `#525252`, always *above* the input (never inline).
- **Inputs** — 1px `#E6E6E6` border, 4px radius, transparent background, 4–8px padding. When filled, they look almost flat — whitespace and label position do the grouping work.
- **Dashed "Add" chips** — placeholder empty-state affordance for required complex fields (Email to reset, Condition). Dashed border = "tap to fill."
- **Dropdowns** — chevron affordance, same border treatment as inputs.
- **Toggle switches** — iOS-style, cobalt-70 when on.

### Status & meta affordances
- **BETA pill** — small rounded pill, periwinkle tint bg (`#E9EBFB`-ish) with periwinkle-80 `#341A9E` text, 10px / 700, right next to the panel title. Reusable for flagging experimental areas.
- **Issue count** — red triangle warning icon + count (⚠ 1, ⚠ 2) in the top menu bar. Editor-wide issue tracker.
- **Deploy button** — top-right, cobalt-70 primary. Always visible, always reachable.

---

## UX Principles the Workflow Editor Embodies

Bubble commits to these ideas throughout:

1. **Dense but breathable.** 12px type everywhere, 4–8px spacing by default — but cards get generous 8–12px internal padding. IDE × design tool hybrid.
2. **Progressive disclosure through nested popovers.** A user never sees 50 options at once; two-level menus + search bars do the heavy lifting.
3. **Same visual language across modes.** Step cards, property panels, and picker menus all share 4/8px radius, 1px `#E6E6E6` borders, and the same shadow vocabulary.
4. **Empty-state as call-to-action.** Placeholders literally say "Add" inside a dashed outline. No separate "create" button needed.
5. **Inline editing everywhere.** Workflow names, event names, and step titles are all double-click editable with the same text-input pattern.
6. **Color communicates category, not priority.** Cobalt = brand/primary, purple = dynamic data, green = data operations, gray = chrome. Mapping color to meaning, not hierarchy.
7. **Escape + hover are first-class citizens.** Hover reveals drag handles, kebab menus, and insertion slots; Escape dismisses any popover. The chrome stays quiet until you engage.

---

## Screenshots Map

Files live in `./screenshots/`.

| Screenshot | What it demonstrates |
|---|---|
| `Editor - Workflows - Action - Send Email.png` | Full 3-panel layout with selected step ("Send password reset email"), step cards stacked with arrows, Properties panel populated on the right (Email to reset, Subject, Body, Password reset mode, breakpoint toggle), Only when section with Add chip |
| `Editor - Workflows - Custom Event - Popover.png` | Workflow navigator sidebar populated with event groups; illustrates the tree structure and count badges |
| `Editor - Backend Workflows - API event.png` | Backend workflow API event screen; different surface variant showing the same panel pattern applied to API triggers |
| `Editor - Backend Workflows - API event 2.png` | Backend API event configuration continued — parameter setup and exposure toggles |

---

## Cross-Surface Interactions

- **From Design Tab:** Clicking "Start/Edit workflow" on an element jumps here with a pre-wired event selected.
- **To Data Tab:** "Make changes to a thing" / "Create a new thing" / "Delete thing" actions reference Data Types defined in the Data Tab.
- **To API Connector:** Plugin actions added to a workflow pull from the API Connector's initialized calls.
- **Runtime Debugger:** Slow and Step-by-step modes let you watch each workflow action execute in the debugger.
