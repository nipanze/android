# Prompt: Financial Service Providers + Loan Products (one combined build)

Two linked pieces, built in this order:
- PART A: Provider / Service system gets a "Financial Services" category (who offers what).
- PART B: Loan posting system gets Loan Products (the actual offers and their terms).
- PART C: the link between them (mapping, matching, display).

```
You are working in the Nipanze Flutter + Supabase app (Uganda marketplace).

FIRST: inspect the code and report back, then WAIT for my OK before editing anything. Report:
- how the Provider onboarding, Individual and Company identities, capabilities, qualifications and proofs work today (including provider_services_catalog.md);
- the current loan request and loan offer tables, screens, matching, notifications and Activity;
- how plans and limits are stored (config or table);
- existing RLS policies on all of the above;
- what you can reuse, which files you will edit per part, and any conflict with this spec.
Do not start Part B until Part A is approved and shown. Do not start Part C until both are shown.

STANDING RULES
- Everything new is behind capability_profiles_enabled.
- SQL goes only in NEW standalone, descriptive patch files. Never modify patch.sql or merged.sql. List every new patch file by name. Do not run any SQL against production without my explicit approval. Never print secrets.
- Keep Flutter architecture, BLoC/Cubit, GoRouter, dependency injection, Supabase auth and RLS.
- Non-custodial. Nipanze never holds funds and never processes repayments. It only helps people discover, match and connect.
- Keep exactly two provider types: Individual and Company. No third type, no separate institution profile system.
- Reuse the existing provider profiles, capabilities, verification and subscription systems. Do not duplicate them.
- Existing loan requests, loan offers, Forex, Needs, notifications and Activity stay working. Preserve existing data with safe migrations.
- Verification never transfers between identities, categories or roles. Payment or a plan is never verification and never grants a badge.
- One active identity per user per category, enforced on the server, concurrency-safe.
- Every limit, audience rule and verification rule is enforced on the server (RLS and RPCs). The UI alone is not enough.
- No hard-coded prices, limits, roles, categories or purposes. They live in catalogue tables or config.
- No "Self-declared" labels. Do not show a save or switch as successful until the database call succeeds.
- All screens respect the selected language and currency. Submit buttons are disabled until required input is valid. 44px minimum tap targets. Status is shown with icon + text, not colour alone. Sheets scroll with the main button fixed at the bottom. Keep the Nipanze blue design.
- Never show who viewed a request, and never show borrower names to people who are not part of the deal.

=====================================================================
PART A: PROVIDER / SERVICE SYSTEM, FINANCIAL SERVICES
=====================================================================
Goal: Individuals (independent money lenders) and Companies (banks, SACCOs, microfinance, MOGO-type vehicle financiers, digital lenders) can declare which financial services they offer. This is separate from posting loans.

A0. NEW TOP-LEVEL CATEGORY. Add "Financial Services" as a new category in the existing provider category catalogue, alongside the current categories (a new data row plus its capabilities, no code change per category).
- It follows the same rules as every category: it stands alone, its roles, capabilities, proofs and details are saved per category, and nothing is copied from other categories.
- It appears in both the Individual and the Company flows (Provider Services cards, category picker, profile).
- Its default verification policy is required_proof (see A3). Other categories keep their current policies.
- Use a clear icon and short description, e.g. "Loans and financing you offer".
- Existing categories, their data and their screens do not change. Behind capability_profiles_enabled.

A1. Under the new "Financial Services" category, add these groups and capabilities:
- Personal Financing: Personal Loan Services, Emergency Loan Services, Salary Loan Services, Medical Financing
- Business Financing: Business Startup Financing, Working Capital Financing, Business Expansion Financing, SME Financing
- Asset Financing: Boda Boda, Car, Tuk-tuk, Motorcycle, Smartphone, Laptop, Heavy Machinery, Equipment Financing
- Agricultural Financing: Agricultural Loans, Livestock Financing, Crop Financing, Farm Equipment Financing
- Property Financing: Mortgage Financing, Land Financing, Property Development Financing
- Education Financing: School Fees Financing, University Financing, Education Loans
- Lifestyle Financing: Travel Financing, Wedding Financing, Other Lifestyle Financing

A2. Both Individual and Company identities can select MULTIPLE capabilities. Selection is saved PER CATEGORY and per identity. Nothing is copied or prefilled between categories or identities.

A3. Verification per capability (reuse the existing policy field: open / optional_proof / required_proof):
- Financial capabilities default to required_proof. Individual proof: ID verification and supporting information. Company proof: business identity, registration documents, and a licence or regulatory document where applicable (for example bank, SACCO, microfinance, money lender licence).
- A capability without approved proof can be saved as a draft but is not shown to borrowers, is not used for matching, and cannot be linked to a published loan product. Enforce on the server.
- If proof is rejected, show the reason and let the user upload again. Unticking follows the existing rule (confirm sheet if proof is pending or approved, one server action, never blocked).
- Badges only come from the existing authorised verification process.

A4. Profile display. The capabilities appear inside the existing provider profile.
- Individual: profile name and photo from Profile, selected financial services, experience note, verification status, reputation.
- Company: logo, company name, description, contact, selected financial services, registration and licence info with verification status, reviews. The company name is edited in one place only (company details step).
A provider can declare a capability without publishing any loan product.

A5. Plans. Provider plans (Individual and Company) can include limits and benefits for financial capabilities and featured capabilities, read from config through the existing admin system. Verification is not a plan feature.

DONE WHEN (Part A): both identity types can declare multiple financial capabilities; required proof is enforced on the server; existing non-financial services and Needs behave exactly as before. Show the diff, files changed, 390px screenshots of each new state, and the SQL patch file names (not run).

=====================================================================
PART B: LOAN POSTING SYSTEM, LOAN PRODUCTS
=====================================================================
Goal: one loan posting engine, used by Individual and Company providers, to publish MANY independent loan products. Do not build separate systems for the two types. Do not rebuild the borrower request system.

B1. Seven loan categories, each with its own purposes (catalogue tables; show only the purposes of the selected category). A purpose is stored as a (category, purpose) pair, because "Agricultural Equipment" exists in two categories.
1 Personal: General Personal Expenses, Salary Advance, Medical Expenses, Debt Consolidation, Family Support, Other Personal Needs
2 Business: Business Startup, Business Expansion, Working Capital, Inventory / Stock Purchase, Equipment for Business, Contract Financing, Invoice Financing, Other Business Needs
3 Asset Financing: Boda Boda, Car, Tuk-tuk, Motorcycle, Smartphone, Laptop, Heavy Machinery, Agricultural Equipment, Other Asset Financing
4 Agricultural: Crop Production, Greenhouse Farming, Livestock, Poultry Farming, Farm Inputs, Irrigation, Tractor Financing, Agricultural Equipment, Other Agricultural Needs
5 Property: Land Purchase, Home Construction, Home Improvement, Mortgage Financing, Property Development, Commercial Property, Other Property Needs
6 Education: School Fees, University Tuition, Vocational Training, Professional Courses, Study Abroad, Educational Equipment, Other Education Needs
7 Lifestyle: Wedding Expenses, Travel / Holiday, Events and Celebrations, Family Events, Relocation Expenses, Other Lifestyle Needs

B2. Posting flow (7 steps, one screen each, progress shown, draft saved on every step):
1 Category. 2 Purpose (only that category's purposes). 3 Loan information: product title, short description, minimum and maximum amount, currency, lending capacity if applicable. 4 Interest and repayment: rate, calculation method (a selectable list, never assume one method), interest-free option, repayment frequency (daily, weekly, biweekly, monthly, custom), minimum and maximum period, extra fees and late fee. 5 Security and eligibility: secured or unsecured (collateral never forced), collateral type, guarantor, minimum age, employment, income, required documents, geographic eligibility, other conditions. 6 Additional: image or promo material, extra terms, enquiry preference. 7 Preview and publish: full preview, validation, Publish disabled until all required fields are valid.

B3. Each product owns its own terms, limits, rates, eligibility, repayment conditions and availability. One provider can have many products across categories.

B4. Ownership and gates (server-side):
- A product belongs to an existing provider identity (Individual or Company). No company profile is needed for an individual.
- Publishing requires the provider to pass the existing verification gate for posting. Drafts can always be saved.
- A product must be linked to a financial capability of that same identity that has APPROVED proof (see Part C mapping). No approved capability, no publish.
- The number of active products and featured placements comes from plan config and is checked in the publish RPC, concurrency-safe. Show "3 of 3 active products" style messages.

B5. Management screen. Providers see all their products with status: Draft, Active, Paused, Unavailable, Archived. They can edit, pause or activate, mark unavailable, archive, see enquiries, see matching borrower requests, and see basic performance (views, enquiries) without revealing who viewed. Companies manage multiple products under their Company identity. Individuals get the same screen within their plan limits.

B6. Marketplace display of a product: provider name (company name and logo for Company), provider type tag (Individual or Company, shown as information only), existing verification badge, product name, category and purpose, financing range, interest information, repayment frequency, main eligibility. Show the posted amount range, not exact private details.

DONE WHEN (Part B): an Individual and a Company can each publish several products with different terms; limits and gates are enforced on the server; existing loan requests and offers are untouched. Same deliverables as Part A.

=====================================================================
PART C: LINK BETWEEN PROVIDERS AND LOAN PRODUCTS
=====================================================================
C1. Capability to loan category and purpose mapping (a data table, editable by admin):
- Personal Loan Services: Personal, General Personal Expenses, Family Support, Debt Consolidation, Other Personal Needs
- Emergency Loan Services: Personal, General Personal Expenses, Medical Expenses
- Salary Loan Services: Personal, Salary Advance
- Medical Financing: Personal, Medical Expenses
- Business Startup Financing: Business, Business Startup
- Working Capital Financing: Business, Working Capital, Inventory / Stock Purchase
- Business Expansion Financing: Business, Business Expansion
- SME Financing: all Business purposes
- Boda Boda / Car / Tuk-tuk / Motorcycle / Smartphone / Laptop Financing: Asset Financing, the matching purpose
- Heavy Machinery Financing: Asset Financing, Heavy Machinery
- Equipment Financing: Business, Equipment for Business; Asset Financing, Other Asset Financing
- Agricultural Loans: all Agricultural purposes
- Livestock Financing: Agricultural, Livestock, Poultry Farming
- Crop Financing: Agricultural, Crop Production, Farm Inputs, Greenhouse Farming, Irrigation
- Farm Equipment Financing: Agricultural, Tractor Financing, Agricultural Equipment; Asset Financing, Agricultural Equipment
- Mortgage Financing: Property, Mortgage Financing, Home Construction, Home Improvement
- Land Financing: Property, Land Purchase
- Property Development Financing: Property, Property Development, Commercial Property
- School Fees Financing: Education, School Fees
- University Financing: Education, University Tuition
- Education Loans: all Education purposes
- Travel Financing: Lifestyle, Travel / Holiday
- Wedding Financing: Lifestyle, Wedding Expenses
- Other Lifestyle Financing: Lifestyle, Events and Celebrations, Family Events, Relocation Expenses, Other Lifestyle Needs
A product can only be published for a (category, purpose) that its linked capability covers.

C2. Matching with the existing borrower loan requests. Match on category, purpose, requested amount within the product range, currency, repayment preference, eligibility, collateral preference and location. Only providers with approved capability and an Active product are matched. Provider type (Individual or Company) is never a ranking advantage. Example: a UGX 8,000,000 tuk-tuk request finds active tuk-tuk products from individual lenders, vehicle financiers and institutions alike.

C3. Audience: a borrower's loan request is visible only to eligible lenders (existing rule). Enforced by RLS.

C4. Notifications and Activity: new matching request notifies matching providers; enquiries on a product appear in Activity. Reuse the existing notification system.

DONE WHEN (Part C): a borrower request surfaces the right products from both provider types; unverified capabilities never match; Activity and notifications work.

BUILD ORDER
1 Part A. 2 Part B. 3 Part C. Finish and show each before the next.

FINAL REPORT (after each part)
Diff, files changed, 390px screenshots of every state, new SQL patch files by name (not run), README and build plan updates, and a confirmation that Home, the Marketplace feed, Loans, Forex and Needs behave as before and that nothing sits outside capability_profiles_enabled.
```
