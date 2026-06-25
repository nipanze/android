# BUILD_PLAN.md — Nipanze

> **Flutter + Supabase** · Digital loan listing matchmaking marketplace for Uganda and emerging economies
> Last updated: March 2026 · Schema v4.0 · Seed v2.0

---

## Stage Map

| Stage | Title | Status |
|---|---|---|
| 1 | Foundation | ✅ Complete |
| 2 | Core Marketplace | 🔄 In Progress |
| 3 | Polish & Supporting Features | ⬜ Planned |
| 3.5 | Cloud Migration & Auth Hardening | ⬜ Planned |
| 4 | Contact Sharing | ⬜ Planned |
| 5 | Admin & Compliance | ⬜ Planned |
| 6 | Launch & Growth | ⬜ Planned |

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

## Stage 2 — Core Marketplace 🔄 In Progress

### 2.1 Marketplace Feed
- [ ] `MarketplaceRepository` — `v_loan_listings`, filters, Realtime stream
- [ ] `MarketplaceCubit` — live feed with Realtime refresh
- [ ] `MarketplacePage` — filter pills, `ListingCard`, skeleton, live dot
- [ ] `LoanDetailPage` — listing detail, income + repayment plan display, offers panel

### 2.2 Loan Requests (Borrower — Free)
- [ ] `ListingCreatePage` — 2-step form: loan details + income/repayment context
- [ ] Form fields: title, purpose, amount, duration, district, income source, preferred repayment plan, repayment amount per period, repayment timeline
- [ ] `SystemSettingsRepository` — fetches public limits from DB; cached singleton; form validators use live values
- [ ] `MyRequestsPage` + `MyRequestsCubit` + `RequestRepository` — real data, Realtime, cancel with confirm
- [ ] Contracted request banner redirects to Positions tab
- [ ] Request tab → direct to `ListingCreatePage` (no intermediate page)

### 2.3 Loan Offers (Lender — Subscription Required)
- [ ] `OfferRepository` — `makeOffer`, `withdrawOffer`, Realtime stream on offers for a listing
- [ ] `LoanDetailPage` — live Realtime offers panel, glow flash on new offer
- [ ] Subscription gate modal — plan cards (Free / Lender / Pro), upgrade navigates to Account
- [ ] `KycVerification` model + `KycRepository` — Storage uploads, `submitForReview`
- [ ] `KycCubit` — per-doc upload state, error preserves data
- [ ] `KycPage` — camera/gallery picker, 3 doc tiles, submit gating, rejection reason banner

### 2.4 Offer Acceptance
- [ ] `accept_offer` RPC called from borrower side on `LoanDetailPage`
- [ ] Rejected offers notified to losing lenders
- [ ] Listing moves to `contracted` status; removed from live feed
- [ ] `WatchlistButton` on detail page — toggles DB save, filled star when saved

### Stage 2 Exit Criteria
- [ ] Borrower can post a free request and receive offers
- [ ] Lender with active subscription can browse and make offers
- [ ] Borrower can accept one offer; all others auto-rejected
- [ ] Live feed and offers panel refresh via Realtime
- [ ] Subscription gate blocks offer placement for free-plan users
- [ ] App stable on Android APK (arm64), web, and Linux desktop

---

## Stage 3 — Polish & Supporting Features ⬜ Planned

### 3.1 Watchlist
- [ ] `WatchlistItem` model
- [ ] `WatchlistRepository` — `getWatchlist`, `addToWatchlist`, `removeFromWatchlist`, `isWatching`, `watchWatchlist` Realtime stream
- [ ] `WatchlistCubit` — optimistic remove with rollback
- [ ] `WatchlistCard` — urgency border (red 6h / amber 24h), offer count, View listing, remove
- [ ] `WatchlistPage` — grouped sections (Closing soon / Active / Ended), features card on empty state, skeleton
- [ ] "Save to watchlist" on `LoanDetailPage` writes to DB; toggles star icon

### 3.2 Positions
- [ ] `LenderOffer` model from `v_lender_offers`
- [ ] `PositionsRepository` — `getMyOffers`, `withdrawOffer`, `getMyRequests`, `watchMyOffers` Realtime
- [ ] `PositionsCubit` — loads requests + offers; Realtime offer updates; optimistic withdraw
- [ ] `LenderOfferCard` — status badge, View listing, Withdraw button with confirm dialog
- [ ] `PositionsPage` — 2 tabs:
  - **My Requests** — borrower's active, contracted, and expired requests
  - **My Offers** — lender's offers grouped Pending / Accepted / History; withdraw button live
- [ ] Portfolio summary drives subtitle (active offers count, active requests count)

### 3.3 Notifications
- [ ] `NotificationRepository` — reads `notifications` table, marks as read
- [ ] `NotificationCubit` — unread count, Realtime subscription
- [ ] `NotificationsPage` — chronological, grouped by type, deep-link navigation
- [ ] Unread badge on bottom nav
- [ ] In-app alerts: offer received, offer accepted/rejected, KYC status, closing-soon

### 3.4 Profile & Account
- [ ] `ProfilePage` — editable name, district, employment; live fetch from `profiles`
- [ ] `AccountPage` — live subscription data; upgrade flow (off-platform)
- [ ] `ThemeMode` persisted via `SharedPreferences`

### 3.5 Error & Empty States
- [ ] `OfflineBanner` — shown when Supabase connectivity lost
- [ ] Loading skeletons on notifications page

### Stage 3 Exit Criteria
- [ ] All 5 nav tabs functional with real data
- [ ] Watchlist alerts fire in-app for watched listings with new offers
- [ ] Positions accurately reflects borrower requests and lender offers
- [ ] Offer withdrawal works end to end
- [ ] App stable on Android APK (arm64), web, and Linux desktop

---

## Stage 3.5 — Cloud Migration & Auth Hardening ⬜ Planned

- [ ] Apply schema v4.0 to cloud project
- [ ] Apply seed v2.0 to cloud project
- [ ] Create storage buckets in cloud (`verification-documents`)
- [ ] RLS audit — no row reachable by wrong user
- [ ] Confirm `v_loan_listings` never exposes `borrower_id`, phone, or email
- [ ] Confirm `v_lender_offers` never exposes borrower contact details before reveal
- [ ] Verify refresh token rotation chain
- [ ] Release APK tested on physical Android device

---

## Stage 4 — Contact Sharing ⬜ Planned

- [ ] `ContactRevealRepository` — fetch reveal record, call `reveal_contact` RPC
- [ ] `ContactRevealCubit` — reveal state, error handling
- [ ] Contact reveal flow on Positions → My Requests → accepted request:
  - Blurred contact card shown with "Reveal contact details" button
  - Confirm dialog: irreversible action warning
  - Animated unblur on confirm
  - Reveals legal name, phone, and email of both parties
- [ ] `reveal_contact` RPC called client-side; enforced at API layer, not just UI
- [ ] Contact card shown to lender after borrower triggers reveal
- [ ] Notification sent to both parties on reveal (`contact_revealed` type)
- [ ] Profile improvements — verification badge shown on borrower listing card

### Stage 4 Exit Criteria
- [ ] Borrower can trigger contact reveal from accepted request
- [ ] Both borrower and lender see each other's legal name, phone, and email post-reveal
- [ ] Reveal is irreversible; second trigger returns an error gracefully
- [ ] Audit log entry written for every reveal event
- [ ] Contact details never accessible before reveal via any API query

---

## Stage 5 — Admin & Compliance ⬜ Planned

- [ ] `AdminDashboardPage` — live `v_marketplace_activity` KPIs + Realtime
- [ ] GoRouter admin guard on `/admin`
- [ ] `KycReviewPage` — approve/reject with document viewer
- [ ] SMS notifications via Africa's Talking
- [ ] `system_settings` editable from admin panel
- [ ] Audit log viewer — filterable by event type, user, date range
- [ ] User management — account status, subscription, KYC status

### Stage 5 Exit Criteria
- [ ] Admin can review and approve/reject KYC submissions
- [ ] `v_marketplace_activity` drives live admin KPI dashboard
- [ ] All sensitive actions logged to `audit_logs` (append-only enforced)
- [ ] SMS alerts fire on offer accepted and contact revealed events

---

## Stage 6 — Launch & Growth ⬜ Planned

- [ ] Play Store AAB + App Store IPA
- [ ] Privacy policy + terms of service
- [ ] 3-screen onboarding carousel
- [ ] Role selection at registration (borrow / lend / both)
- [ ] Crash reporting (Firebase Crashlytics or Sentry)
- [ ] Referral programme (`referrals` table in schema v4.0)
- [ ] Lender subscription growth — in-app upgrade prompts

---

## Key Flows — Current Status

| Flow | Status |
|---|---|
| Register → verify email → login | ✅ |
| 5-tab nav, Request in centre | ✅ |
| Browse marketplace with filters | ❌ Stage 2 |
| Live feed Realtime refresh | ❌ Stage 2 |
| Post a loan request (free) | ❌ Stage 2 |
| Form limits from DB (system_settings) | ❌ Stage 2 |
| Browse and make an offer (lender subscription) | ❌ Stage 2 |
| Subscription gate modal | ❌ Stage 2 |
| Borrower accepts an offer | ❌ Stage 2 |
| Losing offers auto-rejected | ❌ Stage 2 |
| Live offers panel Realtime + flash | ❌ Stage 2 |
| KYC upload (camera/gallery, 3 docs) | ❌ Stage 2 |
| Save to watchlist (toggles star) | ❌ Stage 3 |
| Watchlist — real data, grouped, urgency | ❌ Stage 3 |
| Positions — My Requests tab | ❌ Stage 3 |
| Positions — My Offers tab with withdraw | ❌ Stage 3 |
| Offer withdrawal with confirm dialog | ❌ Stage 3 |
| Notifications | ❌ Stage 3 |
| Profile/Account live data | ❌ Stage 3 |
| OfflineBanner | ❌ Stage 3 |
| Contact reveal flow (blurred → unblur) | ⬜ Stage 4 |
| Admin KYC review | ⬜ Stage 5 |
| Admin KPI dashboard | ⬜ Stage 5 |
| SMS alerts | ⬜ Stage 5 |

---

## Test Accounts (password: `Test1234!`)

| Email | Role | Subscription | Best for testing |
|---|---|---|---|
| `david.mukasa@gmail.com` | Borrower | Free | Contracted request; contact reveal triggered |
| `sarah.namukasa@yahoo.com` | Borrower | Free | Contracted request; contact reveal pending |
| `james.okello@outlook.com` | Both | Pro | Active request with two pending offers; can also make offers |
| `maria.nakato@gmail.com` | Borrower | Free | Active request, one pending offer |
| `robert.ssemwanga@gmail.com` | Both | Lender | Closing-soon request; pending offer on another listing |
| `invest@pearlcapital.ug` | Lender | Pro | Offer accepted on David's request; contact revealed |
| `funds@victoriainvest.co.ug` | Lender | Pro | Offer accepted on Sarah's request; contact reveal pending |
| `lending@equatorfinance.ug` | Lender | Lender | Pending offer on James's request |
| `info@greenleafagro.co.ug` | Lender | Lender | Pending offer on Maria's request; expired offer on Charles's |
| `contact@kampalatech.ug` | Lender | Lender | Pending offer on Frank's request |
| `alice.namuli@gmail.com` | Borrower | Free | KYC pending — test KYC badge; `account_status = pending_verification` |
| `admin1@nipanze.ug` | Admin | Free | Full admin dashboard access |
| `test.user@gmail.com` | Borrower | Free | No prior activity — test onboarding gates |

---

## Architecture Constraints

1. **No fund movement** — platform never initiates, processes, records, or tracks financial transactions
2. **Anonymity by default** — `borrower_id` never in marketplace queries; lender identity hidden until offer is accepted and contact is revealed
3. **DB is the gate** — triggers + RLS enforce all rules; client validation is UX only
4. **Controlled contact sharing** — `reveal_contact` RPC enforced at API layer; contact details never accessible before reveal via any query
5. **Friendly errors** — `parseSupabaseError()` everywhere; raw trigger codes never reach the user
6. **Append-only audit log** — `audit_logs` never writable via UPDATE or DELETE

---

*Nipanze Platforms Limited · contact@nipanze.ug · nipanze.ug*
*Made with ❤️ for financial inclusion in Uganda*