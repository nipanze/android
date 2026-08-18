# Project-Wide Agent Build & Verification Rules

These rules apply to **every feature, screen, process, and database change** made by the agent.

## 1. Language & Currency Verification

* Every screen and process **must reflect the user's current language and currency settings**.
* Do not assume that adding a translation file is enough.
* After implementing or modifying a screen, the agent must **verify the actual screen/UI** using the user's selected language.
* Verify that all user-facing content is localized, including:

  * Page titles
  * Labels
  * Buttons
  * Placeholders
  * Validation messages
  * Error messages
  * Success messages
  * Empty states
  * Dialogs/modals
  * Notifications
  * Currency symbols and amounts
  * Date/number formatting where applicable
* If the user changes their language or currency settings, the affected screen must correctly update to reflect the new settings.
* For languages requiring RTL, verify that the screen layout correctly supports RTL.
* **Do not mark a screen or feature as complete until this verification has been performed.**
* Do not introduce new hardcoded user-facing strings when the project has a localization system.

## 2. Input Validation & Button States

* All required inputs must be validated before an action can be performed.
* **Disable all relevant action buttons when required inputs are missing or invalid.**
* Do not rely only on showing an error after the user presses the button.
* Buttons must clearly reflect the current form state:

  * Required input missing → **Disabled**
  * Input invalid → **Disabled**
  * Required input valid → **Enabled**
  * Submission/loading in progress → **Disabled**
* Verify these states during testing for every form or input-based process.

## 3. README & Build Plan

* Every implemented or modified feature must be documented in the project's **README and/or build plan** where appropriate.
* Documentation must describe the **actual implemented changes**, not just the planned functionality.
* Update the documentation before marking the related task complete.
* Include important implementation details, verification requirements, database changes, and relevant user-facing behavior.

## 4. Database Patch Rules

* **Never modify the existing monolithic `patch.sql` file** for new database changes.
* Every new database change must use a **new standalone SQL patch file**.
* This applies to:

  * Schema changes
  * Tables
  * Columns
  * Indexes
  * Functions
  * Triggers
  * RLS policies
  * Constraints
  * Database configuration changes
* Use clear, descriptive, or timestamped filenames, for example:

`sql/patch_referral_system_v2.sql`

or

`sql/20260818_add_user_blocking.sql`

* Each patch must be independently identifiable and contain only the changes relevant to that update.
* Do not rewrite, merge into, or overwrite previous patches unless explicitly instructed.

## 5. Completion Verification

Before marking any task as **complete**, the agent must verify:

* [ ] The implemented screen/process reflects the user's language setting.
* [ ] The implemented screen/process reflects the user's currency setting where applicable.
* [ ] Required inputs correctly control button enabled/disabled states.
* [ ] Loading/submission states prevent duplicate actions.
* [ ] User-facing text uses the localization system.
* [ ] README/build plan reflects the implemented changes.
* [ ] Database changes use a new standalone SQL patch.
* [ ] The implementation has been tested on the actual affected screen/process.

**The agent must fix any failed verification before considering the task complete.**
