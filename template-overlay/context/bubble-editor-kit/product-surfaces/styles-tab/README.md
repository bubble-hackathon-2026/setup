# Styles Tab

## What It Is
The Styles tab is Bubble's theming system. Instead of setting fonts, colors, borders, and spacing on every individual element, you define named styles and apply them across elements of the same type. When you update a style, every element using it picks up the change automatically. The tab also includes a Style Variables sub-tab where you manage global color variables and font variables -- reusable design tokens that propagate updates instantly across every style or element that references them.

## Key Behaviors
- **Style list:** The left column shows all defined styles, organized by element type (e.g., Button styles, Text styles, Input styles). Select a style to view and edit its properties on the right.
- **Creating a style:** Add a new style for a specific element type, give it a name, and configure its visual properties (font family, size, weight, color, background, border, padding, corner radius, shadows, etc.).
- **Applying a style:** In the Property Editor of any element, choose a style from the style dropdown. The element inherits all the style's properties, but individual overrides are still possible.
- **Style Variables sub-tab:** Define color variables (e.g., "Primary", "Secondary", "Danger") and font variables (e.g., "Heading Font", "Body Font"). When a variable's value changes, every style or element referencing it updates automatically throughout the entire app.
- **Consistency and speed:** Styles enforce visual consistency and make large-scale redesigns fast -- change a color variable once and it ripples through the entire app. This is especially valuable for hackathon projects where the design needs to evolve quickly.

## Vocabulary
- "Style" -- A named collection of visual properties (font, color, border, spacing, etc.) that can be applied to elements of a given type.
- "Style variable" -- A reusable design token (color or font) defined globally and referenced by styles or individual elements; updating the variable propagates the change everywhere.
- "Color variable" -- A named color value (e.g., hex or RGBA) stored as a style variable for reuse across the app.
- "Font variable" -- A named font-family/weight/size combination stored as a style variable.
- "Default style" -- The style automatically applied to new elements of a given type when they are first placed on the canvas.

## Screenshots Needed
> Drop 3-5 annotated screenshots in the `screenshots/` folder next to this file.
> Suggested captures:
> - The Styles tab with the style list on the left and a selected style's properties on the right
> - The Style Variables sub-tab showing color variables with their swatches
> - The Style Variables sub-tab showing font variables
> - An element's Property Editor with the style dropdown open, showing available styles
> - A before/after comparison of changing a color variable and seeing it update across multiple elements
