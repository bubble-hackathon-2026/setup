# Expression Picker (Dynamic Data Picker)

## What It Is
The Expression Picker — also called the Dynamic Data Picker — is the universal dropdown that appears anywhere a field can accept a dynamic value. It's not a standalone "tab" like Design or Workflow, but a cross-surface primitive that shows up in Property Editor inputs, Workflow action fields, conditional expressions, the Styles tab, Data Tab privacy rules, and backend workflows. Learning how this picker feels is essential to making a Bubble-flavored prototype convincing — it's the single most-recognizable interaction in the editor, along with the purple expression chips it produces.

The picker opens in two ways:
1. Clicking the **lightning-bolt ⚡ icon** (purple-60 `#9606BC`) flush-right of any input — this converts a static input into a dynamic expression builder.
2. Clicking directly inside an already-dynamic input (purple-20 `#F6ECF8` background) to extend or edit the existing expression.

Once a dynamic value is in place, it renders inline as a **purple token chip** (purple-20 bg, purple-70 text, 2px radius) — see `context/bubble-editor-kit/reference/design-language.md` for the chip spec.

## Key Behaviors

- **Opening:** Click the lightning-bolt ⚡ on the right of any input that accepts dynamic data. The input converts: background becomes purple-20, and a popover menu appears below with the data-source picker.

- **Expression composition is chained, left-to-right:** You pick a starting data source (e.g., `Current User`), and each subsequent selection narrows the expression. Each link in the chain is a chip; chips flow inline with any static text you type around them.

- **Menu structure (3 section types):**
  - **OPERATORS** — logical / comparison operators that make sense in the current context (`is`, `is not`, `contains`, `doesn't contain`, `is empty`, `is not empty`, `>=`, `<=`, etc.)
  - **DATA FIELDS** — fields available on the current object. E.g., after `Current User`, you see `'s email`, `'s Slug`, `'s Creation Date`, `'s Modified Date`, `'s unique id`, `'s link`, plus any app-defined custom fields.
  - **OTHER OPERATORS** — type-specific transformation methods (for text: `:capitalized words`, `:uppercase`, `:lowercase`, `:formatted as...`, `:used as...`, `:trimmed`, `:number of characters`; for numbers: `:rounded to`, `:formatted as`; for lists: `:filtered`, `:sorted by`, `:first item`, `:count`, etc.).

- **Contextual filtering:** The picker only shows operators and transformations compatible with the current expression's type. After a text field, string operators appear; after a number, numeric operators appear; after a list, list operators appear.

- **Search:** A `Search` input at the top of the picker filters all entries across all sections by substring.

- **Section headers are uppercase, gray-60, 10/600** — these are the only uppercase labels in the editor's everyday UI. They act as quiet dividers, not as prominent headings.

- **Collapsing sections:** Each section has a caret ▼ to collapse/expand. Expanded by default.

- **Closing:** Click outside the popover, press Escape, or pick a value. Picking a value appends a chip to the expression and positions the cursor after the chip, ready for the next link.

- **Empty-state affordance (the dashed "Add" chip):** When a dynamic expression is *required* but not yet filled (e.g., a required "Only when" condition or a "Data to send" parameter), the field shows a **dashed 1px gray-40 chip** with the label `Add`. Clicking it opens the expression picker. See `context/bubble-editor-kit/reference/design-language.md` for the dashed-chip spec.

## Where It Appears

The picker shows up across virtually every editor surface, so building it once and reusing the popover is the Right Move for prototypes:

- **Property Editor** — any input that can be dynamic: text content, background color, visibility, data source, conditional expressions.
- **Workflow Editor** — action parameters, "Only when" conditions, "Data to send".
- **Styles Tab** — style variable expressions, named color references.
- **Data Tab** — privacy rule expressions, default-value expressions on fields.
- **API Connector** — parameter values and header values in API calls.
- **Backend Workflows** — same as frontend workflows plus scheduled triggers.

## Vocabulary

- **"Dynamic expression"** — A composed value that resolves at runtime, built left-to-right as a chain of data sources, fields, operators, and transformations.
- **"Data source"** — The starting point of an expression: `Current User`, `Parent group's thing`, `Do a search for...`, `This button's value`, `Current cell's [type]`, `Website home URL`, etc.
- **"Operator"** — A comparison or boolean-returning link: `is`, `is not`, `contains`, `is empty`, `>=`.
- **"Data field"** — A property of the currently-focused object: `'s email`, `'s Creation Date`, `'s [custom field name]`.
- **"Other operator"** / **"transformation"** — A type-specific method that transforms the preceding value: `:uppercase`, `:trimmed`, `:formatted as...`, `:rounded to`, `:first item`.
- **"Chip" / "Token"** — Each link in the expression renders as a purple pill inline in the field.
- **"⚡" / "Lightning-bolt"** — The affordance that converts a static input into a dynamic one. Always purple-60, always flush-right.
- **"Make dynamic"** — The verb for clicking the lightning-bolt. Inverse is "make static" — less common, hidden behind the input's kebab menu.

## What To Get Right In A Prototype

If the prototype touches the expression picker at all, these are the five things that make it *feel* like Bubble:

1. **Purple token chips** inline with static text — the signature visual.
2. **The lightning-bolt icon** (purple, right-aligned) on anything dynamic-capable.
3. **The three-section menu layout** (OPERATORS / DATA FIELDS / OTHER OPERATORS) with uppercase gray-60 section headers.
4. **Left-to-right chained composition** — each pick narrows the next set of options.
5. **Contextual filtering** — the menu reflects the current expression's type, not a static list.

Shortcuts you can take in a hackathon prototype:
- Hardcode 1-2 sample data sources (`Current User`, `Parent group's thing`) instead of building a full picker.
- Skip the search input unless the demo specifically needs it.
- For compositions, 2-3 chips deep is enough to feel real.

See the screenshots in `screenshots/` for the authoritative visual reference.
