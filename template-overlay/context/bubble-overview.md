# Bubble Product Context

## What Is Bubble

Bubble is a visual programming platform that lets people build web applications without writing code. Users design their UI visually (dragging and placing elements), define data structures, and create workflows (logic) — all through a visual editor in the browser.

## Key Concepts / Terminology

- **Editor**: The main interface where users build their apps — a canvas-based visual IDE
- **Element**: A UI component on the page (text, button, input, group, repeating group, etc.)
- **Workflow**: A sequence of actions triggered by an event (e.g., "When Button is clicked → Create a thing → Navigate to page")
- **Data Type / Thing**: A data model (like a database table). Each Type has fields.
- **Expression**: A dynamic value composed visually — can reference data, do calculations, format text, etc.
- **Repeating Group**: A list/grid that displays multiple items from a data source
- **Group**: A container element that holds other elements
- **Page**: A screen in the app, contains elements and workflows
- **Plugin**: An extension that adds new elements, actions, or API connections
- **App**: The complete application a user builds

## ICP (Ideal Customer Profile)

Bubble's users range from entrepreneurs building MVPs to companies building internal tools. They are typically non-developers who want to build real, functional web apps — not just landing pages, but apps with data, users, logic, and integrations.

## Design Principles

<!-- TODO: Fill in with actual Bubble design tokens from the design team -->

### Colors
- Primary blue: `#0D0DEB` (Bubble brand blue)
- Editor background: `#F5F5F5` (light gray canvas)
- Panel background: `#FFFFFF`
- Text primary: `#1A1A2E`
- Text secondary: `#6B7280`
- Border/divider: `#E5E7EB`
- Accent/selection: `#0D0DEB` at 10% opacity for highlights

### Typography
- Font family: Inter (UI), monospace for expressions/code
- Base size: 13px for editor UI, 14px for content

### Icons
- Phosphor Icons (regular weight, 20px default size)
- Install: `npm install @phosphor-icons/react`

### Layout Patterns
- Left sidebar: element tree / page list
- Right panel: property editor / inspector
- Top bar: app name, preview button, page selector
- Canvas: center area, light gray background with dot grid
- Panels have subtle shadows and rounded corners (border-radius: 8px)

### Component Style
- Buttons: rounded (border-radius: 6px), subtle shadows
- Inputs: bordered, rounded, 36px height
- Dropdowns: clean, with chevron icon
- Tabs: underline style for major sections
- Modals: centered, backdrop blur, rounded corners
