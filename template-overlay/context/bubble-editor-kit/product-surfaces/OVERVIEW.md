# Product Surfaces Overview

> **Claude: Read this file first.** When someone asks you to build, prototype, or discuss a Bubble product surface, start here to find the right context folder. Each folder contains a README.md describing that surface's purpose, interaction patterns, vocabulary, and what screenshots are needed. Read the relevant README before generating any code, designs, or recommendations.

## Surface Map

| Surface | Folder | One-Line Description |
|---------|--------|----------------------|
| API Connector | `api-connector/` | Plugin for configuring calls to external REST APIs, exposable as data sources or workflow actions. |
| Data Tab | `data-tab/` | Schema definition, privacy rules, record browsing/editing, option sets, and file management for the app's database. |
| Design Tab | `design-tab/` | WYSIWYG page editor with drag-and-drop canvas, element tree, element palette, inspector, and responsive preview. |
| Workflow Editor | `workflow-editor/` | Event-driven logic builder where you define triggers and sequential action steps that power app behavior. |
| Styles Tab | `styles-tab/` | Theming system for named reusable styles and global color/font variables applied across the app. |
| Runtime Debugger | `runtime-debugger/` | Bottom panel in Run Mode for stepping through workflows and inspecting elements, conditions, and data sources live. |
| Settings Panel | `settings-panel/` | App-wide configuration: plan, security, domains, SEO, APIs, collaboration, languages, and native mobile publishing. |
| Property Editor | `property-editor/` | Per-element configuration panel for appearance, data binding, conditional formatting, layout, and transitions. |
| Expression Picker | `expression-picker/` | Cross-surface dynamic-data picker — the purple-chip expression builder that appears anywhere a field accepts dynamic values. |

## How to Use These Files

Each surface folder may contain up to four artifacts:

- **`README.md`** — Functional description of the surface: what it is, key behaviors, vocabulary. **Read this first.**
- **`ux-research.md`** — (when present) Raw UX research content provided by the Bubble team, verbatim. This is the **authoritative source** for `design-ux.md`. If you find a contradiction, trust `ux-research.md` over the distilled `design-ux.md`.
- **`design-ux.md`** — (when present) Distilled design and UX context for this surface: layout anatomy, interaction vocabulary, signature patterns, UX principles, screenshots map. Read this whenever you're building something that should look like this surface.
- **`screenshots/`** — Authoritative visual reference. Open these directly (Claude can read PNG).

Workflow for any "build me X" task:

1. **Identify the surface** from the table above.
2. **Read the surface's `README.md`** — understand what it does and the vocabulary it uses.
3. **Read the surface's `design-ux.md`** if it exists — absorb the layout, patterns, and UX principles.
4. **Open the screenshots** — pixel-level visual reference.
5. **Load `context/bubble-editor-kit/reference/design-language.md`** — the global palette, typography, components, and cross-editor patterns.
6. **Cross-reference surfaces** — tasks often span multiple (e.g. API Connector calls appear as data sources in the Property Editor, and as actions in the Workflow Editor).
7. **Consult `ux-research.md`** only if the distilled `design-ux.md` feels ambiguous or incomplete on a specific point — the raw research is verbose but definitive.

### Surfaces with research + design/UX docs

Track the growing list of surfaces that have deep design/UX docs:

| Surface | `ux-research.md` | `design-ux.md` | Screenshots |
|---|---|---|---|
| workflow-editor | done | done | done |
| design-tab | done | done | done |
| data-tab | done | done | done |
| api-connector | pending | pending | done |
| property-editor | pending | pending | done |
| styles-tab | pending | pending | done |
| settings-panel | pending | pending | pending |
| runtime-debugger | pending | pending | done |
| expression-picker | pending | pending | done |

## Common Cross-Surface Relationships

- **Design Tab + Property Editor:** The Property Editor opens from within the Design Tab when you double-click an element. They are tightly coupled -- the Design Tab is the canvas, the Property Editor is the inspector.
- **Design Tab + Workflow Editor:** The "Start/Edit workflow" button on an element bridges you from design to workflow logic. Events in the Workflow Editor reference elements by name.
- **Data Tab + Property Editor:** Data types defined in the Data Tab appear as "Type of content" options in the Property Editor. Data sources like "Do a search for" query the types you defined.
- **Styles Tab + Property Editor:** Styles defined in the Styles Tab are applied to elements via a dropdown in the Property Editor. Style variables flow through to every element using that style.
- **Settings Panel + Data Tab:** Privacy settings and API exposure in the Settings Panel complement the privacy rules configured in the Data Tab. The API sub-tab controls whether your data types are accessible externally.
- **Workflow Editor + Data Tab:** Data actions (create, modify, delete things) in workflows operate on the data types and fields you defined in the Data Tab.
- **Runtime Debugger + Design Tab:** The Runtime Debugger inspects elements that were built in the Design Tab. Conditions shown in the debugger are the same ones defined in the Property Editor's Conditional tab.
- **Runtime Debugger + Workflow Editor:** The debugger lets you step through workflows defined in the Workflow Editor. Slow and Step-by-step modes make it possible to watch each action execute.
