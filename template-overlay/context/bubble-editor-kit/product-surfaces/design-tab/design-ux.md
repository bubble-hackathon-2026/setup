# Design Tab — Design & UX

> Read this alongside `context/bubble-editor-kit/product-surfaces/design-tab/README.md` (functional description) and `context/bubble-editor-kit/reference/design-language.md` (global tokens, components, cross-editor patterns). The screenshots in `screenshots/` are the authoritative visual reference.

---

## Layout Anatomy — the 4-column shell

Same outer chrome as every other tab (44px top menu bar, 40px left icon rail). The middle is:

- **Icon rail (40px)** — Persistent mode switcher. Design icon is active, highlighted cobalt-70 with cobalt-20 rounded background.
- **Left panel (~240px)** — Two stacked sections:
  1. **Elements Tree** at the top with a `Builder` / `Responsive` segmented toggle and a collapse icon.
  2. **Element library** below — searchable lists of Visual Elements, Containers, Input Forms, and Reusable Elements. Element rows are 32px tall with a 16px icon + label.
- **Canvas (flex, `#F7F7F7` gutter around a white page)** — Shows the page as it will render, with cobalt-70 selection outlines and tiny 10px red-70 pixel-measurement captions at the edges of hovered/selected elements.
- **Right panel (~270px)** — Properties, three tabs: **Visual**, **Interaction**, **Conditional**. Same 4px radius, 12px type as the Workflows panel.

## Top menu bar additions (Design-specific)

Beyond the standard top bar (see `design-language.md`):

- **Zoom dropdown** (`70%`, `50%`, `100%`, etc.) — just left of the search icon.
- **View mode icon** (cube / 3D) — toggles edit vs visual preview.
- **Issue count** ⚠ with red badge (e.g. "6") — click opens a panel of layout/binding problems.
- **Preview** — split button: main action launches preview; caret opens breakpoint and debug options.

---

## The Three Right-Panel Tabs

### Visual tab (appearance + layout)

Sections appear in this exact order, each collapsible with a triangle caret:

1. **Content** — Element-specific. Input: Placeholder, Auto-binding toggle, Initial content. Alert: Text. File uploader: Placeholder, Upload button with lightning-bolt (⚡) dynamic-data affordance on the right.

2. **Size** — Width and Height each have two fields: a **mode dropdown** (`Fixed` / `Fit` / `Fill` / `%`) paired with a **numeric input + unit dropdown** (`px` / `%`). `Fit` mode reveals Min/Max height.

3. **Layout**
   - **Position** — 3×3 grid picker (9 dots) for alignment, with two dropdowns (`Top` / `Left` / etc.) beside it.
   - **Order** — 4 icon buttons: Make first (⏮), Previous (↑), Next (↓), Make last (⏭).
   - **Spacing** — Padding and Margin, each with paired inputs (vertical, horizontal) with direction icons, plus an expand-to-4-sides icon on the right.

4. **Configure** — Element-specific binary toggles (e.g. "Position the alert at the top").

5. **Style** — Single row showing the current style name (e.g. "Standard") with an `Overridden` caption badge (10px / 16px / 600 / livid-70 `#415162`) when the style has been locally modified. On the right: pencil (edit) and chain-link (unlink/reset) icons.

6. **Text** — Font dropdown (`App Font (Inter)`), weight dropdown (`400`), size dropdown (`16px`), 3 alignment icons (left/center/right), 3 style icons (B / I / U), and a `⋯` overflow that opens a popover titled "Text Properties" with Word/Line/Letter spacing dropdowns. Color row uses the **named swatch chip** pattern (see design-language.md — this is a core cross-editor pattern).

7. **Placeholder** — Same swatch + lightning pattern as Text. Typically "Gray 40".

8. **Appearance** — Opacity (draggable input with `⋮⋮` grip on the left, `%` suffix), Radius (small corner-icon prefix, expand-to-4-corners icon on the right).

9. **Border** — Collapsed by default; `+` / `−` affordance in the section header. Expanded: style dropdown (`Solid` / `Dashed`), width input + px, expand-to-4-sides icon, color swatch.

10. **Background** — Swatch with named color (e.g. "Primary 20" or hex "#FFFFFF") + opacity % + lightning-bolt.

11. **Shadow** — Collapsed by default with `+`.

### Interaction tab

1. **Workflows** — Empty state: "No workflows added yet." with `Add workflow (⌘+K)` secondary button (bordered, full-width). Populated: lists workflows linked to this element.
2. **Visibility** — `Visible on page load` toggle (cobalt-70 when on), `Collapse when hidden` toggle, info icons (ⓘ) on labels.
3. **Options** — Element-specific toggles: `Submit on 'Enter'`, `Make required`, `Make disabled`.
4. **Transitions** — List with `+` to add. Each row: property name (e.g. "Border color") + duration/easing (e.g. "200, ease") right-aligned in gray-60.
5. **Advanced** — `ID Attribute` textbox for setting a CSS id on the element.

### Conditional tab

- Header `All conditionals` with expand icon + `+` icon.
- `N inherited from Style` collapsible row at top — shows how many conditions come from the shared style.
- Empty state (see design-language.md's empty-state template): gray-20 rounded-square with `</>` icon, "No conditionals yet" headline, helper text, ghost button `+ Add a conditional`.

---

## Element-Specific Content Sections

The Content section of the Visual tab varies by element type:

| Element | Content fields |
|---|---|
| **Alert** | Text |
| **Link** | Text, Destination |
| **Text** | Text (rich text editable) |
| **Input** | Placeholder, Auto-binding toggle, Initial content (with ⚡) |
| **MultilineInput** | Same as Input |
| **Checkbox** | Label, Default value |
| **Image** | Image source (static/dynamic), object-fit dropdown |
| **SliderInput** | Type (`Simple` / `Range` dropdown), Orientation (`Horizontal` / `Vertical` segmented), Step value, Handle color |
| **Date/TimePicker** | Placeholder, Default date, Min/Max date |
| **RadioButtons** | Choices, Default value, Orientation |
| **FileUploader** | Placeholder, Auto-binding, Initial content + Upload button |
| **PictureUploader** | Same as FileUploader + dimension constraints |
| **Searchbox** | Placeholder, Search source |
| **Dropdown** | Choices, Default value, Placeholder |
| **HTML** | Raw HTML code block |
| **Table / RepeatingGroup** | Data source, Layout style dropdown, rows/columns config |
| **Group (container)** | Layout section: Container layout segmented (Column / Row / Align / Fixed) with icons, 5-icon container alignment control, Gap input |

---

## Page-Level Properties

When nothing is selected, the right panel shows the page itself. Layout section reveals the signature Bubble flex controls:

- **Container layout** — 4-option segmented control with icons:
  `↓ Column` | `→ Row` | `⊚ Align` | `⊞ Fixed`
  Active option has white background on a gray-10 track.
- **Container alignment** — 5-icon grid showing Top/Center/Bottom × Left/Center (icons vary by container type).
- **Gap** — single numeric input with gap-icon prefix.
- **Configure** — Page folder dropdown, `Make this page Native Mobile` toggle, Mobile version selector.

---

## Core Interaction Vocabulary

### Add elements
- Drag from the left library onto the canvas — snap guides appear as 1px cobalt-70 dashed lines.
- Search the library via the top field (`Search elements`).
- `Install More` at the bottom of each library section opens the plugin marketplace.
- `+ New Reusable` at the very bottom creates custom components.

### Select & arrange
- Click any element on canvas → cobalt-70 outline + small cobalt-70 label chip floating above its top-left.
- Red measurement labels (10px / red-70) appear around the element while selected.
- Click empty space → selects the page root.
- Shift+click → add to selection.
- Drag on canvas to reposition (when not inside a Fixed container).

### Right-click context menu

18+ options observed in a single menu. Shortcut hints right-aligned in gray-60.

- **Delete** — `delete`
- **Replace the element type** — swap one element for another without losing bindings
- **Convert to a reusable element**
- **Start/Edit workflow** — `⌘+K`, jumps to Workflows tab for this element
- **Group elements in** — submenu with container types (Group, RepeatingGroup, etc.)
- **Cut / Copy / Copy to another app / Paste** — `⌘+X / ⌘+C / ⌘+V`
- **Copy special / Paste special** — submenus for partial copies (styles only, etc.)
- **Select all** — `⌘+A`
- **Select first parent** — navigate up the tree
- **Bring to front / Send to back**
- A **See reference** chip floats next to the menu — opens docs for the element type.

### Style elements
- Every color input accepts: hex, named swatch from the style system, or dynamic expression via lightning-bolt.
- Every numeric input accepts direct typing, drag-to-scrub (inferred), or dropdown presets.
- Typography controls are unified across all text-bearing elements: Font + Weight + Size + Align + B/I/U + overflow.
- Expand-to-4-sides icon (`⧉`) next to padding / margin / radius / border opens a detailed 4-side view.
- Chain-link icon next to Style name unlinks the element from its shared style.

### Responsive design
- Top-of-sidebar `Builder` | `Responsive` toggle switches mode.
- Responsive mode adds a top strip of breakpoint tabs: `1200 | ★ Default | 992 | 768 | 320 | +` (★ = base breakpoint, `+` adds custom).
- Bottom-left of sidebar gains a live debug inspector: `Page 1080px`, `Parent container 1080px`, `Element 250px` (cobalt-70 numbers), plus a **Page states** section for simulating states like "User logged out."

### Inspect & navigate
- Top menu `Find element...` field (magnifier) jumps to any element by name.
- Elements Tree mirrors the canvas as a collapsible tree — click to select, drag to reparent.
- Top-bar breadcrumb updates to show the selected element (e.g. "Input A" with X to deselect).

---

## Design-Tab-Specific Signature Patterns

### Selection overlay on canvas
- 1px cobalt-70 solid outline around selected element
- 8×8 cobalt-70 drag handles at corners + midpoints
- Small cobalt-70 label chip above top-left: dark blue fill, white text, 10px / 16px / 400, 4px horizontal padding, 2px radius — shows element type/name (e.g. `⇶ Input A`)
- Red 10px / red-70 pixel-measurement captions at element edges (non-selectable chrome)

### Color picker popover
When you click any color swatch:
- Title bar with section name ("Background", "Border", "Text") + close X
- 4-tab icon row: solid fill · gradient · image · video
- Classic HSL saturation/lightness square (~240×160)
- Hue slider below, opacity slider below that
- Hex input + opacity % field at the bottom
- **Variables section** with list-view toggle and `+` to add — 5-column × 7-row grid of ~24×24 swatches in cobalt / white / black / red / green / yellow rows, each row going light-to-dark
- Popover: white, 4px radius, menu shadow, ~250px wide

### Canvas visual details
- Gutter: `#F7F7F7` soft gray around the page
- Page: pure `#FFFFFF` with 1px livid-20 (`#E4EAF1`) outline showing page bounds
- Table/grid elements: 1px gray-30 cell borders
- Snap guides (while dragging): 1px cobalt-70 dashed lines
- Empty text elements: italic gray-70 "edit me..." placeholder
- Links: cobalt-70 text with underline
- Alerts: rounded 4px semantic-tinted bg (green bg for success, etc.) with darker text in the same hue
- Slider: cobalt-70 filled track portion, cobalt-20 unfilled, cobalt-70 square handle
- Radio buttons: cobalt-70 filled circle when selected, gray-40 border when empty
- Checkbox: gray-40 1px border, cobalt-70 fill with white checkmark when checked
- File uploader: button-style pill — white bg, gray-30 border, "Click to upload a file"
- Picture uploader: bordered square with centered "Click to upload an image"

### Style system linkage (Overridden indicator)
Every element linked to a shared style shows a **Style** section with the style name + pencil + chain icons.
- **Pencil** → edits the shared style (jumps to Styles tab).
- **Chain** (broken links icon) → unlinks this element's styles from the shared style.
- When any property has been locally changed, an **Overridden** caption appears in livid-70 `#415162`, 10px / 16px / 600, next to the style name.

---

## UX Principles (Design-tab additions)

Beyond the 7 workflow-editor principles (see `context/bubble-editor-kit/product-surfaces/workflow-editor/design-ux.md`):

1. **Every numeric has a unit.** Inputs show `px` / `%` / `em` as a dropdown suffix — never inferred. Makes the editor feel precise and mirrors the CSS mental model.
2. **Named variables over raw values.** Color, font, spacing systems all reward naming. Raw hex/px is an escape hatch, visually de-emphasized.
3. **Dynamic data is purple.** Across the entire editor: any value that can come from runtime data uses purple (⚡ icon, chip background, token styling). Static values stay gray/cobalt.
4. **Expand-where-you-need.** Paired inputs (margin, padding, radius, border) default to a simple 2-input view; each has an "expand to 4 sides" icon for fine-grained control.
5. **Selection scales to context.** Selecting an element, a group, or the page itself all use the same right-panel shell — no mode switches, just different available sections.
6. **Preview always one click away.** Deploy is always visible, but so is Preview (with its own dropdown for breakpoint / debug modes). Editing and testing stay in constant contact.
7. **Red for geometry, cobalt for selection.** Red pixel labels = "this is a measurement." Cobalt outlines = "this is selected." Never swapped.

---

## Keyboard Shortcuts (Design tab)

See `design-language.md` for cross-editor shortcuts. Design-tab specific:

| Shortcut | Behavior |
|---|---|
| `delete` | Delete selected element |
| `⌘+K` | Start/edit workflow for selected element |
| `⌘+X` / `⌘+C` / `⌘+V` | Cut / copy / paste element |
| `⌘+A` | Select all |

---

## Screenshots Map

Files live in `./screenshots/`.

| Screenshot | What it demonstrates |
|---|---|
| `Editor - Canvas - Elements Tree - Containers and Input Forms.png` | Left panel showing element library with Containers and Input forms sections; empty canvas; no selection |
| `Editor - Canvas - Elements Tree - Visual Element Options.png` | Same panel showing Visual Elements section populated |
| `Editor - Canvas - Button Element.png` | Button selected on canvas — cobalt-70 outline, red pixel measurements, right panel populated with Content / Size / Layout / Style / Text sections for the Button |
| `Editor - Canvas - Button Element - 2.png` | Same Button element, different right-panel state (or scrolled further in the property editor) |

---

## Cross-Surface Interactions

- **To Workflow Editor:** `⌘+K` or "Start/Edit workflow" jumps here with this element as the pre-wired event source.
- **To Styles Tab:** Pencil icon next to the Style name opens that style's definition in the Styles tab.
- **To Data Tab:** "Type of content" dropdown on data-bound elements references Data Types defined in the Data Tab.
- **Property Editor:** The right panel *is* the Property Editor. When someone says "Property Editor" they mean the 3-tab panel described here. See `context/bubble-editor-kit/product-surfaces/property-editor/` for a focused reference.
