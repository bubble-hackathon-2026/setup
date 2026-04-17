# Bubble Editor — Design Language

**Source:** CSS custom properties extracted directly from the live Bubble editor + UX research across the main surfaces. This is the authoritative visual reference. Use these exact values — do not approximate.

> **TL;DR — the "looks like Bubble" recipe:** White canvas, `#F7F7F7` secondary surfaces, thin `#E6E6E6` borders, 4px radii everywhere, 12px/16px Open Sans UI text, cobalt-70 `#0C29AB` for primary actions, very tight 4/8px spacing, Phosphor icons (1.5px stroke). Shadows only on floating surfaces (menus, popovers, modals). Dynamic data is always purple `#79059A`. No gradients, no dark mode, no oversized headings.

---

## Typography

**Primary UI font:** Open Sans (Google Fonts)
**Display font (marketing only):** FoundersGrotesk

```css
--font-family: 'Open Sans', Helvetica, Arial, sans-serif;
--font-family-display: 'FoundersGrotesk';
```

### Consolidated type hierarchy

```
Display / section title:       12px / 16px / 700 / gray-80   (#1A1A1A)
Body / control label:          12px / 16px / 400 / gray-70   (#525252)
Body emphasis (button, link):  12px / 16px / 600 / cobalt-70 or gray-80
Caption / metadata:            10px / 16px / 600 / gray-60   (#8A8A8A)
Large body (rare):             16px / 16px / 400 / gray-80
Code / expression tokens:      12px / 16px / 400 / inherits from chip
```

**Critical:** Bubble lives in the 10–16px range. **There are no H1/H2/H3-style large headings in the editor.** The whole UI runs on a compact 12px type scale — this is the most distinctive typographic choice. Never default to 14px or 16px as a UI baseline.

### Google Fonts embed

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Open+Sans:wght@400;600;700&display=swap" rel="stylesheet">
```

---

## Icons — Phosphor

The editor uses **Phosphor Icons** (https://phosphoricons.com). Phosphor's thin rounded-stroke style is essential to the Bubble look — do not substitute Lucide, Heroicons, Material, or FontAwesome.

Style rules: 1.5px stroke, 16×16 for panel icons, 20×20 for the icon rail. Color via `currentColor`; icons inherit from the surrounding `--icon-*` token.

### CDN

```html
<script src="https://unpkg.com/@phosphor-icons/web"></script>
<i class="ph ph-magnifying-glass"></i>
<i class="ph ph-plus"></i>
```

### Common editor icons → Phosphor names

| Use | Phosphor name |
|---|---|
| Search | `magnifying-glass` |
| Add / new | `plus` |
| Close / remove | `x` |
| Expand/collapse | `caret-down` / `caret-right` |
| More menu | `dots-three` / `dots-three-vertical` |
| Delete | `trash` |
| Edit | `pencil-simple` |
| Settings / gear | `gear-six` |
| Visibility | `eye` / `eye-slash` |
| Link / dynamic data | `link` |
| Warning | `warning` |
| Info | `info` |
| Check / saved | `check` / `check-circle` |
| Undo / redo | `arrow-counter-clockwise` / `arrow-clockwise` |
| Run (play) | `play` |
| Lock | `lock` |
| Drag handle | `dots-six-vertical` |

---

## Color System

Every color family uses a 10–80 (sometimes 90) scale. Cobalt is the primary brand.

### Core palette

```css
/* Cobalt (brand) */
--cobalt-10:#F5FAFF; --cobalt-20:#EBF3FF; --cobalt-30:#D5E5FB; --cobalt-40:#AFCEF8;
--cobalt-50:#1E6DF6; --cobalt-60:#0947D7; --cobalt-70:#0C29AB; --cobalt-80:#091E7C; --cobalt-90:#051043;

/* Gray (neutrals) */
--gray-10:#F7F7F7; --gray-20:#F2F2F2; --gray-30:#E6E6E6; --gray-40:#C7C7C7;
--gray-50:#A6A6A6; --gray-60:#8A8A8A; --gray-70:#525252; --gray-80:#1A1A1A;

/* Green (success) */
--green-10:#F5FAF6; --green-20:#EAF5ED; --green-30:#CFE8D5; --green-40:#B7DCBF;
--green-50:#2EA84A; --green-60:#26883C; --green-70:#1E6C30; --green-80:#175425;

/* Red (danger) */
--red-10:#FEF6F5; --red-20:#FDEAE7; --red-30:#FBD0CB; --red-40:#F9B3A9;
--red-50:#EF2F15; --red-60:#CD260E; --red-70:#B0200C; --red-80:#941B0A;

/* Orange (caution) */
--orange-10:#FFFAF5; --orange-20:#FFF4E5; --orange-30:#FFE3C2; --orange-40:#FFD6A3;
--orange-50:#FF9A1F; --orange-60:#F58700; --orange-70:#D17400; --orange-80:#8F4F00;

/* Sky-blue (info) */
--sky-10:#F5FBFF; --sky-20:#E6F6FE; --sky-30:#D3EFFD; --sky-40:#B0E3FC;
--sky-50:#61CAFF; --sky-60:#09A4F1; --sky-70:#0789CA; --sky-80:#056494;

/* Yellow */
--yellow-10:#FFFAF0; --yellow-20:#FFF4DB; --yellow-30:#FFEFC7; --yellow-40:#FFDC8A;
--yellow-50:#FFB505; --yellow-60:#EBA500; --yellow-70:#DCA114; --yellow-80:#B88100;

/* Purple (dynamic-data accent — critical) */
--purple-10:#FAF4FB; --purple-20:#F6ECF8; --purple-30:#E9D2EF; --purple-40:#DEBBE7;
--purple-50:#AE07DA; --purple-60:#9606BC; --purple-70:#79059A; --purple-80:#5B0372;

/* Periwinkle (secondary accent, BETA pills, AI Agent) */
--peri-10:#F2F3FD; --peri-20:#E9EBFB; --peri-30:#D8DBF9; --peri-40:#BDC3F4;
--peri-50:#625DFE; --peri-60:#513EDF; --peri-70:#401FC1; --peri-80:#341A9E;

/* Livid (cool gray) */
--livid-10:#F2F5F9; --livid-20:#E4EAF1; --livid-30:#CAD5E2; --livid-40:#AFC0D4;
--livid-50:#849FBD; --livid-60:#69809B; --livid-70:#415162;

/* Cyan */
--cyan-10:#F2FEFD; --cyan-30:#BBF9F7; --cyan-60:#34C3BE;
```

### Semantic tokens

Bubble binds almost exclusively to semantic tokens — use these whenever possible.

```css
/* Text */
--txt-primary:#1A1A1A; --txt-secondary:#525252; --txt-tertiary:#8A8A8A;
--txt-inactive:#C7C7C7; --txt-on-contrast:#FFFFFF;
--txt-brand:#0C29AB; --txt-brand-inactive:#AFCEF8;
--txt-success:#1E6C30; --txt-danger:#B0200C;
--txt-caution:#D17400; --txt-info:#0789CA;
--txt-dynamic:#79059A;  /* dynamic data — purple */
--txt-dynamic-inactive:#DEBBE7;
--txt-orange:#F58700; --txt-green:#2EA84A;
--txt-periwinkle:#513EDF; --txt-purple:#9606BC;

/* Backgrounds */
--bg-primary:#FFFFFF; --bg-secondary:#F7F7F7; --bg-tertiary:#E6E6E6;
--bg-tertiary2:#D5E5FB; --bg-brand:#0C29AB;
--bg-brand1:#F5FAFF; --bg-brand2:#EBF3FF;   /* selected row highlight */
--bg-on-brand1:#0C29AB; --bg-on-brand2:#0947D7;
--bg-contrast1:#1A1A1A; --bg-contrast2:#525252;
--bg-info1:#F5FBFF;
--bg-caution1:#FFFAF5; --bg-caution2:#FFF4E5;
--bg-success1:#F5FAF6; --bg-success2:#EAF5ED; --bg-success-disabled:#B7DCBF;
--bg-danger1:#FEF6F5; --bg-danger-disabled:#F9B3A9;
--bg-accent-cobalt:#D5E5FB; --bg-accent-sky-blue:#D3EFFD;
--bg-accent-green:#CFE8D5; --bg-accent-yellow:#FFEFC7;
--bg-accent-orange:#FFE3C2; --bg-accent-purple:#E9D2EF;
--bg-accent-periwinkle:#D8DBF9;
--bg-overlay-modal:rgba(0,0,0,0.3);

/* Borders */
--border-default:#E6E6E6; --border-inactive:#F2F2F2;
--border-contrast:#525252; --border-on-contrast:#FFFFFF;
--border-brand:#0C29AB; --border-brand2:#D5E5FB;
--border-success:#1E6C30; --border-danger:#B0200C;
--border-caution:#D17400; --border-info:#0789CA;
--border-dynamic:#79059A;

/* Icons */
--icon-primary:#1A1A1A; --icon-tertiary:#8A8A8A; --icon-inactive:#C7C7C7;
--icon-brand:#0C29AB; --icon-success:#1E6C30; --icon-danger:#B0200C;
--icon-caution:#D17400; --icon-info:#0789CA;
--icon-purple:#9606BC; --icon-periwinkle:#513EDF;
--icon-green:#2EA84A; --icon-green-inactive:#B7DCBF;
--icon-dynamic-inactive:#DEBBE7;
```

### Color meaning map

Colors are **semantic, not decorative**:

| Color | Meaning |
|---|---|
| Cobalt | Brand — primary actions, selected state, focus |
| **Purple** | **Dynamic data references** — the connective tissue of the "no-code expression" feel |
| Green | Success — positive confirmations |
| Red | Danger — errors, destructive actions |
| Orange | Caution — warnings, attention-needed |
| Sky-blue | Info — neutral informational states |
| Periwinkle | Secondary accent — BETA pills, AI Agent label |
| Yellow | Reserved for specific highlights |

---

## Spacing Scale (4-point)

```css
--space-none:0;  --space-xs:2px;  --space-sm:4px;  --space-reg:8px;
--space-tv:12px; --space-md:16px; --space-lg:24px; --space-xl:32px; --space-xxl:40px;
```

Raw steps: 2, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64, 68, 72.

### Density rhythm (operational guidance)
- Between sections in a panel: **16–24px**
- Between fields in a section: **8–12px**
- Between label and input: **4px**
- Inside a card: **8–12px**
- Between step cards on a canvas: **24–32px** (plus connector arrow)

### Component-specific padding

```css
--padding-btn-small:4px;
--padding-btn-regular:8px;
--padding-input:4px;
--padding-list:8px;
```

---

## Radii

Deliberately low-rounded. **4px is dominant.**

```css
--radius-small:2px;       /* expression chips only */
--radius-regular:4px;     /* buttons, inputs, menus, modals, cards */
--radius-medium:8px;      /* step cards, larger cards */
--radius-large:12px;      /* circle badges only */
```

Do not use 6px. Never use 16px+ on standard UI.

---

## Shadows — only 4 elevations

Shadows appear **only on floating surfaces** (menus, popovers, modals, lightboxes). Never on in-flow components.

```css
--shadow-menu:    0px 2px 8px rgba(0,0,0,.10), 0px 1px 2px rgba(0,0,0,.10);
--shadow-alert:   0px 2px 8px rgba(0,0,0,.10), 0px 1px 2px rgba(0,0,0,.10);
--shadow-popover: 0px 1px 2px rgba(0,0,0,.10), 0px 6px 12px rgba(0,0,0,.12);
--shadow-lightbox:0px 1px 2px rgba(0,0,0,.10), 0px 8px 24px rgba(0,0,0,.15);
```

---

## Motion

Very restrained. "IDE-like" identity.

- Hover transitions: **100ms ease**
- Caret rotation on expand/collapse: **150ms ease**
- Popover enter: ~100ms fade + scale
- No bouncy easing anywhere
- Panels do not slide; they just appear
- Everything is flat and quick

---

## Interaction States

Reusable across every clickable / selectable element.

| State | Visual |
|---|---|
| Hover (list row) | gray-10 `#F7F7F7` bg, no border change, 100ms transition |
| Selected (list row) | cobalt-20 `#EBF3FF` bg, cobalt-70 text, often 2px cobalt-70 left border accent |
| Focused (input) | 1px border changes from `#E6E6E6` → cobalt-70. No box-shadow ring. |
| Disabled | gray-40 text on gray-10 bg, no border, 0.6 opacity on icons |
| Error / required | red-40 `#F9B3A9` 1px border on input. No inline red text — the border alone communicates it. |

---

## Component Library

### Primary button (Deploy, Run, + New)
```
bg: cobalt-70 #0C29AB     color: white
height: 32px              padding: 8px
radius: 4px               font: 600 12px/16px Open Sans
border: none              shadow: none
```

### Secondary button (outline)
```
bg: transparent                color: cobalt-70
border: 1px solid cobalt-70    height: 32px
padding: 8px                   radius: 4px
font: 600 12px/16px Open Sans
```

### Tertiary / ghost button
```
bg: transparent (hover → gray-10)
color: gray-70            border: none
height: 32px              padding: 8px
radius: 4px
font: 600 12px/16px Open Sans
```

### Icon button
```
28–32px square            bg: transparent (hover → gray-10)
icon: gray-60 (hover → gray-80)
radius: 4px
```

### Input field
Default: **no visible border**. Inputs blend into the panel.
```
bg: transparent           border: none (default)
padding: 4px 8px 4px 0    color: gray-80
font: 400 12px/16px Open Sans
```
Focused/filled: 1px `#E6E6E6` border appears. Error: `#F9B3A9` border.

### Menu bar / top bar
```
height: 44px              bg: white
border-bottom: 1px #E6E6E6
```
Left-to-right content: Bubble logo (with caret) · `⎇ Main` (branch) · `⌘ Web` (app) · `📄 page_name` · contextual selector · spacer · issue count (⚠ + number) · Preview (split button with caret) · Deploy (cobalt-70). All controls 32px tall.

### Icon rail (far-left)
```
width: 40px               bg: gray-10 #F7F7F7
border-right: 1px #E6E6E6
```
Vertical stack of 20×20 monochrome icons, ~24px vertical spacing. gray-60 default, cobalt-70 when active, with cobalt-20 rounded background on active. Order top-to-bottom: Design · Workflow · Backend Workflows · Data · API Connector · Plugins · Logs · Settings · Analytics · Security. Bottom: Help (?) and user avatar circle. Labels tooltip-only, never inline.

### List item (Elements Tree, palette, dropdowns)
```
padding: 8px              font: 400 12px/16px Open Sans
```
Selected: bg cobalt-20, text cobalt-70. Hover: bg gray-10.

### Panel / sidebar
```
bg: white (or gray-10 for secondary)
border-right/left: 1px #E6E6E6
```

### Popover / menu
```
bg: white                 radius: 4px
shadow: shadow-menu (or shadow-popover)
min-width: ~200px         max-width: ~280px
```
Item layout: `[icon 16×16] [label] [optional caret/shortcut]` with 8px gap. Item height 28–32px, 8px horizontal padding. Section dividers: 1px `#F2F2F2` line, or uppercase gray-60 10px/600 label. Submenus open right, top-aligned to parent, 2px overlap. Close on: Escape, outside click, selection.

### Tooltip
```
bg: gray-80 #1A1A1A       color: white
font: 400 12px/16px       padding: 6–8px
radius: 4px               no arrow
```
Appears ~200ms after hover. Positioned above/below target with 4px offset.

### Zoom control
```
Pill shape, bottom-left of canvas
bg: white, 1px #E6E6E6 border, 4px radius
Contents: — button · percentage text · + button
Dividers: 1px #E6E6E6 verticals
```

### Count badge
```
small rounded-rect, 16–18px tall
bg: cobalt-20, color: cobalt-70
font: 600 10–11px
```
Red variant (red-20 bg, red-70 text) for issue counts.

### BETA pill
```
bg: peri-20 #E9EBFB       color: peri-80 #341A9E
font: 700 10px            padding: 2px 6px
fully rounded
```
Same shape reusable for NEW, PRO, etc.

### Drag handle
```
icon: ⋮⋮ (6 dots in 2 columns)
size: 12×16px             color: gray-40
Visible on hover only, left edge of draggable rows
```
Drag treatment: 0.9 opacity + subtle shadow on dragged row. Drop target: 1px cobalt-70 horizontal line.

### **Expression / Token Chip** — signature Bubble primitive

When dynamic data is inserted into a text field or expression, it renders inline as a chip:

```
Dynamic data:
  bg: purple-20 #F6ECF8    color: purple-70 #79059A
Static / data source ref:
  bg: cobalt-20 #EBF3FF    color: cobalt-70 #0C29AB

padding: 2px 6px
radius: 2px                 (small — intentionally less rounded than buttons)
font: 400 12px Open Sans
```

Chips flow inline with surrounding text — they're not block elements. This single component is THE most recognizable piece of Bubble's UI. If a surface ever shows expression tokens, use this chip treatment.

### Dashed "Add" chip (empty-state affordance)
```
border: 1px dashed gray-40  bg: transparent
color: gray-70              padding: 4px 8px
radius: 4px
font: 400 12px/16px
content: "Add" or "+ Add"
```
Used for required complex fields (Email to reset, Condition expression) — the dashed border = "tap to fill."

### Named color chip (CORE Bubble styling convention)

The way colors are almost always chosen in Bubble. Direct hex is an escape hatch; named variables are the norm.

```
[swatch 14×14 — 1px radius, almost square] [variable name — 12px gray-80] [⚡ lightning icon]
```

- **Swatch:** 14×14px, 1px radius, shows the color fill
- **Variable name:** e.g. `Text`, `Primary 20`, `Gray 40`, `Success 20` — 12px / 16px / 400 / gray-80
- **Lightning-bolt (⚡):** purple-60 `#9606BC`, 16×16, clickable — opens the dynamic data picker

This pattern appears everywhere colors are set: Text color, Background, Border color, Placeholder color, Shadow color. Use the named-swatch pattern by default. Only show raw hex when the user picks "custom color" from the picker.

### Lightning-bolt "Make dynamic" affordance

The ⚡ icon is how ANY value becomes runtime-driven. Appears flush right of any input that accepts dynamic expressions — text, numbers, colors, dates, selections, etc.

```
icon: ph ph-lightning (or equivalent), 16×16
color: purple-60 #9606BC (default)
hover: purple-70 #79059A
position: flush right of the input
```

**Behavior:** Click the lightning → the input converts to an **expression builder** (same dynamic data picker used in Workflows). Once a dynamic expression is set:
- Input background changes to purple-20 `#F6ECF8`
- Text renders as expression-chip tokens (see "Expression / Token Chip" above) in purple-70
- The lightning icon becomes filled / active

This is the universal mechanism across all surfaces for toggling static → dynamic. Always make the ⚡ available on inputs that can accept dynamic data; never hide it behind a menu.

### Segmented control

Used for 2–5 related options where one is selected at a time (layout mode picker, orientation, alignment grid, Builder/Responsive toggle).

```
track: bg gray-20 #F2F2F2, 4px outer radius, 2px inner padding
inactive segment: transparent bg, gray-80 text
active segment: white pill inside track, subtle shadow, gray-80 slightly bolder text, 2–3px inner radius
icon-first with 12px label below, OR icon-only (for alignment 5-icon rows)
```

Never use as a primary action — segmented controls are for state/view selection only.

### Empty-state template (consistent across editor)

Every surface with potential "nothing here yet" states uses this same template:

```
[illustration — gray-20 rounded-square panel, ~80–100px, monochrome icon inside (</> or similar)]
[headline — 12px/16px/700/gray-80]
[helper text — 12px/16px/400/gray-70, 2 lines max, ~260px wide, centered]
[ghost button — + icon + label, cobalt-70 text on transparent bg, hover → gray-10]
```

Examples:
- Conditional tab with no conditions → "No conditionals yet" + Add button
- Workflows section with none added → "No workflows added yet" + Add workflow button
- Empty workflow → large dashed `+ NEW EVENT` card in center of canvas

The consistency makes the editor feel like one app, not many.

---

### Sub-tab bar (underline style — different from segmented control)

Used when a surface has distinct sub-sections to navigate (e.g. Data Tab's Data types · Privacy · App data · Option sets · File manager). Also used on the Property Editor's Visual / Interaction / Conditional tabs.

```
height: 44px              bg: white
labels: 14px / 14px / 400 / gray-80    (← NOTE: 14px, not the default 12px)
active: 2px cobalt-70 underline + cobalt-70 text
inactive: share 0.5px #E6E6E6 bottom border with active
no pill track — just a continuous underline
gap between tabs: 24px
```

**When to use sub-tab bar vs. segmented control:**
- **Sub-tabs** → navigation between distinct sub-surfaces (change the whole workspace)
- **Segmented control** → picking one option among related states (e.g. layout mode, Builder/Responsive)

### Toolbar button cluster

Used on data tables and bulk-action surfaces. **Identical-looking outline buttons** differentiated only by their text labels — Bubble trusts labels over visual differentiation for transactional actions.

```
each button: 32px tall, 1px #E6E6E6 border, white bg, gray-80 text
font: 600 12px/16px Open Sans
radius: 4px               padding: 8px horizontal
```

Example cluster (App data): `New entry` · `Delete (0)` · `Upload` · `Modify` · `Export` · `Bulk`. Count affix (e.g. `Delete (3)`) in parentheses reinforces what a bulk op will affect. Disabled state: gray-40 text, no border change.

### Data grid / spreadsheet table

For any tabular data view (App data, File manager, future data tables).

```
Header row:
  bg: gray-10 #F7F7F7      labels: 12px / 16px / 600 / gray-80
  left-aligned, 8px horizontal padding
  sortable columns: add ▼/▲ triangle suffix in the header cell

Body rows:
  cells: 12px / 16px / 400 / gray-80
  left-aligned, 8px vertical padding
  hover: gray-10 bg fill
  separator: 1px #F2F2F2 horizontal line between rows
  NO vertical grid lines

Left column cluster (row actions):
  select checkbox + pencil/edit icon + optional action link (e.g. "Run as →")
```

Pagination affordances below the grid: `Load N more items...` or `No more items` as cobalt-70 links, left/right aligned.

Date formatting: human-readable (`Sep 30, 2025 10:17 am`), never ISO. File sizes: human-readable (`84.7 KB`). MIME types shown raw (`image/jpeg`).

### Notes drawer (universal entity annotation)

Every significant entity in the editor (data type, field, rule, option, step, element) has a notes bubble icon. Clicking opens a **right-side drawer**:

```
width: 450px                 bg: white
shadow: shadow-lightbox (or shadow-popover)
slides in from the right
full-height
```

**Contents:**
- Header: "Notes" title (12px 700 gray-80) + close X + right-aligned `View all notes (N)` link
- Breadcrumb subheader: context-aware, e.g. `Field - iossettings - field_1`, with a small icon prefix (12px 400 gray-60)
- State helper: `This note hasn't been updated yet` (italic gray-60) when empty
- Full-height textarea — placeholder `Add a note here...`
- Footer hint: `⊘ Notes save automatically` (gray-60)

This drawer is **universal** — any surface dealing with named entities should provide it.

### Overlay hierarchy — three distinct patterns

Bubble uses three different overlay patterns for different weights of interaction. Pick the right one:

| Pattern | When to use | Key differences |
|---|---|---|
| **Popover / menu** | Quick picks, dropdowns, action menus, dynamic data picker | Floating, no backdrop. 4px radius, menu shadow. ~200–280px. Closes on Escape / outside click / selection. |
| **Centered modal** | Creating named entities (new type, new rule, new view, new field) | Dimmed backdrop (`rgba(0,0,0,.3)`). ~340px wide white card, 4px radius, `shadow-lightbox`. Title (16px 700), form fields, footer with cobalt **CREATE** / **SAVE** button (uppercase) + gray "Cancel" link. |
| **Full-workspace takeover** | Transactional operations on data records (Create/Modify entry) | No centered card — fills the workspace area. Title centered at top. Form uses 2-column label-left grid (see below). Footer: cobalt CREATE / SAVE + Cancel link. |

**Why three patterns:** Popovers are lightweight and don't break flow; centered modals are for structured entity creation; full-workspace takeover signals "this is a transactional data operation, don't casually interleave."

### Centered modal dialog (structured entity creation)

```
backdrop: rgba(0,0,0,.3)
card: white, 4px radius, shadow-lightbox, centered
width: ~340px (variable by content)
padding: 20–24px
```

**Contents:**
- Title: 16px 700 gray-80, left-aligned
- Form fields stacked (labels above inputs — the standard editor pattern)
- Optional checkbox (e.g. "This field is a list", "Make private by default")
- Footer (centered or right-aligned):
  - Primary: cobalt-70 filled button with **UPPERCASE label** (`CREATE`, `SAVE`, `DELETE`)
  - Secondary: gray "Cancel" link (no button chrome)

Uppercase primary-button labels are specific to modal-committed actions (CREATE / SAVE). In-flow buttons (Deploy, + New) use Title Case.

### 2-column label-left form grid (database modals only)

Used exclusively for Create / Modify Entry modals in the Data tab — **not** for Workflow or Design Tab forms, which use top-aligned labels. The difference communicates "this is a database record form, not UI configuration."

```
label column: ~120px wide, right-aligned, 12px 400 gray-70
input column: ~250–300px wide, standard input styling
fields flow left-to-right then wrap
row gap: 12px
```

### Destructive environment link (red-70 hypertext)

Used **only** for admin-level actions that affect data stores across environments:
- `Switch to live database`
- `Copy and restore database`

```
display: inline text link (no button chrome, no border, no bg)
color: red-70 #B0200C
font: 400 12px/16px Open Sans
hover: underline appears
```

Never used for element deletion (trash icons) or form cancels (gray "Cancel" links). The red hypertext treatment is reserved for dangerous-but-not-hidden admin affordances.

## Keyboard Shortcuts (observed editor-wide)

| Shortcut | Behavior |
|---|---|
| Escape | Closes any popover/menu |
| Enter | Confirms inline edit |
| Cmd/Ctrl+Z | Undo |
| Shift+Cmd/Ctrl+Z | Redo |
| Cmd/Ctrl+F | Opens "Find element" search |
| Tab | Moves between fields in the properties panel |

---

## Accessibility

- Every interactive element has an `aria-label` or visible text
- Tree items use `role="treeitem"` with expand-state attributes
- Focus rings are subtle: 2px cobalt-70 outline, 1px offset — visible but not loud
- Contrast: gray-70 on white passes AA; cobalt-70 primary button passes AAA

---

## Anti-patterns — what's NOT in the Bubble UI

Avoid these when building Bubble-flavored prototypes:

- **No gradients** anywhere in the editor chrome
- **No fully-rounded pills** (except badges and the zoom control)
- **No drop shadows on in-flow elements** — only floating surfaces
- **No dark mode** (as of this writing)
- **No emoji in UI copy**
- **No UPPERCASE labels** (except small section dividers in popovers)
- **No skeuomorphic icons** — only 1.5px stroke line icons
- **No 14px or 16px as default UI size** — 12px is the Bubble default
- **No radii > 4px** on standard UI (8px / 12px reserved for special cases)
- **No Inter, Roboto, or system-ui as primary font** — Open Sans or it doesn't look like Bubble
- **No raw palette values** when a semantic token fits

---

## Tailwind Theme (copy-paste ready)

```js
module.exports = {
  theme: {
    extend: {
      fontFamily: {
        sans: ['"Open Sans"', 'Helvetica', 'Arial', 'sans-serif'],
        display: ['FoundersGrotesk', 'sans-serif'],
      },
      fontSize: {
        xs: ['12px', '16px'],
        sm: ['14px', '20px'],
        base: ['16px', '16px'],
      },
      colors: {
        cobalt: { 10:'#F5FAFF',20:'#EBF3FF',30:'#D5E5FB',40:'#AFCEF8',50:'#1E6DF6',60:'#0947D7',70:'#0C29AB',80:'#091E7C',90:'#051043' },
        gray:   { 10:'#F7F7F7',20:'#F2F2F2',30:'#E6E6E6',40:'#C7C7C7',50:'#A6A6A6',60:'#8A8A8A',70:'#525252',80:'#1A1A1A' },
        green:  { 10:'#F5FAF6',20:'#EAF5ED',30:'#CFE8D5',40:'#B7DCBF',50:'#2EA84A',60:'#26883C',70:'#1E6C30',80:'#175425' },
        red:    { 10:'#FEF6F5',20:'#FDEAE7',30:'#FBD0CB',40:'#F9B3A9',50:'#EF2F15',60:'#CD260E',70:'#B0200C',80:'#941B0A' },
        orange: { 10:'#FFFAF5',20:'#FFF4E5',30:'#FFE3C2',40:'#FFD6A3',50:'#FF9A1F',60:'#F58700',70:'#D17400',80:'#8F4F00' },
        sky:    { 10:'#F5FBFF',20:'#E6F6FE',30:'#D3EFFD',40:'#B0E3FC',50:'#61CAFF',60:'#09A4F1',70:'#0789CA',80:'#056494' },
        yellow: { 10:'#FFFAF0',20:'#FFF4DB',30:'#FFEFC7',40:'#FFDC8A',50:'#FFB505',60:'#EBA500',70:'#DCA114',80:'#B88100' },
        purple: { 10:'#FAF4FB',20:'#F6ECF8',30:'#E9D2EF',40:'#DEBBE7',50:'#AE07DA',60:'#9606BC',70:'#79059A',80:'#5B0372' },
        peri:   { 10:'#F2F3FD',20:'#E9EBFB',30:'#D8DBF9',40:'#BDC3F4',50:'#625DFE',60:'#513EDF',70:'#401FC1',80:'#341A9E' },
        livid:  { 10:'#F2F5F9',20:'#E4EAF1',30:'#CAD5E2',40:'#AFC0D4',50:'#849FBD',60:'#69809B',70:'#415162' },
        cyan:   { 10:'#F2FEFD',30:'#BBF9F7',60:'#34C3BE' },
      },
      borderRadius: { sm:'2px', DEFAULT:'4px', md:'8px', lg:'12px' },
      boxShadow: {
        menu:    '0px 2px 8px rgba(0,0,0,.10), 0px 1px 2px rgba(0,0,0,.10)',
        alert:   '0px 2px 8px rgba(0,0,0,.10), 0px 1px 2px rgba(0,0,0,.10)',
        popover: '0px 1px 2px rgba(0,0,0,.10), 0px 6px 12px rgba(0,0,0,.12)',
        lightbox:'0px 1px 2px rgba(0,0,0,.10), 0px 8px 24px rgba(0,0,0,.15)',
      },
      spacing: { reg:'8px', tv:'12px' },
    }
  }
}
```

---

## How to Use This Document

When building anything that should look like part of the Bubble editor:

1. Load **Open Sans** and **Phosphor Icons** at the top of every HTML file
2. Copy the Tailwind config above (or inline via `<script>tailwind.config = {...}</script>`)
3. Default to `text-xs` (12px/16px), `font-sans`, `text-gray-80` for body text
4. Use `cobalt-70` for primary actions, `bg-gray-10` for secondary surfaces, `border-gray-30` for dividers
5. Use **purple** (`text-purple-70` / `bg-purple-20`) for dynamic data references — the signature pattern
6. Always check the specific surface's `design-ux.md` file for surface-specific patterns (e.g. `context/bubble-editor-kit/product-surfaces/workflow-editor/design-ux.md`)
7. Refer to actual screenshots in `context/bubble-editor-kit/product-surfaces/<surface>/screenshots/` for pixel-level reference before building
