# Data Tab

## What It Is
The Data tab is the central hub for defining, viewing, and managing everything your app stores. It is split into several sub-tabs: Data Types (where you define your schema), Privacy (where you lock down who can see what), App Data (a spreadsheet-like viewer/editor for live records), Option Sets (static enumerations like statuses or countries that end-users cannot modify), and File Manager (uploaded images and documents). The tab also distinguishes between the Development and Live databases, which are completely separate datastores that you can copy between or restore to earlier points in time.

## Key Behaviors
- **Data Types sub-tab:** Lists all types on the left; selecting one shows its fields on the right. You create new types and fields inline. When creating a type you choose public or private -- private types get an auto-generated privacy rule restricting visibility to the creator.
- **Privacy sub-tab:** Rule-based access control per data type. Each rule specifies conditions under which certain user roles can view fields, find things in searches, or access attached files. By default new types are visible to everyone, so privacy rules should be set before handling real user data.
- **App Data sub-tab:** A tabular view of records. You can create custom views with specific columns, filters, and sort orders (including an "Unsorted" mode for performance with large datasets). Features include: New Entry, Search, Bulk Upload (CSV), Modify (CSV with unique IDs), Export (CSV), Bulk Action (run an API workflow on visible entries), and Run As (impersonate a user for debugging). Data loads 50 rows at a time with a "Load 50 more" button.
- **Option Sets sub-tab:** Define static lists (e.g., task statuses, privilege levels). Each option can carry additional attributes. Unlike database records, options cannot be added or changed by end-users at runtime.
- **File Manager sub-tab:** Browse uploaded files by name, type, or privacy status. Sort by size or upload date. Includes a View link to preview any file (admins bypass privacy rules here).
- **Copy and Restore Database:** Overwrite Live with Dev or vice versa; paid plans can restore to a prior point in time. There is also a "Wipe database change history" option (irreversible).
- **CSV Upload:** Map CSV columns to fields, choose delimiters, handle list fields with a separate list delimiter, and optionally overwrite empty values. Validate before uploading. The first row must be a header row.

## Vocabulary
- "Data type" -- A schema definition (like a database table) that describes a category of things your app stores, e.g., User, Product, Order.
- "Field" -- A named attribute on a data type with a specific value type (text, number, date, list, another data type, etc.).
- "Thing" -- A single record/row of a data type.
- "Privacy rule" -- A server-side condition that restricts which users can see or search for things of a given type.
- "Option set" -- A developer-defined static list of choices (not editable by end-users) that can carry extra attributes.
- "Primary field" -- The field used to represent a thing in the editor and CSV exports (display-name-only; does not affect logic).
- "Run as" -- A debugging feature that lets you preview the app impersonating a specific user from the database.
- "Custom view" -- A saved configuration of columns, filters, and sort order for browsing App Data.
- "Composite field" -- When CSV-importing a reference field, the sub-field used to match text entries to existing database records.

## Screenshots Needed
> Drop 3-5 annotated screenshots in the `screenshots/` folder next to this file.
> Suggested captures:
> - The Data Types sub-tab with a type selected and its fields visible
> - The Privacy sub-tab showing a privacy rule being configured
> - The App Data sub-tab with a custom view, the toolbar buttons (New entry, Upload, Export, Bulk Action), and the Dev/Live toggle
> - The Option Sets sub-tab with an option set expanded to show its options and attributes
> - The File Manager with filter controls and a list of uploaded files
