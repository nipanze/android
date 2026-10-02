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

