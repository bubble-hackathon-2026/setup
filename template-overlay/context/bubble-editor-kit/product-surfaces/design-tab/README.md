# Design Tab

## What It Is
The Design tab is Bubble's visual page editor -- a WYSIWYG canvas where you place, arrange, and configure all the UI elements that make up your app's pages. It combines a drag-and-drop canvas (the UI Builder), a hierarchical element tree, a palette of available element types, an element inspector for cross-referencing where an element is used, and a responsive preview mode that lets you simulate how your layout adapts across screen widths from mobile to desktop.

## Key Behaviors
- **UI Builder (canvas):** Click an element type in the left-side palette, then click-and-drag on the canvas to place it. Double-click any element to open its Property Editor; right-click for a contextual menu with copy, paste, group, and alignment options.
- **Elements Tree:** A collapsible outline of every element on the current page, with indentation showing parent/child nesting. You can drag-and-drop items in the tree to reorder siblings or re-parent elements into different containers. Greyed-out items are currently hidden. Behavior varies by container layout: dragging within Fixed or Align to Parent changes z-index; dragging within Row or Column changes display order.
- **Element Palette:** Organized into sections -- Visual Elements (text, image, button, icon, etc.), Containers (group, repeating group, popup, floating group, group focus, table element), Input Forms (text input, dropdown, file uploader, etc.), Reusable Elements, and built-in templates (tab element, signup/login form). Plugins can add more element types here.
- **Element Inspector:** A slide-out panel showing everywhere the selected element is referenced -- in events, actions, other elements, and custom states. Clicking a reference jumps you to that location in the editor. Also lets you add, edit, or delete custom states on the element.
- **Responsive sub-tab:** Switch from the canvas to a responsive viewer. Preset breakpoint buttons snap to common widths (Mobile 320px, Mobile Landscape 768px, Tablet 992px, Desktop 1200px), and you can scrub to any arbitrary width with the ruler. Custom breakpoints can be added and used as conditional data sources on any element.
- **Page management:** A dropdown in the top bar lets you switch between pages and reusable elements. Apps come with default pages like 404 and reset_pw. Each page has its own URL and can have a Type of Content for data-driven pages.
- **Drag-and-drop limitations:** Popups, group foci, and floating groups cannot be dragged into other containers (they sit above the page), but you can drag other elements into them.

## Vocabulary
- "Element" -- Any object placed on a page: visual elements, containers, or input forms.
- "Container" -- An element that holds other elements (Group, Repeating Group, Popup, Floating Group, Group Focus, Table Element).
- "Container layout" -- The layout mode of a container (Fixed, Align to Parent, Row, Column) that determines how children are positioned and respond to screen changes.
- "Reusable element" -- A self-contained collection of elements that can be embedded on multiple pages (e.g., a shared header or footer).
- "Property Editor" -- The floating panel opened by double-clicking an element; it contains tabs for appearance, data, conditions, and layout.
- "Elements Tree" -- The hierarchical sidebar listing all elements on the page with drag-and-drop reordering.
- "Breakpoint" -- A defined screen width at which your layout can change behavior; used for responsive design.
- "Responsive viewer" -- The sub-tab that lets you preview layout behavior at different screen widths without leaving the editor.
- "Element Inspector" -- The slide-out panel showing all references to the selected element across events, actions, and other elements.

## Screenshots Needed
> Drop 3-5 annotated screenshots in the `screenshots/` folder next to this file.
> Suggested captures:
> - The full Design tab layout: canvas in the center, elements tree on the left, palette below it
> - An element selected on the canvas with its Property Editor open
> - The Elements Tree showing nested containers with drag-and-drop reordering in progress
> - The Responsive sub-tab with breakpoint presets and the width scrubber active
> - The Element Inspector panel showing references to a selected element
