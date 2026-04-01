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
| 2 | Core Marketplace | ✅ Complete | Live feed, order book, bidding |
| 3 | Polish & Supporting Features | 🔄 Next | Watchlist, positions, notifications |
| 3.5 | Cloud Migration & Auth Hardening | ⬜ Planned | Supabase Cloud, RLS audit, token rotation |
| 4 | Negotiator Module & Contract Drafting | ⬜ Planned | Post-acceptance flow, draft contracts |
| 5 | Admin, Compliance & Credit Score Automation | ⬜ Planned | Admin dashboard, KYC automation, reputation engine |
| 6 | Launch & Growth | ⬜ Planned | Play Store, App Store, SMS, marketing |

---

## Stage 1 — Foundation ✅ Complete

### 1.1 Project Bootstrap
- [x] Package name `ug.nipanze.app`
- [x] Core dependencies: `supabase_flutter`, `flutter_bloc`, `go_router`, `injectable`, `get_it`, `freezed`, `json_serializable`, `image_picker`
- [x] `--dart-define` build variables: `SUPABASE_URL`, `SUPABASE_ANON_KEY`
- [x] `core/config/supabase_config.dart` — reads dart-define at build time; no hardcoded keys
- [x] `core/errors/app_exception.dart` — typed exception hierarchy; `parseSupabaseError()` covering all v5.0 trigger codes
- [x] `core/di/injection.dart` + `injection.config.dart` — GetIt bootstrap; all singletons registered

### 1.2 Supabase Local Setup
- [x] `supabase/config.toml` in place
- [x] Schema v5.0 SQL in `sql/` with v4.0 → v5.0 diff documented in `sql/README.md`
- [x] Storage buckets documented: `kyc-documents`, `contracts`
- [ ] `sql/seed.sql` — not yet written

### 1.3 Theme
- [x] `core/theme/app_theme.dart` — light and dark variants, full Material 3
- [x] Brand colours: accent `#3B82F6`, success `#10B981`, warning `#F59E0B`, danger `#EF4444`, purple `#8B5CF6`
- [x] Typography: DM Sans (body), DM Mono (numeric/code values)
- [ ] `ThemeMode` persisted via `SharedPreferences` — not wired yet

### 1.4 Navigation
- [x] `core/router/app_router.dart` — GoRouter with all named routes
- [x] Auth guard — unauthenticated users redirected to `/auth/login`
- [x] `GoRouterRefreshStream` — router rebuilds on every AuthBloc state change
- [x] Full route table declared and working
- [x] `MainScaffold` — 5-tab bottom nav: Markets · Watchlist · Request (centre) · Positions · Account
- [x] Request tab points directly to create form — no intermediate listing page
- [ ] `OfflineBanner` widget — Stage 3

### 1.5 Auth Feature
- [x] `AuthRepository` — signIn, signUp, signOut, resetPassword, currentUser, authStateChanges stream
- [x] `AuthBloc` — full event/state set
- [x] `LoginPage`, `RegisterPage`, `VerifyEmailPage`, `ResetPasswordPage` — all working
- [x] Auth state listener in `main.dart` — router rebuilds on session change
- [x] `AuthState` name clash with Supabase resolved via `hide AuthState`

### 1.6 Dashboard
- [x] `DashboardPage` — welcome + quick-action grid
- [ ] Live `v_user_portfolio` query — uses auth state only; full query in Stage 3

### Stage 1 Exit Criteria ✅
- [x] Register → verify email → login → dashboard flow works end to end
- [x] Logout clears session; router redirects to login
- [x] All routes declared and navigable
- [x] 8 unit tests passing in `test/features/auth/auth_bloc_test.dart`

---

## Stage 2 — Core Marketplace ✅ Complete

### 2.1 Marketplace Feed ✅
- [x] `MarketplaceRepository` — queries `v_loan_listings`; filter params (risk, closing soon, high yield)
- [x] `MarketplaceCubit` — Loading / Loaded / Error states
- [x] `MarketplacePage` — filter pills (All · Low risk · High yield · Closing soon)
- [x] `ListingCard` — title, district, duration, UGX amount (DM Mono), risk badge, bid count, best rate, bid-activity bar, time remaining; closing-soon colour changes at 6h and 24h
- [x] `RiskBadge` widget — Low / Med / High
- [x] `ListingCardSkeleton` — animated skeleton for loading state
- [x] Supabase Realtime: `watchListings()` stream wired in cubit — feed refreshes on `loan_requests` events
- [x] `LiveDot` animated widget on feed header

### 2.2 Loan Detail & Order Book ✅
- [x] `LoanDetailPage` — amount header, stats grid, non-custodial notice
- [x] **Live Realtime order book** — `watchOrderBook()` stream wired; fires on every `loan_bids` change for this listing
- [x] **Listing Realtime** — `watchListings()` stream updates header stats (bid count, best rate, time left) in real time
- [x] Green glow flash on order book when new bid arrives
- [x] Both subscriptions cancelled in `dispose()` — no memory leaks
- [x] Order book — anonymous lender tokens, sorted by best rate, best row highlighted green
- [x] "Accept best bid" CTA — calls `accept_bid` RPC, navigates to contract on success
- [x] "Place bid" CTA — opens `_PlaceBidSheet`
- [x] "Save to watchlist" CTA — snackbar only; DB write in Stage 3
- [x] **Subscription gate modal** — bottom sheet with plan cards (Borrower / Lender / Pro); required plan highlighted; "Upgrade" navigates to Account
- [x] Unauthenticated users redirected to login on bid attempt

### 2.3 KYC Feature ✅
- [x] `KycVerification` model — all fields, computed properties (`allDocsUploaded`, `isApproved` etc.)
- [x] `KycRepository` — `getMyKyc()`, `uploadDocument()` to `kyc-documents` bucket, `saveDocumentUrl()`, `submitForReview()`
- [x] `KycCubit` — Loading / Loaded / Uploading(docType) / Submitting / Error states; preserves data on error
- [x] `KycPage` — status banner, per-document upload tiles with camera/gallery picker, submit button (enabled only when all 3 docs uploaded), rejection reason banner, approved expiry display
- [x] `_SourcePicker` bottom sheet — camera or photo library per document
- [x] DB trigger `trg_fn_require_kyc_for_loan` enforced server-side
- [x] `KycRequiredException` + `KycExpiredException` parsed in `parseSupabaseError()`

### 2.4 Listing Creation — Request Tab ✅
- [x] **Request tab** in centre of bottom nav — goes directly to create form
- [x] No back arrow on step 1 (form is the entry point); back arrow on step 2 returns to step 1
- [x] `ListingCreatePage` — 2-step form: details → review & publish
- [x] Step 1: amount, duration, max interest rate, purpose dropdown (14 options + Other free-text), district dropdown (14 Uganda districts), optional description (500 chars)
- [x] Step 2: full review card with all fields; non-custodial + risk grading notice
- [x] "Publish to marketplace" and "Save as draft" on step 2
- [x] KYC and borrower subscription gates checked before submit
- [x] DB trigger chain enforces all rules server-side
- [x] `MyListingsPage` built and ready — embedded in Positions → As borrower in Stage 3
- [x] `MyListingsCubit` + `ListingRepository` — real Supabase data, Realtime stream, cancel with confirm dialog
- [x] Contracted listings redirected to Positions tab with tap-able banner
- [x] **`system_settings` runtime fetch** — `SystemSettingsRepository` fetches public limits from DB on form open; cached as singleton; falls back to defaults on error; form validators and info banner use live values

### 2.5 Bidding ✅
- [x] `placeBid()` in `MarketplaceRepository` — inserts into `loan_bids`
- [x] `withdrawBid()` in `MarketplaceRepository` — method exists; UI exposed in Stage 3 Positions
- [x] Client-side ceiling rate validation in `_PlaceBidSheet`
- [x] Subscription gate modal shown before bid sheet opens

### 2.6 Bid Acceptance ✅
- [x] `accept_bid` RPC called on "Accept best bid" tap
- [x] Navigates to `/contracts/:contractId` on success
- [x] Error messages from RPC parsed and shown to user
- [x] Listing stream updates feed in real time post-acceptance

### Stage 2 Exit Criteria ✅
- [x] End-to-end: create listing → go live → receive bids → live order book updates → accept bid → listing shows as contracted
- [x] Subscription gates: unsubscribed users shown plan-selector modal, not a raw error
- [x] KYC gate enforced at DB level; `alice.namuli@gmail.com` cannot create a listing
- [x] System limits read from DB at runtime — no hardcoded values in validators

---

## Stage 3 — Polish & Supporting Features 🔄 Next

**Goal:** The app is complete enough for beta users. Watchlist, positions, notifications, and profile are functional. UI is polished. Error states and empty states are handled everywhere.

### 3.1 Watchlist
- [ ] `WatchlistRepository` — `addToWatchlist`, `removeFromWatchlist`, reads `watchlist` table
- [ ] `WatchlistCubit` — syncs on mount; real-time update on bid activity for watched listings
- [ ] `WatchlistPage` — real listings with bid activity, closing alerts, remove action
- [ ] "Save to watchlist" on `LoanDetailPage` writes to DB (currently snackbar only)
- [ ] In-app notification on new bid for watched listing
- [ ] Empty state with browse marketplace CTA

### 3.2 Positions
- [ ] `PositionsPage` — 3-tab layout with real data:
  - **As borrower** — `MyListingsPage` embedded here; active/closed requests with bid count, cancel action
  - **As lender** — bids from `v_lender_bids`; pending / accepted / withdrawn; withdraw button wired
  - **Contracts** — contracted positions for both roles; links to `ContractDetailPage`
- [ ] `v_user_portfolio` drives header stats (active listings, active bids)

### 3.3 Notifications
- [ ] `NotificationRepository` — reads `notifications` table; marks as read
- [ ] `NotificationCubit` — unread count; real-time subscription
- [ ] `NotificationsPage` — chronological, grouped by type, tap deep-links to relevant screen
- [ ] In-app alerts: bid received, bid accepted/rejected, negotiator assigned (stub), KYC status change, closing-soon 24h/6h
- [ ] Unread badge on bottom nav

### 3.4 Profile & Account
- [ ] `ProfilePage` — editable name, district, employment; live fetch from `profiles`
- [ ] `AccountPage` — live subscription data from `subscriptions`; upgrade flow (off-platform payment)
- [ ] `ThemeMode` persisted via `SharedPreferences`

### 3.5 Error & Empty States
- [ ] `OfflineBanner` widget — shown when Supabase connectivity is lost
- [ ] Loading skeletons on watchlist, positions, notifications

### Stage 3 Exit Criteria
- [ ] All 5 nav tabs functional with real data
- [ ] Watchlist alerts fire in-app for watched listings with new bids
- [ ] Positions view reflects borrower + lender activity
- [ ] Bid withdrawal button live in lender positions tab
- [ ] App stable on Android APK (arm64), web, and Linux desktop

---

## Stage 3.5 — Cloud Migration & Auth Hardening ⬜ Planned

- [ ] Apply schema v5.0 to cloud project
- [ ] Create storage buckets in cloud: `kyc-documents`, `contracts`
- [ ] `run_cloud.sh` with cloud credentials
- [ ] RLS audit — no row reachable by wrong user
- [ ] Confirm `v_loan_listings` never exposes `borrower_id`
- [ ] Verify lender tokens never reveal identity
- [ ] Verify refresh token rotation chain
- [ ] Release APK tested on physical Android device

---

## Stage 4 — Negotiator Module & Contract Drafting ⬜ Planned

- [ ] `NegotiatorRepository` — fetch assigned negotiator for a contract
- [ ] Contact reveal flow — blurred → confirm → animated unblur; irreversible
- [ ] `ContractDetailPage` fully wired with live data (indicative schedule, participant-reported status)
- [ ] Anonymised placeholders until reveal
- [ ] Contract status lifecycle: draft → in_execution → completed / defaulted
- [ ] Participant self-report on `repayment_schedules.reported_status`
- [ ] `NegotiatorAssessmentForm` via admin panel

### Stage 4 Exit Criteria
- [ ] Both matched parties see draft contract in Positions → Contracts
- [ ] Reveal flow works: blurred → confirm → animated unblur
- [ ] `funds@victoriainvest.co.ug` and `lending@equatorfinance.ug` show viewable contracts

---

## Stage 5 — Admin, Compliance & Credit Score Automation ⬜ Planned

- [ ] `AdminDashboardPage` fully wired with live `v_loan_performance` data + Realtime KPIs
- [ ] GoRouter admin guard on `/admin`
- [ ] `KycReviewPage` — approve/reject with document viewer from `kyc-documents` bucket
- [ ] `sp_calculate_reputation_score` triggered from Flutter on deal events
- [ ] PDF contract export via Supabase Edge Function; "Download" button active in `ContractDetailPage`
- [ ] SMS notifications via Africa's Talking Edge Function
- [ ] `system_settings` editable from admin panel; `SystemSettingsRepository.invalidate()` called after save

### Stage 5 Exit Criteria
- [ ] Admin can approve/reject KYC in-app
- [ ] Reputation scores recalculate automatically on deal completion
- [ ] PDF downloadable for contracted deals
- [ ] SMS fires on bid acceptance (Africa's Talking sandbox)

---

## Stage 6 — Launch & Growth ⬜ Planned

- [ ] Play Store AAB + App Store IPA
- [ ] Privacy policy at `nipanze.ug/privacy`; terms at `nipanze.ug/terms`
- [ ] 3-screen onboarding carousel (marketplace concept, anonymity, subscription model)
- [ ] Role selection at registration (Borrower / Lender / Both)
- [ ] Crash reporting: Firebase Crashlytics or Sentry
- [ ] Referral programme — `referrals` table already in schema v5.0
- [ ] Pro Plan analytics API — Supabase Edge Function, `api_keys` table, 1,000 req/day

### Stage 6 Exit Criteria
- [ ] App live on Play Store and App Store
- [ ] First 50 paying subscribers onboarded
- [ ] Production monitoring alerting correctly
- [ ] Pro API has at least one external consumer

---

## Test Accounts (password: `Test1234!`)

| Email | Role | Best for |
|---|---|---|
| `david.mukasa@gmail.com` | Borrower | Listing + contracted position; Bronze tier |
| `sarah.namukasa@yahoo.com` | Borrower | Contract draft pending |
| `james.okello@outlook.com` | Both | Borrower + lender flows |
| `maria.nakato@gmail.com` | Borrower | Active listing with 1 pending bid |
| `invest@pearlcapital.ug` | Lender | Multiple active bids |
| `funds@victoriainvest.co.ug` | Lender | Bid accepted — contract viewable |
| `lending@equatorfinance.ug` | Lender | Bid accepted — contract viewable |
| `alice.namuli@gmail.com` | Borrower | KYC pending — test listing gate |
| `admin1@nipanze.ug` | Admin | Full admin access |
| `test.user@gmail.com` | Borrower | No KYC, no profile |

---

## Key Flows — Current Status

| Flow | Status |
|---|---|
| Register → verify email → login | ✅ Working |
| 5-tab nav, Request in centre | ✅ Working |
| Browse marketplace feed with filters | ✅ Working |
| Live feed Realtime refresh | ✅ Working |
| View listing detail | ✅ Working |
| Live order book Realtime updates | ✅ Working |
| Order book flash on new bid | ✅ Working |
| Place a bid | ✅ Working |
| Subscription gate modal (plan cards) | ✅ Working |
| Accept a bid | ✅ Working |
| Request tab → create form direct | ✅ Working |
| Create listing — 2-step form | ✅ Working |
| Purpose dropdown + Other free-text | ✅ Working |
| Save as draft | ✅ Working (stub — real draft status Stage 3) |
| Form limits from DB (system_settings) | ✅ Working |
| KYC document upload (camera/gallery) | ✅ Working |
| KYC submit for review | ✅ Working |
| KYC gate blocks listing creation | ✅ Working (DB enforced) |
| My listings real data | ✅ Working |
| Contracted listings → Positions banner | ✅ Working |
| Cancel listing with confirm dialog | ✅ Working |
| Watchlist real data | ❌ Stub — Stage 3 |
| Positions real data | ❌ Stub — Stage 3 |
| Bid withdrawal UI | ❌ Stage 3 |
| Notifications | ❌ Stage 3 |
| Contact reveal flow | ⬜ Stage 4 |
| PDF contract download | ⬜ Stage 5 |
| Admin KYC review | ⬜ Stage 5 |

---

## Architecture Constraints (Non-Negotiable)

1. **No fund movement** — platform never initiates, processes, or records financial transactions
2. **Anonymity by default** — `borrower_id` never in marketplace queries; lenders shown as tokens
3. **DB is the gate** — triggers + RLS enforce all rules; client validation is UX only
4. **Friendly errors** — `parseSupabaseError()` everywhere; raw codes never reach the user
5. **Append-only audit log** — `audit_logs` never writable via UPDATE or DELETE

---

*Nipanze Platforms Limited · contact@nipanze.ug · nipanze.ug*
*Made with ❤️ for financial inclusion in Uganda*