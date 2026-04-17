# Property Editor

## What It Is
The Property Editor is the floating, draggable panel that appears when you double-click any element (or the page itself) in the Design tab. It is the primary interface for configuring how an individual element looks, what data it displays, how it responds to conditions, and how it behaves responsively. Every element type surfaces a different set of properties here, but they all share common sections: general appearance, data binding, conditional formatting, and layout/responsive settings. The Property Editor is also where you launch workflows directly from an element via the "Start/Edit workflow" button.

## Key Behaviors
- **Opening:** Double-click any element on the canvas, or click its name in the Elements Tree. The panel is draggable and stays open until you close it or select a different element.
- **General properties:** Name the element, set visibility on page load, control clickability ("This element isn't clickable"), and configure type-specific settings. For containers: set Type of Content and Data Source to bind data. For input forms: set content format, placeholder text, and initial content.
- **Appearance properties:** Background color, border style/width/color, corner radius, shadows, font settings, padding, and opacity. These can be overridden by a style or by conditional formatting.
- **Data binding:** Containers (groups, repeating groups, popups, floating groups, group focus) have "Type of content" and "Data source" fields. The data source can be a search, an API call, a parent group's thing, or any dynamic expression. Child elements access this data via "Parent group's [type]" or "Current cell's [type]".
- **Conditional formatting tab:** Add condition rows with a "When" expression (must resolve to yes/no) and one or more properties to override when true. Conditions are evaluated in listed order; if two active conditions change the same property, the last one wins. Conditions can be reordered (Move Up / Move Down), toggled on/off for preview, or removed.
- **Transitions:** Define smooth property changes (e.g., background color fading over 500ms). Configure duration, timing curve, and which property to animate. Not supported on gradient backgrounds.
- **Collapse when hidden:** An option that pulls surrounding elements up to fill the space when this element is hidden, instead of leaving a blank gap. Can be animated with fade or slide effects.
- **Start/Edit workflow button:** Launches or navigates to the workflow associated with this element's primary event (e.g., "When this button is clicked").
- **Container-specific behaviors:**
  - *Groups:* Container layout (Fixed, Align to Parent, Row, Column), data injection via Type of Content and Data Source, collapse-on-hide with optional animation.
  - *Repeating Groups:* Fixed or dynamic row/column counts, min row/column size, scroll direction (vertical, horizontal, wrapped horizontally), reverse scroll, masonry grid mode, separator style/width/color, "Show all items immediately" for full-list loading.
  - *Popups:* Grayout color and blur behind the popup, Esc-to-close toggle. Hidden by default; shown via workflow actions.
  - *Floating Groups:* Vertical and horizontal float anchoring (Top, Bottom, Both, Nothing / Left, Right), z-index control, parallax effect factor for background depth.
  - *Group Focus:* Reference element, offset top/left, auto-close on outside click. Useful for dropdown menus and popovers.
  - *Table Element:* Type of content, data source, table direction (vertical/horizontal), sticky rows, vertical and horizontal separators, fixed or dynamic repeating row counts.

## Vocabulary
- "Property Editor" -- The floating configuration panel for any selected element; the main place you edit element settings.
- "Type of content" -- Declares what kind of data a container holds (e.g., User, Product); must match the Data source's return type.
- "Data source" -- The dynamic expression that provides the actual data displayed in a container; can be a search, API result, or reference to another element's data.
- "Conditional formatting" -- Rules that change an element's appearance or behavior when a dynamic condition evaluates to true.
- "Collapse when hidden" -- A property that removes blank space when an element is hidden, pulling siblings up to fill the gap.
- "Container layout" -- The positioning mode for a container's children: Fixed (absolute positioning), Align to Parent (edge-pinning), Row (horizontal flow), or Column (vertical flow).
- "Current cell's [type]" -- In a Repeating Group, a reference to the data item displayed in the current cell.
- "Parent group's [type]" -- A reference to the data bound to the nearest ancestor container that has a data source.
- "Transition" -- A timed animation applied when a conditional property change occurs (e.g., color fade over a set duration with a chosen easing curve).
- "This element isn't clickable" -- A checkbox that disables click events and pointer cursor on the element; useful for gating actions behind conditions.

## Screenshots Needed
> Drop 3-5 annotated screenshots in the `screenshots/` folder next to this file.
> Suggested captures:
> - The Property Editor open on a Group element showing Type of Content, Data Source, and Container Layout
> - The Conditional Formatting section with multiple conditions, showing the When expression and property overrides
> - The Property Editor open on a Repeating Group showing row/column settings, scroll direction, and masonry grid toggle
> - A Popup's Property Editor showing Grayout color, blur, and the Esc-to-close option
> - The Transitions section showing a duration, timing curve, and selected property
