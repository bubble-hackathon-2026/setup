# Workflow Editor

## What It Is
The Workflow tab is where you define the logic that makes your app respond to user interactions and system events. Every workflow consists of a triggering event (a button click, a page load, a data change, a scheduled time, etc.) followed by a sequence of action steps that execute in order. Actions span a wide range of capabilities: creating and modifying database records, navigating between pages, sending emails, charging credit cards, showing/hiding elements, calling external APIs, triggering custom events, and more. Conditions can be placed on both the event and individual actions to control whether they fire.

## Key Behaviors
- **Adding a workflow:** Click "Click here to add an event..." at the top of the workflow canvas, then select the triggering event type (element click, page load, input change, custom event, recurring event, data trigger, etc.).
- **Adding actions:** After selecting an event, add action steps from a categorized dropdown: Account (signup, login, logout), Navigation (go to page, open URL, add pause), Data (create/modify/delete things), Email (send email, send calendar invite), Element (show, hide, animate, scroll to, set state, display data in group), Custom (trigger/schedule custom events, schedule/cancel API workflows), and Plugins (actions from installed plugins like the API Connector).
- **Action ordering:** Actions run in sequence top-to-bottom. Each action can reference the "Result of step X" from a prior action -- for example, creating a thing in step 1 and then modifying that same thing in step 2.
- **Conditions:** Both the event and each individual action can have an "Only when" condition. This is a dynamic expression that must evaluate to yes/no; the event or action is skipped if the condition is false.
- **Frontend vs Backend:** Frontend workflows run in the user's browser session and stop if the user navigates away. Backend (API) workflows run entirely on the server, can be scheduled for the future, and can be triggered by external API calls.
- **Custom events:** Reusable workflow blocks that can be triggered from other workflows with parameters, or scheduled to fire later (as long as the user stays on the page).
- **Recurring events:** "Do every X seconds" events that repeat on a timed interval while the page is active.
- **Debugging:** The step-by-step debugger lets you walk through a workflow execution in real time, inspecting the values returned at each step.

## Vocabulary
- "Event" -- The trigger that starts a workflow (e.g., "When Button A is clicked", "When page is loaded", "Do every 5 seconds").
- "Action" -- A single step in a workflow that performs a task (e.g., "Create a new Thing", "Navigate to page", "Send email").
- "Only when" -- A condition on an event or action that must be true for it to execute.
- "Result of step X" -- A dynamic reference to the output of a previous action in the same workflow; commonly used to chain data operations.
- "Custom event" -- A user-defined event that can be triggered from other workflows or scheduled to run later (frontend only; resets on page navigation).
- "API workflow" -- A server-side workflow that persists beyond the user's session; can be scheduled, called via API, or run in bulk on a list.
- "Frontend workflow" -- A workflow triggered by user interaction that runs in the browser; stops if the user leaves the page.
- "Thing now" / "Thing before change" -- Data sources available in database trigger workflows representing the new and previous states of a changed record.

## Screenshots Needed
> Drop 3-5 annotated screenshots in the `screenshots/` folder next to this file.
> Suggested captures:
> - The Workflow tab overview showing multiple event blocks with their action sequences
> - The event picker dropdown showing available trigger types
> - The action picker dropdown showing categories (Account, Navigation, Data, Email, Element, Custom, Plugins)
> - A workflow with an "Only when" condition configured on an action step
> - The step-by-step debugger mid-execution, showing current step and inspected values
