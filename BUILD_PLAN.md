# BUILD_PLAN.md — Nipanze

> **Flutter + Supabase** · Digital loan & forex listing matchmaking marketplace — launching in Uganda, expanding across Africa
> Last updated: July 2026 · Schema v6.0 · Seed v2.1 (Uganda-only until Stage 4.5 migration is applied; forex seed data lands with Stage 4.7)

> **⚡ v4.1 Architecture Change:** Nipanze moved from a **role-based** model (borrower / lender) to a **unified, subscription-based, action-based** model. See "Unified Marketplace Model" below.
>
> **⚡ v4.1 Stage 4 additions:** Listing detail visibility is **tiered, not binary** ("Selective Transparency Model"), and a public **Trust & Reputation System** is planned, deliberately kept separate from transparency.
>
> **⚡ v5.0 → v6.0 Architecture Change (superseded, see below):** Nipanze originally planned a single-country → East African Community (EAC) multi-country expansion (Kenya, Tanzania, Rwanda, Burundi, South Sudan, DR Congo, Somalia). **This has been superseded by a broader seven-market plan** — see "Multi-Market Expansion Model" below. Burundi, South Sudan, DR Congo, and Somalia are no longer part of the current roadmap; Nigeria, South Africa, and Egypt have been added.
>
> **⚡ v5.1 → v6.0 Architecture Change:** Nipanze runs **Loans and Forex as two feature-modules on one shared app and one shared Supabase project** — not two products, not two accounts. See "Two Projects, One Platform" below, which now frames the relationship between the two modules more explicitly than the earlier "second request type" framing did.
>
> **⚡ v6.0 Architecture Change:** Currency handling is generalized beyond "one country, one currency." A new `currencies` reference table, decoupled from `countries`, resolves three previously-open questions: loans denominated in USD, subscriptions billed in USD, and which currencies (if any) may appear in a forex pair. See "Currencies — Local, Cross-Border, and USD" below before touching schema, RLS, or seed files.
>
> This layers on top of, and does not replace, the v4.1 changes already documented above: the **Unified Marketplace Model**, the **Selective Transparency Model**, and the **Trust & Reputation System** all still apply unmodified — v6.0 changes *which markets* and *which currencies* the platform serves, and formalizes the *module* boundary between Loans and Forex, without touching how plans, transparency, or trust work.

---

## Stage Map

| Stage | Title | Status |
|---|---|---|
| 1 | Foundation | ✅ Complete |
| 2 | Core Marketplace | ✅ Complete |
| 3 | Polish & Supporting Features | ✅ Complete |
| 3.5 | Cloud Migration & Auth Hardening | ✅ Complete |
| 4 | Structured Deal Agreement, Contact Sharing & Trust System | ⬜ Planned |
| 4.5 | Multi-Market Expansion | ⬜ Planned |
| 4.7 | Forex Marketplace Expansion | ⬜ Planned |
| 5 | Admin & Compliance | ⬜ Planned |
| 6 | Launch & Growth | ⬜ Planned |

> Stage 4.5 is a data-model and RLS change, not a UI feature — it doesn't block Stage 4's contract/trust work and vice versa. Stage 4.7 lands **after** Stage 4.5 (needs `countries`/`currencies` plumbing) and reuses Stage 4's selective-transparency and trust-system machinery directly. Recommended order: Stage 4.5 → Stage 4 → Stage 4.7, though Stage 4.7's schema work can start once Stage 4.5 is done even if Stage 4 UI work is still in flight.

---

## 🧩 Two Projects, One Platform (v6.0 — governs the Loans/Forex module boundary)

### The decision

Nipanze ships **Loans** and **Forex** as two feature-modules on one shared foundation, not as two products and not as one blended feature. This section makes that boundary explicit, since earlier drafts of this plan treated forex as "a second request type" without naming the module split directly — the practical shape is the same, but this framing is now the source of truth for what's shared vs. separate.

| Layer | Shared or Separate |
|---|---|
| Auth, `profiles`, `subscription_plan`, `is_admin` | **Shared** |
| `countries`, `currencies`, `system_settings` | **Shared** |
| Trust & reputation (`trust_aggregates`, `reviews`, `recompute_trust_aggregates`) | **Shared** |
| Selective transparency *pattern* (tiered visibility, participant-gated detail) | **Shared pattern**, separate implementation per module |
| Contracts, contact reveal (`accept_offer`, `reveal_contact`) | **Shared RPCs**, branch on `request_type` only for document wording |
| Watchlist, Positions, Notifications, KYC, Admin dashboard shell | **Shared** |
| `loan_requests` / `loan_offers` | **Separate** — Loans project |
| `forex_requests` / `forex_offers` | **Separate** — Forex project |
| `features/loans/` Flutter module | **Separate** |
| `features/forex/` Flutter module | **Separate** |
| Listing-card design | **Separate** — funded-% progress bar (Loans) vs. Send/Rate/Receive panel (Forex) |
| Create-request form | **Separate** — loan terms vs. currency pair + rate |
| Per-module regulatory gating | **Separate** — `countries.is_active` (Loans) vs. `countries.forex_enabled` (Forex), independently toggled per market |
| Per-module launch sequencing | **Separate** — a market can go live for Loans before Forex, or in principle vice versa |

### Why this split

**Not full separation** (two apps, two backends): a request owner and an offer-maker shouldn't need two accounts or two logins to do two closely related things — post a need, get offers, agree terms, get introduced. Auth, trust, contracts, and contact-reveal would otherwise be built and maintained twice for no product benefit, and a user's reputation would fragment across two silos instead of reflecting their real, combined track record.

**Not full blending** (one generic "request" table, one generic listing card): a loan and a currency exchange are different enough in shape — loan terms vs. exchange rate, funded-% progress vs. Send/Rate/Receive, income-source fields vs. settlement-preference fields — that forcing them into one schema and one card design would compromise both. A loan-shaped table with nullable forex columns bolted on (or vice versa) becomes unreadable within a year.

**The middle path** — two tables, two forms, two card layouts, one everything else — is what's specified throughout this document and mirrored directly in the marketplace mockup: one Marketplace screen, one `All / Loans / Forex` filter row, one bottom nav, two structurally different card types underneath.

### Practical implication for engineering planning

Treat `features/loans/` and `features/forex/` as **separate epics with separate exit criteria** (see Stage 4 vs. Stage 4.7 below) that can be staffed, tested, and shipped somewhat independently, while `features/marketplace/`, `features/positions/`, `features/trust/`, and `features/watchlist/` are **shared surfaces** that must be updated whenever either project adds a new field that needs to render. This is the practical meaning of "loans is a project and forex is a project" in day-to-day planning: two backlogs, one integration surface.

---

## 🧠 Unified Marketplace Model (v4.1 — supersedes role-based framing)

### The decision

- ✅ One interface for every user — no separate borrower/lender screens
- ✅ No "borrower vs lender" role stored on the account
- ✅ Users choose a **subscription plan**, not a role
- ✅ The same person can post a request *and* make offers, any time, with the same login, in either the Loans project or the Forex project

### Mental model shift

| Old model | New model |
|---|---|
| "User *is* a borrower or a lender" | "User *performs* borrower or lender actions depending on what they click" |
| Role determines what's visible | Subscription plan determines what's clickable |
| Separate flows/screens per role | One dashboard, one marketplace, action buttons gated by plan |

### How it behaves

**Single entry point after login** — every user lands on the same dashboard:

1. **📢 Marketplace** — all loan and forex listings, filterable `All / Loans / Forex`
2. **➕ Post Request** — always visible from Free tier upward, request type chosen inside the flow
3. **💼 Offers Panel** — shows offers *received* on your requests, and (if your plan allows) offers *you've made* on others' requests, across both projects

There is no "select your role" step at signup or login, and no "select loan or forex" step at signup either — that choice happens per-post. A user simply acts:

- Clicks **"Post Request"** → picks Loan or Forex → acting as a borrower/requester for that listing
- Clicks **"Make Offer"** → acting as a lender/offer-maker for that listing

### Feature access by plan

| Plan | Access |
|---|---|
| 🟢 **Free** | Post basic loan requests (amount, duration, purpose) or forex requests (currency pair, amount) · Browse marketplace · Accept received offers · Watchlist, Positions, Notifications, KYC · Full visibility into public trust signals on every profile · ❌ Cannot make offers · ❌ Cannot suggest terms when posting |
| 🔵 **Lender Plan** | Everything in Free, **plus**: Make offers on any listing, loan or forex · Set interest rate, late payment fee, repayment schedule on loan offers · Set exchange rate, available amount, terms on forex offers |
| 🟣 **Pro** | Everything in Lender, **plus**: Suggest terms when posting a request — interest rate, late fee, repayment schedule for loans, or a preferred exchange rate for forex · Priority visibility for posted requests · Improved matching · Verified badge · Advanced trust insights |

> No plan is ever labeled "Borrower Plan," "Lender-only," or "Forex Plan." The plan name describes the *unlocked capability*, not the person or the project.

### Feature gating logic

```
IF subscription_plan == "free"
  disable "Make Offer"                              # loan or forex
  disable term-suggestion fields on Post Request     # interest/late fee/schedule, or preferred rate

IF subscription_plan == "lender"
  enable "Make Offer"                                # loan or forex
  enable lender term fields on loan offers (interest, late fee, schedule)
  enable lender term fields on forex offers (rate, amount, terms)
  keep term-suggestion fields on Post Request disabled

IF subscription_plan == "pro"
  enable everything above
  enable term-suggestion fields on Post Request      # loan terms or forex preferred rate
  enable priority visibility / improved matching
  enable Verified badge display + advanced trust insights view
```

### What this removes from the data model

- ❌ `role` column (`borrower` / `lender` / `both`) — **no longer needed**
- ❌ Role-based RLS branching — **replaced with plan-based checks**
- ❌ Any notion of a "forex account" separate from a "lending account" — **never introduced**

### What this replaces it with

```sql
-- users / profiles table (conceptual)
id
email
subscription_plan   -- 'free' | 'lender' | 'pro'
is_admin            -- boolean, unaffected by this change
phone_verified_at   -- nullable timestamp, drives the free "phone verified" trust badge
```

`is_admin` is the **one exception** — admin remains a true role, separate from the subscription plan, since it governs platform moderation rather than marketplace participation.

---

## 🔍 Selective Transparency Model (v4.1 — governs listing detail visibility)

Stage 2 shipped a fully public offer book. Stage 4 replaces that with **tiered visibility**, keyed off participation. Stage 4.7 applies the identical model, unmodified, to forex listings.

### Visibility tiers

| Viewer | Sees on listing detail |
|---|---|
| **Visitor / any logged-in user, not yet bid** | Loan: funded % progress bar, `number_of_offers`, `offer_coverage_tier`, full request summary, request-owner trust badges. Forex: currency pair, `number_of_offers`, `rate_coverage_tier`, full request summary, request-owner trust badges |
| **Lender/Pro-plan holder browsing, has not offered on *this* listing** | Same as a visitor — plan alone does not unlock offer detail; placing an offer does |
| **Offer-maker who has placed an offer on this listing** | Everything above, **plus** exact terms for every offer on this listing, plus public trust badges for each competing offer-maker |
| **Request owner** | Full detail on every offer received, plus each offer-maker's public trust badges (and, if the owner is Pro, advanced trust insights) |

Contact details are a separate boundary and stay locked for **everyone**, at every tier, until contract generation + unlock. Public trust badges are a third, independent boundary, visible at every tier regardless of participation.

### Gating logic

```
listing = get_listing(request_id)

IF viewer == listing.owner
  return full_offer_detail(all offers on this request)

ELSE IF viewer has an offer on this request
  return full_offer_detail(all offers on this request)   -- includes viewer's own offer

ELSE
  return {
    number_of_offers: count(offers),
    coverage_tier: compute_tier(offers)   -- offer_coverage_tier (loan) or rate_coverage_tier (forex)
  }
```

This lives in `get_public_listing_offers(request_id)` / `get_public_forex_offers(request_id)` and the `v_lender_offers` / `v_forex_offers` views (RLS-scoped), **not** in the Flutter client.

### Data model impact

- `v_loan_listings` gains `offer_coverage_tier`; `v_lender_offers` becomes participant-scoped via `security_invoker` + RLS
- `v_forex_listings` gains the analogous `rate_coverage_tier`; `v_forex_offers` follows the identical participant-scoping pattern
- Both `get_public_listing_offers` and `get_public_forex_offers` branch on caller identity (owner / participant / neither) so RPC callers can't bypass the tiering the UI enforces

---

## 🌟 Trust & Reputation System (v4.1 — governs counterparty credibility, separate from deal-term visibility)

### The decision

- ✅ Baseline trust signals (rating, review count, completed-deal count, repeat-participant badge, phone-verified badge, response-time bucket) are **public to every user on every plan** — never gated
- ✅ Pro-tier adds **verification weight** (KYC-based "Verified" badge) and **analytical depth** (success rate, reliability score) on top of the same public data
- ❌ Trust signals never claim to measure off-platform repayment or currency-settlement behavior

### What's public (Free — every profile, every plan)

| Signal | Computed from | Rendered as |
|---|---|---|
| ⭐ Rating average + review count | `reviews` table, one review per completed contract per direction, loan or forex | "⭐ 4.7 (18 reviews)" or "⭐ No reviews yet" at zero-state |
| 📊 Completed deals count | Count of `contracts` the account has been a party to, loan and forex combined | "📊 9 successful deals" or "💎 0 completed" at zero-state |
| 🔁 Repeat participant badge | Second completed contract onward, loan or forex | "🔁 Repeat Borrower" / "🔁 Repeat Lender" |
| 📱 Phone verified badge | `profiles.phone_verified_at` set at OTP verification | "📱 Phone verified" |
| ⏱️ Typical response time | Rolling median time-to-first-action, bucketed | "⏱️ Responds quickly" |

> **Zero-state rendering matters for the marketplace UI:** a freshly-posted listing with no history shows `⭐ No reviews yet` and `💎 0 completed` in the same badge positions a seasoned listing would use — these are not hidden or replaced with blank space, since a visible zero-state is itself informative (this is a new, unproven listing) and keeps the card layout consistent across every listing's lifecycle. See "Marketplace UI Specification" below.

### What's monetized (Pro tier)

| Enhancement | Description |
|---|---|
| 🟦 Verified badge | Full KYC review, stronger than the free phone-verified badge |
| 📊 Success rate | Share of offers accepted / requests reaching contract, loan and forex combined |
| 🔍 Reliability score | Derived score combining rating, completion count, response time |
| 🚀 Priority visibility | Pro-posted requests and Pro offer-maker profiles get improved placement, loan or forex |

### Reviews

- Left only by the counterparty on a **completed contract**, loan or forex — one review per contract, per direction
- 1–5 star rating plus optional short text, immutable once submitted, logged to `audit_logs`
- `submit_review(contract_id, rating, comment)` RPC validates server-side that the caller was a party to that contract, and triggers `recompute_trust_aggregates(user_id)` afterward — regardless of whether the contract originated from Loans or Forex

### Data model impact

- `reviews` table: `id`, `contract_id`, `reviewer_id`, `reviewee_id`, `rating`, `comment`, `created_at` — unique on `(contract_id, reviewer_id)`
- `profiles.phone_verified_at` (nullable timestamp)
- `trust_aggregates` (or cached columns): `rating_avg`, `review_count`, `completed_deals_count`, `is_repeat_participant`, `response_time_bucket` per user, refreshed by `recompute_trust_aggregates(user_id)` — sourced from contracts regardless of `request_type`
- `v_trust_profile_public` / `v_trust_profile_pro` views

---

## 🌍 Multi-Market Expansion Model (v6.0 — supersedes the earlier EAC-only plan)

### What changed from the earlier plan

An earlier version of this document scoped expansion to the eight East African Community (EAC) member states. **That plan is superseded.** The current roadmap targets **seven markets across three African regions**, in this launch order:

| # | Country | ISO Code | Currency | Currency Code | Phone Prefix | Region |
|---|---|---|---|---|---|---|
| 1 | 🇺🇬 Uganda | `UG` | Ugandan Shilling | `UGX` | `+256` | East Africa — **launch market** |
| 2 | 🇰🇪 Kenya | `KE` | Kenyan Shilling | `KES` | `+254` | East Africa |
| 3 | 🇹🇿 Tanzania | `TZ` | Tanzanian Shilling | `TZS` | `+255` | East Africa |
| 4 | 🇷🇼 Rwanda | `RW` | Rwandan Franc | `RWF` | `+250` | East Africa |
| 5 | 🇳🇬 Nigeria | `NG` | Nigerian Naira | `NGN` | `+234` | West Africa |
| 6 | 🇿🇦 South Africa | `ZA` | South African Rand | `ZAR` | `+27` | Southern Africa |
| 7 | 🇪🇬 Egypt | `EG` | Egyptian Pound | `EGP` | `+20` | North Africa |

**Burundi, South Sudan, DR Congo, and Somalia are no longer part of the current roadmap.** The schema pattern below still supports adding any country later the same way any new market is added (one `countries` row insert), so nothing here is a dead end if priorities shift back — but seed files, test accounts, and the per-market launch checklist below should target this seven-market list, not the earlier eight-state EAC list.

### The decision (unchanged in mechanism, changed in scope)

- ✅ **One database, one set of tables, shared across every market** — `profiles`, `loan_requests`, `loan_offers`, `forex_requests`, `forex_offers`, `watchlist`, `reviews`, etc. all stay as single tables
- ✅ Every row that represents a person or a listing carries a `country` code
- ✅ `countries` reference table holds display name, currency code, phone prefix, `is_active` (lending gate), and `forex_enabled` (independent forex gate) per market
- ❌ **No per-country tables**, **no per-country Supabase projects** — rejected for the same reasons as before: N× the RLS/trigger/view/RPC maintenance surface, UNION-query admin reporting, migration-per-market instead of row-insert-per-market

### Why regulatory diversity is a bigger deal now than it was under EAC-only

The earlier EAC-only plan could reasonably treat "confirm payment-rail coverage per market" as the main per-market variable, since all eight EAC states shared a regional bloc and broadly similar mobile-money-dominant payment landscapes. **This seven-market list cannot be treated the same way.** Nigeria, South Africa, and Egypt each sit in materially different regulatory and payments environments from East Africa and from each other:

- **Nigeria** — card, bank-transfer, and fintech-native rails (Flutterwave and Paystack both originate here) are mature, arguably more so than East Africa's; but Nigeria's fintech and lending regulatory environment (CBN oversight) is its own distinct landscape to review, independent of East African findings
- **South Africa** — mature card/EFT banking penetration, different mobile-money reliance than East Africa; its own financial-services regulatory regime (FSCA) to review independently
- **Egypt** — a currency-control history around the EGP that specifically warrants extra scrutiny for the *Forex* module (see Stage 4.7 below), separate from whatever review Loans needs there

**This document is not legal advice and does not assert specific licensing conclusions for any of these markets.** The operating principle carried over from the EAC plan — never assume one market's clearance implies another's — applies with more force here, given how different these three markets are from the four East African ones and from each other. See [Regulatory Compliance] in the README and the per-market Stage 6 checklist below.

### Country as a first-class, indexed column — not a derived guess

`country` is stored explicitly on `profiles`, `loan_requests`, and (Stage 4.7) `forex_requests`. It is **not** re-derived per-query from phone prefix or IP — those are only used as a *default suggestion* at signup:

| Signal | Role |
|---|---|
| `profiles.country` | Source of truth once set. Required, not nullable, after onboarding completes. |
| Phone prefix (`+256`→UG, `+254`→KE, `+255`→TZ, `+250`→RW, `+234`→NG, `+27`→ZA, `+20`→EG) | Onboarding-time **default suggestion** only — user can override before confirming |
| GPS / IP geolocation | Optional, same role as phone prefix — a suggestion, never silently trusted |
| `loan_requests.country` / `forex_requests.country` | Copied from `profiles.country` **at creation time**, via trigger, then locked |

### `loan_offers` and `forex_offers` inherit country from their request — never stored independently

An offer's country is entirely determined by the request it's offering on. Storing it a second time on the offer row creates a value that can drift from its source of truth for no benefit. This rule applies identically to both modules.

### New table: `countries`

```sql
-- countries (conceptual)
code            TEXT PRIMARY KEY   -- ISO 3166-1 alpha-2
name            TEXT NOT NULL
currency_code   TEXT NOT NULL REFERENCES currencies(code)
phone_prefix    TEXT NOT NULL      -- onboarding suggestion only, never enforced
is_active       BOOLEAN NOT NULL DEFAULT FALSE  -- gates lending specifically
forex_enabled   BOOLEAN NOT NULL DEFAULT FALSE  -- gates forex specifically, independent of is_active
created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP

-- seed: 7 markets, seeded together, activated independently
-- ('UG', 'Uganda',       'UGX', '+256', TRUE,  FALSE)   -- lending live at migration time; forex reviewed separately (Stage 4.7)
-- ('KE', 'Kenya',        'KES', '+254', FALSE, FALSE)
-- ('TZ', 'Tanzania',     'TZS', '+255', FALSE, FALSE)
-- ('RW', 'Rwanda',       'RWF', '+250', FALSE, FALSE)
-- ('NG', 'Nigeria',      'NGN', '+234', FALSE, FALSE)
-- ('ZA', 'South Africa', 'ZAR', '+27',  FALSE, FALSE)
-- ('EG', 'Egypt',        'EGP', '+20',  FALSE, FALSE)
```

Launching lending in a new market: `UPDATE countries SET is_active = TRUE WHERE code = 'KE'`, no migration required. Launching forex in that same market is the independent `forex_enabled` flip, reviewed and timed separately — see Stage 4.7.

### Marketplace filtering — server-enforced, not just a UI filter

**1. Application-level default filter** — `MarketplaceRepository` queries `v_loan_listings WHERE country = :userCountry` and `v_forex_listings WHERE country = :userCountry` by default.

**2. RLS-level boundary** — global browse (recommended default, unchanged from the earlier plan) vs. hard country isolation. The non-spoofable RLS pattern, if hard isolation is ever adopted:

```sql
USING (
  country = (SELECT country FROM profiles WHERE id = auth.uid())
  OR private.is_admin()
)
```

> As before: **do not** rely on `auth.jwt() -> 'user_metadata'` for this — `user_metadata` is client-writable and therefore spoofable for access control. Use the `profiles` subquery pattern above, or a custom access-token hook into `app_metadata` if avoiding the subquery is ever worth the extra infrastructure.

This plan recommends **global browse, not hard isolation**, for the same reason as before: diaspora lending and forex are realistic, valuable use cases across this seven-market list too — arguably more so given three of the seven are in entirely different regions from the other four.

### Cross-border offers — recommendation unchanged

Recommendation: launch with cross-border offers **allowed**, revisit only if fraud/compliance review in Stage 5 flags a specific reason to restrict per market. Currency-neutral either way — an offer's currency always matches its listing's currency via the join, regardless of the offer-maker's registered country.

### Trust & Reputation aggregates stay global per user, not per-country or per-module

Unchanged from the earlier plan: `trust_aggregates` is one row per user, not one row per user per country or per module.

### 💳 Payments Infrastructure — scoped addendum, updated for the new market list

Subscriptions (and, if adopted, the contact-unlock fee) need to be charged and settled in the payer's own currency, or in USD where a subscriber opts into USD billing — see "Currencies" below. Flutterwave and Paystack both cover Nigeria natively (Paystack originates there) in addition to East Africa; South Africa and Egypt need their own rail-coverage confirmation, which should **not** be assumed from either East African or Nigerian coverage.

**Critical scope boundary, unchanged:** payment integration covers Nipanze's own revenue only — subscriptions and, if adopted, the contact-unlock fee. It never touches money or currency exchanged between two matched users, on either module.

**`transactions` table** (conceptual, unchanged in shape from the earlier plan, `currency_code` now referencing `currencies(code)` rather than assuming a country's local currency):

```sql
-- transactions (conceptual)
id                       UUID PRIMARY KEY
user_id                  UUID NOT NULL REFERENCES profiles(id)
type                     TEXT NOT NULL   -- 'subscription' | 'contact_unlock'
amount                   BIGINT NOT NULL
currency_code            TEXT NOT NULL REFERENCES currencies(code)   -- may be the payer's local currency or USD
country                  TEXT NOT NULL REFERENCES countries(code)    -- payer's country at time of charge
provider                 TEXT NOT NULL DEFAULT 'flutterwave'
provider_tx_ref          TEXT NOT NULL UNIQUE
provider_tx_id           TEXT
status                   TEXT NOT NULL DEFAULT 'pending'
related_subscription_id  UUID REFERENCES subscriptions(id)
related_reveal_id        UUID REFERENCES contact_reveals(id)
webhook_verified_at      TIMESTAMP
created_at               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
updated_at               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
```

### What this does not include (explicitly out of scope for v6.0's country expansion)

- ❌ Currency conversion or cross-currency comparison between markets
- ❌ Per-country subscription pricing figures — a Stage 6 business decision, per market
- ❌ Language localization
- ❌ Country-specific KYC document types beyond what `kyc_verifications.national_id_type` (free text) already absorbs
- ❌ P2P loan payment processing or currency exchange of any kind — see payments scope boundary above

---

## 💱 Currencies — Local, Cross-Border, and USD (v6.0 — resolves the earlier open decision)

### Why this exists

The earlier plan flagged, but did not resolve, whether `forex_requests.currency_held`/`currency_needed` should reference `countries.currency_code` directly (market-local pairs only) or a standalone table (to support USD and other non-market currencies). Separately, product direction raised two related but distinct questions: whether a **loan** could be denominated in USD, and whether a **subscription** could be billed in USD. This section resolves all three with one table and three independently-gated flags, rather than three ad-hoc columns scattered across `loan_requests`, `subscriptions`, and `forex_requests`.

### The three questions are genuinely different in risk

| Question | Risk profile | Gate |
|---|---|---|
| Loan denominated in USD instead of local currency | Lower — no currency trade happens, Nipanze still never touches the money; the live question is whether that country restricts foreign-currency-denominated P2P lending (a capital-controls question) | `system_settings.allow_foreign_currency_loans` (per country) |
| Subscription billed in USD instead of local currency | Lowest — pure billing-currency choice for Nipanze's own revenue, no different in kind from billing in local currency | No gate needed — offered wherever the payment provider supports it |
| Forex pair trading into/out of USD (or any currency) | Higher — this is the one closest to currency-exchange/bureau-de-change licensing territory, and applies even to two *local* currencies trading against each other (e.g. UGX↔KES), not just USD pairs | `currencies.forex_trading_enabled` (per currency, defaults `FALSE` for everything) |

Collapsing all three into a single "is USD allowed" decision would have over-restricted the two lower-risk cases to match the caution the third genuinely needs. Splitting them means Nigeria's NGN, for example, can be fully usable for NGN-denominated loans and NGN subscription billing from day one, while NGN's *forex-trading* clearance is reviewed and flipped on its own timeline, independent of the Loans module entirely.

### New table: `currencies`

```sql
-- currencies (conceptual)
code                    TEXT PRIMARY KEY   -- ISO 4217: UGX, KES, TZS, RWF, NGN, ZAR, EGP, USD
name                    TEXT NOT NULL
is_market_currency      BOOLEAN NOT NULL DEFAULT FALSE   -- TRUE for the 7 currencies tied to a live/planned Nipanze country
market_country          TEXT REFERENCES countries(code)  -- set only when is_market_currency = TRUE
forex_trading_enabled   BOOLEAN NOT NULL DEFAULT FALSE    -- gates use in a forex_requests pair; independent of loan/subscription usage
created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP

-- seed: the 7 market currencies + USD, all forex_trading_enabled = FALSE at migration time
-- ('UGX', 'Ugandan Shilling',    TRUE,  'UG', FALSE)
-- ('KES', 'Kenyan Shilling',     TRUE,  'KE', FALSE)
-- ('TZS', 'Tanzanian Shilling',  TRUE,  'TZ', FALSE)
-- ('RWF', 'Rwandan Franc',       TRUE,  'RW', FALSE)
-- ('NGN', 'Nigerian Naira',      TRUE,  'NG', FALSE)
-- ('ZAR', 'South African Rand',  TRUE,  'ZA', FALSE)
-- ('EGP', 'Egyptian Pound',      TRUE,  'EG', FALSE)
-- ('USD', 'US Dollar',           FALSE, NULL, FALSE)
```

Note that **every** row starts with `forex_trading_enabled = FALSE`, including the seven market currencies — a currency being someone's home currency does not automatically clear it for cross-border forex trading. UGX-vs-KES needs its own review to be tradeable on the Forex module just as much as UGX-vs-USD does; the table does not privilege "local" pairs over "foreign" ones in its default gating, only in the sense that market currencies are far more likely to clear review first.

### Downstream schema changes this implies

- `loan_requests.currency_code` → `TEXT NOT NULL REFERENCES currencies(code)`, defaulting to the requester's `profiles.country`'s local currency at insert, but overridable to `USD` (or, in principle, any `currencies` row) if `system_settings.allow_foreign_currency_loans` is `TRUE` for that country at post time
- `system_settings` gains `allow_foreign_currency_loans BOOLEAN NOT NULL DEFAULT FALSE` (per-country override, same nullable-`country`-means-global-default pattern already used for other settings)
- `subscriptions.currency_code` → `TEXT NOT NULL REFERENCES currencies(code)`, defaulting to the subscriber's local currency, freely overridable to `USD` at billing time with no additional gate — this is purely a payment-provider/UX decision, tracked as a Stage 6 pricing item, not a compliance one
- `forex_requests.currency_held` / `currency_needed` → both `TEXT NOT NULL REFERENCES currencies(code)`, with a trigger-level check that both rows have `forex_trading_enabled = TRUE` at request-creation time (`trg_fn_validate_forex_offer`, extended to validate the *request* too, not just the offer — see Stage 4.7)
- `CHECK (currency_held <> currency_needed)` on `forex_requests`, unchanged from the earlier draft

### Why a currency-level flag, not a country-level one

A single `countries.currency_tradeable` flag was considered and rejected: it would conflate "does this currency exist in Nipanze's vocabulary" (needed for loans and subscriptions, lower stakes) with "is this currency cleared for forex trading" (needed only for Forex, higher stakes). The two-table split (`countries` for markets, `currencies` for money) keeps those independently gated, which matters in practice — e.g., NGN can be immediately usable everywhere Loans needs a currency, while its forex-trading clearance follows its own, later timeline without touching Loans at all.

---

## 🎯 Pro Advanced Marketplace Filters (v4.2)

Pro-tier users can access advanced filtering controls on the marketplace feed to find listings matching specific borrower profile attributes or listing status details: employment type, income bracket (`fn_income_bracket`), suggested-terms presence, and KYC-verified owner status. Gated at the DB layer via `v_marketplace_pro_filters` (zero rows if the caller isn't Pro) and `get_marketplace_pro_filtered`, presented in the UI via an entry icon next to the notification bell opening a bottom sheet. These filters apply to loan listings; a forex-specific filter set (currency pair, rate-coverage tier) is a candidate for a later iteration on top of Stage 4.7, not committed here.

---

## 🖼️ Marketplace UI Specification (v6.0 — new, matches the mockup)

This section is the implementation spec for the shared Marketplace screen described conceptually in the README's "Marketplace Feed & Listing Design" section.

### Filter row

Three pill tabs: `All` (default), `Loans` 🌾, `Forex` 🔀. Selecting a tab swaps the underlying query between a merged `v_loan_listings ∪ v_forex_listings` (interleaved by `listed_at`, `All`) and a single-source query (`Loans` or `Forex` alone). No new RLS is needed for this — it's the same country-scoped queries from the Multi-Market Expansion Model, just combined or split for display.

### Loan `ListingCard` — field spec

| Element | Source | Notes |
|---|---|---|
| `Loan` badge (green dot) | Static, `request_type = 'loan'` | |
| Meta line | `district` · `duration_months` | e.g. "Eastern · 18 months" |
| Title | `title` | |
| Amount | `requested_amount` + `currency_code` | |
| Summary | `purpose`, truncated | |
| Progress bar | Derived from `number_of_offers` × average offer size vs. `requested_amount` | Server-computed `funded_pct` field on `v_loan_listings`, not client-computed |
| Countdown | `expires_at` − now, rendered "Xd left" | |
| Offer countdown | `loan_offers.expires_at` − now on participant-visible offer rows | Requires `get_public_listing_offers` to return `expires_at` |
| Localization and currency labels | App language setting + listing/profile currency | Listing detail, edit profile, and Pro filters must not hardcode English labels or UGX-only money labels |
| Trust badges | `v_trust_profile_public` for `owner_id` | Renders `⭐ No reviews yet` / `💎 0 completed` at zero-state |
| Watchlist star | `watchlist` membership for current user | |

### Forex `ListingCard` — field spec

| Element | Source | Notes |
|---|---|---|
| `Forex` badge (blue dot) | Static, `request_type = 'forex'` | |
| Meta line | requester's district/city (from `profiles`) · settlement speed hint | e.g. "Kampala · Instant" — "Instant" vs. a duration is a copy choice for near-term settlement preferences, not a new schema field |
| Title | Directional pair, e.g. `"{currency_held} → {currency_needed} Exchange"` | Composed client-side from `currency_held`/`currency_needed`, not stored as a title string |
| Headline amount | Computed `amount × rate_coverage`'s midpoint, or simply `amount` in `currency_needed` if a `preferred_rate` exists | Needs a product decision on exactly which number headlines the card — flagged as a UI-detail decision for Stage 4.7 implementation, not blocking the schema |
| Summary | Free-text derived from `settlement_preference`, e.g. "Exchange $500 to UGX at preferred rate" | |
| Send/Rate/Receive panel | `amount` (`currency_held`) / `preferred_rate` or aggregate rate signal / computed receive amount (`currency_needed`) | For a **non-participant** viewer, the "Rate" shown must be the aggregate `rate_coverage_tier` signal or the requester's own `preferred_rate` if Pro-suggested — **never** an individual offer-maker's exact proposed rate, per the Selective Transparency Model |
| `⚡ Urgent` tag | New `forex_requests.is_urgent` boolean, or derived from `expires_at` proximity | Recommendation: derive automatically (e.g. `expires_at` within a configurable threshold) rather than adding a self-declared flag a requester could spam, consistent with how "closing soon" watchlist styling already works off real timestamps, not a user-set flag |
| Trust badges | Same `v_trust_profile_public` pattern as loan cards | |
| Watchlist star | `watchlist` membership for current user | |

### Shared: bottom navigation

`Markets · Watchlist · Request · Positions · Account` — unchanged by the module split; the routes underneath (`/marketplace`, `/watchlist`, `/loans/create` + `/forex/create` behind the Request FAB, `/positions`, `/account`) are what branch by module, not the nav bar itself.

### Implementation checklist

- [ ] `v_loan_listings` gains a server-computed `funded_pct` column (not client-derived from raw offer rows, to keep the selective-transparency boundary intact for non-participants)
- [ ] `v_forex_listings` gains `rate_coverage_tier` and a server-computed aggregate "indicative rate" safe to show non-participants (never a specific offer's rate)
- [ ] `forex_requests` gains either `is_urgent` or an agreed derivation rule off `expires_at` — decide before Stage 4.7 UI work starts, not during it
- [ ] `MarketplacePage` implements the three-tab filter and dispatches to the correct card widget (`LoanListingCard` vs `ForexListingCard`) based on `request_type`
- [ ] `TrustBadgeRow` renders explicit zero-states (`No reviews yet`, `0 completed`) rather than omitting badges when a profile has no history yet

---

## Stage 1 — Foundation ✅ Complete

- [x] Project bootstrap, package name `ug.nipanze.app`
- [x] All core dependencies including `image_picker`
- [x] `--dart-define` build variables; no hardcoded keys
- [x] `core/errors/app_exception.dart` — full v4.0 trigger error codes
- [x] GetIt + Injectable DI — all singletons registered
- [x] `supabase/config.toml`, schema v4.0 in `sql/`
- [x] Light/dark theme — DM Sans + DM Mono, brand colours
- [x] GoRouter — full route table, auth guard, `GoRouterRefreshStream`
- [x] 5-tab bottom nav: Markets · Watchlist · Request · Positions · Account
- [x] `AuthRepository` + `AuthBloc` — full event/state set
- [x] Login, Register, VerifyEmail, ResetPassword pages
- [x] 8 unit tests passing

---

## Stage 2 — Core Marketplace ✅ Complete

### 2.1 Marketplace Feed
- [x] `MarketplaceRepository` — `v_loan_listings`, filters, Realtime stream
- [x] `MarketplaceCubit` — live feed with Realtime refresh
- [x] `MarketplacePage` — filter pills, `ListingCard`, skeleton, live dot
- [x] `LoanDetailPage` — listing detail, income + repayment plan display, offers panel

### 2.2 Loan Requests (Free tier and above)
- [x] `ListingCreatePage` — 3-step form: loan details → income/repayment context → review & publish
- [x] Form fields: title, purpose, amount, duration, district, income source, preferred repayment plan, repayment amount per period, repayment timeline
- [x] Basic request form does not require interest rate; lenders propose interest/return expectations in offers
- [x] `SystemSettingsRepository` — fetches public limits from DB; cached singleton
- [x] `MyRequestsPage` + `MyRequestsCubit` + `RequestRepository` — real data, Realtime, cancel with confirm
- [x] Contracted request banner redirects to Positions tab

### 2.3 Loan Offers (Lender tier and above)
- [x] `OfferRepository` — `makeOffer`, `withdrawOffer`, Realtime stream
- [x] `LoanDetailPage` — live Realtime offers panel, glow flash on new offer
- [x] Subscription gate modal — plan cards (Free / Lender / Pro), upgrade navigates to Account
- [x] `KycVerification` model + `KycRepository` — Storage uploads, `submitForReview`
- [x] `KycPage` — camera/gallery picker, 3 doc tiles, submit gating, rejection reason banner

### 2.4 Offer Acceptance
- [x] `accept_offer` RPC called from the request-owner side
- [x] Rejected offers notified to losing offer-makers
- [x] Listing moves to `contracted` status; removed from live feed
- [x] `WatchlistButton` on detail page — toggles DB save

### Stage 2 Exit Criteria
- [x] Any user (Free+) can post a free request and receive offers
- [x] Any user with an active Lender/Pro plan can browse and make offers
- [x] Request owner can accept one offer; all others auto-rejected
- [x] Live feed and offers panel refresh via Realtime
- [x] Subscription gate blocks offer placement for Free-plan users
- [x] App stable on Android APK (arm64), web, and Linux desktop

---

## Stage 3 — Polish & Supporting Features ✅ Complete

### 3.1 Watchlist
- [x] `WatchlistRepository`, `WatchlistCubit`, `WatchlistCard`, `WatchlistPage` — urgency grouping, empty state, Realtime

### 3.2 Positions
- [x] `PositionsRepository`, `PositionsCubit`, `LenderOfferCard`, `PositionsPage` — My Requests / My Offers tabs, withdraw with confirm

> Note: "My Requests" and "My Offers" are two views of the same account's activity — from Stage 4.7 onward, both tabs are module-agnostic (spanning loan and forex requests/offers), same query pattern extended to a second source table per tab.

### 3.3 Notifications
- [x] `NotificationRepository`, `NotificationCubit`, `NotificationsPage` — Realtime, unread badge

### 3.4 Profile & Account
- [x] `ProfilePage`, `AccountPage` — live subscription data, upgrade flow (off-platform), theme persistence

### 3.5 Error & Empty States
- [x] `OfflineBanner`, loading skeletons throughout

### Stage 3 Exit Criteria
- [x] All 5 nav tabs functional with real data
- [x] Watchlist, Positions, offer withdrawal working end to end
- [x] App stable on local dev with Supabase cloud project

---

## Stage 3.5 — Cloud Migration & Auth Hardening ✅ Complete

- [x] Schema/seed applied to cloud, RLS/view/grants patch, function security fix
- [x] `verification-documents` storage bucket (private, path-based ownership)
- [x] `private` schema, SECURITY INVOKER wrappers, append-only audit log enforced
- [x] Full RLS field-masking audit against README rules
- [x] Refresh token rotation, JWT expiry, leaked-password protection
- [x] Realtime publication on core tables

### App Testing ⏳ In Progress
- [/] End-to-end request-posting flow tested on cloud (web)
- [ ] End-to-end offer-making flow tested on cloud (web)
- [ ] KYC document upload verified
- [ ] Release APK built and tested on physical device

> **Finish this checklist before starting Stage 4.5**, so the multi-market migration lands on a verified-stable baseline.

---

## Stage 4 — Structured Deal Agreement, Contact Sharing & Trust System ⬜ Planned

Introduces locked bidding, the Selective Transparency Model, and the Trust & Reputation System for the **Loans project**. Stage 4.7 later applies the identical pattern to the **Forex project**.

### Flow overview

```
REQUEST POSTED (locked on publish)          → amount, duration, purpose, [PRO] suggested interest/late fee/schedule
LISTING DETAIL VIEWED (tiered)              → everyone: broad listing context
                                               owner only: offer count/coverage and full bid book
                                               owner/participants only: exact offer detail + offer expiry countdown + offer-maker trust badges
OFFER SUBMITTED (locked on submit)          → amount, interest rate, late fee, schedule → unlocks full detail for offer-maker
CONTRACT GENERATED (on acceptance)          → final terms locked, contact revealed to both parties
DEAL COMPLETES (off-platform)               → either party may review the other, feeding global trust aggregates
```

### 📋 Request Posting — Term Suggestions (Pro-tier)

| Field | Free | Lender | Pro |
|---|---|---|---|
| Amount needed | ✅ | ✅ | ✅ |
| Duration | ✅ | ✅ | ✅ |
| Purpose | ✅ | ✅ | ✅ |
| Suggested interest rate / late fee / schedule | ❌ | ❌ | ✅ |

### 🏷️ Offer Submission — Term Setting (Lender plan and above)

Amount offered, interest rate, late payment fee (% on missed installment only), repayment schedule — locked on submit. Placing an offer unlocks full offer-level detail on that listing for the offer-maker.

### 🔍 Selective Transparency — Implementation Checklist

- [ ] `offer_coverage_tier` computed column on `v_loan_listings`
- [ ] `v_lender_offers` scoped via RLS + `security_invoker`
- [ ] `get_public_listing_offers(request_id)` RPC branches on caller identity
- [ ] `LoanDetailPage` renders tiered payload correctly
- [ ] Placing/withdrawing an offer refetches and correctly re-locks/unlocks detail
- [ ] Non-participant direct-RPC test confirms aggregate-only payload

### 🌟 Trust & Reputation System — Implementation Checklist

- [ ] `reviews` table, `profiles.phone_verified_at`, `submit_review` RPC, `recompute_trust_aggregates` trigger
- [ ] `v_trust_profile_public` / `v_trust_profile_pro` views
- [ ] `TrustBadgeRow` shared widget, including explicit zero-states (`No reviews yet`, `0 completed`)
- [ ] Pro-only `AdvancedTrustPanel`
- [ ] `UserReviewsPage`, "Leave a review" prompt on Positions
- [ ] Non-Pro/non-participant access tests

### 📄 Contract Contents (Loans)

Both parties' identity (post-reveal), loan amount, agreed interest rate, total repayment amount, repayment schedule, late payment fee (missed installment only), start/end dates, legal disclaimer, audit timestamp. `fn_generate_locked_contract_text` includes `currency_code` explicitly.

### 🔓 Contact Reveal Flow

Blurred Deal + Contact Card → "Unlock Deal & Contact" → irreversible confirmation → contact revealed (name, phone, email) → `deal_unlocked` notification to both parties → full contract visible. Enforced via `reveal_contact` RPC, never accessible before this step via any query.

### ✅ Stage 4 Exit Criteria

- [ ] Pro-tier gate on interest/late fee/repayment fields in the request form
- [ ] Request terms locked on publish; offer terms locked on submit
- [ ] `offer_coverage_tier` visible to every viewer, public and anonymized
- [ ] Exact offer-term detail visible only to owner/participants; verified via direct-RPC test
- [ ] Public trust badge row visible on every profile/card/offer row to every viewer, including zero-states
- [ ] Pro-only Verified badge and advanced insights never substitute for or hide the public badge row
- [ ] Reviews participant-gated, one per contract per direction
- [ ] Contract auto-generated on acceptance; late fee applies only to missed installment
- [ ] Contact reveal only after contract generation; never accessible before via any query
- [ ] `role` column fully removed; all gating reads `subscription_plan` only
- [ ] Pro Advanced Marketplace Filters shipped (`v_marketplace_pro_filters`, `get_marketplace_pro_filtered`, gated entry button + bottom sheet)

---

## Stage 4.5 — Multi-Market Expansion ⬜ Planned

Full model in "Multi-Market Expansion Model" and "Currencies" above.

### Migration Checklist

- [ ] Create `currencies` table; seed the 7 market currencies + `USD`, all `forex_trading_enabled = FALSE`
- [ ] Create `countries` table; seed all 7 markets — `UG` as `is_active = TRUE`, the other six `FALSE`; all 7 `forex_enabled = FALSE` at this stage
- [ ] `ALTER TABLE profiles ADD COLUMN country ...`; backfill to `'UG'`; set `NOT NULL`
- [ ] `ALTER TABLE loan_requests ADD COLUMN country ...`; backfill from `profiles.country`; set `NOT NULL`; add `currency_code REFERENCES currencies(code)`, defaulting to the country's local currency
- [ ] New trigger `trg_fn_set_request_country` (`BEFORE INSERT`) — locks `country` at publish
- [ ] `ALTER TABLE system_settings ADD COLUMN country ...` and `ADD COLUMN allow_foreign_currency_loans BOOLEAN NOT NULL DEFAULT FALSE`
- [ ] Rename `subscriptions.amount_ugx` → `amount_minor_units`; add `currency_code REFERENCES currencies(code)`
- [ ] Rebuild `v_loan_listings`, `v_lender_offers`, `v_marketplace_activity` to include `country` / `currency_code`
- [ ] Indexes: `idx_lr_country`, `idx_lr_country_status`, `idx_profiles_country`
- [ ] `MarketplaceRepository` default query filters `country = currentUserCountry`, with explicit "browse other markets" toggle
- [ ] Onboarding: country-select step, pre-filled from phone-prefix guess, editable
- [ ] Decide and document: global browse vs. hard isolation; cross-border offers allowed vs. blocked
- [ ] `stage-4.5-verify.sql` — no `loan_requests`/`profiles` row with `country IS NULL`; all 7 countries and 8 currencies present

### Stage 4.5 Exit Criteria

- [ ] Every `profiles` and `loan_requests` row has a non-null `country`
- [ ] Marketplace feed defaults to the logged-in user's country; switching markets is explicit
- [ ] `v_loan_listings`/`v_lender_offers` return `currency_code` alongside every amount
- [ ] `system_settings` limits (including `allow_foreign_currency_loans`) resolve correctly per country
- [ ] Open decisions (browse vs. isolation; cross-border offers) explicitly resolved
- [ ] Activating a new market requires only `UPDATE countries SET is_active = TRUE` — verified by flipping `KE` in staging
- [ ] Admin KPI view filterable/groupable by country
- [ ] A test loan request successfully posted in `USD` where `allow_foreign_currency_loans = TRUE`, and rejected where `FALSE`

---

## Stage 4.7 — Forex Marketplace Expansion ⬜ Planned

Full model in the README's "Foreign Exchange (Forex)" section and this document's "Currencies" section above. Depends on Stage 4.5; reuses Stage 4's selective-transparency and trust-system implementation directly.

### Migration Checklist

- [ ] Create `forex_requests`: `currency_held`/`currency_needed` (both `REFERENCES currencies(code)`), `amount`, `preferred_rate` (Pro-only, nullable), `settlement_preference`, `country` (locked at insert), `is_urgent` or agreed `expires_at`-derived urgency rule (see Marketplace UI Specification above — decide before building the UI, not during), `CHECK (currency_held <> currency_needed)`
- [ ] Create `forex_offers`: `rate_offered`, `amount_available`, `terms` — **no `country` column**
- [ ] New trigger `trg_fn_set_forex_request_country` — mirrors `trg_fn_set_request_country`
- [ ] New/extended trigger `trg_fn_validate_forex_offer` — validates both `currency_held` and `currency_needed` on the *request* have `forex_trading_enabled = TRUE` at creation, and validates offer shape (`rate_offered > 0`, `amount_available > 0`) at offer time; cross-border check only if that open decision is resolved to "disallowed" (not recommended)
- [ ] Decide `countries.forex_enabled` value for Uganda at Stage 4.7 ship — this is an explicit go/no-go, not an automatic `TRUE` just because Uganda's lending is live
- [ ] For each of `UGX`, `KES`, `TZS`, `RWF`, `NGN`, `ZAR`, `EGP`, and `USD` — explicit, individually-reviewed decision on `forex_trading_enabled`, not a bulk flip; **flag Egypt's EGP for additional scrutiny** given its currency-control history, independent of whatever review clears Uganda's lending or Uganda's own forex
- [ ] Build `v_forex_listings` (public feed, `rate_coverage_tier`, server-computed indicative rate safe for non-participants) and `v_forex_offers` (participant-scoped, `security_invoker` + RLS)
- [ ] Build `get_public_forex_offers(request_id)` RPC mirroring `get_public_listing_offers`
- [ ] Extend `v_user_marketplace_activity` and `v_marketplace_activity` to include forex rows, with a `request_type` discriminator
- [ ] Extend `accept_offer` and `fn_generate_locked_contract_text` with a `request_type` branch for forex contract wording (currency pair, rate, amount, settlement terms in place of interest/late-fee/schedule) — `reveal_contact` itself needs no change
- [ ] Verify `recompute_trust_aggregates(user_id)` fires on forex contract/review events (generalize the trigger's join if the Stage 4 implementation hard-coded a loan-only path)
- [ ] `MarketplaceRepository` gains a `v_forex_listings` query path; UI gains the `All / Loans / Forex` filter (see Marketplace UI Specification above)
- [ ] `ListingCreatePage`'s "Post Request" flow gains a Loan/Forex choice at the start, branching into the existing loan form or a new `ForexCreatePage`
- [ ] `PositionsPage`'s My Requests / My Offers tabs extended to include forex rows in the same lists (not a separate third tab)
- [ ] Forex-specific seed data exercising at least two currency pairs and both participant and non-participant selective-transparency views
- [ ] `stage-4.7-verify.sql` — no `forex_requests` row with `country IS NULL` or `currency_held = currency_needed`; no forex offer/listing exposes exact rate to a non-participant; no forex request created against a currency pair where either side has `forex_trading_enabled = FALSE`

### Stage 4.7 Exit Criteria

- [ ] Any user (Free+) can post a free forex request specifying `currency_held`, `currency_needed`, and `amount`, in any `forex_enabled` market, limited to `forex_trading_enabled` currency pairs
- [ ] Any user with an active Lender/Pro plan can browse and make forex offers with their own rate, amount, and terms
- [ ] Forex request/offer terms locked on publish/submit, identical rule to loans
- [ ] `rate_coverage_tier` visible on every forex listing to every viewer, public and anonymized
- [ ] Exact forex offer-term detail visible only to the request owner and to offer-makers who have bid — verified by non-participant test account
- [ ] Forex deals feed the same global `trust_aggregates` row as loan deals — verified by a test account completing one of each and observing a single combined `completed_deals_count`
- [ ] Forex contract generation and contact reveal use the same `accept_offer`/`reveal_contact` RPCs as loans, with forex-appropriate contract wording
- [ ] `countries.forex_enabled` and `currencies.forex_trading_enabled` correctly and independently gate forex availability
- [ ] No new `subscription_plan` values, price points, or account types introduced for forex
- [ ] Marketplace feed cleanly presents both Loans and Forex listings via the `All/Loans/Forex` filter, matching the field spec in "Marketplace UI Specification" above
- [ ] Cross-border forex offers explicitly resolved (recommendation: allowed)
- [ ] `stage-4.7-verify.sql` passes cleanly against a staging environment with Stage 4.5 and Stage 4 already applied

---

## Stage 5 — Admin & Compliance ⬜ Planned

- [ ] Admin KYC review dashboard, review moderation, KPI dashboard (`v_marketplace_activity`), SMS alerts
- [ ] Admin dashboard filterable by country and by `request_type` (loan vs. forex)
- [ ] Per-country `system_settings` editable from the admin panel, including `allow_foreign_currency_loans`
- [ ] `countries.is_active` toggle exposed in admin — pause/resume lending in a market without a deploy
- [ ] `countries.forex_enabled` toggle exposed in admin, independent of `is_active`
- [ ] `currencies.forex_trading_enabled` toggle exposed in admin, per currency

---

## Stage 6 — Launch & Growth ⬜ Planned

- [ ] Play Store AAB + App Store IPA, privacy policy + terms of service
- [ ] 3-screen onboarding carousel — no role-selection step; country-select step (pre-filled from phone-prefix guess, editable)
- [ ] Crash reporting, referral programme
- [ ] Contextual subscription upgrade prompts (Loans and Forex triggers alike)
- [ ] Finalize per-market subscription pricing against local willingness-to-pay research; confirm no separate forex price point is needed — same pricing governs both modules; decide whether/where USD billing is offered as an alternative
- [ ] Decide go/no-go on the contact-unlock fee, informed by real Stage 4/5 usage data across both modules
- [ ] Flutterwave/Paystack (or equivalent) integration for `subscriptions`, scoped strictly to Nipanze's own revenue
- [ ] **Per-market launch checklist — repeat independently for Kenya, Tanzania, Rwanda, Nigeria, South Africa, and Egypt, in that order, before flipping that country's `is_active`:**
  - [ ] `countries.is_active` set `TRUE`
  - [ ] Local-currency pricing finalized for Lender and Pro
  - [ ] Payment-rail coverage confirmed with the chosen aggregator for that specific country — Nigeria's card/fintech-native rails, South Africa's card/EFT rails, and Egypt's rails each need independent confirmation, not inference from East African or from each other's coverage
  - [ ] Local KYC document types validated
  - [ ] Local regulatory/compliance review completed for **lending** specifically
  - [ ] **Separately**, decide and document `countries.forex_enabled` and the relevant `currencies.forex_trading_enabled` flags for that market — do not assume forex clears alongside lending; Egypt in particular should not inherit any other market's forex clearance given its EGP currency-control history
- [ ] Decide rollout cadence — simultaneous vs. sequential per the priority order above, informed by Uganda + Kenya learnings once Kenya ships

---

## Key Flows — Current Status

| Flow | Status |
|---|---|
| Register → verify email → login | ✅ |
| 5-tab nav, Request in centre | ✅ |
| Browse marketplace with filters | ✅ Stage 2 |
| Live feed Realtime refresh | ✅ Stage 2 |
| Post a structured loan request | ✅ Stage 2 |
| Form limits from DB (system_settings) | ✅ Stage 2 |
| Browse and make an offer with full terms (Lender/Pro) | ✅ Stage 2 |
| Subscription gate modal | ✅ Stage 2 |
| Request owner accepts an offer | ✅ Stage 2 |
| Losing offers auto-rejected | ✅ Stage 2 |
| Live offers panel Realtime + flash | ✅ Stage 2 |
| KYC upload | ✅ Stage 2 |
| Save to watchlist | ✅ Stage 3 |
| Watchlist — real data, grouped, urgency | ✅ Stage 3 |
| Positions — My Requests / My Offers tabs | ✅ Stage 3 |
| Offer withdrawal with confirm dialog | ✅ Stage 3 |
| Notifications | ✅ Stage 3 |
| Profile/Account live data | ✅ Stage 3 |
| Pro-tier: suggest interest rate / late fee / repayment on post | ⬜ Stage 4 |
| Request/offer terms locked on publish/submit | ⬜ Stage 4 |
| Selective transparency (loans) | ✅ DB · ✅ UI (spec) |
| Public trust badge row, incl. zero-states | ⬜ Stage 4 |
| Pro-tier Verified badge + advanced trust insights | ⬜ Stage 4 |
| Post-contract review flow | ⬜ Stage 4 |
| Contract auto-generation, contact reveal | ⬜ Stage 4 |
| `role` column removal | ⬜ Stage 4 |
| Pro Advanced Marketplace Filters | ⬜ Stage 4 |
| Multi-market schema (`countries`, `currencies`, 7-market seed) | ⬜ Stage 4.5 |
| USD-denominated loans + USD subscription billing | ⬜ Stage 4.5 |
| Marketplace feed defaults to user's country, browse-other-markets toggle | ⬜ Stage 4.5 |
| Forex schema (`forex_requests`, `forex_offers`, `forex_enabled`, `forex_trading_enabled`) | ⬜ Stage 4.7 |
| `All / Loans / Forex` marketplace filter + Send/Rate/Receive card | ⬜ Stage 4.7 |
| Forex selective transparency and trust-signal reuse | ⬜ Stage 4.7 |
| Payment integration (subscriptions + contact-unlock fee only) | ⬜ Stage 6 |
| Admin KYC review, review moderation, KPI dashboard | ⬜ Stage 5 |
| SMS alerts | ⬜ Stage 5 |

---

## Test Accounts (password: `Test1234!`)

| Email | Country | Subscription | Best for testing |
|---|---|---|---|
| `david.mukasa@gmail.com` | UG | Free | Contracted loan request; contact reveal triggered |
| `james.okello@outlook.com` | UG | Pro | Active loan request, two pending offers |
| `robert.ssemwanga@gmail.com` | UG | Lender | Closing-soon loan request |
| `admin1@nipanze.ug` | UG | Free (`is_admin = true`) | Full admin dashboard access |
| `test.user@gmail.com` | UG | Free | No prior activity — onboarding gates |
| `wanjiru.kamau@gmail.com` *(Stage 4.5)* | KE | Free | KE feed/currency rendering, cross-border browse to UG |
| `amani.mwakalinga@gmail.com` *(Stage 4.5)* | TZ | Free | TZS currency rendering |
| `uwase.claudine@gmail.com` *(Stage 4.5)* | RW | Pro | RWF Pro term suggestions, gating parity |
| `chidinma.okafor@example.ng` *(Stage 4.5)* | NG | Lender | NGN currency rendering; confirms Nigeria's rail-coverage assumptions are validated independently of East Africa |
| `thandiwe.dlamini@example.co.za` *(Stage 4.5)* | ZA | Pro | ZAR Pro term suggestions and gating parity |
| `youssef.hassan@example.eg` *(Stage 4.5)* | EG | Free | EGP currency rendering; flagged specifically for the extra forex-review note re: EGP — this account should **not** be used to imply forex clearance for Egypt |
| `diaspora.usd@example.com` *(Stage 4.5)* | UG | Pro | Posts a USD-denominated loan request where `allow_foreign_currency_loans = TRUE`; also tests USD subscription billing |
| `mutesi.grace@gmail.com` *(Stage 4.7)* | UG | Lender | Active `UGX → KES` forex request, two pending rate offers; primary account for the forex request-owner full-detail view |
| `kampala.exchange@example.ug` *(Stage 4.7)* | UG | Pro | Competing forex offer on Grace's request; verifies participant-gated unlock |
| `nonparticipant.tester@gmail.com` *(Stage 4.7)* | UG | Free | Verifies non-participants see only `rate_coverage_tier` on forex listings, never individual rates |

> **Stage 4.5 currency testing:** confirm `v_loan_listings`/`v_lender_offers` currency-formatting logic against all 7 market currencies plus USD; confirm a loan request in USD is rejected where `allow_foreign_currency_loans = FALSE` and accepted where `TRUE`.
>
> **Stage 4.7 forex testing:** view `mutesi.grace@gmail.com`'s `UGX → KES` request as `nonparticipant.tester@gmail.com` to confirm only `rate_coverage_tier` is visible; log in as `kampala.exchange@example.ug` (has bid) to confirm full detail unlocks. Complete a forex contract between two accounts that already share a loan-side completed deal to confirm `completed_deals_count` combines both into one number.

---

## Deployment

| Target | Available now | Command |
| --- | --- | --- |
| Android APK (sideload) | ✅ | `flutter build apk --release` |
| Web | ✅ | `flutter build web --release` |
| Linux desktop | ✅ | `flutter build linux --release` |
| Edge Functions | ✅ (free tier) | `supabase functions deploy` |
| DB Migrations | ✅ | `supabase db push` |
| Android Play Store | Stage 6 | `flutter build appbundle --release` |
| iOS App Store | Stage 6 | `flutter build ios --release` |

---

## Architecture Constraints

1. **No fund movement** — platform never initiates, processes, records, or tracks financial transactions or currency exchanges, in any country
2. **Anonymity by default** — request-owner id never in marketplace queries; offer-maker identity hidden until offer accepted and contact revealed, loan or forex
3. **DB is the gate** — triggers + RLS enforce all rules based on `subscription_plan`, `country`, `currencies.forex_trading_enabled`, and `request_type` where relevant; client validation is UX only
4. **Controlled contact sharing** — `reveal_contact` enforced at API layer; never accessible before reveal via any query
5. **Friendly errors** — `parseSupabaseError()` everywhere; raw trigger codes never reach the user
6. **Append-only audit log** — `audit_logs` never writable via UPDATE or DELETE
7. **No stored role** — the only role is `is_admin`; all marketplace capability comes from `subscription_plan`, applied identically to Loans and Forex
8. **Selective transparency** — exact offer-level terms visible only to the request owner and to offer-makers with a live offer on that request; offer count and coverage are borrower-only on listing detail, enforced via RLS/RPC/view masking
9. **Input-gated actions** — create/publish/send buttons stay disabled until required inputs for the current step are present; validators still provide detailed messages after interaction
10. **Notification deep links use current app routes only** — loan notifications go to `/marketplace/:requestId`, forex notifications go to `/forex/:requestId`; removed legacy contract routes are not emitted by the client
11. **Trust signals are public, platform-scoped, country-agnostic, and module-agnostic** — reflecting a user's full on-platform history across all markets and both projects; never implying knowledge of off-platform repayment or settlement behavior
12. **Country is explicit, indexed, and locked-at-creation** — `profiles.country` is the source of truth; `loan_requests.country`/`forex_requests.country` are copied and frozen at insert; offers never store their own country
13. **Two projects, one platform** — Loans and Forex share auth, trust, contracts, and contact-reveal, but keep separate request/offer tables, separate create-flows, and separate listing-card designs. Neither module gets its own subscription plan, price point, or account type
14. **Currency gating is three independent flags, not one** — `system_settings.allow_foreign_currency_loans` (loans in a non-local currency), free USD billing (subscriptions, no gate), and `currencies.forex_trading_enabled` (forex pairs, the highest-scrutiny gate, defaults off for every currency including market-local ones)
13. **Regulatory review is per-market and per-module, never inherited** — a market's lending clearance (`countries.is_active`) never implies its forex clearance (`countries.forex_enabled`); one market's clearance never implies another's, and this applies with particular force across the Uganda/Kenya/Tanzania/Rwanda vs. Nigeria/South Africa/Egypt boundary, given how different these markets' regulatory and payment landscapes are from each other

---

*Nipanze Platforms Limited · contact@nipanze.ug · nipanze.ug*
*Made with ❤️ for financial inclusion across Africa*
