# Provider proof and verification policy

## Goal

Require evidence before showing a **Provider Verified** badge for services where
licensing, professional competence, or physical safety materially affects
customers. Keep ordinary creative, digital, personal, and advisory listings
self-declared unless a specific regulated service is added. Rules attach to
capabilities, not whole categories, so one listing does not over-verify every
provider in a broad category.

## Rules implemented

`verification_requirements.provider_type` now distinguishes `individual`,
`company`, and legacy/shared (`both`) evidence rules. A company rule may request
the organization authorization and evidence of its named qualified staff; an
individual rule requests the provider's own credential. Capability evidence is
reviewed by an admin; upload alone never grants the badge. Annual expiry is the
default for licences and registrations in this matrix.

The seeded capabilities are:

| Capability | Individual evidence | Company evidence |
| --- | --- | --- |
| Legal services | Current practising certificate | Law firm approval and named advocate's current certificate |
| Accounting and tax | ICPAU practising certificate | ICPAU firm licence and named accountant's certificate |
| Company registration | Company secretarial or legal practice credential | Business registration and named qualified company secretary or advocate |
| Architecture, engineering, surveying | Current personal registration/practising credential | Firm registration and named professional credential |
| Electrical works and installation | ERA installation permit | ERA company permit and named installer's permit |
| Solar systems | Applicable ERA permit or recognized installer credential | Company authorization and named installer credentials |
| Building contractors | Contractor registration or trade competency | NBRB contractor registration, trading licence, and regulated professional when required |
| Roofing, concrete, plumbing, excavation | Relevant trade and safety competency | Contractor/business registration and relevant named worker or professional evidence |
| Heavy haulage, cargo transport, truck hire, event transport | Correct driving class and applicable PSV/operator authorization | Operator authorization where applicable, and vehicle registration/insurance |
| Driving school / driver training | Authorized instructor credential | Driving school licence, instructor credentials, and training vehicle documents |
| Excavator, loader, grader, crane hire | Operator competency and ownership/hire authority | Fleet evidence, ownership/logbook, and operator competency when an operator is supplied |
| Visa assistance, Hajj & Umrah | Authorization or affiliation with a licensed operator | Current travel/operator accreditation and business licence |
| Seeds & inputs | Dealer/handler authorization when applicable | Registered dealer/premises and product registration for regulated inputs |
| Catering | Food handler health certificate | Food business health permit and food staff certificates |

These are capability-specific safeguards, not a claim that every listed
document is legally required for every service in every district. Admin review
must accept the locally applicable equivalent. Do not require proof for all
Technology, Marketing, Photo/Video/Music, Beauty, general Events, general
Education, or Procurement listings. If a regulated activity is later added
(such as drone operation or medical supply distribution), add a separate rule
for that capability.

## Flow and safeguards

1. The picker shows evidence keys for the selected provider type, preferring a
   type-specific rule and falling back to a `both` rule.
2. The server checks the provider's saved category type when accepting evidence
   and when the admin reviews it. Company saves accept only company/shared
   evidence keys. Each submitted evidence row snapshots the provider type so a
   later type switch cannot reinterpret old proof.
3. Admin approval promotes only the matching capability to `provider_verified`;
   rejected or expired evidence returns it to `self_declared`.
4. Evidence remains private and is scoped to the provider and capability.
5. General categories remain self-declared; they do not receive a mandatory
   proof gate through a category-wide fallback.

## Rollout

Apply SQL in this order after the base schema/catalog is present:

1. `patch_provider_services_work_profiles.sql`
2. `patch_role_qualification_evidence_flags.sql`
3. `patch_provider_category_type.sql`
4. `patch_provider_type_verification_matrix.sql`
5. Reapply `patch_provider_capability_evidence_security.sql`
6. Reapply `patch_company_provider_path.sql`

The last two reapplications install the provider-type-aware evidence and
company-save checks. Confirm the app is deployed with matching provider service
capability slugs. Then check the matrix in `verification_requirements`, test
one individual and one company submission per high-risk capability in staging,
and confirm a badge appears only after the complete evidence set is approved.

This repo does not confirm whether these patches have been applied to the live
database. The launch operator should verify migration status and review the
locally applicable licence equivalents before enabling the badge rules for
customers.
