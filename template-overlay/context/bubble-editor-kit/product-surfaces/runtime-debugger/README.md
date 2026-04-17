# Runtime Debugger

## What It Is
The Runtime Debugger is a bottom panel that appears while previewing a Bubble app in Run Mode (the "preview" view users see when they click the Run button). It lets the builder step through workflows, inspect any element on the page, and check the runtime state of data sources and conditions — all without leaving the running app. It's the primary tool for figuring out why something isn't behaving as expected.

## Key Behaviors
- A horizontal bar docked to the bottom of the browser window, visible only when the user previews their app with debug mode enabled
- The bar spans the full width of the page and causes the app content above to shift up to make room
- Debugger speed controls let the user pick how workflows play back:
  - **Normal** (default, selected by default in light-purple pill)
  - **Slow** — animates actions step-by-step at reduced speed
  - **Step-by-step** — pauses between each action; user clicks forward to advance
- A dropdown on the right selects what's being inspected. Options include the current page, any specific element on the page, or individual workflow steps
- **Inspect button** on the far right opens the full inspector panel (element + data view)
- When inspecting an element, the debugger expands upward to show a detail panel with multiple sections:
  - **Conditions** — every conditional rule on the element, labeled `Condition 1`, `Condition 2`, etc., with the rule expression and current evaluation (green = true/applying, red = false)
  - **Properties** — a two-column key/value grid of the element's runtime properties (visible, clickable, width, height, X, Y, margins, label, alignment, text, etc.)
  - **Evaluator** — shows the resolved value of a dynamic expression (e.g. `Current User's email` → the actual value for the logged-in user)
- When an element is hovered in Run Mode while the debugger is open, the page outlines that element with a purple overlay and shows a small preview tooltip (see "Inspect Element" screenshot)
- The "Show responsive boxes" toggle highlights the responsive layout boundaries on the canvas
- A warning icon on the far right surfaces any runtime issues
- **Stop button** in primary blue closes Run Mode and returns to the Editor

## Vocabulary
- "Run Mode" — the live preview view of the app
- "Debugger" — the bottom bar itself
- "Normal / Slow / Step-by-step" — the three playback speeds for workflows
- "Inspect" — opens the detailed element + data inspector
- "Conditions" — conditional rules evaluated in real time
- "Properties" — runtime property values for the selected element
- "Evaluator" — live evaluation of a dynamic expression against the current data
- "Responsive boxes" — the responsive layout guides that can be toggled on
- "Stop" — exits Run Mode

## Screenshots Needed
> Drop screenshots in the `screenshots/` folder next to this file.
> Current captures:
> - `Runmode - Debug Mode.png` — the baseline debugger bar with a button on the page
> - `Runmode - Debug Mode - Inspect Element.png` — the element inspector expanded, showing Conditions + Properties for a Button
> - `Runmode - Debug Mode - Inspect Data Source.png` — the data-source inspector with the Evaluator panel on the right
