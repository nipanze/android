# Nipanze README — Needs Layer Update + Implementation Guide

This file has two parts:

- **Part 1**: drop-in README edits, in the order they appear in your README.
- **Part 2**: how to implement it (database → Flutter → rollout).

The design rule throughout: **Loans and Forex stay exactly as they are.** The Needs layer is added beside them as a third module. It reuses the same auth, plans, trust, blocks, and contact-reveal machinery.

---

# PART 1 — README EDITS

## 1.1 Tagline + Overview (replace the first blockquote and the first Overview paragraph)

> Nipanze is a **need-first marketplace**. You say what you need — money, currency, a visa agent, an excavator, a specialist, a truck, a hard-to-find product — and people who can help make you offers. No bank, custodian, or intermediary ever holds your funds or currency. Live in Uganda first, built on one shared schema to expand across Kenya, Tanzania, Rwanda, Nigeria, South Africa, and Egypt.

Add to the end of the Overview section:

> **Jiji is inventory-first: "I have this, who wants it?" Nipanze is need-first: "I need this, who can help?"** Loans and Forex are the two financial modules. **Needs** is the third module and covers five non-financial categories where finding the right person is the hard part: Travel & International, Machinery & Equipment, Professional Services, Transport & Logistics, and Specialized Products & Procurement.

## 1.2 Replace "Two Projects, One Platform" with "Three Modules, One Platform"

| Shared (one platform) | Separate (three modules) |
|---|---|
| Auth, `profiles`, `subscription_plan`, `is_admin` | `loan_requests`/`loan_offers` · `forex_requests`/`forex_offers` · `needs_requests`/`need_offers` |
| `countries`, `currencies`, `system_settings` | `features/loans/` · `features/forex/` · `features/needs/` |
| Trust & reputation (`trust_aggregates`, `reviews`) | Card design: funded-% bar · Send/Rate/Receive panel · Need card (category + offers) |
| Selective transparency pattern (RLS + RPC) | Create flow: loan terms · currency pair · category-driven need form |
| Contact reveal, blocks, watchlist, notifications, KYC, Admin | Per-module regulatory review per market |
| One Marketplace screen with a module filter | Per-module launch sequencing |

Why not one generic "request" table: a loan, a currency exchange, and a visa-assistance need have different shapes. Force-fitting them makes all three worse. Three tables and three forms, with everything else shared.

## 1.3 New section — "The Needs Layer" (insert after "The Unified Marketplace Model")

### The five launch categories

| | Category | Core problem it solves | Example need |
|---|---|---|---|
| ✈️ | **Travel & International** | Hard-to-vet agents for visas, tickets, Hajj/Umrah | "Sweden visa assistance, December, UGX 500k budget" |
| 🚜 | **Machinery & Equipment** | Expensive assets people need temporarily | "Excavator for 3 months, Wakiso" |
| 🧑‍💼 | **Professional Services** | Finding the right specialist | "Company registration help, Kampala" |
| 🚚 | **Transport & Logistics** | Specialized or heavy transport on short notice | "20 tonnes of cement, Kampala → Gulu" |
| 🔎 | **Specialized Products & Procurement** | Things that aren't easy to find | "50 Epson L3150 printers, delivered to Mbarara" |

Loans (💰) and Forex (💱) remain first-class markets alongside these, not sub-categories of Needs.

### How a Need works

```
1. POST     → Anyone posts a Need for free (category-driven form: what, where, when, budget)
2. OFFER    → Providers with a matching declared capability make offers (price, timeline, message) — locked on submit
3. REVIEW   → The requester compares offers plus each provider's trust signals
4. ACCEPT   → Requester accepts one offer; the others are rejected
5. UNLOCK   → Contact details are revealed only after acceptance
6. CONNECT  → Parties proceed off-platform. Nipanze never handles payment for goods or services
7. RATE     → One review per side, feeding the same global trust aggregate
```

### Provider capabilities (what you can help people with)

- **Multi-select, per capability.** Someone can provide *Visa Assistance* and *Excavator Hire* at the same time. Each capability is its own row (`provider_capabilities`), not a single "profession".
- **Offers require a matching capability.** You can only offer on a Need whose category you have declared a capability in. This stops "I provide everything" accounts.
- **Progressive verification, never trusted from onboarding alone:**

| Level | How earned | Shown as |
|---|---|---|
| 🟡 Self-declared | Ticked during onboarding or profile | "Offers Visa Assistance" |
| 📱 Phone verified | OTP (already in `profiles.phone_verified_at`) | + phone badge |
| 🪪 Identity verified | KYC approved (already in `kyc_verifications`) | + verified badge |
| 🟦 Provider verified | Admin review of capability-specific evidence (licence, fleet, portfolio) | "Verified Travel Provider" |
| ⭐ Earned | Completed connections + reviews | rating + completed count |

"Verified Provider" labels are only ever set by admin review. A user can never set their own verification level.

### Selective transparency for Needs (same tiers as Loans/Forex)

| Viewer | Sees |
|---|---|
| Anyone browsing | Need summary, budget, location, number of offers, coverage tier. Never individual offer terms |
| Provider who has **not** offered | Same as anyone browsing |
| Provider who **has** offered | Above, plus exact terms of competing offers (anonymized) |
| Requester | Every offer in full, plus each provider's trust signals |

Contact details stay locked for everyone until the requester accepts and unlocks.

### Non-custodial boundary for Needs

Nipanze does **not** hold payment for goods or services, run escrow, verify that a service was delivered, guarantee quality, or act as a travel agent, visa agent, equipment dealer, or carrier. It matches needs with offers and controls contact sharing.

## 1.4 New section — "Personalization: Intent-Based Onboarding & Home" (insert after Needs Layer)

### Onboarding asks two separate questions

No "Are you a provider or a visitor?" step. Those are system concepts, not identities.

1. **What brings you to Nipanze?** *(multi-select, max 3 as top interests)*: Money/financing · Currency exchange · Travel/Visa · Machinery/Equipment · Professional services · Transport/Logistics · Hard-to-find products · Something else
2. **Is there anything you can help people with?** *(optional, multi-select, skippable)*: capability picker grouped by category. Each tick becomes a self-declared `provider_capabilities` row.

Both answers are editable any time under **Account → Your Nipanze**.

### Interest profile: explicit + learned

| Signal | Source |
|---|---|
| Explicit | Onboarding picks, categories followed, categories muted |
| Behavioral | Needs opened, saved to watchlist, needs posted, offers made (`user_interest_events`, last 30 days) |
| Outcome | Accepted offers, completed connections, reviews |

Feed ranking = explicit weight + recent behavior. Muted categories are excluded outright.

### Home vs Markets

| | **Home** | **Markets** |
|---|---|---|
| Question it answers | "What might be useful to *me*?" | "Show me the marketplace" |
| Content | Greeting, search, **For You** (ranked), your interests (editable), saved items, **Provider Opportunities** (needs matching what you provide), explore-by-category | Full feed with filter row `For You · All · Loans · Forex · Needs`, category chips, country scope |
| Personalized | Yes | Only the `For You` tab |

**Provider Opportunities** appears on Home only if the user has at least one active capability: "People are looking for what you provide: 3 Travel, 2 Machinery." One account, both experiences, no separate provider mode.

### Suggested bottom navigation (proposal — changes current nav)

Current: `Markets · Watchlist · Request · Activity · Account`
Proposed: **`Home · Markets · ➕ Post · Activity · Account`**

- The ➕ Post FAB opens a chooser: **Loan · Forex · Need**.
- Watchlist moves to a "Saved" row on Home, and stays reachable from Account.
- If you'd rather not touch the nav yet, ship Home as the first tab and keep the rest unchanged.

## 1.5 Edits to existing sections

**Feature access by plan** — add to each row:

| Plan | Add this |
|---|---|
| 🟢 Free | Post unlimited-per-plan-limit Needs · browse all Needs · accept offers received · make a small number of Need offers per month if you hold a matching capability (default **3/month**, admin-configurable via `system_settings.needs_free_offers_per_month`) |
| 🔵 Lender | Unlimited Need offers for capabilities you hold |
| 🟣 Pro | Above + priority placement for your Needs and offers, "Provider verified" review fast-track |

> **Open decision:** the plan is called "Lender" but now unlocks offers for a visa agent or truck owner. Either rename it (e.g. "Offers") or keep the internal enum value `lender` and change only the display label. Not blocking; the schema keeps `subscription_plan_enum` unchanged.

**Marketplace Feed & Listing Design** — filter row becomes `For You · All · Loans · Forex · Needs`. Add a card spec:

### Need listing card
- **Badge:** category icon + name (e.g. `✈️ Travel & International`)
- **Meta line:** location · timeline (e.g. "Kampala · December")
- **Title** (what is needed) and **budget** (in the listing's currency, or "Open to offers")
- **One-line summary**
- **Offer count** (e.g. "3 offers") and **"Xd left"** countdown
- **Trust badges:** requester `⭐ No reviews yet` / `💎 0 completed`; `✓ Verified requester` when KYC approved
- **Star icon:** save to watchlist

**Regulatory Compliance** — add: *Needs categories carry their own sector rules. Travel and immigration assistance, Hajj/Umrah operators, freight, and professional services (legal, accounting, engineering) are licensed or regulated in many markets. Nipanze matches; it does not vouch for a provider's licence unless the "Provider verified" badge, granted after admin review, says so. Every market needs a per-category review before that category is enabled there.*

**Project Structure** — add:

```
features/
├── home/            # Personalized Home: For You, interests, provider opportunities
├── needs/           # 🟠 NEEDS PROJECT — create need, need detail, my needs, need offers
├── interests/       # Interest picker, follow/mute, behavior event recording
└── provider/        # Capability picker, "Your services", verification status
shared/widgets/      # + NeedCard, CategoryChip, CapabilityBadge, ProviderVerificationChip
```

**Screen / Route Map** — add:

| Route | Screen | Auth |
|---|---|---|
| `/home` | HomePage (personalized) | Yes |
| `/needs/create` | NeedCreatePage (category-driven form) | Yes (Free+) |
| `/needs/:requestId` | NeedDetailPage + offers | Yes |
| `/needs/my-needs` | MyNeedsPage | Yes |
| `/onboarding/interests` | InterestsStep | Yes |
| `/onboarding/capabilities` | CapabilitiesStep | Yes |
| `/account/services` | ProviderServicesPage | Yes |
| `/account/interests` | EditInterestsPage | Yes |

**Database Schema tables** — add:

| Table | Purpose |
|---|---|
| `need_categories` | The five categories (slug, name, icon, sort, `is_active`) |
| `need_capabilities` | Sub-capabilities per category (e.g. `visa_assistance`, `excavator_hire`) |
| `needs_requests` *(extended)* | Existing table plus `category_slug`, `capability_slug`, `details` (JSONB, category-specific fields), `number_of_offers`, `expires_at`, status lifecycle |
| `need_offers` | Provider offers: price, timeline, message. Locked on submit. No `country` column (read via `need_id`) |
| `need_contact_reveals` | Post-acceptance contact sharing for needs |
| `provider_capabilities` | Per-user declared capabilities plus `verification_level` (admin-controlled) |
| `user_interests` | Explicit interests / mutes |
| `user_interest_events` | Behavioral signals for ranking |

**Key functions/views** — add: `v_needs_listings` (rebuilt, adds coverage tier + trust), `get_public_need_offers(need_id)`, `accept_need_offer(need_id, offer_id)`, `unlock_need_contact(offer_id)`, `get_for_you_needs(country, limit)`, `get_provider_opportunities(limit)`, `record_interest_event(category, event)`.

**Roadmap** — add after Stage 4.7:

### Stage 4.8 — Needs Layer & Provider Services ✅ Implemented
- Needs categories + capabilities, extended `needs_requests`, `need_offers`, contact reveal, provider capabilities with progressive verification
- Intent-based onboarding, personalized Home, `For You` ranking, provider opportunities
- Per-category, per-market enablement flag (`need_categories.is_active` plus a country override in `system_settings`)

**Recent Updates** — add a dated entry summarizing: Needs module, five categories, onboarding intent step, Home vs Markets split, capability-gated offers, and the privacy fix on `needs_requests` (below).

---

# PART 2 — HOW TO IMPLEMENT

## 2.0 What already exists (build on it, don't redo it)

Your repo already has `needs_requests`, `v_needs_listings`, ~110 sample rows, and an insert/update policy for posting. The new work extends that table instead of replacing it. Two problems in the current patch need fixing first:

1. **`requester_id` is publicly readable.** The current patch grants `select` on the base table to `anon` with an "active rows" policy, which exposes the poster's UUID. That breaks the platform's masking rule. The SQL patch moves public reads to the view (which excludes it) and restricts the base table to the owner.
2. **`budget` is `integer`.** It overflows at ~2.1B, which is a realistic value for machinery in NGN or UGX. The patch widens it to `bigint`.

The existing sample rows use free-text categories (`'Home & Energy'`, `'Business Equipment'`…). The patch backfills `category_slug` from them with a best-guess map. Review that map, since most sample rows land in "Specialized Products".

## 2.1 Phase 1 — Database (run `patch_needs_layer.sql`)

Run order: the patch is idempotent and assumes `schema.sql` + `patch.sql` are already applied. It creates:

- Reference tables with the five categories and starter capabilities
- Extended `needs_requests` (category, details JSONB, offer count, expiry)
- `need_offers` with validation trigger (must be active, not self, must hold a matching capability, free-tier monthly cap)
- `provider_capabilities` with a trigger that forces `verification_level = 'self_declared'` unless the writer is an admin
- `user_interests`, `user_interest_events`
- RPCs: accept, unlock, public offer book, For You, provider opportunities, record event
- RLS on everything new; rebuilt `v_needs_listings`

Then verify:

```sql
select slug, is_active from need_categories order by sort_order;
select category_slug, count(*) from needs_requests group by 1;
-- as anon, this must fail or return zero rows:
select requester_id from needs_requests limit 1;
```

## 2.2 Phase 2 — Flutter data layer

```
lib/features/needs/
├── data/
│   ├── models/         need_listing_model.dart, need_offer_model.dart, need_category_model.dart
│   └── datasources/    needs_remote_ds.dart   // v_needs_listings, need_offers, RPCs
├── domain/
│   ├── entities/       need_listing.dart, need_offer.dart
│   └── repositories/   needs_repository.dart
└── presentation/
    ├── bloc/           needs_feed_cubit.dart, need_create_cubit.dart, need_detail_cubit.dart
    └── pages/          need_create_page.dart, need_detail_page.dart, my_needs_page.dart
lib/features/home/       home_cubit.dart, home_page.dart
lib/features/interests/  interests_cubit.dart, interests_repository.dart
lib/features/provider/   capabilities_cubit.dart, provider_repository.dart
```

Add constants in `core/constants`: `Tables.needRequests`, `Tables.needOffers`, `Views.needsListings`, `Rpcs.getForYouNeeds`, `Rpcs.acceptNeedOffer`, `Rpcs.unlockNeedContact`, `Rpcs.getProviderOpportunities`, `Rpcs.recordInterestEvent`.

**Category-driven create form.** Store category-specific fields in `details` JSONB and drive the form from a small per-category field config, so adding a field never needs a migration:

```dart
const needFormSchema = {
  'travel_international': [Field.text('destination'), Field.date('travel_date'), Field.int('travellers')],
  'machinery_equipment':  [Field.text('equipment_type'), Field.int('duration_days'), Field.bool('operator_needed')],
  'transport_logistics':  [Field.text('from'), Field.text('to'), Field.text('load_description')],
  // …
};
```

Keep `title`, `specification`, `budget`, `currency`, `location`, `country`, `urgency` as real columns. They are what the feed sorts and filters on.

## 2.3 Phase 3 — Marketplace integration

1. Extend `MarketplaceCubit` module filter enum: `forYou | all | loans | forex | needs`.
2. `needs` → query `v_needs_listings` with the same `country` scoping used for loans/forex.
3. `forYou` → call `get_for_you_needs`.
4. `all` → merge loans + forex + needs by `listed_at` (as you already do for loans + forex). Cap each source to avoid one module drowning the rest.
5. Add `NeedCard` and render it from the same list widget.
6. On card open / save / post / offer, call `record_interest_event` (fire-and-forget; never block the UI on it).

## 2.4 Phase 4 — Onboarding + Home

1. Add two steps after signup: `InterestsStep` (required, pick up to 3) and `CapabilitiesStep` (optional, skippable). Write `user_interests` and `provider_capabilities` rows.
2. Route guard: users with no `user_interests` rows are sent to `/onboarding/interests` once.
3. `HomePage` sections, each hidden when empty: greeting + search → For You (top 5) → Your interests (chips, edit) → Saved → Provider Opportunities (only if user has capabilities) → Explore by category.
4. Make Home the first tab. Only then decide on the nav change in 1.4.

## 2.5 Phase 5 — Provider trust

- Add `ProviderVerificationChip` reading `provider_capabilities.verification_level` plus existing phone/KYC status.
- Admin portal: a "Provider capabilities" queue (filter `self_declared`, approve → set `provider_verified`). Only admin can set the level, and the DB trigger enforces it.
- Reviews: add `need_deal_id` to `reviews` (same nullable-sibling pattern used for `forex_contract_id`) and extend `recompute_trust_aggregates` to count completed needs deals, so trust stays one global score across all three modules. *(Not included in the SQL patch; do it as a follow-up once needs deals exist.)*

## 2.6 Rollout order (smallest safe steps)

| Step | Ship | Risk |
|---|---|---|
| 1 | SQL patch + privacy fix | Low — no UI change |
| 2 | Needs tab in Markets (browse + post) using existing posting | Low |
| 3 | Offers + accept + unlock | Medium — new money-adjacent trust flow |
| 4 | Capabilities + capability-gated offers | Medium |
| 5 | Onboarding interests + Home + For You | Medium — changes first-run |
| 6 | Verification queue + badges | Low |
| 7 | Enable categories per market | Regulatory — gate each one |

Launch with **Machinery, Professional Services, Transport, Products** first. Enable **Travel & International** last and only for verified providers, since visa/Hajj fraud is the highest-harm category.

## 2.7 Tests to write

- Anon cannot read `requester_id` from `needs_requests`.
- A user without a capability in the category cannot offer (`P0203`).
- Free user's 4th offer in a month is rejected; Lender's is not.
- Non-participant sees only count + tier; offer-maker sees competing terms anonymized; owner sees all.
- Accepting one offer rejects the others and sets the need `matched`.
- A user cannot change their own `verification_level`.
- Muted category never appears in `get_for_you_needs`.
- Blocked user cannot see or offer on the blocker's needs.

## 2.8 Things to decide before Step 3

1. **Plan naming/gating for offers** (see 1.5).
2. **Do Needs need a locked agreement?** The patch skips agreements (accept → reveal only), since a visa or transport job doesn't have loan-style terms. If you want a locked record, add `need_agreements` mirroring `forex_agreements`.
3. **Contact-unlock fee:** still an open decision in your schema. If adopted, it applies to Needs too.
4. **Provider licence evidence** per category (what admin checks before "Provider verified").

---

# PART 3 — CENTRAL VERIFICATION & ACTIVITY SYSTEM

## 3.1 Central Platform-Level Verification (Extended KYC)

Identity verification is the central security and trust gate for the entire marketplace across all modules (Loans, Forex, Needs, Offers, and Provider Services).

- **Identity Verified (`profiles.kyc_status = 'approved'` / `kyc_verifications`)**:
  - Global pre-requisite for posting or making offers.
  - An unverified user can browse, search, view listings, save watchlist items, and view public profiles.
  - An unverified user **cannot** post Loan/Forex/Need requests, make Loan/Forex/Need offers, create service capabilities, accept offers, or unlock contact details.
- **Provider Verified (`provider_capabilities.verification_level = 'provider_verified'`)**:
  - Capability/category-specific verification based on administrative review of submitted evidence (licenses, certifications, fleet records).
  - Identity verification does not automatically grant provider verification.

## 3.2 Hierarchical Verification Requirements Engine

Verification rules are stored dynamically in `verification_requirements` and evaluated hierarchically:
`Capability Level` -> `Category Level` -> `Activity Level` -> `Global Level` (most specific rule applies).

- **Database Enforcement**: Server-side triggers and RPC guards enforce rules (`private.require_identity_verified`, `can_perform_marketplace_activity`).
- **Flutter Interception**: `VerificationGateModal.checkAndGate` intercepts posting and offer actions before forms open, prompting users to verify and returning them to their intended flow upon completion.

## 3.3 Activity Navigation Update

- Navigation bar, routes, tabs, and user-facing terminology transitioned from **Positions** to **Activity** (`AppRoutes.activity`, `navActivity`).

## 3.4 Standalone Database Migration

- `sql/patch_central_verification_system.sql`: Contains the complete standalone schema, RLS policies, trigger guards on requests/offers/capabilities/unlocks, and admin RPCs.