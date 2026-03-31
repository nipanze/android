# BUILD_PLAN.md — Nipanze

> **Flutter + Supabase** · Digital loan listing marketplace for Uganda and emerging economies
> Last updated: March 2026 · Schema v5.0 · Scaffold v1.0

---

## Overview

This document is the authoritative build roadmap for Nipanze. Each stage builds on the last and is designed to be independently deployable. Stages 1–3 constitute the MVP. Stage 4 onward moves into growth and automation.

**Guiding principle:** Ship a working, honest subset at each stage. Never ship a broken feature in the name of completeness.

---

## Stage Map

| Stage | Title | Status | Target |
|---|---|---|---|
| 1 | Foundation | ✅ Complete | Auth, navigation, DB bootstrap |
| 2 | Core Marketplace | 🔄 In Progress | Live feed, order book, bidding |
| 3 | Polish & Supporting Features | ⬜ Next | Watchlist, positions, notifications |
| 3.5 | Cloud Migration & Auth Hardening | ⬜ Planned | Supabase Cloud, RLS audit, token rotation |
| 4 | Negotiator Module & Contract Drafting | ⬜ Planned | Post-acceptance flow, draft contracts |
| 5 | Admin, Compliance & Credit Score Automation | ⬜ Planned | Admin dashboard, KYC automation, reputation engine |
| 6 | Launch & Growth | ⬜ Planned | Play Store, App Store, SMS, marketing |

---

## Stage 1 — Foundation ✅ Complete

**Goal:** Working app skeleton. Users can register, verify email, log in, and land on a protected dashboard. All core infrastructure is in place and tested locally.

### 1.1 Project Bootstrap

- [x] `flutter create nipanze` with package name `ug.nipanze.app`
- [x] Core dependencies: `supabase_flutter`, `flutter_bloc`, `go_router`, `injectable`, `get_it`, `freezed`, `json_serializable`
- [x] `--dart-define` build variables: `SUPABASE_URL`, `SUPABASE_ANON_KEY`
- [x] `core/config/supabase_config.dart` — reads dart-define at build time; no hardcoded keys
- [x] `core/errors/app_exception.dart` — typed exception hierarchy; `parseSupabaseError()` utility covering all v5.0 trigger error codes
- [x] `core/di/injection.dart` — GetIt + Injectable; `configureDependencies()` called in `main.dart`; pre-generated bootstrap registers all current singletons

### 1.2 Supabase Local Setup

- [x] `supabase/config.toml` in place for local stack
- [x] Schema v5.0 SQL in `sql/` with full v4.0 → v5.0 diff documented in `sql/README.md`
- [x] Storage buckets documented: `kyc-documents`, `contracts`
- [ ] `sql/seed.sql` — not yet written; apply schema manually until seed is created in Stage 2

### 1.3 Theme

- [x] `core/theme/app_theme.dart` — light and dark variants, full Material 3 configuration
- [x] Brand colours: accent `#3B82F6`, success `#10B981`, warning `#F59E0B`, danger `#EF4444`, purple `#8B5CF6`
- [x] Typography: DM Sans (body/UI), DM Mono (all numeric and code values)
- [ ] `ThemeMode` persisted via `SharedPreferences` — scaffolded but not wired to persistence yet

### 1.4 Navigation

- [x] `core/router/app_router.dart` — GoRouter with all named routes
- [x] Auth guard: unauthenticated users redirected to `/auth/login`; post-login redirect to intended route
- [x] `GoRouterRefreshStream` — router rebuilds on every AuthBloc state change
- [x] Full route table declared: `/auth/login`, `/auth/register`, `/auth/verify-email`, `/auth/reset-password`, `/dashboard`, `/marketplace`, `/marketplace/:requestId`, `/watchlist`, `/listings/create`, `/listings/my-listings`, `/contracts/:contractId`, `/positions`, `/notifications`, `/kyc`, `/profile`, `/account`, `/admin`
- [x] `MainScaffold` — bottom nav (Marketplace, Watchlist, Positions, Account) with GoRouter location-aware highlighting
- [ ] `OfflineBanner` widget — not yet built

### 1.5 Auth Feature

- [x] `AuthRepository` — `signIn`, `signUp`, `signOut`, `resetPassword`, `currentUser`, `resendVerificationEmail`, `authStateChanges` stream
- [x] `AuthBloc` — events: `AuthStarted`, `AuthSignInRequested`, `AuthSignUpRequested`, `AuthSignOutRequested`, `AuthPasswordResetRequested`, `AuthUserChanged`
- [x] `AuthBloc` — states: `AuthLoading`, `AuthAuthenticated`, `AuthUnauthenticated`, `AuthError`, `AuthPasswordResetSent`
- [x] `LoginPage` — email + password; forgot password link; register link; `parseSupabaseError()` error display
- [x] `RegisterPage` — email, password, confirm password; post-submit redirects to verify-email
- [x] `VerifyEmailPage` — resend email button; auto-redirect on session detection via BlocListener
- [x] `ResetPasswordPage` — email input; confirmation state on success
- [x] Auth state listener in `main.dart` — rebuilds router on session change; `AuthState` name clash with Supabase resolved via `hide AuthState`
- [ ] Session expiry / idle timeout not wired (auto-logout after 30 min per `system_settings` — Stage 3.5)

### 1.6 Dashboard

- [x] `DashboardPage` — welcome text, quick-action grid (browse, list request, watchlist, KYC status)
- [x] Displays subscription plan, KYC status, lender token from auth state
- [ ] Live `v_user_portfolio` query not wired — uses auth state cache only; full data query in Stage 3

### Stage 1 Exit Criteria

- [x] Register → verify email → login → dashboard flow works end to end on web and Android emulator
- [x] Logout clears session; router redirects to login
- [x] All routes in route table declared (stub screens acceptable)
- [x] 8 unit tests passing in `test/features/auth/auth_bloc_test.dart`
- [x] `supabase/config.toml` and schema SQL in place for `supabase start` workflow
- [ ] `dart run build_runner build` must be run after first clone to generate `injection.config.dart`

---

## Stage 2 — Core Marketplace 🔄 In Progress

**Goal:** The primary product loop is live. Borrowers can create listings. Lenders can browse, evaluate, and bid. Borrowers can view the live order book and accept a bid.

### 2.1 Marketplace Feed

- [x] `MarketplaceRepository` — queries `v_loan_listings`; filter params (risk category, closing soon, high yield)
- [x] `MarketplaceCubit` — states: `MarketplaceInitial`, `MarketplaceLoading`, `MarketplaceLoaded(listings, activeFilter)`, `MarketplaceError`
- [x] `MarketplacePage` — live feed with filter pills (All / Low risk / High yield / Closing soon)
- [x] `ListingCard` — title, district, duration, UGX amount (DM Mono), risk badge, bid count, best rate, bid-activity bar, time remaining; closing-soon colour changes at 6h and 24h
- [x] `RiskBadge` widget — Low (green) / Med (amber) / High (red)
- [x] `ListingCardSkeleton` — animated skeleton for loading state
- [x] `watchListings()` Realtime stream wired in `MarketplaceCubit` — feed refreshes on `loan_requests` events
- [x] `LiveDot` animated widget on feed header
- [ ] Filter/scroll state not preserved on back-navigation — cubit disposes with the page

### 2.2 Loan Detail & Order Book

- [x] `LoanDetailPage` at `/marketplace/:requestId` — amount header, stats grid (best bid rate, bid count, credit band, time left), non-custodial notice
- [x] Order book — anonymous lender tokens, amounts, rates sorted by lowest rate; best bid row highlighted green
- [x] "Save to watchlist" CTA — snackbar confirmation; DB write wired in Stage 3
- [x] "Accept best bid" CTA — calls `accept_bid` RPC; navigates to `/contracts/:contractId` on success
- [x] "Place bid" CTA — opens `_PlaceBidSheet` bottom sheet
- [x] `_PlaceBidSheet` — amount and rate inputs, ceiling rate validation, `placeBid()` call, loading state
- [ ] `watchOrderBook()` exists in `MarketplaceRepository` but not yet wired into `LoanDetailPage` — page does a one-off load on mount; Realtime per-listing order book is next
- [ ] Subscription gate — DB rejects correctly and error is parsed; plan-selector modal not yet built (snackbar only)
- [ ] Optimistic UI rollback on `accept_bid` RPC failure not implemented

### 2.3 KYC Feature

- [x] `KycPage` — status banner (not submitted / pending / approved / rejected), document item list UI, submit button with loading state
- [x] DB trigger `trg_fn_require_kyc_for_loan` enforced at DB level; `KycRequiredException` and `KycExpiredException` parsed by `parseSupabaseError()`
- [x] KYC gate check on `ListingCreatePage` step 3 — reads subscription and KYC from auth state before allowing submit
- [ ] `KycRepository` — Storage uploads to `kyc-documents` bucket not yet wired; document picker not integrated
- [ ] `KycCubit` — not yet created; `KycPage` uses local `setState` only
- [ ] `KycStatusBanner` — not extracted as reusable widget; gate is inline on listing create page

### 2.4 Listing Creation

- [x] `ListingCreatePage` — 3-step `PageView` (step 1: amount/duration/purpose → step 2: ceiling rate/risk → step 3: district/review)
- [x] Client-side validation on each step before advancing
- [x] KYC and borrower subscription gates checked before submit with user-facing messages
- [x] Inserts into `loan_requests`; full DB trigger chain enforces all rules server-side
- [ ] `ListingRepository` — not extracted; insert is inline in `ListingCreatePage`
- [ ] `ListingCreateCubit` — multi-step form state not extracted; page uses `PageController` + local state
- [ ] `system_settings` limits (min/max amount, rate bounds) hardcoded in validators — runtime fetch from DB not wired
- [ ] `MyListingsPage` — empty state stub only; no real Supabase query

### 2.5 Bidding

- [x] `placeBid(requestId, amount, rate)` in `MarketplaceRepository` — inserts into `loan_bids`
- [x] `withdrawBid(bidId)` in `MarketplaceRepository` — updates status to `withdrawn`
- [x] Client-side ceiling rate validation in `_PlaceBidSheet`
- [ ] `BidRepository` — not extracted as separate class; bid methods live in `MarketplaceRepository`
- [ ] Bid withdrawal UI — method exists but no button exposed in positions view yet
- [ ] Lender subscription pre-check UI — DB rejects and error is parsed; no pre-flight UI gate

### 2.6 Bid Acceptance

- [x] `accept_bid(request_id, bid_id, borrower_id)` RPC called on "Accept best bid" tap
- [x] On success: navigates to `/contracts/:contractId`
- [x] Error messages from RPC parsed by `parseSupabaseError()` and shown to user
- [ ] Listing status does not update in real time on feed after acceptance — feed requires manual pull-to-refresh
- [ ] No optimistic UI rollback on RPC failure

### Stage 2 Remaining Work

- [ ] Wire `watchOrderBook()` Realtime stream into `LoanDetailPage`
- [ ] Build `KycRepository` + `KycCubit` with file picker and Storage uploads
- [ ] Extract `ListingRepository` and `ListingCreateCubit`
- [ ] Read `system_settings` limits from DB at runtime for form bounds
- [ ] `MyListingsPage` real data query against `loan_requests` filtered by `borrower_id`
- [ ] Subscription gate plan-selector modal on bid/listing CTAs
- [ ] Bid withdrawal button in lender positions tab
- [ ] Feed Realtime update after bid acceptance

### Stage 2 Exit Criteria

- [ ] End-to-end: create listing → go live → receive bids → live order book updates → accept bid → listing shows as contracted
- [ ] Subscription gates work: unsubscribed users cannot bid or create listings; watchlist is free
- [ ] KYC gate: `alice.namuli@gmail.com` cannot create a listing
- [ ] `admin1@nipanze.ug` can see contracted listing in admin stub
- [ ] All RLS policies verified: borrower cannot see another borrower's identity through any query

---

## Stage 3 — Polish & Supporting Features ⬜ Next

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
- [ ] "Save to watchlist" on `LoanDetailPage` writes to DB (currently snackbar only)
- [ ] Empty state: illustrated prompt to browse marketplace

### 3.2 Positions

- [ ] `PositionsPage` — three-tab layout with real data:
  - **As borrower** — open listings with bid count; contracted positions with rate and next indicative payment
  - **As lender** — bids placed, current status (Pending / Accepted / Withdrawn), contracted positions
  - **Contracts** — links to `/contracts/:contractId`
- [ ] Uses `v_user_portfolio` and `v_lender_bids` views
- [ ] `RepTierBadge` wired to live tier from DB (widget already built)

### 3.3 Notifications

- [ ] `NotificationRepository` — reads `notifications` table; marks as read
- [ ] `NotificationCubit` — unread count; real-time subscription
- [ ] `NotificationsPage` — chronological list; grouped by type; tap deep-links to relevant screen
- [ ] In-app alerts for: bid received, bid accepted/rejected, negotiator assigned (stub), KYC status change, closing-soon 24h/6h
- [ ] Unread badge on `MainScaffold` bottom nav

### 3.4 Profile & Account

- [ ] `ProfilePage` — editable name, district, employment; live fetch from `profiles`
- [ ] `AccountPage` — live subscription data from `subscriptions`; upgrade flow (off-platform payment)
- [ ] `ThemeMode` persisted via `SharedPreferences`

### 3.5 Analytics

- [ ] `AnalyticsPage` — `fl_chart` charts from `v_lender_bids` and `v_user_portfolio`
  - Borrower: listing history, bid count over time, avg offered rate trend
  - Lender: bids placed, win rate, avg contracted rate, portfolio by risk category

### 3.6 Error States & Empty States

- [ ] `OfflineBanner` widget — shown when Supabase connectivity is lost
- [ ] Loading skeletons on watchlist, positions, notifications pages
- [ ] Every list screen has a loading skeleton, empty state, and error state with retry
- [ ] `parseSupabaseError()` verified on every screen

### Stage 3 Exit Criteria

- [ ] All bottom nav tabs functional with real data
- [ ] Watchlist alerts fire in-app for watched listings with new bids
- [ ] Positions view accurately reflects borrower + lender activity from seed data
- [ ] Profile and account show correct subscription and KYC status for each test account
- [ ] App is stable on Android APK (arm64), web, and Linux desktop builds

---

## Stage 3.5 — Cloud Migration & Auth Hardening ⬜ Planned

**Goal:** Move from local Supabase to cloud. Harden auth, verify all RLS policies, confirm all triggers fire correctly in production.

### 3.5.1 Cloud Migration

- [ ] Apply `sql/schema_v5.sql` to cloud project via SQL Editor
- [ ] Apply `sql/seed.sql` to cloud project
- [ ] Create storage buckets in cloud: `kyc-documents`, `contracts`
- [ ] Create `run_cloud.sh` with cloud credentials
- [ ] Smoke test all 13 test accounts against cloud

### 3.5.2 RLS & Security Audit

- [ ] Verify RLS on every table: no row reachable by a user who should not access it
- [ ] Confirm `v_loan_listings` view excludes `borrower_id`, email, phone, full name, raw `credit_score` in all query paths
- [ ] Confirm lender tokens (e.g. `L-#482`) are consistent per-session and never reveal lender identity
- [ ] Audit `audit_logs` — confirm append-only (no UPDATE/DELETE possible via RLS)
- [ ] Confirm device IP logging on auth events
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

## Stage 4 — Negotiator Module & Contract Drafting ⬜ Planned

**Goal:** Complete the post-acceptance flow. Negotiator assignment is automatic and functional. A draft contract is generated on-platform and viewable by both matched parties.

> **Note:** No money movement introduced at any point. The platform generates and displays a draft contract; all execution happens off-platform.

### 4.1 Negotiator Assignment

- [ ] `sp_assign_negotiator(contract_id)` RPC — already in schema v5.0; wire into Flutter
- [ ] `NegotiatorRepository` — fetch assigned negotiator for a contract
- [ ] Both matched parties notified: "A negotiator has been assigned to your deal"
- [ ] Negotiator details redacted on-platform until contact reveal

### 4.2 Contact Reveal Flow

- [ ] Post-acceptance reveal gate: borrower and lender unlock each other's contact details
- [ ] Reveal recorded in `contact_reveals` table and `audit_logs`; irreversible
- [ ] Revealed details blurred by default; animated unblur on confirm
- [ ] Push notification to other party: "Your contact details have been accessed"
- [ ] No fee charged on-platform (non-custodial; v5.0 removed `amount_charged_ugx`)

### 4.3 Draft Contract Generation

- [ ] `ContractDetailPage` fully wired with live data (currently queries DB; indicative schedule display done)
- [ ] Anonymised placeholders where identity not yet revealed
- [ ] "Download draft" button — stub until Stage 5 PDF generation
- [ ] "View negotiator" section — blurred until reveal flow completed

### 4.4 Contract Status Lifecycle

- [ ] Status transitions: `draft` → `in_execution` → `completed` or `defaulted`
- [ ] Participant self-report on `repayment_schedules.reported_status`
- [ ] Disputed status escalated to admin
- [ ] Status changes feed into reputation score recalculation

### 4.5 Negotiator Assessments

- [ ] `NegotiatorAssessmentForm` — submitted via admin panel
- [ ] Assessment stored in `negotiator_assessments`; feeds `sp_calculate_reputation_score`
- [ ] Never shown raw to assessed user — score effect only

### Stage 4 Exit Criteria

- [ ] `accept_bid` RPC assigns negotiator and creates draft contract atomically
- [ ] Both matched parties see the draft contract in Positions → Contracts tab
- [ ] Reveal flow works: blurred → confirm → animated unblur
- [ ] Contract status can transition through full lifecycle
- [ ] `funds@victoriainvest.co.ug` and `lending@equatorfinance.ug` test accounts show viewable contracts

---

## Stage 5 — Admin, Compliance & Credit Score Automation ⬜ Planned

**Goal:** Admin dashboard fully operational. KYC review in-app. Reputation scoring automated. PDF contract export works. Platform ready for real users.

### 5.1 Admin Dashboard

- [ ] `AdminDashboardPage` fully wired (currently shows static KPIs; needs live `v_loan_performance` data)
- [ ] GoRouter admin guard: redirect non-admin users away from `/admin`
- [ ] Live KPI grid via Supabase Realtime
- [ ] Listing activity table with all active listings
- [ ] User management: list users, view KYC, suspend/activate account
- [ ] Audit log viewer: filterable by user, event type, date range
- [ ] Negotiator management: list vetted negotiators, manual assignment, view assessments

### 5.2 KYC Review (In-App Admin)

- [ ] `KycReviewPage` — admin view of pending submissions
- [ ] Document viewer: National ID front/back, selfie from `kyc-documents` bucket
- [ ] Approve / Reject with required rejection reason
- [ ] KYC expiry tracking: flag users expiring within 30 days

### 5.3 Credit Score Automation

- [ ] `sp_calculate_reputation_score(user_id)` — already in schema v5.0; trigger from Flutter events
- [ ] Score recalculated on: contract status change, negotiator assessment submitted, new deal completed
- [ ] Reputation tier auto-assigned; `RepTierBadge` pulls live tier from DB
- [ ] Raw score never exposed to third parties

### 5.4 PDF Contract Export

- [ ] Supabase Edge Function (Deno): `generate-contract-pdf`
- [ ] Triggered on contract status change to `in_execution`
- [ ] PDF stored in `contracts` bucket; signed URL returned to matched parties
- [ ] "Download contract PDF" button active in `ContractDetailPage`

### 5.5 SMS Notifications

- [ ] Supabase Edge Function: `send-sms` — Africa's Talking or Twilio
- [ ] SMS triggers: bid accepted, negotiator assigned, contract available, closing-soon, KYC status
- [ ] Phone OTP verification added to register flow

### 5.6 System Settings Enforcement

- [ ] Admin panel section: view and edit `system_settings` values at runtime
- [ ] Flutter form validators read limits from DB (not hardcoded)

### Stage 5 Exit Criteria

- [ ] Admin can approve/reject KYC submissions in-app
- [ ] Reputation scores recalculate automatically on deal completion
- [ ] PDF contract generated and downloadable for contracted deals
- [ ] SMS fires on bid acceptance (Africa's Talking sandbox)
- [ ] `v_loan_performance` drives all admin KPI metrics accurately

---

## Stage 6 — Launch & Growth ⬜ Planned

**Goal:** Public launch. App Store and Play Store submissions. Production monitoring. Onboarding flow.

### 6.1 App Store & Play Store Submission

- [ ] `flutter build appbundle --release` — Play Store AAB
- [ ] `flutter build ios --release` — App Store IPA
- [ ] Play Store listing: screenshots, description, privacy policy URL
- [ ] App Store listing: screenshots, App Privacy details
- [ ] Privacy policy published at `nipanze.ug/privacy`
- [ ] Terms of service published at `nipanze.ug/terms`

### 6.2 Onboarding Flow

- [ ] 3-screen carousel: marketplace concept, anonymity, subscription model
- [ ] Role selection at registration: Borrower / Lender / Both
- [ ] KYC prompt immediately after role selection
- [ ] Subscription prompt with plan comparison shown post-KYC

### 6.3 Production Monitoring

- [ ] Crash reporting: Firebase Crashlytics or Sentry
- [ ] Performance monitoring: cold start, feed load, order book update latency
- [ ] Supabase dashboard alerts: DB size, auth error rate, function failures
- [ ] Uptime monitoring on `/health` endpoint

### 6.4 Pro Plan — Analytics API

- [ ] Supabase Edge Function returning marketplace aggregate data
- [ ] Authentication via API key (`api_keys` table, Pro subscribers only)
- [ ] Rate limited to 1,000 requests/day
- [ ] Documented at `nipanze.ug/developers`

### 6.5 Marketing & Growth

- [ ] Referral programme — `referrals` table already in schema v5.0
- [ ] SEO landing page at `nipanze.ug`
- [ ] Partnership outreach: SACCOs, MFIs, business associations

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

| Flow | Stage | Status | Account |
|---|---|---|---|
| Register → verify email → login | 1 | ✅ Working | New account |
| KYC gate blocks listing creation | 2 | ✅ Working (DB enforced) | `alice.namuli@gmail.com` |
| Browse marketplace (free, no bid) | 2 | ✅ Working | `test.user@gmail.com` |
| View live order book | 2 | ✅ Working (one-off load) | Any authenticated account |
| Place a bid | 2 | ✅ Working | `invest@pearlcapital.ug` |
| Accept a bid | 2 | ✅ Working | `david.mukasa@gmail.com` |
| Live order book Realtime updates | 2 | ❌ Not wired | Any account |
| Subscription gate modal | 2 | ❌ Snackbar only | Any free account |
| KYC document upload to storage | 2 | ❌ Not wired | Any account |
| My listings — real data | 2 | ❌ Stub | `david.mukasa@gmail.com` |
| Watchlist alerts on new bid | 3 | ⬜ Planned | Any account |
| Positions — real data | 3 | ⬜ Planned | `david.mukasa@gmail.com` |
| Lender bid tracking | 3 | ⬜ Planned | `invest@pearlcapital.ug` |
| Negotiator assignment post-acceptance | 4 | ⬜ Planned | `david.mukasa@gmail.com` |
| Contact reveal flow | 4 | ⬜ Planned | `funds@victoriainvest.co.ug` |
| Draft contract viewable | 4 | ⬜ Planned | `lending@equatorfinance.ug` |
| Admin KYC approve/reject | 5 | ⬜ Planned | `admin1@nipanze.ug` |
| Reputation score recalculation | 5 | ⬜ Planned | Admin triggers on deal completion |
| PDF contract download | 5 | ⬜ Planned | Any contracted pair |

---

## Architecture Constraints (Non-Negotiable Across All Stages)

1. **No fund movement** — Nipanze never initiates, processes, or records financial transactions. All financial settlement is directly between matched participants off-platform.
2. **Anonymity by default** — `borrower_id` is never exposed in marketplace queries. Lenders appear as tokens (e.g. `L-#482`). Identity is revealed only through the opt-in contact reveal flow (Stage 4).
3. **DB is the gate** — all rules enforced at DB level via triggers and RLS. Client-side validation is UX convenience only.
4. **Friendly errors** — `parseSupabaseError()` is used everywhere. Raw exception strings, internal URLs, and `errno` codes never reach the user.
5. **One account per person** — duplicate email and phone enforcement via DB unique constraints; flagged in `audit_logs`.
6. **Append-only audit log** — `audit_logs` must never be writable via UPDATE or DELETE by any role.

---

## Dependencies

| Dependency | Purpose | Stage introduced |
|---|---|---|
| `supabase_flutter` | Auth, DB, Realtime, Storage | 1 ✅ |
| `flutter_bloc` | State management | 1 ✅ |
| `go_router` | Navigation + auth guards | 1 ✅ |
| `injectable` + `get_it` | Dependency injection | 1 ✅ |
| `freezed` + `json_serializable` | Code generation | 1 ✅ |
| `hive_flutter` | UI-layer cache | 1 ✅ |
| `intl` | Date/number formatting | 1 ✅ |
| `fl_chart` | Analytics charts | 3 ⬜ |
| `firebase_crashlytics` or Sentry | Crash reporting | 6 ⬜ |
| Africa's Talking or Twilio SDK | SMS | 5 ⬜ |

---

*Nipanze Platforms Limited · contact@nipanze.ug · nipanze.ug*
*Made with ❤️ for financial inclusion in Uganda*