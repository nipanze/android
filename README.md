# Nipanze — Flutter + Supabase

## A Non-Custodial Digital Lending Matchmaking Marketplace

> Nipanze is a peer-to-peer financial marketplace that connects people who need money with people willing to lend, through structured requests, offers, and controlled contact sharing — without a bank, custodian, or intermediary holding any funds.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Status: MVP](https://img.shields.io/badge/Status-MVP-blue.svg)
![Stack: Flutter + Supabase](https://img.shields.io/badge/Stack-Flutter%20%2B%20Supabase-purple.svg)

A cross-platform fintech app built with Flutter and Supabase, targeting Android, iOS, Web, and Desktop (Linux, Windows, macOS).

---

## Table of Contents

- [Overview](#overview)
- [Problem Statement](#problem-statement)
- [Solution](#solution)
- [The Unified Marketplace Model](#the-unified-marketplace-model)
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

Nipanze is a **peer-to-peer financial marketplace** built on a single, unified account model. There is no "borrower account" or "lender account" — every user sees the same marketplace and performs an action (**Post Request** or **Make Offer**) depending on what they click. Access to each action is gated purely by `subscription_plan`, not by any stored role.

Nipanze does **not** hold funds, accept deposits, issue loans, pool capital, guarantee repayment, track repayments, or act as a financial institution. It simply helps financial requests and offers meet through structured discovery, matching, and controlled connection.

Posting a request is free for everyone. Making offers requires the **Lender** plan. Suggesting preferred terms on a posted request requires the **Pro** plan. Contact details remain hidden until a contract is generated after an offer is accepted. Beyond contact, listing detail itself uses **tiered visibility** — see [Transparency & Controlled Contact](#transparency--controlled-contact) — so exact offer terms are only visible to the request owner and to other offer-makers competing on that same listing.

**Core Principle:** One marketplace. One account. One dashboard. Capability comes from your subscription plan, not from a fixed identity.

---

## Problem Statement

In Uganda and similar emerging economies, access to affordable capital faces critical barriers:

- **Long bank procedures:** Formal approvals can take too long for urgent needs
- **Lack of collateral:** Many people needing funds cannot meet traditional security requirements
- **Limited financial history:** Thin credit files exclude people with real repayment ability
- **High interest rates:** People needing funds lack flexible, competitive alternatives
- **Limited visibility:** People willing to lend struggle to find requests and assess repayment ability
- **Weak lending structure:** Informal lending lacks a reliable marketplace for discovery, offers, and connection

Many lending options still focus on collateral and institutional gatekeeping instead of giving people a structured way to show income, intent, and repayment plans.

---

## Solution

Nipanze provides a single marketplace structure where:

- Anyone can publish a structured funding request for free
- Every request includes loan details, source of income, loan purpose, and repayment ability
- Anyone can browse listed requests for free
- Making an offer requires the Lender plan; the offer carries the offer-maker's own amount, interest/return expectation, and terms
- The request owner reviews available offers and accepts the one that fits
- Contact details are revealed only after the request owner accepts an offer
- Both parties connect outside the platform
- The platform supports discovery, matching, and controlled contact sharing — nothing more

**We are not a lender. We are a matchmaking marketplace.**

---

## The Unified Marketplace Model

Nipanze v4.1 moved away from a role-based design (`borrower` / `lender`) to a **unified, action-based** model. This section is the source of truth for how capability works across the app — see [BUILD_PLAN.md](BUILD_PLAN.md) for the full rationale and migration history.

### The decision

- One interface for every user — no separate borrower/lender screens or signup paths
- No `role` column stored on the account
- Users choose a **subscription plan**, not an identity
- The same person can post a request *and* make offers, at any time, from the same login

### Single entry point after login

Every user lands on the same dashboard:

1. **Marketplace** — all loan listings, same feed for everyone
2. **Post Request** — always visible, Free tier and up
3. **Offers Panel** — offers *received* on your requests, and (if your plan allows) offers *you've made* on others' requests

There is no "select your role" step anywhere in the app. A user simply acts:

- Clicks **Post Request** → acting as the request owner for that listing
- Clicks **Make Offer** → acting as the offer-maker for that listing

### Feature access by plan

| Plan | Access |
|---|---|
| 🟢 **Free** | Post basic loan requests (amount, duration, purpose) · Browse marketplace · Accept received offers · Watchlist, Positions, Notifications, KYC · ❌ Cannot make offers · ❌ Cannot suggest terms when posting |
| 🔵 **Lender** | Everything in Free, **plus**: make offers on any listing · set interest rate, late payment fee, and repayment schedule on offers |
| 🟣 **Pro** | Everything in Lender, **plus**: suggest terms when posting a request (interest rate, late fee, repayment schedule) · priority visibility for posted requests · improved matching |

No plan is ever labeled "Borrower Plan" or "Lender-only." Each plan name describes the *unlocked capability*, not the person holding it. A single user can hold only **one** `subscription_plan` at a time (`free | lender | pro`), and Pro is a strict superset of Lender, which is a strict superset of Free.

### The one exception: `is_admin`

`is_admin` is a true role, separate from the subscription plan, since it governs platform moderation rather than marketplace participation. It is the **only** role in the system.

---

## Key Features

### Posting a Request (Free plan and above)

- **Free access** — post loan requests without paying to list
- **Structured requests** — title, amount, duration, purpose, district, income source, and repayment ability
- **Repayment visibility** — show the marketplace how the loan will be repaid
- **Flexible outcomes** — receive and compare offers from multiple lenders
- **My Requests** — track posted requests and responses in one place (Positions tab)
- **Controlled contact** — personal contact details stay hidden until an offer is accepted

### Making Offers (Lender plan and above)

- **Free browsing** — review requests before subscribing to the Lender plan
- **Repayment context** — assess loan purpose, requested amount, duration, and repayment plan
- **My Offers** — manage offer activity in one place (Positions tab)
- **Custom terms** — offer your own amount, interest rate, late payment fee, and repayment schedule (locked on submit)
- **Return potential** — fund selected requests directly

### Suggesting Terms (Pro plan)

- **Negotiating leverage** — suggest a preferred interest rate, late payment fee, and repayment schedule when posting a request (locked on publish)
- **Priority visibility** — Pro-posted requests get improved placement and matching

### Platform Features

- **Free posting** — anyone can create a request without a listing fee
- **Free browsing** — anyone can browse requests before subscribing
- **Subscription-gated offers** — making offers requires an active Lender (or Pro) plan
- **Locked bidding** — both suggested posting terms and offer terms are locked on submission; no post-publish edits
- **Contract generation** — a digital contract is auto-generated when a request owner accepts an offer
- **Single account, one dashboard** — every user posts and offers from the same account and screen
- **Marketplace main screen** — live feed of requests with amount, purpose, district, and repayment plan
- **Non-custodial architecture** — Nipanze never holds, pools, or moves user funds
- **Controlled contact sharing** — contact details are revealed only after a contract is generated
- **Selective transparency** — listing detail shows aggregate signals (funded %, offer count, coverage tier) to everyone, but exact offer terms unlock only for the request owner and for offer-makers who have themselves bid on that listing
- **Compliance built-in** — append-only audit trail from day one

---

## Business Model

Nipanze generates revenue through subscriptions — not interest spreads — via a single upgrade path.

| Plan | Unlocks |
|---|---|
| 🟢 **Free** | Post basic requests (amount, duration, purpose) · browse · accept offers received |
| 🔵 **Lender** *(subscription)* | Everything in Free + make offers with full terms (amount, interest, late fee, schedule) |
| 🟣 **Pro** *(subscription)* | Everything in Lender + suggest terms when posting a request (interest, late fee, schedule) + priority visibility + improved matching |

Users pay to unlock offer-making (Lender), and pay more to also unlock posting leverage (Pro). A single `subscription_plan` enum drives all of it — there is no separate "Premium Borrower" product, and no "posting add-on" sold independently of a plan.

Nipanze does **not** earn interest margins, custody fees, lending spreads, or any fee tied to loan performance.

---

## Transparency & Controlled Contact

Nipanze is **transparent before matching and controlled by design**. Requests show enough structured information for potential lenders to make informed decisions, while personal contact details remain protected until the request owner accepts an offer, and exact offer terms remain protected until a viewer has skin in that specific deal.

Contact details are revealed **only after an offer is accepted** — enforced at the API layer, not just the UI.

### Request Structure

Each request must include:

- **Loan details:** request title, amount needed, duration, purpose, and district
- **Source of income:** salary, business income, side income, or other repayment source
- **Repayment preference:** weekly, monthly, or one-time payment
- **Repayment ability:** amount payable per period and repayment timeline

Example: "I earn 800,000 UGX monthly and can repay 200,000 UGX per month."

Free-plan requests do **not** carry interest rate, late payment fee, or repayment schedule — lenders set all terms in their offers.

Pro-plan requests can additionally suggest a preferred interest rate, late payment fee, and repayment schedule. These are **locked on publish** and give the request extra negotiating leverage when offers come in.

### Selective Transparency Model

Listing detail pages use **tiered visibility**, not a single public/private split. Every visitor sees enough to gauge how competitive a request is; only people with skin in that specific deal see its exact offer terms.

| Viewer | What they see on a listing |
|---|---|
| **Visitor / any logged-in user browsing** | Funded % (progress bar), number of offers, an aggregate coverage tier (e.g. "high interest" for many/large offers vs "low interest" for few/small ones), and the full request summary (amount needed, purpose, district, duration, income source category, repayment plan) |
| **Lender/Pro-plan holder who has not offered on this listing** | Same as a visitor — full offer-level detail stays locked until they place an offer on this specific request |
| **Offer-maker who has placed an offer on this listing** | Everything a visitor sees, **plus** the exact amount, interest rate, late fee, and repayment schedule of every offer on this listing — their competitive position against other offer-makers |
| **Request owner** | Full detail on every offer submitted to their request: exact amount, interest rate, late fee, repayment schedule, and offer timestamp |

Contact details stay locked for everyone, at every tier, until a contract is generated and unlock is confirmed — that boundary is unchanged by this model; selective transparency only governs *offer terms*, not identity.

**Why tiered instead of fully public or fully locked:**

- **Fully public exact terms** invite copy-bidding — offer-makers underpricing each other by a token amount without doing their own risk assessment — and lets outside parties reverse-engineer a request owner's negotiating position without ever participating
- **Fully locked terms** remove the transparency lenders need to size up how competitive a listing already is, which discourages offers entirely
- **Tying full offer detail to participation** (having bid, or owning the request) rewards engagement, keeps competition healthy, and gives the platform a natural nudge toward the Lender plan — "Place an offer to see full bid detail on this listing"

This is enforced at the RPC/RLS layer (see [`get_public_listing_offers`](#key-functions-and-triggers) and the `v_lender_offers` view below), not just hidden in the UI.

### Field Masking Rules

#### Public Loan Listing (`v_loan_listings` view)

**Exposed:** `request_id`, `title`, `purpose`, `district`, `duration_months`, `requested_amount`, `preferred_repayment_plan`, `repayment_amount_per_period`, `repayment_timeline`, `number_of_offers`, `offer_coverage_tier`, `listed_at`, `expires_at`

**Masked before acceptance:** request-owner id, income source, employer/salary details, email, phone, full name, national ID, and private verification documents

`offer_coverage_tier` is a derived, anonymized signal (e.g. `low` / `medium` / `high`) computed server-side from the number and size of offers on a listing — it lets any visitor gauge how competitive a request is without exposing any individual offer's exact terms.

#### Offers (`v_lender_offers` view) — participant-gated detail

**Exposed only to the request owner and to offer-makers who have themselves placed an offer on that same request:** offer amount, interest rate, late payment fee, repayment schedule, timestamp

**Exposed to everyone, including non-participants:** total number of offers on the listing, and the aggregate `offer_coverage_tier` described above

Offer amounts can be full or partial. For example, a UGX 9M request can receive one UGX 9M offer, a UGX 5M offer, and a UGX 3M offer from different offer-makers — but a non-participant viewing that listing only sees "3 offers, high coverage," not the individual figures.

**Masked before acceptance, for everyone:** offer-maker's name, email, phone, and private verification documents

#### Post-Acceptance Contact Sharing

Revealed only after the request owner accepts an offer and confirms unlock: legal name, phone, and email.

### Platform Boundary

Nipanze helps participants discover each other and make informed matching decisions. It does not handle money, track repayments, guarantee repayment, or manage the relationship after contact details are revealed.

---

## How It Works

```
1. POST       → Anyone posts a structured loan request for free
2. BROWSE     → Anyone browses requests for free; sees funded %, offer count, and coverage tier
3. OFFER      → Lender/Pro plan holders make offers with their own amount, interest rate, late fee, and repayment schedule
                 → Placing an offer unlocks full offer-level detail on that listing for that offer-maker
4. REVIEW     → Request owner compares available offers with full exact-term detail
5. ACCEPT     → Request owner selects one offer; contract is auto-generated
6. UNLOCK     → Contact details are revealed only after contract unlock
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
│   ├── positions/                  # My Requests · My Offers (same account, two views)
│   ├── account/                    # Subscription plan, profile, verification
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
│   ├── schema.sql                  # Full schema v4.1 — tables, triggers, RPCs, views
│   └── seed.sql                    # Seed data v2.1 — users, listings, and offers
supabase/
│   └── migrations/                 # Incremental migrations applied on top of schema.sql
assets/
    ├── fonts/                      # DM Sans (body) + DM Mono (numeric values)
    └── images/                     # Onboarding illustrations
```

> Note: `features/loans` and `features/offers` are named after the *actions* they support (posting a request, making an offer), not after a stored role — any user with the right plan can reach either.

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
| `/loans/create` | LoanCreatePage | Yes (Free plan and up) |
| `/loans/my-loans` | MyRequestsPage | Yes |
| `/offers` | MyOffersPage | Yes (Lender/Pro plan) |
| `/notifications` | NotificationsPage | Yes |
| `/kyc` | KycPage | Yes |
| `/profile` | ProfilePage | Yes |
| `/admin` | AdminDashboardPage | Yes (`is_admin`) |

---

## Database Schema

The full schema lives in `sql/schema.sql` (v4.1). It defines all tables, triggers, functions, views, indexes, and seed `system_settings` in a single deployable file. Apply with:

```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -f sql/schema.sql
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -f sql/seed.sql
```

### Tables (v4.1)

| Table | Purpose |
| --- | --- |
| `profiles` | Core user profile. Extends `auth.users` 1-to-1. One account, no stored role — capability comes from `subscription_plan`. |
| `system_settings` | Platform config. Business limits read from here at runtime. |
| `subscriptions` | `subscription_plan` enum (`free` \| `lender` \| `pro`) — gates offer-making and term-suggestion. Posting and browsing remain free. |
| `kyc_verifications` | Optional verification and admin review. |
| `loan_requests` | Structured funding requests with amount, duration, purpose, income source, and repayment plan. |
| `loan_offers` | Offers made on requests. Exact terms visible only to the request owner and to other offer-makers on the same request; contact details stay hidden until acceptance. |
| `watchlist` | User-saved listings. |
| `contact_reveals` | Post-acceptance contact sharing. Logged in `audit_logs`. |
| `notifications` | In-app notification feed. |
| `audit_logs` | **Append-only** compliance trail. Never update or delete rows. |
| `refresh_tokens` | JWT refresh token store with rotation chain. |
| `referrals` | Referral programme tracking. |

> The `role` column (`borrower` / `lender` / `both`) has been removed from the schema. All marketplace gating reads `subscription_plan` only; `is_admin` remains the sole stored role.

### Key Functions and Triggers

| Name | Type | Purpose |
| --- | --- | --- |
| `handle_new_auth_user()` | Trigger fn | Syncs `auth.users` → `public.profiles` |
| `accept_offer(request_id, offer_id, owner_id)` | RPC | Atomic offer acceptance + contact eligibility |
| `get_public_listing_offers(request_id)` | RPC | Anonymized public offer book for active listings — returns aggregate coverage tier and offer count only; exact per-offer terms are omitted unless the caller is the request owner or has an offer on that request |

### Key Views

| View | Purpose |
| --- | --- |
| `v_loan_listings` | Public marketplace listings with request-owner contact details excluded, offer detail rolled up into `number_of_offers` + `offer_coverage_tier` |
| `v_user_marketplace_activity` | Dashboard — requests posted and offers made, in one query |
| `v_lender_offers` | Offer activity for the current account, and — when the account is the request owner or an offer-maker on that request — the exact terms of every offer on that listing |
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
| `percent_indicator ^4.x` | Request progress and offer coverage indicators | 2 |
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
| `make-offer` | Server-side subscription-plan validation for offers |
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

All accounts are pre-loaded by `sql/seed.sql` v2.1 with fixed UUIDs and `email_confirmed_at` set.
**Password for all accounts: `Test1234!`**

The `role` column has been removed — accounts below are described purely by activity and `subscription_plan`, matching the unified model.

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
- **Plan checked server-side** — `subscription_plan` is validated in RLS/RPCs, never trusted from the client
- **JWT auth** — Supabase issues short-lived JWTs; sessions auto-refresh
- **Service role key never in client** — only used inside Edge Functions
- **Controlled contact sharing** — contact details stay hidden until acceptance
- **Selective offer-term transparency** — exact offer amounts, rates, and fees are gated to the request owner and to offer-makers who have bid on that listing; everyone else sees an aggregate coverage tier only
- **Append-only audit log** — `audit_logs` has no UPDATE/DELETE in app user grants
- **Private documents** — verification documents are never exposed in marketplace listings
- **Refresh token rotation** — reuse attack detection via `replaced_by` chain
- **`--dart-define` credentials** — Supabase keys injected at build time, not hardcoded

---

## Regulatory Compliance

> Nipanze operates as a technology marketplace. We do not hold funds, accept deposits, issue loans, pool capital, or set interest rates.

**We DO:** Provide marketplace infrastructure, show requester-provided information, manage controlled contact sharing, and facilitate discovery.

**We DO NOT:** Accept deposits, hold or pool user funds, issue loans, set interest rates, guarantee returns, act as a bank or financial institution, process payments, or track repayments.

All money movement, loan documentation, and repayment tracking happen directly between matched participants outside the platform.

---

## Roadmap

See [BUILD_PLAN.md](BUILD_PLAN.md) for the full, authoritative stage-by-stage roadmap.

### Stage 1 — Foundation ✅ Complete
- Schema v4.0, seed data, Flutter scaffold, auth, navigation, onboarding, unit + integration tests

### Stage 2 — Core Marketplace ✅ Complete
- Live marketplace feed, structured requests, free browsing, lender-proposed offer terms, subscription-gated offers, offer acceptance

### Stage 3 — Polish & Supporting Features ✅ Complete
- Watchlist alerts, positions, notifications, analytics, profile, error/empty states

### Stage 3.5 — Cloud Migration & Auth Hardening ✅ Complete
- Supabase Cloud, RLS audit, token rotation, APK release build

### Stage 4 — Structured Deal Agreement & Contact Sharing ⬜ Planned (revised for unified model)
- Locked-term bidding: Pro-plan users suggest interest rate, late fee, and repayment schedule at posting; Lender/Pro-plan users set their own terms at offer time; both locked on submission
- Selective transparency: listing detail shows funded %, offer count, and coverage tier to everyone; exact offer terms unlock only for the request owner and for offer-makers who have bid on that listing
- Contract auto-generated after offer acceptance with all agreed terms + legal disclaimer
- Contact reveal only after contract is generated and unlock is confirmed
- `role` column fully removed from schema; all gating reads `subscription_plan` only

### Stage 5 — Admin & Compliance ⬜ Planned
- Admin dashboard, verification review, audit trails, SMS

### Stage 6 — Launch & Growth ⬜ Planned
- Play Store, App Store, referral programme, subscription growth (no role-selection onboarding step)

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