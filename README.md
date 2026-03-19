# OpenCapital — Flutter + Supabase

## A Non-Custodial Digital Marketplace for Direct Public Lending and Project Funding

> OpenCapital is a non-custodial digital marketplace that allows individuals and businesses to borrow and lend directly through competitive market bidding — without banks holding funds or setting interest rates.

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
- [User Model & Wallet Rules](#user-model--wallet-rules)
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

OpenCapital is a **transparent, market-driven capital marketplace** that directly connects borrowers and lenders through competitive bidding.

Unlike traditional banks or centralized digital lenders, OpenCapital does **not** issue loans, pool funds, or set interest rates. It operates as a **non-custodial exchange**, enabling participants to discover fair pricing through open market competition.

Borrowers can **view and compare lender bids in real time** before accepting any offer. No obligation exists until a borrower explicitly commits.

**Core Principle:** Democratize access to capital by eliminating unnecessary intermediaries and enabling true price discovery through open market competition.

---

## Problem Statement

In Uganda and similar emerging economies, access to affordable capital faces critical barriers:

- **High interest rates:** Traditional banks charge premium rates with limited competition
- **Rigid requirements:** Strict credit criteria exclude viable borrowers
- **Slow processing:** Lengthy approval processes delay funding
- **Limited transparency:** Opaque pricing and decision-making
- **Underutilised savings:** Public funds lack productive investment channels

Many digital lending platforms simply replicate banking models — acting as shadow banks with centralized pricing and custody of funds.

> Rapid mobile money adoption, increasing digital identity systems, and growing public demand for alternative investment opportunities create the ideal conditions for decentralized capital marketplaces in emerging economies.

---

## Solution

OpenCapital transforms lending into an **open marketplace activity** where:

- Borrowers publish funding requests with their maximum acceptable interest rate
- Lenders compete by bidding lower interest rates
- Borrowers observe live bidding activity **before committing**
- Market forces determine the final cost of capital
- Licensed payment providers handle all fund transfers
- The platform orchestrates matching, contracts, and repayment coordination

**We are not a bank. We are a capital exchange.**

---

## Key Features

### For Borrowers

- **Competitive rates** — market-driven pricing reduces borrowing costs
- **Fast access** — digital verification and automated matching
- **Transparent process** — real-time visibility into bid activity before commitment
- **Flexible terms** — define your own loan parameters
- **Clear repayment tracking** — scheduled visibility into obligations

### For Lenders

- **Direct investment** — fund specific borrowers or projects
- **Risk transparency** — comprehensive risk scores and borrower insights
- **Higher returns** — competitive market yields
- **Portfolio control** — full control over exposure and diversification

### Platform Features

- **Unified participant model** — one account can borrow and lend seamlessly
- **Non-custodial architecture** — platform never holds user funds
- **Wallet segregation** — DB-enforced separation of own funds vs borrowed funds
- **Risk assessment engine** — multi-factor credit scoring stored in `risk_assessments`
- **Digital contracts** — automated agreement generation, e-signing, and PDF download
- **Compliance built-in** — KYC, AML gates, and append-only audit trail from day one

---

## Business Model

OpenCapital generates revenue through marketplace facilitation rather than interest spreads.

Revenue sources include transaction facilitation fees, contract execution fees, premium analytics for lenders, institutional marketplace access, and optional risk assessment services. OpenCapital does not earn interest margins, custody fees, or lending spreads.

---

## Privacy & Anonymity

OpenCapital is **anonymous by default and transparent by design**. During loan listing and bidding, borrower and lender identities are fully masked. Participants interact using risk indicators, financial terms, and performance metrics — not personal identity.

Full legal identity and contact details are revealed **only after a bid is accepted and a digital contract is executed** — enforced at the API layer, not just the UI.

### Field Masking Rules

#### Borrower → Public Loan Listing (`v_loan_listings` view)

**Exposed (safe):** `request_id`, `requested_amount`, `duration_months`, `max_interest_rate`, `purpose`, `district` (from `user_profiles`), `risk_category`, `credit_score_band` (range only, never raw score), `funding_percentage`, `number_of_bids`, `listed_at`

**Masked (never in any public response):** `borrower_id`, email, phone, full name, date of birth, `address_line1/2`, `employer_name`, `business_registration_number`, all document URLs, raw `credit_score`

#### Lender → Public Bids

**Masked:** Lender name, email, phone, wallet balances, any identifying information.

**Exposed:** `bid_id`, `bid_amount`, `interest_rate`, lender `reputation_score`, lender `reputation_tier`, timestamp.

#### Post-Acceptance

Revealed to contract parties only via `contract_bids` + `user_profiles` with RLS policies: legal names, verified contact information, payment identifiers, contract document URL, regulatory disclosures.

### Reputation System

Trust is **earned, not claimed**. A dynamic, behavior-based reputation score (0–100) is computed by `sp_calculate_reputation_score()` after contract events and stored in `users.reputation_score`. The tier is auto-synced by `trg_sync_reputation_tier`.

#### Formula (Weighted)

```
Reputation Score =
  Repayment Performance     × 40%
  Participation History     × 20%
  Risk Accuracy             × 20%
  Consistency & Reliability × 20%
```

#### Reputation Tiers (`fn_score_to_tier`)

| Score | Tier | Notes |
| --- | --- | --- |
| 85–100 | Platinum | Auto-accept eligibility, highest visibility |
| 70–84 | Gold | Enhanced visibility, lower platform fees |
| 55–69 | Silver | Standard access |
| 40–54 | Bronze | Basic access |
| < 40 | Restricted | Limited platform access |

---

## How It Works

```
1. REQUEST    → Borrower specifies: amount, duration, max interest rate
2. VERIFY     → KYC approval required (trg_fn_require_kyc_for_loan enforces this)
3. LIST       → Anonymous request published via v_loan_listings view
4. BID        → Lenders compete; borrowers view bids before committing
5. ACCEPT     → Borrower explicitly accepts one bid (accept_bid RPC)
6. CONTRACT   → loan_contracts + contract_bids rows created; both parties sign
7. DISBURSE   → Funds move via licensed payment rails → non_lendable_borrowed credited
8. REPAY      → Scheduled installments; lender lendable_balance restored on completion
```

---

## User Model & Wallet Rules

OpenCapital uses a **single unified user account**. A user may borrow, lend, or do both (`role = 'both'`), subject to rules enforced at the database level.

### Three Segregated Wallet Pools (`wallet_balances`)

| Column | Label | Rule |
| --- | --- | --- |
| `lendable_balance` | 💰 Your Money | Deposited funds. The **only** pool eligible for bid amounts. |
| `locked_repayment` | 🔒 Locked | Reserved when a bid is accepted. Cannot be moved until repayments flow back. |
| `non_lendable_borrowed` | 🚫 Borrowed Funds | Credited on disbursement. **Permanently ineligible** for lending. |

### Core Rule

> Borrowed funds (`non_lendable_borrowed`) can **never** flow into `lendable_balance`. This is enforced at the column level and in `trg_fn_debit_borrower_on_repayment`.

### Trigger Chain (Full Lifecycle)

```
deposit          → lendable_balance   ↑
bid placed       → (validated: lendable_balance >= bid_amount)
bid accepted     → lendable_balance ↓  locked_repayment ↑   (lender)
disbursement     → non_lendable_borrowed ↑                   (borrower)
repayment paid   → non_lendable_borrowed ↓ / lendable ↓      (borrower)
                 → lendable_balance ↑  locked_repayment ↓    (lender)
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
| Database | Supabase Postgres (19 tables) | Relational data, RLS, triggers, functions |
| Realtime | Supabase Realtime | WebSocket live subscriptions |
| Storage | Supabase Storage | KYC docs, contract PDFs |
| Functions | Supabase Edge Functions (Stage 4) | Server-side business logic, async jobs |

---

## Project Structure

```
lib/
├── main.dart                       # Supabase init, DI setup, BLoC observer
├── core/
│   ├── theme/                      # AppTheme — light/dark, #1A56DB brand colour
│   ├── router/                     # GoRouter, auth redirect guards, route constants
│   ├── config/                     # SupabaseConfig — reads --dart-define at build time
│   ├── constants/                  # TableNames, StorageKeys, AppStrings
│   ├── errors/                     # AppException hierarchy
│   └── di/                         # Injectable config, GetIt locator
├── features/
│   ├── auth/                       # Login, Register, Verify Email, Reset Password
│   ├── dashboard/                  # Home — portfolio stats, quick actions
│   ├── marketplace/                # Loan list (v_loan_listings), filters, detail
│   ├── loans/                      # Create loan, my loans, repayment schedule
│   ├── bids/                       # Place bid, my bids, bid history
│   ├── contracts/                  # Contract view, signing, PDF download
│   ├── wallet/                     # Three-pool display, top-up, transaction history
│   ├── analytics/                  # Portfolio charts (v_user_portfolio, v_lender_investments)
│   ├── notifications/              # Notification centre, unread badge
│   ├── kyc/                        # Document upload, status display
│   ├── risk/                       # Risk profile, credit score band, assessment history
│   ├── profile/                    # User profile, edit, completion percentage
│   └── admin/                      # User notes, audit logs, KYC review (admin role only)
│       └── */
│           ├── data/               # DataSources (Supabase) + Models
│           ├── domain/             # Entities, UseCases, Repository interfaces
│           └── presentation/       # BLoC + Pages + Widgets
├── shared/
│   └── widgets/                    # MainScaffold, SearchBar, BalanceCard, RepTierBadge
sql/
│   ├── schema.sql                  # Full schema v3.2 — tables, triggers, RPCs, views, mock functions
│   └── seed.sql                    # Seed data v2.1 — 18 users with fixed UUIDs, Test1234! password
supabase/
│   └── migrations/                 # Incremental migrations applied on top of schema.sql
assets/
    ├── fonts/                      # Sora (headings) + Inter (body)
    ├── images/                     # Onboarding illustrations
    └── icons/                      # Custom SVG icons
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
| `/dashboard` | DashboardPage | Yes |
| `/marketplace` | MarketplacePage | Yes |
| `/marketplace/:requestId` | LoanDetailPage | Yes |
| `/loans/create` | LoanCreatePage | Yes (borrower + KYC) |
| `/loans/my-loans` | MyLoansPage | Yes |
| `/loans/repayments/:contractId` | RepaymentSchedulePage | Yes |
| `/bids` | MyBidsPage | Yes |
| `/contracts` | ContractsPage | Yes |
| `/contracts/:contractId` | ContractDetailPage | Yes (party only) |
| `/wallet` | WalletPage | Yes |
| `/analytics` | AnalyticsPage | Yes |
| `/notifications` | NotificationsPage | Yes |
| `/kyc` | KycPage | Yes |
| `/profile` | ProfilePage | Yes |
| `/admin` | AdminDashboardPage | Yes (admin role) |

---

## Database Schema

The full schema lives in `sql/schema.sql` (v3.2). It defines 19 tables, all triggers, functions, views, indexes, mock RPCs, and seeded `system_settings` in a single deployable file. Apply it with:

```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -f sql/schema.sql
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -f sql/seed.sql
```

### Tables

| Table | Purpose |
| --- | --- |
| `users` | Core authentication and identity. Holds `reputation_score`, `reputation_tier`. |
| `user_profiles` | Extended personal, address, employment data. Only `district` is public. |
| `password_reset_tokens` | Single-use, 1-hour TTL. |
| `email_verification_tokens` | Email confirmation on register / email change. |
| `refresh_tokens` | JWT refresh token store. SHA-256 hash only, never plaintext. Rotation chain. |
| `kyc_verifications` | Document upload and admin review. `status='approved'` required for loan creation. |
| `risk_assessments` | Credit scores (300–850) and risk categories. `is_current=TRUE` is live. |
| `wallet_balances` | Three segregated pools. Auto-created on user INSERT. |
| `loan_requests` | Borrower funding requests. Public view via `v_loan_listings`. |
| `bids` | Lender offers. INSERT validates `lendable_balance`. |
| `loan_contracts` | Executed agreements. Activated when all parties sign. |
| `contract_bids` | Junction: one row per lender per contract. Tracks per-lender signature. |
| `disbursements` | Fund transfers from each lender to borrower. |
| `loan_repayments` | Amortization schedule. Generated by `sp_calculate_repayment_schedule()`. |
| `repayment_transactions` | Actual payment events per installment. |
| `audit_logs` | **Append-only** compliance trail. Never update or delete rows. |
| `notifications` | In-app notification feed. `data` JSONB for deep-linking. |
| `user_notes` | Internal CRM notes. Never visible to subject user. |
| `system_settings` | Runtime platform config. Public settings served to client. |

### Key Functions and Triggers

| Name | Type | Purpose |
| --- | --- | --- |
| `handle_new_auth_user()` | Trigger fn | Syncs `auth.users` → `public.users` on signup |
| `sp_calculate_reputation_score(user_id)` | Function | Weighted 0–100 reputation score |
| `fn_score_to_tier(score)` | Function (IMMUTABLE) | Maps score → tier enum |
| `sp_calculate_credit_score(user_id)` | Function | Credit score 300–850 |
| `sp_calculate_repayment_schedule(contract_id)` | Function | Generates amortization schedule |
| `accept_bid(request_id, bid_id, borrower_id)` | RPC | Atomic bid acceptance + contract creation |
| `mock_top_up(user_id, amount)` | RPC | MVP wallet top-up (replaced in Stage 4) |
| `mock_disburse(contract_id, bid_id)` | RPC | MVP disbursement (replaced in Stage 4) |
| `mock_repayment(repayment_id, amount)` | RPC | MVP repayment (replaced in Stage 4) |
| `trg_sync_reputation_tier` | BEFORE UPDATE on `users` | Auto-syncs `reputation_tier` from `reputation_score` |
| `trg_auto_create_wallet` | AFTER INSERT on `users` | Creates `wallet_balances` row |
| `trg_require_kyc_for_loan` | BEFORE INSERT on `loan_requests` | Blocks without approved KYC |
| `trg_require_active_borrower` | BEFORE INSERT on `loan_requests` | Blocks if `users.status != 'active'` |
| `trg_enforce_lendable_on_bid` | BEFORE INSERT on `bids` | Blocks if `lendable_balance < bid_amount` |
| `trg_lock_funds_on_accept` | AFTER UPDATE on `bids` | Moves funds to `locked_repayment` |
| `trg_update_funding_progress` | AFTER UPDATE on `bids` | Updates `funding_percentage` and loan status |
| `trg_credit_borrower_on_disbursement` | AFTER UPDATE on `disbursements` | Credits `non_lendable_borrowed` |
| `trg_check_all_lenders_signed` | AFTER UPDATE on `contract_bids` | Auto-activates contract |
| `trg_update_contract_on_repayment` | AFTER UPDATE on `loan_repayments` | Updates `outstanding_balance`, detects default |
| `trg_release_lender_funds` | AFTER UPDATE on `repayment_transactions` | Restores `lendable_balance` |

### Key Views

| View | Purpose |
| --- | --- |
| `v_loan_listings` | Anonymised marketplace listing — `borrower_id` intentionally excluded |
| `v_active_loans` | Admin dashboard — active contracts with borrower names |
| `v_user_portfolio` | Dashboard — borrower + lender aggregates + wallet in one query |
| `v_lender_investments` | Lender returns page — invested amounts, default exposure, avg rate |
| `v_loan_performance` | Monthly platform KPIs for analytics and reports |

---

## Supabase Setup

### 1. Local Development Stack (Stages 1–3)

```bash
# Install Supabase CLI
brew install supabase/tap/supabase   # macOS
# Linux: https://supabase.com/docs/guides/cli/getting-started
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

The `handle_new_auth_user()` function is defined in `sql/schema.sql` and runs automatically on every `auth.users` INSERT. It creates the corresponding `public.users` row, which in turn fires `trg_auto_create_wallet` to create the `wallet_balances` row. No separate migration file is needed.

### 3. Storage Buckets

Create two buckets in Storage → New bucket:

- `kyc-documents` — private; user can upload to own folder only
- `contracts` — private; only contract parties can read

### 4. Production Project

1. Go to [supabase.com](https://supabase.com) and create a project named `opencapital`
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
git clone https://github.com/your-org/opencapital.git
cd opencapital

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

The run scripts (`run_local.sh`, `run_linux.sh`) source `.env.local` and inject Supabase credentials via `--dart-define` automatically.

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

# Production — fill in at Stage 4
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...
```

Credentials are injected via `--dart-define` at build time and read by `lib/core/config/supabase_config.dart` using `String.fromEnvironment()`. The anon key is safe to bundle — RLS enforces access control at the database level. The service role key is used only in test teardown helpers and Edge Functions, never in client code.

---

## Key Packages

| Package | Purpose | Stage |
| --- | --- | --- |
| `supabase_flutter ^2.x` | Auth, database, Realtime, storage | 1 |
| `flutter_bloc ^8.x` | BLoC state management | 1 |
| `go_router ^14.x` | Declarative routing with auth guards | 1 |
| `get_it + injectable` | Dependency injection with code-gen | 1 |
| `flutter_secure_storage ^9.x` | Secure token storage | 1 |
| `reactive_forms ^18.x` | Form validation | 1 |
| `animate_do ^3.x` | FadeIn/SlideIn animations | 1 |
| `lottie ^3.x` | Loading and empty state animations | 1 |
| `smooth_page_indicator ^1.x` | Onboarding slide dots | 1 |
| `shimmer ^3.x` | Skeleton loading screens | 2 |
| `percent_indicator ^4.x` | Loan funding progress bars | 2 |
| `fl_chart ^0.69.x` | Portfolio and analytics charts | 2 |
| `cached_network_image ^3.x` | Avatar and document thumbnails | 2 |
| `hive_flutter ^1.x` | UI-layer cache only (not primary DB) | 2 |
| `pdf ^3.x` | Client-side contract PDF generation | 3 |
| `printing + flutter_pdfview` | PDF view and download | 3 |
| `local_auth ^2.x` | Biometric login | 3 |
| `flutter_local_notifications ^17.x` | In-app notification banners | 3 |

---

## Edge Functions

Edge Functions (Deno TypeScript) wrap the existing Postgres RPCs for server-side enforcement. Added in Stage 4, one at a time.

```bash
supabase functions new accept-bid
supabase functions serve accept-bid --env-file .env.local   # local test
supabase functions deploy accept-bid                         # deploy
```

| Function | Replaces | Purpose |
| --- | --- | --- |
| `accept-bid` | `accept_bid` RPC | Atomic bid acceptance with server enforcement |
| `place-bid` | Client-side bid INSERT | Server-side balance validation |
| `process-repayment` | `mock_repayment` RPC | Handle real payment provider webhooks |
| `calculate-risk-score` | Client-side scoring | Run after KYC approval or contract event |
| `send-notification` | Client-side notification INSERT | Triggered by DB webhook on status changes |
| `generate-contract` | Client-side PDF | Generate, hash, and store PDF on activation |

---

## Testing

```bash
# Unit + widget tests (no local stack needed)
flutter test

# Single test file
flutter test test/features/auth/auth_bloc_test.dart

# Integration tests — Linux desktop only (web not supported by integration_test)
supabase start
flutter test integration_test/integration_test.dart -d linux

# Coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Test Accounts

All accounts are pre-loaded by `sql/seed.sql` v2.1 with fixed UUIDs and `email_confirmed_at` set.
**Password for all accounts: `Test1234!`**

No manual email confirmation step is required — seed accounts are ready to sign in immediately.

| Email | Role | State |
| --- | --- | --- |
| `david.mukasa@gmail.com` | borrower | KYC approved, loan fully funded |
| `sarah.namukasa@yahoo.com` | borrower | KYC approved, loan partially funded |
| `james.okello@outlook.com` | both | KYC approved, loan fully funded |
| `maria.nakato@gmail.com` | borrower | KYC approved, loan active (no bids) |
| `robert.ssemwanga@gmail.com` | both | KYC approved, lender + draft loan |
| `invest@pearlcapital.ug` | lender | 3M lendable, 7M locked |
| `funds@victoriainvest.co.ug` | lender | 3M lendable, 2M locked |
| `lending@equatorfinance.ug` | lender | 2M lendable, 3M locked |
| `info@greenleafagro.co.ug` | lender | 1.5M lendable, pending bid |
| `contact@kampalatech.ug` | lender | 1M lendable, pending bid |
| `charles.mwesigwa@gmail.com` | both | KYC approved, 1.2M lendable |
| `lucy.nambi@yahoo.com` | both | KYC approved |
| `frank.omondi@gmail.com` | borrower | KYC approved, loan active (no bids) |
| `alice.namuli@gmail.com` | borrower | KYC pending — use to test KYC gate |
| `admin1@opencapital.ug` | admin | Full access |
| `test.user@gmail.com` | borrower | No KYC, no profile — minimal fixture |

---

## Deployment

| Target | Available now | Command |
| --- | --- | --- |
| Android APK (sideload) | ✅ | `flutter build apk --release` |
| Web | ✅ | `flutter build web --release` |
| Linux desktop | ✅ | `flutter build linux --release` |
| Edge Functions | ✅ (free tier) | `supabase functions deploy` |
| DB Migrations | ✅ | `supabase db push` |
| Android Play Store | Stage 4 | `flutter build appbundle --release` |
| iOS App Store | Stage 4 | `flutter build ios --release` |

---

## Security

- **No fund custody** — platform never holds user money
- **RLS on all tables** — Postgres enforces access control, not just the application layer
- **JWT auth** — Supabase issues short-lived JWTs; sessions auto-refresh
- **Service role key never in client** — only used inside Edge Functions and test helpers
- **Wallet segregation** — `non_lendable_borrowed` can never flow into `lendable_balance` (DB constraint)
- **Append-only audit log** — `audit_logs` has no UPDATE/DELETE in app user grants
- **Anonymised listings** — `borrower_id` excluded from `v_loan_listings` at the view level
- **KYC gate** — DB trigger blocks loan creation without approved KYC
- **Contract hash** — `loan_contracts.contract_hash` stores SHA-256 of signed PDF for tamper detection
- **Refresh token rotation** — reuse attack detection via `replaced_by` chain in `refresh_tokens`
- **`--dart-define` credentials** — Supabase keys injected at build time, not hardcoded

---

## Regulatory Compliance

> OpenCapital operates as a technology marketplace and partners with licensed financial institutions and payment providers for fund movement and settlement.

**We DO:** Provide marketplace infrastructure, verify user identities (KYC via `kyc_verifications`), assess and display risk scores (`risk_assessments`), coordinate payment initiation, maintain an immutable audit trail (`audit_logs`).

**We DO NOT:** Accept deposits, hold or pool user funds, issue loans or set interest rates, guarantee returns, act as a bank or financial institution.

---

## Roadmap

### Stage 1 — Foundation ✅ Complete

- [x] Schema design — 19 tables, triggers, functions, views, mock RPCs (`sql/schema.sql` v3.2)
- [x] Seed data — 18 users with fixed UUIDs, GoTrue-compatible passwords (`sql/seed.sql` v2.1)
- [x] Flutter scaffold — theme, routing, DI, bottom nav, all platform targets
- [x] Supabase Auth — email/password, verification, password reset
- [x] Auth bridge — `handle_new_auth_user()` trigger syncs `auth.users` → `public.users` + wallet
- [x] Auth guards and navigation shell
- [x] Onboarding — 3-slide responsive page with animated indicators
- [x] Unit tests — 7/7 passing (`auth_bloc_test.dart`)
- [x] Integration tests — 15/15 passing (Linux desktop, local stack)

### Stage 2 — Core Marketplace *(real schema, mock payments)*

- [ ] Wallet page with three segregated balance types
- [ ] Mock top-up (`mock_top_up` RPC already in schema)
- [ ] Loan request creation with DB trigger enforcement
- [ ] Anonymised marketplace listing via `v_loan_listings`
- [ ] Competitive bidding with Realtime subscriptions
- [ ] `accept_bid` RPC — atomic contract creation (already in schema)
- [ ] Contract signing and `sp_calculate_repayment_schedule`
- [ ] Mock disbursement (`mock_disburse` RPC already in schema)
- [ ] Mock repayment (`mock_repayment` RPC already in schema)
- [ ] Reputation recalculation via `sp_calculate_reputation_score`

### Stage 3 — Polish *(no external APIs)*

- [ ] In-app Realtime notifications (`notifications` table)
- [ ] KYC document upload (Supabase Storage) + admin review in Studio
- [ ] Contract PDF generation and upload to Storage
- [ ] Analytics charts from `v_user_portfolio`, `v_lender_investments`
- [ ] Risk profile display (credit score band, risk category)
- [ ] Dashboard live data from `v_user_portfolio`
- [ ] Biometric login, dark mode, offline cache (Hive)

### Stage 4 — External Integrations

- [ ] Edge Functions — server-side logic enforcement (one at a time)
- [ ] MTN Mobile Money (sandbox → production)
- [ ] Airtel Money (sandbox → production)
- [ ] Africa's Talking SMS OTP
- [ ] Automated KYC verification (Smile Identity)
- [ ] Background push notifications (FCM)
- [ ] Play Store / App Store submission

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

Copyright © 2024–2026 OpenCapital Platforms Limited. All rights reserved.

---

## Contact

**OpenCapital Platforms Limited**
Email: <contact@opencapital.com>
Website: <https://opencapital.com>

---

*Made with ❤️ for financial inclusion*