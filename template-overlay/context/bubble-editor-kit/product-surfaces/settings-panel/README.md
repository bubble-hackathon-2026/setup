# Settings Panel

## What It Is
The Settings tab is the control center for everything about your app that is not page-specific design or logic. It spans billing and plan management, security and privacy configuration, domain and email setup, SEO and metatags, API exposure (Data API and Workflow API), collaboration and access control, language/localization management, version and platform updates, native mobile app publishing, and a collection of advanced options like timezone overrides, custom fonts, Figma imports, and app optimization tools. Changes made here generally require a deploy to take effect in the live environment.

## Key Behaviors
- **My Plan sub-tab:** View your current Bubble plan tier, workload usage, storage consumption, and installed plugin count.
- **General sub-tab:** A broad collection of settings organized into sections:
  - *Privacy & Security:* application rights (private/public/editable), password policies (min length, require numbers/capitals/special chars), two-factor authentication setup, X-Frame-Options for iframe embedding, cookie consent controls ("Do not set cookies on new visitors by default"), file-upload endpoint toggle, and app-level username/password protection.
  - *General Appearance:* favicon upload, progress bar color, repeating group spinner color.
  - *API Keys:* Google Maps, Google Geocode, Algolia application/search/admin keys.
  - *iOS Appearance:* hide Safari UI, prevent zoom, home-screen icon, startup images for iPhone and iPad.
  - *Custom Fonts:* upload CSS font files with font-family names; each weight added separately.
  - *Figma Import:* import designs directly from Figma.
  - *App File Management:* optimize app (clean unused metadata), export/import app as JSON, clean app changes history.
  - *Advanced:* timezone overrides, expose HTML element IDs, expression parentheses toggle.
- **API sub-tab:** Enable/disable the Workflow API and Data API, generate and label API tokens, configure OAuth/SAML third-party access, set up Discourse SSO, toggle Swagger docs visibility, and configure infinite recursion protection.
- **Collaboration sub-tab:** Invite collaborators by email, assign privilege levels controlling what each person can view or edit.
- **Languages sub-tab:** Manage app text translations for every static string (built-in, plugin-provided, or custom). Supports CSV import/export for bulk translation work.
- **Web App sub-tab:** SEO settings (OpenGraph title/description/image, robots.txt customization, sitemap exposure), 301 redirects, root-directory file hosting, script/meta tag injection in header and body, and domain/email configuration.
- **Native Mobile sub-tab:** App display name, icon, splash screen, Apple App Store settings (Bundle ID, Team ID, APNs keys), Android Play Store settings (package name, signing keys, Firebase), build management, device permissions, and supported languages.
- **Versions sub-tab:** Manage Bubble platform version upgrades; Enterprise plans get granular update control.
- **Sub Apps sub-tab:** Link parent-child app relationships and push changes from parent to children for white-labeling scenarios.
- **Notifications sub-tab:** Set up custom alerts for workload unit consumption to stay on top of spending.

## Vocabulary
- "Deploy" -- Publishing your Development environment changes to the Live environment so end-users see them.
- "API token" -- A secret key generated in the API sub-tab that authenticates external calls to your app's Data API or Workflow API.
- "Data API" -- An auto-generated REST API that lets external systems read from and write to your app's database.
- "Workflow API" -- An API that lets external systems trigger backend workflows in your app.
- "App text" -- A static string in your app (button labels, error messages, etc.) that can be translated into multiple languages via the Languages sub-tab.
- "Sub app" -- A child app linked to a parent; changes can be pushed from parent to child for white-labeling scenarios.
- "Workload" -- A measure of server computing resources your app consumes; tracked and billed in the My Plan sub-tab.
- "X-Frame-Options" -- A security header controlling whether your app can be embedded in iframes on other websites.
- "Opt-in to Cookies" / "Opt-out from Cookies" -- Workflow actions that control whether Bubble sets cookies for the current visitor, used for GDPR-style consent flows.

## Screenshots Needed
> Drop 3-5 annotated screenshots in the `screenshots/` folder next to this file.
> Suggested captures:
> - The General sub-tab showing the Privacy & Security section with password policy controls
> - The API sub-tab with Data API and Workflow API toggles and the API token generator
> - The Languages sub-tab with translated app texts and the import/export buttons
> - The Web App sub-tab showing SEO/metatag settings and the domain configuration area
> - The Native Mobile sub-tab showing Apple and Android store configuration fields
