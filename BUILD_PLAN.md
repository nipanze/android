# BUILD_PLAN.md — Nipanze

> **Flutter + Supabase** · Non-custodial digital lending & forex matchmaking marketplace for Uganda and expansion markets across Africa
> Last updated: July 2026 · Schema v6.0 · Seed v2.2 (Uganda-only until Stage 4.5 migration is applied; Stage 4.7 adds forex seed data)

> **⚡ v4.1 Architecture Change:** Nipanze moved from a **role-based** model (borrower / lender) to a **unified, subscription-based, action-based** model. There is no "I am a borrower" or "I am a lender" — every user sees one marketplace and performs borrower actions (Post Request) or lender actions (Make Offer) depending on what they click. Access to actions is gated purely by `subscription_plan`. See "Unified Marketplace Model" below.
>
> **⚡ v4.1 Stage 4 addition:** Listing detail visibility is **tiered, not binary**. See "Selective Transparency Model" below — it changes what `v_lender_offers` / `v_forex_offers` and `get_public_listing_offers` / `get_public_forex_offers` return depending on who's asking.
>
> **⚡ v4.1 Stage 4 addition:** A public **Trust & Reputation System** (ratings, reviews, completed-deal counts, badges) is planned. See "Trust & Reputation System" below — deliberately kept separate from selective transparency: trust signals are public to everyone on every plan, while offer-term detail stays participation-gated.
>
> **⚡ v5.0 → v6.0 Architecture Change:** Nipanze's multi-market ambitions have been **re-scoped twice** since v5.0:
> 1. The original v5.0 plan targeted the full **East African Community (EAC)** — Kenya, Uganda, Tanzania, Rwanda, Burundi, South Sudan, DR Congo, and Somalia.
> 2. **v6.0 replaces that EAC-only scope.** The committed expansion list is now **seven countries across three African regions** — Uganda, Kenya, Tanzania, Rwanda, Nigeria, South Africa, and Egypt — see the "Multi-Market Architecture" section below, which fully supersedes the old "Multi-Country Expansion Model (EAC)" section and its 8-country reference table. **Burundi, South Sudan, DR Congo, and Somalia are no longer on the roadmap.** The underlying schema pattern (one shared `countries` row per market, one `is_active` flag) still supports adding any of them back later the same way any new country is added — a row insert — but they are explicitly out of scope for the current plan.
>
> **⚡ v6.0 Architecture Change — Forex module added.** Nipanze is no longer a single-purpose lending marketplace. It now ships **two feature-modules on one shared platform**: **Loans** (unchanged in spirit from v4.1/v5.0) and **Forex** (new) — peer-to-peer currency exchange matchmaking. See "Two Projects, One Platform" and "Forex Marketplace Expansion Model" below. This is the single biggest structural change since the v4.1 unified-marketplace decision, and it touches almost every section of this document: schema, RLS, subscription gating, selective transparency, trust aggregates, the marketplace feed, and the roadmap.
>
> This layers on top of, and does not replace, the v4.1 changes already documented above: the **Unified Marketplace Model**, the **Selective Transparency Model**, and the **Trust & Reputation System** all still apply — and, as of v6.0, apply identically to both Loans and Forex. Multi-market adds a *geographic* dimension and Forex adds a *second module* dimension on top of them; neither changes how plans, transparency, or trust work.

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

> Stage 4.5 is written to be implementable **before or alongside** Stage 4 — it's a data-model and RLS change, not a UI feature, so it doesn't block Stage 4's contract/trust work and vice versa. Recommended order: ship Stage 4.5's schema migration first (smaller, lower-risk, and everything after it should be country-aware from the start), then build Stage 4 UI on top of a schema that's already multi-market-shaped, then ship Stage 4.7 (Forex) once Loans' contract/trust/transparency machinery is stable — Forex reuses that machinery directly rather than inventing a parallel version of it. Stage 4.7 does **not** need to wait for every Stage 4.5 country to be active — Forex can go live in Uganda alone (`countries.forex_enabled = TRUE` for `UG` only) while the other six markets are still `is_active = FALSE` for lending.

---

## 🏗️ Two Projects, One Platform (v6.0 — governs the Loans/Forex split)

### The decision

Nipanze ships **Loans** and **Forex** as two distinct feature-modules — each with its own request/offer tables, its own create-request flow, its own listing-card design, and its own stage checklist and exit criteria (this document) — running on **one shared app, one shared Supabase project, and one shared account system.**

This is deliberately the middle path between two rejected extremes:

- ❌ **Full separation** (two apps, two accounts, two logins) — rejected. A request owner and an offer-maker shouldn't need two accounts to do two closely related things: post a need, get offers, agree terms, get introduced. Full separation means re-implementing auth, trust, contracts, and contact-reveal twice for no product benefit.
- ❌ **Full blending** (one generic "request" table and one generic listing card for both) — rejected. A loan and a currency exchange are different enough in shape — loan terms vs. an exchange rate; a funded-% progress bar vs. a Send/Rate/Receive panel — that force-fitting them into one schema and one card layout would make both worse.

### What's shared vs. what's separate

| Shared (one platform) | Separate (two projects) |
|---|---|
| Auth, `profiles`, `subscription_plan`, `is_admin` | `loan_requests` / `loan_offers` vs `forex_requests` / `forex_offers` |
| `countries`, `currencies`, `system_settings` | `features/loans/` vs `features/forex/` Flutter modules |
| Trust & reputation (`trust_aggregates`, `reviews`) | Listing-card design (funded-% progress bar vs Send/Rate/Receive panel) |
| Selective transparency machinery (same RLS/RPC pattern) | Create-request form (loan terms vs currency pair + rate) |
| Contracts, contact reveal (`accept_offer`, `reveal_contact`) | Per-module RLS/RPC pairs (`v_lender_offers`/`get_public_listing_offers` vs `v_forex_offers`/`get_public_forex_offers`) |
| Watchlist, Positions, Notifications, KYC, Admin | Per-module regulatory review, per market (`countries.is_active` for lending, `countries.forex_enabled` for forex, independently toggled) |
| One `Marketplace` screen, filterable by module | Per-module launch sequencing (a market can go live for Loans before Forex, or vice versa) |

### Why this matters for the build plan specifically

Every stage below that touches deal terms, transparency, trust, or contracts (Stage 4) is written once and applies to **both** modules — the RLS pattern, the locked-bidding pattern, and the trust-aggregate pattern are identical for a loan offer and a forex offer. Only the request/offer table shape and the listing card differ. This is why Stage 4.7 (Forex) is scoped as a comparatively small stage: it reuses Stage 4's machinery wholesale rather than rebuilding it.

---

## 🧠 Unified Marketplace Model (v4.1 — supersedes role-based framing; v6.0 extends across both modules)

### The decision

- ✅ One interface for every user — no separate borrower/lender screens
- ✅ No "borrower vs lender" role stored on the account
- ✅ Users choose a **subscription plan**, not a role
- ✅ The same person can post a request *and* make offers, any time, with the same login, on **either module** (Loans or Forex), in any country their account belongs to

### Mental model shift

| Old model | New model |
|---|---|
| "User *is* a borrower or a lender" | "User *performs* borrower or lender actions depending on what they click" |
| Role determines what's visible | Subscription plan determines what's clickable |
| Separate flows/screens per role | One dashboard, one marketplace, action buttons gated by plan |
| (pre-v6.0) One request type | (v6.0) Loan or Forex, chosen at the moment of posting or offering — not a fixed identity |

### How it behaves

**Single entry point after login** — every user lands on the same dashboard:

1. **📢 Marketplace** — all loan and forex listings for the user's active country, filterable by `All / Loans / Forex`
2. **➕ Post Request** — always visible from Free tier upward; choosing Loan or Forex happens at the moment of posting
3. **💼 Offers Panel** — shows offers *received* on your requests, and (if your plan allows) offers *you've made* on others' requests, across both modules

There is no "select your role" step at signup or login, and no "select your module" step at signup either. A user simply acts:

- Clicks **"Post Request"** → picks Loan or Forex → acting as the request owner for that listing
- Clicks **"Make Offer"** → acting as the offer-maker for that listing, loan or forex

### Feature access by plan

| Plan | Access |
|---|---|
| 🟢 **Free** | Post basic loan or forex requests (loan: amount, duration, purpose · forex: currency pair, amount, settlement preference) · Browse marketplace · Accept received offers · Watchlist, Positions, Notifications, KYC · Full visibility into public trust signals on every profile · ❌ Cannot make offers · ❌ Cannot suggest terms when posting |
| 🔵 **Lender Plan** | Everything in Free, **plus**: Make offers on any listing, loan or forex · Set interest rate, late payment fee, repayment schedule on loan offers · Set exchange rate, available amount, and terms on forex offers |
| 🟣 **Pro** | Everything in Lender, **plus**: Suggest terms when posting a request — interest rate, late fee, repayment schedule for a loan request, or a preferred exchange rate for a forex request · Priority visibility for posted requests, loan or forex · Improved matching · Verified badge · Advanced trust insights (success rate, reliability score) |

> No plan is ever labeled "Borrower Plan," "Lender-only," or "Forex Plan." The plan name describes the *unlocked capability*, not the person or the module. No plan is ever country- or module-specific — a single `subscription_plan` applies regardless of which country's marketplace a user is viewing or whether they're acting in Loans or Forex.

### Feature gating logic

```
IF subscription_plan == "free"
  disable "Make Offer"   -- loan or forex
  disable term-suggestion fields on Post Request  -- loan or forex

IF subscription_plan == "lender"
  enable "Make Offer"   -- loan or forex
  enable lender term fields (interest, late fee, schedule) on loan offers
  enable lender term fields (rate, amount, terms) on forex offers
  keep term-suggestion fields on Post Request disabled

IF subscription_plan == "pro"
  enable everything above
  enable term-suggestion fields on Post Request  -- loan terms, or forex preferred rate
  enable priority visibility / improved matching  -- loan or forex
  enable Verified badge display + advanced trust insights view
```

### Why this is the right call

1. **Simpler UX** — no "am I a borrower or a lender?" confusion at signup, and (v6.0) no "am I here for loans or forex?" confusion either — the marketplace shows both, filterable
2. **Higher conversion** — users aren't boxed into one identity or one module, so upgrading feels natural rather than like switching accounts
3. **More revenue paths** — a Free user who only ever posted loan requests can upgrade to Lender the moment they want to make a forex offer, same account, no re-registration, no second subscription product

### What this removes from the data model

- ❌ `role` column (`borrower` / `lender` / `both`) — **no longer needed**
- ❌ Role-based RLS branching — **replaced with plan-based checks**
- ❌ (v6.0) Any notion of a per-module account type — **one `subscription_plan` gates both modules identically**

### What this replaces it with

```sql
-- users / profiles table (conceptual)
id
email
subscription_plan   -- 'free' | 'lender' | 'pro'
is_admin            -- boolean, unaffected by this change
phone_verified_at   -- nullable timestamp, drives the free "phone verified" trust badge
country              -- v5.0/v6.0, see Multi-Market Architecture below
```

`is_admin` is the **one exception** — admin remains a true role, separate from the subscription plan, since it governs platform moderation rather than marketplace participation, and (v6.0) spans every country and both modules.

### Migration impact (Stage 4 dependency)

Because Stage 4 (deal agreement + contact sharing) was originally scoped around a "Premium Borrower" vs "Lender" dual-subscription split, and originally scoped around Loans only, it must be re-read through both the unified model and the two-module model:

- "Premium Borrower" features (suggested interest/late fee/schedule on post) are now simply **Pro-tier loan-posting capability** — not a separate subscription product
- "Lender" subscription features (making offers with full terms) are now the **Lender-tier capability**, available without needing Pro, and available identically for loan offers and forex offers
- A single user can hold only **one** `subscription_plan` at a time (`free | lender | pro`), and Pro is a strict superset of Lender, which is a strict superset of Free — there is no "buy just the posting add-on" product, and (v6.0) no "buy just Forex" product either

This keeps subscription logic to one enum column and one gating function, rather than two independent entitlement flags or two per-module products — simpler RLS, simpler billing, simpler UI.

---

## 🔍 Selective Transparency Model (v4.1 — governs listing detail visibility; v6.0 extends identically to Forex)

Stage 2 shipped a fully public offer book on `LoanDetailPage`: every visitor could see every offer's exact amount and terms. Stage 4 replaces that with **tiered visibility**, keyed off participation rather than role — and, as of v6.0, this exact same tiering logic governs `ForexDetailPage` too, with no separate design.

### The decision

- ✅ Marketplace feed (`v_loan_listings`, `v_forex_listings`) stays exactly as public as it already is — funded %/rate-coverage tier, offer count, time left, all public
- ✅ Listing detail becomes tiered: aggregate signals for everyone, exact offer terms only for participants — identical rule for loan listings and forex listings
- ❌ No full lock-down — visitors and non-participating Lender/Pro users still see enough to gauge how competitive a request is
- ❌ No permanent full exposure — copying another offer-maker's exact price (loan interest rate, or forex exchange rate) without doing your own risk assessment is no longer possible without first placing a bid

### Mental model shift

| Old model (Stage 2, Loans only) | New model (Stage 4, Loans + Forex) |
|---|---|
| "Anyone viewing a listing sees every offer's exact terms" | "Anyone viewing a listing sees the shape of the market; only participants see exact terms" |
| Transparency = fully public | Transparency = **selective**, tied to participation |
| Offer detail is a UI concern | Offer detail is an RLS/RPC concern — enforced at the data layer |
| Loans-only | Loans and Forex, same tiering logic, different fields exposed |

### Visibility tiers

| Viewer | Sees on `LoanDetailPage` | Sees on `ForexDetailPage` |
|---|---|---|
| **Visitor / any logged-in user, not yet bid** | Funded % progress bar, `number_of_offers`, `offer_coverage_tier` (`low`/`medium`/`high`), full request summary (amount, purpose, district, duration, repayment plan), owner's public trust badges | Currency pair, amount needed, `number_of_offers`, `rate_coverage_tier` (`low`/`medium`/`high`), settlement preference, owner's public trust badges — **never** individual offered rates |
| **Lender/Pro-plan holder browsing, has not offered on *this* listing** | Same as a visitor — plan alone does not unlock offer detail; placing an offer does | Same as a visitor — plan alone does not unlock offer detail; placing an offer does |
| **Offer-maker who has placed an offer on this listing** | Everything above, **plus** exact amount, interest rate, late fee, and repayment schedule for every offer on this listing, plus each offer-maker's public trust badges | Everything above, **plus** exact rate offered, available amount, and settlement terms for every offer on this listing, plus each offer-maker's public trust badges |
| **Request owner** | Full detail on every offer received (amount, interest rate, late fee, schedule, timestamp) plus each offer-maker's trust badges (and advanced insights if the owner is Pro) | Full detail on every offer received (rate, amount, terms, timestamp) plus each offer-maker's trust badges (and advanced insights if the owner is Pro) |

Contact details are a separate boundary and stay locked for **everyone**, at every tier, until contract generation + unlock — this model only changes *offer-term* visibility, not identity, and that boundary is unchanged by which module the listing belongs to. Public trust badges are a third, independent boundary — see "Trust & Reputation System" below — visible at every tier regardless of participation or module, because reputation is not a competitive-position signal the way offer terms are.

### Why tiered, not fully public or fully locked

1. **Fully public exact terms** let offer-makers copy-price off each other (undercut a loan's interest rate, or shave a forex rate, by a token amount without doing their own risk assessment) and let outsiders read a request owner's negotiating position without ever participating
2. **Fully locked terms** remove the market signal lenders/offer-makers need to decide whether a listing is worth competing on, which suppresses offer volume on both modules
3. **Participation-gated detail** rewards engagement, keeps competition on substance rather than copying, and creates a natural in-product nudge toward the Lender plan ("Place an offer to see full bid detail on this listing")

### Gating logic (module-parametric — one function shape, two callers)

```
listing = get_listing(request_id, module)   -- module: 'loan' | 'forex'

IF viewer == listing.owner
  return full_offer_detail(all offers on this request, module)

ELSE IF viewer has an offer on this request
  return full_offer_detail(all offers on this request, module)   -- includes viewer's own offer

ELSE IF module == 'loan'
  return {
    number_of_offers: count(loan_offers),
    offer_coverage_tier: compute_tier(loan_offers)   -- low / medium / high, anonymized aggregate
  }

ELSE  -- module == 'forex'
  return {
    number_of_offers: count(forex_offers),
    rate_coverage_tier: compute_tier(forex_offers)   -- low / medium / high, anonymized aggregate
  }
```

This logic lives in `get_public_listing_offers(request_id)` / `get_public_forex_offers(request_id)` and the `v_lender_offers` / `v_forex_offers` views (both RLS-scoped), **not** in the Flutter client — a non-participant calling either RPC directly gets the same reduced payload as one browsing the UI, on either module.

### Data model impact

- `v_loan_listings` gains a derived `offer_coverage_tier` column; `v_forex_listings` gains a derived `rate_coverage_tier` column — both public, anonymized, computed from that request's own offers, alongside `number_of_offers`
- `v_lender_offers` becomes participant-scoped via `security_invoker` + RLS: a row is only returned to the request owner or to an account with an offer on that `request_id`
- `v_forex_offers` becomes participant-scoped via the identical `security_invoker` + RLS pattern, scoped to `forex_requests.request_id`
- `get_public_listing_offers(request_id)` and `get_public_forex_offers(request_id)` RPCs branch on caller identity (owner / participant / neither) using the same logic as above, so Edge Functions and direct RPC callers can't bypass the tiering that the UI enforces, on either module

### What stays unchanged

- Marketplace feed fields and public request summary fields (loan: title, amount, duration, purpose, district, repayment plan · forex: currency pair, amount, settlement preference) — unaffected by this model
- Contact-reveal flow and its RPC-level enforcement — unaffected; still gated strictly behind contract generation, loan or forex
- Public trust badges — unaffected by this model; they render at every visibility tier, on every listing, regardless of module

---

## 🌟 Trust & Reputation System (v4.1 — governs counterparty credibility, separate from deal-term visibility; v6.0 unifies across both modules)

Early product feedback flagged that Nipanze's plan tiers (Free / Lender / Pro) describe *capability* well but say nothing about *credibility* — a Free user browsing the marketplace has no way to judge whether a request owner or offer-maker is a reliable counterparty before ever engaging. This section defines a public reputation layer to close that gap, and a Pro-tier verification/insight layer to monetize it responsibly. As of v6.0, this layer is explicitly **global across both modules** — a user's forex deal history and loan deal history contribute to one combined reputation, not two separate scores.

### The decision

- ✅ Baseline trust signals (rating, review count, completed-deal count, repeat-participant badge, phone-verified badge, response-time bucket) are **public to every user on every plan** — never a pricing-table line item, never gated behind a plan check
- ✅ Trust signals are computed from **on-platform events across both modules** — a completed loan contract and a completed forex contract both count toward the same `completed_deals_count`, the same rating average, and the same repeat-participant badge
- ✅ Pro-tier adds **verification weight** (full KYC-based "Verified" badge) and **analytical depth** (success rate, reliability score) on top of the same public, module-combined data — it does not create a second, hidden trust system, and it does not split into a "Loans reliability score" and a "Forex reliability score"
- ❌ Trust signals never claim to measure off-platform repayment or settlement behavior — Nipanze does not track loan repayments or forex settlement (see Architecture Constraints), so every signal is built strictly from on-platform events: requests posted, offers made, contracts generated, reviews left after a completed contract, on either module

### Why public, not paywalled

A marketplace with hidden reputation data doesn't function — new users need proof that other participants are real and reliable before they'll risk posting a request or placing an offer, whether that request is for a loan or a currency exchange. Locking ratings, review counts, or deal history behind a subscription would suppress activity for everyone, including paying users, since a Lender/Pro account still needs to evaluate *other* people's trust signals to decide who to fund or exchange with. So:

- 🔓 **Trust = public reputation system** — visible regardless of plan, country, or module
- 💰 **Paid plans = visibility + verification + analytical advantage system** — Pro doesn't unlock reputation, it strengthens and interprets it

### What's public (Free — every profile, every plan, every market, both modules)

| Signal | Computed from | Rendered as |
|---|---|---|
| ⭐ Rating average + review count | `reviews` table, one review per completed contract per direction, loan or forex, across all countries | Star rating + count, e.g. "⭐ 4.7 (18 reviews)" |
| 📊 Completed deals count | Count of `contracts` the account has been a party to, loan and forex combined, across all countries | "📊 9 successful deals" |
| 🔁 Repeat participant badge | Second completed contract onward, loan or forex, anywhere in the region | "🔁 Repeat Borrower" / "🔁 Repeat Lender" depending on which side of the most recent deal |
| 📱 Phone verified badge | `profiles.phone_verified_at` set at OTP verification, signup-time | "📱 Phone verified" |
| ⏱️ Typical response time | Rolling median time-to-first-action, bucketed (not exact), loan or forex | "⏱️ Responds quickly" |

These render as a compact badge row on `ListingCard` (loan or forex card), the offers panel, and `ProfilePage` — the same shared component, `TrustBadgeRow`, everywhere a counterparty appears, so the signal is consistent across the app and across modules.

```
John K.
⭐ 4.7 (18 reviews)
🔁 Repeat Lender
📊 9 successful deals   -- 6 loan deals + 3 forex deals, shown as one combined count
📱 Phone verified
⏱️ Responds quickly
```

Note the deliberate framing on the last line: the badge says **"Phone verified"**, not the phone number itself — verification status is public, the underlying contact detail stays locked behind the existing contact-reveal flow, unchanged by which module the deal is on. A profile with no history yet renders these as **"No reviews yet"** and **"0 completed"** — the same badge slots, just at their zero-state, never hidden or omitted.

### What's monetized (Pro tier)

| Enhancement | Description | Why Pro, not Free |
|---|---|---|
| 🟦 Verified badge | Awarded after full KYC review (existing `kyc_verifications` approval flow) | Stronger than the free phone-verified badge because it's backed by ID review, not just an OTP; the review cost/effort justifies gating it behind Pro |
| 📊 Success rate | Share of an account's offers accepted, or requests that reached contract, computed across **all markets and both modules** | Interpretive analytics, not raw reputation data — Free users still see the raw counts (completed deals, ratings) that this rate is derived from |
| 🔍 Reliability score | Single derived score combining rating, completion count, and response time, computed identically regardless of loan/forex mix | A convenience summary of already-public data, not new information — appropriate as a paid-tier UX enhancement, not a data-access gate |
| 🚀 Priority visibility | Pro-posted requests and Pro offer-maker profiles get improved placement, loan or forex | Existing Pro benefit, reinforced by the verified badge appearing alongside it |

This table is intentionally scoped to **interpretation and verification weight**, not to withholding raw trust data — see "Guardrail" below.

### Guardrail: what must never be paywalled

- ❌ Never hide star ratings, review counts, or completed-deal counts behind a plan
- ❌ Never hide the repeat-participant or phone-verified badges behind a plan
- ❌ Never split trust data by module (no separate "Loans score" vs "Forex score" — one combined identity, one combined reputation)
- ❌ Never display or compute a signal that implies knowledge of off-platform repayment or settlement behavior (e.g. "on-time repayment rate," "settlement completion rate") — Nipanze has no visibility into money or currency movement after contact reveal, so any such claim would misrepresent the platform's actual knowledge and conflicts with the Regulatory Compliance boundary
- ❌ Never let Pro purchase a *fabricated* trust signal (e.g. a boosted rating) — Pro only adds a verification badge (backed by real KYC) and analytics derived from real, existing data

### Reviews

- Left only by the counterparty on a **completed contract**, loan or forex — one review per contract, per direction (so a single deal can produce up to two reviews, one from each side)
- 1–5 star rating plus optional short text
- Immutable once submitted, logged to `audit_logs`
- Moderated the same way KYC documents are — visible to admins for abuse review (Stage 5), never edited by the platform itself
- `submit_review(contract_id, rating, comment)` RPC validates server-side that the caller was actually a party to that contract (loan or forex) before writing, and triggers `recompute_trust_aggregates(user_id)` on the counterparty afterward — the aggregate recompute is module-agnostic, it just sums across whatever contract types exist

### Data model impact

- `reviews` table: `id`, `contract_id`, `reviewer_id`, `reviewee_id`, `rating` (1–5), `comment` (nullable, short text), `created_at` — unique constraint on `(contract_id, reviewer_id)` to enforce one review per contract per direction. `contract_id` may reference either a loan-originated or forex-originated contract; the table itself does not branch on module
- `profiles` gains `phone_verified_at` (nullable timestamp)
- Cached aggregate columns (or a dedicated `trust_aggregates` table, TBD at implementation time) holding `rating_avg`, `review_count`, `completed_deals_count`, `is_repeat_participant`, `response_time_bucket` per user, refreshed by `recompute_trust_aggregates(user_id)` on relevant events (new review, new completed contract, loan or forex) — **one row per user, not one row per user per module**
- View `v_trust_profile_public` — readable by any authenticated user, returns the Free-tier signal set for a given `user_id`, combined across modules
- View `v_trust_profile_pro` — RLS-scoped to callers whose own `subscription_plan = 'pro'`, returns `success_rate` and `reliability_score` for a given `user_id` on top of the public set, combined across modules

### 💰 Contact-unlock fee — flagged as an open decision, not yet committed

Product feedback also proposed a flat, per-unlock contact fee (a few thousand UGX, or the local-currency equivalent), charged at the moment contact is revealed, free or discounted for Pro, as a second revenue engine alongside subscriptions — applicable identically to loan and forex contact reveals. This is **not folded into the committed Stage 4 scope**, because it changes two things currently treated as fixed elsewhere in this plan and in the README:

1. The stated principle that Nipanze earns revenue **"primarily through subscriptions — not interest spreads and not currency-exchange spreads — via a single upgrade path"** would need to explicitly become "subscriptions plus a flat, disclosed contact-unlock fee"
2. `reveal_contact` today is purely **status-gated** (owner has accepted an offer → both parties may unlock), loan or forex — a paid unlock means adding a payment-confirmation step in front of the existing unlock logic, plus a payment provider integration that doesn't otherwise exist in this stack

**If this is adopted**, the fee must stay flat and disclosed up front — never a percentage of loan amount, interest rate, exchange amount, or exchange rate — to remain consistent with the "no fee tied to deal performance" principle in Regulatory Compliance. It is tracked here as a **Stage 4 decision point** requiring an explicit go/no-go before implementation, rather than assumed into the checklist below. Recommendation: ship the trust system and selective transparency first for Loans, extend both to Forex in Stage 4.7 (both reinforce trust and offer-making without touching money or currency), then revisit contact-unlock pricing once there's real usage data on how often contact reveal happens on each module.

### 💵 Pricing note (flagged, not changed)

Product feedback separately suggested the (previously undocumented) Pro price point may be too high for the target Uganda early-stage market, and recommended validating actual subscription pricing against local willingness-to-pay before Stage 6 launch — and, as of v6.0, doing so **independently per market**, since a UGX price is never simply copy-pasted as the same numeral in NGN, ZAR, EGP, KES, TZS, or RWF. This build plan does not currently commit to specific figures for any tier in any currency — pricing is a business decision to be finalized closer to each market's own Stage 6 launch, with real local market input, not assumed from another market's figures. There is no separate Forex subscription price — the same `subscriptions` row and price point governs offer-making and term-suggestion for both Loans and Forex.

---

## 🎯 Pro Advanced Marketplace Filters (v4.2 — Loans-scoped at introduction; forex-equivalent flagged for Stage 4.7)

Pro-tier users can access advanced filtering controls on the marketplace feed to find listings matching specific borrower profile attributes or listing status details.
- **Employment type filter:** Filter borrower profiles by categorical type (e.g. `government_employee`, `employed`, `self_employed`, `small_business_owner`, `business_owner`, `student`, `other`).
- **Income bracket filter:** Filter borrower profiles by a coarse monthly income bracket (using `fn_income_bracket`: `under_2m`, `2m_5m`, `5m_10m`, `over_10m`, denominated in that request's own local currency).
- **Suggested terms filter:** Limit the feed to requests carrying suggested terms locked by a Pro poster at publish time — loan interest/late fee/schedule, or forex preferred rate.
- **Verified status filter:** Limit the feed to requests from KYC-approved owners.

This capability is gated at the DB layer via the `v_marketplace_pro_filters` view (which checks for an active Pro subscription and returns zero rows if absent) and the `get_marketplace_pro_filtered` RPC. In the UI, the filters are presented via an entry icon button next to the notification bell (Option B) opening a bottom sheet, gated strictly to Pro users. Income/employment filters are loan-specific by nature (a forex request has no "income source"); the suggested-terms and verified-status filters apply to both modules and should filter across `All / Loans / Forex` consistently with whichever marketplace tab is active. Full forex-side filter parity (e.g. filtering by currency pair or settlement method) is not committed in this version — flagged as a Stage 4.7 candidate, not required for that stage's exit criteria.

---

## 🌍 Multi-Market Architecture (v6.0 — supersedes the v5.0 "Multi-Country Expansion Model (EAC)" section below in full)

> **This section replaces the earlier East African Community (EAC)-only framing.** The v5.0 draft of this plan targeted all eight EAC member states, including Burundi, South Sudan, DR Congo, and Somalia. That framing is retired. The committed v6.0 scope is the seven-market list below — a deliberate shift from a single regional bloc to three African regions. The underlying schema pattern is unchanged (see "Why one shared schema, not one per country" below); only the *committed market list* has changed.

### Scope: Uganda first, then six planned markets across three regions

| Country | Code | Currency | Currency Code | Phone Prefix | Region |
|---|---|---|---|---|---|
| 🇺🇬 Uganda | `UG` | Ugandan Shilling | `UGX` | `+256` | East Africa — **launch market** |
| 🇰🇪 Kenya | `KE` | Kenyan Shilling | `KES` | `+254` | East Africa |
| 🇹🇿 Tanzania | `TZ` | Tanzanian Shilling | `TZS` | `+255` | East Africa |
| 🇷🇼 Rwanda | `RW` | Rwandan Franc | `RWF` | `+250` | East Africa |
| 🇳🇬 Nigeria | `NG` | Nigerian Naira | `NGN` | `+234` | West Africa |
| 🇿🇦 South Africa | `ZA` | South African Rand | `ZAR` | `+27` | Southern Africa |
| 🇪🇬 Egypt | `EG` | Egyptian Pound | `EGP` | `+20` | North Africa |

All seven are seeded in the `countries` table from the Stage 4.5 migration onward. Uganda is the only market with `is_active = TRUE` at launch (lending); the other six activate independently, in the order listed above, as each clears its own pricing, payment-rail coverage, and compliance review — see Roadmap. Seeding all seven up front means the country picker, admin per-country settings, and currency-formatting logic never need a schema change to support a market that hasn't launched yet.

### Why one shared schema, not one per country (unchanged rationale from v5.0)

A per-country table design (`loan_requests_uganda`, `loan_requests_nigeria`, …) was considered and rejected: it would multiply every RLS policy, trigger, view, and RPC in this schema by the number of countries, turn cross-market admin reporting into a UNION query across up to seven tables, and make launching a new country a migration project instead of a one-row data insert. Instead:

1. **One `countries` reference table** (`code`, `name`, `currency_code`, `phone_prefix`, `is_active`, `forex_enabled`) — adding a new market is one row insert (already done for all seven); *launching lending* in a market is one `UPDATE ... SET is_active = TRUE`; *launching forex* in a market is the independent `forex_enabled` flag (see Forex Marketplace Expansion Model below)
2. **`profiles.country`, `loan_requests.country`, and `forex_requests.country`** — indexed, non-nullable columns that make every user and every listing's market explicit and queryable
3. **`loan_offers` and `forex_offers` have no country of their own** — an offer's country is always its parent request's country, read through the join, so there's exactly one source of truth for "what market is this offer in," not one that can drift out of sync across seven markets or two modules
4. Cross-country admin reporting stays a single `GROUP BY country` query, not a UNION across per-country tables
5. A single indexed `country` column on an already-indexed table scales to millions of rows per market without needing physical table separation — Postgres doesn't need help here at Nipanze's expected scale

### Country as a first-class, indexed column — not a derived guess

`country` is stored explicitly on `profiles` (source of truth for a user), `loan_requests`, and `forex_requests` (source of truth for a listing). It is **not** re-derived per-query from phone prefix or IP — those are only used as a *default suggestion* at onboarding, never as the enforced value:

| Signal | Role |
|---|---|
| `profiles.country` | Source of truth once set. Required, not nullable, after onboarding completes. |
| Phone prefix (`+256`→UG, `+254`→KE, `+255`→TZ, `+250`→RW, `+234`→NG, `+27`→ZA, `+20`→EG) | Onboarding-time **default suggestion** only — user can override before confirming |
| GPS / IP geolocation | Optional, same role as phone prefix — a suggestion, never silently trusted |
| `loan_requests.country` / `forex_requests.country` | Copied from `profiles.country` at creation time, via trigger — see below |

> **Why copy `country` onto the request tables instead of joining to `profiles.country` on every query?** Two reasons: it lets the marketplace feed filter and index on `loan_requests.country` / `forex_requests.country` directly without a join, and it freezes the listing's country at post time — if a user's profile country is later corrected, it shouldn't silently move an already-published listing into a different market's feed.

### Offers inherit country from their request — never stored independently

Neither `loan_offers` nor `forex_offers` carries a `country` column. An offer's country is entirely determined by the request it's offering on (`request_id → loan_requests.country` or `request_id → forex_requests.country`). Storing it a second time on the offer row would create a value that can drift from its source of truth for no benefit — every query that needs an offer's country already has to join the request table for listing details anyway.

This also means a lender in Nigeria is not blocked from making an offer on a Uganda listing at the database layer just because their `profiles.country = 'NG'` — see "Cross-border offers" below.

### New table: `countries`

```sql
-- countries (conceptual)
code            TEXT PRIMARY KEY   -- ISO 3166-1 alpha-2
name            TEXT NOT NULL
currency_code   TEXT NOT NULL      -- ISO 4217
phone_prefix    TEXT NOT NULL      -- used for onboarding suggestion only, never enforced
is_active       BOOLEAN NOT NULL DEFAULT FALSE  -- gates whether new LOAN listings can be posted in this market
forex_enabled   BOOLEAN NOT NULL DEFAULT FALSE  -- independent gate for FOREX listings, see Forex Expansion Model
created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP

-- seed: all 7 markets, seeded together, each flag activated independently
-- ('UG', 'Uganda',       'UGX', '+256', TRUE,  FALSE)  -- lending live at migration time; forex flips independently at Stage 4.7
-- ('KE', 'Kenya',        'KES', '+254', FALSE, FALSE)
-- ('TZ', 'Tanzania',     'TZS', '+255', FALSE, FALSE)
-- ('RW', 'Rwanda',       'RWF', '+250', FALSE, FALSE)
-- ('NG', 'Nigeria',      'NGN', '+234', FALSE, FALSE)
-- ('ZA', 'South Africa', 'ZAR', '+27',  FALSE, FALSE)
-- ('EG', 'Egypt',        'EGP', '+20',  FALSE, FALSE)
```

`profiles.country`, `loan_requests.country`, and `forex_requests.country` are all `TEXT NOT NULL REFERENCES countries(code)`. Launching lending in a new market becomes: `UPDATE countries SET is_active = TRUE WHERE code = 'KE'`, no migration required, since the row already exists. Launching forex in that same market is a **separate** statement on `forex_enabled`, on its own timeline. Pausing a market (e.g. for compliance review) is the same statement in reverse — new listings blocked, existing ones and history untouched.

### Currency travels with country — never assume UGX again, and is decoupled via `currencies`

`requested_amount`, `repayment_amount_per_period`, `offer_amount`, `forex_offers.amount_available`, and every other monetary figure are **plain `BIGINT` minor-unit-free numbers with no currency of their own** — they are only meaningful alongside the row's `country → countries.currency_code` (for loans) or the request's explicit `currency_held` / `currency_needed` pair (for forex). Concretely:

- The marketplace feed, listing detail, and offer views must all resolve and display the relevant currency code next to every amount (via a join or a denormalized `currency_code` column on `v_loan_listings` / `v_lender_offers`, and `currency_held`/`currency_needed` on `v_forex_listings` / `v_forex_offers`, for query simplicity)
- **A UGX 5,000,000 loan request and a KES 5,000,000 loan request are not comparable** — nor are any two amounts across any two of the seven market currencies (`UGX`, `KES`, `TZS`, `RWF`, `NGN`, `ZAR`, `EGP`), nor across USD where permitted. The app must never sum, average, or rank amounts across currencies without conversion (out of scope — see "What this does not include" below). This applies equally to admin cross-market KPI views (`v_marketplace_activity`) — a "total requested" figure across markets is either broken down per currency or omitted, never silently summed as if all currencies were the same unit
- `system_settings` limits like `min_loan_amount` / `max_loan_amount` are **per-country**, via a `country` column on `system_settings` with a composite unique key on `(setting_key, country)` — reuses the existing table and admin UI with one extra filter column, rather than standing up a parallel settings table. `system_settings` also gains `allow_foreign_currency_loans` (per country, boolean) — see the `currencies` section immediately below

Because currency questions turned out to be more granular than "one country, one currency" — loan currency choice, subscription billing currency, and forex-tradeable-currency clearance are three genuinely different decisions with three different risk profiles — v6.0 introduces a **dedicated `currencies` reference table**, decoupled from `countries`:

```sql
-- currencies (conceptual)
code                    TEXT PRIMARY KEY   -- ISO 4217, e.g. UGX, KES, TZS, RWF, NGN, ZAR, EGP, USD
name                    TEXT NOT NULL
is_market_currency      BOOLEAN NOT NULL DEFAULT FALSE   -- TRUE for the 7 currencies tied to a live/planned Nipanze country
market_country          TEXT REFERENCES countries(code)  -- set only when is_market_currency = TRUE
forex_trading_enabled   BOOLEAN NOT NULL DEFAULT FALSE    -- gates use in a forex_requests pair, independent of loan usage
created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP

-- seed: the 7 market currencies (UGX, KES, TZS, RWF, NGN, ZAR, EGP) plus USD — 8 rows total
-- forex_trading_enabled starts FALSE for every one of them, including the market currencies
```

| Question | Answer | Where it's decided |
|---|---|---|
| Can I post a loan request in my own country's currency? | Always yes | Default — no flag needed |
| Can I post a loan request in USD instead of my local currency? | Only where the market allows it | `system_settings.allow_foreign_currency_loans` (per country) — lighter check, mainly about that country's rules on foreign-currency-denominated P2P lending |
| Can I pay my subscription in USD instead of local currency? | Yes, wherever offered | Pure billing-currency choice — no different in kind from billing in local currency |
| Can a forex request trade *into or out of* USD (or any currency)? | Only if that currency is explicitly cleared for forex trading | `currencies.forex_trading_enabled` — real exposure to currency-exchange/bureau-style licensing, defaults to **off** for every currency until reviewed |

A single `countries.currency_tradeable` flag was considered and rejected, because it conflates "does this currency exist in Nipanze's vocabulary at all" (needed for loans and subscriptions, lower stakes) with "is it cleared to appear in a forex pair" (needed only for Forex, higher stakes, closer to bureau-de-change territory). Splitting them means Nigeria's NGN can be fully usable for NGN-denominated loans and NGN subscription billing on day one, while NGN's forex-trading clearance is reviewed and flipped on its own timeline — without touching the Loans module at all. Full detail and rationale: see Forex Marketplace Expansion Model below.

### Marketplace filtering — server-enforced, not just a UI filter

A user's marketplace feed defaults to their own `profiles.country`, across **both** Loans and Forex. This is implemented at **two layers**, matching how every other access rule in this schema works — never trusted from the client alone:

**1. Application-level default filter** — `MarketplaceRepository` queries `v_loan_listings WHERE country = :userCountry` and `v_forex_listings WHERE country = :userCountry` by default. This is the normal, fast path and is what powers the live feed and Realtime stream for both modules.

**2. RLS-level boundary (policy decision — resolved for v6.0)** — Nipanze ships with **global browse**, not hard isolation: any authenticated user can query any active market's public marketplace feed, loan or forex. The app defaults to the user's home country and lets them switch explicitly. This supports diaspora and cross-border lending/currency-exchange relationships (East Africans, Nigerians, South Africans, and Egyptians abroad funding family back home, or converting currency person-to-person) as a real, valuable use case rather than blocking it. Forex, being inherently cross-currency, leans on this browse-other-markets path more than loans do by default (see Forex Expansion Model).

> **Non-spoofable RLS pattern, unchanged from v5.0:** country-scoped RLS (where it applies, e.g. to admin-only cross-market writes) uses a subquery against `profiles`, not a JWT custom claim or `user_metadata` (both of which are either extra infrastructure or client-writable and therefore not safe to gate access on):
> ```sql
> USING (
>   country = (SELECT country FROM profiles WHERE id = auth.uid())
>   OR private.is_admin()
> )
> ```

### Cross-border offers — resolved for v6.0: allowed

Nipanze launches with cross-border offers **allowed** across all seven markets for both modules — simpler, and a genuine value-add: diaspora capital is common throughout the expansion list (Nigerian capital funding Nigerian requests from a South-Africa-registered account, and so on). `trg_fn_validate_offer` / `trg_fn_validate_forex_offer` do not carry a country-match check. This is revisited only if fraud/compliance review in Stage 5 flags a specific reason to restrict it per market. This decision is currency-neutral either way — a loan offer's currency always matches its listing's currency, and a forex offer's rate is always denominated in the listing's declared currency pair, regardless of what country the offer-maker is registered in.

### Regulatory diversity across these seven markets is real — flagged, not glossed over

Unlike the retired EAC-only framing, where all target markets shared a regional bloc and broadly similar mobile-money-led payment landscapes, the seven-market list spans **materially different regulatory regimes and payment landscapes**: East Africa's mobile-money-dominant rails differ from Nigeria's card/bank-transfer-and-fintech-native rails, South Africa's mature card/EFT banking system, and Egypt's currency-control history around the EGP. This document does not constitute legal advice — every market needs its own local regulatory review before `countries.is_active` (lending) or `countries.forex_enabled` (forex) is flipped, and that review should be treated as **more consequential** now than it was under the single-bloc EAC plan, not routine. See Regulatory Compliance.

### Trust & Reputation aggregates stay global per user, not per-country or per-module

Unchanged from v5.0, extended to modules: `trust_aggregates` remain **one row per user** — not per country, not per module. A lender who has completed 9 loan deals in Uganda and is now browsing Nigerian forex listings for the first time shows up with their real track record, not a blank slate. A future `completed_deals_in_country` additive column is a possible enhancement, not committed.

### 💳 Payments Infrastructure (Flutterwave / Paystack / comparable aggregator) — scoped addendum

Multi-market makes one thing unavoidable: subscriptions and any future contact-unlock fee need to be **charged and settled in the payer's own currency**, across mobile-money, card, and bank-transfer/EFT rails that vary meaningfully across three regions — East Africa's mobile-money-dominant rails, Nigeria's card/bank-transfer/fintech-native rails, South Africa's mature card/EFT system, and Egypt's own landscape. Flutterwave and Paystack (or a comparable aggregator) are reasonable fits for exactly this reason: broader API coverage across mobile money and cards than integrating each provider per country directly — but coverage is **not uniform across all seven markets** and must be verified per market before activation, not assumed from another market's success.

**Critical scope boundary — this must not be confused with the money or currency exchanged between users:**

- ✅ In scope for payment integration: **Nipanze's own revenue** — `subscriptions` (Lender/Pro plan payment) and, if the open decision above is ever resolved to "yes," the flat contact-unlock fee, for both Loans and Forex
- ❌ **Never** in scope: any money or currency exchanged between two matched users. Loan principal, interest, and repayment — and forex principal and settlement — all stay **entirely off-platform**, exactly as stated in Architecture Constraint #1. Adding an aggregator for subscriptions does **not** change Nipanze's non-custodial positioning — it's Nipanze charging its own customers for its own service, not touching P2P loan funds or exchanged currency

**Table: `transactions`**

```sql
-- transactions (conceptual)
id                       UUID PRIMARY KEY
user_id                  UUID NOT NULL REFERENCES profiles(id)
type                     TEXT NOT NULL   -- 'subscription' | 'contact_unlock'
amount                   BIGINT NOT NULL
currency_code            TEXT NOT NULL REFERENCES currencies(code)
country                  TEXT NOT NULL REFERENCES countries(code)   -- payer's country at time of charge
provider                 TEXT NOT NULL DEFAULT 'flutterwave'
provider_tx_ref          TEXT NOT NULL UNIQUE   -- idempotency key Nipanze generates and sends to the provider
provider_tx_id           TEXT                    -- provider's own reference, populated on webhook confirm
status                   TEXT NOT NULL DEFAULT 'pending'  -- 'pending' | 'successful' | 'failed' | 'reversed'
related_subscription_id  UUID REFERENCES subscriptions(id)
related_reveal_id        UUID REFERENCES contact_reveals(id)
webhook_verified_at      TIMESTAMP   -- set only after the webhook signature check passes — never trust the client-side redirect alone
created_at               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
updated_at               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
```

Design notes that matter more than the table itself:

- `provider_tx_ref` is generated by Nipanze, not the provider, before the charge is initiated — retries and webhook replays stay idempotent; insert `pending`, call the provider with that ref, only ever transition status on a verified webhook, never on the client's post-payment redirect
- **The webhook handler is the only writer of `status = 'successful'`**, runs as an Edge Function with the provider's secret hash verified against the request signature first, and is idempotent on `provider_tx_ref`
- `provider` is plain text, not an enum, specifically so a second processor can be added later without a schema migration
- Upgrading a user's `subscriptions.plan` happens **only after** `transactions.status = 'successful'` — never optimistically on redirect
- RLS: `user_id = auth.uid() OR private.is_admin()` for read; all writes happen through the service-role Edge Function, never directly from the Flutter client

**Sequencing:** payments infrastructure does not need to ship with the market-expansion migration itself — `countries`, `currencies`, `profiles.country`, `loan_requests.country`, and `forex_requests.country` are useful and shippable with subscriptions still handled off-platform, per the existing `AccountPage` note in Stage 3. Aggregator integration is realistically a **Stage 6 (Launch & Growth)** item, once pricing per market is finalized.

### What this does not include (explicitly out of scope for v6.0)

- ❌ **Currency conversion or cross-currency comparison** — Nipanze displays each loan listing in its own market's currency and does not convert between them; Nipanze never quotes a "platform rate" for forex either — see Forex Expansion Model
- ❌ **Per-country subscription pricing localization logic beyond a currency-agnostic amount column** — `subscriptions.amount_minor_units` is currency-agnostic on its own and only meaningful alongside the subscriber's `profiles.country` or opted-in USD billing currency; actual per-market price points remain a Stage 6 business decision
- ❌ **Language localization** — a separate, unrelated effort not addressed here
- ❌ **Country-specific KYC document types** beyond what `kyc_verifications.national_id_type` (free text) already absorbs — validation rules per country are an app-layer concern for later
- ❌ **P2P loan payment or forex settlement processing of any kind** — aggregator integration, if adopted, touches subscriptions and unlock fees only

### Data model impact summary

| Table | Change |
|---|---|
| `countries` | **New table** — `code`, `name`, `currency_code`, `phone_prefix`, `is_active`, `forex_enabled` |
| `currencies` | **New table, v6.0** — `code`, `name`, `is_market_currency`, `market_country`, `forex_trading_enabled` |
| `profiles` | **+ `country` column**, `TEXT NOT NULL REFERENCES countries(code)`, default set at onboarding |
| `loan_requests` | **+ `country` column**, set by trigger from `profiles.country` at insert, immutable after |
| `forex_requests` | **New table, Stage 4.7** — `currency_held`, `currency_needed`, `amount`, optional `preferred_rate`, settlement preference, `country` locked at insert (same trigger pattern) |
| `loan_offers` | **No new column** — country read via `loan_requests.country` through `request_id` |
| `forex_offers` | **New table, Stage 4.7** — `rate_offered`, `amount_available`, `terms`; no `country` column — read via `forex_requests.country` through `request_id` |
| `system_settings` | **+ `country` column** (nullable = global default), **+ `allow_foreign_currency_loans`** per country; composite unique on `(setting_key, country)` |
| `subscriptions` | `amount_ugx` → `amount_minor_units`; currency implied by the subscriber's `profiles.country` or opted-in USD |
| `v_loan_listings` | **+ `country`, + `currency_code`** (joined from `countries`) |
| `v_forex_listings` | **New view, Stage 4.7** — `country`, `currency_held`, `currency_needed`, `rate_coverage_tier` |
| `v_lender_offers` | **+ `country`, + `currency_code`** (joined through `loan_requests` → `countries`) |
| `v_forex_offers` | **New view, Stage 4.7** — participant-scoped exact rate/amount/terms, joined through `forex_requests` → `countries` |
| `v_marketplace_activity` | **+ `country` grouping**, **+ `request_type` grouping** (loan/forex) — admin KPIs sliceable per market and per module |
| `trust_aggregates` | **Unchanged** — stays global per user, combined across modules |
| `transactions` | **New table, Stage 6** — payment records for subscriptions and contact-unlock fees only; never P2P loan funds or exchanged currency |

---

## 💱 Forex Marketplace Expansion Model (v6.0 — new, Stage 4.7)

Nipanze extends the unified marketplace model beyond lending to **peer-to-peer foreign exchange (forex) requests** — connecting people who hold one currency and need another with people willing to exchange, directly, without a bank or bureau de change sitting in the middle. Forex is the second of Nipanze's two modules — see "Two Projects, One Platform" above — running on the same shared schema, subscription plans, and non-custodial boundary as Loans.

**Core Principle:** Forex is matchmaking, not exchange. Nipanze never holds, converts, or moves currency on anyone's behalf, in any market.

### Why this is a small stage, not a rebuild

Every governing model in this document — Unified Marketplace, Selective Transparency, Trust & Reputation — was written (or, in v6.0, rewritten) to be module-parametric. Stage 4.7's job is narrower than it looks:

- **Reuse, don't reinvent:** subscription gating, the locked-bidding pattern, the participant-gated-detail pattern, the trust-aggregate pattern, and the contact-reveal boundary all already exist in shape from Stage 4 — Stage 4.7 wires forex request/offer tables into that existing machinery
- **New, module-specific work:** `forex_requests` / `forex_offers` tables, `currencies.forex_trading_enabled` gating, the `ForexDetailPage` UI and Send/Rate/Receive listing-card widget, and the forex-specific Edge Function (`make-forex-offer`)

### Fits the existing unified model

- **Post a Forex Request** — free, same as posting a loan request
- **Make a Forex Offer** — requires the Lender plan, same as making a loan offer
- **Suggest a preferred rate** on a posted forex request — requires the Pro plan
- One dashboard, one Positions tab, one `subscription_plan` gates both modules identically

### Request structure

A forex request specifies:

- **Currency held** and **currency needed** — both must have `forex_trading_enabled = TRUE` in `currencies`, checked server-side at request creation
- **Amount** to exchange
- **Preferred rate** (optional) — Pro-only field, locked on publish
- **Settlement preference** — in-person, mobile money, bank transfer, or other off-platform method, disclosed as a preference only, never brokered by the platform

An offer against a forex request specifies:

- **Exchange rate offered**
- **Available amount**
- **Terms** (settlement method, timing) — locked on submit, denominated in the listing's currency

### Cross-border and cross-currency by nature

A forex request is inherently about two currencies, and the primary use case (diaspora/cross-border transfer) is inherently cross-border. A Uganda-registered user can post `UGX → KES`, `UGX → NGN`, or `UGX → USD` (where USD is cleared for trading), just as a Nigeria-registered user might post `NGN → ZAR`. `forex_requests.country` still tells you *where the requester is*; it never constrains *which two currencies* the request is about. Nipanze does **not** perform the conversion or quote a "platform rate" anywhere — every rate shown is a specific offer-maker's own proposed rate.

### Selective transparency and trust — same model, no exceptions

Forex listings use the identical tiered-visibility model as loans (see Selective Transparency Model above) and feed the identical global trust aggregate as loans (see Trust & Reputation System above). A user's forex deal history and loan deal history contribute to one combined reputation, not two separate scores.

### Non-custodial by design

- **Does not** hold, pool, or transfer either currency, at any point
- **Does not** act as a broker, dealer, or counterparty to the exchange
- **Does not** guarantee a rate, quote a platform rate, or guarantee the exchange completes
- **Does not** touch settlement — cash, mobile money, or bank transfer between the two parties happens entirely off-platform, after contact is revealed

### A genuinely separate compliance surface

Currency-exchange facilitation can carry its own licensing requirements distinct from loan matchmaking, even within a market where lending is already cleared — this is why `countries.forex_enabled` is a flag independent of `countries.is_active`, and why `currencies.forex_trading_enabled` is independently gated per currency (see Multi-Market Architecture above). Uganda launching with lending active does not imply Uganda launches with forex active on day one — see Stage 4.7 exit criteria below.

### Schema

| Table | Purpose |
|---|---|
| `forex_requests` | Structured exchange requests: `currency_held`, `currency_needed`, `amount`, optional `preferred_rate` (Pro-only, locked on publish), settlement preference, `country` (locked at insert, same trigger pattern as `loan_requests`) |
| `forex_offers` | Offers against a forex request: `rate_offered`, `amount_available`, `terms` (locked on submit) — no `country` of its own, read through `request_id → forex_requests.country` |

### New triggers and functions (Stage 4.7)

| Name | Type | Purpose |
| --- | --- | --- |
| `trg_fn_set_forex_request_country` | Trigger fn | Copies `country` onto a new `forex_requests` row at insert; locked thereafter — mirrors `trg_fn_set_request_country` |
| `trg_fn_validate_forex_offer` | Trigger fn | Validates `currency_held`/`currency_needed` are both `forex_trading_enabled` at request-creation time |
| `get_public_forex_offers(request_id)` | RPC | Anonymized public offer book for active forex listings — mirrors `get_public_listing_offers` |
| `make-forex-offer` | Edge Function | Server-side subscription-plan validation for forex offers, plus currency-eligibility check |

### Marketplace feed and listing-card impact

The Marketplace screen gains an `All / Loans / Forex` filter row — three pill-style tabs above the feed. `All` interleaves both modules chronologically; `Loans` and `Forex` each show only their own module's listings. Filtering here is purely presentational — it's the same `country`-scoped queries against `v_loan_listings` and `v_forex_listings`, just merged or split for display.

**Forex listing card** (new widget, `SendRateReceivePanel`):
- Badge: `Forex` (blue dot); loan cards keep their `Loan` badge (green dot)
- Meta line: location · turnaround (e.g. "Kampala · Instant")
- Title as a directional pair (e.g. "USD → UGX Exchange")
- Headline amount in the currency the requester needs
- **Send / Rate / Receive panel** — replaces the loan card's funded-% bar, since a forex request has a rate, not a "funded percentage"
- `⚡ Urgent` tag for time-sensitive requests (near `expires_at`, or explicitly flagged at posting) — reuses the existing watchlist closing-soon urgency signal, surfaced inline instead of as a card border
- Same `TrustBadgeRow` pattern as loan cards — trust is module-agnostic

### Stage 4.7 Implementation Checklist

- [ ] `currencies` table created; seeded with the 7 market currencies + USD, all `forex_trading_enabled = FALSE`
- [ ] `countries.forex_enabled` column added, default `FALSE` for all 7 seeded rows
- [ ] `forex_requests` table created: `currency_held`, `currency_needed`, `amount`, `preferred_rate` (nullable, Pro-only), settlement preference, `country` (trigger-set, locked)
- [ ] `forex_offers` table created: `rate_offered`, `amount_available`, `terms` (locked on submit), `request_id → forex_requests`
- [ ] `trg_fn_set_forex_request_country` and `trg_fn_validate_forex_offer` implemented and tested
- [ ] `v_forex_listings` view — public forex marketplace listings, `country` + `currency_held`/`currency_needed` + `rate_coverage_tier`
- [ ] `v_forex_offers` view — participant-scoped exact rate/amount/terms, `security_invoker` + RLS, mirrors `v_lender_offers`
- [ ] `get_public_forex_offers(request_id)` RPC — mirrors `get_public_listing_offers`, branches on caller identity
- [ ] `make-forex-offer` Edge Function — subscription-plan check + currency-eligibility check server-side
- [ ] `ForexCreatePage` (`/forex/create`) — currency-pair picker (filtered to `forex_trading_enabled = TRUE` pairs only), amount, optional Pro-only preferred rate, settlement preference
- [ ] `ForexDetailPage` (`/forex/:requestId`) — tiered offers panel reusing the Selective Transparency pattern, Send/Rate/Receive display
- [ ] `MyForexRequestsPage` (`/forex/my-forex`) — mirrors `MyRequestsPage`
- [ ] Marketplace `All / Loans / Forex` filter row implemented; `v_loan_listings` and `v_forex_listings` merged for `All`
- [ ] Forex listing card (`SendRateReceivePanel` widget) implemented per the design above
- [ ] Positions tab extended: My Requests and My Offers both show loan and forex entries in one list, filterable
- [ ] Watchlist extended to support saving forex listings alongside loan listings
- [ ] Contract generation and contact reveal extended to forex-originated contracts, reusing `accept_offer` / `reveal_contact` with a module parameter
- [ ] Trust aggregate recompute confirmed to combine loan and forex contract counts into one `completed_deals_count`
- [ ] Reviews confirmed to work identically for a forex-originated `contract_id`
- [ ] Unit/integration tests: a currency pair with either leg `forex_trading_enabled = FALSE` is rejected at request creation, server-side, even if the client UI is bypassed
- [ ] Unit/integration tests: non-participant querying `v_forex_offers` or `get_public_forex_offers` directly receives only the aggregate `rate_coverage_tier` payload

### Stage 4.7 Exit Criteria

- [ ] `currencies` table live with all 8 rows (7 market currencies + USD), `forex_trading_enabled` reviewable and toggleable per currency without a schema change
- [ ] `countries.forex_enabled` toggle independently controls forex availability per market, decoupled from `countries.is_active`
- [ ] A user can post a free forex request specifying a currency pair, amount, and settlement preference, limited to `forex_trading_enabled` pairs
- [ ] A Lender/Pro-plan user can make a forex offer with rate, amount, and terms, locked on submit
- [ ] A Pro-plan user can suggest a preferred rate when posting a forex request, locked on publish
- [ ] Forex listing detail follows the identical Selective Transparency tiers as loan listings — exact rate/amount/terms visible only to the owner and to offer-makers with a live offer on that listing
- [ ] Forex deal history feeds the same global `trust_aggregates` row as loan deal history — no separate forex trust score
- [ ] Marketplace `All / Loans / Forex` filter functions correctly, defaulting to the user's country for both modules
- [ ] Contact reveal on an accepted forex offer follows the identical contract → reveal flow as loans
- [ ] Uganda can go live for forex (`forex_enabled = TRUE`) independently of any other market's lending or forex status, verified in staging by flipping only Uganda's flag

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

> Unaffected by v6.0 — no country or module concept existed yet, which is expected for a foundation stage.

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

> Note: in Stage 2 the offers panel on `LoanDetailPage` showed every offer's exact terms to any viewer. Stage 4 replaces this with the **Selective Transparency Model** above — full exact-term detail becomes participant-gated, while the aggregate signal (offer count + coverage tier) stays visible to everyone. Stage 4 additionally layers the **Trust & Reputation System** above on top of every listing and profile, independent of that tiering. Stage 4.7 extends both models to Forex with no separate design.

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

> **Stage 4.5 note:** once the multi-market migration lands, `MarketplaceRepository` and `v_loan_listings` gain the `country` filter described in the Multi-Market Architecture above — this is an additive change to already-shipped Stage 2 code, not a rebuild. **Stage 4.7 note:** the Forex module is entirely additive on top of Stage 2 — it does not modify `loan_requests`, `loan_offers`, or any Stage 2 code path, only adds parallel tables, views, and screens.

---

## Stage 3 — Polish & Supporting Features ✅ Complete

### 3.1 Watchlist
- [x] `WatchlistItem` model — integrated into `WatchlistLoaded` state
- [x] `WatchlistRepository` — `getWatchlist`, `getWatchedListings`, `watchWatchedListings` Realtime stream
- [x] `WatchlistCubit` — optimistic remove with Realtime updates
- [x] `WatchlistCard` — urgency border (red 6h / amber 24h), offer count, View listing, remove button
- [x] `WatchlistPage` — displays watched listings with active/closing-soon grouping, empty state, skeleton loading
- [x] "Save to watchlist" on `LoanDetailPage` writes to DB; toggles star icon

> **Stage 4.7 note:** watchlist extends to forex listings in the same table/flow — see Stage 4.7 Implementation Checklist.

### 3.2 Positions
- [x] `LenderOffer` model from `v_lender_offers`
- [x] `PositionsRepository` — `getMyOffers`, `withdrawOffer`, `getMyRequests`, `watchMyOffers` Realtime
- [x] `PositionsCubit` — loads requests + offers; Realtime offer updates; optimistic withdraw
- [x] `LenderOfferCard` — status badge, View listing, Withdraw button with confirm dialog
- [x] `PositionsPage` — 2 tabs:
  - **My Requests** — requests you've posted: active, contracted, and expired
  - **My Offers** — offers you've made, grouped Pending / Accepted / History; withdraw button live

> Note: "My Requests" and "My Offers" are simply two views of the same account's activity — not two roles. A single user can have entries in both tabs simultaneously. Positions is always a **participant** view, so it's unaffected by the Stage 4 selective-transparency tiering — a user always sees full detail on their own requests and their own offers. Trust badges on counterparty listings/offers within Positions are unaffected either way, since they're public. Also unaffected by country — Positions is already scoped to `auth.uid()`, and watched/owned listings simply carry whatever `country` they were posted with. **Stage 4.7 note:** both tabs extend to show loan and forex entries in one combined, filterable list — same account, two views, two modules.

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

> **Finish this app-testing checklist before starting Stage 4.5**, so the multi-market migration lands on a verified-stable cloud baseline rather than stacking on top of untested changes. `forex_offers`/`forex_requests` are not yet in `supabase_realtime` publication — that's a Stage 4.7 addition alongside the other Stage 4.7 schema work.

---

## Stage 4 — Structured Deal Agreement, Contact Sharing & Trust System ⬜ Planned

Stage 4 redesigns how terms are agreed upon and introduces a **locked bidding system** where both the request owner and the offer-maker commit to terms upfront — eliminating unstructured back-and-forth before a contract is generated. It also introduces the **Selective Transparency Model** and the **Trust & Reputation System** (both above), replacing Stage 2's fully public offer book with participation-gated deal detail plus an always-public reputation layer. **Stage 4 is scoped to Loans**; Stage 4.7 extends the identical machinery to Forex once Loans' version has shipped and stabilized.

See the schema (`sql/schema.sql`) for the authoritative, already-implemented definitions of `agreements`, `reviews`, `trust_aggregates`, `get_public_listing_offers`, `submit_review`, and `recompute_trust_aggregates` — these are unaffected by the market layer except that offer/listing detail now also carries `country` and `currency_code` for display, and are unaffected by the forex layer except that `recompute_trust_aggregates` sums across both contract types once Stage 4.7 ships.

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

> **Why Pro?** A request with suggested terms carries negotiating leverage — it attracts offers already aligned with the poster's preferred terms. This is the core value of the Pro tier, available to anyone regardless of whether they've ever made an offer themselves, and (Stage 4.7) equally true of a Pro-suggested forex rate. Pro's Verified badge and advanced trust insights reinforce the same "serious participant" positioning.

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
- [ ] `recompute_trust_aggregates(user_id)` trigger fn — recalculates `rating_avg`, `review_count`, `completed_deals_count`, `is_repeat_participant`, `response_time_bucket`, fired on new review / new completed contract; written to sum across contract types so it needs no change when Stage 4.7 adds forex contracts
- [ ] `v_trust_profile_public` view — public signal set, readable by any authenticated user, keyed on `user_id`
- [ ] `v_trust_profile_pro` view — RLS-scoped to callers on Pro, adds `success_rate` and `reliability_score`
- [ ] `TrustBadgeRow` shared widget — renders the public badge set consistently on `ListingCard`, offers panel rows, and `ProfilePage`, and is reused as-is for forex cards in Stage 4.7
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

> **Currency note (v6.0):** the contract text generator (`fn_generate_locked_contract_text`) and the agreement snapshot JSON should include `currency_code` explicitly, so a generated contract never displays a bare number without its currency — add this as one line item to the checklist above, not a new subsystem. **Forex note (Stage 4.7):** the same generator is reused for a forex-originated agreement, with `currency_held`/`currency_needed`/`rate_offered` in place of loan-specific fields, and a matching, module-appropriate legal disclaimer ("Nipanze does not perform the exchange or hold currency").

### 🔓 Contact Reveal Flow

After contract generation:

1. A blurred **Deal + Contact Card** is shown to both parties
2. User clicks **"Unlock Deal & Contact"**
3. Confirmation dialog: action is irreversible
4. Contact details revealed: legal name, phone, email
5. Notifications sent to both parties (`deal_unlocked`)
6. Full contract becomes visible

Contact details are **never accessible before this step** — enforced at API level via `reveal_contact` RPC. This is a separate boundary from the Selective Transparency Model above: offer-term visibility can be participant-gated well before a deal is struck, but identity stays locked until this step regardless of participation or module.

> A per-unlock contact fee at this step is a proposed, **not yet committed**, monetization change — see "Contact-unlock fee" under Trust & Reputation System above. Until an explicit decision is made, step 2 remains free and status-gated only, on both modules.

### 💰 Revenue — Unified Subscription Model

| Plan | Unlocks |
|---|---|
| 🟢 **Free** | Post basic requests (loan: amount + duration + purpose · forex: currency pair + amount) · Browse · Accept offers received · Full visibility into every counterparty's public trust badges |
| 🔵 **Lender** *(subscription)* | Everything in Free + make offers with full terms — loan (amount, interest, late fee, schedule) or forex (rate, amount, terms) + unlocks full offer-detail view on any listing you've bid on |
| 🟣 **Pro** *(subscription)* | Everything in Lender + suggest terms when posting a request (loan interest/late fee/schedule, or forex preferred rate) + priority visibility + improved matching + Verified badge + advanced trust insights (success rate, reliability score) |

> Platform earns from one committed upgrade path, not two parallel ones and not one per module: users pay to unlock offer-making (Lender), and pay more to also unlock posting leverage and stronger trust signaling (Pro) — identically whether they're active in Loans, Forex, or both. A single `subscription_plan` enum drives all of it — no separate "Premium Borrower" or "Forex Plan" product to maintain. Selective transparency and the trust system both add natural, low-pressure upgrade nudges: a Free user who wants full bid detail on a listing sees a prompt to upgrade to Lender and place an offer; a Lender who wants a Verified badge or deeper counterparty insight sees a prompt to upgrade to Pro. A flat per-unlock contact fee is a proposed secondary lever, not yet part of the committed model.

### 🛡️ Compliance & Security

- Terms locked at post/offer time — no post-publish edits, loan or forex
- `reveal_contact` RPC enforced at API level
- Offer-term detail scoped to the request owner and offer-makers on that request, enforced via RLS/RPC — not the Flutter client
- Trust signals are computed strictly from on-platform events (requests, offers, contracts, reviews) — never framed as measuring off-platform repayment or settlement behavior, consistent with the platform boundary in Regulatory Compliance
- Reviews are participant-gated server-side in `submit_review`, not just the UI
- All actions recorded in **append-only audit logs**, including review submissions
- Contract snapshot stored for traceability
- Platform never tracks repayments or settlement, or enforces obligations
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
- [ ] Contract includes all agreed fields + legal disclaimer + `currency_code`
- [ ] Late fee applies only to missed installment (not total balance)
- [ ] Contact reveal only after contract is generated
- [ ] Contact details never accessible before reveal via any query
- [ ] Contact-unlock fee explicitly decided go/no-go before any payment-flow work begins (not assumed)
- [ ] Audit logs capture full contract lifecycle, including review submissions
- [ ] Both parties receive `deal_unlocked` notification
- [ ] `role` column fully removed from schema; all gating reads `subscription_plan` only
- [ ] Pro Advanced Marketplace Filters: `v_marketplace_pro_filters` view and `get_marketplace_pro_filtered` RPC applied to DB, Pro-gated entry button (Option B) and filter criteria bottom sheet implemented in UI, and client-side stream intersection applied in MarketplaceCubit
- [ ] `recompute_trust_aggregates(user_id)` and the trust views are built module-agnostic from the start, so Stage 4.7 requires zero changes to trust logic

---

## Stage 4.5 — Multi-Market Expansion ⬜ Planned

Full model and rationale documented in "Multi-Market Architecture" above. This section tracks the migration checklist and exit criteria. **This replaces the earlier "Stage 4.5 — Multi-Country Expansion (EAC)" checklist** — the 8-country EAC seed list is retired in favor of the 7-market list below.

### Migration Checklist

- [ ] Create `countries` table; seed with all 7 markets per the reference table above — `UG` as `is_active = TRUE` (existing market), the other six (`KE`, `TZ`, `RW`, `NG`, `ZA`, `EG`) as `is_active = FALSE` until each clears its own Stage 6 launch-readiness review; `forex_enabled = FALSE` for all 7 at this stage (forex activation is Stage 4.7+)
- [ ] Create `currencies` table; seed with the 7 market currencies + `USD` (8 rows), all `forex_trading_enabled = FALSE`
- [ ] `ALTER TABLE profiles ADD COLUMN country TEXT REFERENCES countries(code)`; backfill all existing rows to `'UG'`; then set `NOT NULL`
- [ ] `ALTER TABLE loan_requests ADD COLUMN country TEXT REFERENCES countries(code)`; backfill from `profiles.country` via join; then set `NOT NULL`
- [ ] New trigger `trg_fn_set_request_country` (`BEFORE INSERT`) — copies `country` from the borrower's profile; add to the existing "lock after publish" pattern so it can't be edited post-publish
- [ ] `ALTER TABLE system_settings ADD COLUMN country TEXT REFERENCES countries(code)`; existing rows stay `country = NULL` (treated as global default); composite unique index `(setting_key, country)`; add `allow_foreign_currency_loans` boolean, default `FALSE` per country
- [ ] Rename `subscriptions.amount_ugx` → `amount_minor_units` (or add the new column, backfill, drop the old one in a follow-up migration to avoid a breaking change mid-flight)
- [ ] Rebuild `v_loan_listings`, `v_lender_offers`, `v_marketplace_activity` to include `country` / `currency_code`
- [ ] Add indexes: `CREATE INDEX idx_lr_country ON loan_requests(country)`; `CREATE INDEX idx_lr_country_status ON loan_requests(country, status)`; `CREATE INDEX idx_profiles_country ON profiles(country)`
- [ ] Update `MarketplaceRepository` default query to filter `country = currentUserCountry`, with an explicit "browse other markets" toggle in the UI
- [ ] Onboarding: add a country-select step, pre-filled from phone-prefix guess, editable before confirming
- [ ] Document the two resolved v6.0 policy decisions in code comments/RLS so future engineers don't re-litigate them: (a) global browse, not hard isolation, (b) cross-border offers allowed
- [ ] `stage-4.5-verify.sql` — confirm no `loan_requests` or `profiles` row has `country IS NULL`, confirm all 7 markets and 8 currencies are seeded as described in `stage-4.5-status.sql`

### Stage 4.5 Exit Criteria

- [ ] Every `profiles` and `loan_requests` row has a non-null `country`
- [ ] `countries` has exactly 7 rows, `currencies` has exactly 8 rows, matching the reference tables above
- [ ] Marketplace feed defaults to the logged-in user's country; switching markets is an explicit user action, not automatic
- [ ] `v_loan_listings` and `v_lender_offers` return `currency_code` alongside every amount
- [ ] `system_settings` limits resolve correctly per country (falls back to the global/`NULL` row when no country-specific override exists)
- [ ] Global browse and allowed cross-border offers are reflected in RLS/triggers as described above
- [ ] Activating a new market for lending requires only `UPDATE countries SET is_active = TRUE` (the row already exists — all 7 markets are seeded at migration time) — verified by actually flipping one (e.g. `KE`) in a staging environment and confirming no code change was needed
- [ ] Admin KPI view (`v_marketplace_activity`) can be filtered or grouped by country
- [ ] `currencies.forex_trading_enabled` exists and is independently toggleable, ready for Stage 4.7 to consume without a further schema change

---

## Stage 5 — Admin & Compliance ⬜ Planned

- [ ] Admin KYC review dashboard
- [ ] Admin review moderation (Stage 4 reviews)
- [ ] Admin KPI dashboard (`v_marketplace_activity`), filterable by country and by module (loan/forex)
- [ ] SMS alerts (respecting each market's carrier norms — Africa's Talking, Twilio, or Termii)
- [ ] Admin dashboard filterable by country (`v_marketplace_activity` grouped by `country` and `request_type`)
- [ ] Per-country `system_settings` editable from the admin panel (min/max loan amount, listing duration, `allow_foreign_currency_loans`, etc. per market)
- [ ] `countries.is_active` toggle exposed in admin — pause/resume lending in a market without a deploy
- [ ] `countries.forex_enabled` toggle exposed in admin — pause/resume forex in a market independently of lending
- [ ] `currencies.forex_trading_enabled` toggle exposed in admin, per currency

---

## Stage 6 — Launch & Growth ⬜ Planned

- [ ] Play Store AAB + App Store IPA
- [ ] Privacy policy + terms of service
- [ ] 3-screen onboarding carousel — **no role selection step**; onboarding introduces the unified marketplace, subscription tiers, and the public trust system, plus a country-select step (pre-filled from phone-prefix guess, editable) as the only new onboarding question
- [ ] Crash reporting (Firebase Crashlytics or Sentry)
- [ ] Referral programme (`referrals` table in schema)
- [ ] Subscription upgrade prompts — contextual (e.g., prompt to upgrade to Lender the moment a Free user taps "Make Offer" on either module, to Pro the moment a user views another Pro's Verified badge, or taps "See full bid detail" on a listing)
- [ ] Finalize actual subscription pricing (per market currency) for Lender and Pro against local willingness-to-pay research, per market — flagged in Stage 4 as an open item, resolved here before each market's own public launch. No separate forex subscription price.
- [ ] Decide go/no-go on the proposed contact-unlock fee, informed by real Stage 4/4.7/5 usage data on contact-reveal frequency, loan and forex
- [ ] Flutterwave/Paystack (or equivalent) integration for `subscriptions` payment, scoped strictly to Nipanze's own revenue (plan upgrades, and contact-unlock fee if that open decision is resolved to "yes") — never P2P loan funds or exchanged currency; `transactions` table, webhook-verified status transitions, Edge Function signature verification — see Payments Infrastructure addendum above
- [ ] Per-market launch checklist — repeat for each of Kenya, Tanzania, Rwanda, Nigeria, South Africa, and Egypt before flipping that country's `is_active` (lending) to `TRUE`, and separately before flipping `forex_enabled`:
  - [ ] `countries.is_active` set `TRUE` for that market (lending go-live)
  - [ ] `countries.forex_enabled` set `TRUE` for that market, independently timed, only after its own currency-exchange-facilitation compliance review
  - [ ] Local-currency pricing finalized for Lender and Pro (no cross-market conversion — each market prices independently against local willingness-to-pay)
  - [ ] Payment-rail coverage confirmed with the chosen aggregator for that specific country (do not assume coverage from a neighboring or same-region market's success)
  - [ ] Local KYC document types validated (`kyc_verifications.national_id_type` accepts the correct free-text values for that market)
  - [ ] Local payment/contact norms and any market-specific regulatory or compliance review completed, treated as independent per market given the regulatory diversity across regions (see Regulatory Compliance)
- [ ] Rollout order and cadence: **Uganda (live) → Kenya → Tanzania → Rwanda → Nigeria → South Africa → Egypt**, each with its own lending *and* separately-timed forex go/no-go — sequential by default, revisited based on Uganda+Kenya learnings once Kenya ships

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
| Selective transparency: aggregate view for non-participants, full detail for owner/offer-makers | ⬜ Stage 4 |
| Public trust badge row (rating, reviews, deals, repeat, phone-verified, response time) | ⬜ Stage 4 |
| Pro-tier Verified badge + advanced trust insights | ⬜ Stage 4 |
| Post-contract review flow | ⬜ Stage 4 |
| Contract auto-generated after offer acceptance | ⬜ Stage 4 |
| Contact reveal flow (blurred → unblur) | ⬜ Stage 4 |
| Contact-unlock fee (open decision) | ⬜ Not yet committed |
| Remove `role` column; subscription-only gating | ⬜ Stage 4 |
| Pro Advanced Marketplace Filters (employment type, income bracket, suggested terms, verified status) | ⬜ Stage 4 |
| Multi-market schema migration (`countries`, `currencies`, `profiles.country`, `loan_requests.country`) | ⬜ Stage 4.5 |
| Marketplace feed defaults to user's country, with explicit browse-other-markets toggle | ⬜ Stage 4.5 |
| `forex_requests` / `forex_offers` tables, `forex_enabled` / `forex_trading_enabled` gates | ⬜ Stage 4.7 |
| Forex marketplace filter (`All / Loans / Forex`) and Send/Rate/Receive listing card | ⬜ Stage 4.7 |
| Forex selective transparency + trust reuse (no separate forex trust score) | ⬜ Stage 4.7 |
| Forex contract generation + contact reveal | ⬜ Stage 4.7 |
| Flutterwave/Paystack payment integration (subscriptions + contact-unlock fee only) | ⬜ Stage 6 |
| Admin KYC review | ⬜ Stage 5 |
| Admin review moderation | ⬜ Stage 5 |
| Admin KPI dashboard (country- and module-filterable) | ⬜ Stage 5 |
| SMS alerts | ⬜ Stage 5 |

---

## Test Accounts (password: `Test1234!`)

> `Role` column removed — accounts are described purely by activity + subscription plan, matching the unified model. All 17 pre-v6.0 seed accounts (see `sql/seed.sql`) backfill to `country = 'UG'` under the Stage 4.5 migration. Test accounts previously seeded for the retired EAC-only countries (Burundi, South Sudan, DR Congo, Somalia) are not part of this list — see the note at the end of this section.

| Email | Country | Subscription | Best for testing |
|---|---|---|---|
| `david.mukasa@gmail.com` | UG | Free | Contracted loan request; contact reveal triggered |
| `sarah.namukasa@yahoo.com` | UG | Free | Contracted loan request; contact reveal pending |
| `james.okello@outlook.com` | UG | Pro | Active loan request with two pending offers; also has offers out on other listings |
| `maria.nakato@gmail.com` | UG | Free | Active loan request, one pending offer |
| `robert.ssemwanga@gmail.com` | UG | Lender | Closing-soon loan request; pending offer on another listing |
| `invest@pearlcapital.ug` | UG | Pro | Offer accepted on David's request; contact revealed |
| `funds@victoriainvest.co.ug` | UG | Pro | Offer accepted on Sarah's request; contact reveal pending |
| `lending@equatorfinance.ug` | UG | Lender | Pending offer on James's request |
| `info@greenleafagro.co.ug` | UG | Lender | Pending offer on Maria's request; expired offer on Charles's |
| `contact@kampalatech.ug` | UG | Lender | Pending offer on Frank's request |
| `alice.namuli@gmail.com` | UG | Free | KYC pending — test KYC badge; `account_status = pending_verification` |
| `admin1@nipanze.ug` | UG | Free (`is_admin = true`) | Full admin dashboard access |
| `test.user@gmail.com` | UG | Free | No prior activity — test onboarding gates |
| `wanjiru.kamau@gmail.com` *(Stage 4.5)* | KE | Free | Confirms a KE-registered user sees only KE listings by default, and that switching to "Browse Uganda" surfaces UG listings without exposing exact offer terms they're not party to |
| `nairobi.capital@example.co.ke` *(Stage 4.5)* | KE | Lender | Confirms a KE lender can (per the recommended default) place a cross-border offer on a UG listing, and that the resulting offer/trust data behaves correctly across the country boundary |
| `amani.mwakalinga@gmail.com` | TZ | Free | Confirms TZS displays correctly on a TZ-posted request (amount, currency symbol/code), and that a TZ user's default feed excludes UG/KE listings |
| `uwase.claudine@gmail.com` | RW | Pro | Confirms RWF-denominated Pro term suggestions (interest, late fee, schedule) render correctly, and that Pro-tier gating (Verified badge, advanced trust insights) works identically regardless of `country` |
| `chidinma.okafor@example.ng` *(new, v6.0)* | NG | Lender | Confirms NGN currency rendering and cross-border offer placement into UG |
| `thandiwe.dlamini@example.co.za` *(new, v6.0)* | ZA | Pro | Confirms ZAR Pro term suggestions and gating |
| `youssef.hassan@example.eg` *(new, v6.0)* | EG | Free | Confirms EGP currency rendering; flagged for extra forex-review scrutiny given EGP's currency-control history |
| `mutesi.grace@gmail.com` *(new, Stage 4.7)* | UG | Lender | Active `UGX → KES` forex request with two pending rate offers |
| `nonparticipant.tester@gmail.com` *(new, Stage 4.7)* | UG | Free | Verifies non-participants see only `rate_coverage_tier` on forex listings |

All existing pre-v6.0 accounts and their test scenarios (David Mukasa's contracted request, James Okello's multi-offer listing, etc.) are otherwise unchanged — see `sql/seed.sql` for the full list. The KE/TZ/RW/NG/ZA/EG accounts above are seeded as `is_active = FALSE`-market test data — useful for verifying the schema and currency handling work correctly ahead of each market's actual Stage 6 launch, without implying any of them are live.

> **Retired EAC-only seed accounts removed:** the v5.0 plan seeded example accounts and reference data for Burundi, South Sudan, DR Congo, and Somalia. Those four countries and any associated test data are **removed from the current test-account list** along with their EAC framing — they are not part of the v6.0 seven-market plan. If they're reintroduced to the roadmap later, they'd be added the same way any new country is: a `countries` row insert plus a matching test account, not a schema change.

> **Currency-rendering test note:** with all 7 market currencies (plus USD) live in the `currencies` seed, add at minimum one seed loan listing per currency (`UGX`, `KES`, `TZS`, `RWF` at Stage 4.5; `NGN`, `ZAR`, `EGP` incrementally as each market approaches its own Stage 6 launch) so `v_loan_listings` / `v_lender_offers` currency-formatting logic is exercised against every currency code the schema supports, not just UGX. Stage 4.7 additionally needs at least one seed forex listing per currency pair under test (e.g. `UGX → KES`), and at least one pair deliberately left with `forex_trading_enabled = FALSE` on one leg, to confirm the eligibility check rejects it server-side.

> **Stage 4 selective-transparency testing:** view a contested listing (e.g. James Okello's active request, which has two pending offers) while logged in as a non-participant account like `test.user@gmail.com` to confirm only the aggregate `offer_coverage_tier` is visible, then log in as `lending@equatorfinance.ug` (which has a pending offer on James's request) to confirm full offer detail unlocks. **Stage 4.7:** repeat the identical test on `mutesi.grace@gmail.com`'s forex request using `nonparticipant.tester@gmail.com` as the non-participant, confirming only `rate_coverage_tier` is visible until an offer is placed.
>
> **Stage 4 trust-system testing:** `invest@pearlcapital.ug` and `david.mukasa@gmail.com` already share a completed contract (offer accepted, contact revealed) — a good seed pair for the first mutual reviews once `reviews` ships, to confirm the rating/review-count badges update correctly on both profiles. **Stage 4.7:** once a forex contract completes for `mutesi.grace@gmail.com`, confirm her `completed_deals_count` increments on the same global aggregate as her (if any) loan deal history, not a separate forex-only counter.

---

## Architecture Constraints

1. **No fund or currency movement** — platform never initiates, processes, records, or tracks financial transactions or currency exchange, in any country, on either module
2. **Anonymity by default** — request-owner id never in marketplace queries; offer-maker identity hidden until offer is accepted and contact is revealed, loan or forex
3. **DB is the gate** — triggers + RLS enforce all rules based on `subscription_plan`, `country`, and (v6.0) currency-trading eligibility; client validation is UX only
4. **Controlled contact sharing** — `reveal_contact`/`unlock_contact` RPCs enforced at API layer; contact details never accessible before reveal via any query, loan or forex
5. **Friendly errors** — `parseSupabaseError()` everywhere; raw trigger codes never reach the user
6. **Append-only audit log** — `audit_logs` never writable via UPDATE or DELETE
7. **No stored role** — the only role in the system is `is_admin`; all marketplace capability comes from `subscription_plan` (`free | lender | pro`), identically on both modules
8. **Selective transparency** — exact offer-level terms (loan: amount, interest rate, late fee, schedule · forex: rate, amount, terms) are visible only to the request owner and to offer-makers with a live offer on that same request; every other viewer, regardless of subscription plan, sees only the aggregate `offer_coverage_tier`/`rate_coverage_tier` and offer count. Enforced via RLS/RPC, never trusted from the client.
9. **Trust signals are public, platform-scoped, country-agnostic, and module-agnostic** — baseline reputation data (ratings, review counts, completed-deal counts, repeat/phone-verified badges) is visible to every viewer regardless of plan, participation, country, or module, and reflects a user's full on-platform history across all markets and both Loans and Forex, not a per-country or per-module reset. Nipanze never displays or implies a signal about off-platform repayment or settlement behavior, consistent with constraint 1. Pro-tier trust features add verification weight (KYC-backed badge) and interpretation (derived scores) on top of this same public data — they never withhold or replace it, and never split by module.
10. **Country is explicit, indexed, and locked-at-creation** — `profiles.country` is the editable source of truth for a user; `loan_requests.country` and `forex_requests.country` are copied from it at post time and frozen; `loan_offers` and `forex_offers` have no country of their own and are always read through their parent request. One shared schema serves every market — never a table or database per country, and never a table or database per module.
11. **Currency eligibility is independently gated per use-case** — a currency existing in Nipanze's vocabulary (`currencies` row present) does not imply it's cleared for forex trading (`forex_trading_enabled`); loan-currency permission (`system_settings.allow_foreign_currency_loans`) and forex-trading permission are two separate, deliberately un-bundled decisions, checked server-side, never assumed from the other.
12. **Lending and forex activation are independently gated per market** — `countries.is_active` (lending) and `countries.forex_enabled` (forex) are two separate flags on the same row, flipped on independent timelines after independent compliance review; a market going live for one module never implies the other is live.

---

*Nipanze Platforms Limited · contact@nipanze.ug · nipanze.ug*
*Made with ❤️ for financial inclusion across Africa*