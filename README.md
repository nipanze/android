# Nipanze — Flutter + Supabase

## A Non-Custodial Digital Lending Matchmaking Marketplace

> Nipanze is a peer-to-peer financial marketplace that connects borrowers and lenders through structured requests, lender offers, and controlled contact sharing — without a bank, custodian, or intermediary holding any funds.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Status: MVP](https://img.shields.io/badge/Status-MVP-blue.svg)
![Stack: Flutter + Supabase](https://img.shields.io/badge/Stack-Flutter%20%2B%20Supabase-purple.svg)

A cross-platform fintech app built with Flutter and Supabase, targeting Android, iOS, Web, and Desktop (Linux, Windows, macOS).

---

## Table of Contents

- [Overview](#overview)
- [Problem Statement](#problem-statement)
- [Solution](#solution)
- [Key Features](#key-features)
- [Business Model](#business-model)
- [Transparency & Controlled Contact](#transparency--controlled-contact)
- [How It Works](#how-it-works)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Screen / Route Map](#screen--route-map)
- [Database Schema](#database-schema)
- [Supabase Setup](#supabase-setup)
- [Getting Started](#getting-started)
- [Environment Configuration](#environment-configuration)
- [Key Packages](#key-packages)
- [Edge Functions](#edge-functions)
- [Testing](#testing)
- [Deployment](#deployment)
- [Security](#security)
- [Regulatory Compliance](#regulatory-compliance)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

---

## Overview

Nipanze is a **peer-to-peer financial marketplace** that connects people who need money with people willing to lend, all within a single unified account system.

Nipanze does **not** hold funds, accept deposits, issue loans, pool capital, guarantee repayment, track repayments, or act as a financial institution. It simply helps financial requests and offers meet through structured discovery, matching, and controlled connection.

Users operate from one account and can act as both borrower and lender. Borrowing is free, marketplace viewing is free, and making lending offers requires a subscription. Contact details remain hidden until an offer is accepted.

**Core Principle:** One marketplace. One account. Multiple financial opportunities.

---

## Problem Statement

In Uganda and similar emerging economies, access to affordable capital faces critical barriers:

- **Long bank procedures:** Formal approvals can take too long for urgent needs
- **Lack of collateral:** Many viable borrowers cannot meet traditional security requirements
- **Limited financial history:** Thin credit files exclude people with real repayment ability
- **High interest rates:** Borrowers lack flexible, competitive alternatives
- **Limited lender visibility:** Potential lenders struggle to find borrowers and assess repayment ability
- **Weak lending structure:** Informal lending lacks a reliable marketplace for discovery, offers, and connection

Many lending options still focus on collateral and institutional gatekeeping instead of giving borrowers a structured way to show income, intent, and repayment plans.

---

## Solution

Nipanze provides a simple marketplace structure where:

- Borrowers publish structured funding requests for free
- Every request includes loan details, source of income, loan purpose, and repayment plan
- Lenders browse listed requests for free
- Lenders subscribe when they want to make offers
- Borrowers review available offers and select the one that fits
- Contact details are revealed only after a borrower accepts an offer
- Both parties connect outside the platform
- The platform supports discovery, matching, and controlled contact sharing

**We are not a lender. We are a matchmaking marketplace.**

---

## Key Features

### For Borrowers

- **Free access** — post loan requests without paying to list
- **Structured requests** — explain amount, duration, repayment plan, income source, and purpose
- **Repayment visibility** — show lenders how the loan will be repaid
- **Flexible options** — receive and compare offers from multiple lenders
- **My Requests** — track borrowing activity and lender responses in one place
- **Controlled contact** — personal contact details stay hidden until an offer is accepted

### For Lenders

- **Free browsing** — review borrower requests before subscribing
- **Repayment context** — assess loan purpose, requested amount, duration, and repayment plan
- **My Offers** — manage lending activity using simple, human, trustworthy language
- **Custom terms** — make offers with your own amount and expectations
- **Borrower context** — use profile, purpose, and repayment-plan details to compare opportunities
- **Return potential** — lend directly to selected borrowers for profit

### Platform Features

- **Free borrower posting** — borrowers can create requests without a listing fee
- **Free lender browsing** — lenders can browse requests before subscribing
- **Subscription-gated offers** — making lending offers requires an active subscription
- **Single account, multiple roles** — each user can borrow and lend from one account
- **Marketplace main screen** — live feed of borrower requests with amount, purpose, profile, and repayment plan
- **Non-custodial architecture** — Nipanze never holds, pools, or moves user funds
- **Controlled contact sharing** — contact details are revealed only after acceptance
- **Compliance built-in** — append-only audit trail from day one

---

## Business Model

Nipanze generates revenue through lender subscriptions for making offers — not interest spreads.

| Revenue Stream | Description |
|---|---|
| Lender subscriptions | Paid access for lenders who want to make offers |

Nipanze does **not** earn interest margins, custody fees, lending spreads, or any fee tied to loan performance.

---

## Transparency & Controlled Contact

Nipanze is **transparent before matching and controlled by design**. Borrower requests show enough structured information for lenders to make informed decisions, while personal contact details remain protected until a borrower accepts an offer.

Contact details are revealed **only after an offer is accepted** — enforced at the API layer, not just the UI.

### Borrower Request Structure

Each borrower request must include:

- **Loan details:** amount needed, duration, and preferred repayment plan
- **Source of income:** salary, business income, side income, or other repayment source
- **Purpose of the loan:** what the money will be used for
- **Repayment plan:** amount payable per period and repayment timeline

Example: “I earn 800,000 UGX monthly and can repay 200,000 UGX per month.”

### Field Masking Rules

#### Borrower → Public Loan Listing (`v_loan_listings` view)

**Exposed:** `request_id`, `title`, `purpose`, `district`, `duration_months`, `requested_amount`, `preferred_repayment_plan`, `repayment_amount_per_period`, `repayment_timeline`, `number_of_offers`, `listed_at`, `expires_at`

**Masked before acceptance:** `borrower_id`, income source, employer/salary details, email, phone, full name, national ID, and private verification documents

#### Lender → Offers

**Exposed:** offer amount, proposed expectations or terms, timestamp

Offer amounts can be full or partial. For example, a UGX 9M request can receive one UGX 9M offer, a UGX 5M offer, and a UGX 3M offer from different lenders.

**Masked before acceptance:** lender name, email, phone, and private verification documents

#### Post-Acceptance Contact Sharing

Revealed only after the borrower accepts an offer: legal name, phone, and email.

### Platform Boundary

Nipanze helps participants discover each other and make informed matching decisions. It does not handle money, track repayments, guarantee repayment, or manage the relationship after contact details are revealed.

---

## How It Works

```
1. POST       → Borrower posts a structured loan request for free
2. BROWSE     → Lenders browse borrower requests for free
3. OFFER      → Lenders subscribe to make offers
4. REVIEW     → Borrower reviews available offers
5. ACCEPT     → Borrower selects one offer
6. REVEAL     → Contact details are revealed only after acceptance
7. CONNECT    → Parties proceed independently outside the platform
```

---

## Architecture

| Layer | Technology | Responsibility |
| --- | --- | --- |
| Frontend | Flutter 3.x + Dart | UI, state management, routing, local cache |
| State Management | BLoC + Cubit | Predictable unidirectional data flow |
| Navigation | GoRouter | Declarative routing with auth guards |
| DI Container | get_it + injectable | Service locator with code-gen |
| Auth | Supabase Auth | Email login, JWT, session management |
| Database | Supabase Postgres | Relational data, RLS, triggers, functions |
| Realtime | Supabase Realtime | WebSocket updates for marketplace requests and offers |
| Storage | Supabase Storage | Optional profile and verification documents |
| Functions | Supabase Edge Functions (Stage 5) | Server-side logic, PDF generation |

---

## Project Structure

```
lib/
├── main.dart                       # Supabase init, DI setup
├── core/
│   ├── theme/                      # AppTheme — DM Sans / DM Mono, dark/light
│   ├── router/                     # GoRouter, auth redirect guards, route constants
│   ├── config/                     # SupabaseConfig — reads --dart-define at build time
│   ├── constants/                  # Tables, Views, Rpcs, Channels, SettingKeys
│   ├── errors/                     # AppException hierarchy, parseSupabaseError()
│   └── di/                         # Injectable config, GetIt locator
├── features/
│   ├── auth/                       # Login, Register, Verify Email, Reset Password, Onboarding
│   ├── dashboard/                  # Home stub (redirects to marketplace post-login)
│   ├── marketplace/                # Live feed (v_loan_listings), filters, loan detail, offers
│   ├── watchlist/                  # Saved listings, closing alerts
│   ├── positions/                  # My Requests · My Offers
│   ├── account/                    # Subscription, profile, verification
│   ├── loans/                      # Create request, my requests
│   ├── offers/                     # My Offers page
│   ├── notifications/              # Notification centre, unread badge
│   ├── kyc/                        # Optional verification, status display
│   ├── profile/                    # User profile, edit
│   └── admin/                      # Verification review, user management, audit logs (admin only)
│       └── */
│           ├── data/               # DataSources (Supabase) + Models
│           ├── domain/             # Entities, UseCases, Repository interfaces
│           └── presentation/       # BLoC + Pages + Widgets
├── shared/
│   ├── models/                     # LoanListingModel, OfferModel, UserModel…
│   └── widgets/                    # MainScaffold, ProfileSummary, VerificationChip
sql/
│   ├── schema.sql                  # Full schema v4.0 — tables, triggers, RPCs, views
│   └── seed.sql                    # Seed data v1.0 — users, listings, and offers
supabase/
│   └── migrations/                 # Incremental migrations applied on top of schema.sql
assets/
    ├── fonts/                      # DM Sans (body) + DM Mono (numeric values)
    └── images/                     # Onboarding illustrations
```

---

## Screen / Route Map

| Route | Screen | Auth Required |
| --- | --- | --- |
| `/` | SplashPage | No |
| `/onboarding` | OnboardingPage | No |
| `/auth/login` | LoginPage | No |
| `/auth/register` | RegisterPage | No |
| `/auth/verify-email` | VerifyEmailPage | Yes (unverified) |
| `/auth/forgot-password` | ForgotPasswordPage | No |
| `/marketplace` | MarketplacePage (tab 1) | Yes |
| `/marketplace/:requestId` | LoanDetailPage + Offers | Yes |
| `/watchlist` | WatchlistPage (tab 2) | Yes |
| `/positions` | My Requests + My Offers | Yes |
| `/account` | AccountPage (tab 4) | Yes |
| `/loans/create` | LoanCreatePage | Yes (borrower) |
| `/loans/my-loans` | MyRequestsPage | Yes |
| `/offers` | MyOffersPage | Yes |
| `/notifications` | NotificationsPage | Yes |
| `/kyc` | KycPage | Yes |
| `/profile` | ProfilePage | Yes |
| `/admin` | AdminDashboardPage | Yes (admin role) |

---

## Database Schema

The full schema lives in `sql/schema.sql` (v4.0). It defines all tables, triggers, functions, views, indexes, and seed `system_settings` in a single deployable file. Apply with:

```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -f sql/schema.sql
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -f sql/seed.sql
```

### Tables (v4.0)

| Table | Purpose |
| --- | --- |
| `profiles` | Core user profile. Extends `auth.users` 1-to-1. Supports one account with borrower and lender activity. |
| `system_settings` | Platform config. Business limits read from here at runtime. |
| `subscriptions` | Lender offer access. Borrower posting and marketplace viewing remain free. |
| `kyc_verifications` | Optional verification and admin review. |
| `loan_requests` | Structured borrower funding requests with amount, duration, purpose, income source, and repayment plan. |
| `loan_offers` | Lender offers on borrower requests. Contact details stay hidden until acceptance. |
| `watchlist` | User-saved listings. |
| `contact_reveals` | Post-acceptance contact sharing. Logged in `audit_logs`. |
| `notifications` | In-app notification feed. |
| `audit_logs` | **Append-only** compliance trail. Never update or delete rows. |
| `refresh_tokens` | JWT refresh token store with rotation chain. |
| `referrals` | Referral programme tracking. |

### Key Functions and Triggers

| Name | Type | Purpose |
| --- | --- | --- |
| `handle_new_auth_user()` | Trigger fn | Syncs `auth.users` → `public.profiles` |
| `accept_offer(request_id, offer_id, borrower_id)` | RPC | Atomic offer acceptance + contact eligibility |
| `get_public_listing_offers(request_id)` | RPC | Anonymized public offer book for active listings |

### Key Views

| View | Purpose |
| --- | --- |
| `v_loan_listings` | Public marketplace listings with borrower contact details excluded |
| `v_user_marketplace_activity` | Dashboard — borrower requests and lender offers in one query |
| `v_lender_offers` | Lender offer activity |
| `v_marketplace_activity` | Marketplace request and offer KPIs |

---

## Supabase Setup

### 1. Local Development Stack

```bash
# Install Supabase CLI (Linux)
# https://supabase.com/docs/guides/cli/getting-started
# Docker Desktop must be running

supabase init
supabase start
# Outputs: Project URL, Auth Keys, Studio URL (http://127.0.0.1:54323)

# Apply schema and seed data
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -f sql/schema.sql
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -f sql/seed.sql
```

Studio at `http://127.0.0.1:54323` provides table browsing, auth user management, and storage inspection.

### 2. Auth Bridge Trigger

The `handle_new_auth_user()` function is defined in `sql/schema.sql` and runs automatically on every `auth.users` INSERT. It creates the corresponding `public.profiles` row for marketplace access.

### 3. Storage Buckets

Create one bucket in Storage → New bucket:

- `verification-documents` — private; user can upload optional ID documents to own folder only

### 4. Production Project

1. Go to [supabase.com](https://supabase.com) and create a project named `nipanze`
2. Note your Project URL and anon key from Settings → API
3. Apply schema: Settings → SQL Editor → paste `sql/schema.sql`
4. Apply seed (optional on production): same method

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Supabase CLI
- Docker Desktop (for local Supabase stack)
- `psql` — `sudo apt install postgresql-client` (Linux) or via Homebrew (macOS)

### Installation

```bash
git clone https://github.com/your-org/nipanze.git
cd nipanze

flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Local Development

```bash
# Terminal 1 — keep running during development
supabase start
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -f sql/schema.sql
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -f sql/seed.sql

# Terminal 2 — run app (use the convenience scripts)
./run_local.sh          # Chrome (web)
./run_linux.sh          # Linux desktop
flutter run -d android  # Android (emulator or device)
```

The run scripts source `.env.local` and inject Supabase credentials via `--dart-define` automatically.

### Resetting Local Data

```bash
supabase db reset
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -f sql/schema.sql
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -f sql/seed.sql
```

### Building for Production

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...

flutter build web --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

---

## Environment Configuration

Copy `.env.example` to `.env.local` and fill in values from `supabase start` output:

```bash
cp .env.example .env.local
```

```env
# .env.local — never commit this file
LOCAL_SUPABASE_URL=http://127.0.0.1:54321
LOCAL_ANON_KEY=sb_publishable_...
LOCAL_SERVICE_ROLE_KEY=sb_secret_...

# Production — fill in at Stage 3.5
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...
```

Credentials are injected via `--dart-define` at build time and read by `lib/core/config/supabase_config.dart`. The anon key is safe to bundle — RLS enforces access control at the database level.

---

## Key Packages

| Package | Purpose | Stage |
| --- | --- | --- |
| `supabase_flutter ^2.x` | Auth, database, Realtime, storage | 1 |
| `flutter_bloc ^8.x` | BLoC state management | 1 |
| `go_router ^14.x` | Declarative routing with auth guards | 1 |
| `get_it + injectable` | Dependency injection with code-gen | 1 |
| `google_fonts` | DM Sans + DM Mono typography | 1 |
| `flutter_secure_storage ^9.x` | Secure token storage | 1 |
| `hive_flutter ^1.x` | UI-layer cache only | 1 |
| `animate_do ^3.x` | FadeIn/SlideIn animations | 1 |
| `lottie ^3.x` | Loading and empty state animations | 2 |
| `shimmer ^3.x` | Skeleton loading screens | 2 |
| `percent_indicator ^4.x` | Request interest and offer coverage indicators | 2 |
| `fl_chart ^0.69.x` | Portfolio and analytics charts | 3 |
| `local_auth ^2.x` | Biometric login | 3 |
| `flutter_local_notifications ^17.x` | In-app notification banners | 3 |

---

## Edge Functions

Edge Functions (Deno TypeScript) wrap Postgres RPCs for server-side enforcement. Added in Stage 5.

```bash
supabase functions new accept-offer
supabase functions serve accept-offer --env-file .env.local   # local test
supabase functions deploy accept-offer                         # deploy
```

| Function | Purpose |
| --- | --- |
| `accept-offer` | Atomic offer acceptance with server enforcement |
| `make-offer` | Server-side subscription validation for lender offers |
| `reveal-contact` | Post-acceptance contact sharing |
| `send-sms` | Africa's Talking or Twilio SMS alerts |

---

## Testing

```bash
# Unit + widget tests (no local stack needed)
flutter test

# Single test file
flutter test test/features/auth/auth_bloc_test.dart

# Integration tests — Linux desktop only
supabase start
flutter test integration_test/integration_test.dart -d linux

# Coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Test Accounts

All accounts are pre-loaded by `sql/seed.sql` v1.0 with fixed UUIDs and `email_confirmed_at` set.
**Password for all accounts: `Test1234!`**

| Email | Role | State |
| --- | --- | --- |
| `david.mukasa@gmail.com` | Borrower | Verified, active listing |
| `sarah.namukasa@yahoo.com` | Borrower | Verified, offer accepted |
| `james.okello@outlook.com` | Both | Verified, borrower + lender flows |
| `maria.nakato@gmail.com` | Borrower | Active listing, 1 pending offer |
| `robert.ssemwanga@gmail.com` | Both | Offers submitted on two listings |
| `invest@pearlcapital.ug` | Lender | Multiple active offers |
| `funds@victoriainvest.co.ug` | Lender | Offer accepted — contact reveal available |
| `lending@equatorfinance.ug` | Lender | Offer accepted — contact reveal available |
| `info@greenleafagro.co.ug` | Lender | Pending offer |
| `contact@kampalatech.ug` | Lender | Pending offer |
| `alice.namuli@gmail.com` | Borrower | Optional ID verification pending |
| `admin1@nipanze.ug` | Admin | Full admin dashboard access |
| `test.user@gmail.com` | Borrower | No profile — test onboarding gates |

---

## Deployment

| Target | Available now | Command |
| --- | --- | --- |
| Android APK (sideload) | ✅ | `flutter build apk --release` |
| Web | ✅ | `flutter build web --release` |
| Linux desktop | ✅ | `flutter build linux --release` |
| Edge Functions | ✅ (free tier) | `supabase functions deploy` |
| DB Migrations | ✅ | `supabase db push` |
| Android Play Store | Stage 6 | `flutter build appbundle --release` |
| iOS App Store | Stage 6 | `flutter build ios --release` |

---

## Security

- **No fund custody** — Nipanze never holds, pools, or moves user money
- **RLS on all tables** — Postgres enforces access control, not just the application layer
- **JWT auth** — Supabase issues short-lived JWTs; sessions auto-refresh
- **Service role key never in client** — only used inside Edge Functions
- **Controlled contact sharing** — borrower and lender contact details stay hidden until acceptance
- **Append-only audit log** — `audit_logs` has no UPDATE/DELETE in app user grants
- **Private documents** — verification documents are never exposed in marketplace listings
- **Refresh token rotation** — reuse attack detection via `replaced_by` chain
- **`--dart-define` credentials** — Supabase keys injected at build time, not hardcoded

---

## Regulatory Compliance

> Nipanze operates as a technology marketplace. We do not hold funds, accept deposits, issue loans, pool capital, or set interest rates.

**We DO:** Provide marketplace infrastructure, show borrower-provided request information, manage controlled contact sharing, and facilitate discovery.

**We DO NOT:** Accept deposits, hold or pool user funds, issue loans or set interest rates, guarantee returns, act as a bank or financial institution, process payments.

All money movement, loan documentation, and repayment tracking happen directly between matched participants outside the platform.

---

## Roadmap

See [BUILD_PLAN.md](BUILD_PLAN.md) for the full, authoritative stage-by-stage roadmap.

### Stage 1 — Foundation ✅ Complete
- Schema v4.0, seed data, Flutter scaffold, auth, navigation, onboarding, unit + integration tests

### Stage 2 — Core Marketplace *(in progress)*
- Live marketplace feed, structured borrower requests, free browsing, subscription-gated offers, offer acceptance

### Stage 3 — Polish & Supporting Features
- Watchlist alerts, positions, notifications, analytics, profile, error/empty states

### Stage 3.5 — Cloud Migration & Auth Hardening
- Supabase Cloud, RLS audit, token rotation, APK release build

### Stage 4 — Contact Sharing & Deal Agreement
- Structured deal agreement system with controlled contact sharing after offer acceptance
- Agreement template generation, editable terms, locked confirmation, and unrevealable contact reveal

### Stage 5 — Admin & Compliance
- Admin dashboard, verification review, audit trails, SMS

### Stage 6 — Launch & Growth
- Play Store, App Store, referral programme, lender subscription growth

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

---

## License

MIT License — see the [LICENSE](LICENSE) file for details.

Copyright © 2024–2026 Nipanze Platforms Limited. All rights reserved.

---

## Contact

**Nipanze Platforms Limited**
Email: <contact@nipanze.ug>
Website: <https://nipanze.ug>

---

*Made with ❤️ for financial inclusion in Uganda*
