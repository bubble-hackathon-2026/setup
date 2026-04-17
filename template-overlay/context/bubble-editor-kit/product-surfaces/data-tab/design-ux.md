# Data Tab — Design & UX

> Read this alongside `context/bubble-editor-kit/product-surfaces/data-tab/README.md` (functional), `context/bubble-editor-kit/product-surfaces/data-tab/ux-research.md` (raw source), and `context/bubble-editor-kit/reference/design-language.md` (global tokens and components). Screenshots in `screenshots/` are the authoritative visual reference.

---

## Layout Break — the Data Tab doesn't use the 3-panel shell

The Data Tab is different from every other surface documented so far. It **does not have** a right-hand properties panel, and it **does not** use the icon-rail-anchored chrome-around-a-canvas layout. Instead:

- Standard outer chrome persists (44px top menu bar, 40px left icon rail with **Data** as the active mode).
- Below the top bar is a **horizontal sub-tab bar** (~44px): **Data types** · **Privacy** · **App data** · **Option sets** · **File manager**.
- Each sub-tab drives a **full-width workspace** — no right inspector.
- Three of five sub-tabs (Data types, Privacy, Option sets) use a **two-column master-detail pattern**: ~400px left list + flex right detail.
- Two sub-tabs (App data, File manager) use a **spreadsheet / data-grid pattern**.

### Sub-tab bar spec (cross-editor pattern — now in `design-language.md`)

- Label font is **14px / 14px / 400 / gray-80** — notably larger than the 12px default used elsewhere in the editor. These tabs are intentionally more prominent.
- Active tab: **2px cobalt-70 underline** + cobalt-70 text.
- Inactive tabs share a 0.5px `#E6E6E6` bottom border with the active one, creating one continuous underline.
- No segmented-control track; this is the pill-less tab bar pattern.

---

## 1. Data types (schema)

**Layout:** ~400px left master list + flex right detail panel.

### Left column — master list
- Section title "Data types" (14px / 16px / 700 / gray-80)
- Search input: magnifier + "Data types" placeholder
- List rows (32px):
  - Type name — cobalt-70 when selected, gray-80 otherwise
  - Right-aligned gray-60 caption: `Publicly visible` or `Privacy rules applied`
  - Trash icon (16×16 gray-40, on hover)
  - Selected row: cobalt-20 bg + cobalt-70 text
- **"Bubble AI" promotion card** below the list — 1px `#E6E6E6` border, 4px radius, sparkle icon + "Bubble AI" label on left, cobalt-70 filled **Generate data types** button on right. (AI offering is treated as an "add-on," not part of the core create flow.)
- **"New type" creation card** at the bottom — 1px `#E6E6E6` border, gray-10 bg, form:
  - "New type" label + text input
  - "Make this data type private by default" heading + "Things are visible to everyone" helper line + right-aligned cobalt checkbox
  - Gray "Create" button bottom-right (activates to cobalt-70 when name filled)

### Right column — Fields for type X
- Title: "Fields for type {name}"
- "Type name" row: label + inline-editable text input + notes bubble icon
- **Fields table** — no visible cell borders, row-based layout:
  - Col 1: field name (inline-editable input)
  - Col 2: field type (plain text, e.g. "text", "date", "User")
  - Col 3: default value (input placeholder, or gray-60 italic "Built-in field" for system fields)
  - Col 4 (hover only): notes + trash icons
- Built-in fields (non-deletable): **Creator** (User), **Modified Date**, **Created Date**, **Slug**. User type built-ins: **email**, **Modified Date**, **Created Date**, **Slug**.
- **"Create a new field"** ghost button at bottom (1px `#E6E6E6` border, cobalt-70 text)

### "Create a new field" modal
Centered modal, ~340px wide, white bg, 4px radius, lightbox shadow:
- Title "Create a new field" (16px 700 gray-80)
- "Field name" text input
- "Field type" searchable dropdown
- "This field is a list (multiple entries)" checkbox
- Footer: cobalt **CREATE** button (uppercase!) + "Cancel" link

### Field type dropdown (inside the modal)
Searchable, categorized with uppercase gray-60 10px section headers:
- **DATA TYPES** — every custom data type (User, Employee, Product, etc.)
- **BASIC TYPES** — text, number, numeric range, date, date range, date interval, yes/no, file, image, geographic address
- **PLUGIN TYPES** — types exposed by installed plugins (API Connector etc.)

---

## 2. Privacy (row-level security per type)

**Layout:** Same two-column as Data types. Left list identical. Right panel shows "Privacy rules for type {name}".

### Empty state (right panel)
- Centered title "Privacy rules for type X"
- Helper: "This type is visible by everyone. You can create a rule if you want to restrict access"
- Cobalt-outlined **Define a new rule** button (white bg, 1px cobalt-70 border, cobalt-70 text)

### Rule card (once created)
~700px wide card, 1px `#E6E6E6` border, 4px radius, white bg, 20px padding:
- `Name` label + text input (rule name), right-aligned notes + trash icons
- `When` label + **expression field**:
  - Empty: contains the dashed "Add" chip
  - Filled: cobalt-70 token string reading like natural English (e.g. `Current User is This User`)
  - The field border is lighter than standard inputs (`#F2F2F2` vs `#E6E6E6`) and has more vertical padding
- "Users who match this rule can..." subtitle
- 2×2 checkbox grid: `View all fields` · `Find this in searches` / `View attached files` · `Allow auto-binding`

Multiple rule cards stack vertically. Rule cascade is top-down; first matching wins.

### "Everyone else (default permissions)" card
Always present at the bottom. When `View all fields` is **unchecked**, the card expands to reveal:
- A 2-column indented **field-level permission grid** — every field in the type gets its own checkbox (api-test, Created Date, Modified Date, Slug, email, etc.)
- Below: a separate cluster with `Find this in searches`, `View attached files`, `Allow auto-binding` as standalone toggles

**Define a new rule** button sits below the Everyone-else card.

---

## 3. App data (database browser)

**Layout:** Two-column — narrower left sidebar (~245px) + full spreadsheet-style grid on the right.

### Top strip (full width)
- Title: `Application data - {view name} - Development version` (12px 400 gray-80)
- Right-aligned **red-70 destructive environment links** (no button chrome):
  - `Copy and restore database`
  - `Switch to live database`

### Toolbar row
- Left: search input with magnifier + "Search for data entries"
- Entry count: `N entries (displaying N)` (12px 400 gray-60)
- Right: **identical-looking outline-button cluster**, 32px tall, 1px `#E6E6E6` border, white bg, gray-80 text:
  - `New entry` · `Delete (0)` · `Upload` · `Modify` · `Export` · `Bulk`
  - All buttons look identical — Bubble trusts labels over visual differentiation. `Delete (0)` shows count in parentheses and grays out when no selection.

### Left sidebar
- Two side-by-side cobalt-outlined buttons: `New view`, `Edit primary fields`
- Search input "Views or data types"
- Views list:
  - Built-in: `All Employees`, `All iossettings`, `All Products`, `All Stores`, `All test_dts`, `All Users`
  - Each row: view name (bold when selected) + right-aligned copy + pencil icons
  - Custom views (e.g. `All Users modified`) indented under their parent type
  - Selected view: cobalt-20 bg + cobalt-70 text

### Data grid
- Header row: 12px 600 gray-80 labels on gray-10 bg
- Left columns: select-all checkbox + icon column + data columns
- Row leftmost cluster: selection checkbox + pencil (edit) icon + **`Run as →`** link (cobalt-70, User type only — launches a preview session as that user)
- Cells: 12px 400 gray-80, left-aligned, 8px vertical padding
- Dates: human-readable `Sep 30, 2025 10:17 am`
- **`2 additional fields`** link (right-aligned above grid) — expands hidden columns
- No vertical grid lines; 1px `#F2F2F2` horizontal separators
- Row hover: gray-10 bg fill

### Bottom strip
- Left: `Refresh data` (cobalt-70 link)
- Right: `Load 50 more items...` (cobalt-70 link) or `No more items` caption

### Create / Modify Entry modal (full-workspace takeover)
- Takes over the entire workspace — not a floating centered card
- Title centered at top (`Create a new database entry` / `Modify an existing database entry`)
- `Type of thing` dropdown (first field)
- **2-column label-left form grid** — labels right-aligned ~120px wide, inputs ~250–300px wide. Fields flow left-to-right then wrap.
  - Modify mode shows ALL fields pre-populated, including built-ins (`Created Date`, `Modified Date`, `Unique id` — all editable!)
  - Create mode hides built-ins
- Footer: centered cobalt **CREATE** / **SAVE** button + right-aligned "Cancel" link

---

## 4. Option sets (enums with metadata)

**Layout:** Same master-detail two-column as Data types / Privacy.

### Left column
- Option sets list (no privacy captions — option sets aren't governed by privacy)
- Trash icons on hover
- Bottom creation card: `New option set` label + input + gray Create button (no private-by-default toggle)

### Right column — "Attributes and options for set X"
Two stacked sections separated by a thin rule:

**Attributes** (fields that describe each option)
- Same no-border table layout as Fields in Data types
- Every option set has a built-in `Display` attribute of type `text` (gray-60 "Built-in attribute" caption)
- `Create a new attribute` ghost button

**Options**
- Each row: Display value (inline-editable input) + `Modify attributes` (gray-60 placeholder link) + notes + trash icons
- Bottom: `New option` label + input + gray Create button

**Mental model:** Option sets = enums with typed per-option metadata (color, sort order, icon, etc.). Display is the label; attributes travel with each option.

---

## 5. File manager

**Layout:** Full-width, single-panel (breaks the master-detail pattern of the schema tabs).

- Title: "File manager" + right-aligned red-70 `Switch to live database` link
- Filter bar: `File name` input + `File type` dropdown (default "All files") + `Only private files` checkbox
- Right-aligned actions: `Search` (cobalt-outlined) + `Delete` (grayed until selection) + `Upload`
- `Showing files N - N of N` caption
- Data grid columns: checkbox | icon | File name | Size | Type | `Upload date ▼` (sortable) | User ID | Attached to
  - Size: human-readable (`84.7 KB`)
  - Type: MIME (`image/jpeg`)
  - Attached to: link to the Thing referencing this file (blank if orphaned)
- Footer: `No more items` or pagination

---

## Global UX patterns (Data-tab specific)

### Schema vs. Content separation
- **Schema tabs** (Data types / Privacy / Option sets) = structure, deployed with the app
- **Content tabs** (App data / File manager) = runtime data, separate Dev/Live environments
- Mental model shifts between them; the red-70 destructive links only appear on content tabs

### Dual environment (Dev/Live)
The red-70 hypertext-style links (`Switch to live database`, `Copy and restore database`) communicate "this affects production data." Deliberately alarming. Never used for element deletion or form cancels.

### Inline editing everywhere
Type names, field names, rule names, option values — all directly editable in place. No "rename" modals in schema editing. Auto-saves on blur.

### Notes system (universal — also cross-editor)
Every major entity (type, field, rule, option) has a notes bubble icon. Click opens a **right-side drawer** (see `design-language.md` for the global spec):
- 450px wide, white bg, shadow, slides in from the right
- Breadcrumb subheader: `Field - iossettings - field_1`
- Placeholder: `Add a note here...`
- Footer hint: `⊘ Notes save automatically`

### Confirmation patterns
- No undo toast — trash icons trigger browser `confirm()` dialogs
- Bulk ops show count in button label: `Delete (3)`
- Schema changes: immediate; data changes: affect the selected environment only

### "Run as →" (User type only)
Each user row has a `Run as →` link — launches a preview session as that user. Distinctive affordance for auth testing.

### Privacy indicator captions
The `Publicly visible` / `Privacy rules applied` captions are gray-60 12px, no background. Deliberately honest: when all rows show "Publicly visible," the developer immediately knows there's no row-level security.

---

## UX Principles (Data Tab additions)

1. **Schema is code, data is content.** Sub-tab ordering (types → privacy → data → option sets → files) reflects a "build schema first, manage data second" workflow. Privacy between the two is intentional — impossible to ignore.
2. **Dangerous actions are always red, never hidden.** Dev/Live switches and field-level permission unchecks are visually loud.
3. **Built-in fields are informational, not editable.** Gray-60 italic "Built-in field" is a hard UI boundary.
4. **Privacy is opt-in with public default.** New types default to publicly visible. Privacy indicators make the state visible at a glance. Philosophy: trust developers to tighten.
5. **The grid is the record.** App data uses a real spreadsheet pattern (rows, columns, sort, search, bulk) because that's the mental model users have for databases.
6. **Notes are universal.** Every significant entity gets a notes drawer — documentation in place for team knowledge transfer.
7. **Modals lock the full workspace.** Unlike Design-tab popovers that float alongside panels, Data tab modals take over (Create/Modify entry) or center with a backdrop (Create type, Create rule, Create view). Data operations are transactional.

---

## Screenshots Map

Files live in `./screenshots/`.

| Screenshot | What it demonstrates |
|---|---|
| `Data Tab - Data Type - 1.png` | Data types sub-tab with Store type selected; master list + field table + Bubble AI card + New type card |
| `Data Tab - Data Type - add field.png` | Create a new field modal with the categorized Field type dropdown open (DATA TYPES / BASIC TYPES sections) |
| `Data Tab - Data Type - referenced field.png` | Employee type showing a Store reference field (type: Store, not a basic type) |
| `Data Tab - App Data - Users - View.png` | App data sub-tab — spreadsheet grid, left sidebar of views, toolbar button cluster, Run as → affordance on User row |
| `Data Tab - Option Sets - Example.png` | Option sets sub-tab showing Opt-Role with Attributes + Options sections and reorderable option rows |
| `Data Tab - Privacy Rule - Example.png` | Privacy rules screen with "Self" rule, expression-token When clause, 2×2 permission grid, Everyone-else expanded with field-level permissions |
| `Data Tab - File Manager.png` | File manager — full-width filter + table layout, red-70 Switch to live database link |

---

## Cross-Surface Interactions

- **Design Tab → Data Tab:** "Type of content" dropdowns on data-bound elements in the Property Editor reference Data Types defined here.
- **Workflow Editor → Data Tab:** `Make changes to a thing` / `Create a new thing` / `Delete thing` actions operate on Data Types defined here.
- **API Connector → Data Tab:** Plugin-exposed types show up under "PLUGIN TYPES" in the field-type dropdown.
- **Runtime Debugger → Data Tab:** Debugger's Evaluator panel shows live field values for the current data context; developers often cross-reference against App data to verify.
- **Settings Panel → Data Tab:** The Settings > API sub-tab controls whether Data Types are exposed via the Data API externally.
