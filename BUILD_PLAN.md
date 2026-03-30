# BUILD_PLAN.md — Nipanze

> **Flutter + Supabase** · Digital loan listing marketplace for Uganda and emerging economies
> Last updated: March 2026 · Schema v1.0 · Seed v1.0

---

## Overview

This document is the authoritative build roadmap for Nipanze. Each stage builds on the last and is designed to be independently deployable. Stages 1–3 constitute the MVP. Stage 4 onward moves into growth and automation.

**Guiding principle:** Ship a working, honest subset at each stage. Never ship a broken feature in the name of completeness.

---

## Stage Map

| Stage | Title | Status | Target |
|---|---|---|---|
| 1 | Foundation | 🔄 In Progress | Auth, navigation, DB bootstrap |
| 2 | Core Marketplace | ⬜ Next | Live feed, order book, bidding |
| 3 | Polish & Supporting Features | ⬜ Planned | Watchlist, positions, notifications |
| 3.5 | Cloud Migration & Auth Hardening | ⬜ Planned | Supabase Cloud, RLS audit, token rotation |
| 4 | Negotiator Module & Contract Drafting | ⬜ Planned | Post-acceptance flow, draft contracts |
| 5 | Admin, Compliance & Credit Score Automation | ⬜ Planned | Admin dashboard, KYC automation, reputation engine |
| 6 | Launch & Growth | ⬜ Planned | Play Store, App Store, SMS, marketing |

---

## Stage 1 — Foundation

**Goal:** Working app skeleton. Users can register, verify email, log in, and land on a protected dashboard. All core infrastructure is in place and tested locally.

### 1.1 Project Bootstrap

- [ ] `flutter create nipanze` with package name `ug.nipanze.app`
- [ ] Add core dependencies: `supabase_flutter`, `flutter_bloc`, `go_router`, `injectable`, `get_it`, `freezed`, `json_serializable`, `envied`
- [ ] Configure `--dart-define` build variables: `SUPABASE_URL`, `SUPABASE_ANON_KEY`
- [ ] Set up `core/config/supabase_config.dart` — reads dart-define at build time; no hardcoded keys
- [ ] Add `core/errors/app_exception.dart` — typed exception hierarchy; `parseSupabaseError()` utility
- [ ] Set up `core/di/` — GetIt + Injectable; `configureDependencies()` called in `main.dart`

### 1.2 Supabase Local Setup

- [ ] Install Supabase CLI; `supabase init`; `supabase start`
- [ ] Apply `sql/schema.sql` (v1.0) to local instance
- [ ] Apply `sql/seed.sql` (v1.0) — 18 users, 41 listings, 3 contracts
- [ ] Confirm all 19 tables, views (`v_loan_listings`, `v_user_portfolio`, `v_lender_investments`, `v_loan_performance`), triggers, and RPCs are present
- [ ] Verify RLS enabled on all tables
- [ ] Create storage buckets: `kyc-documents`, `contracts`
- [ ] Confirm `trg_fn_require_kyc_for_loan` and `trg_fn_require_active_borrower` triggers fire correctly

### 1.3 Theme

- [ ] `core/theme/app_theme.dart` — light and dark variants
- [ ] Brand colours: accent blue `#3B82F6`, success green `#10B981`, warning amber `#F59E0B`, danger red `#EF4444`, purple `#8B5CF6`
- [ ] Typography: DM Sans (body), DM Mono (numeric/code values)
- [ ] `ThemeMode` persisted via `SharedPreferences`

### 1.4 Navigation

- [ ] `core/router/app_router.dart` — GoRouter with named routes
- [ ] Auth guard: unauthenticated users redirected to `/auth/login`; post-login redirect to intended route
- [ ] Route table (all routes declared, screens may be placeholder stubs):
  - `/auth/login`, `/auth/register`, `/auth/verify-email`, `/auth/reset-password`
  - `/dashboard`
  - `/marketplace`, `/marketplace/:requestId`
  - `/watchlist`
  - `/listings/create`, `/listings/my-listings`
  - `/contracts/:contractId`
  - `/positions`
  - `/analytics`
  - `/notifications`
  - `/kyc`
  - `/profile`, `/account`
  - `/admin`
- [ ] `MainScaffold` — bottom nav (Markets, Watchlist, Positions, Account) with GoRouter location-aware highlighting
- [ ] `OfflineBanner` widget — shown when Supabase connectivity is lost

### 1.5 Auth Feature

- [ ] `AuthRepository` — wraps `supabase.auth`; exposes `signIn`, `signUp`, `signOut`, `resetPassword`, `currentUser`
- [ ] `AuthBloc` / `AuthCubit` — states: `AuthInitial`, `AuthLoading`, `AuthAuthenticated`, `AuthUnauthenticated`, `AuthError`
- [ ] `LoginPage` — email + password; "Forgot password" link; "Register" link; error display using `parseSupabaseError()`
- [ ] `RegisterPage` — email, password, confirm password; post-submit redirects to verify-email prompt
- [ ] `VerifyEmailPage` — static instruction screen; "Resend email" button; auto-redirect on session detection
- [ ] `ResetPasswordPage` — email input; confirmation message on submit
- [ ] Session persistence — `supabase_flutter` handles JWT refresh automatically; verify token rotation via `replaced_by` chain in `audit_logs`
- [ ] Auth state listener in `main.dart` — rebuilds router on session change

### 1.6 Dashboard (Stub)

- [ ] `DashboardPage` — placeholder with "Welcome, [name]" and quick-action buttons
- [ ] Fetches `v_user_portfolio` for borrower/lender activity counts
- [ ] Visible only to authenticated users

### Stage 1 Exit Criteria

- [ ] Fresh `flutter pub get` + `dart run build_runner build` completes with zero errors
- [ ] Register → verify email → login → dashboard flow works end to end on web and Android emulator
- [ ] Logout clears session; router redirects to login
- [ ] All routes in route table are declared (stub screens acceptable)
- [ ] `supabase start` + schema + seed runs cleanly with no errors

---

## Stage 2 — Core Marketplace

**Goal:** The primary product loop is live. Borrowers can create listings. Lenders can browse, evaluate, and bid. Borrowers can view the live order book and accept a bid. This is the full marketplace loop minus negotiator assignment and contract drafting.

### 2.1 Marketplace Feed

- [ ] `MarketplaceRepository` — queries `v_loan_listings`; supports filter params (risk category, closing time, yield)
- [ ] `MarketplaceCubit` — states: `Loading`, `Loaded(listings)`, `Error`
- [ ] `MarketplacePage` — live feed with:
  - Filter pills: All · Low risk · High yield · Closing soon
  - `ListingCard` widget: name, region, duration, amount (UGX, DM Mono), risk badge, bid count, best current rate, coverage progress bar, time remaining
  - Live dot indicator (Supabase Realtime subscription on `loan_requests`)
  - Search/filter state preserved on navigation back
- [ ] `RiskBadge` widget — `Low` (green) / `Med` (amber) / `High` (red)
- [ ] Supabase Realtime: subscribe to `loan_requests` inserts and updates; refresh feed on event

### 2.2 Loan Detail & Order Book

- [ ] `LoanDetailPage` at `/marketplace/:requestId`
  - Amount, region, duration, ceiling rate header
  - Stats grid: best bid rate, competing bid count, coverage %, credit band (range only — never raw score)
  - **Live order book** — Supabase Realtime subscription on `loan_bids` for this `request_id`
  - Order book rows: anonymous lender token (e.g. `L-#482`), amount, rate — sorted by best (lowest) rate
  - "Save to watchlist" CTA — free, no subscription gate
  - "Accept best bid" CTA — visible to listing owner; requires Borrower subscription; triggers `accept_bid` RPC
  - "Place bid" CTA — requires Lender subscription; opens bid sheet
  - Subscription gate: unsubscribed users shown plan selector modal rather than error
- [ ] `OrderBookWidget` — real-time row list; best bid highlighted in green; animates on new bid arrival

### 2.3 KYC Feature

- [ ] `KycRepository` — reads/writes `kyc_verifications`; uploads docs to `kyc-documents` storage bucket
- [ ] `KycCubit` — states: `NotSubmitted`, `Pending`, `Approved`, `Rejected(reason)`
- [ ] `KycPage` — document upload form (National ID front/back, selfie); status display; rejection reason shown if rejected
- [ ] `KycStatusBanner` — reusable widget shown on `ListingCreatePage` when KYC is not approved
- [ ] DB trigger `trg_fn_require_kyc_for_loan` blocks listing creation at DB level; UI pre-checks and shows guidance

### 2.4 Listing Creation

- [ ] `ListingRepository` — creates records in `loan_requests`; enforces `system_settings` bounds client-side before submit
- [ ] `ListingCreateCubit` — multi-step form state; validates each step before advancing
- [ ] `ListingCreatePage` (Borrower subscription required)
  - Step 1: Amount (min/max from `system_settings`), duration, purpose
  - Step 2: Maximum acceptable interest rate (ceiling; within `system_settings` bounds)
  - Step 3: District selection, review summary
  - KYC gate: if KYC not approved, blocks step 3 with `KycStatusBanner`
  - On submit: inserts into `loan_requests`; DB trigger enforces all rules
- [ ] `MyListingsPage` — lists the current user's loan requests; status badges (Active / Expired / Contracted)

### 2.5 Bidding

- [ ] `BidRepository` — `placeBid(requestId, amount, rate)`, `withdrawBid(bidId)` 
- [ ] Bid validation client-side: rate ≤ ceiling rate; amount ≥ `system_settings.min_lender_investment`
- [ ] `PlaceBidSheet` — bottom sheet modal; amount and rate inputs; live preview of position in order book
- [ ] Lender subscription gate on bid submission
- [ ] Bid withdrawal: available until borrower accepts; `WithdrawBidButton` on lender's positions view

### 2.6 Bid Acceptance

- [ ] `accept_bid(request_id, bid_id, borrower_id)` RPC called on "Accept best bid" tap
- [ ] Atomic operation: marks bid as accepted, listing as contracted, triggers negotiator assignment (stub in Stage 2 — assignment recorded but no notification sent yet)
- [ ] Post-acceptance: listing status updates in real time on marketplace feed
- [ ] Error handling: optimistic UI rollback on RPC failure

### Stage 2 Exit Criteria

- [ ] End-to-end: create listing → go live → receive bids → live order book updates → accept bid → listing shows as contracted
- [ ] Subscription gates work: unsubscribed users cannot bid or create listings; watchlist is free
- [ ] KYC gate: `alice.namuli@gmail.com` cannot create a listing
- [ ] `admin1@nipanze.ug` can see contracted listing in admin stub
- [ ] All RLS policies verified: borrower cannot see another borrower's identity through any query

---

## Stage 3 — Polish & Supporting Features

**Goal:** The app is complete enough for beta users. Watchlist, positions, notifications, analytics, and profile are functional. UI is polished. Error states and empty states are handled everywhere.

### 3.1 Watchlist

- [ ] `WatchlistRepository` — `addToWatchlist`, `removeFromWatchlist`, reads `watchlist` table
- [ ] `WatchlistCubit` — syncs on mount; real-time update on bid activity for watched listings
- [ ] `WatchlistPage`
  - Saved listings with latest bid activity and timestamp
  - Closing urgency alerts: highlight card when < 24h remaining
  - "View & bid" and "Remove" per listing
  - Feature summary card (no subscription prompt — watchlist is free)
- [ ] Watchlist alerts: in-app notification when a new bid lands on a watched listing
- [ ] Empty state: illustrated prompt to browse marketplace

### 3.2 Positions

- [ ] `PositionsPage` — three-tab layout:
  - **As borrower** — open listings with bid count and coverage; contracted positions with rate, next payment status
  - **As lender** — bids placed, current status (Pending / Accepted / Withdrawn), contracted positions
  - **Contracts** — draft contracts available to view (links to `/contracts/:contractId`; stub in Stage 3)
- [ ] `RepTierBadge` widget — Bronze / Silver / Gold / Platinum / Restricted with correct colours

### 3.3 Notifications

- [ ] `NotificationRepository` — reads `notifications` table; marks as read
- [ ] `NotificationCubit` — unread count badge; real-time subscription
- [ ] `NotificationsPage` — chronological list; grouped by type; tap navigates to relevant screen
- [ ] In-app alerts for:
  - Bid received on your listing
  - Bid accepted / rejected
  - Negotiator assigned (stub message in Stage 3)
  - Contract draft available (stub in Stage 3)
  - KYC status change
  - Closing-soon warnings (24h and 6h)
- [ ] Unread badge on `MainScaffold` bottom nav notification icon

### 3.4 Profile & Account

- [ ] `ProfilePage` — avatar (initials), name, email, location, reputation tier badge, KYC status, subscription details
- [ ] `AccountPage`
  - Active subscription card: plan name, renewal date, included features
  - Plan upgrade selector: Borrower 20K / Lender 35K / Pro 150K — each shows feature list; "Upgrade" button (payment handled off-platform in Stage 3; button shows confirmation modal)
  - Identity panel: KYC status, employment type, reputation score out of 100 (tier displayed; raw score not shown to third parties)

### 3.5 Analytics

- [ ] `AnalyticsPage` — charts for the authenticated user:
  - Borrower: listing history, bid count over time, average offered rate trend
  - Lender: bids placed, win rate, average contracted rate, portfolio by risk category
- [ ] Uses `v_lender_investments` and `v_user_portfolio` views
- [ ] `fl_chart` or `syncfusion_flutter_charts` for rendering

### 3.6 Error States & Empty States

- [ ] Every list screen has a loading skeleton, empty state illustration, and error state with retry
- [ ] `OfflineBanner` appears and dismisses based on Supabase connectivity
- [ ] `parseSupabaseError()` used everywhere — no raw error strings shown to users

### Stage 3 Exit Criteria

- [ ] All bottom nav tabs are functional with real data
- [ ] Watchlist alerts fire in-app for watched listings with new bids
- [ ] Positions view accurately reflects borrower + lender activity from seed data
- [ ] Profile and account show correct subscription and KYC status for each test account
- [ ] App is stable on Android APK (arm64), web, and Linux desktop builds

---

## Stage 3.5 — Cloud Migration & Auth Hardening

**Goal:** Move from local Supabase to the cloud project (`sjkxselmwuflmubiwrfh`). Harden auth, verify all RLS policies, and confirm all triggers fire correctly in production.

### 3.5.1 Cloud Migration

- [ ] Apply `sql/schema.sql` (v1.0) to cloud project via SQL Editor
- [ ] Apply `sql/seed.sql` (v1.0) to cloud project
- [ ] Create storage buckets in cloud: `kyc-documents`, `contracts`
- [ ] Update `run_cloud.sh` scripts with cloud credentials
- [ ] Smoke test all 13 test accounts against cloud

### 3.5.2 RLS & Security Audit

- [ ] Verify RLS on every table: no row reachable by a user who should not access it
- [ ] Confirm `v_loan_listings` view excludes `borrower_id`, email, phone, full name, and raw `credit_score` in all query paths
- [ ] Confirm lender tokens (e.g. `L-#482`) are consistent per-session and never reveal lender identity
- [ ] Audit `audit_logs` — confirm append-only (no UPDATE/DELETE possible via RLS)
- [ ] Confirm device IP logging on auth events
- [ ] Confirm failed login threshold triggers account lock
- [ ] Verify refresh token rotation with `replaced_by` chain

### 3.5.3 Auth Hardening

- [ ] Email verification required before any protected route is accessible
- [ ] Session expiry handled gracefully — user prompted to re-authenticate
- [ ] Password reset flow tested end-to-end on cloud
- [ ] `audit_logs` confirmed written on every login, logout, and token refresh

### 3.5.4 Build Pipeline

- [ ] Android APK release build tested: `flutter build apk --release --split-per-abi --dart-define=...`
- [ ] Web release build tested: `flutter build web --release`
- [ ] Linux desktop release build tested

### Stage 3.5 Exit Criteria

- [ ] All flows from Stage 1–3 verified against cloud project
- [ ] RLS audit complete — no data leaks found
- [ ] Release APK installs and runs correctly on a physical Android device

---

## Stage 4 — Negotiator Module & Contract Drafting

**Goal:** Complete the post-acceptance flow. Negotiator assignment is automatic and functional. A draft contract is generated on-platform and viewable by both matched parties. The negotiator facilitates everything off-platform.

> **Note:** This is the most complex stage. No money movement is introduced. The platform generates and displays a draft contract; all execution happens off-platform.

### 4.1 Negotiator Assignment

- [ ] `sp_assign_negotiator(contract_id)` RPC — assigns an available, vetted negotiator from `negotiators` table
- [ ] Assignment happens atomically as part of `accept_bid` RPC
- [ ] `NegotiatorRepository` — fetch assigned negotiator for a contract (name and contact shown only after reveal)
- [ ] Both matched parties notified: "A negotiator has been assigned to your deal"
- [ ] Negotiator profile: name, credentials, specialisation — viewable by admin; redacted on-platform until reveal

### 4.2 Contact Reveal Flow

- [ ] Post-acceptance reveal gate: borrower and lender can unlock each other's contact details and the negotiator's details via a one-time subscription add-on
- [ ] Reveal is recorded in `audit_logs`; irreversible
- [ ] Revealed details blurred by default in UI; animated unblur on confirm
- [ ] Reveal triggers push notification to the other matched party: "Your contact details have been accessed by your matched partner"
- [ ] Neither party's contact details are shown before reveal — anonymity enforced at DB level

### 4.3 Draft Contract Generation

- [ ] `accept_bid` RPC triggers draft contract generation — written to `contracts` table
- [ ] Contract fields: borrower details (anonymised on-platform), lender details (anonymised on-platform), amount, rate, duration, repayment schedule, purpose, governing law clause
- [ ] Draft contract stored as structured data (not PDF) in Stage 4; PDF export in Stage 5
- [ ] `ContractDetailPage` at `/contracts/:contractId`:
  - Read-only on-platform
  - Shows all contract fields with anonymised placeholders where identity has not been revealed
  - "Download draft" button (Stage 5)
  - "View negotiator" section — blurred until reveal
  - Status badge: Draft / In Execution / Completed / Defaulted

### 4.4 Contract Status Lifecycle

- [ ] Contract status transitions: `draft` → `in_execution` → `completed` or `defaulted`
- [ ] Status updated by: negotiator report, participant self-report (both required to confirm)
- [ ] Disputed status: escalated to admin for manual resolution
- [ ] Status changes feed into credit scoring (Stage 5 for full automation)

### 4.5 Negotiator Assessments

- [ ] `NegotiatorAssessmentForm` — submitted by assigned negotiator via admin panel
- [ ] Assessment fields: repayment behaviour, contract adherence, dispute handling, overall rating (1–5)
- [ ] Assessment stored in `negotiator_assessments` table; feeds `sp_calculate_reputation_score`
- [ ] Assessments visible to admin; never directly shown to assessed user (score effect only)

### Stage 4 Exit Criteria

- [ ] `accept_bid` RPC assigns negotiator and creates draft contract atomically
- [ ] Both matched parties see the draft contract in their Positions → Contracts tab
- [ ] Reveal flow works: blurred → confirm → animated unblur
- [ ] Contract status can transition through full lifecycle
- [ ] `funds@victoriainvest.co.ug` and `lending@equatorfinance.ug` test accounts both show viewable contracts

---

## Stage 5 — Admin, Compliance & Credit Score Automation

**Goal:** Admin dashboard is fully operational. KYC review is in-app. Credit/reputation scoring is automated. PDF contract export works. Platform is ready for real users.

### 5.1 Admin Dashboard

- [ ] `AdminDashboardPage` at `/admin` (admin role only; GoRouter guard)
- [ ] Live KPI grid (Supabase Realtime):
  - Active listings, total bid volume (UGX), active subscribers, avg market rate, match rate, reveals this month + revenue
- [ ] Listing activity table: all listings with name, amount, risk, bid count, best rate, coverage, status
- [ ] User management: list all users; view KYC status; suspend / activate account
- [ ] Audit log viewer: filterable by user, event type, date range
- [ ] Negotiator management: list vetted negotiators; assign manually if auto-assignment fails; view assessments submitted

### 5.2 KYC Review (In-App Admin)

- [ ] `KycReviewPage` — admin view of pending KYC submissions
- [ ] Document viewer: National ID front/back, selfie pulled from `kyc-documents` bucket
- [ ] Approve / Reject with required rejection reason
- [ ] Approval triggers: `kyc_verifications.status` updated; user notified; listing creation gate lifted
- [ ] KYC expiry tracking: flag users whose KYC will expire within 30 days; prompt re-verification

### 5.3 Credit Score Automation

- [ ] `sp_calculate_reputation_score(user_id)` — weighted 0–100 score:
  - Repayment performance: 40% (negotiator-reported + participant self-reported)
  - Platform participation: 20% (listing and bidding activity)
  - Risk accuracy: 20% (stated risk vs actual outcome)
  - Consistency: 20% (behavioural patterns across deals)
- [ ] Score recalculated on: contract status change, negotiator assessment submitted, new deal completed
- [ ] Reputation tier assigned automatically: Platinum (85–100), Gold (70–84), Silver (55–69), Bronze (40–54), Restricted (< 40)
- [ ] Tier displayed publicly on listings; raw score never exposed to third parties
- [ ] `RepTierBadge` widget updated to pull live tier from DB

### 5.4 PDF Contract Export

- [ ] Supabase Edge Function (Deno): `generate-contract-pdf`
- [ ] Triggered on contract status change to `in_execution`
- [ ] PDF stored in `contracts` storage bucket; signed URL returned to matched parties
- [ ] "Download contract PDF" button active in `ContractDetailPage` after generation
- [ ] PDF template: Nipanze letterhead, all contract fields, repayment schedule table, signature blocks

### 5.5 SMS Notifications (Stage 5 Addition)

- [ ] Supabase Edge Function: `send-sms`
- [ ] Integrated with Africa's Talking or Twilio
- [ ] SMS triggers: bid accepted, negotiator assigned, contract draft available, closing-soon (24h), KYC status change
- [ ] Phone number confirmed via OTP at registration (added to register flow in this stage)

### 5.6 System Settings Enforcement

- [ ] Admin panel section: view and edit `system_settings` values
  - `max_concurrent_loans`, `min_loan_amount`, `max_loan_amount`
  - `min_interest_rate`, `max_interest_rate`
  - `listing_duration_days`, `kyc_validity_months`
  - `min_lender_investment`
- [ ] Changes take effect immediately (DB is source of truth; client reads at runtime)

### Stage 5 Exit Criteria

- [ ] Admin can approve/reject KYC submissions in-app
- [ ] Reputation scores recalculate automatically on deal completion
- [ ] PDF contract generated and downloadable for contracted deals
- [ ] SMS fires on bid acceptance (tested with Africa's Talking sandbox)
- [ ] `v_loan_performance` view drives all admin KPI metrics accurately

---

## Stage 6 — Launch & Growth

**Goal:** Public launch. App Store and Play Store submissions. Production monitoring. Onboarding flow. Growth tooling.

### 6.1 App Store & Play Store Submission

- [ ] `flutter build appbundle --release` — Play Store AAB
- [ ] `flutter build ios --release` — App Store IPA
- [ ] Play Store listing: screenshots (Pixel 6, tablet), description, privacy policy URL, content rating
- [ ] App Store listing: screenshots (iPhone 15, iPad), description, App Privacy details
- [ ] Privacy policy published at `nipanze.ug/privacy`
- [ ] Terms of service published at `nipanze.ug/terms`

### 6.2 Onboarding Flow

- [ ] First-launch onboarding: 3-screen carousel explaining marketplace concept, anonymity, and subscription model
- [ ] Role selection at registration: Borrower / Lender / Both
- [ ] KYC prompt shown immediately after role selection with estimated completion time
- [ ] Subscription prompt with plan comparison shown post-KYC

### 6.3 Production Monitoring

- [ ] Supabase dashboard alerts: DB size, auth error rate, function invocation failures
- [ ] Crash reporting: `firebase_crashlytics` or Sentry
- [ ] Performance monitoring: cold start time, marketplace feed load time, order book update latency
- [ ] Uptime monitoring: external ping on `/health` endpoint

### 6.4 Pro Plan — Analytics API

- [ ] REST API endpoint (Supabase Edge Function) returning marketplace aggregate data
- [ ] Authentication via API key issued to Pro subscribers
- [ ] Rate limited to 1,000 requests/day per key
- [ ] Documented at `nipanze.ug/developers`
- [ ] Data available: listings feed, bid volume by category, market rate trends, credit band distribution

### 6.5 Marketing & Growth

- [ ] Referral programme: existing subscribers can share a referral code; successful activation credits one month free
- [ ] SEO landing page at `nipanze.ug` — static, fast-loading, Uganda-targeted
- [ ] Partnership outreach: SACCOs, MFIs, business associations for lender pipeline

### Stage 6 Exit Criteria

- [ ] App live on Play Store (Android) and App Store (iOS)
- [ ] First 50 paying subscribers onboarded
- [ ] Production monitoring alerting correctly
- [ ] Pro API has at least one active external consumer

---

## Test Accounts Reference

All accounts use password `Test1234!`

| Email | Role | Best for testing |
|---|---|---|
| `david.mukasa@gmail.com` | Borrower | Listing + contracted position; Bronze tier |
| `sarah.namukasa@yahoo.com` | Borrower | Contract draft pending |
| `james.okello@outlook.com` | Both | Borrower + lender flows |
| `maria.nakato@gmail.com` | Borrower | Active listing with 1 pending bid |
| `robert.ssemwanga@gmail.com` | Both | Bid submitted on two listings |
| `invest@pearlcapital.ug` | Lender | Multiple active bids |
| `funds@victoriainvest.co.ug` | Lender | Bid accepted — contract viewable |
| `lending@equatorfinance.ug` | Lender | Bid accepted — contract viewable |
| `info@greenleafagro.co.ug` | Lender | Pending bid |
| `contact@kampalatech.ug` | Lender | Pending bid |
| `alice.namuli@gmail.com` | Borrower | KYC pending — test listing gate |
| `admin1@nipanze.ug` | Admin | Full admin dashboard access |
| `test.user@gmail.com` | Borrower | No KYC, no profile — test onboarding gates |

---

## Key Flows to Test at Each Stage

| Flow | Stage | Account |
|---|---|---|
| Register → verify email → login | 1 | New account |
| KYC gate blocks listing creation | 2 | `alice.namuli@gmail.com` |
| Browse marketplace (free, no bid) | 2 | `test.user@gmail.com` |
| View live order book | 2 | Any authenticated account |
| Place a bid (lender subscription) | 2 | `invest@pearlcapital.ug` |
| Accept a bid (borrower subscription) | 2 | `david.mukasa@gmail.com` |
| Watchlist alerts on new bid | 3 | Any account — watch "Business expansion" |
| Positions — borrower + contracts tabs | 3 | `david.mukasa@gmail.com` |
| Lender bid tracking | 3 | `invest@pearlcapital.ug` |
| Negotiator assignment post-acceptance | 4 | `david.mukasa@gmail.com` |
| Contact reveal flow | 4 | `funds@victoriainvest.co.ug` |
| Draft contract viewable | 4 | `lending@equatorfinance.ug` |
| Admin KYC approve/reject | 5 | `admin1@nipanze.ug` |
| Reputation score recalculation | 5 | Admin triggers on deal completion |
| PDF contract download | 5 | Any contracted pair |

---

## Architecture Constraints (Carry Through All Stages)

These constraints are non-negotiable and apply to every feature built:

1. **No fund movement** — Nipanze never initiates, processes, or records financial transactions. Mock RPCs (`mock_top_up`, `mock_disburse`, `mock_repayment`) exist in seed for testing state flows only; they are removed before Stage 6 launch.
2. **Anonymity by default** — `borrower_id` is never exposed in marketplace queries. Lenders appear as tokens. Identity is revealed only through the opt-in reveal flow (Stage 4).
3. **DB is the gate** — all rules enforced at DB level via triggers and RLS. Client-side validation is UX convenience only.
4. **Friendly errors** — `parseSupabaseError()` is used everywhere. Raw exception strings, internal URLs, and `errno` codes never reach the user.
5. **One account per person** — duplicate email and phone enforcement via DB unique constraints; flagged in `audit_logs`.
6. **Append-only audit log** — `audit_logs` must never be writable via UPDATE or DELETE by any role.

---

## Dependencies

| Dependency | Purpose | Stage introduced |
|---|---|---|
| `supabase_flutter` | Auth, DB, Realtime, Storage | 1 |
| `flutter_bloc` | State management | 1 |
| `go_router` | Navigation + auth guards | 1 |
| `injectable` + `get_it` | Dependency injection | 1 |
| `freezed` + `json_serializable` | Code generation | 1 |
| `envied` | Compile-time secrets | 1 |
| `fl_chart` or `syncfusion_flutter_charts` | Analytics charts | 3 |
| `firebase_crashlytics` or Sentry | Crash reporting | 6 |
| Africa's Talking or Twilio SDK | SMS | 5 |

---

*Nipanze Platforms Limited · contact@nipanze.ug · nipanze.ug*
*Made with ❤️ for financial inclusion in Uganda*