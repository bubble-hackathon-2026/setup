# Bubble Editor Kit — Index

**Only read this if the hackathon project is mocking up something that should look like it lives inside the Bubble editor.** If it's a custom UI with its own look, skip the whole `context/bubble-editor-kit/` folder — it will just make the prototype feel wrong.

---

## What's Here

A reference kit for building prototypes that look and feel like Bubble's editor: design language tokens, product-surface deep dives, and annotated screenshots. Extracted from the live editor + UX research. Credit: LD Acosta (design/surface docs) and Jeremy (editor screenshots).

```
context/bubble-editor-kit/
├── INDEX.md                    ← you are here
├── reference/                  ← global knowledge; read once per project
│   ├── design-language.md      ★ AUTHORITATIVE visual spec (read before any UI)
│   ├── architecture-overview.md    how Bubble apps are structured
│   ├── domain-glossary.md          Bubble-specific vocabulary
│   └── user-personas.md            who uses Bubble
└── product-surfaces/           ← per-surface deep dives; read the one you need
    ├── OVERVIEW.md             ← map of all surfaces; start here
    ├── workflow-editor/        ★ full deep dive (README + design-ux + ux-research + screenshots)
    ├── design-tab/             ★ full deep dive
    ├── data-tab/               ★ full deep dive
    ├── expression-picker/      ← README + screenshots (the dynamic-data picker / purple chips)
    ├── property-editor/        ← README + screenshots
    ├── api-connector/          ← README + screenshots
    ├── styles-tab/             ← README + screenshots
    ├── runtime-debugger/       ← README + screenshots
    └── settings-panel/         ← README (no screenshots yet)
```

★ = surface with the deepest context.

---

## Reading Order For A Prototype Task

1. **`reference/design-language.md`** — always, always, always first. Every UI rule that makes a prototype recognizably Bubble is in this file. Skim it once at the start of the project, then keep it open.
2. **`product-surfaces/OVERVIEW.md`** — identify which surface(s) your prototype lives in. Most prototypes span 1-3 surfaces.
3. **`product-surfaces/<surface>/README.md`** — what the surface does, vocabulary, key behaviors.
4. **`product-surfaces/<surface>/design-ux.md`** (when present) — layout anatomy, signature patterns, UX principles.
5. **`product-surfaces/<surface>/screenshots/*.png`** — read every screenshot in the target surface. These are the authoritative visual reference; the Read tool can open PNGs directly.
6. **`product-surfaces/<surface>/ux-research.md`** (when present) — consult only if `design-ux.md` is ambiguous on a specific point. Verbose but definitive.

For tasks that span multiple surfaces, repeat steps 3-5 for each.

---

## Non-Negotiables (from `reference/design-language.md`)

These are the things every Bubble prototype has to get right. If any of these slip, the demo won't feel like Bubble:

- **Font:** Open Sans, 12px / 16px default body. Not Inter. Not 14px. Not system-ui.
- **Icons:** Phosphor (`@phosphor-icons/react` or the CDN). 1.5px stroke. Not Lucide, not Heroicons, not Material.
- **Primary action color:** cobalt-70 `#0C29AB`.
- **Dynamic data:** always purple (`#79059A`), rendered as inline chips with the ⚡ lightning-bolt affordance.
- **Radii:** 4px dominant, 8px for larger cards, 2px for expression chips. Never 6px, never > 8px on standard UI.
- **No gradients, no drop shadows on in-flow elements, no dark mode, no oversized headings, no UPPERCASE labels** (except small popover dividers and modal CREATE/SAVE buttons).

Full anti-pattern list lives in `reference/design-language.md` under "Anti-patterns — what's NOT in the Bubble UI."

---

## Vocabulary Is Part Of The Look

Using the right words matters almost as much as the visual treatment — Bubble users recognize the product by its language. See `reference/domain-glossary.md` for the full list. Quick substitutions:

| Don't say | Say |
|---|---|
| table / record | Data Type / Thing |
| component | Element |
| state / local variable | Custom State |
| automation / pipeline | Workflow |
| function / helper workflow | Custom Event |
| field on a table | Field on a Data Type |

---

## Self-Review Before Calling It Done

When the prototype feels complete:

1. Re-open 1-2 screenshots in the target surface folder.
2. Compare side-by-side with what you built — look for typography, color, icon, spacing, and vocabulary gaps.
3. Fix the top 3-5 differences before calling the prototype demo-ready.

The delta between "almost looks like Bubble" and "looks like Bubble" is usually 3-5 small fixes.
