# BUILD_PLAN.md — Nipanze

> **Flutter + Supabase** · Digital loan listing matchmaking marketplace for Uganda and emerging economies
> Last updated: July 2026 · Schema v4.1 · Seed v2.1

> **⚡ v4.1 Architecture Change:** Nipanze has moved from a **role-based** model (borrower / lender) to a **unified, subscription-based, action-based** model. There is no "I am a borrower" or "I am a lender" — every user sees one marketplace and performs borrower actions (Post Request) or lender actions (Make Offer) depending on what they click. Access to actions is gated purely by `subscription_plan`. See "Unified Marketplace Model" below before reading Stage 4.
>
> **⚡ Stage 4 addition:** Listing detail visibility is now **tiered, not binary**. See "Selective Transparency Model" below before reading the Stage 4 flow — it changes what `v_lender_offers` and `get_public_listing_offers` return depending on who's asking.

---

## Stage Map

| Stage | Title | Status |
|---|---|---|
| 1 | Foundation | ✅ Complete |
| 2 | Core Marketplace | ✅ Complete |
| 3 | Polish & Supporting Features | ✅ Complete |
| 3.5 | Cloud Migration & Auth Hardening | ✅ Complete |
| 4 | Structured Deal Agreement & Contact Sharing | ⬜ Planned (revised for unified model) |
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
| 🟢 **Free** | Post basic loan requests (amount, duration, purpose) · Browse marketplace · Accept received offers · Watchlist, Positions, Notifications, KYC · ❌ Cannot make offers · ❌ Cannot suggest terms when posting |
| 🔵 **Lender Plan** | Everything in Free, **plus**: Make offers on any listing · Set interest rate, late payment fee, repayment schedule on offers |
| 🟣 **Pro** | Everything in Lender, **plus**: Suggest terms when posting a request (interest rate, late fee, repayment schedule) · Priority visibility for posted requests · Improved matching |

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
| **Visitor / any logged-in user, not yet bid** | Funded % progress bar, `number_of_offers`, `offer_coverage_tier` (`low` / `medium` / `high`), full request summary (amount, purpose, district, duration, repayment plan) |
| **Lender/Pro-plan holder browsing, has not offered on *this* listing** | Same as a visitor — plan alone does not unlock offer detail; placing an offer does |
| **Offer-maker who has placed an offer on this listing** | Everything above, **plus** exact amount, interest rate, late fee, and repayment schedule for every offer on this listing |
| **Request owner** | Full detail on every offer received: exact amount, interest rate, late fee, repayment schedule, timestamp |

Contact details are a separate boundary and stay locked for **everyone**, at every tier, until contract generation + unlock — this model only changes *offer-term* visibility, not identity.

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

> Note: in Stage 2 the offers panel on `LoanDetailPage` showed every offer's exact terms to any viewer. Stage 4 replaces this with the **Selective Transparency Model** above — full exact-term detail becomes participant-gated, while the aggregate signal (offer count + coverage tier) stays visible to everyone.

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

> Note: "My Requests" and "My Offers" are simply two views of the same account's activity — not two roles. A single user can have entries in both tabs simultaneously. Positions is always a **participant** view, so it's unaffected by the Stage 4 selective-transparency tiering — a user always sees full detail on their own requests and their own offers.

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

## Stage 4 — Structured Deal Agreement & Contact Sharing ⬜ Planned (revised for unified model)

Stage 4 redesigns how terms are agreed upon and introduces a **locked bidding system** where both the request owner and the offer-maker commit to terms upfront — eliminating unstructured back-and-forth before a contract is generated. It also introduces the **Selective Transparency Model** (above), replacing Stage 2's fully public offer book with participation-gated detail.

---

## 🎯 Objective

> **"We connect the two sides of a deal, help them agree on terms, then generate a contract — everything else happens offline."**

Core principles:
- Terms are **locked at the point of posting / bidding** — no editing after publish
- Both parties commit to their position independently
- A contract is generated when their terms match via acceptance
- Contact is revealed only after the contract is locked
- Exact offer terms are visible only to the request owner and to offer-makers who have bid on that listing; everyone else sees an aggregate coverage signal
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

LISTING DETAIL VIEWED (tiered — see Selective Transparency Model)
──────────────────────────────────────────
Everyone: funded %, offer count, offer_coverage_tier
Owner / participants only: exact offer amounts + terms
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

> **Why Pro?** A request with suggested terms carries negotiating leverage — it attracts offers already aligned with the poster's preferred terms. This is the core value of the Pro tier, available to anyone regardless of whether they've ever made an offer themselves.

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

> Placing an offer on a listing also unlocks full offer-level detail (all offers' exact terms) on that same listing for the offer-maker — see Selective Transparency Model.

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

---

## 💰 Revenue — Unified Subscription Model (replaces "Dual Subscription Model")

| Plan | Unlocks |
|---|---|
| 🟢 **Free** | Post basic requests (amount + duration + purpose only) · Browse · Accept offers received |
| 🔵 **Lender** *(subscription)* | Everything in Free + make offers with full terms (amount, interest, late fee, schedule) + unlocks full offer-detail view on any listing you've bid on |
| 🟣 **Pro** *(subscription)* | Everything in Lender + suggest terms when posting a request (interest, late fee, schedule) + priority visibility + improved matching |

> Platform earns from one upgrade path, not two parallel ones: users pay to unlock offer-making (Lender), and pay more to also unlock posting leverage (Pro). A single `subscription_plan` enum drives all of it — no separate "Premium Borrower" product to maintain. Selective transparency adds a natural, low-pressure upgrade nudge: a Free user who wants to see full bid detail on a listing sees a prompt to upgrade to Lender and place an offer, rather than a paywall on browsing itself.

---

## 🛡️ Compliance & Security

- Terms locked at post/offer time — no post-publish edits
- `reveal_contact` RPC enforced at API level
- Offer-term detail scoped to the request owner and offer-makers on that request, enforced via RLS/RPC — not the Flutter client
- All actions recorded in **append-only audit logs**
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
- [ ] Contract auto-generated after request owner accepts an offer
- [ ] Contract includes all agreed fields + legal disclaimer
- [ ] Late fee applies only to missed installment (not total balance)
- [ ] Contact reveal only after contract is generated
- [ ] Contact details never accessible before reveal via any query
- [ ] Audit logs capture full contract lifecycle
- [ ] Both parties receive `deal_unlocked` notification
- [ ] `role` column fully removed from schema; all gating reads `subscription_plan` only

---

## Stage 5 — Admin & Compliance ⬜ Planned

- [ ] `AdminDashboardPage` — live `v_marketplace_activity` KPIs + Realtime
- [ ] GoRouter admin guard on `/admin`
- [ ] `KycReviewPage` — approve/reject with document viewer
- [ ] SMS notifications via Africa's Talking
- [ ] `system_settings` editable from admin panel
- [ ] Audit log viewer — filterable by event type, user, date range
- [ ] User management — account status, subscription plan, KYC status
- [ ] Admin view bypasses selective-transparency tiering for moderation purposes only (full offer detail on any listing), logged to `audit_logs` like any other privileged read

### Stage 5 Exit Criteria
- [ ] Admin can review and approve/reject KYC submissions
- [ ] `v_marketplace_activity` drives live admin KPI dashboard
- [ ] All sensitive actions logged to `audit_logs` (append-only enforced)
- [ ] SMS alerts fire on offer accepted and contact revealed events

---

## Stage 6 — Launch & Growth ⬜ Planned

- [ ] Play Store AAB + App Store IPA
- [ ] Privacy policy + terms of service
- [ ] 3-screen onboarding carousel — **no role selection step**; onboarding introduces the unified marketplace and subscription tiers instead
- [ ] Crash reporting (Firebase Crashlytics or Sentry)
- [ ] Referral programme (`referrals` table in schema v4.0)
- [ ] Subscription upgrade prompts — contextual (e.g., prompt to upgrade to Lender the moment a Free user taps "Make Offer", or taps "See full bid detail" on a listing)

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
| Contract auto-generated after offer acceptance | ⬜ Stage 4 |
| Contact reveal flow (blurred → unblur) | ⬜ Stage 4 |
| Remove `role` column; subscription-only gating | ⬜ Stage 4 |
| Admin KYC review | ⬜ Stage 5 |
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

---

*Nipanze Platforms Limited · contact@nipanze.ug · nipanze.ug*
*Made with ❤️ for financial inclusion in Uganda*