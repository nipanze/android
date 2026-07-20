# BUILD_PLAN.md — Nipanze

> **Flutter + Supabase** · Digital loan listing matchmaking marketplace for Uganda and emerging economies
> Last updated: July 2026 · Schema v4.1 · Seed v2.1

> **⚡ v4.1 Architecture Change:** Nipanze has moved from a **role-based** model (borrower / lender) to a **unified, subscription-based, action-based** model. There is no "I am a borrower" or "I am a lender" — every user sees one marketplace and performs borrower actions (Post Request) or lender actions (Make Offer) depending on what they click. Access to actions is gated purely by `subscription_plan`. See "Unified Marketplace Model" below before reading Stage 4.
>
> **⚡ Stage 4 addition:** Listing detail visibility is now **tiered, not binary**. See "Selective Transparency Model" below before reading the Stage 4 flow — it changes what `v_lender_offers` and `get_public_listing_offers` return depending on who's asking.
>
> **⚡ Stage 4 addition:** A public **Trust & Reputation System** (ratings, reviews, completed-deal counts, badges) is now planned. See "Trust & Reputation System" below — it is deliberately kept separate from selective transparency: trust signals are public to everyone on every plan, while offer-term detail stays participation-gated.

---

## Stage Map

| Stage | Title | Status |
|---|---|---|
| 1 | Foundation | ✅ Complete |
| 2 | Core Marketplace | ✅ Complete |
| 3 | Polish & Supporting Features | ✅ Complete |
| 3.5 | Cloud Migration & Auth Hardening | ✅ Complete |
| 4 | Structured Deal Agreement, Contact Sharing & Trust System | ⬜ Planned (revised for unified model) |
| 5 | Admin & Compliance | ⬜ Planned |
| 6 | Launch & Growth | ⬜ Planned |

---

## 🧠 Unified Marketplace Model (New — supersedes role-based framing)

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

## 🔍 Selective Transparency Model (New — governs listing detail visibility)

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

## 🌟 Trust & Reputation System (New — governs counterparty credibility, separate from deal-term visibility)

Early product feedback flagged that Nipanze's plan tiers (Free / Lender / Pro) currently describe *capability* well but say nothing about *credibility* — a Free user browsing the marketplace has no way to judge whether a request owner or offer-maker is a reliable counterparty before ever engaging. This section defines a public reputation layer to close that gap, and a Pro-tier verification/insight layer to monetize it responsibly.

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

These render as a compact badge row (see example below) on `ListingCard`, the offers panel, and `ProfilePage` — the same component, `TrustBadgeRow`, everywhere a counterparty appears, so the signal is consistent across the app.

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

To avoid the trust-erosion failure mode flagged in product review, the following are permanent constraints on this system, not just a v1 default:

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

Product feedback also proposed a flat, per-unlock contact fee (a few thousand UGX) charged at the moment contact is revealed, free or discounted for Pro, as a second revenue engine alongside subscriptions. This is **not folded into the committed Stage 4 scope** below, because it changes two things currently treated as fixed elsewhere in this plan and in the README:

1. The stated principle that Nipanze earns **"revenue through subscriptions — not interest spreads — via a single upgrade path"** would need to explicitly become "subscriptions plus a flat, disclosed contact-unlock fee"
2. `reveal_contact` today is purely **status-gated** (owner has accepted an offer → both parties may unlock) — a paid unlock means adding a payment-confirmation step in front of the existing unlock logic, plus a payment provider integration that doesn't otherwise exist in this stack

**If this is adopted**, the fee must stay flat and disclosed up front — never a percentage of loan amount, interest rate, or deal outcome — to remain consistent with the "no fee tied to loan performance" principle in Regulatory Compliance. It is tracked here as a **Stage 4 decision point** requiring an explicit go/no-go before implementation, rather than assumed into the checklist below. Recommendation: ship the trust system and selective transparency first (both reinforce trust and offer-making without touching money), then revisit contact-unlock pricing once there's real usage data on how often contact reveal happens.

### 💵 Pricing note (flagged, not changed)

Product feedback separately suggested the (previously undocumented) Pro price point may be too high for the target Uganda early-stage market, and recommended validating actual subscription pricing against local willingness-to-pay before Stage 6 launch. This build plan does not currently commit to specific UGX figures for any tier — pricing is a business decision to be finalized closer to Stage 6 (Launch & Growth) with real market input, and is called out here so it isn't lost.

---

## 🎯 Pro Advanced Marketplace Filters (v4.2 addition)

Pro-tier users can access advanced filtering controls on the marketplace feed to find listings matching specific borrower profile attributes or listing status details.
- **Employment type filter:** Filter borrower profiles by categorical type (e.g. `government_employee`, `employed`, `self_employed`, `small_business_owner`, `business_owner`, `student`, `other`).
- **Income bracket filter:** Filter borrower profiles by a coarse monthly income bracket (using `fn_income_bracket`: `under_2m`, `2m_5m`, `5m_10m`, `over_10m`).
- **Suggested terms filter:** Limit the feed to requests carrying suggested terms locked by a Pro poster at publish time.
- **Verified status filter:** Limit the feed to requests from KYC-approved owners.

This capability is gated at the DB layer via the `v_marketplace_pro_filters` view (which checks for an active Pro subscription and returns zero rows if absent) and the `get_marketplace_pro_filtered` RPC. In the UI, the filters are presented via an entry icon button next to the notification bell (Option B) opening a bottom sheet, gated strictly to Pro users.

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

> Note: "My Requests" and "My Offers" are simply two views of the same account's activity — not two roles. A single user can have entries in both tabs simultaneously. Positions is always a **participant** view, so it's unaffected by the Stage 4 selective-transparency tiering — a user always sees full detail on their own requests and their own offers. Trust badges on counterparty listings/offers within Positions are unaffected either way, since they're public.

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

---

## Stage 4 — Structured Deal Agreement, Contact Sharing & Trust System ⬜ Planned (revised for unified model)

Stage 4 redesigns how terms are agreed upon and introduces a **locked bidding system** where both the request owner and the offer-maker commit to terms upfront — eliminating unstructured back-and-forth before a contract is generated. It also introduces the **Selective Transparency Model** and the **Trust & Reputation System** (both above), replacing Stage 2's fully public offer book with participation-gated deal detail plus an always-public reputation layer.

---

## 🎯 Objective

> **"We connect the two sides of a deal, help them see who they're dealing with, agree on terms, then generate a contract — everything else happens offline."**

Core principles:
- Terms are **locked at the point of posting / bidding** — no editing after publish
- Both parties commit to their position independently
- A contract is generated when their terms match via acceptance
- Contact is revealed only after the contract is locked
- Exact offer terms are visible only to the request owner and to offer-makers who have bid on that listing; everyone else sees an aggregate coverage signal
- Public trust signals (rating, reviews, completed deals, badges) are visible to everyone regardless of participation or plan
- Neither party is a fixed "role" in the schema — capability comes entirely from `subscription_plan`

---

## 🔁 Flow Overview

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

---

## 📋 Request Posting — Term Suggestions (Pro-tier feature)

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

---

## 🏷️ Offer Submission — Term Setting (Lender plan and above)

When a user submits an offer, they set their own terms. They may align with the posted suggestions or propose different ones. Once submitted, the offer is **locked**.

| Field | Description |
|---|---|
| Amount offered | Full or partial of the requested amount |
| Interest rate | Offer-maker's required return |
| Late payment fee | % applied only to missed installment |
| Repayment schedule | Monthly / Weekly / One-time + installment amount |

> Offer-making requires at least the **Lender plan**. Maximising the pool of people who can make offers is essential for platform value, so Lender-tier pricing should stay accessible.

> Placing an offer on a listing also unlocks full offer-level detail (all offers' exact terms, plus every offer-maker's public trust badges) on that same listing for the offer-maker — see Selective Transparency Model.

---

## 🔍 Selective Transparency — Implementation Checklist

- [ ] `offer_coverage_tier` computed column/function added to `v_loan_listings` (derived from `loan_offers` for that `request_id`; `low` / `medium` / `high`)
- [ ] `v_lender_offers` scoped via RLS + `security_invoker` so a row returns only to the request owner or to an account with an offer on that `request_id`
- [ ] `get_public_listing_offers(request_id)` RPC branches on caller identity: owner/participant → full detail; everyone else → `number_of_offers` + `offer_coverage_tier` only
- [ ] `LoanDetailPage` UI reads the tiered payload and renders either the full offers panel or the aggregate summary + "Place an offer to see full bid detail" prompt
- [ ] Placing an offer triggers a client-side refetch of the listing detail so the offer-maker immediately sees the unlocked, full-detail view
- [ ] Withdrawing an offer re-locks detail on that listing for that user (no offer on the request → back to aggregate-only view)
- [ ] Unit/integration tests: non-participant querying `v_lender_offers` or the RPC directly (bypassing UI) receives only the aggregate payload

---

## 🌟 Trust & Reputation System — Implementation Checklist

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

---

## 📄 Contract Contents

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

### Late Payment Rule

> "A [X]% penalty applies only to the missed payment amount — not the total loan balance."

This keeps penalties fair, prevents compounding debt, and builds platform trust.

### Legal Disclaimer

> "Nipanze provides this agreement for convenience only. The final obligation is solely between the two parties. Nipanze does not enforce repayment or hold funds."

---

## 🔓 Contact Reveal Flow

After contract generation:

1. A blurred **Deal + Contact Card** is shown to both parties
2. User clicks **"Unlock Deal & Contact"**
3. Confirmation dialog: action is irreversible
4. Contact details revealed: legal name, phone, email
5. Notifications sent to both parties (`deal_unlocked`)
6. Full contract becomes visible

Contact details are **never accessible before this step** — enforced at API level via `reveal_contact` RPC. This is a separate boundary from the Selective Transparency Model above: offer-term visibility can be participant-gated well before a deal is struck, but identity stays locked until this step regardless of participation.

> A per-unlock contact fee at this step is a proposed, **not yet committed**, monetization change — see "Contact-unlock fee" under Trust & Reputation System above. Until an explicit decision is made, step 2 remains free and status-gated only.

---

## 💰 Revenue — Unified Subscription Model (replaces "Dual Subscription Model")

| Plan | Unlocks |
|---|---|
| 🟢 **Free** | Post basic requests (amount + duration + purpose only) · Browse · Accept offers received · Full visibility into every counterparty's public trust badges |
| 🔵 **Lender** *(subscription)* | Everything in Free + make offers with full terms (amount, interest, late fee, schedule) + unlocks full offer-detail view on any listing you've bid on |
| 🟣 **Pro** *(subscription)* | Everything in Lender + suggest terms when posting a request (interest, late fee, schedule) + priority visibility + improved matching + Verified badge + advanced trust insights (success rate, reliability score) |

> Platform earns from one committed upgrade path, not two parallel ones: users pay to unlock offer-making (Lender), and pay more to also unlock posting leverage and stronger trust signaling (Pro). A single `subscription_plan` enum drives all of it — no separate "Premium Borrower" product to maintain. Selective transparency and the trust system both add natural, low-pressure upgrade nudges: a Free user who wants full bid detail on a listing sees a prompt to upgrade to Lender and place an offer; a Lender who wants a Verified badge or deeper counterparty insight sees a prompt to upgrade to Pro. A flat per-unlock contact fee is a proposed secondary lever, not yet part of the committed model — see above.

---

## 🛡️ Compliance & Security

- Terms locked at post/offer time — no post-publish edits
- `reveal_contact` RPC enforced at API level
- Offer-term detail scoped to the request owner and offer-makers on that request, enforced via RLS/RPC — not the Flutter client
- Trust signals are computed strictly from on-platform events (requests, offers, contracts, reviews) — never framed as measuring off-platform repayment behavior, consistent with the platform boundary in Regulatory Compliance
- Reviews are participant-gated server-side in `submit_review`, not just the UI
- All actions recorded in **append-only audit logs**, including review submissions
- Contract snapshot stored for traceability
- Platform never tracks repayments or enforces obligations
- Subscription plan checked server-side (RLS / RPC), never trusted from client

---

## ✅ Stage 4 Exit Criteria

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
- [ ] Contract includes all agreed fields + legal disclaimer
- [ ] Late fee applies only to missed installment (not total balance)
- [ ] Contact reveal only after contract is generated
- [ ] Contact details never accessible before reveal via any query
- [ ] Contact-unlock fee explicitly decided go/no-go before any payment-flow work begins (not assumed)
- [ ] Audit logs capture full contract lifecycle, including review submissions
- [ ] Both parties receive `deal_unlocked` notification
- [ ] `role` column fully removed from schema; all gating reads `subscription_plan` only
- [ ] Pro Advanced Marketplace Filters: `v_marketplace_pro_filters` view and `get_marketplace_pro_filtered` RPC applied to DB, Pro-gated entry button (Option B) and filter criteria bottom sheet implemented in UI, and client-side stream intersection applied in MarketplaceCubit

---

## Stage 5 — Admin & Compliance ⬜ Planned

- [ ] `AdminDashboardPage` — live `v_marketplace_activity` KPIs + Realtime
- [ ] GoRouter admin guard on `/admin`
- [ ] `KycReviewPage` — approve/reject with document viewer
- [ ] SMS notifications via Africa's Talking
- [ ] `system_settings` editable from admin panel
- [ ] Audit log viewer — filterable by event type, user, date range
- [ ] User management — account status, subscription plan, KYC status
- [ ] Review moderation queue — flagged reviews, abuse review, same reviewer workflow pattern as KYC
- [ ] Admin view bypasses selective-transparency tiering for moderation purposes only (full offer detail on any listing), logged to `audit_logs` like any other privileged read

### Stage 5 Exit Criteria
- [ ] Admin can review and approve/reject KYC submissions
- [ ] Admin can review and moderate flagged reviews
- [ ] `v_marketplace_activity` drives live admin KPI dashboard
- [ ] All sensitive actions logged to `audit_logs` (append-only enforced)
- [ ] SMS alerts fire on offer accepted and contact revealed events

---

## Stage 6 — Launch & Growth ⬜ Planned

- [ ] Play Store AAB + App Store IPA
- [ ] Privacy policy + terms of service
- [ ] 3-screen onboarding carousel — **no role selection step**; onboarding introduces the unified marketplace, subscription tiers, and the public trust system instead
- [ ] Crash reporting (Firebase Crashlytics or Sentry)
- [ ] Referral programme (`referrals` table in schema v4.0)
- [ ] Subscription upgrade prompts — contextual (e.g., prompt to upgrade to Lender the moment a Free user taps "Make Offer", to Pro the moment a user views another Pro's Verified badge, or taps "See full bid detail" on a listing)
- [ ] Finalize actual subscription pricing (UGX) for Lender and Pro against local willingness-to-pay research — flagged in Stage 4 as an open item, resolved here before public launch
- [ ] Decide go/no-go on the proposed contact-unlock fee, informed by real Stage 4/5 usage data on contact-reveal frequency

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
| Pro Advanced Marketplace Filters: Pro-only filters (employment type, income bracket, suggested terms, verified status) | ⬜ Stage 4 |
| Admin KYC review | ⬜ Stage 5 |
| Admin review moderation | ⬜ Stage 5 |
| Admin KPI dashboard | ⬜ Stage 5 |
| SMS alerts | ⬜ Stage 5 |

---

## Test Accounts (password: `Test1234!`)

> `Role` column removed — accounts are now described purely by activity + subscription plan, matching the unified model.

| Email | Subscription | Best for testing |
|---|---|---|
| `david.mukasa@gmail.com` | Free | Contracted request; contact reveal triggered |
| `sarah.namukasa@yahoo.com` | Free | Contracted request; contact reveal pending |
| `james.okello@outlook.com` | Pro | Active request with two pending offers; also has offers out on other listings |
| `maria.nakato@gmail.com` | Free | Active request, one pending offer |
| `robert.ssemwanga@gmail.com` | Lender | Closing-soon request; pending offer on another listing |
| `invest@pearlcapital.ug` | Pro | Offer accepted on David's request; contact revealed |
| `funds@victoriainvest.co.ug` | Pro | Offer accepted on Sarah's request; contact reveal pending |
| `lending@equatorfinance.ug` | Lender | Pending offer on James's request |
| `info@greenleafagro.co.ug` | Lender | Pending offer on Maria's request; expired offer on Charles's |
| `contact@kampalatech.ug` | Lender | Pending offer on Frank's request |
| `alice.namuli@gmail.com` | Free | KYC pending — test KYC badge; `account_status = pending_verification` |
| `admin1@nipanze.ug` | Free (`is_admin = true`) | Full admin dashboard access |
| `test.user@gmail.com` | Free | No prior activity — test onboarding gates |

> For Stage 4 selective-transparency testing: view a contested listing (e.g. James Okello's active request, which has two pending offers) while logged in as a non-participant account like `test.user@gmail.com` to confirm only the aggregate `offer_coverage_tier` is visible, then log in as `lending@equatorfinance.ug` (which has a pending offer on James's request) to confirm full offer detail unlocks.
>
> For Stage 4 trust-system testing: `invest@pearlcapital.ug` and `david.mukasa@gmail.com` already share a completed contract (offer accepted, contact revealed) — a good seed pair for the first mutual reviews once `reviews` ships, to confirm the rating/review-count badges update correctly on both profiles.

---

## Architecture Constraints

1. **No fund movement** — platform never initiates, processes, records, or tracks financial transactions
2. **Anonymity by default** — request-owner id never in marketplace queries; offer-maker identity hidden until offer is accepted and contact is revealed
3. **DB is the gate** — triggers + RLS enforce all rules based on `subscription_plan`; client validation is UX only
4. **Controlled contact sharing** — `reveal_contact` RPC enforced at API layer; contact details never accessible before reveal via any query
5. **Friendly errors** — `parseSupabaseError()` everywhere; raw trigger codes never reach the user
6. **Append-only audit log** — `audit_logs` never writable via UPDATE or DELETE
7. **No stored role** — the only role in the system is `is_admin`; all marketplace capability comes from `subscription_plan` (`free | lender | pro`)
8. **Selective transparency** — exact offer-level terms (amount, interest rate, late fee, schedule) are visible only to the request owner and to offer-makers with a live offer on that same request; every other viewer, regardless of subscription plan, sees only the aggregate `offer_coverage_tier` and offer count. Enforced via RLS/RPC, never trusted from the client.
9. **Trust signals are public and platform-scoped** — baseline reputation data (ratings, review counts, completed-deal counts, repeat/phone-verified badges) is visible to every viewer regardless of plan or participation, and is built only from on-platform events. Nipanze never displays or implies a signal about off-platform repayment behavior, consistent with constraint 1 and the Regulatory Compliance boundary. Pro-tier trust features add verification weight (KYC-backed badge) and interpretation (derived scores) on top of this same public data — they never withhold or replace it.

---

*Nipanze Platforms Limited · contact@nipanze.ug · nipanze.ug*
*Made with ❤️ for financial inclusion in Uganda*