# Nipanze — Flutter + Supabase

## A Non-Custodial Digital Loan Listing Marketplace

> Nipanze is a peer-to-peer loan listing marketplace that connects borrowers and lenders through competitive market bidding — without a bank, custodian, or intermediary holding any funds.

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
- [Privacy & Anonymity](#privacy--anonymity)
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

Nipanze is a **transparent, market-driven loan listing marketplace** that directly connects borrowers and lenders through competitive bidding.

Nipanze does **not** hold funds, accept deposits, issue loans, pool capital, or set interest rates. It operates as a **non-custodial listing exchange**, enabling participants to discover fair pricing through open market competition. All money movement happens directly between matched parties via licensed payment providers — **never through Nipanze**.

Borrowers can **view and compare lender bids in real time** before accepting any offer. No obligation exists until a borrower explicitly commits. After acceptance, a vetted **negotiator** is assigned to facilitate the off-platform deal.

**Core Principle:** Democratise access to capital by eliminating unnecessary intermediaries and enabling true price discovery through open market competition.

---

## Problem Statement

In Uganda and similar emerging economies, access to affordable capital faces critical barriers:

- **High interest rates:** Traditional banks charge premium rates with limited competition
- **Rigid requirements:** Strict credit criteria exclude viable borrowers
- **Slow processing:** Lengthy approval processes delay funding
- **Limited transparency:** Opaque pricing and decision-making
- **Underutilised savings:** Public funds lack productive investment channels

Many digital lending platforms simply replicate banking models — acting as shadow banks with centralised pricing and custody of funds.

> Rapid mobile money adoption, increasing digital identity systems, and growing public demand for alternative investment opportunities create the ideal conditions for decentralised capital marketplaces in emerging economies.

---

## Solution

Nipanze transforms lending into an **open marketplace activity** where:

- Borrowers publish funding requests with their maximum acceptable interest rate
- Lenders compete by bidding lower interest rates
- Borrowers observe live bidding activity (the **order book**) **before committing**
- Market forces determine the final cost of capital
- A vetted **negotiator** is auto-assigned after bid acceptance to facilitate the deal
- Participants arrange settlement directly — Nipanze never touches funds
- The platform orchestrates matching, anonymity, negotiator assignment, and reputation

**We are not a lender. We are a capital exchange.**

---

## Key Features

### For Borrowers

- **Competitive rates** — market-driven pricing reduces borrowing costs
- **Fast listing** — digital KYC and self-service listing creation
- **Transparent process** — real-time order book visibility before commitment
- **Flexible terms** — define amount, duration, and ceiling rate
- **Watchlist** — track listings for free, subscribe only to bid or list

### For Lenders

- **Direct investment** — bid on specific listings you choose
- **Risk transparency** — risk scores and credit bands (never raw scores)
- **Higher returns** — compete to offer the best rate
- **Order book** — see where your bid stands against competing lenders
- **Reputation system** — behaviour-based trust scores

### Platform Features

- **Subscription model** — Borrower (UGX 20K/mo), Lender (UGX 35K/mo), Pro (UGX 150K/mo). Watchlist is free.
- **Non-custodial architecture** — Nipanze never holds, pools, or moves user funds
- **Anonymity by default** — borrower and lender identities masked until post-acceptance reveal
- **Negotiator assignment** — vetted facilitators assigned automatically on bid acceptance
- **Contact reveal** — opt-in, one-time identity disclosure (UGX 25,000 add-on)
- **Reputation engine** — weighted 0–100 score with Platinum / Gold / Silver / Bronze / Restricted tiers
- **KYC gate** — listing creation blocked without approved KYC (DB trigger enforced)
- **Compliance built-in** — append-only audit trail from day one

---

## Business Model

Nipanze generates revenue through subscription fees and contact reveal add-ons — not interest spreads.

| Revenue Stream | Description |
|---|---|
| Borrower subscription | UGX 20,000/month — list up to 2 requests, accept bids |
| Lender subscription | UGX 35,000/month — place bids, track positions |
| Pro subscription | UGX 150,000/month — analytics API access |
| Contact reveal | UGX 25,000 per reveal — one-time post-acceptance add-on |

Nipanze does **not** earn interest margins, custody fees, lending spreads, or any fee tied to loan performance.

---

## Privacy & Anonymity

Nipanze is **anonymous by default and transparent by design**. During listing and bidding, borrower and lender identities are fully masked. Participants interact using risk indicators, financial terms, and performance metrics — not personal identity.

Full legal identity and contact details are revealed **only after a bid is accepted and the contact reveal add-on is purchased** — enforced at the API layer, not just the UI.

### Field Masking Rules

#### Borrower → Public Loan Listing (`v_loan_listings` view)

**Exposed (safe):** `request_id`, `title`, `purpose`, `district`, `duration_months`, `requested_amount`, `max_interest_rate`, `risk_category`, `credit_score_band` (range only, never raw score), `number_of_bids`, `funding_percentage`, `listed_at`, `expires_at`, `best_bid_rate`

**Masked (never in any public response):** `borrower_id`, email, phone, full name, raw credit score

#### Lender → Order Book

**Exposed:** `lender_token` (e.g. `L-#482`), `amount`, `interest_rate`, timestamp

**Masked:** Lender name, email, phone — never exposed in order book

#### Post-Acceptance Reveal (`contact_reveals` table)

Revealed only to the initiating party via opt-in reveal flow: legal name, phone, email, assigned negotiator contact.

### Reputation System

Trust is **earned, not claimed**. A dynamic, behaviour-based reputation score (0–100) is computed by `sp_calculate_reputation_score()` after contract events.

#### Formula (Weighted)

```
Reputation Score =
  Repayment Performance     × 40%
  Participation History     × 20%
  Risk Accuracy             × 20%
  Consistency & Reliability × 20%
```

#### Reputation Tiers

| Score | Tier | Notes |
| --- | --- | --- |
| 85–100 | Platinum | Highest visibility |
| 70–84 | Gold | Enhanced visibility |
| 55–69 | Silver | Standard access |
| 40–54 | Bronze | Basic access |
| < 40 | Restricted | Limited platform access |

---

## How It Works

```
1. SUBSCRIBE  → User selects Borrower or Lender plan (Watchlist is free)
2. KYC        → Identity verified before listing creation is allowed
3. LIST       → Borrower specifies amount, duration, ceiling rate
4. BID        → Lenders compete; order book visible in real time
5. ACCEPT     → Borrower explicitly accepts one bid (accept_bid RPC)
6. NEGOTIATE  → Negotiator auto-assigned; both parties notified
7. REVEAL     → Optional contact reveal (UGX 25,000 add-on)
8. SETTLE     → Parties arrange payment directly off-platform
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
| Realtime | Supabase Realtime | WebSocket live order book subscriptions |
| Storage | Supabase Storage | KYC docs, contract PDFs |
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
│   ├── marketplace/                # Live feed (v_loan_listings), filters, loan detail, order book
│   ├── watchlist/                  # Saved listings, closing alerts (free for all users)
│   ├── positions/                  # My listings · My bids · Contracts (3-tab)
│   ├── account/                    # Subscription, identity (KYC), reputation tier
│   ├── loans/                      # Create listing, my listings, repayment schedule
│   ├── bids/                       # My bids page
│   ├── contracts/                  # Contract list and detail
│   ├── notifications/              # Notification centre, unread badge
│   ├── kyc/                        # Document upload, status display
│   ├── profile/                    # User profile, edit
│   └── admin/                      # KYC review, user management, audit logs (admin only)
│       └── */
│           ├── data/               # DataSources (Supabase) + Models
│           ├── domain/             # Entities, UseCases, Repository interfaces
│           └── presentation/       # BLoC + Pages + Widgets
├── shared/
│   ├── models/                     # LoanListingModel, BidModel, ContractModel, UserModel…
│   └── widgets/                    # MainScaffold, ReputationTierBadge, KycStatusChip
sql/
│   ├── schema.sql                  # Full schema v4.0 — tables, triggers, RPCs, views
│   └── seed.sql                    # Seed data v1.0 — 16 users, 41 listings, 3 contracts
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
| `/marketplace/:requestId` | LoanDetailPage + Order Book | Yes |
| `/watchlist` | WatchlistPage (tab 2) | Yes |
| `/positions` | PositionsPage (tab 3) | Yes |
| `/account` | AccountPage (tab 4) | Yes |
| `/loans/create` | LoanCreatePage | Yes (borrower + KYC) |
| `/loans/my-loans` | MyLoansPage | Yes |
| `/bids` | MyBidsPage | Yes |
| `/contracts` | ContractsPage | Yes |
| `/contracts/:contractId` | ContractDetailPage | Yes (party only) |
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
| `profiles` | Core user profile. Extends `auth.users` 1-to-1. Holds `credit_score`, `reputation_tier`, `lender_token`. |
| `system_settings` | Platform config. Business limits read from here at runtime. |
| `subscriptions` | Active plan per user. `watchlist` plan = free. |
| `kyc_verifications` | Document upload and admin review. `status='approved'` required for listing creation. |
| `loan_requests` | Borrower funding requests. Public view via `v_loan_listings` (borrower_id excluded). |
| `loan_bids` | Lender offers. Lenders shown as `lender_token` — identity never exposed in order book. |
| `watchlist` | User-saved listings. Free for all plans. |
| `negotiators` | Vetted professionals assignable to matched deals. |
| `contracts` | Created atomically on bid acceptance. Drives full post-acceptance lifecycle. |
| `repayment_schedules` | Amortisation lines per contract. Participants self-report; Nipanze does not verify. |
| `negotiator_assignments` | Links a contract to its assigned negotiator. |
| `negotiator_assessments` | Structured assessments that feed `sp_calculate_reputation_score`. |
| `contact_reveals` | Opt-in, irreversible identity disclosure. Logged in `audit_logs`. |
| `credit_score_events` | Audit trail for score changes. |
| `notifications` | In-app notification feed. |
| `audit_logs` | **Append-only** compliance trail. Never update or delete rows. |
| `refresh_tokens` | JWT refresh token store with rotation chain. |
| `api_keys` | Pro plan API keys. |
| `referrals` | Referral programme tracking. |

### Key Functions and Triggers

| Name | Type | Purpose |
| --- | --- | --- |
| `handle_new_auth_user()` | Trigger fn | Syncs `auth.users` → `public.profiles`; creates free watchlist subscription |
| `sp_calculate_reputation_score(user_id)` | Function | Weighted 0–100 reputation score |
| `sp_calculate_repayment_schedule(contract_id)` | Function | Generates amortisation schedule |
| `accept_bid(request_id, bid_id, borrower_id)` | RPC | Atomic bid acceptance + contract + negotiator assignment |
| `sp_assign_negotiator(contract_id)` | RPC | Auto-assigns an available negotiator |

### Key Views

| View | Purpose |
| --- | --- |
| `v_loan_listings` | Anonymised marketplace — `borrower_id` intentionally excluded |
| `v_user_portfolio` | Dashboard — borrower + lender aggregates in one query |
| `v_lender_investments` | Lender returns page — invested amounts, avg rate |
| `v_loan_performance` | Monthly platform KPIs |

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

The `handle_new_auth_user()` function is defined in `sql/schema.sql` and runs automatically on every `auth.users` INSERT. It creates the corresponding `public.profiles` row and provisions a free `watchlist` subscription automatically.

### 3. Storage Buckets

Create two buckets in Storage → New bucket:

- `kyc-documents` — private; user can upload to own folder only
- `contracts` — private; only contract parties can read

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
| `percent_indicator ^4.x` | Bid coverage progress bars | 2 |
| `fl_chart ^0.69.x` | Portfolio and analytics charts | 3 |
| `pdf ^3.x` | Client-side contract PDF | 5 |
| `local_auth ^2.x` | Biometric login | 3 |
| `flutter_local_notifications ^17.x` | In-app notification banners | 3 |

---

## Edge Functions

Edge Functions (Deno TypeScript) wrap Postgres RPCs for server-side enforcement. Added in Stage 5.

```bash
supabase functions new accept-bid
supabase functions serve accept-bid --env-file .env.local   # local test
supabase functions deploy accept-bid                         # deploy
```

| Function | Purpose |
| --- | --- |
| `accept-bid` | Atomic bid acceptance with server enforcement |
| `place-bid` | Server-side balance/subscription validation |
| `assign-negotiator` | Auto-assign vetted negotiator on acceptance |
| `generate-contract-pdf` | Generate, hash, and store contract PDF |
| `send-sms` | Africa's Talking or Twilio SMS alerts |
| `calculate-reputation` | Run after contract events |

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
| `david.mukasa@gmail.com` | Borrower | KYC approved, active listing |
| `sarah.namukasa@yahoo.com` | Borrower | KYC approved, contract draft pending |
| `james.okello@outlook.com` | Both | KYC approved, borrower + lender flows |
| `maria.nakato@gmail.com` | Borrower | Active listing, 1 pending bid |
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
- **Anonymised listings** — `borrower_id` excluded from `v_loan_listings` at the view level
- **KYC gate** — DB trigger blocks listing creation without approved KYC
- **Append-only audit log** — `audit_logs` has no UPDATE/DELETE in app user grants
- **Lender tokens** — stable per-session anonymous IDs (e.g. `L-#482`) in order book
- **Refresh token rotation** — reuse attack detection via `replaced_by` chain
- **`--dart-define` credentials** — Supabase keys injected at build time, not hardcoded

---

## Regulatory Compliance

> Nipanze operates as a technology marketplace. We do not hold funds, accept deposits, issue loans, pool capital, or set interest rates.

**We DO:** Provide marketplace infrastructure, verify user identities (KYC), display risk scores, coordinate negotiator assignment, maintain an immutable audit trail.

**We DO NOT:** Accept deposits, hold or pool user funds, issue loans or set interest rates, guarantee returns, act as a bank or financial institution, process payments.

All money movement is arranged directly between matched participants off-platform.

---

## Roadmap

See [BUILD_PLAN.md](BUILD_PLAN.md) for the full, authoritative stage-by-stage roadmap.

### Stage 1 — Foundation ✅ Complete
- Schema v4.0, seed data, Flutter scaffold, auth, navigation, onboarding, unit + integration tests

### Stage 2 — Core Marketplace *(in progress)*
- Live marketplace feed, order book, KYC upload, listing creation, bidding, bid acceptance

### Stage 3 — Polish & Supporting Features
- Watchlist alerts, positions, notifications, analytics, profile, error/empty states

### Stage 3.5 — Cloud Migration & Auth Hardening
- Supabase Cloud, RLS audit, token rotation, APK release build

### Stage 4 — Negotiator Module & Contract Drafting
- Negotiator assignment, contact reveal flow, draft contract generation

### Stage 5 — Admin, Compliance & Credit Score Automation
- Admin dashboard, in-app KYC review, reputation automation, PDF contracts, SMS

### Stage 6 — Launch & Growth
- Play Store, App Store, referral programme, Pro API

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