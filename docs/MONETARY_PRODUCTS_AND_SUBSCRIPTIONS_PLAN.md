# Monetary Products and Subscriptions Plan

## Purpose

Plan the money-related products, account plans, and optional paid features Nipanze could offer across its marketplace. This is a product-planning inventory, not a commitment to launch every item. Existing Loans, Forex, Needs, provider services, and the non-custodial boundary remain the foundation: Nipanze introduces people and controls contact sharing; it does not lend, exchange, hold, transfer, or insure customer funds.

## Product principles

- Keep core discovery and access fair: browsing, posting a request, receiving offers, and comparing offers should remain available to all users within sensible anti-spam limits.
- Charge for optional provider productivity, business tools, or promotion rather than access to essential safety or trust information.
- Never sell a verification badge, rating, offer acceptance, or a promise of a successful transaction.
- Show price, billing period, renewal date, cancellation path, taxes, and refund terms before checkout. Make renewal opt-in and cancellation self-service.
- Display prices in the user's market currency using configured country-specific price rows; do not silently convert or imply a guaranteed exchange rate.
- Keep payments for subscriptions separate from payments between marketplace users. No escrow, wallet, or transaction settlement is implied by this plan.
- Roll out paid features only after country-specific legal, tax, consumer-protection, payment-provider, and operational review.

## Existing marketplace categories and monetary features

The category inventory follows Nipanze's current marketplace structure. Monetary features below are candidates; they do not change the listing, offer, or contact-reveal flow by themselves.

| Marketplace category | Core user need | Potential money-related tools |
|---|---|---|
| Loans | Borrowers find lenders and compare loan offers | Loan amount and currency, repayment schedule, interest/fee disclosure fields, total repayment calculator, due-date reminders, saved offers, lender lead-management tools. Nipanze must not issue loans or guarantee repayment. |
| Forex | People find counterparties for a currency pair | Pair and amount filters, quote comparison, rate timestamp and expiry, spread/fee disclosure fields, rate alerts, saved pairs, provider lead tools. Nipanze must not execute or custody exchange. |
| Travel & International | Find visa, ticketing, pilgrimage, relocation, or international-travel assistance | Budget and fee breakdown fields, milestones/deadlines, document checklist, quote comparison, provider response tools. Do not imply visa approval or sell travel funds. |
| Machinery & Equipment | Find equipment to hire, lease, or source | Hour/day/week/month pricing fields, deposit and delivery terms disclosure, availability dates, quote comparison, provider calendar and lead tools. No Nipanze collection of rental deposits. |
| Professional Services | Find a specialist or business service | Fixed/hourly/project quote fields, scope and milestone templates, quote comparison, provider portfolio and lead tools. No guarantee of professional outcome. |
| Transport & Logistics | Find cargo, haulage, moving, or delivery | Per-trip/per-distance/per-load quote fields, route and load filters, quote comparison, availability and lead tools. No carrier or cargo insurance promise. |
| Specialized Products & Procurement | Source hard-to-find goods or bulk products | Quantity/lot pricing fields, sourcing and delivery quote breakdowns, supplier response tools, saved sourcing requests. Nipanze does not sell or take payment for goods. |
| Provider Services catalog (all service categories) | Providers advertise what they can do | Business profile, portfolio, service-area and availability tools, lead inbox, analytics, team seats, and optional sponsored placement. Catalog categories include technology, marketing, business, education, events, media, beauty, construction, energy, transport, machinery, agriculture, procurement, travel, household, health, investment, and cultural services. |

### Money-related functions shared across categories

- Request-side budget range, currency, urgency, and optional target date.
- Offer-side price, pricing basis, validity/expiry, included items, exclusions, and optional milestone schedule.
- Clear comparison of comparable offers, with fee and total-cost fields where applicable.
- Private saved searches, watchlists, and price/availability alerts.
- Provider earnings and lead analytics based on Nipanze activity only; never label estimates as guaranteed income.
- Optional quote and invoice document exchange can be explored later, but documents must not be treated as proof that money was paid.

## Subscription plans

The repository already describes Free and paid plan access, including a free monthly cap for offers. Treat the following as the proposed product shape; retain the existing internal plan enum where database compatibility requires it and resolve display names separately.

| Plan | Audience | Candidate inclusions | Candidate limits / notes |
|---|---|---|---|
| Free | Anyone trying the marketplace | Browse all enabled categories, post requests within anti-spam limits, receive and compare offers, maintain a basic profile, use trust and safety tools, save a small watchlist | Small monthly cap on provider offers (current Needs proposal: 3/month); basic active-post cap. Never paywall reports, blocks, or trust context. |
| Provider | Individuals or small providers | Free features plus higher offer allowance, capability/service profile, portfolio, lead inbox, saved replies, performance summary, response-time tools | Candidate rename for existing “Lender” display plan; do not change enum without migration review. Country pricing and monthly/annual billing. |
| Business | Registered or multi-person providers | Provider features plus multiple service locations, team seats, shared lead inbox, business profile, exports, richer analytics, operating-hours and availability tools | Seats and locations are explicit add-ons or included allowances; no implied verification from business subscription. |
| Enterprise / Partner | Large networks or institutional partners | Multiple branches, administrator roles, integrations/export options, consolidated analytics, support contact, configurable seat allowance | Contracted pricing and onboarding; only after support and compliance processes exist. |

### Subscription behavior and account controls

- A user can compare plans and see exactly which feature or limit changes before upgrading.
- The account screen shows current plan, renewal date, payment status, invoices/receipts, and cancellation or downgrade controls.
- Failed renewal produces a grace period and clear notices; downgrade preserves user data while disabling plan-only actions gracefully.
- Plan entitlement is enforced server-side. UI hiding alone is not access control.
- Apply entitlement changes consistently across Loans, Forex, Needs, and provider catalog features. Document category-specific exceptions explicitly.
- Support monthly and annual periods only when the payment provider and local rules support them; show the annual total and equivalent monthly price without obscuring billing.
- Define refunds, chargebacks, proration, tax handling, and account deletion effects before accepting payment.

## Optional paid features and one-time purchases

These are separate from a recurring subscription and should be tested for user value before implementation.

| Feature | Who may pay | What it provides | Guardrails |
|---|---|---|---|
| Sponsored listing / request boost | Requester or provider | Temporary, clearly labeled placement in relevant search/feed results | Never changes trust/rating, offer ranking fairness, or guarantees responses; cap frequency and disclose duration/targeting. |
| Provider spotlight | Provider/business | Clearly labeled promotion of a service profile in matching categories and locations | No “verified” implication; only show where relevant; define impression/click reporting. |
| Extra team seat or branch | Business | Additional account seat or location beyond plan allowance | Role-based access, audit trail, seat management, prorating rules. |
| Extra lead/offer pack | Provider | A one-time increase to monthly offer allowance | Avoid pay-to-spam; eligibility and caps still apply; never sell access to private competitor data. |
| Business profile setup | Provider/business | Optional assisted profile/catalogue setup | Publish scope, service level, and refund terms; no promise of leads. |
| Export/report pack | Provider/business | Download own leads and performance summaries | Export only data the buyer is authorized to access; privacy retention rules apply. |

Do not launch buyer-side success fees, percentage commissions, escrow, stored-value wallets, paid “guaranteed” placement, paid verification, or user-to-user payment collection without a separate regulatory, trust, and architecture review. These alter Nipanze's current non-custodial model.

## Category-specific paid-tool candidates

| Category | Provider subscription value candidates | Optional one-time candidates |
|---|---|---|
| Loans | Lender lead inbox, saved borrower filters, offer templates, repayment schedule calculator, portfolio-of-leads analytics | Extra offer pack; sponsored lender profile |
| Forex | Pair/market alerts, quote templates, availability management, lead analytics | Sponsored provider listing; extra quote pack |
| Travel & International | Destination/service coverage, document checklist templates, appointment availability, lead inbox | Sponsored category placement |
| Machinery & Equipment | Equipment inventory, availability calendar, hire-period quote templates, location coverage | Extra inventory slot; promoted equipment profile |
| Professional Services | Portfolio, service packages, response templates, client lead analytics | Extra profile/service slot; sponsored listing |
| Transport & Logistics | Fleet/service-area profile, route and load quote templates, availability calendar, team leads | Extra vehicle/fleet slot; promoted provider |
| Specialized Products & Procurement | Supplier catalogue, sourcing request inbox, quote templates, saved product lists | Extra catalogue slot; sponsored supplier listing |
| Provider Services catalog | Multi-category profile, portfolio, team/branch tools, response analytics | Featured profile or additional service slots |

## Pricing and payment operations

- Use a `subscription_prices`-style country/currency configuration as source of truth; do not hardcode price logic in clients.
- Record product/plan, market, currency, price, period, tax treatment, effective dates, and provider product identifiers.
- Use a payment processor with supported local methods and reliable subscription webhooks; availability must be checked per launch country.
- Treat processor events as authoritative for entitlement state, with idempotent webhook handling and reconciliation.
- Store only processor references and minimum billing metadata required for support and accounting; never store raw card credentials.
- Keep a user-visible receipt and an auditable admin view of plan changes, refunds, failed payments, and promotional grants.
- Report gross subscription revenue, refunds, processor fees, taxes, conversion, churn, and active entitlements separately.

## Rollout sequence

1. **Define entitlements:** reconcile current Free and paid limits across Loans, Forex, and Needs; settle the public name for the existing `lender` plan.
2. **Make billing transparent:** finalize market currencies, price configuration, renewal, cancellation, failed-payment, refund, and tax behavior.
3. **Launch one provider plan:** offer higher, clearly bounded offer capacity plus provider productivity tools; measure conversion, retention, support load, and spam.
4. **Test optional promotion:** run a small labeled placement pilot with frequency caps and relevance constraints.
5. **Add business tools:** team seats, branches, exports, and category tools after demand and support readiness are demonstrated.
6. **Review before each market expansion:** verify payment methods, pricing display, consumer rules, taxes, and category-specific compliance in that country.

## Decisions to resolve before implementation

- What is the user-facing name for the current `lender` paid plan: Provider, Offers, or another name?
- Which paid plan features already exist in production, and what are the actual country price rows and quotas?
- Should free users' offer allowance be shared across Loans, Forex, and Needs or tracked separately by module?
- Is annual billing desirable at launch, or should the first version be monthly only?
- Which payment processor and local payment methods are available for each launch market?
- Are sponsored placements acceptable, and what relevance, labeling, and frequency policy should govern them?
- Which provider categories have enough usage to justify dedicated paid tools first?

## Success measures

- Upgrade conversion and paid-plan retention by country, category, and acquisition source.
- Provider response rate, time to first response, and completed connections by plan, checked for unfair exclusion.
- Free-to-paid upgrade reasons and downgrade/cancellation reasons.
- Sponsored placement click-through and downstream offer quality, reported separately from organic activity.
- Payment failure, refund, chargeback, complaint, and support-contact rates.
- User trust measures: reports, blocks, misleading-price complaints, and perceived pressure to pay.

## Out of scope for this plan

This document does not approve lending, foreign-exchange execution, money transfers, escrow, wallets, insurance, payment collection for marketplace deals, or regulatory claims. Those require separate product, technical, and country-specific review before any implementation.
