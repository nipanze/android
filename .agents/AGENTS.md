# Project-Wide Agent Build & Verification Rules

These rules apply to **every feature, screen, process, and database change** made by the agent within the codebase.

---

## 1. Language, Theme & Currency Verification

* **Localization & RTL**:
  * Supported languages: **English (`en`)**, **Swahili (`sw`)**, **French (`fr`)**, **Kinyarwanda (`rw`)**, and **Arabic (`ar`)** (with full Right-to-Left / RTL layout support).
  * Every user-facing screen and notification **must strictly use the localization system** (`AppLocalizations`).
  * Never introduce hardcoded user-facing strings.
  * Verify all UI elements across localized text: page titles, labels, action buttons, placeholders, validation messages, empty states, error/success notifications, and dialogs.

* **Theme Adaptivity (Light & Dark Mode)**:
  * Every screen and custom component must adapt seamlessly to **both Light and Dark themes**.
  * Use `Theme.of(context)` dynamic tokens (`colorScheme.surface`, `colorScheme.onSurface`, `colorScheme.primary`, etc.) instead of hardcoded hex values or fixed colors.
  * Ensure card backgrounds, borders, shadows, icons, and text maintain high contrast and visual polish in both theme modes.

* **Currency & Formatting**:
  * Amounts, symbols, numbers, and dates must honor the user's currency and regional locale settings.

---

## 2. Navigation, Deep Linking & Workflow Resilience

* **Route Parameter Fallbacks**:
  * Deep-link handlers and page parameters must handle ambiguous or alternative identifiers (`agreementId`, `offerId`, `requestId`) gracefully.
  * Repositories and domain models must attempt fallback resolution (e.g. resolving `agreementId` via `offerId` or `requestId` lookup) before failing.

* **Non-Active Entity Data Handling**:
  * When listings or requests change status (e.g., `contracted`, `completed`, `cancelled`), view queries (like `v_loan_listings`) may filter them out.
  * Repositories must fall back to table queries (`loan_requests`, `loan_offers`) when listing detail views return 0 rows.

* **Graceful Error Handling**:
  * Wrap all deep-link navigations and async action flows in `try-catch` blocks.
  * Display clean, human-readable error messages using `userFacingErrorMessage(e)` via SnackBars or dialogs instead of breaking UI execution.

---

## 3. Input Validation & Form Safety

* **Button State Management**:
  * Action buttons must accurately reflect input validation states:
    * Required input missing or invalid → **Disabled**
    * Required input valid → **Enabled**
    * Async submission / loading in progress → **Disabled with loading indicator**
  * Do not rely solely on post-click error messages.

---

## 4. Database Architecture & SQL Patch Rules

* **Standalone SQL Patch Policy**:
  * **Never modify existing historical migration files** for new database changes.
  * Every new database schema change, RLS policy, RPC function, trigger, or table modification must be placed in a **new standalone SQL patch file** with a clear timestamped or descriptive name (e.g., `sql/patch_contact_reveal_permissions.sql` or `sql/20260902_add_user_blocking.sql`).

* **Multi-Party Permission Security**:
  * Database RPCs and functions for multi-party workflows (such as agreements, contact reveals, and bid acceptances) must validate **all legitimate deal participants** (e.g., both borrower and lender) rather than artificially restricting access to a single party.

---

## 5. Definition of Done & Completion Checklist

Before marking any task or feature as **complete**, the agent must verify:

- [ ] **Localization**: Screen/process accurately renders in all target languages (`en`, `sw`, `fr`, `rw`, `ar`) without hardcoded text.
- [ ] **Theme Adaptivity**: Verified UI appearance in both **Light and Dark modes** using dynamic `Theme.of(context)` tokens.
- [ ] **Currency & Formatting**: Correctly reflects locale-specific currency symbols and number formats.
- [ ] **Navigation & Deep Links**: Route handlers and fallback lookups resolve parameters (`agreementId`, `offerId`, `requestId`) without failing.
- [ ] **Form Validation**: Buttons dynamically update between enabled, disabled, and loading states based on form validity.
- [ ] **Error Handling**: Async flows catch exceptions and present localized, formatted user error messages.
- [ ] **Database Integrity**: Database modifications are contained in a new standalone SQL patch and validate multi-party permissions.
- [ ] **Documentation**: Updated `README.md` and/or build plan documents to reflect implemented changes.
- [ ] **Code Verification**: `flutter analyze` passes with zero issues and `flutter test` completes successfully.

## 6. AI Agent Operating Rules

These rules apply to any AI coding agent working on Nipanze, including local models such as Ollama/Qwen.

### Before Making Changes

- Inspect the existing implementation before proposing changes.
- Read the relevant feature files, repository, models, routes, localization files, and database definitions before editing.
- Do not invent tables, columns, RPCs, views, policies, routes, models, or services that do not exist.
- Reuse existing architecture and patterns wherever possible.
- Do not rewrite working code unnecessarily.
- Do not make unrelated changes.

### Database Safety

- Never modify historical SQL migrations or existing database patches for a new change.
- Create a new standalone SQL patch for every database change.
- Never expose, hardcode, or commit Supabase service-role keys, API keys, passwords, tokens, or other secrets.
- Never place secrets in source code, documentation, prompts, agent instructions, or test fixtures.
- Before creating SQL, inspect the current schema and existing functions/policies.

### Code Changes

- Make the smallest safe change that solves the requested task.
- Preserve existing BLoC/Cubit, repository, dependency-injection, and routing patterns.
- Do not introduce a new state-management or architectural pattern without explicit approval.
- Do not remove existing functionality unless explicitly requested.
- Do not silently change business rules.

### Verification

After implementation:

1. Run `flutter analyze`.
2. Run the relevant tests.
3. Run `flutter test`.
4. Verify localization.
5. Verify Light and Dark themes.
6. Verify currency and number formatting.
7. Verify navigation and deep-link fallbacks.
8. Verify loading, disabled, success, and error states.
9. Review the git diff for unintended changes.
10. Update README/build-plan documentation when required.

### Reporting

When finished, report:

- Files changed
- What changed
- Database patches created
- Tests run
- Verification results
- Any remaining warnings or limitations

Never claim a task is complete if required verification has not actually been performed.
