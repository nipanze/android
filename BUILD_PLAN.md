# BUILD_PLAN.md — Nipanze

> **Flutter + Supabase** · Digital loan listing matchmaking marketplace for Uganda and emerging economies
> Last updated: March 2026 · Schema v4.0 · Seed v2.0

---

## Stage Map

| Stage | Title | Status |
|---|---|---|
| 1 | Foundation | ✅ Complete |
| 2 | Core Marketplace | ✅ Complete |
| 3 | Polish & Supporting Features | ✅ Complete |
| 3.5 | Cloud Migration & Auth Hardening | ✅ Complete |
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

## Stage 2 — Core Marketplace ✅ Complete

### 2.1 Marketplace Feed
- [x] `MarketplaceRepository` — `v_loan_listings`, filters, Realtime stream
- [x] `MarketplaceCubit` — live feed with Realtime refresh
- [x] `MarketplacePage` — filter pills, `ListingCard`, skeleton, live dot
- [x] `LoanDetailPage` — listing detail, income + repayment plan display, offers panel

### 2.2 Loan Requests (Borrower — Free)
- [x] `ListingCreatePage` — 2-step form: loan details + income/repayment context
- [x] Form fields: title, purpose, amount, duration, district, income source, preferred repayment plan, repayment amount per period, repayment timeline
- [x] `SystemSettingsRepository` — fetches public limits from DB; cached singleton; form validators use live values
- [x] `MyRequestsPage` + `MyRequestsCubit` + `RequestRepository` — real data, Realtime, cancel with confirm
- [x] Contracted request banner redirects to Positions tab
- [x] Request tab → direct to `ListingCreatePage` (no intermediate page)

### 2.3 Loan Offers (Lender — Subscription Required)
- [x] `OfferRepository` — `makeOffer`, `withdrawOffer`, Realtime stream on offers for a listing
- [x] `LoanDetailPage` — live Realtime offers panel, glow flash on new offer
- [x] Subscription gate modal — plan cards (Free / Lender / Pro), upgrade navigates to Account
- [x] `KycVerification` model + `KycRepository` — Storage uploads, `submitForReview`
- [x] `KycCubit` — per-doc upload state, error preserves data
- [x] `KycPage` — camera/gallery picker, 3 doc tiles, submit gating, rejection reason banner

### 2.4 Offer Acceptance
- [x] `accept_offer` RPC called from borrower side on `LoanDetailPage`
- [x] Rejected offers notified to losing lenders
- [x] Listing moves to `contracted` status; removed from live feed
- [x] `WatchlistButton` on detail page — toggles DB save, filled star when saved

### Stage 2 Exit Criteria
- [x] Borrower can post a free request and receive offers
- [x] Lender with active subscription can browse and make offers
- [x] Borrower can accept one offer; all others auto-rejected
- [x] Live feed and offers panel refresh via Realtime
- [x] Subscription gate blocks offer placement for free-plan users
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
  - **My Requests** — borrower's active, contracted, and expired requests
  - **My Offers** — lender's offers grouped Pending / Accepted / History; withdraw button live
- [x] Portfolio summary drives subtitle (active offers count, active requests count)

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
- [x] Positions accurately reflects borrower requests and lender offers
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
- [x] `v_loan_listings` — `borrower_id` NOT exposed ✅
- [x] `v_loan_listings` — `income_source` NOT exposed (stays in `loan_requests` table) ✅
- [x] `v_loan_listings` — `phone`, `email`, `full_name`, `national_id` NOT exposed ✅
- [x] `v_lender_offers` — `lender_phone`, `lender_email`, `lender_name` NOT exposed pre-reveal ✅
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
- [/] End-to-end borrower flow tested on cloud (web) — post request, browse, save watchlist
- [ ] End-to-end lender flow tested on cloud (web) — browse, make offer, withdraw offer
- [ ] KYC document upload verified (`verification-documents` bucket receives file)
- [ ] Release APK built (`flutter build apk --release --dart-define=...`)
- [ ] APK installed and tested on physical Android device (no crashes, logcat clean)

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
| Browse marketplace with filters | ✅ Stage 2 |
| Live feed Realtime refresh | ✅ Stage 2 |
| Post a loan request (free) | ✅ Stage 2 |
| Form limits from DB (system_settings) | ✅ Stage 2 |
| Browse and make an offer (lender subscription) | ✅ Stage 2 |
| Subscription gate modal | ✅ Stage 2 |
| Borrower accepts an offer | ✅ Stage 2 |
| Losing offers auto-rejected | ✅ Stage 2 |
| Live offers panel Realtime + flash | ✅ Stage 2 |
| KYC upload (camera/gallery, 3 docs) | ✅ Stage 2 |
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