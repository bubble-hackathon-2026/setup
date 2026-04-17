# API Connector

## What It Is
The API Connector is a first-party Bubble plugin that lets your app communicate with virtually any external REST API. You configure one or more "APIs" inside the plugin, and within each API you define individual "calls" -- each call specifies a URL, HTTP method, headers, parameters, and body. Once a call is initialized (test-fired so Bubble can learn the response shape), it becomes available throughout the editor either as a data source or as a workflow action, depending on how you configured it. All calls route through Bubble's server by default, but lightweight public-read calls can optionally run directly from the user's browser to avoid shared rate limits.

## Key Behaviors
- Install via the Plugins tab by searching "API Connector"; once added, the plugin panel expands with sections for each API you create.
- Each API gets its own authentication method (None, Private key in URL/header, HTTP Basic Auth, OAuth2 Password/User-Agent/Custom Token, JWT, or Client-side SSL).
- Inside an API you add calls. For each call you choose a unique name, select "Use as" Data or Action, pick the HTTP method (GET, POST, PUT, PATCH, DELETE), and fill in the URL, headers, parameters, and body.
- Parameters can be marked "Private" (never sent to the browser) or "Client-safe" (dynamically settable in the editor). Headers can likewise be marked Private or Optional.
- Body type choices: JSON, Form-data, or Raw. For JSON bodies you must add a `Content-Type: application/json` header manually.
- "Initialize call" test-fires the call so Bubble can parse the response schema. This is a live request -- it will actually create/delete data on the remote service, so use sample values.
- After initialization, Data calls appear under "Get data from an external API" in dynamic-expression dropdowns; Action calls appear under the Plugins section of the workflow action picker.
- "Include errors in response" checkbox exposes an error object (status code, message, body, has-error flag) so you can handle failures in your workflow instead of halting.
- "Capture response headers" lets you include HTTP response headers in the parsed result.
- You can paste a cURL command directly into the connector to bootstrap a call's configuration quickly.
- Calls eligible for browser-side execution (no auth, no private params, no headers, data-only) show a checkbox to run directly from the browser, which avoids Bubble's shared server rate limits.

## Vocabulary
- "Initialize call" -- The one-time test request that teaches Bubble the structure of the API response so it can expose typed fields in the editor.
- "Use as: Data" -- Makes the call available as a data source (read operations); appears in the "Get data from an external API" dropdown.
- "Use as: Action" -- Makes the call available as a workflow action (write/mutate operations); appears under Plugins in the actions menu.
- "Private" (parameter/header) -- The value is never exposed to the end-user's browser; use this for API keys and secrets.
- "Client-safe" -- The value is sent to the browser and can be set dynamically in the editor; appropriate for search terms, filters, and other non-sensitive inputs.
- "Allow blank" -- Prevents a parameter's default/initialization value from being sent in production calls.
- "Shared headers" -- Headers defined at the API level that apply to every call within that API.
- "Body type" -- The format of the request body: JSON, Form-data, or Raw (plain text).

## Screenshots Needed
> Drop 3-5 annotated screenshots in the `screenshots/` folder next to this file.
> Suggested captures:
> - The API Connector plugin panel showing an expanded API with its authentication dropdown
> - A single call fully configured: name, method, URL, headers, parameters, body, and the "Initialize call" button
> - The initialization success state showing the parsed response fields
> - The "Use as" toggle (Data vs Action) and the "Include errors in response" checkbox
> - A workflow or data-source picker showing an initialized API call available for selection
