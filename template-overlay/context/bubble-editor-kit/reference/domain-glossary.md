# Bubble — Domain Glossary

Bubble-specific terms as they're used inside the product. Use the
correct vocabulary when you prototype — it helps users recognize the
experience.

## Core Concepts

**App** — A single Bubble application. Pricing, collaborators, APIs,
and plugins are scoped to the app, not the user account.

**Page** — The root element of a URL in your app. Each page has its
own element tree and its own workflows. Pages can receive a "type of
content" so they know which thing they're displaying.

**Element** — Anything you draw on a page: text, buttons, images,
inputs, containers. Every element has properties edited in the
property editor.

**Visual element** — An element that just displays something (text,
icon, image, button) and can trigger workflows. Can't contain other
elements.

**Container** — An element that holds other elements. Groups,
repeating groups, popups, floating groups, group focus, and tables
are all containers.

**Group** — The most common container. Collects elements visually and
can hold a single thing as data so its children can reference
"Parent group's thing."

**Repeating Group** — A container that displays a list of things. You
design one cell and Bubble repeats it for each item. Supports vertical
scroll, horizontal scroll, wrapped, masonry, and fixed grid layouts.

**Popup** — A modal container that floats over the page, centered in
the viewport. Hidden until shown via a workflow action; closed by
Esc, outside-click, or a Hide popup action.

**Floating Group** — A container fixed relative to the top, bottom,
left, or right of the viewport. Common for headers, sticky CTAs,
and scroll-to-top buttons.

**Group Focus** — A container that auto-hides when the user clicks
outside of it. Positioned relative to a reference element. Ideal for
dropdowns and menus.

**Table Element** — A container element specifically for tabular
layouts, with sticky rows/columns and separator styling.

**Reusable Element** — A bundle of elements defined once and reused
across multiple pages (headers, footers, nav bars, login forms).

**Input Form** — An element that accepts user input: text inputs,
dropdowns, multiselects, file uploaders, date pickers, checkboxes,
radio buttons.

**Element Tree** — The hierarchical view of all elements on a page in
the Design tab. Shows parent/child nesting and lets you drag to
reparent.

**Property Editor** — The draggable panel that opens when you
double-click or right-click an element; where you edit its
appearance, data, and behavior.

**Element Inspector** — A panel showing where the selected element is
referenced across the app (events, actions, other elements).

## Data

**Data Type** — The definition of a category of data in your app
(User, Post, Order). You define its fields in the Data tab. Not
called a "table."

**Field** — A property on a data type. Has a type (text, number,
date, yes/no, image, file, geographic address, another data type, or
a list of any of these). Not called a "column."

**Thing** — A single record of a data type. One user, one post, one
order. Not called a "row" or "record."

**Unique ID** — Every thing has an auto-generated unique ID used for
addressing, references, and URL routing.

**Built-in fields** — Every thing automatically has Creator, Created
Date, and Modified Date.

**Data Source** — The starting point of a dynamic expression.
Examples: Current User, Do a search for, Current page thing, Parent
group's thing, Current cell's thing, Get data from an external API,
Get data from page URL, Current date/time.

**Do a search for** — The standard expression for querying the
database. You specify a type, constraints, and optional sorting.

**Constraint** — A filter on a search (e.g. `status = "open"`,
`created_date > some_date`, `address within 1 mile of X`).

**Ignore empty constraints** — A search setting that skips constraints
whose value is null, instead of matching only null fields.

**Advanced filter** — A client-side filter applied after a search,
used for logic that can't be expressed as a database constraint.

**Primary Field** — The display field for a data type (e.g. email for
Users, title for Posts). Used for display-only formatting in lists
and CSV exports.

**Option Set** — A fixed list of values defined by the app builder
(statuses, categories, roles). End users can't modify them. Faster
to reference than database lookups.

**Option** — A single item in an option set, with optional attributes
(display, color, icon, etc.).

**Privacy Rule** — A server-enforced rule per data type that defines
which users can view, find in searches, modify, or see attached
files for each thing. Set in the Data tab's Privacy sub-tab.

**App Data** — The actual rows of data in the database, viewable in
the Data tab's App data sub-tab. Development and Live have separate
App Data.

**Custom View** — A saved view of a data type in App Data, with
specific fields shown and optional constraints applied.

**File Manager** — The Data tab section listing all uploaded files
and images in either Development or Live.

**App Text** — Named text snippets used throughout the app, with
translations in the Languages settings tab.

## Workflows and Logic

**Workflow** — A sequence of actions triggered by an event. The unit
of logic in Bubble.

**Event** — What triggers a workflow (button clicked, page loaded,
input value changed, custom event, API workflow called, database
trigger).

**Action** — A single step inside a workflow. Examples: Create a new
thing, Make changes to a thing, Go to page, Send email, Show
element, Set state, Sign the user up.

**Action Step** — A numbered action in a workflow. Subsequent steps
can reference `Result of step N` to chain outputs.

**Only When** — A condition applied to an event or action step that
gates whether it runs.

**Condition** — A dynamic expression that evaluates to yes or no.
Used in Only When clauses and in conditional formatting on elements.

**Custom State** — A temporary variable stored on an element or the
page. Reset on reload. Useful for UI state like "which tab is open."

**Custom Event** — A reusable event block you define once and
trigger from elsewhere via actions. Can accept parameters.

**Result of step X** — A data source that references the output of a
previous step in the same workflow.

**Current Workflow Thing** — Inside a custom workflow or API
workflow, the thing that was passed in.

**Thing Now** — Inside a database trigger workflow, the latest state
of the thing that changed.

**Thing Before Change** — Inside a database trigger workflow, the
state of the thing before the change happened.

**Conditional Formatting** — Property overrides applied to an element
when a condition is true (hover highlight, error state, etc.).

**Run as** — A debugging tool in the Data tab that lets you preview
the app as if logged in as a specific user.

**Debugger** — The runtime tool that lets you step through workflows
and inspect the values returned at each step.

## Plugins and APIs

**Plugin** — An installable extension that can add elements, actions,
events, data sources, login services, and API calls to your app.

**Plugin Marketplace** — The gallery of installable plugins, opened
from the Plugins tab. Contains free and paid plugins, built by the
Bubble team or third-party developers.

**API Connector** — A Bubble-built plugin for connecting to external
REST APIs. You configure headers, parameters, and calls, then use
each call as an action or data source.

**API Call** — A single configured request in the API Connector.
Must be initialized (executed once) before it appears in the editor.

**Client safe parameter** — An API Connector parameter that's safe to
send to the browser. Don't mark secrets as client safe.

**Use as Action / Use as Data** — The two modes an API Connector call
can be set up in.

**Backend Workflow** — A workflow that runs server-side. Keeps
running even if the user closes their browser.

**API Workflow** — A type of backend workflow with a URL endpoint and
parameters. Can be triggered from the app or, if public, from
external services via the Workflow API.

**Scheduled Workflow** — An API workflow queued to run at a future
time or on a recurring schedule.

**Database Trigger Workflow** — A backend workflow that fires when a
thing of a given type is created, changed, or deleted.

**Recurring Event** — A workflow set up to run repeatedly at a fixed
interval via a Custom action.

**Workflow API** — The Bubble app's own outward-facing API for
triggering API workflows via HTTP. Enabled in Settings > API.

**Data API** — The Bubble app's own outward-facing RESTful API for
external systems to read, create, modify, and delete things in the
database. Enabled in Settings > API.

**API Token** — An authentication token generated in Settings > API.
Grants broad access to the app's APIs — use with care.

**Bearer Token** — The authentication format used by the Bubble API
(sent in the Authorization header).

**Swagger** — The interactive API documentation auto-generated from
your enabled API, useful for testing endpoints. Can be hidden in
Settings > API.

## Expressions and Dynamic Data

**Dynamic Expression** — A live formula that fetches, combines, or
transforms data at runtime. Composed of a data source followed by
operators.

**Dynamic Data** — Data inserted into a property via the "Insert
dynamic data" option, rather than a hard-coded value.

**Operator** — A step in a dynamic expression that transforms the
value: `:first item`, `:filtered`, `:formatted as`, `:count`,
`:plus`, `:minus`, and many more.

**Parameter** — A named input to an API workflow, custom event, or
API Connector call. Typed and optionally required.

**Parent group's thing** — The data piped into the current element's
parent container. How children read data without re-querying.

**Current cell's thing** — Inside a repeating group cell, the
specific item assigned to that cell.

**Current page's thing** — The thing assigned to the page itself
when a page has a type of content.

**Current User** — The user viewing the app, either signed up (with
a permanent database record) or temporary (auto-deleted after three
days of inactivity).

## Design and Layout

**Responsive Engine** — Bubble's system for adapting page layout to
screen width. Controlled by container layouts and breakpoints.

**Container Layout Type** — The layout mode of a container: Fixed,
Align to parent, Row, or Column. Determines how child elements are
arranged and sized.

**Row layout** — Lays children out horizontally; similar to flex
row. Children order is the order in the element tree.

**Column layout** — Lays children vertically; similar to flex column.

**Fixed layout** — Absolute positioning; children ordered by z-index.

**Align to parent layout** — Children are positioned relative to the
container's edges; ordered by z-index.

**Breakpoint** — A screen width at which layout rules can change.
Bubble ships with Default plus presets (Mobile 320px, Mobile
Landscape 768px, Tablet 992px, Desktop 1200px) and supports custom
breakpoints.

**Responsive Viewer** — The sub-tab of the Design tab that previews
your page at any width.

**Style** — A named bundle of visual properties (font, colors,
borders, etc.) applied to elements of a given type. Managed in the
Styles tab.

**Style Variable** — A named font or color token that can be reused
across styles and elements. Updating a variable updates every use.

**States (of an element)** — Built-in situations an element can be in
(hovered, visible, loading, etc.). Distinct from custom states.

**Collapse when hidden** — A container setting that pulls surrounding
elements up when the container is hidden.

**Z-index** — The stacking order of elements in Fixed and Align-to-
parent layouts. Higher numbers render on top.

## Users and Authentication

**User** — The built-in data type for people who use your app.
Always present.

**Current User** — See above.

**Signed-up user** — A user with a permanent database record, created
via a sign-up workflow.

**Temporary user** — A visitor who hasn't signed up yet. Has a
short-lived record automatically deleted after three days of
inactivity. Can be promoted to signed-up on sign-up.

**Log in / Log out actions** — Workflow actions under the Account
category that manage user sessions.

**Login Service** — A plugin type that enables social sign-in (Log
in with Facebook, Google, LinkedIn, etc.).

**Collaborator** — A Bubble user invited to work on an app with
scoped permissions (editor, viewer, etc.).

## Deployment and Versioning

**Development version** — Where you build and test the app. Own
database, accessed at `/version-test` URLs.

**Live version** — What end users see at your main domain. Own
database.

**Deploy to live** — The action that copies your current development
app changes to the live version. Does not copy data.

**Branch** — An isolated copy of the app for parallel development.
The main branch is always `version-test`.

**Version Control** — The system for branches, merges, and save
points (paid plans).

**Save Point** — A snapshot of the app you can revert to later.

**Bubble Engine Version** — The underlying platform version your app
runs on. Most updates apply automatically; breaking changes require
manual upgrade in Settings > Versions.

**Immediate release / Scheduled release / Dedicated release** — The
three release tiers that control when platform updates reach your
app.

**Sub App** — A separate app linked to a parent app in a parent-
child relationship. Changes can be pushed from parent to sub apps.

**Workload** — Bubble's measure of computing resources an app uses
(workflow runs, database calls, etc.). Drives billing and capacity.

**Primary domain** — The canonical URL your live app is served from.
Can be a custom domain or the default `bubbleapps.io` URL.
