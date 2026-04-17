# Bubble — Architecture Overview

A hackathon-friendly tour of how Bubble apps are put together. Use this
as a mental map when you're prototyping a feature that needs to match
how the real product behaves.

## What Bubble is

Bubble is a no-code platform for building web applications visually.
Instead of writing HTML, CSS, JavaScript, and backend code by hand, you
design pages, wire up logic, store data, and connect to external
services through a visual editor. The platform renders and runs the
final app for you.

People use Bubble to ship marketplaces, internal tools, SaaS products,
directories, dashboards, social apps, and AI-powered experiences.
Apps can also be published as native mobile apps through Bubble's
beta native mobile features.

## High-level app structure

A Bubble app is made up of a small number of top-level building blocks:

- **Pages** — each page has a unique URL and contains a tree of
  elements and its own set of workflows.
- **Elements** — the things you see on a page (text, buttons, images,
  inputs, containers, etc.). Every element has properties you edit in
  the property editor.
- **Reusable elements** — element groups you define once and drop into
  multiple pages (headers, footers, modals, nav bars).
- **Data types and fields** — the shape of your app's database. A
  "thing" is a single record of a data type.
- **Option sets** — app-defined lists of static values (statuses,
  categories, roles). End users can't edit them.
- **Workflows** — the logic that makes the app do things. A workflow
  is an event plus a sequence of action steps.
- **Backend workflows** — workflows that run on the server, including
  API workflows, scheduled workflows, and database trigger workflows.
- **Plugins** — installed extensions that add new elements, actions,
  events, data sources, and API connections.
- **Styles and style variables** — reusable visual definitions (fonts,
  colors, borders) applied across elements.

## The editor layout

The Bubble editor has several tabs across the top:

- **Design tab** — draw and arrange elements on pages, edit element
  properties, preview responsive behavior. Contains the UI builder,
  element tree, element palette, element inspector, and responsive
  viewer.
- **Workflow tab** — define events and the action steps that run when
  they fire. This is where frontend logic lives.
- **Data tab** — define data types and fields, view and edit rows
  (things), set privacy rules, manage option sets, and work with the
  file manager. You can also upload/export CSVs and switch between
  development and live databases here.
- **Styles tab** — manage shared styles and style variables (font and
  color variables) that apply across elements.
- **Plugins tab** — browse, install, and configure plugins. Plugins
  can add elements, actions, events, data sources, and login services.
- **Settings tab** — app-level settings: plan, general options, APIs,
  collaboration, languages, SEO, custom domain, sub-apps, Bubble
  version, notifications, and native mobile config.
- **Logs tab** — inspect runtime logs for debugging.

## How the frontend works

- **Page as root element.** Each page is the top-level element; all
  other elements live inside it. Pages can receive a "type of content"
  so they know what thing they're displaying (e.g. an Apartment page).
- **Element hierarchy.** Elements nest inside containers. A child
  element can reference its parent's data via "Parent group's thing,"
  which is how you pipe data down the tree.
- **Containers.** Groups, repeating groups, popups, floating groups,
  group focus, and tables. Each has a container layout type that
  controls responsive behavior.
- **Container layouts.** Four main layout modes — Fixed, Align to
  parent, Row, Column. Row and Column are the workhorses for
  responsive design. Fixed and Align to parent use z-index-based
  ordering.
- **Responsive engine.** Pages and containers respond to screen width
  via breakpoints. Bubble ships with a Default breakpoint plus four
  presets (Mobile 320px, Mobile Landscape 768px, Tablet 992px, Desktop
  1200px), and you can add custom breakpoints. The Responsive sub-tab
  of the Design tab lets you scrub through widths to preview behavior.
- **Dynamic data.** Element properties (text, data sources, visibility,
  colors) can be bound to dynamic expressions that pull from the
  database, page state, URL parameters, or other elements. When the
  underlying data changes, the UI updates automatically.
- **Repeating groups.** Display lists of things. You design one cell,
  and Bubble repeats it for every item. Cells can reference
  `Current cell's thing`.
- **Custom states.** Per-element variables that store temporary data
  on the page (e.g. which tab is selected). They reset on reload.
- **Reusable elements.** Bundles of elements shared across pages.

## How the backend works

Bubble splits logic into frontend (runs in the browser) and backend
(runs on the server).

- **Frontend workflows** — triggered by element events on a page
  (button click, input change, page load, etc.). They run in the
  user's browser and can show/hide elements, set states, navigate,
  and also perform server-side actions like saving data.
- **Backend workflows** — run entirely on the server. They keep
  running even if the user closes the tab. Three main flavors:
  - **API workflows** — a type of backend workflow with a URL
    endpoint, parameters, and authentication. Can be triggered from
    inside the app or, if marked public, called from outside via the
    Workflow API.
  - **Scheduled workflows** — API workflows queued to run at a
    specific time, or on a recurring schedule.
  - **Database trigger workflows** — fire when a thing of a given
    type is created, changed, or deleted. Inside them you can
    reference `Thing before change` and `Thing now`.
- **Actions** — the steps inside any workflow. Built-in action
  categories include Account (sign up, log in, log out), Navigation
  (go to page, open external URL, terminate workflow), Data/Things
  (create, modify, delete, make changes to a list), Email, Element
  (show/hide, animate, set state, scroll), and Custom (trigger custom
  events, schedule/cancel API workflows, run recurring events).
- **Events** — what triggers a workflow: element interactions (click,
  value change), page events (page loaded, unhandled error), custom
  events (reusable event blocks you can trigger from anywhere), and
  backend-specific events (API workflow, database trigger).
- **Conditions and Only When.** Any workflow or action step can have
  an "Only when" condition that gates execution.

## How data works

- **Data types and fields.** You define data types in the Data tab
  (User, Post, Order, etc.). Each has fields with types like text,
  number, date, image, file, geographic address, yes/no, or a custom
  type pointing to another data type. Fields can also hold lists.
- **Things.** Instances of a data type — the rows in your database.
  Every thing has built-in fields including Creator, Created Date,
  Modified Date, and a unique ID.
- **Data sources.** The starting point of any dynamic expression.
  Common sources include Current User, Do a search for, Current page
  thing, Parent group's thing, Current cell's thing, Get data from an
  external API, Get data from page URL, Current date/time, Arbitrary
  text, and more.
- **Searches and constraints.** `Do a search for` is the standard way
  to query the database. You pick a type, add constraints (field = x,
  within radius, contains text, etc.), and optionally sort. Element
  searches stay live-synced to the database, so the UI updates when
  data changes.
- **Option sets.** Static lists defined by the app builder. Good for
  things users shouldn't edit, like statuses or categories. They
  don't hit the database on lookups.
- **Privacy rules.** Server-enforced rules per data type that define
  which users can see, find, and modify each field. Marking a data
  type "private" at creation time sets up a default rule so only the
  creator can access it. You should always set privacy rules before
  handling real user data.
- **Current User.** A signed-up user has a permanent database record;
  a visitor who hasn't signed up yet is a temporary user (auto-deleted
  after three days of inactivity). Temporary users can still be
  modified; when they sign up, their temp record is promoted to
  permanent.
- **Files and File Manager.** Upload images and documents through
  file uploader elements, the property editor, or workflows. The File
  Manager in the Data tab shows all uploaded files, and files attached
  to things inherit that thing's privacy rules.
- **CSV import/export.** Bulk-load or export data per type on paid
  plans. Works via the Data tab.

## How plugins extend the platform

Plugins are the extension mechanism for Bubble. They can add any of
the following to an app:

- New elements (chart widgets, calendars, rich text editors, etc.)
- New workflow actions
- New events
- New data sources
- Login services (social sign-in like Facebook, Google, LinkedIn)
- API connections

Install plugins from the Plugins tab gallery. Many are free; some are
paid (one-time or subscription). The **API Connector** is a
Bubble-built plugin that lets you connect to almost any external REST
API: configure headers, parameters, and a URL, and the call becomes
available as either an action or a data source in your app. Calls
route through Bubble's server by default, but safe public calls can
be set to run directly from the browser.

Plugins have versions. New versions of an installed plugin don't
auto-apply — you can upgrade on your development version, test, and
then deploy, which keeps breaking changes from surprising live users.

## APIs your app exposes

Every Bubble app can expose two built-in APIs (both off by default,
toggled in Settings > API):

- **Data API** — a RESTful interface for external systems to search,
  read, create, modify, and delete things in your database.
- **Workflow API** — lets external systems trigger API workflows via
  HTTP requests. The same infrastructure powers Bubble's ability to
  schedule workflows internally.

Both support authentication via API token or per-user bearer tokens.

## Deployment model

Every Bubble app has two environments:

- **Development version** — where you build and test. Has its own
  database. Accessed in the editor and at `/version-test` URLs.
- **Live version** — what your end users see at your main domain.
  Has its own separate database.

You move changes from development to live by clicking **Deploy to
live**. You can also copy or restore databases between the two, set
save points, and roll back to earlier states of the app on paid plans.
Advanced teams can use branches for parallel development and merge
them back together — the main branch is always called `version-test`.

Bubble itself also has engine versions. Most platform updates roll out
immediately, but occasional breaking changes let you choose when to
upgrade (Settings > Versions). Apps on scheduled release get daily
batched updates rather than continuous ones; Enterprise dedicated
instances have full control over their Bubble version.

## Key Mental Model

When in doubt while prototyping, picture the app as:

1. **A tree of elements** rendered on pages, where data flows
   downward from parents to children via data sources.
2. **A library of workflows** (frontend and backend) that fire on
   events and run action steps, gated by conditions.
3. **A typed database** of things protected by privacy rules, queried
   through `Do a search for` with constraints.
4. **A plugin layer** that adds elements, actions, and API calls
   without writing low-level code.
5. **Two environments** (development and live) with separate
   databases, tied together by Deploy to live.

If your prototype can be described in those five terms, it will feel
familiar to real Bubble users.
