# BUILD_PLAN.md — Nipanze

> **Flutter + Supabase** · Digital loan listing matchmaking marketplace for Uganda and emerging economies
> Last updated: July 2026 · Schema v5.0 · Seed v2.1 (Uganda-only until Stage 4.5 migration is applied)

> **⚡ v4.1 Architecture Change:** Nipanze moved from a **role-based** model (borrower / lender) to a **unified, subscription-based, action-based** model. There is no "I am a borrower" or "I am a lender" — every user sees one marketplace and performs borrower actions (Post Request) or lender actions (Make Offer) depending on what they click. Access to actions is gated purely by `subscription_plan`. See "Unified Marketplace Model" below.
>
> **⚡ v4.1 Stage 4 addition:** Listing detail visibility is **tiered, not binary**. See "Selective Transparency Model" below — it changes what `v_lender_offers` and `get_public_listing_offers` return depending on who's asking.
>
> **⚡ v4.1 Stage 4 addition:** A public **Trust & Reputation System** (ratings, reviews, completed-deal counts, badges) is planned. See "Trust & Reputation System" below — deliberately kept separate from selective transparency: trust signals are public to everyone on every plan, while offer-term detail stays participation-gated.
>
> **⚡ v5.0 Architecture Change:** Nipanze is moving from a **single-country (Uganda-only)** model to a **multi-country, single-database** model covering the full **East African Community (EAC)** — Kenya, Uganda, Tanzania, Rwanda, Burundi, South Sudan, DR Congo, and Somalia. One set of tables (`profiles`, `loan_requests`, `loan_offers`, …) now carries a `country` code and every amount resolves to that country's own currency, instead of separate tables, databases, or a single hardcoded currency. See "Multi-Country Expansion Model" below — and the "EAC Country Reference" table within it — before touching schema, RLS, or seed files.
>
> This layers on top of, and does not replace, the v4.1 changes already documented above: the **Unified Marketplace Model**, the **Selective Transparency Model**, and the **Trust & Reputation System** all still apply — multi-country adds a *geographic* dimension on top of them, it doesn't change how plans, transparency, or trust work.

---

## Stage Map

| Stage | Title | Status |
|---|---|---|
| 1 | Foundation | ✅ Complete |
| 2 | Core Marketplace | ✅ Complete |
| 3 | Polish & Supporting Features | ✅ Complete |
| 3.5 | Cloud Migration & Auth Hardening | ✅ Complete |
| 4 | Structured Deal Agreement, Contact Sharing & Trust System | ⬜ Planned |
| 4.5 | Multi-Country Expansion | ⬜ Planned |
| 5 | Admin & Compliance | ⬜ Planned |
| 6 | Launch & Growth | ⬜ Planned |

> Stage 4.5 is written to be implementable **before or alongside** Stage 4 — it's a data-model and RLS change, not a UI feature, so it doesn't block Stage 4's contract/trust work and vice versa. Recommended order: ship Stage 4.5's schema migration first (smaller, lower-risk, and everything after it should be country-aware from the start), then build Stage 4 UI on top of a schema that's already multi-country-shaped.

---

## 🧠 Unified Marketplace Model (v4.1 — supersedes role-based framing)

### The decision

- ✅ One interface for every user — no separate borrower/lender screens
- ✅ No "borrower vs lender" role stored on the account
- ✅ Users choose a **subscription plan**, not a role
- ✅ The same person can post a request *and* make offers, any time, with the same login

### Mental model shift

| Old model | New model |
|---|---|
| "User *is* a borrower or a lender" | "User *performs* borrower or lender actions depending on what they click" |
| Role determines what's visible | Subscription plan determines what's clickable |
| Separate flows/screens per role | One dashboard, one marketplace, action buttons gated by plan |

### How it behaves

**Single entry point after login** — every user lands on the same dashboard:

1. **📢 Marketplace** — all loan listings, same feed for everyone
2. **➕ Post Request** — always visible from Free tier upward
3. **💼 Offers Panel** — shows offers *received* on your requests, and (if your plan allows) offers *you've made* on others' requests

There is no "select your role" step at signup or login. A user simply acts:

- Clicks **"Post Request"** → acting as a borrower for that listing
- Clicks **"Make Offer"** → acting as a lender for that listing

### Feature access by plan

| Plan | Access |
|---|---|
| 🟢 **Free** | Post basic loan requests (amount, duration, purpose) · Browse marketplace · Accept received offers · Watchlist, Positions, Notifications, KYC · Full visibility into public trust signals on every profile · ❌ Cannot make offers · ❌ Cannot suggest terms when posting |
| 🔵 **Lender Plan** | Everything in Free, **plus**: Make offers on any listing · Set interest rate, late payment fee, repayment schedule on offers |
| 🟣 **Pro** | Everything in Lender, **plus**: Suggest terms when posting a request (interest rate, late fee, repayment schedule) · Priority visibility for posted requests · Improved matching · Verified badge · Advanced trust insights (success rate, reliability score) |

> No plan is ever labeled "Borrower Plan" or "Lender-only." The plan name describes the *unlocked capability*, not the person.

### Feature gating logic

```
IF subscription_plan == "free"
  disable "Make Offer"
  disable term-suggestion fields on Post Request

IF subscription_plan == "lender"
  enable "Make Offer"
  enable lender term fields (interest, late fee, schedule) on offers
  keep term-suggestion fields on Post Request disabled

IF subscription_plan == "pro"
  enable everything above
  enable term-suggestion fields on Post Request
  enable priority visibility / improved matching
  enable Verified badge display + advanced trust insights view
```

### Why this is the right call

1. **Simpler UX** — no "am I a borrower or a lender?" confusion at signup
2. **Higher conversion** — users aren't boxed into one identity, so upgrading feels natural rather than like switching accounts
3. **More revenue paths** — a Free user who only ever posted requests can upgrade to Lender the moment they want to fund someone else's listing, same account, no re-registration

### What this removes from the data model

- ❌ `role` column (`borrower` / `lender` / `both`) — **no longer needed**
- ❌ Role-based RLS branching — **replaced with plan-based checks**

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

### Migration impact (Stage 4 dependency)

Because Stage 4 (deal agreement + contact sharing) was originally scoped around a "Premium Borrower" vs "Lender" dual-subscription split, it must be re-read through the unified model:

- "Premium Borrower" features (suggested interest/late fee/schedule on post) are now simply **Pro-tier posting capability** — not a separate subscription product
- "Lender" subscription features (making offers with full terms) are now the **Lender-tier capability** — available without needing Pro
- A single user can hold only **one** `subscription_plan` at a time (`free | lender | pro`), and Pro is a strict superset of Lender, which is a strict superset of Free — there is no "buy just the posting add-on" product

This keeps subscription logic to one enum column and one gating function, rather than two independent entitlement flags — simpler RLS, simpler billing, simpler UI.

---

## 🔍 Selective Transparency Model (v4.1 — governs listing detail visibility)

Stage 2 shipped a fully public offer book on `LoanDetailPage`: every visitor could see every offer's exact amount and terms. Stage 4 replaces that with **tiered visibility**, keyed off participation rather than role.

### The decision

- ✅ Marketplace feed (`v_loan_listings`) stays exactly as-is — funded %, offer count, time left, all public
- ✅ Listing detail becomes tiered: aggregate signals for everyone, exact offer terms only for participants
- ❌ No full lock-down — visitors and non-participating Lender/Pro users still see enough to gauge how competitive a request is
- ❌ No permanent full exposure — copying another offer-maker's exact price without doing your own risk assessment is no longer possible without first placing a bid

### Mental model shift

| Old model (Stage 2) | New model (Stage 4) |
|---|---|
| "Anyone viewing a listing sees every offer's exact terms" | "Anyone viewing a listing sees the shape of the market; only participants see exact terms" |
| Transparency = fully public | Transparency = **selective**, tied to participation |
| Offer detail is a UI concern | Offer detail is an RLS/RPC concern — enforced at the data layer |

### Visibility tiers

| Viewer | Sees on `LoanDetailPage` |
|---|---|
| **Visitor / any logged-in user, not yet bid** | Funded % progress bar, `number_of_offers`, `offer_coverage_tier` (`low` / `medium` / `high`), full request summary (amount, purpose, district, duration, repayment plan), and public trust badges for the request owner |
| **Lender/Pro-plan holder browsing, has not offered on *this* listing** | Same as a visitor — plan alone does not unlock offer detail; placing an offer does |
| **Offer-maker who has placed an offer on this listing** | Everything above, **plus** exact amount, interest rate, late fee, and repayment schedule for every offer on this listing, plus public trust badges for each competing offer-maker |
| **Request owner** | Full detail on every offer received: exact amount, interest rate, late fee, repayment schedule, timestamp, plus each offer-maker's public trust badges (and, if the owner is Pro, each offer-maker's advanced trust insights) |

Contact details are a separate boundary and stay locked for **everyone**, at every tier, until contract generation + unlock — this model only changes *offer-term* visibility, not identity. Public trust badges are a third, independent boundary — see "Trust & Reputation System" below — visible at every tier regardless of participation, because reputation is not a competitive-position signal the way offer terms are.

### Why tiered, not fully public or fully locked

1. **Fully public exact terms** let offer-makers copy-price off each other (undercut by a token amount without doing their own risk assessment) and let outsiders read a request owner's negotiating position without ever participating
2. **Fully locked terms** remove the market signal lenders need to decide whether a listing is worth competing on, which suppresses offer volume
3. **Participation-gated detail** rewards engagement, keeps competition on substance rather than copying, and creates a natural in-product nudge toward the Lender plan ("Place an offer to see full bid detail on this listing")

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
    offer_coverage_tier: compute_tier(offers)   -- low / medium / high, anonymized aggregate
  }
```

This logic lives in `get_public_listing_offers(request_id)` and the `v_lender_offers` view (RLS-scoped), **not** in the Flutter client — a non-participant calling the RPC directly gets the same reduced payload as one browsing the UI.

### Data model impact

- `v_loan_listings` gains a derived `offer_coverage_tier` column (public, anonymized, computed from the same request's `loan_offers` rows) alongside the existing `number_of_offers`
- `v_lender_offers` becomes participant-scoped via `security_invoker` + RLS: a row is only returned to the request owner or to an account with an offer on that `request_id`
- `get_public_listing_offers(request_id)` RPC is updated to branch on caller identity (owner / participant / neither) using the same logic as above, so Edge Functions and direct RPC callers can't bypass the tiering that the UI enforces

### What stays unchanged

- Marketplace feed fields and public request summary fields (title, amount, duration, purpose, district, repayment plan) — unaffected by this model
- Contact-reveal flow and its RPC-level enforcement — unaffected; still gated strictly behind contract generation
- Public trust badges — unaffected by this model; they render at every visibility tier

---

## 🌟 Trust & Reputation System (v4.1 — governs counterparty credibility, separate from deal-term visibility)

Early product feedback flagged that Nipanze's plan tiers (Free / Lender / Pro) describe *capability* well but say nothing about *credibility* — a Free user browsing the marketplace has no way to judge whether a request owner or offer-maker is a reliable counterparty before ever engaging. This section defines a public reputation layer to close that gap, and a Pro-tier verification/insight layer to monetize it responsibly.

### The decision

- ✅ Baseline trust signals (rating, review count, completed-deal count, repeat-participant badge, phone-verified badge, response-time bucket) are **public to every user on every plan** — never a pricing-table line item, never gated behind a plan check
- ✅ Pro-tier adds **verification weight** (full KYC-based "Verified" badge) and **analytical depth** (success rate, reliability score) on top of the same public data — it does not create a second, hidden trust system
- ❌ Trust signals never claim to measure off-platform repayment behavior — Nipanze does not track repayments (see Architecture Constraints), so every signal is built strictly from on-platform events: requests posted, offers made, contracts generated, reviews left after a completed contract

### Why public, not paywalled

A marketplace with hidden reputation data doesn't function — new users need proof that other participants are real and reliable before they'll risk posting a request or placing an offer. Locking ratings, review counts, or deal history behind a subscription would suppress activity for everyone, including paying users, since a Lender/Pro account still needs to evaluate *other* people's trust signals to decide who to fund. So:

- 🔓 **Trust = public reputation system** — visible regardless of plan
- 💰 **Paid plans = visibility + verification + analytical advantage system** — Pro doesn't unlock reputation, it strengthens and interprets it

### What's public (Free — every profile, every plan)

| Signal | Computed from | Rendered as |
|---|---|---|
| ⭐ Rating average + review count | `reviews` table, one review per completed contract per direction | Star rating + count, e.g. "⭐ 4.7 (18 reviews)" |
| 📊 Completed deals count | Count of `contracts` the account has been a party to | "📊 9 successful deals" |
| 🔁 Repeat participant badge | Second completed contract onward | "🔁 Repeat Borrower" / "🔁 Repeat Lender" depending on which side of the most recent deal |
| 📱 Phone verified badge | `profiles.phone_verified_at` set at OTP verification, signup-time | "📱 Phone verified" |
| ⏱️ Typical response time | Rolling median time-to-first-action, bucketed (not exact) | "⏱️ Responds quickly" |

These render as a compact badge row on `ListingCard`, the offers panel, and `ProfilePage` — the same shared component, `TrustBadgeRow`, everywhere a counterparty appears, so the signal is consistent across the app.

```
John K.
⭐ 4.7 (18 reviews)
🔁 Repeat Borrower
📊 9 successful deals
📱 Phone verified
⏱️ Responds quickly
```

Note the deliberate framing on the last line: the badge says **"Phone verified"**, not the phone number itself — verification status is public, the underlying contact detail stays locked behind the existing contact-reveal flow. This is consistent with the platform's existing controlled-contact-sharing principle; trust badges never leak the data they attest to.

### What's monetized (Pro tier)

| Enhancement | Description | Why Pro, not Free |
|---|---|---|
| 🟦 Verified badge | Awarded after full KYC review (existing `kyc_verifications` approval flow) | Stronger than the free phone-verified badge because it's backed by ID review, not just an OTP; the review cost/effort justifies gating it behind Pro |
| 📊 Success rate | Share of an account's offers accepted, or requests that reached contract, computed from on-platform events | Interpretive analytics, not raw reputation data — Free users still see the raw counts (completed deals, ratings) that this rate is derived from |
| 🔍 Reliability score | Single derived score combining rating, completion count, and response time | A convenience summary of already-public data, not new information — appropriate as a paid-tier UX enhancement, not a data-access gate |
| 🚀 Priority visibility | Pro-posted requests and Pro offer-maker profiles get improved placement | Existing Pro benefit, reinforced by the verified badge appearing alongside it |

This table is intentionally scoped to **interpretation and verification weight**, not to withholding raw trust data — see "Guardrail" below.

### Guardrail: what must never be paywalled

- ❌ Never hide star ratings, review counts, or completed-deal counts behind a plan
- ❌ Never hide the repeat-participant or phone-verified badges behind a plan
- ❌ Never display or compute a signal that implies knowledge of off-platform repayment behavior (e.g. "on-time repayment rate") — Nipanze has no visibility into money movement after contact reveal, so any such claim would misrepresent the platform's actual knowledge and conflicts with the Regulatory Compliance boundary
- ❌ Never let Pro purchase a *fabricated* trust signal (e.g. a boosted rating) — Pro only adds a verification badge (backed by real KYC) and analytics derived from real, existing data

### Reviews

- Left only by the counterparty on a **completed contract** — one review per contract, per direction (so a single deal can produce up to two reviews, one from each side)
- 1–5 star rating plus optional short text
- Immutable once submitted, logged to `audit_logs`
- Moderated the same way KYC documents are — visible to admins for abuse review (Stage 5), never edited by the platform itself
- `submit_review(contract_id, rating, comment)` RPC validates server-side that the caller was actually a party to that contract before writing, and triggers `recompute_trust_aggregates(user_id)` on the counterparty afterward

### Data model impact

- New `reviews` table: `id`, `contract_id`, `reviewer_id`, `reviewee_id`, `rating` (1–5), `comment` (nullable, short text), `created_at` — unique constraint on `(contract_id, reviewer_id)` to enforce one review per contract per direction
- `profiles` gains `phone_verified_at` (nullable timestamp)
- New cached aggregate columns (or a dedicated `trust_aggregates` table, TBD at implementation time) holding `rating_avg`, `review_count`, `completed_deals_count`, `is_repeat_participant`, `response_time_bucket` per user, refreshed by `recompute_trust_aggregates(user_id)` on relevant events (new review, new completed contract)
- New view `v_trust_profile_public` — readable by any authenticated user, returns the Free-tier signal set for a given `user_id`
- New view `v_trust_profile_pro` — RLS-scoped to callers whose own `subscription_plan = 'pro'`, returns `success_rate` and `reliability_score` for a given `user_id` on top of the public set

### 💰 Contact-unlock fee — flagged as an open decision, not yet committed

Product feedback also proposed a flat, per-unlock contact fee (a few thousand UGX) charged at the moment contact is revealed, free or discounted for Pro, as a second revenue engine alongside subscriptions. This is **not folded into the committed Stage 4 scope**, because it changes two things currently treated as fixed elsewhere in this plan and in the README:

1. The stated principle that Nipanze earns **"revenue through subscriptions — not interest spreads — via a single upgrade path"** would need to explicitly become "subscriptions plus a flat, disclosed contact-unlock fee"
2. `reveal_contact` today is purely **status-gated** (owner has accepted an offer → both parties may unlock) — a paid unlock means adding a payment-confirmation step in front of the existing unlock logic, plus a payment provider integration that doesn't otherwise exist in this stack

**If this is adopted**, the fee must stay flat and disclosed up front — never a percentage of loan amount, interest rate, or deal outcome — to remain consistent with the "no fee tied to loan performance" principle in Regulatory Compliance. It is tracked here as a **Stage 4 decision point** requiring an explicit go/no-go before implementation, rather than assumed into the checklist below. Recommendation: ship the trust system and selective transparency first (both reinforce trust and offer-making without touching money), then revisit contact-unlock pricing once there's real usage data on how often contact reveal happens.

### 💵 Pricing note (flagged, not changed)

Product feedback separately suggested the (previously undocumented) Pro price point may be too high for the target Uganda early-stage market, and recommended validating actual subscription pricing against local willingness-to-pay before Stage 6 launch. This build plan does not currently commit to specific UGX figures for any tier — pricing is a business decision to be finalized closer to Stage 6 (Launch & Growth) with real market input.

---

## 🎯 Pro Advanced Marketplace Filters (v4.2)

Pro-tier users can access advanced filtering controls on the marketplace feed to find listings matching specific borrower profile attributes or listing status details.
- **Employment type filter:** Filter borrower profiles by categorical type (e.g. `government_employee`, `employed`, `self_employed`, `small_business_owner`, `business_owner`, `student`, `other`).
- **Income bracket filter:** Filter borrower profiles by a coarse monthly income bracket (using `fn_income_bracket`: `under_2m`, `2m_5m`, `5m_10m`, `over_10m`).
- **Suggested terms filter:** Limit the feed to requests carrying suggested terms locked by a Pro poster at publish time.
- **Verified status filter:** Limit the feed to requests from KYC-approved owners.

This capability is gated at the DB layer via the `v_marketplace_pro_filters` view (which checks for an active Pro subscription and returns zero rows if absent) and the `get_marketplace_pro_filtered` RPC. In the UI, the filters are presented via an entry icon button next to the notification bell (Option B) opening a bottom sheet, gated strictly to Pro users.

---

## 🌍 Multi-Country Expansion Model (v5.0)

### Scope: the full East African Community (EAC)

Nipanze's multi-country model targets **all eight EAC member states**, not just a Uganda→Kenya expansion. The schema, RLS, and seed data described below are designed to support all eight from day one of the Stage 4.5 migration — launch sequencing (which markets go `is_active = TRUE` and when) is a Stage 6 business decision, but the data model itself does not treat any one of them as a special case.

### EAC Country Reference

| Country | ISO Code | Currency | Currency Code | Phone Prefix | Capital |
|---|---|---|---|---|---|
| 🇺🇬 Uganda | `UG` | Ugandan Shilling | `UGX` | `+256` | Kampala |
| 🇰🇪 Kenya | `KE` | Kenyan Shilling | `KES` | `+254` | Nairobi |
| 🇹🇿 Tanzania | `TZ` | Tanzanian Shilling | `TZS` | `+255` | Dodoma |
| 🇷🇼 Rwanda | `RW` | Rwandan Franc | `RWF` | `+250` | Kigali |
| 🇧🇮 Burundi | `BI` | Burundian Franc | `BIF` | `+257` | Gitega |
| 🇸🇸 South Sudan | `SS` | South Sudanese Pound | `SSP` | `+211` | Juba |
| 🇨🇩 DR Congo | `CD` | Congolese Franc | `CDF` | `+243` | Kinshasa |
| 🇸🇴 Somalia | `SO` | Somali Shilling | `SOS` | `+252` | Mogadishu |

> DR Congo and Somalia are the two most recent EAC accessions — both are included in the reference table and seed data for schema completeness, but should stay `is_active = FALSE` until each market's KYC document types, payment-rail coverage (Flutterwave/Paystack/DPO support varies by country — verify per market before activating), and compliance review are confirmed at Stage 6. Currency and phone-prefix data doesn't change based on activation status, so there's no reason to leave them out of the seed.

### The decision

- ✅ **One database, one set of tables, shared across every EAC country** — `profiles`, `loan_requests`, `loan_offers`, `watchlist`, `reviews`, etc. all stay as single tables
- ✅ Every row that represents a person or a listing carries a `country` code (ISO 3166-1 alpha-2, one of the eight in the reference table above)
- ✅ A new small `countries` reference table holds display name, currency code, phone prefix, and an `is_active` flag per market — seeded with all eight EAC countries, regardless of which are launched yet
- ❌ **No per-country tables** (`loan_requests_uganda`, `loan_requests_kenya`, …) — rejected explicitly, see rationale below
- ❌ **No per-country Supabase projects/databases** — rejected for the same reason; it would mean re-implementing every RLS policy, trigger, and RPC per country and losing the ability to run one cross-market admin view

### Why one shared table, not one table per country

A separate-table-per-country design was raised during planning and rejected:

1. **Every RLS policy, trigger, view, and RPC in this schema would need to be duplicated per country** — `get_public_listing_offers`, `accept_offer`, `v_loan_listings`, the trust-aggregate trigger, all of it. That's N× the maintenance surface for every future feature, forever.
2. **Cross-country admin reporting becomes a UNION-of-N-tables exercise** instead of one `GROUP BY country`.
3. **Adding a new country today means writing a migration**, not inserting a row into `countries` and updating one `CHECK` constraint.
4. A single indexed `country` column on an already-indexed table (`loan_requests`, `profiles`) scales to millions of rows per market without needing physical table separation — Postgres doesn't need help here at Nipanze's expected scale.

### Country as a first-class, indexed column — not a derived guess

`country` is stored explicitly on `profiles` (source of truth for a user) and on `loan_requests` (source of truth for a listing). It is **not** re-derived per-query from phone prefix or IP — those are only used as a *default suggestion* at signup, never as the enforced value:

| Signal | Role |
|---|---|
| `profiles.country` | Source of truth once set. Required, not nullable, after onboarding completes. |
| Phone prefix (`+256` → UG, `+254` → KE, `+255` → TZ, `+250` → RW, `+257` → BI, `+211` → SS, `+243` → CD, `+252` → SO) | Onboarding-time **default suggestion** only — user can override before confirming. Note `+243` (DR Congo) and a few others are multi-digit country codes with regional overlaps in raw dialing habits, so this remains a suggestion, never an enforced value — same principle as every other prefix. |
| GPS / IP geolocation | Optional, same role as phone prefix — a suggestion, never silently trusted |
| `loan_requests.country` | Copied from `profiles.country` of the borrower **at creation time**, via trigger — see below |

> **Why copy `country` onto `loan_requests` instead of joining to `profiles.country` on every query?** Two reasons: it lets the marketplace feed filter and index on `loan_requests.country` directly without a join, and it freezes the listing's country at post time — if a user's profile country is later corrected (e.g. they fix a mistake at signup), it shouldn't silently move an already-published listing into a different market's feed.

### `loan_offers` inherits country from its request — never stored independently

An earlier draft considered adding `country` directly to `loan_offers` as well. **Rejected:** an offer's country is entirely determined by the request it's offering on (`loan_offers.request_id → loan_requests.country`). Storing it a second time on the offer row creates a value that can drift from its source of truth for no benefit — every query that needs an offer's country already has to join `loan_requests` for the listing details anyway. `loan_offers` gets no new column; country is read through the join.

This also means a lender in Kenya cannot be blocked from making an offer on a Ugandan listing at the database layer just because their `profiles.country = 'KE'` — see "Cross-border offers" below for whether that should be allowed at all.

### New table: `countries`

```sql
-- countries (conceptual)
code            TEXT PRIMARY KEY   -- ISO 3166-1 alpha-2
name            TEXT NOT NULL
currency_code   TEXT NOT NULL      -- ISO 4217
phone_prefix    TEXT NOT NULL      -- used for onboarding suggestion only, never enforced
is_active       BOOLEAN NOT NULL DEFAULT FALSE  -- gates whether new listings can be posted in this market
created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP

-- seed: all 8 EAC member states, seeded together, activated independently
-- ('UG',  'Uganda',       'UGX', '+256', TRUE)   -- existing market, active at migration time
-- ('KE',  'Kenya',        'KES', '+254', FALSE)
-- ('TZ',  'Tanzania',     'TZS', '+255', FALSE)
-- ('RW',  'Rwanda',       'RWF', '+250', FALSE)
-- ('BI',  'Burundi',      'BIF', '+257', FALSE)
-- ('SS',  'South Sudan',  'SSP', '+211', FALSE)
-- ('CD',  'DR Congo',     'CDF', '+243', FALSE)
-- ('SO',  'Somalia',      'SOS', '+252', FALSE)
```

`profiles.country` and `loan_requests.country` are both `TEXT NOT NULL REFERENCES countries(code)`. Launching a new market becomes: `UPDATE countries SET is_active = TRUE WHERE code = 'KE'`, no migration required, since the row already exists. Pausing a market (e.g. for compliance review) is the same statement in reverse — new listings blocked, existing ones and history untouched. Seeding all eight up front (rather than inserting each one only at its own launch) means onboarding's country-select dropdown, admin's per-country settings screen, and any country-aware UI never need a schema change to add a market — only a flag flip plus the Stage 6 launch-readiness items (pricing, KYC document types, payment-rail coverage) called out per country below.

### Currency travels with country — never assume UGX again

`requested_amount`, `repayment_amount_per_period`, `offer_amount`, and every other monetary figure are **plain `BIGINT` minor-unit-free numbers with no currency of their own** — they are only meaningful alongside the row's `country → countries.currency_code`. Concretely:

- The marketplace feed, listing detail, and offer views must all resolve and display `countries.currency_code` next to every amount (via a join or a denormalized `currency_code` column on `v_loan_listings` / `v_lender_offers` for query simplicity)
- **A UGX 5,000,000 request and a KES 5,000,000 request are not comparable** — nor are any two amounts across any two of the eight EAC currencies (`UGX`, `KES`, `TZS`, `RWF`, `BIF`, `SSP`, `CDF`, `SOS`). The app must never sum, average, or rank amounts across countries without currency-aware conversion (out of scope for now — Nipanze does not do currency conversion; see "What this does not include" below). This applies equally to admin cross-market KPI views (`v_marketplace_activity`) — a "total requested" figure across markets is either broken down per currency or omitted, never silently summed as if all currencies were the same unit.
- `system_settings` limits like `min_loan_amount` / `max_loan_amount` are currently single global values in UGX. Under v5.0 these become **per-country**, either as a new `country_settings(country, setting_key, setting_value)` table or by adding a `country` column to `system_settings` with a composite unique key on `(setting_key, country)` — recommendation: the latter, since it reuses the existing table and admin UI with one extra filter column, rather than standing up a parallel settings table

### Marketplace filtering — server-enforced, not just a UI filter

The core behavior requested: a Kenyan user sees Kenyan listings, a Ugandan user sees Ugandan listings. This is implemented at **two layers**, matching how every other access rule in this schema works — never trusted from the client alone:

**1. Application-level default filter** — `MarketplaceRepository` queries `v_loan_listings WHERE country = :userCountry` by default. This is the normal, fast path and is what powers the live feed and Realtime stream.

**2. RLS-level boundary (optional, policy decision — see "Open decision" below)** — whether a user can query `v_loan_listings` for a country *other than their own* at all. Two options:

   - **Global browse (recommended default):** any authenticated user can query any EAC country's public marketplace feed (useful for a diaspora Ugandan living in Kenya who wants to fund a request back home, a Rwandan lender comparing opportunities across the region, or any cross-border movement common within the EAC's integrated labor and trade market) — the app just *defaults* to the user's home country and lets them switch. RLS stays as-is (`status = 'active' OR owner OR admin`), with `country` as a plain filterable column, not an access boundary.
   - **Hard country isolation:** RLS itself blocks cross-country reads.

> **Important correction to the naive "put country in the JWT" pattern:** two versions of this have come up, and both have a problem for RLS specifically:
> 1. `auth.jwt() ->> 'country'` reading a **top-level custom claim** — this is `NULL` unless a **custom access token hook** is configured in Supabase Auth to inject it. Real, but extra infrastructure this plan doesn't currently assume.
> 2. `auth.jwt() -> 'user_metadata' ->> 'country_code'` reading **`user_metadata`** (set via `supabase.auth.updateUser({ data: { country_code: 'UG' } })`) — this *does* work with zero extra setup, since Supabase already embeds `user_metadata` in every JWT. But `user_metadata` is **client-writable by the user it belongs to**. Any authenticated user can call `updateUser` themselves and set `country_code` to whatever they like, which means an RLS policy built on it isn't actually enforcing anything — it's trusting client input at one extra layer of indirection. (`app_metadata`, by contrast, is server-only and would work, but setting it requires a service-role call on every country change, which is more moving parts than needed here.)
>
> The realistic, zero-extra-infrastructure, non-spoofable RLS equivalent is a subquery against `profiles` — the same pattern this schema already uses for `private.is_admin()`:
> ```sql
> USING (
>   country = (SELECT country FROM profiles WHERE id = auth.uid())
>   OR private.is_admin()
> )
> ```
> This plan **recommends global browse, not hard isolation**, for the reason above (diaspora lending is a realistic and valuable use case for a matchmaking marketplace), but the subquery pattern above is documented here so that hard isolation is a one-policy change if product direction changes later — not a redesign.

### Cross-border offers — open decision, not yet committed

Whether a lender registered in one EAC country should be allowed to make an offer on a listing posted in another is a **product decision, not a technical constraint** — the schema supports either answer, and supports it uniformly across all eight countries rather than needing a special case per country pair:

- **If allowed:** no change needed beyond what's described above; `trg_fn_validate_offer` doesn't need a country check.
- **If disallowed (single-market offers only):** add one clause to `trg_fn_validate_offer`: reject if `(SELECT country FROM profiles WHERE id = NEW.lender_id) != v_listing.country`.

Recommendation: launch with cross-border offers **allowed** across the EAC (simpler, and it's a genuine value-add — diaspora capital is common throughout the region: Ugandan capital funding Ugandan requests from a Kenya-registered account, Rwandan capital funding Rwandan requests from a Tanzania-registered account, and so on), and revisit only if fraud/compliance review in Stage 5 flags a specific reason to restrict it per market. Note this decision is currency-neutral either way — an offer's currency always matches its listing's currency (via the `loan_offers → loan_requests.country` join), regardless of what country the offer-maker is registered in.

### Trust & Reputation aggregates stay global per user, not per-country

`trust_aggregates` (rating average, completed-deal count, response-time bucket, etc.) remain **one row per user, not one row per user per country**. Rationale: reputation is about *this specific person's* reliability as a counterparty, and that doesn't reset at a border — a lender who has completed 9 deals in Uganda and is now browsing Kenyan listings for the first time should show up with their real track record, not a blank slate. If a future need arises to show "deals completed *in this market*" as an additional, separate signal, that's an **additive** column (`completed_deals_in_country`), not a replacement for the global aggregate — flagged here as a possible v5.1 enhancement, not committed.

### 💳 Payments Infrastructure (Flutterwave) — scoped addendum

Multi-country makes one thing unavoidable: subscriptions and any future contact-unlock fee need to be **charged and settled in the payer's own currency**, across multiple mobile-money and card rails. Flutterwave (or a comparable regional aggregator — Paystack and DPO cover overlapping but not identical country sets) is a reasonable fit for exactly this reason: one API surface across mobile money (MTN, Airtel, M-Pesa, etc.) and cards, instead of Nipanze integrating each provider per country directly.

**Rail coverage is not uniform across all eight EAC countries and must be verified per market before activation** — Uganda, Kenya, Tanzania, and Rwanda have mature, well-covered mobile-money rails through Flutterwave and comparable aggregators. Burundi, South Sudan, DR Congo, and Somalia have thinner or partial coverage on most regional aggregators as of this writing, and each has different regulatory and sanctions-screening considerations that need dedicated review — this is exactly why `countries.is_active` exists as a per-market gate independent of whether the row itself has been seeded. A country should never be flipped to `is_active = TRUE` in Stage 6 until its specific payment-rail coverage has been confirmed, not assumed from the fact that three of its neighbors already work.

**Critical scope boundary — this must not be confused with the loan itself:**

- ✅ In scope for payment integration: **Nipanze's own revenue** — `subscriptions` (Lender/Pro plan payment) and, if the open decision above is ever resolved to "yes," the flat contact-unlock fee
- ❌ **Never** in scope: any money between a borrower and a lender. Loan principal, interest, and repayment stay **entirely off-platform**, exactly as stated in Architecture Constraint #1 (no fund movement). Adding Flutterwave for subscriptions does **not** change Nipanze's non-custodial positioning — it's Nipanze charging its own customers for its own service, not touching P2P loan funds. This boundary should be stated explicitly in any Stage 5/6 payments documentation so it's never ambiguous to a reviewer, regulator, or future engineer that these are different things.

**New table: `transactions`**

```sql
-- transactions (conceptual)
id                  UUID PRIMARY KEY
user_id             UUID NOT NULL REFERENCES profiles(id)
type                TEXT NOT NULL   -- 'subscription' | 'contact_unlock'
amount              BIGINT NOT NULL
currency_code       TEXT NOT NULL REFERENCES countries(currency_code)
country             TEXT NOT NULL REFERENCES countries(code)   -- payer's country at time of charge
provider             TEXT NOT NULL DEFAULT 'flutterwave'
provider_tx_ref      TEXT NOT NULL UNIQUE   -- idempotency key Nipanze generates and sends to Flutterwave
provider_tx_id       TEXT                    -- Flutterwave's own reference, populated on webhook confirm
status               TEXT NOT NULL DEFAULT 'pending'  -- 'pending' | 'successful' | 'failed' | 'reversed'
related_subscription_id UUID REFERENCES subscriptions(id)
related_reveal_id       UUID REFERENCES contact_reveals(id)
webhook_verified_at TIMESTAMP   -- set only after the webhook signature check passes — never trust the client-side redirect alone
created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
```

Design notes that matter more than the table itself:

- **`provider_tx_ref` is generated by Nipanze, not Flutterwave**, before the charge is initiated, and is what makes retries and webhook replays idempotent — insert the `pending` row first, then call Flutterwave with that ref, then only ever transition status on a verified webhook, never on the client's post-payment redirect (a user closing the app or losing signal right after paying should never be able to fake success, and a page reload should never double-charge or double-grant a plan)
- **The webhook handler is the only writer of `status = 'successful'`**, runs as an Edge Function with the Flutterwave secret hash verified against the request signature before anything else happens, and is idempotent on `provider_tx_ref` (a resend of the same webhook must not grant a second subscription period)
- **`provider` is a plain text column, not an enum**, specifically so a second processor can be added later (e.g. a card-only fallback, or a different aggregator for a market Flutterwave doesn't cover well) without a schema migration
- Upgrading a user's `subscriptions.plan` happens **only after** `transactions.status = 'successful'` — never optimistically on redirect — so a failed or abandoned payment can never leave someone with Lender/Pro access they didn't pay for
- RLS: same pattern as everything else in this schema — `user_id = auth.uid() OR private.is_admin()` for read; all writes happen through the service-role Edge Function, never directly from the Flutter client

**Sequencing relative to the rest of Stage 4.5/6:** payments infrastructure does not need to ship with the country migration itself — `countries`, `profiles.country`, and `loan_requests.country` are useful and shippable with subscriptions still handled exactly as they are today (manual/off-platform, per the existing `AccountPage` "upgrade flow (off-platform)" note in Stage 3). Flutterwave integration is realistically a **Stage 6 (Launch & Growth)** item, once pricing per market is finalized — since building payment infrastructure before pricing is decided means building it twice.

### What this does not include (explicitly out of scope for v5.0)

- ❌ **Currency conversion or cross-currency comparison** — Nipanze displays each listing in its own market's currency and does not convert between them
- ❌ **Per-country subscription pricing localization logic** beyond what Stage 6's pricing research already flags — `subscriptions.amount_ugx` should be renamed/generalized (`amount_minor_units` + implied currency from the user's country) as part of this migration, but actual per-market price points remain a Stage 6 business decision
- ❌ **Language localization** — a separate, unrelated effort not addressed here
- ❌ **Country-specific KYC document types** (e.g. Kenyan ID vs Ugandan national ID formats) — `kyc_verifications.national_id_type` already exists as free text and can absorb this without a schema change; validation rules per country are an app-layer concern for later
- ❌ **P2P loan payment processing of any kind** — see the payments scope boundary immediately above; Flutterwave, if adopted, touches subscriptions and unlock fees only, never a loan between two users

### Data model impact summary

| Table | Change |
|---|---|
| `countries` | **New table** — `code`, `name`, `currency_code`, `phone_prefix`, `is_active` |
| `profiles` | **+ `country` column**, `TEXT NOT NULL REFERENCES countries(code)`, default set at onboarding |
| `loan_requests` | **+ `country` column**, `TEXT NOT NULL REFERENCES countries(code)`, set by trigger from `profiles.country` at insert, immutable after (same "locked at post time" pattern already used for terms) |
| `loan_offers` | **No new column** — country is read via `loan_requests.country` through `request_id` |
| `system_settings` | **+ `country` column** (nullable = global default, non-null = per-country override), composite unique on `(setting_key, country)` |
| `subscriptions` | `amount_ugx` → rename to `amount_minor_units`; currency implied by the subscriber's `profiles.country` |
| `v_loan_listings` | **+ `country`, + `currency_code`** (joined from `countries`) |
| `v_lender_offers` | **+ `country`, + `currency_code`** (joined through `loan_requests` → `countries`) |
| `v_marketplace_activity` | **+ `country` grouping** — admin KPIs become sliceable per market, not just global |
| `trust_aggregates` | **Unchanged** — stays global per user (see above) |
| `transactions` | **New table, Stage 6** — Flutterwave (or equivalent) payment records for subscriptions and contact-unlock fees only; never P2P loan funds — see Payments Infrastructure above |

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

> Unaffected by v5.0 — no country concept existed yet, which is expected for a foundation stage.

---

## Stage 2 — Core Marketplace ✅ Complete

### 2.1 Marketplace Feed
- [x] `MarketplaceRepository` — `v_loan_listings`, filters, Realtime stream
- [x] `MarketplaceCubit` — live feed with Realtime refresh
- [x] `MarketplacePage` — filter pills, `ListingCard`, skeleton, live dot
- [x] `LoanDetailPage` — listing detail, income + repayment plan display, offers panel

### 2.2 Loan Requests (Free tier and above)
- [x] `ListingCreatePage` — 3-step form: loan details → income/repayment context → review & publish
- [x] Form fields: title, purpose, amount, duration, district, income source, preferred repayment plan (`weekly`, `monthly`, `one_time`), repayment amount per period, repayment timeline
- [x] Basic request form does not require interest rate; lenders propose interest/return expectations in offers
- [x] `SystemSettingsRepository` — fetches public limits from DB; cached singleton; form validators use live values
- [x] `MyRequestsPage` + `MyRequestsCubit` + `RequestRepository` — real data, Realtime, cancel with confirm
- [x] Contracted request banner redirects to Positions tab
- [x] Request tab → direct to `ListingCreatePage` (no intermediate page)

### 2.3 Loan Offers (Lender tier and above — Subscription Required)
- [x] `OfferRepository` — `makeOffer`, `withdrawOffer`, Realtime stream on offers for a listing
- [x] Offer terms carry offer amount and proposed expectations, including any interest/return expectation
- [x] `LoanDetailPage` — live Realtime offers panel, glow flash on new offer
- [x] Subscription gate modal — plan cards (Free / Lender / Pro), upgrade navigates to Account
- [x] `KycVerification` model + `KycRepository` — Storage uploads, `submitForReview`
- [x] `KycCubit` — per-doc upload state, error preserves data
- [x] `KycPage` — camera/gallery picker, 3 doc tiles, submit gating, rejection reason banner

> Note: in Stage 2 the offers panel on `LoanDetailPage` showed every offer's exact terms to any viewer. Stage 4 replaces this with the **Selective Transparency Model** above — full exact-term detail becomes participant-gated, while the aggregate signal (offer count + coverage tier) stays visible to everyone. Stage 4 additionally layers the **Trust & Reputation System** above on top of every listing and profile, independent of that tiering.

### 2.4 Offer Acceptance
- [x] `accept_offer` RPC called from the request-owner side on `LoanDetailPage`
- [x] Rejected offers notified to losing offer-makers
- [x] Listing moves to `contracted` status; removed from live feed
- [x] `WatchlistButton` on detail page — toggles DB save, filled star when saved

### Stage 2 Exit Criteria
- [x] Any user (Free+) can post a free request and receive offers
- [x] Any user with an active Lender/Pro plan can browse and make offers with their own amount and terms
- [x] Request owner can accept one offer; all others auto-rejected
- [x] Live feed and offers panel refresh via Realtime
- [x] Subscription gate blocks offer placement for Free-plan users
- [x] App stable on Android APK (arm64), web, and Linux desktop

> **Stage 4.5 note:** once the multi-country migration lands, `MarketplaceRepository` and `v_loan_listings` gain the `country` filter described in the Multi-Country Expansion Model above — this is an additive change to already-shipped Stage 2 code, not a rebuild.

---

## Stage 3 — Polish & Supporting Features ✅ Complete

### 3.1 Watchlist
- [x] `WatchlistItem` model — integrated into `WatchlistLoaded` state
- [x] `WatchlistRepository` — `getWatchlist`, `getWatchedListings`, `watchWatchedListings` Realtime stream
- [x] `WatchlistCubit` — optimistic remove with Realtime updates
- [x] `WatchlistCard` — urgency border (red 6h / amber 24h), offer count, View listing, remove button
- [x] `WatchlistPage` — displays watched listings with active/closing-soon grouping, empty state, skeleton loading
- [x] "Save to watchlist" on `LoanDetailPage` writes to DB; toggles star icon

### 3.2 Positions
- [x] `LenderOffer` model from `v_lender_offers`
- [x] `PositionsRepository` — `getMyOffers`, `withdrawOffer`, `getMyRequests`, `watchMyOffers` Realtime
- [x] `PositionsCubit` — loads requests + offers; Realtime offer updates; optimistic withdraw
- [x] `LenderOfferCard` — status badge, View listing, Withdraw button with confirm dialog
- [x] `PositionsPage` — 2 tabs:
  - **My Requests** — requests you've posted: active, contracted, and expired
  - **My Offers** — offers you've made, grouped Pending / Accepted / History; withdraw button live
- [x] Portfolio summary drives subtitle (active offers count, active requests count)

> Note: "My Requests" and "My Offers" are simply two views of the same account's activity — not two roles. A single user can have entries in both tabs simultaneously. Positions is always a **participant** view, so it's unaffected by the Stage 4 selective-transparency tiering — a user always sees full detail on their own requests and their own offers. Trust badges on counterparty listings/offers within Positions are unaffected either way, since they're public. Also unaffected by country — Positions is already scoped to `auth.uid()`, and watched/owned listings simply carry whatever `country` they were posted with.

### 3.3 Notifications
- [x] `NotificationRepository` — reads `notifications` table, marks as read, Realtime stream
- [x] `NotificationCubit` — unread count tracking, Realtime subscription, optimistic mark-as-read
- [x] `NotificationsPage` — chronological display, grouped by type, deep-link navigation
- [x] Unread badge on bottom nav Account tab (red dot with count)
- [x] In-app notifications loaded via Realtime stream

### 3.4 Profile & Account
- [x] `ProfilePage` — editable name, district, employment; live fetch from `profiles`
- [x] `AccountPage` — live subscription data; upgrade flow (off-platform)
- [x] `ThemeMode` persisted via `SharedPreferences`

### 3.5 Error & Empty States
- [x] `OfflineBanner` — shown when Supabase connectivity lost
- [x] Loading skeletons throughout the app (notifications, watchlist, marketplace)

### Stage 3 Exit Criteria
- [x] All 5 nav tabs functional with real data
- [x] Watchlist displays watched listings with Realtime updates
- [x] Positions accurately reflects requests posted and offers made by the account
- [x] Offer withdrawal works end to end
- [x] App stable on local dev with Supabase cloud project

---

## Stage 3.5 — Cloud Migration & Auth Hardening ✅ Complete

### Database — Schema & Data
- [x] Apply schema v4.0 to cloud project (`sql/schema.sql`)
- [x] Apply seed v2.0 to cloud project (`sql/seed.sql`) — 17 test accounts
- [x] Apply cloud patch (`sql/cloud_patch.sql`) — RLS + views + grants
- [x] Apply function security fix (`sql/fix_functions.sql`) — private schema wrapper pattern

### Storage
- [x] Create `verification-documents` bucket (private, 10 MB limit)
- [x] RLS on `storage.objects` — path-based ownership (`{user_id}/{filename}`)
- [x] Admins can read all KYC documents for review (Stage 5 ready)

### Security Hardening
- [x] `private` schema created; `private.is_admin()` isolated from API exposure
- [x] `accept_offer` and `reveal_contact` moved to SECURITY INVOKER wrappers (Security Advisor clean)
- [x] All 4 views recreated with `security_invoker = true` (`cloud_patch.sql`)
- [x] Append-only `audit_logs` enforced — no UPDATE/DELETE for `authenticated` role
- [x] `verification-documents` bucket is private — KYC docs never public
- [x] Service role key stays out of Flutter client — only in Edge Functions (Stage 5)

### RLS Audit (README field masking rules)
- [x] `v_loan_listings` — `borrower_id` (request-owner id) NOT exposed ✅
- [x] `v_loan_listings` — `income_source` NOT exposed (stays in `loan_requests` table) ✅
- [x] `v_loan_listings` — `phone`, `email`, `full_name`, `national_id` NOT exposed ✅
- [x] `v_lender_offers` — offer-maker's `phone`, `email`, `name` NOT exposed pre-reveal ✅
- [x] RLS on all 9 core tables — no row reachable by wrong user
- [x] `contact_reveals` accessible only to matched parties + admin

### Auth Hardening
- [x] Refresh token rotation enabled (Supabase Dashboard → Authentication → Settings)
- [x] JWT expiry: 3600 seconds; refresh token reuse interval: 10 seconds
- [x] "Prevent use of leaked passwords" enabled (Supabase Dashboard)
- [x] Refresh token rotation chain verified via `refresh_tokens` table (`replaced_by` column)

### Realtime
- [x] `loan_offers`, `loan_requests`, `notifications`, `contact_reveals`, `watchlist` in `supabase_realtime` publication

### Verification ✅ Complete
- [x] `stage-3.5-status.sql` — all 10 sections ✅ (schema, views, RLS, seed, storage, private schema, Realtime)
- [x] `stage-3.5-verify.sql` — all 11 sections ✅ (masking, security_invoker, append-only audit_logs enforced via `USING (false)`)

### App Testing ⏳ In Progress
- [/] End-to-end request-posting flow tested on cloud (web) — post request, browse, save watchlist
- [ ] End-to-end offer-making flow tested on cloud (web) — browse, make offer, withdraw offer
- [ ] KYC document upload verified (`verification-documents` bucket receives file)
- [ ] Release APK built (`flutter build apk --release --dart-define=...`)
- [ ] APK installed and tested on physical Android device (no crashes, logcat clean)

> **Finish this app-testing checklist before starting Stage 4.5**, so the multi-country migration lands on a verified-stable cloud baseline rather than stacking on top of untested changes.

---

## Stage 4 — Structured Deal Agreement, Contact Sharing & Trust System ⬜ Planned

Stage 4 redesigns how terms are agreed upon and introduces a **locked bidding system** where both the request owner and the offer-maker commit to terms upfront — eliminating unstructured back-and-forth before a contract is generated. It also introduces the **Selective Transparency Model** and the **Trust & Reputation System** (both above), replacing Stage 2's fully public offer book with participation-gated deal detail plus an always-public reputation layer.

See the schema (`sql/schema.sql`) for the authoritative, already-implemented definitions of `agreements`, `reviews`, `trust_aggregates`, `get_public_listing_offers`, `submit_review`, and `recompute_trust_aggregates` — these are unaffected by the country layer except that offer/listing detail now also carries `country` and `currency_code` for display.

### 🎯 Objective

> **"We connect the two sides of a deal, help them see who they're dealing with, agree on terms, then generate a contract — everything else happens offline."**

Core principles:
- Terms are **locked at the point of posting / bidding** — no editing after publish
- Both parties commit to their position independently
- A contract is generated when their terms match via acceptance
- Contact is revealed only after the contract is locked
- Exact offer terms are visible only to the request owner and to offer-makers who have bid on that listing; everyone else sees an aggregate coverage signal
- Public trust signals (rating, reviews, completed deals, badges) are visible to everyone regardless of participation or plan
- Neither party is a fixed "role" in the schema — capability comes entirely from `subscription_plan`

### 🔁 Flow Overview

```
REQUEST POSTED (locked on publish)
──────────────────────────────────────────
Amount needed
Duration
Purpose (optional)
[PRO ONLY] Suggested interest rate
[PRO ONLY] Suggested late payment fee (%)
[PRO ONLY] Suggested repayment schedule
──────────────────────────────────────────

LISTING DETAIL VIEWED (tiered — see Selective Transparency Model; trust badges always public)
──────────────────────────────────────────
Everyone: funded %, offer count, offer_coverage_tier, request owner's trust badges
Owner / participants only: exact offer amounts + terms + each offer-maker's trust badges
──────────────────────────────────────────

OFFER SUBMITTED (locked on submit — requires Lender or Pro plan)
──────────────────────────────────────────
Amount offered
Offered interest rate
Offered late payment fee (%)
Offered repayment schedule
→ submitting unlocks full offer detail on this listing for the offer-maker
──────────────────────────────────────────

CONTRACT GENERATED (after request owner accepts an offer)
──────────────────────────────────────────
Final terms locked
Digital contract created
Contact revealed to both parties
──────────────────────────────────────────

DEAL COMPLETES (off-platform)
──────────────────────────────────────────
Either party may submit one review of the other, tied to this contract
Review feeds both parties' public trust aggregates
──────────────────────────────────────────
```

### 📋 Request Posting — Term Suggestions (Pro-tier feature)

Pro-plan users can suggest preferred loan terms **at the time of posting**. Once published, these terms are **locked**.

| Field | Free | Lender | Pro |
|---|---|---|---|
| Amount needed | ✅ | ✅ | ✅ |
| Duration | ✅ | ✅ | ✅ |
| Purpose | ✅ | ✅ | ✅ |
| Suggested interest rate | ❌ | ❌ | ✅ |
| Suggested late payment fee | ❌ | ❌ | ✅ |
| Suggested repayment schedule | ❌ | ❌ | ✅ |

> **Why Pro?** A request with suggested terms carries negotiating leverage — it attracts offers already aligned with the poster's preferred terms. This is the core value of the Pro tier, available to anyone regardless of whether they've ever made an offer themselves. Pro's Verified badge and advanced trust insights reinforce the same "serious participant" positioning.

### 🏷️ Offer Submission — Term Setting (Lender plan and above)

When a user submits an offer, they set their own terms. They may align with the posted suggestions or propose different ones. Once submitted, the offer is **locked**.

| Field | Description |
|---|---|
| Amount offered | Full or partial of the requested amount |
| Interest rate | Offer-maker's required return |
| Late payment fee | % applied only to missed installment |
| Repayment schedule | Monthly / Weekly / One-time + installment amount |

> Offer-making requires at least the **Lender plan**. Maximising the pool of people who can make offers is essential for platform value, so Lender-tier pricing should stay accessible.

> Placing an offer on a listing also unlocks full offer-level detail (all offers' exact terms, plus every offer-maker's public trust badges) on that same listing for the offer-maker — see Selective Transparency Model.

### 🔍 Selective Transparency — Implementation Checklist

- [ ] `offer_coverage_tier` computed column/function added to `v_loan_listings` (derived from `loan_offers` for that `request_id`; `low` / `medium` / `high`)
- [ ] `v_lender_offers` scoped via RLS + `security_invoker` so a row returns only to the request owner or to an account with an offer on that `request_id`
- [ ] `get_public_listing_offers(request_id)` RPC branches on caller identity: owner/participant → full detail; everyone else → `number_of_offers` + `offer_coverage_tier` only
- [ ] `LoanDetailPage` UI reads the tiered payload and renders either the full offers panel or the aggregate summary + "Place an offer to see full bid detail" prompt
- [ ] Placing an offer triggers a client-side refetch of the listing detail so the offer-maker immediately sees the unlocked, full-detail view
- [ ] Withdrawing an offer re-locks detail on that listing for that user (no offer on the request → back to aggregate-only view)
- [ ] Unit/integration tests: non-participant querying `v_lender_offers` or the RPC directly (bypassing UI) receives only the aggregate payload

### 🌟 Trust & Reputation System — Implementation Checklist

- [ ] `reviews` table created: `id`, `contract_id`, `reviewer_id`, `reviewee_id`, `rating` (1–5), `comment`, `created_at`; unique on `(contract_id, reviewer_id)`
- [ ] `profiles.phone_verified_at` added; set by the existing OTP verification step at signup (no new verification flow needed for this badge)
- [ ] `submit_review(contract_id, rating, comment)` RPC — validates caller was a party to the contract, enforces one review per contract per direction, writes to `reviews`, logs to `audit_logs`
- [ ] `recompute_trust_aggregates(user_id)` trigger fn — recalculates `rating_avg`, `review_count`, `completed_deals_count`, `is_repeat_participant`, `response_time_bucket`, fired on new review / new completed contract
- [ ] `v_trust_profile_public` view — public signal set, readable by any authenticated user, keyed on `user_id`
- [ ] `v_trust_profile_pro` view — RLS-scoped to callers on Pro, adds `success_rate` and `reliability_score`
- [ ] `TrustBadgeRow` shared widget — renders the public badge set consistently on `ListingCard`, offers panel rows, and `ProfilePage`
- [ ] Pro-only `AdvancedTrustPanel` widget — renders success rate + reliability score, gated on the current user's own `subscription_plan`, only shown when viewing a counterparty
- [ ] `UserReviewsPage` (`/profile/:userId/reviews`) — full review list with star + text, paginated
- [ ] "Leave a review" prompt surfaced on `PositionsPage` for any contract without an existing review from the current user
- [ ] Unit/integration tests: non-Pro caller cannot read `v_trust_profile_pro` rows; non-participant on a contract cannot call `submit_review` for it; a second review attempt on the same `(contract_id, reviewer_id)` is rejected

### 📄 Contract Contents

Once the request owner accepts an offer, the system auto-generates a locked contract:

- Both parties' identity (post-reveal)
- Loan amount
- Agreed interest rate
- Total repayment amount
- Repayment schedule (frequency + installment amount)
- Late payment fee (% on missed installment only — **not the total balance**)
- Start & end dates
- Legal disclaimer
- Audit timestamp

**Late Payment Rule:** *"A [X]% penalty applies only to the missed payment amount — not the total loan balance."* This keeps penalties fair, prevents compounding debt, and builds platform trust.

**Legal Disclaimer:** *"Nipanze provides this agreement for convenience only. The final obligation is solely between the two parties. Nipanze does not enforce repayment or hold funds."*

> **Currency note (v5.0):** if Stage 4.5 ships first, the contract text generator (`fn_generate_locked_contract_text`) and the agreement snapshot JSON should include `currency_code` explicitly, so a generated contract never displays a bare number without its currency — add this as one line item to the checklist above, not a new subsystem.

### 🔓 Contact Reveal Flow

After contract generation:

1. A blurred **Deal + Contact Card** is shown to both parties
2. User clicks **"Unlock Deal & Contact"**
3. Confirmation dialog: action is irreversible
4. Contact details revealed: legal name, phone, email
5. Notifications sent to both parties (`deal_unlocked`)
6. Full contract becomes visible

Contact details are **never accessible before this step** — enforced at API level via `reveal_contact` RPC. This is a separate boundary from the Selective Transparency Model above: offer-term visibility can be participant-gated well before a deal is struck, but identity stays locked until this step regardless of participation.

> A per-unlock contact fee at this step is a proposed, **not yet committed**, monetization change — see "Contact-unlock fee" under Trust & Reputation System above. Until an explicit decision is made, step 2 remains free and status-gated only.

### 💰 Revenue — Unified Subscription Model

| Plan | Unlocks |
|---|---|
| 🟢 **Free** | Post basic requests (amount + duration + purpose only) · Browse · Accept offers received · Full visibility into every counterparty's public trust badges |
| 🔵 **Lender** *(subscription)* | Everything in Free + make offers with full terms (amount, interest, late fee, schedule) + unlocks full offer-detail view on any listing you've bid on |
| 🟣 **Pro** *(subscription)* | Everything in Lender + suggest terms when posting a request (interest, late fee, schedule) + priority visibility + improved matching + Verified badge + advanced trust insights (success rate, reliability score) |

> Platform earns from one committed upgrade path, not two parallel ones: users pay to unlock offer-making (Lender), and pay more to also unlock posting leverage and stronger trust signaling (Pro). A single `subscription_plan` enum drives all of it — no separate "Premium Borrower" product to maintain. Selective transparency and the trust system both add natural, low-pressure upgrade nudges: a Free user who wants full bid detail on a listing sees a prompt to upgrade to Lender and place an offer; a Lender who wants a Verified badge or deeper counterparty insight sees a prompt to upgrade to Pro. A flat per-unlock contact fee is a proposed secondary lever, not yet part of the committed model.

### 🛡️ Compliance & Security

- Terms locked at post/offer time — no post-publish edits
- `reveal_contact` RPC enforced at API level
- Offer-term detail scoped to the request owner and offer-makers on that request, enforced via RLS/RPC — not the Flutter client
- Trust signals are computed strictly from on-platform events (requests, offers, contracts, reviews) — never framed as measuring off-platform repayment behavior, consistent with the platform boundary in Regulatory Compliance
- Reviews are participant-gated server-side in `submit_review`, not just the UI
- All actions recorded in **append-only audit logs**, including review submissions
- Contract snapshot stored for traceability
- Platform never tracks repayments or enforces obligations
- Subscription plan checked server-side (RLS / RPC), never trusted from client

### ✅ Stage 4 Exit Criteria

- [ ] Pro-tier subscription gate on interest/late fee/repayment fields in the request form
- [ ] Request terms locked on publish (`terms_locked_at` set; no further edits)
- [ ] Offer terms locked on submit
- [ ] `offer_coverage_tier` visible on every listing to every viewer (public, anonymized)
- [ ] Exact offer-term detail visible only to the request owner and to offer-makers who have bid on that listing (Selective Transparency Model)
- [ ] Non-participant calling `v_lender_offers` or `get_public_listing_offers` directly cannot retrieve exact offer terms
- [ ] Public trust badge row (rating, review count, completed deals, repeat badge, phone-verified, response time) visible on every profile, listing card, and offer row to every viewer regardless of plan
- [ ] Pro-only Verified badge and advanced trust insights (success rate, reliability score) gated to Pro viewers only, and never substitute for or hide the public badge row
- [ ] Reviews can only be submitted by a verified party to a completed contract, one per contract per direction
- [ ] Contract auto-generated after request owner accepts an offer
- [ ] Contract includes all agreed fields + legal disclaimer (+ `currency_code` if Stage 4.5 has shipped first)
- [ ] Late fee applies only to missed installment (not total balance)
- [ ] Contact reveal only after contract is generated
- [ ] Contact details never accessible before reveal via any query
- [ ] Contact-unlock fee explicitly decided go/no-go before any payment-flow work begins (not assumed)
- [ ] Audit logs capture full contract lifecycle, including review submissions
- [ ] Both parties receive `deal_unlocked` notification
- [ ] `role` column fully removed from schema; all gating reads `subscription_plan` only
- [ ] Pro Advanced Marketplace Filters: `v_marketplace_pro_filters` view and `get_marketplace_pro_filtered` RPC applied to DB, Pro-gated entry button (Option B) and filter criteria bottom sheet implemented in UI, and client-side stream intersection applied in MarketplaceCubit

---

## Stage 4.5 — Multi-Country Expansion ⬜ Planned

Full model and rationale documented in "Multi-Country Expansion Model" above. This section tracks the migration checklist and exit criteria.

### Migration Checklist

- [ ] Create `countries` table; seed with all 8 EAC member states per the reference table above — `UG` as `is_active = TRUE` (existing market), the other seven (`KE`, `TZ`, `RW`, `BI`, `SS`, `CD`, `SO`) as `is_active = FALSE` until each clears its own Stage 6 launch-readiness review
- [ ] `ALTER TABLE profiles ADD COLUMN country TEXT REFERENCES countries(code)`; backfill all existing rows to `'UG'`; then set `NOT NULL`
- [ ] `ALTER TABLE loan_requests ADD COLUMN country TEXT REFERENCES countries(code)`; backfill from `profiles.country` via join; then set `NOT NULL`
- [ ] New trigger `trg_fn_set_request_country` (`BEFORE INSERT`) — copies `country` from the borrower's profile; add to the existing "lock after publish" pattern so it can't be edited post-publish
- [ ] `ALTER TABLE system_settings ADD COLUMN country TEXT REFERENCES countries(code)`; existing rows stay `country = NULL` (treated as global default); composite unique index `(setting_key, country)`
- [ ] Rename `subscriptions.amount_ugx` → `amount_minor_units` (or add the new column, backfill, drop the old one in a follow-up migration to avoid a breaking change mid-flight)
- [ ] Rebuild `v_loan_listings`, `v_lender_offers`, `v_marketplace_activity` to include `country` / `currency_code`
- [ ] Add indexes: `CREATE INDEX idx_lr_country ON loan_requests(country)`; `CREATE INDEX idx_lr_country_status ON loan_requests(country, status)`; `CREATE INDEX idx_profiles_country ON profiles(country)`
- [ ] Update `MarketplaceRepository` default query to filter `country = currentUserCountry`, with an explicit "browse other markets" toggle in the UI
- [ ] Onboarding: add a country-select step, pre-filled from phone-prefix guess, editable before confirming
- [ ] Decide and document the two open items above before Stage 4.5 exit: (a) global browse vs hard RLS isolation, (b) cross-border offers allowed vs blocked
- [ ] `stage-4.5-verify.sql` — confirm no `loan_requests` or `profiles` row has `country IS NULL`, confirm every active country in `countries` has at least the seed seen in `stage-4.5-status.sql`

### Stage 4.5 Exit Criteria

- [ ] Every `profiles` and `loan_requests` row has a non-null `country`
- [ ] Marketplace feed defaults to the logged-in user's country; switching markets is an explicit user action, not automatic
- [ ] `v_loan_listings` and `v_lender_offers` return `currency_code` alongside every amount
- [ ] `system_settings` limits resolve correctly per country (falls back to the global/`NULL` row when no country-specific override exists)
- [ ] Open decisions (global browse vs isolation; cross-border offers) explicitly resolved and reflected in RLS/triggers, not left ambiguous
- [ ] Activating a new market requires only `UPDATE countries SET is_active = TRUE` (the row already exists — all 8 EAC countries are seeded at migration time) — verified by actually flipping one (e.g. `KE`) in a staging environment and confirming no code change was needed
- [ ] Admin KPI view (`v_marketplace_activity`) can be filtered or grouped by country

---

## Stage 5 — Admin & Compliance ⬜ Planned

- [ ] Admin KYC review dashboard
- [ ] Admin review moderation (Stage 4 reviews)
- [ ] Admin KPI dashboard (`v_marketplace_activity`)
- [ ] SMS alerts
- [ ] Admin dashboard filterable by country (`v_marketplace_activity` grouped by `country`)
- [ ] Per-country `system_settings` editable from the admin panel (min/max loan amount, listing duration, etc. per market)
- [ ] `countries.is_active` toggle exposed in admin — pause/resume a market without a deploy

---

## Stage 6 — Launch & Growth ⬜ Planned

- [ ] Play Store AAB + App Store IPA
- [ ] Privacy policy + terms of service
- [ ] 3-screen onboarding carousel — **no role selection step**; onboarding introduces the unified marketplace, subscription tiers, and the public trust system, plus a country-select step (pre-filled from phone-prefix guess, editable) as the only new onboarding question
- [ ] Crash reporting (Firebase Crashlytics or Sentry)
- [ ] Referral programme (`referrals` table in schema v4.0)
- [ ] Subscription upgrade prompts — contextual (e.g., prompt to upgrade to Lender the moment a Free user taps "Make Offer", to Pro the moment a user views another Pro's Verified badge, or taps "See full bid detail" on a listing)
- [ ] Finalize actual subscription pricing (per market currency) for Lender and Pro against local willingness-to-pay research — flagged in Stage 4 as an open item, resolved here before public launch
- [ ] Decide go/no-go on the proposed contact-unlock fee, informed by real Stage 4/5 usage data on contact-reveal frequency
- [ ] Flutterwave (or equivalent) integration for `subscriptions` payment, scoped strictly to Nipanze's own revenue (plan upgrades, and contact-unlock fee if that open decision is resolved to "yes") — never P2P loan funds; `transactions` table, webhook-verified status transitions, Edge Function signature verification — see Payments Infrastructure addendum above
- [ ] Per-market EAC launch checklist — repeat for each of Kenya, Tanzania, Rwanda, Burundi, South Sudan, DR Congo, and Somalia before flipping that country's `is_active` to `TRUE`:
  - [ ] `countries.is_active` set `TRUE` for that market
  - [ ] Local-currency pricing finalized for Lender and Pro (see "What this does not include" — no cross-market conversion, each market prices independently against local willingness-to-pay)
  - [ ] Payment-rail coverage confirmed with the chosen aggregator for that specific country (do not assume coverage from a neighboring market's success)
  - [ ] Local KYC document types validated (`kyc_verifications.national_id_type` accepts the correct free-text values for that market)
  - [ ] Local payment/contact norms and any market-specific regulatory or compliance review completed
- [ ] Decide the EAC rollout order and cadence — simultaneous multi-market launch vs. sequential (e.g. Uganda → Kenya → Tanzania → Rwanda first, given deeper payment-rail maturity, with Burundi/South Sudan/DR Congo/Somalia following once each clears its own rail-coverage and compliance review) — based on Uganda+Kenya learnings once Kenya ships

---

## Key Flows — Current Status

| Flow | Status |
|---|---|
| Register → verify email → login | ✅ |
| 5-tab nav, Request in centre | ✅ |
| Browse marketplace with filters | ✅ Stage 2 |
| Live feed Realtime refresh | ✅ Stage 2 |
| Post a structured loan request (Free — amount, duration, purpose only) | ✅ Stage 2 |
| Form limits from DB (system_settings) | ✅ Stage 2 |
| Browse and make an offer with full terms (Lender/Pro) | ✅ Stage 2 |
| Subscription gate modal | ✅ Stage 2 |
| Request owner accepts an offer | ✅ Stage 2 |
| Losing offers auto-rejected | ✅ Stage 2 |
| Live offers panel Realtime + flash | ✅ Stage 2 |
| KYC upload (camera/gallery, 3 docs) | ✅ Stage 2 |
| Save to watchlist (toggles star) | ✅ Stage 3 |
| Watchlist — real data, grouped, urgency | ✅ Stage 3 |
| Positions — My Requests tab | ✅ Stage 3 |
| Positions — My Offers tab with withdraw | ✅ Stage 3 |
| Offer withdrawal with confirm dialog | ✅ Stage 3 |
| Notifications | ✅ Stage 3 |
| Profile/Account live data | ✅ Stage 3 |
| OfflineBanner | ✅ Stage 3 |
| Pro-tier: suggest interest rate / late fee / repayment on post | ⬜ Stage 4 |
| Request terms locked on publish | ⬜ Stage 4 |
| Offer terms locked on submit | ⬜ Stage 4 |
| Selective transparency: aggregate view for non-participants, full detail for owner/offer-makers | ✅ DB · ✅ UI |
| Marketplace hides listings where user has an active offer (pending/accepted) | ✅ UI |
| Public trust badge row (rating, reviews, deals, repeat, phone-verified, response time) | ⬜ Stage 4 |
| Pro-tier Verified badge + advanced trust insights | ⬜ Stage 4 |
| Post-contract review flow | ⬜ Stage 4 |
| Contract auto-generated after offer acceptance | ⬜ Stage 4 |
| Contact reveal flow (blurred → unblur) | ⬜ Stage 4 |
| Contact-unlock fee (open decision) | ⬜ Not yet committed |
| Remove `role` column; subscription-only gating | ⬜ Stage 4 |
| Pro Advanced Marketplace Filters (employment type, income bracket, suggested terms, verified status) | ⬜ Stage 4 |
| Multi-country schema migration (`countries`, `profiles.country`, `loan_requests.country`) | ⬜ Stage 4.5 |
| Marketplace feed defaults to user's country, with explicit browse-other-markets toggle | ⬜ Stage 4.5 |
| Flutterwave payment integration (subscriptions + contact-unlock fee only) | ⬜ Stage 6 |
| Admin KYC review | ⬜ Stage 5 |
| Admin review moderation | ⬜ Stage 5 |
| Admin KPI dashboard (country-filterable) | ⬜ Stage 5 |
| SMS alerts | ⬜ Stage 5 |

---

## Test Accounts (password: `Test1234!`)

> `Role` column removed — accounts are described purely by activity + subscription plan, matching the unified model. All 17 existing seed accounts (see `sql/seed.sql`) backfill to `country = 'UG'` under the Stage 4.5 migration.

| Email | Country | Subscription | Best for testing |
|---|---|---|---|
| `david.mukasa@gmail.com` | UG | Free | Contracted request; contact reveal triggered |
| `sarah.namukasa@yahoo.com` | UG | Free | Contracted request; contact reveal pending |
| `james.okello@outlook.com` | UG | Pro | Active request with two pending offers; also has offers out on other listings |
| `maria.nakato@gmail.com` | UG | Free | Active request, one pending offer |
| `robert.ssemwanga@gmail.com` | UG | Lender | Closing-soon request; pending offer on another listing |
| `invest@pearlcapital.ug` | UG | Pro | Offer accepted on David's request; contact revealed |
| `funds@victoriainvest.co.ug` | UG | Pro | Offer accepted on Sarah's request; contact reveal pending |
| `lending@equatorfinance.ug` | UG | Lender | Pending offer on James's request |
| `info@greenleafagro.co.ug` | UG | Lender | Pending offer on Maria's request; expired offer on Charles's |
| `contact@kampalatech.ug` | UG | Lender | Pending offer on Frank's request |
| `alice.namuli@gmail.com` | UG | Free | KYC pending — test KYC badge; `account_status = pending_verification` |
| `admin1@nipanze.ug` | UG | Free (`is_admin = true`) | Full admin dashboard access |
| `test.user@gmail.com` | UG | Free | No prior activity — test onboarding gates |
| `wanjiru.kamau@gmail.com` *(new, Stage 4.5)* | KE | Free | Confirms a KE-registered user sees only KE listings by default, and that switching to "Browse Uganda" surfaces UG listings without exposing exact offer terms they're not party to |
| `nairobi.capital@example.co.ke` *(new, Stage 4.5)* | KE | Lender | Confirms a KE lender can (per the recommended default) place a cross-border offer on a UG listing, and that the resulting offer/trust data behaves correctly across the country boundary |
| `amani.mwakalinga@gmail.com` *(new, Stage 4.5)* | TZ | Free | Confirms TZS displays correctly on a TZ-posted request (amount, currency symbol/code), and that a TZ user's default feed excludes UG/KE listings |
| `uwase.claudine@gmail.com` *(new, Stage 4.5)* | RW | Pro | Confirms RWF-denominated Pro term suggestions (interest, late fee, schedule) render correctly, and that Pro-tier gating (Verified badge, advanced trust insights) works identically regardless of `country` |

All existing 17 accounts and their test scenarios (David Mukasa contracted request, James Okello's multi-offer listing, etc.) are otherwise unchanged — see `sql/seed.sql` for the full list. The TZ and RW accounts above are seeded as `is_active = FALSE`-market test data — useful for verifying the schema and currency handling work correctly ahead of each market's actual Stage 6 launch, without implying either market is live.

> **Currency-rendering test note:** with all 8 EAC currencies live in the `countries` seed, add at minimum one seed listing per currency (`UGX`, `KES`, `TZS`, `RWF` at Stage 4.5; `BIF`, `SSP`, `CDF`, `SOS` can be added incrementally as each market approaches its own Stage 6 launch) so `v_loan_listings` / `v_lender_offers` currency-formatting logic is exercised against every currency code the schema supports, not just UGX.

> **Stage 4 selective-transparency testing:** view a contested listing (e.g. James Okello's active request, which has two pending offers) while logged in as a non-participant account like `test.user@gmail.com` to confirm only the aggregate `offer_coverage_tier` is visible, then log in as `lending@equatorfinance.ug` (which has a pending offer on James's request) to confirm full offer detail unlocks.
>
> **Stage 4 trust-system testing:** `invest@pearlcapital.ug` and `david.mukasa@gmail.com` already share a completed contract (offer accepted, contact revealed) — a good seed pair for the first mutual reviews once `reviews` ships, to confirm the rating/review-count badges update correctly on both profiles.

---

## Architecture Constraints

1. **No fund movement** — platform never initiates, processes, records, or tracks financial transactions, in any country
2. **Anonymity by default** — request-owner id never in marketplace queries; offer-maker identity hidden until offer is accepted and contact is revealed
3. **DB is the gate** — triggers + RLS enforce all rules based on `subscription_plan` and, as of v5.0, `country`; client validation is UX only
4. **Controlled contact sharing** — `reveal_contact`/`unlock_contact` RPCs enforced at API layer; contact details never accessible before reveal via any query
5. **Friendly errors** — `parseSupabaseError()` everywhere; raw trigger codes never reach the user
6. **Append-only audit log** — `audit_logs` never writable via UPDATE or DELETE
7. **No stored role** — the only role in the system is `is_admin`; all marketplace capability comes from `subscription_plan` (`free | lender | pro`)
8. **Selective transparency** — exact offer-level terms (amount, interest rate, late fee, schedule) are visible only to the request owner and to offer-makers with a live offer on that same request; every other viewer, regardless of subscription plan, sees only the aggregate `offer_coverage_tier` and offer count. Enforced via RLS/RPC, never trusted from the client.
9. **Trust signals are public, platform-scoped, and country-agnostic** — baseline reputation data (ratings, review counts, completed-deal counts, repeat/phone-verified badges) is visible to every viewer regardless of plan, participation, or which country they're browsing, and reflects a user's full on-platform history across all markets, not just their home country. Nipanze never displays or implies a signal about off-platform repayment behavior, consistent with constraint 1. Pro-tier trust features add verification weight (KYC-backed badge) and interpretation (derived scores) on top of this same public data — they never withhold or replace it.
10. **Country is explicit, indexed, and locked-at-creation** — `profiles.country` is the editable source of truth for a user; `loan_requests.country` is copied from it at post time and frozen; `loan_offers` has no country of its own and is always read through its parent request. One shared schema serves every market — never a table or database per country.

---

*Nipanze Platforms Limited · contact@nipanze.ug · nipanze.ug*
*Made with ❤️ for financial inclusion across East Africa*