# Nipanze — Flutter + Supabase

## A Non-Custodial Digital Lending Matchmaking Marketplace, Built for the East African Community from the Ground Up

> Nipanze is a peer-to-peer financial marketplace that connects people who need money with people willing to lend, through structured requests, offers, and controlled contact sharing — without a bank, custodian, or intermediary holding any funds. Launching in Uganda, architected on one shared schema to expand across the full **East African Community** — Kenya, Tanzania, Rwanda, Burundi, South Sudan, DR Congo, and Somalia — without a redesign.

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
- [Multi-Country Architecture](#multi-country-architecture)
- [Key Features](#key-features)
- [Business Model](#business-model)
- [Transparency & Controlled Contact](#transparency--controlled-contact)
- [Trust & Reputation Signals](#trust--reputation-signals)
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

As of v5.0, Nipanze also runs on a **single shared database across every East African Community (EAC) country it operates in**, rather than a separate database or table set per market. A user's marketplace defaults to their own country; posting, browsing, offers, and trust signals all carry a `country` value that's enforced at the data layer, not just filtered in the UI. See [Multi-Country Architecture](#multi-country-architecture) for how this works and why it was built this way instead of per-country tables.

Nipanze does **not** hold funds, accept deposits, issue loans, pool capital, guarantee repayment, track repayments, or act as a financial institution, in any market it operates in. It simply helps financial requests and offers meet through structured discovery, matching, and controlled connection.

Posting a request is free for everyone. Making offers requires the **Lender** plan. Suggesting preferred terms on a posted request requires the **Pro** plan. Contact details remain hidden until a contract is generated after an offer is accepted. Listing detail itself uses **tiered visibility** — see [Transparency & Controlled Contact](#transparency--controlled-contact) — so exact offer terms are only visible to the request owner and to other offer-makers competing on that same listing.

**Core Principle:** One marketplace per country, one shared platform underneath. Capability comes from your subscription plan; your default feed comes from your country — neither is a fixed identity baked into separate infrastructure.

---

## Problem Statement

Across Uganda and the wider East African Community, access to affordable capital faces critical barriers:

- **Long bank procedures:** Formal approvals can take too long for urgent needs
- **Lack of collateral:** Many people needing funds cannot meet traditional security requirements
- **Limited financial history:** Thin credit files exclude people with real repayment ability
- **High interest rates:** People needing funds lack flexible, competitive alternatives
- **Limited visibility:** People willing to lend struggle to find requests and assess repayment ability
- **Weak lending structure:** Informal lending lacks a reliable marketplace for discovery, offers, and connection
- **Fragmented markets:** Cross-border and diaspora lending relationships already exist informally across the region (Ugandans, Kenyans, Rwandans, and others abroad funding family back home) but have no structured platform to happen on safely

Many lending options still focus on collateral and institutional gatekeeping instead of giving people a structured way to show income, intent, and repayment plans — and almost none are built to serve more than one country without becoming a different product per market.

---

## Solution

Nipanze provides a single marketplace structure — replicated per country on shared infrastructure — where:

- Anyone can publish a structured funding request for free, in their own country's market and currency
- Every request includes loan details, source of income, loan purpose, and repayment ability
- Anyone can browse listed requests for free, defaulting to their own country with the option to browse other active EAC markets
- Making an offer requires the Lender plan; the offer carries the offer-maker's own amount, interest/return expectation, and terms, in the request's currency
- The request owner reviews available offers and accepts the one that fits
- Contact details are revealed only after the request owner accepts an offer
- Both parties connect outside the platform
- The platform supports discovery, matching, and controlled contact sharing — nothing more, in every market it serves

**We are not a lender. We are a matchmaking marketplace — one product, one region, many countries.**

---

## The Unified Marketplace Model

Nipanze moved away from a role-based design (`borrower` / `lender`) to a **unified, action-based** model. This section is the source of truth for how capability works across the app — see [BUILD_PLAN.md](BUILD_PLAN.md) for the full rationale and migration history.

### The decision

- One interface for every user — no separate borrower/lender screens or signup paths
- No `role` column stored on the account
- Users choose a **subscription plan**, not an identity
- The same person can post a request *and* make offers, at any time, from the same login, in any country their account belongs to

### Single entry point after login

Every user lands on the same dashboard:

1. **Marketplace** — all loan listings for the user's active country, same feed structure for everyone
2. **Post Request** — always visible, Free tier and up
3. **Offers Panel** — offers *received* on your requests, and (if your plan allows) offers *you've made* on others' requests

There is no "select your role" step anywhere in the app. A user simply acts:

- Clicks **Post Request** → acting as the request owner for that listing
- Clicks **Make Offer** → acting as the offer-maker for that listing

### Feature access by plan

| Plan | Access |
|---|---|
| 🟢 **Free** | Post basic loan requests (amount, duration, purpose) · Browse marketplace · Accept received offers · Watchlist, Positions, Notifications, KYC · Full visibility into public trust signals on every profile · ❌ Cannot make offers · ❌ Cannot suggest terms when posting |
| 🔵 **Lender** | Everything in Free, **plus**: make offers on any listing (in-country or cross-border, see [Multi-Country Architecture](#multi-country-architecture)) · set interest rate, late payment fee, and repayment schedule on offers |
| 🟣 **Pro** | Everything in Lender, **plus**: suggest terms when posting a request (interest rate, late fee, repayment schedule) · priority visibility for posted requests · improved matching · Verified badge · advanced trust insights |

No plan is ever labeled "Borrower Plan" or "Lender-only," and no plan is country-specific — a single `subscription_plan` applies to the account regardless of which country's marketplace they're viewing. Each plan name describes the *unlocked capability*, not the person holding it. A single user can hold only **one** `subscription_plan` at a time (`free | lender | pro`), and Pro is a strict superset of Lender, which is a strict superset of Free.

### The one exception: `is_admin`

`is_admin` is a true role, separate from the subscription plan, since it governs platform moderation rather than marketplace participation. It is the **only** role in the system, and admin access spans every country.

---

## Multi-Country Architecture

Nipanze runs on **one shared Supabase database and one set of tables for every EAC country it operates in** — not a separate database, project, or table set per market. This section explains the design and why. Full schema-level detail lives in [BUILD_PLAN.md](BUILD_PLAN.md#-multi-country-expansion-model-v50).

### Scope: all eight EAC member states

| Country | Code | Currency | Phone Prefix |
|---|---|---|---|
| 🇺🇬 Uganda | `UG` | UGX | `+256` |
| 🇰🇪 Kenya | `KE` | KES | `+254` |
| 🇹🇿 Tanzania | `TZ` | TZS | `+255` |
| 🇷🇼 Rwanda | `RW` | RWF | `+250` |
| 🇧🇮 Burundi | `BI` | BIF | `+257` |
| 🇸🇸 South Sudan | `SS` | SSP | `+211` |
| 🇨🇩 DR Congo | `CD` | CDF | `+243` |
| 🇸🇴 Somalia | `SO` | SOS | `+252` |

All eight are seeded in the `countries` table from the Stage 4.5 migration onward. Uganda is the only market with `is_active = TRUE` at launch; the other seven activate independently as each clears its own pricing, payment-rail coverage, and compliance review — see [Roadmap](#roadmap). Seeding all eight up front means the country picker, admin per-country settings, and currency-formatting logic never need a schema change to support a market that hasn't launched yet.

### Why one shared schema, not one per country

A per-country table design (`loan_requests_uganda`, `loan_requests_kenya`, …) was considered and rejected: it would multiply every RLS policy, trigger, view, and RPC in this schema by the number of countries, turn cross-market admin reporting into a UNION query across up to eight tables, and make launching a new country a migration project instead of a one-row data insert. Instead:

- **One `countries` reference table** (`code`, `name`, `currency_code`, `phone_prefix`, `is_active`) — adding a new market is one row insert (already done for all eight); *launching* a market is one `UPDATE ... SET is_active = TRUE`
- **`profiles.country` and `loan_requests.country`** — indexed, non-nullable columns that make every user and every listing's market explicit and queryable
- **`loan_offers` has no country of its own** — an offer's country is always its parent request's country, read through the join, so there's exactly one source of truth for "what market is this offer in," not one that can drift out of sync across eight markets

### How filtering works

A user's marketplace feed defaults to their own `profiles.country`. A Kenyan user sees Kenyan listings by default; a Rwandan user sees Rwandan listings by default — and so on for all eight markets. This is enforced at the application query layer (`MarketplaceRepository` filters `v_loan_listings WHERE country = :userCountry`), with an explicit, user-initiated option to browse other active markets — a deliberate choice over hard per-country RLS isolation, because diaspora and cross-border lending (funding a family request back home from elsewhere in the region) is a real, valuable use case this design wants to support rather than block. The RLS-level "hard isolation" alternative is fully specified in BUILD_PLAN.md if product direction changes later — it's a policy change, not a rearchitecture.

### Currency travels with country

Every monetary figure in the schema (`requested_amount`, `offer_amount`, etc.) is a plain number with no currency of its own — it is only meaningful next to its row's `country → countries.currency_code`. Nipanze does not convert between currencies or compare amounts across markets; each listing is always shown in its own market's currency, whether that's UGX, KES, TZS, RWF, BIF, SSP, CDF, or SOS.

### What stays global regardless of country

Public trust signals (rating, review count, completed-deal count, badges) reflect a user's **entire on-platform history across every market**, not a per-country reset — a lender's track record follows them whether they're browsing Kenya for the first time or their tenth deal in Uganda. See [Trust & Reputation Signals](#trust--reputation-signals).

### Launching a new market

Adding a country requires **no schema migration** — all eight are already seeded. Launching one is: flip `countries.is_active` to `TRUE`, finalize that market's `system_settings` overrides (min/max loan amount, listing duration, etc.) and local-currency subscription pricing, confirm payment-rail coverage with the chosen aggregator for that specific country, and localize KYC document-type expectations at the app layer. Rail coverage and regulatory readiness are **not uniform across the region** — Uganda, Kenya, Tanzania, and Rwanda have the most mature mobile-money coverage today; Burundi, South Sudan, DR Congo, and Somalia need dedicated per-market verification before activation. See [BUILD_PLAN.md](BUILD_PLAN.md) Stage 4.5 and Stage 6 for the full migration and per-market launch checklist.

---

## Key Features

### Posting a Request (Free plan and above)

- **Free access** — post loan requests without paying to list, in any active EAC market
- **Structured requests** — title, amount, duration, purpose, district, income source, and repayment ability
- **Repayment visibility** — show the marketplace how the loan will be repaid
- **Flexible outcomes** — receive and compare offers from multiple lenders
- **My Requests** — track posted requests and responses in one place (Positions tab)
- **Controlled contact** — personal contact details stay hidden until an offer is accepted

### Making Offers (Lender plan and above)

- **Free browsing** — review requests before subscribing to the Lender plan
- **Repayment context** — assess loan purpose, requested amount, duration, and repayment plan
- **My Offers** — manage offer activity in one place (Positions tab)
- **Custom terms** — offer your own amount, interest rate, late payment fee, and repayment schedule (locked on submit), denominated in the listing's currency
- **Cross-border capital** — offer on listings outside your home country, subject to the platform's current cross-border policy (see [BUILD_PLAN.md](BUILD_PLAN.md))
- **Return potential** — fund selected requests directly

### Suggesting Terms (Pro plan)

- **Negotiating leverage** — suggest a preferred interest rate, late payment fee, and repayment schedule when posting a request (locked on publish)
- **Priority visibility** — Pro-posted requests get improved placement and matching, in whichever market they're posted

### Platform Features

- **Free posting** — anyone can create a request without a listing fee, in any active market
- **Free browsing** — anyone can browse requests before subscribing, defaulting to their own country
- **Subscription-gated offers** — making offers requires an active Lender (or Pro) plan, independent of country
- **Locked bidding** — both suggested posting terms and offer terms are locked on submission; no post-publish edits
- **Contract generation** — a digital contract is auto-generated when a request owner accepts an offer
- **Single account, one dashboard** — every user posts and offers from the same account and screen, in every country their profile belongs to
- **Marketplace main screen** — live feed of requests with amount, purpose, district, repayment plan, and currency
- **Non-custodial architecture** — Nipanze never holds, pools, or moves user funds, anywhere
- **Controlled contact sharing** — contact details are revealed only after a contract is generated
- **Selective transparency** — listing detail shows aggregate signals (funded %, offer count, coverage tier) to everyone, but exact offer terms unlock only for the request owner and for offer-makers who have themselves bid on that listing
- **Public trust signals** — rating, review count, completed-deal count, repeat-participant badge, and phone-verification status are visible on every profile, free, regardless of plan or country — see [Trust & Reputation Signals](#trust--reputation-signals)
- **Pro Advanced Filters** — Pro-tier users can use advanced filters (categorical employment type, bucketed income range, suggested-terms, owner KYC verification status) next to the notification bell, with database-level self-gating
- **Compliance built-in** — append-only audit trail from day one

---

## Business Model

Nipanze generates revenue primarily through subscriptions — not interest spreads — via a single upgrade path, applied consistently across every EAC market it operates in. A small, clearly-disclosed contact-unlock fee is under consideration as a secondary revenue lever; see [Trust & Reputation Signals](#trust--reputation-signals) for how it would fit alongside subscriptions without becoming a fee tied to loan performance.

| Plan | Unlocks |
|---|---|
| 🟢 **Free** | Post basic requests (amount, duration, purpose) · browse · accept offers received · full visibility into every counterparty's public trust signals |
| 🔵 **Lender** *(subscription)* | Everything in Free + make offers with full terms (amount, interest, late fee, schedule) |
| 🟣 **Pro** *(subscription)* | Everything in Lender + suggest terms when posting a request (interest, late fee, schedule) + priority visibility + improved matching + verified badge + advanced trust insights |

Users pay to unlock offer-making (Lender), and pay more to also unlock posting leverage and stronger trust signaling (Pro). A single `subscription_plan` enum drives all of it — there is no separate "Premium Borrower" product, and no "posting add-on" sold independently of a plan. The plan tiers and what they unlock are identical across every market; only the **price** is localized.

**Subscription pricing is set per country**, reflecting local willingness-to-pay — a UGX price is never simply copy-pasted as the same numeral in KES, TZS, or any other EAC currency. `subscriptions.amount_minor_units` is currency-agnostic on its own and only meaningful alongside the subscriber's `profiles.country`. Pricing for each market is finalized closer to that market's own Stage 6 launch, not assumed from another market's figures.

Nipanze does **not** earn interest margins, custody fees, lending spreads, or any fee tied to loan performance, in any market. Any future contact-unlock fee is a flat, disclosed marketplace-access fee — never priced off a deal's interest rate, amount, or outcome.

**Payments (Stage 6):** subscription charges (and, if adopted, the contact-unlock fee) are processed via Flutterwave or a comparable regional aggregator, covering mobile money and cards across each active market. This is scoped **strictly to Nipanze's own revenue** — it never touches money between a borrower and a lender, which stays off-platform per the non-custodial model above. Rail coverage varies by country, so each market's aggregator support is verified before that market's `is_active` flag is flipped, rather than assumed from a neighboring market's success. See [BUILD_PLAN.md](BUILD_PLAN.md#-payments-infrastructure-flutterwave--scoped-addendum) for the `transactions` table design and webhook-verification requirements.

---

## Transparency & Controlled Contact

Nipanze is **transparent before matching and controlled by design**, in every country it operates in. Requests show enough structured information for potential lenders to make informed decisions, while personal contact details remain protected until the request owner accepts an offer, and exact offer terms remain protected until a viewer has skin in that specific deal.

Contact details are revealed **only after an offer is accepted** — enforced at the API layer, not just the UI.

### Request Structure

Each request must include:

- **Loan details:** request title, amount needed, duration, purpose, and district
- **Source of income:** salary, business income, side income, or other repayment source
- **Repayment preference:** weekly, monthly, or one-time payment
- **Repayment ability:** amount payable per period and repayment timeline

Example: "I earn 800,000 UGX monthly and can repay 200,000 UGX per month." (Or the equivalent in KES, TZS, RWF, BIF, SSP, CDF, or SOS, depending on the request owner's country.)

Free-plan requests do **not** carry interest rate, late payment fee, or repayment schedule — lenders set all terms in their offers.

Pro-plan requests can additionally suggest a preferred interest rate, late payment fee, and repayment schedule. These are **locked on publish** and give the request extra negotiating leverage when offers come in.

### Selective Transparency Model

Listing detail pages use **tiered visibility**, not a single public/private split. Every visitor sees enough to gauge how competitive a request is; only people with skin in that specific deal see its exact offer terms. This tiering logic is identical in every country — only the currency label attached to the numbers changes.

| Viewer | What they see on a listing |
|---|---|
| **Visitor / any logged-in user browsing** | Funded % (progress bar), number of offers, an aggregate coverage tier (e.g. "high" for many/large offers vs "low" for few/small ones), and the full request summary (amount needed, purpose, district, duration, income source category, repayment plan) — in the listing's own currency |
| **Lender/Pro-plan holder who has not offered on this listing** | Same as a visitor — full offer-level detail stays locked until they place an offer on this specific request |
| **Offer-maker who has placed an offer on this listing** | Everything a visitor sees, **plus** the exact amount, interest rate, late fee, and repayment schedule of every offer on this listing — their competitive position against other offer-makers |
| **Request owner** | Full detail on every offer submitted to their request: exact amount, interest rate, late fee, repayment schedule, and offer timestamp |

Contact details stay locked for everyone, at every tier, until a contract is generated and unlock is confirmed — that boundary is unchanged by this model or by which country the listing is in; selective transparency only governs *offer terms*, not identity.

Public trust signals (rating, review count, deal count, badges) are a separate, always-public layer that sits on top of this model — see below. They are not gated by participation the way exact offer terms are, because withholding basic reputation information would undermine trust marketplace-wide rather than protect any one deal.

**Why tiered instead of fully public or fully locked:**

- **Fully public exact terms** invite copy-bidding — offer-makers underpricing each other by a token amount without doing their own risk assessment — and lets outside parties reverse-engineer a request owner's negotiating position without ever participating
- **Fully locked terms** remove the transparency lenders need to size up how competitive a listing already is, which discourages offers entirely
- **Tying full offer detail to participation** (having bid, or owning the request) rewards engagement, keeps competition healthy, and gives the platform a natural nudge toward the Lender plan — "Place an offer to see full bid detail on this listing"

This is enforced at the RPC/RLS layer (see [`get_public_listing_offers`](#key-functions-and-triggers) and the `v_lender_offers` view below), not just hidden in the UI.

### Field Masking Rules

#### Public Loan Listing (`v_loan_listings` view)

**Exposed:** `request_id`, `title`, `purpose`, `district`, `country`, `currency_code`, `duration_months`, `requested_amount`, `preferred_repayment_plan`, `repayment_amount_per_period`, `repayment_timeline`, `number_of_offers`, `offer_coverage_tier`, `listed_at`, `expires_at`

**Masked before acceptance:** request-owner id, income source, employer/salary details, email, phone, full name, national ID, and private verification documents

`offer_coverage_tier` is a derived, anonymized signal (e.g. `low` / `medium` / `high`) computed server-side from the number and size of offers on a listing — it lets any visitor gauge how competitive a request is without exposing any individual offer's exact terms.

#### Offers (`v_lender_offers` view) — participant-gated detail

**Exposed only to the request owner and to offer-makers who have themselves placed an offer on that same request:** offer amount, interest rate, late payment fee, repayment schedule, timestamp — always shown alongside the listing's `currency_code`, never a bare number

**Exposed to everyone, including non-participants:** total number of offers on the listing, and the aggregate `offer_coverage_tier` described above

Offer amounts can be full or partial. For example, a UGX 9M request can receive one UGX 9M offer, a UGX 5M offer, and a UGX 3M offer from different offer-makers — but a non-participant viewing that listing only sees "3 offers, high coverage," not the individual figures. The same logic applies identically to a KES, TZS, RWF, BIF, SSP, CDF, or SOS request.

**Masked before acceptance, for everyone:** offer-maker's name, email, phone, and private verification documents

#### Post-Acceptance Contact Sharing

Revealed only after the request owner accepts an offer and confirms unlock: legal name, phone, and email — regardless of country.

### Platform Boundary

Nipanze helps participants discover each other and make informed matching decisions, in whichever EAC market they're in. It does not handle money, track repayments, guarantee repayment, or manage the relationship after contact details are revealed, anywhere.

---

## Trust & Reputation Signals

Selective transparency (above) governs *deal terms*. Trust & reputation signals are a separate, always-public layer that governs *counterparty credibility* — independent of both deal-term visibility and country. They exist so a request owner or offer-maker can gauge who they're dealing with before ever placing an offer or accepting one, without waiting on participation, and without a trust profile resetting at a border.

**Design rule: reputation is public infrastructure, verification and insight depth are monetized.** Hiding basic trust signals behind a paywall would suppress activity marketplace-wide — new users need to see that a marketplace has real, credible participants before they'll post a request or risk an offer. So the baseline signals below are visible on every profile to every viewer, on every plan, in every market, including logged-out browsing of the public marketplace feed where applicable.

### A user's trust profile is global, not per-country

**A user's trust profile spans every EAC market they've participated in — it does not reset at a border.** A lender who has completed nine deals in Uganda and is browsing Kenyan listings for the first time shows up with their real track record, not a blank slate. See [Multi-Country Architecture](#multi-country-architecture) for the schema rationale (`trust_aggregates` is one row per user, never one row per user per country).

### What Nipanze can and cannot show

Because Nipanze does not track repayments or hold funds (see [Regulatory Compliance](#regulatory-compliance)), every trust signal below is built only from **events that happen on-platform** — requests posted, offers made, contracts generated, and reviews left by a counterparty after a deal — never from off-platform financial behavior Nipanze has no visibility into, in any country. Nipanze does not claim to know, measure, or display whether a loan was actually repaid.

### Public trust signals (Free — visible to everyone, on every profile, in every market)

| Signal | Source | Notes |
|---|---|---|
| ⭐ Rating average + review count | Post-deal reviews left by the other party to a completed contract, across all countries | Only the counterparty on a completed deal can leave a review; one review per contract |
| 📊 Completed deals count | Count of contracts the account has been a party to (as owner or offer-maker), across all countries | Reflects on-platform activity, not repayment outcome |
| 🔁 Repeat participant badge | Awarded after a second completed deal, anywhere in the region | Signals an account is an active, returning marketplace participant |
| 📱 Phone verified badge | OTP verification at signup, tracked in `profiles.phone_verified_at` | Free, lightweight — distinct from full KYC |
| ⏱️ Typical response time | Rolling median time-to-first-action on offers/requests received | Computed server-side; shown as a bucket (e.g. "Responds quickly"), never an exact timestamp pattern |

These render as compact badges on `ListingCard`, the offers panel, and `ProfilePage` — never gated behind a plan check, and never listed as a pricing-table line item, so a Free user browsing the marketplace never has to guess whether a badge is locked.

### Pro-tier trust enhancements (monetized layer)

Pro does not create new trust data that Free users can't see the shape of — it adds **verification weight** and **analytical depth** on top of the same public signals:

| Enhancement | Plan | Description |
|---|---|---|
| 🟦 Verified badge | Pro | Awarded after full KYC review (existing `kyc_verifications` flow, using the country-appropriate national ID or document type), distinct from and stronger than the free phone-verified badge |
| 📊 Offer/request success rate | Pro (on their own profile, and on any counterparty profile they view) | Share of an account's offers accepted, or requests that reached a contract, computed from on-platform events across all markets |
| 🚀 Priority visibility | Pro | Pro-posted requests and Pro offer-maker profiles get improved placement, in whichever market they're posted or offering — already part of the existing Pro tier |
| 🔍 Reliability score | Pro | A single derived score combining rating, completion count, and response time, shown only to Pro viewers looking at a counterparty |

Advanced insights are explicitly scoped to **on-platform** behavior (ratings, completion counts, response time) rather than claims about real-world repayment, to stay inside the platform boundary in [Regulatory Compliance](#regulatory-compliance). Nipanze does not display or compute anything resembling a "repayment reliability" score based on off-platform loan performance, since that data never reaches the platform, in any country.

### Reviews

- A review can only be left by the counterparty on a **completed contract** (one review per contract, per direction)
- Reviews are a star rating (1–5) plus optional short text
- Reviews are immutable once submitted and logged to `audit_logs`, consistent with the append-only audit approach used elsewhere
- Review content is moderated the same way KYC documents are — visible to admins for abuse review, never edited by the platform

### Contact-unlock fee (proposed secondary revenue lever — not yet committed)

Feedback from early product review suggested a small, flat contact-unlock fee (a few thousand UGX or the local-currency equivalent) charged at the moment contact is revealed, on top of the subscription model, with a free or discounted unlock for Pro. This is **not yet part of the committed architecture** described elsewhere in this document, and is flagged here rather than folded silently into the Business Model or contract-reveal flow, because it changes two things that are currently stated as fixed:

1. **"Revenue via subscriptions only"** (see [Business Model](#business-model)) would need to become "subscriptions plus a flat, disclosed contact-unlock fee"
2. **Contact reveal today is a status-gated action** (request owner accepts → both parties can unlock), not a paid action — adding a fee means `reveal_contact` needs a payment-confirmation step before the existing unlock logic runs

If adopted, the fee must stay flat and disclosed up front, in each market's own local currency (never a percentage of loan amount, interest rate, or any deal-performance figure), to remain consistent with the "no fee tied to loan performance" principle already stated in Business Model and Regulatory Compliance. This is tracked as a Stage 4 decision point in [BUILD_PLAN.md](BUILD_PLAN.md) rather than assumed here.

---

## How It Works

```
1. POST       → User posts a structured loan request for free, in their own country and currency
2. BROWSE     → Marketplace defaults to the user's country; browsing other active EAC markets is optional
                 → sees funded %, offer count, coverage tier, and counterparty trust signals
3. OFFER      → Lender/Pro plan holders make offers with their own amount, interest rate, late fee, and repayment schedule
                 → Placing an offer unlocks full offer-level detail on that listing for that offer-maker
4. REVIEW     → Request owner compares available offers with full exact-term detail and each offer-maker's trust signals
5. ACCEPT     → Request owner selects one offer; contract is auto-generated
6. UNLOCK     → Contact details are revealed only after contract unlock
7. CONNECT    → Parties proceed independently outside the platform
8. RATE       → Both parties may leave a one-time review on the completed contract, feeding the reviewee's global trust signal
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
| Database | Supabase Postgres | Relational data, RLS, triggers, functions — one shared schema for every EAC country |
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
│   ├── constants/                  # Tables, Views, Rpcs, Channels, SettingKeys, Countries
│   ├── errors/                     # AppException hierarchy, parseSupabaseError()
│   └── di/                         # Injectable config, GetIt locator
├── features/
│   ├── auth/                       # Login, Register, Verify Email, Reset Password, Onboarding (incl. country select)
│   ├── dashboard/                  # Home stub (redirects to marketplace post-login)
│   ├── marketplace/                # Live feed (v_loan_listings), country + other filters, loan detail, offers
│   ├── watchlist/                  # Saved listings, closing alerts
│   ├── positions/                  # My Requests · My Offers (same account, two views)
│   ├── account/                    # Subscription plan, profile, verification, country setting
│   ├── loans/                      # Create request, my requests
│   ├── offers/                     # My Offers page
│   ├── notifications/              # Notification centre, unread badge
│   ├── kyc/                        # Optional verification, status display, country-appropriate document types
│   ├── trust/                      # Trust badges, ratings, reviews, reputation summary (global, not per-country)
│   ├── profile/                    # User profile, edit
│   └── admin/                      # Verification review, user management, audit logs, per-country settings (admin only)
│       └── */
│           ├── data/               # DataSources (Supabase) + Models
│           ├── domain/             # Entities, UseCases, Repository interfaces
│           └── presentation/       # BLoC + Pages + Widgets
├── shared/
│   ├── models/                     # LoanListingModel, OfferModel, UserModel, TrustProfileModel, CountryModel…
│   └── widgets/                    # MainScaffold, ProfileSummary, VerificationChip, TrustBadgeRow, CurrencyLabel
supabase/
sql/
│   ├── schema.sql                  # Full schema — tables, triggers, RPCs, views (multi-country, all 8 EAC states, from v5.0)
│   └── seed.sql                    # Seed data — users, listings, offers (Uganda-only until Stage 4.5 seed additions)
│   └── migrations/                 # Incremental migrations, including the Stage 4.5 country migration
assets/
    ├── fonts/                      # DM Sans (body) + DM Mono (numeric values)
    └── images/                     # Onboarding illustrations
```

> Note: `features/loans` and `features/offers` are named after the *actions* they support (posting a request, making an offer), not after a stored role — any user with the right plan can reach either, in any country. `features/trust` renders the same badge row wherever a counterparty is shown (listing cards, offer rows, profile pages), and is deliberately country-agnostic.

---

## Screen / Route Map

| Route | Screen | Auth Required |
| --- | --- | --- |
| `/` | SplashPage | No |
| `/onboarding` | OnboardingPage (incl. country select) | No |
| `/auth/login` | LoginPage | No |
| `/auth/register` | RegisterPage | No |
| `/auth/verify-email` | VerifyEmailPage | Yes (unverified) |
| `/auth/forgot-password` | ForgotPasswordPage | No |
| `/marketplace` | MarketplacePage (tab 1) — defaults to user's country | Yes |
| `/marketplace/:requestId` | LoanDetailPage + Offers | Yes |
| `/watchlist` | WatchlistPage (tab 2) | Yes |
| `/positions` | My Requests + My Offers | Yes |
| `/account` | AccountPage (tab 4) — includes country setting | Yes |
| `/loans/create` | LoanCreatePage | Yes (Free plan and up) |
| `/loans/my-loans` | MyRequestsPage | Yes |
| `/offers` | MyOffersPage | Yes (Lender/Pro plan) |
| `/notifications` | NotificationsPage | Yes |
| `/kyc` | KycPage | Yes |
| `/profile` | ProfilePage | Yes |
| `/profile/:userId/reviews` | UserReviewsPage | Yes |
| `/admin` | AdminDashboardPage | Yes (`is_admin`) |

---

## Database Schema

The full schema lives in `sql/schema.sql`. Apply against the Supabase Cloud project (via Dashboard SQL Editor or `psql` with the cloud connection string):

```bash
psql "postgresql://postgres:<password>@<project-ref>.supabase.co:5432/postgres" -f sql/schema.sql
psql "postgresql://postgres:<password>@<project-ref>.supabase.co:5432/postgres" -f sql/seed.sql
```

### Tables

| Table | Purpose |
| --- | --- |
| `countries` | **New, v5.0.** Reference table: `code`, `name`, `currency_code`, `phone_prefix`, `is_active`. Seeded with all 8 EAC member states; launching a market is one `UPDATE ... SET is_active = TRUE`. |
| `profiles` | Core user profile. Extends `auth.users` 1-to-1. Carries `country` (source of truth for the account) and `phone_verified_at` for the free trust badge. One account, no stored role — capability comes from `subscription_plan`. |
| `system_settings` | Platform config, with an optional `country` column — `NULL` rows are global defaults, non-null rows override per market. |
| `subscriptions` | `subscription_plan` enum (`free` \| `lender` \| `pro`) — gates offer-making and term-suggestion; same plans in every country, priced per market via `amount_minor_units`. |
| `kyc_verifications` | Optional verification and admin review. Approval drives the Pro-tier "Verified" badge. |
| `loan_requests` | Structured funding requests, carrying `country` (copied from the borrower's profile at post time, locked thereafter). |
| `loan_offers` | Offers made on requests. **No `country` column** — always read via `request_id → loan_requests.country`. Exact terms visible only to the request owner and other offer-makers on the same request. |
| `watchlist` | User-saved listings. |
| `contact_reveals` | Post-acceptance contact sharing. Logged in `audit_logs`. |
| `notifications` | In-app notification feed. |
| `reviews` | One-time, post-contract star rating + optional text between the two parties to a completed contract. Feeds a user's **global** (not per-country) trust signals. |
| `audit_logs` | **Append-only** compliance trail. Never update or delete rows. |
| `refresh_tokens` | JWT refresh token store with rotation chain. |
| `referrals` | Referral programme tracking. |
| `transactions` | **Stage 6.** Flutterwave (or equivalent) payment records for subscriptions and contact-unlock fees only — never P2P loan funds. Carries `country` and `currency_code`, webhook-verified status transitions only. |

> The `role` column (`borrower` / `lender` / `both`) has been removed from the schema. All marketplace gating reads `subscription_plan` only; `is_admin` remains the sole stored role. `country` is present on `profiles` and `loan_requests` only — see [Multi-Country Architecture](#multi-country-architecture) for why `loan_offers` doesn't get its own copy.

### Key Functions and Triggers

| Name | Type | Purpose |
| --- | --- | --- |
| `handle_new_auth_user()` | Trigger fn | Syncs `auth.users` → `public.profiles` |
| `accept_offer(request_id, offer_id, owner_id)` | RPC | Atomic offer acceptance + contact eligibility |
| `get_public_listing_offers(request_id)` | RPC | Anonymized public offer book for active listings — returns aggregate coverage tier and offer count only; exact per-offer terms are omitted unless the caller is the request owner or has an offer on that request |
| `submit_review(contract_id, rating, comment)` | RPC | Records a one-time post-contract review from the calling account onto the counterparty; refreshes that counterparty's cached (global) trust aggregates |
| `recompute_trust_aggregates(user_id)` | Trigger fn | Recalculates rating average, review count, completed-deal count, and response-time bucket after a review or contract event, across all countries the user has participated in |
| `trg_fn_set_request_country` | Trigger fn (Stage 4.5) | Copies `country` from the borrower's profile onto a new `loan_requests` row at insert; locked thereafter, same pattern as term-locking |

### Key Views

| View | Purpose |
| --- | --- |
| `v_loan_listings` | Public marketplace listings, including `country` and `currency_code`; request-owner contact details excluded; offer detail rolled up into `number_of_offers` + `offer_coverage_tier` |
| `v_user_marketplace_activity` | Dashboard — requests posted and offers made, in one query |
| `v_lender_offers` | Offer activity for the current account, participant-scoped exact terms, `country`/`currency_code` joined through the listing |
| `v_marketplace_activity` | Marketplace request and offer KPIs, filterable/groupable by `country` |
| `v_marketplace_pro_filters` | Pro-only marketplace filter signals (employment type, income bracket, suggested terms, owner verification status); self-gated to Pro subscribers |
| `v_trust_profile_public` | Public trust signals for any `user_id` — rating average, review count, completed-deal count, repeat-participant flag, phone-verified flag, response-time bucket. Readable by any authenticated user. **Global, not per-country.** |
| `v_trust_profile_pro` | Pro-only extension of the above — adds success rate and reliability score; RLS restricts rows to callers on the Pro plan viewing any profile |

---

## Supabase Setup

> This project runs against the **Supabase Cloud** project — there is no local Supabase stack in the current workflow (`./run_cloud.sh chrome` connects directly to cloud).

### 1. Cloud Project

1. Create (or use the existing) Supabase project — one project serves every EAC country, see [Multi-Country Architecture](#multi-country-architecture)
2. Apply the schema and seed against the cloud database, either via the Supabase Dashboard → SQL Editor (paste the file contents) or via `psql` pointed at the cloud connection string:
   ```bash
   psql "postgresql://postgres:<password>@<project-ref>.supabase.co:5432/postgres" -f sql/schema.sql
   psql "postgresql://postgres:<password>@<project-ref>.supabase.co:5432/postgres" -f sql/seed.sql
   ```
3. Confirm `countries` has all 8 EAC states seeded, with `UG` as the only `is_active = TRUE` row, before onboarding any users
4. Create the `verification-documents` storage bucket (private) if it doesn't already exist

### 2. Auth Bridge Trigger

The `handle_new_auth_user()` function is defined in `sql/schema.sql` and runs automatically on every `auth.users` INSERT. It creates the corresponding `public.profiles` row for marketplace access.

### 3. Studio

Use the Supabase Dashboard (`https://supabase.com/dashboard/project/<project-ref>`) for table browsing, auth user management, and storage inspection.

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Supabase CLI (for `functions deploy` / `db push` only — no local stack needed)
- A configured Supabase Cloud project (see [Supabase Setup](#supabase-setup))

### Installation

```bash
git clone https://github.com/your-org/nipanze.git
cd nipanze

flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Running the App (Cloud)

```bash
./run_cloud.sh chrome    # Chrome, against the Supabase cloud project
flutter run -d android   # Android (emulator or device), reads the same cloud credentials
```

`./run_cloud.sh` sources `.env.cloud` (or equivalent) and injects the cloud `SUPABASE_URL` / `SUPABASE_ANON_KEY` via `--dart-define` — see [Environment Configuration](#environment-configuration).

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

```env
# .env.cloud — never commit this file
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...   # Edge Functions only — never bundled into the Flutter client
```

Credentials are injected via `--dart-define` at build time and read by `lib/core/config/supabase_config.dart`. The anon key is safe to bundle — RLS enforces access control at the database level, including `subscription_plan` and `country` checks.

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

Edge Functions (Deno TypeScript) wrap Postgres RPCs for server-side enforcement.

```bash
supabase functions new accept-offer
supabase functions serve accept-offer --env-file .env.cloud   # local test against cloud project
supabase functions deploy accept-offer                         # deploy
```

| Function | Purpose |
| --- | --- |
| `accept-offer` | Atomic offer acceptance with server enforcement |
| `make-offer` | Server-side subscription-plan validation for offers |
| `reveal-contact` | Post-acceptance contact sharing |
| `submit-review` | Server-side validation that the caller was a party to the completed contract before writing a review |
| `send-sms` | Africa's Talking or Twilio SMS alerts, respecting each market's carrier norms |
| `flutterwave-webhook` | **Stage 6.** Signature-verified webhook handler; the only writer of `transactions.status = 'successful'`, idempotent on `provider_tx_ref` |

---

## Testing

```bash
# Unit + widget tests (no local stack needed)
flutter test

# Single test file
flutter test test/features/auth/auth_bloc_test.dart

# Integration tests — Linux desktop only, runs against the Supabase Cloud project
flutter test integration_test/integration_test.dart -d linux

# Coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Test Accounts

All accounts are pre-loaded by `sql/seed.sql` with fixed UUIDs and `email_confirmed_at` set.
**Password for all accounts: `Test1234!`**

The `role` column has been removed — accounts are described purely by activity, `subscription_plan`, and `country`, matching the unified, multi-country model. All original 17 seed accounts currently sit at `country = 'UG'`; Stage 4.5 adds representative accounts for other EAC markets to validate cross-country filtering, currency rendering, and cross-border offers. The full, current list (including per-market test accounts for Kenya, Tanzania, and Rwanda) lives in [BUILD_PLAN.md](BUILD_PLAN.md#test-accounts-password-test1234).

| Email | Country | Subscription | Best for testing |
|---|---|---|---|
| `david.mukasa@gmail.com` | UG | Free | Contracted request; contact reveal triggered |
| `james.okello@outlook.com` | UG | Pro | Active request with two pending offers |
| `robert.ssemwanga@gmail.com` | UG | Lender | Closing-soon request; pending offer on another listing |
| `admin1@nipanze.ug` | UG | Free (`is_admin = true`) | Full admin dashboard access |
| `wanjiru.kamau@gmail.com` | KE | Free | Confirms a KE user's default feed and currency rendering (KES) |
| `nairobi.capital@example.co.ke` | KE | Lender | Confirms cross-border offer placement on a UG listing |
| `amani.mwakalinga@gmail.com` | TZ | Free | Confirms TZS currency rendering on a TZ-posted request |
| `uwase.claudine@gmail.com` | RW | Pro | Confirms RWF-denominated Pro term suggestions and Pro-gating work identically across countries |

> For trust-signal testing: `invest@pearlcapital.ug` and `david.mukasa@gmail.com` have a completed contract between them and are good candidates for seeding a mutual review pair once the `reviews` table ships — see BUILD_PLAN.md for the complete seed roster and per-scenario test notes.

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

- **No fund custody** — Nipanze never holds, pools, or moves user money, in any market
- **RLS on all tables** — Postgres enforces access control, not just the application layer
- **Plan and country checked server-side** — `subscription_plan` and `country` are validated in RLS/RPCs, never trusted from the client
- **No JWT country claim assumed** — country-scoped RLS (if adopted) uses a `profiles` subquery, not a custom JWT claim or `user_metadata` (which is client-writable and therefore spoofable for access-control purposes)
- **Payment status is webhook-verified only** — a `transactions` row only reaches `status = 'successful'`, and a subscription plan only upgrades, after Flutterwave's signed webhook is verified server-side; the client-side payment redirect is never trusted to grant access
- **JWT auth** — Supabase issues short-lived JWTs; sessions auto-refresh
- **Service role key never in client** — only used inside Edge Functions
- **Controlled contact sharing** — contact details stay hidden until acceptance
- **Selective offer-term transparency** — exact offer amounts, rates, and fees are gated to the request owner and to offer-makers who have bid on that listing; everyone else sees an aggregate coverage tier only, independent of country
- **Reviews are participant-gated** — only the counterparty on a completed contract can submit a review, enforced server-side in `submit_review`, not just hidden in the UI
- **Append-only audit log** — `audit_logs` has no UPDATE/DELETE in app user grants
- **Private documents** — verification documents are never exposed in marketplace listings
- **Refresh token rotation** — reuse attack detection via `replaced_by` chain
- **`--dart-define` credentials** — Supabase keys injected at build time, not hardcoded
- **Pro Advanced Filters categorical gating** — advanced filters use bucketed income (`fn_income_bracket`) and categorical employment type without ever exposing exact monthly income or employer/bank names. Access to filter details is gated at the DB layer via `v_marketplace_pro_filters` view which checks for the caller's active Pro plan subscription.

---

## Regulatory Compliance

> Nipanze operates as a technology marketplace in every EAC country it serves. We do not hold funds, accept deposits, issue loans, pool capital, or set interest rates, anywhere.

**We DO:** Provide marketplace infrastructure, show requester-provided information, manage controlled contact sharing, facilitate discovery, and surface on-platform trust signals (ratings, review counts, completed-deal counts) so participants can make informed matching decisions — consistently, per market.

**We DO NOT:** Accept deposits, hold or pool user funds, issue loans, set interest rates, guarantee returns, act as a bank or financial institution, process payments, track repayments, convert currencies, or claim to measure real-world repayment behavior, in any country.

All money movement, loan documentation, and repayment tracking happen directly between matched participants outside the platform. Each new market may carry its own local regulatory review — including sanctions-screening and payment-rail considerations for markets like Burundi, South Sudan, DR Congo, and Somalia — before `countries.is_active` is set to `TRUE`. This is a launch-checklist item per market, not a schema concern.

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
- Supabase Cloud, RLS audit, token rotation, APK release build (app testing checklist ⏳ in progress — finish before Stage 4.5)

### Stage 4 — Structured Deal Agreement, Contact Sharing & Trust System ⬜ Planned
- Locked-term bidding: Pro-plan users suggest interest rate, late fee, and repayment schedule at posting; Lender/Pro-plan users set their own terms at offer time; both locked on submission
- Selective transparency: listing detail shows funded %, offer count, and coverage tier to everyone; exact offer terms unlock only for the request owner and for offer-makers who have bid on that listing
- Trust & reputation layer: public rating/review/completed-deal/repeat/phone-verified badges on every profile, global across countries; Pro-tier verified badge and advanced trust insights
- Contract auto-generated after offer acceptance with all agreed terms, currency, and legal disclaimer
- Contact reveal only after contract is generated (contact-unlock fee remains an open decision — see [Trust & Reputation Signals](#trust--reputation-signals))
- `role` column fully removed from schema; all gating reads `subscription_plan` only

### Stage 4.5 — Multi-Country Expansion ⬜ Planned
- `countries` table seeded with all 8 EAC states; `country` added to `profiles`/`loan_requests`; `currency_code` surfaced on every listing/offer view; per-country `system_settings` overrides; marketplace feed defaults to the user's country with an explicit browse-other-markets toggle

### Stage 5 — Admin & Compliance ⬜ Planned
- Admin dashboard, verification review, audit trails, SMS, review moderation — plus per-country KPI filtering and per-market pause/resume via `countries.is_active`

### Stage 6 — Launch & Growth ⬜ Planned
- Play Store, App Store, referral programme, per-market subscription pricing (no role-selection onboarding step; country-select step instead)
- Flutterwave (or equivalent) payment integration, scoped strictly to Nipanze's own revenue
- Per-market EAC rollout checklist (Kenya, Tanzania, Rwanda first given deeper payment-rail maturity; Burundi, South Sudan, DR Congo, and Somalia following once each clears its own rail-coverage and compliance review)

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

*Made with ❤️ for financial inclusion across East Africa*