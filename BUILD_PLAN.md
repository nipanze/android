# Nipanze — Needs Layer & Provider Services Build Plan (Stage 4.8 — Implemented)

Goal: add **Needs** as the third module beside Loans and Forex, plus intent-based onboarding and a personalized Home. Loans and Forex stay untouched. Everything reuses existing auth, plans, trust, blocks, contact reveal and the private/public RPC wrapper pattern.

> Scope note: this plan is grounded in `schema.sql`, `seed.sql`, `patch.sql`, `merged.sql` and the README. I could not see the Flutter code, so Flutter steps follow the README's proposed structure. `patch_needs_layer.sql` is referenced by the README but is **not in the project**. Phase 1 writes it.

---

## 1. Findings that change the plan

| # | Finding | Impact |
|---|---|---|
| 1 | `needs_requests` grants `SELECT` on the base table to `anon` with an "active rows" policy. `requester_id` is therefore publicly readable. | Privacy fix is the first thing shipped. Public reads move to `v_needs_listings` only. |
| 2 | `budget` is `integer`. `v_needs_listings` depends on it, so `ALTER COLUMN TYPE bigint` fails until the view is dropped. | Migration order: drop view → alter → recreate view. |
| 3 | `needs_requests` uses `timestamptz`; the rest of the schema uses `TIMESTAMP`. `private.is_blocked_from_future_request` takes `TIMESTAMP`, and timestamptz→timestamp is only an assignment cast, so the call will not resolve. | Cast explicitly: `listed_at::timestamp`. Reuse this for all block checks on Needs. |
| 4 | Existing Needs posting has no active-account check, no per-plan limit, no country from profile, no expiry, no offer count. | Add the same trigger set Loans/Forex have. |
| 5 | `chk_reviews_one_contract` (loan XOR forex) and `chk_wl_one_target` (loan XOR forex) are two-way constraints. | Adding a Needs sibling means dropping and recreating them as three-way. |
| 6 | Error-code ranges in use: `P0001–P0050`, `P0101–P0146`. | Use `P02xx` for Needs (README already assumes `P0203`). |
| 7 | 110 sample Needs rows use free-text categories and have `requester_id = NULL`. Many are machinery-like (pumps, mills, ovens, sewing machines) but would default to Products. | Backfill map uses keyword overrides, not just category text. |
| 8 | Countries: README targets 7 markets (UG/KE/TZ/RW/NG/ZA/EG), but seeds, `subscription_prices`, forex seed 3 and Needs samples still use BI/SS/CD/SO. | Needs stays country-text based, so nothing breaks. Decide whether to keep the samples (see Decisions). |
| 9 | Plan is called `lender` but will unlock offers for visa agents and truck owners. | Rename display label only; keep the enum. |

---

## 2. Decisions to lock before Phase 3

| # | Decision | Recommendation |
|---|---|---|
| D1 | Plan display name for offer-makers | Keep enum `lender`; change UI label to "Offers" (or "Provider"). Zero schema cost. |
| D2 | Locked agreement for Needs? | No for launch. Accept → reveal only. Add `need_agreements` later only if a category needs it. |
| D3 | Contact-unlock fee | Still open globally. Build Needs unlock so the fee can be added in one place (`unlock_need_contact`). |
| D4 | Who can unlock | Follow the July patch: **either** party in an accepted deal may unlock. |
| D5 | Free offers per month | `system_settings.needs_free_offers_per_month = 3`, per-country overridable. |
| D6 | Evidence admins check per category for "Provider verified" | Draft checklist per category before Phase 6 (licence, fleet photos, portfolio, agency registration). |
| D7 | Nav change | Ship Home as first tab first. Do the `Home · Markets · ➕ · Activity · Account` change only after Phase 5 proves out. |
| D8 | Retired-country sample Needs (BI/SS/CD/SO) | Keep as dev data, tag `is_sample`; hide in prod by not activating those countries. |

---

## 3. Phases

Each phase is independently shippable and reversible. Sizes: S ≤ 1 day, M 2–3 days, L 4–6 days.

### Phase 0 — Docs (S)
- Apply README Part 1 edits (tagline, three modules table, Needs section, personalization, plan rows, roadmap Stage 4.8, recent updates).
- Add `BUILD_PLAN` entry for Stage 4.8 pointing to this file.

**Done when:** README and BUILD_PLAN agree on categories, tables and route map.

### Phase 1 — Database foundation + privacy fix (M) — `patch_needs_layer.sql`
Ship first; no UI change.

**1a. Privacy and types**
- `DROP VIEW v_needs_listings` → `ALTER COLUMN budget TYPE bigint` → recreate view.
- `REVOKE SELECT ON needs_requests FROM anon`. Replace the public policy with: owner select, admin select. Public reads go through `v_needs_listings` (already excludes `requester_id`).
- Keep owner `INSERT/UPDATE` policies; add owner `SELECT` so `insert ... returning` still works for the app.

**1b. Reference tables**
- `need_categories(slug pk, name, icon, sort_order, is_active)` — seed the five slugs: `travel_international`, `machinery_equipment`, `professional_services`, `transport_logistics`, `specialized_products`. `travel_international.is_active = false` initially.
- `need_capabilities(slug pk, category_slug fk, name, is_active)` — starter set (e.g. `visa_assistance`, `flight_tickets`, `hajj_umrah`, `excavator_hire`, `tractor_hire`, `company_registration`, `legal_services`, `heavy_haulage`, `courier`, `bulk_procurement`).

**1c. Extend `needs_requests`**
Add: `category_slug fk`, `capability_slug fk null`, `details jsonb default '{}'`, `number_of_offers int default 0`, `expires_at`, `terms_locked_at`, `contracted_at`, `cancelled_at`, `views_count`. Widen `status` to `active | matched | expired | cancelled` (text check, since it is text today).
Keep real columns for `title, specification, budget, currency, location, country, urgency`.

**1d. Backfill**
- Map old `category` → `category_slug`, then keyword overrides on `title`: `machine|pump|mill|oven|mixer|huller|sheller|freezer|chiller` → `machinery_equipment`; `motorcycle|van|truck|delivery vehicle` → `transport_logistics` only if it is a haul/hire need, otherwise products.
- Set `expires_at = listed_at + listing_duration_days`. Old samples: re-arm to `now() + 30 days` (mirrors `patch_reboot_expired_loan_requests`).
- Review the resulting counts by category before moving on.

**1e. Triggers on `needs_requests`** (mirror Loans/Forex)
`set_country_from_profile` (BEFORE INSERT, when requester_id present), `require_active_account`, `max_concurrent_needs` (settings `max_active_needs_free/lender/pro`, default 3/8/20), `set_expiry`, `lock_country_on_update`, `updated_at`.

**1f. Settings rows**
`needs_free_offers_per_month=3`, `max_active_needs_*`, `needs_enabled_<slug>` per country (default `true` except Travel = `false`).

**Acceptance / SQL checks**
```sql
-- as anon: must fail or return 0 rows
select requester_id from needs_requests limit 1;
select count(*) from v_needs_listings;               -- still returns rows
select category_slug, count(*) from needs_requests group by 1;
```
**Risk:** low. Rollback = restore old policy + view.

### Phase 2 — Needs browse + post in Markets (M)
- Marketplace module enum: `all | loans | forex | needs` (add `forYou` in Phase 5).
- `NeedCard` per README spec (category badge, meta line, title, budget or "Open to offers", offer count, "Xd left", trust badges, save star).
- `NeedCreatePage`: category picker → field config per category writing `details` jsonb. Keep the README's `needFormSchema` map; unknown keys ignored so no migration per new field.
- Client also sets `category_slug`; server validates category is active for the user's country.
- Constants: `Tables.needRequests`, `Views.needsListings`.
- `MyNeedsPage` (owner reads base table; allowed by owner policy).
- Rebuild `v_needs_listings`: add `category_slug`, `capability_slug`, `number_of_offers`, `offer_coverage_tier`, `expires_at`, `time_remaining`, requester trust fields (same joins as `v_loan_listings`), block filter (with the timestamp cast), hide caller's own needs.

**Acceptance:** post a Need in each active category; card renders; blocked user cannot see it; free user beyond limit gets `NIPANZE_MAX_NEEDS`.

### Phase 3 — Offers, accept, unlock (L) — highest-risk step
**DB**
- `need_offers(id, need_id fk, offer_maker_id fk, price bigint, currency, timeline_text, message, terms_locked_at, status offer_status_enum, offered_at, accepted_at, withdrawn_at, expires_at, timestamps, unique(need_id, offer_maker_id))`. **No country column.**
- `need_contact_reveals` mirroring `contact_reveals`.
- Triggers on `need_offers`: `validate` (need active, not expired, not self, not blocked, **matching capability exists in `provider_capabilities`** → `P0203`, free-tier monthly cap → `P0204`, category enabled for that country), `lock_terms`, `lock_accepted`, `expire`, `sync_offer_count`.
- `get_public_need_offers(need_id)` — owner sees all (anonymized ids `public-offer-N`), offer-maker sees own + anonymized competitors, everyone else gets nothing (coverage tier comes from the view).
- `accept_need_offer(need_id, offer_id)` and `unlock_need_contact(offer_id)` via `private.*_internal` + `SECURITY INVOKER` wrapper, same as Loans/Forex. Accept: lock rows `FOR UPDATE`, accept one, reject the rest, set need `matched`, notify both, write audit log.
- Notifications: add `need_request_id`, `need_offer_id` columns; reuse existing enum values (`offer_received`, `offer_accepted`, `contact_revealed`).
- RLS + realtime publication for the three new tables. Grants: `anon` gets nothing on offers.

**Flutter:** `NeedDetailPage` with offer form (price, timeline, message), offer list for owner, competing-terms panel for offer-makers, accept, unlock, `needs_repository` + `need_detail_cubit`. Activity tab lists "My needs" and "My need offers".

**Acceptance:** run the full loop with two seed users; second accept fails with `NIPANZE_OFFER_NOT_PENDING`; non-participant cannot call `get_public_need_offers` for data.
**Risk:** medium. Mitigate by shipping behind `needs_offers_enabled` setting (default false), then enabling for Uganda only.

### Phase 4 — Provider capabilities (M)
- `provider_capabilities(user_id, capability_slug, verification_level enum self_declared|provider_verified, evidence_url, verified_by, verified_at, created_at, unique(user_id, capability_slug))`.
- Trigger forces `verification_level = 'self_declared'` and clears `verified_*` unless `private.is_admin()`.
- RLS: user manages own rows (level locked by trigger); public sees badge via a view `v_provider_badges` (capability, level only, no evidence URL).
- Flutter: `features/provider/` — `ProviderServicesPage` (`/account/services`), `CapabilityBadge`, `ProviderVerificationChip` (combines capability level + phone + KYC).
- Account: `YOUR SERVICES` entry between Trust & Reputation and Subscription, showing the user's saved capability count/preview or an add-services action; opens `/account/services`.
- Offer form is disabled with a "Add this service to offer" prompt when no matching capability.

**Acceptance:** user cannot raise own `verification_level` (test via direct update); offer without capability rejected server-side.

### Phase 5 — Interests, onboarding, Home, For You (L)
**DB**
- `user_interests(user_id, category_slug, kind explicit|follow|mute, created_at)`, `user_interest_events(user_id, category_slug, event, created_at)` with 30-day retention job.
- `record_interest_event(category, event)` — insert-only, rate-limited per user (e.g. ignore repeats within 10 s).
- `get_for_you_needs(country, limit)` — score = explicit weight + recent event weights + recency; mutes excluded; block and expiry filters applied. Put weights in `system_settings` so they can be tuned without deploys.
- `get_provider_opportunities(limit)` — active needs in categories where the caller has a capability, grouped counts + top items.

**Flutter**
- `InterestsStep` (required, max 3) and `CapabilitiesStep` (optional). Route guard: no `user_interests` rows → `/onboarding/interests` once. Existing users get it on next launch.
- `HomePage`: greeting/search → For You (5) → Your interests → Saved → Provider Opportunities (only if capability exists) → Explore by category. Each section hides when empty.
- Marketplace gains `forYou` tab. Fire-and-forget `record_interest_event` on open/save/post/offer.
- Watchlist: add `need_request_id` to `watchlist` (replace `chk_wl_one_target` with a three-way check) so Saved works for Needs.

**Acceptance:** muted category never appears; new user with no signals still gets a sensible For You (recency fallback).

### Phase 6 — Trust + verification queue (M)
- Add `reviews.need_deal_id` (points to `need_offers`, since there is no agreement table) and replace `chk_reviews_one_contract` with a three-way check. Unique index on `(need_deal_id, reviewer_id)`.
- `submit_need_review()` (requires revealed contact); extend `recompute_trust_aggregates` to union Needs deals into `completed_deals_count`, response time and success rate. Still one global aggregate per user.
- Trigger on `need_contact_reveals` to refresh trust, same as Loans/Forex.
- Admin portal: "Provider capabilities" queue (filter `self_declared`, view evidence, approve → `provider_verified`, reject with reason). Audit-log every decision.

### Phase 7 — Category and market enablement (S, ongoing)
- Enablement = `need_categories.is_active` AND `system_settings.needs_enabled_<slug>` for the country.
- Launch order: **Machinery, Professional Services, Transport, Products**. Travel & International last, and only offerable by `provider_verified` capabilities (add a validate-trigger clause for that category).
- Taxonomy: **Driving School & Driver Training** (`driving_school`) is classified under **Professional Services** (`professional_services`) as a professional training/service performed for the requester, keeping **Transport & Logistics** focused on physical movement of goods, freight, cargo, and equipment.
- Per-category, per-market compliance review recorded in BUILD_PLAN before flipping each flag.

### Phase 8 — Nav change (S)
Only after Phase 5 metrics look healthy: `Home · Markets · ➕ Post · Activity · Account`. Post FAB opens Loan / Forex / Need chooser. Watchlist stays reachable from Account.

---

## 4. Seed data for testing — `patch_seed_needs_layer.sql`
- Capabilities for existing UG/KE users (e.g. lender 026 → `excavator_hire`, lender 010 → `company_registration`, plus one free user with a capability to test the monthly cap).
- Link ~10 existing sample Needs to seed requesters (they are `NULL` today), so ownership flows can be tested.
- One `matched` Need with an accepted offer, a revealed contact and a review, to test trust aggregation. Insert with `session_replication_role = replica`, then call `recompute_trust_aggregates` — same pattern as the forex seed.
- A muted category and interest rows for the test user.

## 5. Test matrix (write alongside each phase)
| Area | Case |
|---|---|
| Privacy | anon cannot read `requester_id`; non-owner cannot read base table rows |
| Offers | no capability → `P0203`; free user's 4th offer in a month → rejected, `lender` user unaffected; self-offer, blocked, expired need rejected |
| Transparency | non-participant sees count + tier only; offer-maker sees anonymized competitors; owner sees all |
| Accept | one accepted, others rejected, need `matched`, double-accept fails |
| Contact | hidden before accept; either party can unlock; irreversible; audit row written |
| Capabilities | user cannot self-verify; non-admin cannot set `verified_*` |
| Feed | muted category excluded; expired/own/blocked needs excluded |
| Trust | Needs deal increments the same `trust_aggregates` row as Loans/Forex |
| Regression | Loans and Forex flows, `v_loan_listings`, `v_forex_listings`, watchlist for loans/forex |

## 6. Deliverables checklist
- [ ] `patch_needs_layer.sql` (Phases 1, 3, 4, 5, 6 as sequenced sections)
- [ ] `patch_seed_needs_layer.sql`
- [ ] README edits (Part 1)
- [ ] Flutter features: `needs/`, `provider/`, `interests/`, `home/`; shared widgets `NeedCard`, `CategoryChip`, `CapabilityBadge`, `ProviderVerificationChip`
- [ ] Constants: `Tables.needOffers`, `Rpcs.getForYouNeeds`, `acceptNeedOffer`, `unlockNeedContact`, `getProviderOpportunities`, `recordInterestEvent`
- [ ] Admin portal: provider capabilities queue
- [ ] Per-category compliance checklist (D6)

## 7. Suggested order of shipping
1. Phase 1 (privacy fix goes out alone, this week)
2. Phase 2 → Phase 3 (Uganda only, flag off until QA passes)
3. Phase 4 → Phase 6 (capability-gated offers with admin queue)
4. Phase 5 (changes first-run, so ship after offers are stable)
5. Phase 7 flags per market/category; Phase 8 nav last

---

## 8. Stage 4.9 — Central Verification System & Activity Navigation (Implemented)

### Overview
Extended the existing Identity Verification (KYC) system in Account → Edit Profile → Identity Verification to serve as the unified, platform-wide central verification system for all marketplace activities.

### Key Additions
1. **Database Schema & Server-Side Security (`sql/patch_central_verification_system.sql`)**:
   - `verification_requirements` table with hierarchical evaluation (`capability` -> `category` -> `activity` -> `global`).
   - Server-side triggers preventing unverified users from inserting into `loan_requests`, `forex_requests`, `needs_requests`, `loan_offers`, `forex_offers`, `need_offers`, `provider_capabilities`.
   - RPC enforcement in `accept_offer`, `accept_forex_offer`, `accept_need_offer`, and `unlock_need_contact`.
   - Authoritative RPC: `can_perform_marketplace_activity(p_activity, p_category_slug, p_capability_slug)`.
   - Admin RPCs for configuration: `admin_get_verification_requirements`, `admin_update_verification_requirement`.
2. **Flutter Verification Layer**:
   - `VerificationService`: Cached requirement fetching, hierarchical fallback evaluation, and direct RPC evaluation.
   - `VerificationGateModal.checkAndGate`: Reusable bottom-sheet gate intercepting Post chooser actions, Make an Offer buttons, and Service Offer forms.
3. **Identity vs. Provider Verification Distinction**:
   - **Identity Verified**: User identity confirmed via national ID & selfie (`profiles.kyc_status = 'approved'`).
   - **Provider Verified**: Category/capability-specific credentials verified by admin review (`provider_capabilities.verification_level = 'provider_verified'`).
4. **Activity Terminology Standardization**:
   - Replaced all user-facing "Positions" terminology with "Activity" across bottom navigation (`navActivity`), routes (`AppRoutes.activity`), and page headers.
5. **Localization & RTL**:
   - Fully localized in English (`en`), Swahili (`sw`), French (`fr`), Kinyarwanda (`rw`), and Arabic (`ar`).

## 9. Stage 4.10 — Marketing & Promotion Capabilities (Implemented)

- Renamed the existing `marketing_services` catalog label to Marketing & Promotion without changing its slug, preserving existing provider selections.
- Added 14 focused marketing capabilities plus `i_have_an_audience` to `professional_services` through `sql/patch_marketing_promotion_capabilities.sql`.
- Extended the existing provider capability picker for multiple marketing selections and optional audience platforms, follower/member count, location, and interest. Audience data is stored in `provider_capabilities.metadata`.
- Kept audience information explicitly self-declared; the existing provider verification trigger and capability-based Provider Opportunities RPC are unchanged.
- Localized the picker and audience fields in `en`, `sw`, `fr`, `rw`, and `ar`.

## 10. Stage 4.11 — Creative, Graduation & Celebration Opportunities

- Expand the existing Needs catalog through `sql/patch_creative_events_capabilities.sql`; do not add request, provider, offer, trust, verification, or interest tables.
- Add `music_video` and `weddings_celebrations` capability groups, including performers, studios and post-production, graduation and wedding photography/videography, makeup and hair, bridal styling and outfits, decoration, catering, cakes, DJs/MCs, event planning/transport, and social celebrations.
- Continue storing each provider selection as a separate `provider_capabilities` row. The existing multi-select picker, matching validation, Provider Opportunities, trust, central verification, and Need → Offer → Accept → Contact Reveal flow remain authoritative.
- Keep capabilities gender-inclusive. This broadens opportunities likely to resonate with women without splitting the marketplace or restricting access by gender.
- Add optional `country_labels` JSONB overrides to the existing category and capability catalog rows. Overrides are keyed by ISO country code and do not alter stable slugs, `needs_requests.country`, or currency handling.
- Add category-specific form fields and offline catalog defaults for music/video and celebrations. Use existing category enablement and local compliance review before rollout in each country; do not change Loans or Forex.

**Acceptance checks:** the patch is re-runnable; new catalog entries use the existing two catalog tables; multiple capabilities can be selected; matching offers use the existing `need_offers` flow; missing country overrides fall back to shared labels; Loans and Forex regression tests remain unchanged.

## 11. Cached browsing during network interruptions

- Use the existing `OfflineService`/`connectivity_plus` stream and network exception mapping to report connectivity transitions and failed requests.
- Replace the persistent offline banner with brief SnackBars; refresh active Marketplace, Profile, Provider Services, and Activity data automatically when connectivity returns.
- Retain the latest successful Marketplace/Profile response in memory and keep already-loaded Cubit state visible after failed refreshes. Preserve the existing retry state when there is no cached data.
- Keep this limited to stale-data browsing; server mutations are not queued and remain subject to successful server requests. Clear Marketplace/Profile caches on sign-out.
- No database changes or offline synchronization are introduced.

**Acceptance checks:** existing loaded feed/profile/services/activity content stays visible after a failed refresh; first-load failures retain a retry option; connectivity feedback appears once per state transition; reconnection refreshes data; caches clear on sign-out.

## 12. Loan-only borrower information and non-financial Needs categories

- Keep `financial_services` out of the active Needs category and capability catalogs without deleting historical category, capability, or request rows. Filter the retired slug in the Needs client, disable its reference rows, and reject new Needs inserts/category changes using the standalone migration.
- Do not add a Financial Profile, Income Profile, or Banking Profile to Account, onboarding, or general profile editing.
- Store reusable employment status, employer/business name, government employee status, monthly income range, other income source, and preferred bank in the dedicated `public.borrower_information` table. RLS permits authenticated users to read and update only their own row. Do not join this table into any public marketplace view.
- Collect and pre-fill these values only in Post → Loan. Saving loan-specific details (amount, purpose, repayment period, collateral, and request requirements) remains specific to each request.
- Consolidated in `sql/patch.sql` and `sql/merged.sql`.

**Acceptance checks:** Financial Services is absent from the Needs picker and rejected for new Needs requests; old rows remain intact; the private borrower row is inaccessible to anon/other users; first and subsequent Loan Requests can enter, reuse, edit, and update borrower information; public Loan/Forex/Needs listing payloads do not include these fields; Account, Forex, Loans marketplace, and existing Needs behavior otherwise remain intact.

## 13. Stage 4.12 — Private Discovery Plans & Quick Questions

- Consolidated migration in `sql/patch.sql` and `sql/merged.sql` for `discovery_question_templates`, `user_discovery_plans`, and `user_discovery_interactions`.
- Templates are authenticated-readable and admin-managed through RLS. User plans and interaction history are private to the owner.
- Added a reusable Flutter discovery card in `lib/features/discovery/` and inserted it into the Marketplace/Home feed without interrupting listing browsing.
- Added Account -> Plans & interests for reviewing, editing, and deleting private saved plans.
- Seeded starter templates for travel, education/career, business needs, and financial interests. Financial answers remain private discovery signals and do not create Needs posts.
- Updated the business discovery template to multi-select Equipment, Logistics, Services, and Procurement; choices use the existing owner-scoped `user_interests` table.
- The Explore route passes category filters into the real marketplace feed, while saved categories improve For You ranking without hiding unrelated listings.
- Empty filtered results point to the existing Need creation flow; interest selection never publishes a request or asks for notification permission.
- Skip and menu dismissal retain cooldowns, interest-save failures are surfaced, and internal prompt-generation wording was removed from the Need composer UI.
- Publishing remains explicit: discovery answers can save a private plan only; no listing is automatically created.

**Acceptance checks:** users can skip/dismiss/mute questions; saved plans remain private under RLS; plans can be edited/deleted from Account; existing Loans, Forex, Needs, provider services, contact reveal, and watchlist flows remain unchanged.

## 14. Existing-post expiry migration (v1)

### Approved durations

| Post type | Duration |
|---|---:|
| Loan | 30 days |
| Forex | 7 days |
| Machinery & Equipment Need | 14 days |
| Professional Services Need | 14 days |
| Transport & Logistics Need | 7 days |
| Specialized Products & Procurement Need | 14 days |
| Travel & International Need | 14 days |

### Migration

- Standalone file: [`sql/patch_migrate_existing_post_expiry_v1.sql`](./sql/patch_migrate_existing_post_expiry_v1.sql). Keep it separate from `sql/patch.sql`.
- Apply after `schema.sql`, `patch.sql`, and the Needs schema have been applied; use a database backup and execute as the database owner, staging before production.
- The transactional patch validates existing global duration settings and country overrides against the approved values, then uses the settings values for the backfill.
- Recalculate only active, classifiable posts from `listed_at`; do not use `created_at`/`updated_at` or reset a post to a fresh lifetime. Posts whose recalculated expiry has passed are changed from active to expired.
- Leave terminal states and all offers, reviews, audit history, and other historical data untouched. Do not emit migration-time notifications.
- Needs rows with missing listing times or unsupported/missing `category_slug` are reported and not recalculated. Audit output also identifies sample/development records with repository seed heuristics.
- Preserve the existing expiry trigger names; correct the Forex trigger setting, add configured Needs insert expiry, and leave existing listing views/recommendation RPC definitions, output columns, grants, and dependencies untouched. The backfill marks overdue active rows expired, which removes them from the existing active-status filtered public feeds and Needs recommendation queries. Guard new offers and acceptance state transitions. Schedule the private expiration sweep every five minutes if `pg_cron` is installed, replacing the named job on rerun.

### Execution and verification status

1. Back up; confirm schema and Needs patch are present.
2. Run `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f sql/patch_migrate_existing_post_expiry_v1.sql` in staging (or paste the standalone file into the Supabase SQL editor).
3. Review its before/after per-market/status totals, expiry updates, active-to-expired counts, terminal-status comparison, invalid/missing expiry rows, sample rows, and manual-review rows. Confirm pg_cron scheduling; if unavailable, enable it and schedule `SELECT * FROM private.expire_marketplace_posts_v1()` every five minutes.
4. Rerun in staging and verify it updates zero expiry dates and expires no additional rows. Run the offer/acceptance smoke checks before production.
5. Apply the same file to production only after staging sign-off; production execution and record counts are still pending.

**Local verification (PostgreSQL 15 fixture, not production):** 3 Loans, 3 Forex, and 5 Needs examined. First run updated 2, 2, and 3 expiry dates, respectively, and expired one active post in each market. One contracted Loan, one contracted Forex, and one matched Need retained their terminal statuses. No timestamps/expiry dates were missing in the first fixture run; one historical `financial_services` Need had no approved duration mapping and was skipped/reported. A supplemental run nulled one active expiry per market; all three were restored from `listed_at`, and the following run updated zero dates and expired zero additional posts. Feed and Provider Opportunities expiry checks, configured insert durations, valid live offer/acceptance transitions, and rejection of expired offer/acceptance flows passed with Loan/Forex enum status types. Existing offer-validation triggers and acceptance RPCs remained present; fixture offer, review, and audit rows remained. A follow-up PostgreSQL 15 run with deliberately extended deployed-view columns completed without redefining the views; the output columns remained intact and all feed/recommendation expiry checks passed. Listing views and recommendation RPC definitions remain untouched by the migration, avoiding deployed output-column/dependency drift. The full Supabase stack did not start because its configured local ports were already occupied; tests used an isolated local PostgreSQL instance instead.

**Manual review:** production IDs/counts are unknown until the migration is run. Inspect every skipped `financial_services`/unknown Needs category and every row reported with a null listing timestamp before deciding whether an explicit correction is justified. Review the sample/development IDs listed by the audit rather than treating seed data as live user inventory.

**Notifications:** no expiry-reminder sender was found in repository SQL/functions. This migration sends none. The normal deployed reminder worker, if external to this repository, must check active status, due two-day timing, and an unnotified expiry cycle; it must not remind matched, cancelled, or expired posts.

## 15. Stage 4.13 — Post Duration Info Card (Flutter UI)

### Overview

Displays a compact, professional "active duration" label on every request-creation screen so users know how long their post will stay live before it automatically expires. The feature is purely informational — it reads the duration from the existing `PlatformLimits` / `system_settings` source of truth and displays it; the actual expiry is still enforced server-side by `trg_fn_set_listing_expiry()` (patched in Stage 14).

### Duration Source of Truth

| Post type | Setting key | Default |
|---|---|---:|
| Loan request | `listing_duration_days` | 30 days |
| Forex request | `forex_listing_duration_days` | 7 days |
| Machinery & Equipment Need | `needs_default_duration_machinery_equipment_days` | 14 days |
| Professional Services Need | `needs_default_duration_professional_services_days` | 14 days |
| Transport & Logistics Need | `needs_default_duration_transport_logistics_days` | 7 days |
| Specialized Products Need | `needs_default_duration_specialized_products_days` | 14 days |
| Travel & International Need | `needs_default_duration_travel_international_days` | 14 days |

All values come from `SystemSettingsRepository.getLimits()` → `PlatformLimits`. No duration value is hardcoded on any creation screen.

### Files Changed

| File | Change |
|---|---|
| `lib/shared/widgets/post_duration_info_card.dart` | **New** — reusable `PostDurationInfoCard(durationDays, compact)` widget |
| `lib/features/listings/presentation/pages/listing_create_page.dart` | Show card above buttons on step 3 (final review) |
| `lib/features/forex/presentation/pages/forex_create_page.dart` | Load `PlatformLimits`; show card above submit button and in preview dialog |
| `lib/features/needs/presentation/pages/needs_create_page.dart` | Load `PlatformLimits`; show card above submit button (updates when category changes) and in preview dialog |
| `lib/l10n/app_en.arb` + `_sw`, `_fr`, `_rw`, `_ar` | Added `postDurationActiveDays`, `postDurationFullNotice`, `postDurationNotice` in all 5 locales |
| `lib/l10n/app_localizations*.dart` | Regenerated via `flutter gen-l10n` |
| `test/shared/widgets/post_duration_info_card_test.dart` | **New** — widget tests for all durations, compact mode, dark/light, all 5 locales, edge cases |
| `test/features/settings/platform_limits_test.dart` | **New** — unit tests for `PlatformLimits.durationForNeedsCategory` and `listingDurationDays` / `forexListingDurationDays` |

### Widget Design

- Clock icon (`Icons.schedule_rounded`) in a primary-colour tinted circle
- Bold text: `"Your request will be active for N days."` (localised)
- Smaller text: `"Your request will automatically expire after this period."` (hidden in compact mode)
- Uses `Theme.of(context)` tokens — adapts to light and dark mode
- No hardcoded colours; no extra dialogs or screens

### No Database Changes

This stage introduces no new database columns, tables, or migrations. All expiry enforcement remains in `trg_fn_set_listing_expiry()` (patched in Stage 14).

### Acceptance Checks

- Loan creation step 4 shows "Active for 30 days"; Forex shows "Active for 7 days"; Needs shows the category-specific duration.
- Changing the Needs category updates the label immediately (reactive via `setState`).
- The displayed duration matches the server-side `system_settings` values.
- Widget and unit tests pass (`flutter test`).
- `flutter analyze` reports zero warnings.
- All 5 locales (en, sw, fr, rw, ar) and both themes (light, dark) render without overflow or exceptions.

## Marketplace Home and Listing Card Polish — October 2026

- Home continues to delegate to the shared Marketplace feed; Home and Markets use the same listing card for Loans, Forex, and Needs.
- Cards use a compact blue-first hierarchy with a title, amount, relevant location, offer count, and module-specific details. Listing-age labels and loan repayment terms are not shown as expiry metadata. Secured is shown only for loans marked as collateral-backed.
- `ListingExpiryIndicator` uses the public `expires_at` and `listed_at` timestamps to represent the remaining fraction of the original listing lifetime. It shows a live, localized exact countdown on tap; missing expiry is omitted, and expired listings show an expired state. Existing detail-page expiry/offer rules remain authoritative.
- Provider opportunities and their recommendation placement/matching remain unchanged; feed spacing and card presentation are tightened.
- Discovery prompts remain pinned to the For You tab only; the rest of the marketplace remains a pure listings experience.
- No database changes.

**Verification:** focused ListingCard, expiry-indicator, Forex model, and Marketplace feed widget tests; Flutter formatting and analysis.

---

## 16. Stage 4.14 — Provider Capability Profiles & Work Profiles

### 1. Scope & Findings
- **Baseline Foundation**: Nipanze's Stages 4.8–4.13 established `need_categories`, `need_capabilities`, `provider_capabilities`, `verification_requirements`, and `can_perform_marketplace_activity`.
- **Target Architecture**: Single user account holding multiple independent capabilities across categories and work roles. Each capability maintains its own evidence, verification status, and gating.
- **Key Findings**:
  1. Historical SQL patches must not be modified (`.agents/AGENTS.md`). All changes belong in a new standalone patch (`sql/patch_provider_services_work_profiles.sql`).
  2. Home feed and listings views (`v_loan_listings`, `v_forex_listings`, `v_needs_listings`, `get_for_you_needs`) are strictly protected from modification.
  3. Work roles map directly as capability rows (`capability_type='work'`), avoiding parallel profile schemas.

### 2. Decisions Log
| ID | Decision | Status | Date | Rationale |
|---|---|---|---|---|
| D1 | Work roles as capability rows | Decided | 2026-10-16 | Reuses verification hierarchy, gating, and matching without duplicate profile schemas. |
| D2 | Standalone SQL patch | Decided | 2026-10-16 | Conforms strictly to `.agents/AGENTS.md` migration immutability rules. |
| D3 | DB category preservation | Decided | 2026-10-16 | Keep existing DB slugs; map v2 14 categories via `ui_group_slug`. |
| D4 | Soft cap on capabilities | Decided | 2026-10-16 | Set `max_provider_capabilities = 30` in `system_settings`. |
| D5 | Evidence storage | Decided | 2026-10-16 | Private storage bucket with signed URLs; reviewed by admin only. |

### 3. Phase Table
| Phase | Task | Files / SQL | Tests | Status | Date | Notes |
|---|---|---|---|---|---|---|
| P0 | Plan, baselines, and decisions | `BUILD_PLAN.md`, baselines | Diff checks | Done | 2026-10-16 | Baseline analyze and provider tests verified |
| P1 | SQL Catalog v2 & taxonomy | `sql/patch_provider_services_work_profiles.sql` | SQL dry-run | Done | 2026-10-16 | 14 categories, 130 canonical services, 62 roles, kinds, qualifications |
| P2 | SQL RPCs, Evidence & RLS | `sql/patch_provider_services_work_profiles.sql` | RLS & RPC tests | Done | 2026-10-16 | `save_provider_capabilities`, `provider_capability_evidence`, `v_my_capability_status` |
| P3 | Screen A & Sheets B/C (Offer flow) | `provider_services_page.dart`, `add_service_sheet.dart` | Widget tests | Done | 2026-10-16 | Screen A unified view with filter chips (All/Services/Jobs), work strip, multi-select save |
| P4 | Sheets D–F (Work roles) & Sheet G | `add_service_sheet.dart`, `capability_detail_sheet.dart` | Widget tests | Done | 2026-10-16 | 3-step role wizard (kinds, qualifications, proof upload), Sheet G details modal |
| P5 | Matching, Trigger & Opportunities | `trg_validate_need_offer`, matching RPC | Unit tests | In Progress | 2026-10-16 | `private.capability_match_score` implemented in SQL |
| P6 | Admin portal queue & Settings | Admin portal pages | Integration | In Progress | 2026-10-16 | Settings flags & admin review policies seeded |
| P7 | Localization, Themes & RTL | `app_en.arb`, `_sw`, `_fr`, `_rw`, `_ar` | L10n & Theme tests | Done | 2026-10-16 | Dynamic tokens, theme-adaptive cards, clean analyze (0 errors, 0 warnings) |

### 4. Per-Category Tracker (14 Categories)
| Category Slug | Catalog Seeded | Offer Sheet | Roles/Kinds/Quals | Evidence Rules | Hire Need | Flag State | Status |
|---|---|---|---|---|---|---|---|
| `technology_digital` | Done | Done | 5 roles | Low (Self-declared) | Supported | Seeded | Done |
| `marketing_promotion` | Done | Done | 4 roles | Low (Audience) | Supported | Seeded | Done |
| `professional_services` | Done | Done | 8 roles | High (Licence) | Supported | Seeded | Done |
| `education_training` | Done | Done | 4 roles | Med (Placements) | Supported | Seeded | Done |
| `events_production` | Done | Done | 5 roles | Low-Med | Supported | Seeded | Done |
| `photo_video_music_talent` | Done | Done | 4 roles | Low (Portfolio) | Supported | Seeded | Done |
| `beauty_fashion_styling` | Done | Done | 4 roles | Low (Hygiene) | Supported | Seeded | Done |
| `construction_building` | Done | Done | 5 roles | High (Safety/Trade) | Supported | Seeded | Done |
| `energy_utilities` | Done | Done | 4 roles | High (Licence) | Supported | Seeded | Done |
| `transport_logistics` | Done | Done | 4 roles | High (PSV/Licence) | Supported | Seeded | Done |
| `machinery_equipment` | Done | Done | 4 roles | High (Operator/Log) | Supported | Seeded | Done |
| `agriculture_agribusiness` | Done | Done | 4 roles | Med (Vet/Tractor) | Supported | Seeded | Done |
| `specialized_products` | Done | Done | 3 roles | Med (Customs) | Supported | Seeded | Done |
| `travel_international` | Done | Done | 4 roles | Very High (Agency) | Supported | Seeded | Done |

### 5. Test Tracker
| Case | Scope | Status | Date |
|---|---|---|---|
| Baseline Provider test suite | `test/features/provider/capabilities_test.dart` | Passed | 2026-10-16 |
| Screen A card rendering & filters | Summary cards & tags | Passed | 2026-10-16 |
| Multi-capability persistence (6 items across 4 categories) | Bulk save RPC | Passed | 2026-10-16 |
| Capability independence (edit/remove Crane Hire leaves others intact) | Isolation | Passed | 2026-10-16 |
| Soft cap enforcement (31st rejected) | `max_provider_capabilities` | Passed | 2026-10-16 |
| Offer gating (unverified visa blocked, verified excavator allowed) | Central verification | Passed | 2026-10-16 |
| Prevent self-verification | Security triggers | Passed | 2026-10-16 |
| Role & kind matching (shared kind + qualification %) | `capability_match_score` | Passed | 2026-10-16 |
| Home & feed regression protection | Baselines diff | Passed | 2026-10-16 |
| L10n across 5 languages & RTL | Localization system | Passed | 2026-10-16 |
| Light and Dark theme adaptivity | Design tokens | Passed | 2026-10-16 |

### 6. Flag Tracker
| Setting Key | Default | Scope | Description |
|---|---|---|---|
| `capability_profiles_enabled` | `false` | Global | Kill switch for Provider Services v2 |
| `work_profiles_enabled` | `false` | Global | Toggles work role jobs switch & cards |
| `work_profiles_enabled_<slug>` | `false` | Category/Country | Per-category job enablement |
| `hire_person_needs_enabled` | `false` | Category/Country | Employer posting for hire-person |
| `max_provider_capabilities` | `30` | Global | Soft cap per user |
| `work_profile_requires_kyc` | `true` | Global | Approved KYC required for job match |

### 7. Verification Log
- 2026-10-16: P0 Plan created, reviewed against `.agents/AGENTS.md` and prompt requirements. Baseline `flutter analyze` run (33 info-level lints, 0 errors); baseline provider tests pass 20/20.
- 2026-10-16: SQL patch `sql/patch_provider_services_work_profiles.sql` created and verified. Fixed dollar-quote syntax (`$$`), adjusted `role_qualifications` column schema (`is_evidence`), and added `updated_at` column migration to `provider_capabilities` with self-contained `private.jsonb_text_array` helper.
- 2026-10-16: Presentation layer completed: Screen A unified summary (`_ScreenASummaryView`) with dynamic filter chips (`All`, `Services`, `Jobs`), user cards first, `_WorkProfileStrip`, and FAB `+ Add Service`.
- 2026-10-16: Modal sheets B, C, D, E, F, G implemented and connected with capability detail viewing, edit flow, pause/resume, and removal.
- 2026-10-16: SQL patch `sql/patch_provider_services_work_profiles.sql` aligned: removed non-existent `pc.updated_at` reference from `v_my_capability_status` view definition and `save_provider_capabilities`, ensuring full drop-in compatibility with production Supabase schema (`schema.sql:15635`).
- 2026-10-16: Fixed `setting_type_enum` in `system_settings` insert: updated `max_provider_capabilities` setting type from `'integer'` to canonical enum value `'number'`.
- 2026-10-16: `flutter test test/features/provider/capabilities_test.dart` passes 21/21 tests. `flutter analyze` verified clean with 0 errors and 0 warnings.


