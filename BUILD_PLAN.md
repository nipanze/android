# BUILD_PLAN.md — Nipanze

> **Flutter + Supabase** · Digital loan listing marketplace for Uganda and emerging economies
> Last updated: March 2026 · Schema v5.0 · Scaffold v1.0

---

## Stage Map

| Stage | Title | Status |
|---|---|---|
| 1 | Foundation | ✅ Complete |
| 2 | Core Marketplace | ✅ Complete |
| 3 | Polish & Supporting Features | 🔄 In Progress |
| 3.5 | Cloud Migration & Auth Hardening | ⬜ Planned |
| 4 | Negotiator Module & Contract Drafting | ⬜ Planned |
| 5 | Admin, Compliance & Credit Score Automation | ⬜ Planned |
| 6 | Launch & Growth | ⬜ Planned |

---

## Stage 1 — Foundation ✅ Complete

- [x] Project bootstrap, package name `ug.nipanze.app`
- [x] All core dependencies including `image_picker`
- [x] `--dart-define` build variables; no hardcoded keys
- [x] `core/errors/app_exception.dart` — full v5.0 trigger error codes
- [x] GetIt + Injectable DI — all singletons registered
- [x] `supabase/config.toml`, schema v5.0 in `sql/`
- [x] Light/dark theme — DM Sans + DM Mono, brand colours
- [x] GoRouter — full route table, auth guard, `GoRouterRefreshStream`
- [x] 5-tab bottom nav: Markets · Watchlist · Request · Positions · Account
- [x] `AuthRepository` + `AuthBloc` — full event/state set
- [x] Login, Register, VerifyEmail, ResetPassword pages
- [x] 8 unit tests passing

---

## Stage 2 — Core Marketplace ✅ Complete

- [x] `MarketplaceRepository` — `v_loan_listings`, filters, `placeBid`, `withdrawBid`, `acceptBid`, Realtime streams
- [x] `MarketplaceCubit` — live feed with Realtime refresh
- [x] `MarketplacePage` — filter pills, `ListingCard`, skeleton, live dot
- [x] `LoanDetailPage` — live Realtime order book (`watchOrderBook`), glow flash on new bid, listing stream
- [x] Subscription gate modal — plan cards (Borrower / Lender / Pro), upgrade navigates to Account
- [x] `KycVerification` model + `KycRepository` — Storage uploads, `submitForReview`
- [x] `KycCubit` — per-doc upload state, error preserves data
- [x] `KycPage` — camera/gallery picker, 3 doc tiles, submit gating, rejection reason banner
- [x] Request tab → direct to `ListingCreatePage` (no intermediate page)
- [x] `ListingCreatePage` — 2-step form, purpose dropdown + Other, district dropdown, draft save, review screen
- [x] `SystemSettingsRepository` — fetches public limits from DB; cached singleton; form validators use live values
- [x] `MyListingsPage` + `MyListingsCubit` + `ListingRepository` — real data, Realtime, cancel with confirm
- [x] Contracted listings banner redirects to Positions tab
- [x] `WatchlistButton` on detail page — toggles DB save, filled star when saved

---

## Stage 3 — Polish & Supporting Features 🔄 In Progress

### 3.1 Watchlist ✅ Complete
- [x] `WatchlistItem` model
- [x] `WatchlistRepository` — `getWatchlist`, `addToWatchlist`, `removeFromWatchlist`, `isWatching`, `watchWatchlist` Realtime stream
- [x] `WatchlistCubit` — optimistic remove with rollback
- [x] `WatchlistCard` — urgency border (red 6h / amber 24h), bid count, best rate, View & bid, remove
- [x] `WatchlistPage` — grouped sections (Closing soon / Active / Ended), features card on empty state, skeleton
- [x] "Save to watchlist" on `LoanDetailPage` writes to DB; toggles star icon

### 3.2 Positions ✅ Complete
- [x] `LenderBid` model from `v_lender_bids`
- [x] `PositionsRepository` — `getMyBids`, `withdrawBid`, `getMyContracts`, `getPortfolioSummary`, `watchMyBids` Realtime
- [x] `PositionsCubit` — loads bids + contracts + portfolio; Realtime bid updates; optimistic withdraw
- [x] `LenderBidCard` — status badge, View listing, Withdraw button with confirm dialog
- [x] `ContractCard` — amount, rate, indicative monthly, role (borrower/lender), status badge, taps to ContractDetailPage
- [x] `PositionsPage` — 3 tabs:
  - **Borrower** — `MyListingsPage` embedded (active/closed requests)
  - **Lender** — bids grouped Pending / Accepted / History; withdraw button live
  - **Contracts** — Active / Other; non-custodial notice
- [x] Portfolio summary drives subtitle (active bids count, active contracts count)
- [x] `RepTierBadge` in positions header

### 3.3 Notifications ⬜ Next
- [ ] `NotificationRepository` — reads `notifications` table, marks as read
- [ ] `NotificationCubit` — unread count, Realtime subscription
- [ ] `NotificationsPage` — chronological, grouped by type, deep-link navigation
- [ ] Unread badge on bottom nav
- [ ] In-app alerts: bid received, bid accepted/rejected, KYC status, closing-soon

### 3.4 Profile & Account ⬜ Next
- [ ] `ProfilePage` — editable name, district, employment; live fetch from `profiles`
- [ ] `AccountPage` — live subscription data; upgrade flow (off-platform)
- [ ] `ThemeMode` persisted via `SharedPreferences`

### 3.5 Error & Empty States ⬜ Next
- [ ] `OfflineBanner` — shown when Supabase connectivity lost
- [ ] Loading skeletons on notifications page

### Stage 3 Exit Criteria
- [ ] All 5 nav tabs functional with real data
- [ ] Watchlist alerts fire in-app for watched listings with new bids
- [ ] Positions accurately reflects borrower + lender activity
- [ ] Bid withdrawal works end to end
- [ ] App stable on Android APK (arm64), web, and Linux desktop

---

## Stage 3.5 — Cloud Migration & Auth Hardening ⬜ Planned

- [ ] Apply schema v5.0 to cloud project
- [ ] Create storage buckets in cloud
- [ ] RLS audit — no row reachable by wrong user
- [ ] Confirm `v_loan_listings` never exposes `borrower_id`
- [ ] Verify refresh token rotation chain
- [ ] Release APK tested on physical Android device

---

## Stage 4 — Negotiator Module & Contract Drafting ⬜ Planned

- [ ] `NegotiatorRepository` — fetch assigned negotiator
- [ ] Contact reveal flow — blurred → confirm → animated unblur; irreversible
- [ ] `ContractDetailPage` fully wired — indicative schedule, participant-reported status
- [ ] Contract status lifecycle: draft → in_execution → completed / defaulted
- [ ] Participant self-report on `repayment_schedules.reported_status`
- [ ] `NegotiatorAssessmentForm` via admin panel

---

## Stage 5 — Admin, Compliance & Credit Score Automation ⬜ Planned

- [ ] `AdminDashboardPage` — live `v_loan_performance` KPIs + Realtime
- [ ] GoRouter admin guard on `/admin`
- [ ] `KycReviewPage` — approve/reject with document viewer
- [ ] `sp_calculate_reputation_score` triggered on deal events
- [ ] PDF contract export via Supabase Edge Function
- [ ] SMS notifications via Africa's Talking
- [ ] `system_settings` editable from admin panel

---

## Stage 6 — Launch & Growth ⬜ Planned

- [ ] Play Store AAB + App Store IPA
- [ ] Privacy policy + terms of service
- [ ] 3-screen onboarding carousel
- [ ] Role selection at registration
- [ ] Crash reporting (Firebase Crashlytics or Sentry)
- [ ] Referral programme (`referrals` table in schema v5.0)
- [ ] Pro Plan analytics API

---

## Key Flows — Current Status

| Flow | Status |
|---|---|
| Register → verify email → login | ✅ |
| 5-tab nav, Request in centre | ✅ |
| Browse marketplace with filters | ✅ |
| Live feed Realtime refresh | ✅ |
| Live order book Realtime + flash | ✅ |
| Subscription gate modal | ✅ |
| Place / accept a bid | ✅ |
| Request tab → create form direct | ✅ |
| 2-step create form with draft save | ✅ |
| Form limits from DB (system_settings) | ✅ |
| KYC upload (camera/gallery, 3 docs) | ✅ |
| Save to watchlist (toggles star) | ✅ |
| Watchlist — real data, grouped, urgency | ✅ |
| Positions — borrower tab (MyListings) | ✅ |
| Positions — lender tab with withdraw | ✅ |
| Positions — contracts tab | ✅ |
| Bid withdrawal with confirm dialog | ✅ |
| Notifications | ❌ Stage 3 next |
| Profile/Account live data | ❌ Stage 3 next |
| OfflineBanner | ❌ Stage 3 next |
| Contact reveal flow | ⬜ Stage 4 |
| PDF contract download | ⬜ Stage 5 |
| Admin KYC review | ⬜ Stage 5 |

---

## Test Accounts (password: `Test1234!`)

| Email | Role | Best for |
|---|---|---|
| `david.mukasa@gmail.com` | Borrower | Listing + contracted position; Bronze tier |
| `invest@pearlcapital.ug` | Lender | Multiple active bids |
| `funds@victoriainvest.co.ug` | Lender | Bid accepted — contract viewable |
| `alice.namuli@gmail.com` | Borrower | KYC pending — test listing gate |
| `admin1@nipanze.ug` | Admin | Full admin access |

---

## Architecture Constraints

1. **No fund movement** — platform never initiates, processes, or records financial transactions
2. **Anonymity by default** — `borrower_id` never in marketplace queries; lenders shown as tokens
3. **DB is the gate** — triggers + RLS enforce all rules; client validation is UX only
4. **Friendly errors** — `parseSupabaseError()` everywhere; raw codes never reach the user
5. **Append-only audit log** — `audit_logs` never writable via UPDATE or DELETE

---

*Nipanze Platforms Limited · contact@nipanze.ug · nipanze.ug*
*Made with ❤️ for financial inclusion in Uganda*