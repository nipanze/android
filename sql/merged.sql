-- ==============================================================================
-- NIPANZE FULL DATABASE MERGED SETUP (SUPABASE CLOUD)
-- ==============================================================================
-- This file merges sql/schema.sql, sql/seed.sql, and sql/patch.sql in their
-- required execution order:
--   1. Base Schema (sql/schema.sql)
--   2. Base Seed Data (sql/seed.sql)
--   3. Consolidated Patches & Enhancements (sql/patch.sql)
--
-- Safe to run directly in the Supabase Cloud SQL Editor (https://supabase.com/dashboard).
-- ==============================================================================


-- ==============================================================================
-- 1. BASE SCHEMA (sql/schema.sql)
-- ==============================================================================

-- ============================================
-- NIPANZE Database Schema
-- Version: 5.0 (Multi-Country Expansion + Pro Advanced Filters, on top of the
--               v4.1 Unified Marketplace Model — Non-Custodial Matchmaking Marketplace)
-- PostgreSQL 14+ · Flutter + Supabase
--
-- Non-custodial peer-to-peer loan listing marketplace.
-- Uganda-first, architected for the full East African Community (EAC) on one
-- shared schema. Basic borrowing is free. Premium borrowers can suggest terms.
-- Lender bids require a subscription.
-- Platform NEVER holds, tracks, or processes money between borrower and lender.
-- Contact details are revealed only after a locked contract is generated.
--
-- v4.1 change: removed role-based model. There is no stored borrower/lender
-- role. All marketplace capability comes from subscription_plan. The only
-- remaining role concept is is_admin (boolean), which governs platform
-- moderation and is unrelated to marketplace participation.
--
-- v4.1.1 fix: reordered two blocks that referenced objects before they
-- were defined (fixed as ordering bugs found during clean-schema replay):
--   1) CREATE SCHEMA IF NOT EXISTS private; moved to top of file, before
--      any private.* function definition.
--   2) trg_agreements_updated_at trigger moved from right after the
--      agreements table into the TRIGGERS section, after fn_set_updated_at()
--      is defined.
--
-- v4.2 addition: Pro Advanced Marketplace Filters — fn_income_bracket(),
-- v_marketplace_pro_filters view, and get_marketplace_pro_filtered() RPC.
-- Self-gated to callers with an active Pro subscription; returns zero rows
-- (view) or raises (RPC) for anyone else. Never exposes exact monthly
-- income or employer/bank names — only bucketed income and categorical
-- employment type.
--
-- v5.0 addition: Multi-Country Expansion. One shared schema now serves every
-- East African Community member state instead of Uganda only:
--   1) New `countries` reference table — code, name, currency_code,
--      phone_prefix, is_active. Seeded with all 8 EAC states (UG active,
--      the other 7 inactive until each clears its own launch checklist).
--      Created early in this file so `profiles` and `loan_requests` can
--      reference it via FK.
--   2) `profiles.country` — source of truth for a user's market, defaults
--      to 'UG', set from onboarding (phone-prefix suggestion, never
--      enforced) via handle_new_auth_user().
--   3) `loan_requests.country` — copied from the borrower's profile at
--      insert time by trg_fn_set_request_country(), then immutable
--      (same "locked after publish" pattern as suggested terms).
--   4) `loan_offers` gets NO country column — an offer's country is always
--      read through `request_id -> loan_requests.country`, so there is
--      exactly one source of truth, never two that can drift apart.
--   5) `system_settings.country` — nullable; NULL rows are global defaults,
--      non-null rows are per-market overrides. Composite unique constraint
--      on (setting_key, country).
--   6) `subscriptions.amount_ugx` renamed to `amount_minor_units` — the
--      currency is implied by the subscriber's `profiles.country`, not
--      hardcoded to UGX.
--   7) `v_loan_listings` and `v_lender_offers` now expose `country` and
--      `currency_code` (joined from `countries`) alongside every amount.
--      `v_marketplace_activity` is now groupable by `country`.
--   8) New `transactions` table (Stage 6 — Flutterwave or equivalent).
--      Scoped strictly to Nipanze's own revenue (subscriptions, and the
--      contact-unlock fee if that open decision is ever resolved to "yes").
--      NEVER touches P2P loan funds. Only a verified webhook may write
--      status = 'successful'; the client-side redirect is never trusted.
--   9) Cross-border offers are ALLOWED by default in this schema (no country
--      check in trg_fn_validate_offer) per the BUILD_PLAN.md recommendation.
--      A single clause can be added there later if product direction
--      changes to single-market-only offers.
--  10) Marketplace filtering by country is an APPLICATION-LAYER default
--      (MarketplaceRepository filters `v_loan_listings WHERE country =
--      :userCountry`), not an RLS boundary — "global browse" was the
--      chosen policy over hard per-country RLS isolation, to support
--      diaspora and cross-border lending. See BUILD_PLAN.md for the
--      documented subquery pattern if hard isolation is ever adopted.
-- ============================================


-- ============================================
-- EXTENSIONS
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ============================================
-- SCHEMAS
-- private schema created early so any private.* function definition
-- later in this file (e.g. private.accept_offer_internal,
-- private.reveal_contact_internal, private.unlock_contact_internal,
-- private.is_admin) has somewhere to live.
-- ============================================

CREATE SCHEMA IF NOT EXISTS private;


-- ============================================
-- ENUMS
-- ============================================

CREATE TYPE account_status_enum AS ENUM (
    'active', 'suspended', 'pending_verification', 'deactivated'
);

CREATE TYPE kyc_status_enum AS ENUM (
    'not_submitted', 'pending', 'approved', 'rejected', 'expired'
);

CREATE TYPE employment_type_enum AS ENUM (
    'employed', 'government_employee', 'self_employed', 'small_business_owner', 'business_owner', 'student', 'other'
);

CREATE TYPE subscription_plan_enum AS ENUM (
    'free', 'lender', 'pro'
);

CREATE TYPE subscription_status_enum AS ENUM (
    'active', 'expired', 'cancelled', 'grace_period'
);

CREATE TYPE loan_status_enum AS ENUM (
    'active', 'contracted', 'expired', 'cancelled'
);

CREATE TYPE offer_status_enum AS ENUM (
    'pending', 'accepted', 'rejected', 'withdrawn', 'expired'
);

CREATE TYPE reveal_status_enum AS ENUM (
    'pending', 'revealed'
);

CREATE TYPE repayment_frequency_enum AS ENUM (
    'weekly', 'monthly', 'one_time'
);

CREATE TYPE agreement_status_enum AS ENUM (
    'pending', 'borrower_agreed', 'lender_agreed', 'locked'
);

CREATE TYPE notification_type_enum AS ENUM (
    'offer_received',
    'offer_accepted',
    'offer_rejected',
    'offer_withdrawn',
    'contact_revealed',
    'agreement_locked',
    'kyc_approved',
    'kyc_rejected',
    'closing_soon_24h',
    'closing_soon_6h',
    'watchlist_new_offer',
    'system'
);

CREATE TYPE audit_event_type_enum AS ENUM (
    'login', 'logout', 'register', 'password_reset',
    'token_refresh', 'token_reuse_detected',
    'login_failed', 'account_locked',
    'kyc_submitted', 'kyc_approved', 'kyc_rejected',
    'listing_created', 'listing_cancelled',
    'offer_placed', 'offer_withdrawn', 'offer_accepted',
    'agreement_locked',
    'contact_revealed', 'review_submitted',
    'subscription_changed',
    'transaction_completed',
    'admin_action'
);

CREATE TYPE setting_type_enum AS ENUM (
    'string', 'number', 'boolean', 'json'
);


-- ============================================
-- TABLE: countries  (v5.0 — new reference table)
-- One row per East African Community member state. Seeded with all 8 up
-- front; launching a market is `UPDATE countries SET is_active = TRUE`,
-- never a schema migration. profiles and loan_requests both FK to this
-- table, so it must exist before either is created.
-- ============================================

CREATE TABLE countries (
    code           TEXT PRIMARY KEY,          -- ISO 3166-1 alpha-2
    name           TEXT NOT NULL,
    currency_code  TEXT NOT NULL,              -- ISO 4217
    phone_prefix   TEXT NOT NULL,              -- onboarding-time default suggestion only, never enforced
    is_active      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  countries IS
'Reference table for every EAC market Nipanze can operate in. is_active gates whether new
 listings/subscriptions can be created in that market; existing data and history are untouched
 when a market is paused. Adding a market is a data change, never a schema migration.';
COMMENT ON COLUMN countries.phone_prefix IS
'Onboarding-time default suggestion only (like GPS/IP). Never trusted as the enforced value —
 profiles.country, once set, is the source of truth.';

INSERT INTO countries (code, name, currency_code, phone_prefix, is_active) VALUES
    ('UG', 'Uganda',       'UGX', '+256', TRUE),
    ('KE', 'Kenya',        'KES', '+254', FALSE),
    ('TZ', 'Tanzania',     'TZS', '+255', FALSE),
    ('RW', 'Rwanda',       'RWF', '+250', FALSE),
    ('BI', 'Burundi',      'BIF', '+257', FALSE),
    ('SS', 'South Sudan',  'SSP', '+211', FALSE),
    ('CD', 'DR Congo',     'CDF', '+243', FALSE),
    ('SO', 'Somalia',      'SOS', '+252', FALSE);

CREATE INDEX idx_countries_is_active ON countries (is_active) WHERE is_active = TRUE;


-- ============================================
-- AUTH BRIDGE
-- Syncs auth.users → public.profiles on registration.
-- Also creates a free subscription automatically.
-- v5.0: also resolves the new user's country from onboarding metadata
-- (phone-prefix guess or explicit selection), falling back to 'UG' if
-- missing or not a known country code — never trusts an unvalidated value.
-- ============================================

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_country TEXT;
    v_phone TEXT;
BEGIN
    v_country := UPPER(COALESCE(NEW.raw_user_meta_data->>'country_code', 'UG'));
    IF NOT EXISTS (SELECT 1 FROM public.countries WHERE code = v_country) THEN
        v_country := 'UG';
    END IF;

    v_phone := COALESCE(NEW.raw_user_meta_data->>'phone', NEW.phone);

    INSERT INTO public.profiles (
        id, full_name, phone, account_status, is_admin, country
    )
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', SPLIT_PART(NEW.email, '@', 1)),
        v_phone,
        'pending_verification',
        FALSE,
        v_country
    )
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        phone = COALESCE(EXCLUDED.phone, public.profiles.phone),
        country = COALESCE(EXCLUDED.country, public.profiles.country);

    -- Auto confirm mock email users for phone sign ups
    IF NEW.email LIKE '%@nipanze.test' AND NEW.email_confirmed_at IS NULL THEN
        UPDATE auth.users SET email_confirmed_at = NOW() WHERE id = NEW.id;
    END IF;

    -- Every new user gets a free subscription (can browse marketplace and post requests)
    INSERT INTO public.subscriptions (user_id, plan, status, amount_minor_units)
    VALUES (NEW.id, 'free', 'active', 0)
    ON CONFLICT (user_id) WHERE status = 'active' DO NOTHING;

    RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_auth_user();

COMMENT ON FUNCTION public.handle_new_auth_user IS
'Syncs auth.users → public.profiles on every registration, resolves the new profile''s country
 (defaulting to UG if the onboarding suggestion is missing or unrecognized), and provisions a
 free subscription. Free plan allows marketplace browsing and posting loan requests at no cost.';


-- ============================================
-- TABLE: profiles  (extends auth.users 1-to-1)
-- v4.1: no stored borrower/lender role. is_admin is the only role concept,
-- and it governs platform moderation only — never marketplace capability.
-- v5.0: carries `country`, the source of truth for which EAC market this
-- account belongs to. Required, defaults to 'UG', editable by the user.
-- ============================================

CREATE TABLE profiles (
    id               UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

    full_name        TEXT,
    phone            TEXT UNIQUE,
    -- Public badge only; the phone number itself remains private until reveal.
    phone_verified_at TIMESTAMP,
    country          TEXT NOT NULL DEFAULT 'UG' REFERENCES countries(code),
    district         TEXT,
    street_address   TEXT,
    employment_type  employment_type_enum,
    employer_name    TEXT,
    monthly_income     BIGINT,
    income_currency    VARCHAR(3) NOT NULL DEFAULT 'UGX',  -- ISO 4217; derived from profiles.country
    preferred_bank      TEXT,
    institution_type    TEXT CHECK (
        institution_type IS NULL OR
        institution_type IN ('bank', 'forex_exchange', 'sacco', 'company')
    ),
    is_bank_agent       BOOLEAN NOT NULL DEFAULT FALSE,
    show_professional_tag BOOLEAN NOT NULL DEFAULT TRUE,

    -- Marketplace filter preferences (v4.5) — mirrors Advanced Filters defaults
    preferred_employment_types  TEXT[],
    preferred_income_bracket    TEXT,
    prefers_suggested_terms     BOOLEAN NOT NULL DEFAULT FALSE,
    prefers_verified_only       BOOLEAN NOT NULL DEFAULT FALSE,

    -- Free contact-unlock credits (welcome gift for free-plan users)
    free_unlocks_remaining      INT NOT NULL DEFAULT 1,

    account_status   account_status_enum NOT NULL DEFAULT 'pending_verification',
    is_admin         BOOLEAN NOT NULL DEFAULT FALSE,

    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  profiles IS 'Core user profile. Extends auth.users 1-to-1. One account supports both borrower and lender activity, in whichever EAC country the account belongs to.';
COMMENT ON COLUMN profiles.phone IS 'Masked until contact reveal is triggered post-offer-acceptance.';
COMMENT ON COLUMN profiles.phone_verified_at IS
'Timestamp of OTP verification. Only the verified status is exposed as a trust signal.';
COMMENT ON COLUMN profiles.country IS
'Source of truth for the account''s market. Editable by the user; loan_requests.country is
 copied from this value at post time and then frozen, so a later correction here never
 silently moves an already-published listing into a different market''s feed.';
COMMENT ON COLUMN profiles.monthly_income IS
'Free-text numeric income figure used only for fn_income_bracket() bucketing in Pro Advanced
 Filters — never exposed as an exact figure to any other user, regardless of plan or country.';
COMMENT ON COLUMN profiles.is_admin IS
'The only role in the system. Governs platform moderation access, unrelated to marketplace
 capability, which comes entirely from subscription_plan on the subscriptions table.';

CREATE INDEX idx_profiles_country ON profiles (country);


-- ============================================
-- TABLE: user_blocks
-- Directional privacy control shared by Loans and Forex.
-- Blocking affects future marketplace discovery/interactions only; historical
-- contracts, reviews, audit logs, and completed activity remain untouched.
-- ============================================

CREATE TABLE user_blocks (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blocker_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_user_blocks_pair UNIQUE (blocker_id, blocked_id),
    CONSTRAINT chk_user_blocks_not_self CHECK (blocker_id <> blocked_id)
);

COMMENT ON TABLE user_blocks IS
'Directional account-level blocks. If A blocks B, B cannot discover, deep-link, or offer on
 A''s future loan or forex requests. Existing contracts, reviews, and audit history are kept.';

CREATE INDEX idx_user_blocks_blocker_id ON user_blocks (blocker_id);
CREATE INDEX idx_user_blocks_blocked_id ON user_blocks (blocked_id);


-- ============================================
-- TABLE: system_settings  (key-value, admin-managed)
-- v5.0: gains a nullable `country` column. NULL rows are global defaults;
-- non-null rows override a specific market. Composite-unique on
-- (setting_key, country) via a normalized expression index below, since a
-- plain UNIQUE on setting_key alone no longer holds once overrides exist.
-- ============================================

CREATE TABLE system_settings (
    setting_id    UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    setting_key   VARCHAR(100) NOT NULL,
    country       TEXT         REFERENCES countries(code),   -- NULL = global default
    setting_value TEXT,
    setting_type  setting_type_enum NOT NULL DEFAULT 'string',
    category      VARCHAR(50),
    description   TEXT,
    is_public     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  system_settings IS
'Platform configuration. All business limits read from here at runtime. A row with
 country IS NULL is the global default; a row with country set overrides that key for
 that market only. Resolve with: COALESCE(country-specific row, global row).';

-- Composite-unique on (setting_key, country), treating NULL country as a single
-- normalized value so at most one global-default row can exist per key.
CREATE UNIQUE INDEX uidx_system_settings_key_country
    ON system_settings (setting_key, COALESCE(country, '__global__'));


-- ============================================
-- DEFAULT SYSTEM SETTINGS
-- Global defaults (country IS NULL). Per-country overrides are inserted
-- later, per market, as each one is prepared for launch — see BUILD_PLAN.md
-- Stage 4.5/6.
-- ============================================

INSERT INTO system_settings (setting_key, setting_value, setting_type, category, description, is_public) VALUES
    ('min_loan_amount',         '100000',   'number',  'limits',      'Minimum loan request amount, in the request''s own currency (global default)', TRUE),
    ('max_loan_amount',         '50000000', 'number',  'limits',      'Maximum loan request amount, in the request''s own currency (global default)', TRUE),
    ('min_offer_amount',        '100000',   'number',  'limits',      'Minimum offer amount per lender, in the listing''s own currency (global default)', TRUE),
    ('max_concurrent_requests', '2',        'number',  'limits',      'Legacy fallback maximum active loan requests per borrower', TRUE),
    ('max_active_requests_free',   '2',     'number',  'limits',      'Maximum active loan requests for Free subscribers',      TRUE),
    ('max_active_requests_lender', '5',     'number',  'limits',      'Maximum active loan requests for Lender subscribers',    TRUE),
    ('max_active_requests_pro',    '15',    'number',  'limits',      'Maximum active loan requests for Pro subscribers',       TRUE),
    ('listing_duration_days',   '7',        'number',  'marketplace', 'Days a loan request stays listed before expiry',       TRUE),
    ('kyc_validity_months',     '12',       'number',  'compliance',  'Months until KYC expires and re-verification required', TRUE),
    ('platform_currency',       'UGX',      'string',  'general',     'Fallback/global-default operating currency (each market''s actual currency comes from countries.currency_code)', TRUE),
    ('market_interest_rate_baseline_pct', '10.0', 'number', 'marketplace', 'Global default market baseline interest rate percentage, controlled by admin.', TRUE),
    ('market_late_payment_rate_baseline_pct', '5.0', 'number', 'marketplace', 'Global default market baseline late-payment rate percentage, controlled by admin.', TRUE),
    ('auto_logout_minutes',     '30',       'number',  'security',    'Idle session timeout in minutes',                      FALSE),
    ('access_token_minutes',    '15',       'number',  'security',    'Access JWT TTL in minutes',                            FALSE),
    ('refresh_token_days',      '7',        'number',  'security',    'Refresh token TTL in days',                            FALSE);


-- ============================================
-- TABLE: subscriptions
-- Free plan → browse + post requests (no cost).
-- Lender plan → make offers (paid subscription required).
-- v5.0: amount_ugx renamed to amount_minor_units — currency is implied by
-- the subscriber's profiles.country, not hardcoded to UGX. Same plan tiers
-- and capabilities in every market; only the price differs.
-- ============================================

CREATE TABLE subscriptions (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    plan        subscription_plan_enum   NOT NULL DEFAULT 'free',
    status      subscription_status_enum NOT NULL DEFAULT 'active',

    started_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at  TIMESTAMP,
    amount_minor_units BIGINT NOT NULL DEFAULT 0,
    auto_renew  BOOLEAN NOT NULL DEFAULT TRUE,

    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  subscriptions IS
'One active subscription per user. free = no cost, browse and post requests.
 lender or pro plan required to make offers. amount_minor_units is only meaningful
 alongside the subscriber''s profiles.country -> countries.currency_code; the plan
 tiers themselves are identical across every market, only the price is localized.';

-- Only one active subscription per user at a time
CREATE UNIQUE INDEX uidx_sub_active_user ON subscriptions (user_id) WHERE status = 'active';


-- ============================================
-- TABLE: kyc_verifications  (optional — admin-reviewed)
-- ============================================

CREATE TABLE kyc_verifications (
    id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id               UUID UNIQUE NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    status                kyc_status_enum NOT NULL DEFAULT 'not_submitted',

    national_id_type      VARCHAR(50),
    national_id_number    VARCHAR(100),
    national_id_front_url VARCHAR(500),
    national_id_back_url  VARCHAR(500),
    selfie_url            VARCHAR(500),

    id_verified           BOOLEAN NOT NULL DEFAULT FALSE,
    selfie_verified       BOOLEAN NOT NULL DEFAULT FALSE,

    verified_by           UUID REFERENCES profiles(id) ON DELETE SET NULL,
    rejection_reason      TEXT,
    verification_notes    TEXT,

    submitted_at          TIMESTAMP,
    reviewed_at           TIMESTAMP,
    expires_at            TIMESTAMP,   -- set to submitted_at + kyc_validity_months on approval

    created_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE kyc_verifications IS
'Optional KYC. Verification badge shown on borrower profile when approved.
 Not required to post a loan request — borrowing is free and open.
 national_id_type is free text specifically so it can absorb country-specific document
 types (e.g. Kenyan ID vs Ugandan national ID formats) without a schema change.';


-- ============================================
-- TABLE: loan_requests  (borrower listings)
-- Borrowers post structured funding requests for free.
-- Contact details are never exposed until an offer is accepted.
-- v5.0: carries `country`, copied from the borrower's profile at insert
-- time by trg_fn_set_request_country() and then frozen — the listing's
-- market never silently moves if the borrower's profile country is later
-- corrected.
-- ============================================

CREATE TABLE loan_requests (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    borrower_id                 UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
    country                     TEXT NOT NULL REFERENCES countries(code),

    title                       TEXT NOT NULL,
    purpose                     TEXT NOT NULL,
    requested_amount            BIGINT NOT NULL CONSTRAINT chk_lr_amount_positive CHECK (requested_amount > 0),
    duration_months             INT NOT NULL
                                    CONSTRAINT chk_lr_duration CHECK (duration_months BETWEEN 1 AND 60),

    -- Borrower's income context. Stored for request review, but not exposed
    -- through the public marketplace listing view.
    income_source               TEXT NOT NULL,          -- e.g. 'Monthly salary from Kampala City Council'
    preferred_repayment_plan    TEXT NOT NULL           -- weekly, monthly, one_time
                                    CONSTRAINT chk_lr_repayment_plan
                                    CHECK (preferred_repayment_plan IN ('weekly', 'monthly', 'one_time')),
    repayment_amount_per_period BIGINT NOT NULL         -- e.g. 200000, in the request's own currency
                                    CONSTRAINT chk_lr_repayment_positive CHECK (repayment_amount_per_period > 0),
    repayment_timeline          TEXT NOT NULL,          -- e.g. '4 months starting March 2026'

    -- Borrower-declared collateral. Details/value/location are public risk
    -- signals only when has_collateral is true; value and location are optional.
    has_collateral              BOOLEAN NOT NULL DEFAULT FALSE,
    collateral_details          TEXT,
    collateral_estimated_value  BIGINT
                                    CONSTRAINT chk_lr_collateral_value_positive
                                    CHECK (collateral_estimated_value IS NULL OR collateral_estimated_value > 0),
    collateral_location         TEXT,

    -- Pro-tier term suggestions. These are optional, public, and
    -- locked by trigger at publish time.
    suggested_interest_rate_pct NUMERIC(5,2)
                                    CONSTRAINT chk_lr_suggested_interest_rate_range
                                    CHECK (suggested_interest_rate_pct IS NULL OR
                                           (suggested_interest_rate_pct >= 0 AND suggested_interest_rate_pct <= 100)),
    suggested_late_fee_pct      NUMERIC(5,2)
                                    CONSTRAINT chk_lr_suggested_late_fee_range
                                    CHECK (suggested_late_fee_pct IS NULL OR
                                           (suggested_late_fee_pct >= 0 AND suggested_late_fee_pct <= 100)),
    suggested_repayment_frequency TEXT
                                    CONSTRAINT chk_lr_suggested_repayment_frequency
                                    CHECK (suggested_repayment_frequency IS NULL OR
                                           suggested_repayment_frequency IN ('weekly', 'monthly', 'one_time')),
    suggested_installment_amount BIGINT
                                    CONSTRAINT chk_lr_suggested_installment_positive
                                    CHECK (suggested_installment_amount IS NULL OR suggested_installment_amount > 0),
    terms_locked_at             TIMESTAMP,

    district                    TEXT NOT NULL,

    -- Offer count only — no monetary aggregates (platform never tracks fund totals)
    number_of_offers            INT NOT NULL DEFAULT 0,

    status                      loan_status_enum NOT NULL DEFAULT 'active',

    listed_at                   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at                  TIMESTAMP,              -- set by trigger on insert
    contracted_at               TIMESTAMP,
    cancelled_at                TIMESTAMP,

    views_count                 INT NOT NULL DEFAULT 0,

    created_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  loan_requests IS
'Borrower funding requests. Free to post. borrower_id masked on all public views.
 Income and repayment fields give lenders enough context to make an informed bid.
 Pro-tier term suggestions are locked on publish. country is copied from the
 borrower''s profile at insert time and frozen thereafter.';
COMMENT ON COLUMN loan_requests.borrower_id IS
'NEVER exposed in v_loan_listings or any marketplace query. Contact revealed only post-acceptance.';
COMMENT ON COLUMN loan_requests.country IS
'Set once by trg_fn_set_request_country() at insert, from the borrower''s profiles.country.
 Immutable thereafter — see trg_fn_lock_request_terms(), which also guards this column.';
COMMENT ON COLUMN loan_requests.number_of_offers IS
'Count of offers only. No monetary totals stored — platform is non-custodial.';

CREATE INDEX idx_lr_country        ON loan_requests (country);
CREATE INDEX idx_lr_country_status ON loan_requests (country, status);


-- ============================================
-- TABLE: loan_offers  (lender offers on a borrower request)
-- Lenders must have an active lender/pro subscription to make offers.
-- Lender identity is hidden from the borrower until the offer is accepted.
-- v5.0: deliberately gets NO country column. An offer's country is always
-- its parent request's country, read through request_id -> loan_requests.
-- Storing it a second time here would create a value that can drift from
-- its source of truth for no benefit. Cross-border offers (a lender in one
-- EAC country bidding on a request in another) are allowed by default —
-- see trg_fn_validate_offer() below, which has no country check.
-- ============================================

CREATE TABLE loan_offers (
    id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id           UUID NOT NULL REFERENCES loan_requests(id) ON DELETE CASCADE,
    lender_id            UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,

    offer_amount         BIGINT NOT NULL CONSTRAINT chk_lo_amount_positive CHECK (offer_amount > 0),
    interest_rate_pct    NUMERIC(5,2) NOT NULL
                            CONSTRAINT chk_lo_interest_rate_range CHECK (interest_rate_pct >= 0 AND interest_rate_pct <= 100),
    late_fee_pct         NUMERIC(5,2) NOT NULL
                            CONSTRAINT chk_lo_late_fee_range CHECK (late_fee_pct >= 0 AND late_fee_pct <= 100),
    repayment_frequency  TEXT NOT NULL
                            CONSTRAINT chk_lo_repayment_frequency CHECK (repayment_frequency IN ('weekly', 'monthly', 'one_time')),
    installment_amount   BIGINT NOT NULL
                            CONSTRAINT chk_lo_installment_positive CHECK (installment_amount > 0),
    proposed_expectations TEXT,   -- optional: lender's additional terms or expectations
    terms_locked_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    status               offer_status_enum NOT NULL DEFAULT 'pending',

    offered_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    accepted_at          TIMESTAMP,
    withdrawn_at         TIMESTAMP,
    expires_at           TIMESTAMP,

    created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- a lender can have only one active offer per request
    UNIQUE (request_id, lender_id)
);

COMMENT ON COLUMN loan_offers.lender_id IS
'Internal FK. Lender identity hidden from borrower until the offer is accepted. May belong
 to a profile in a different EAC country than the listing — cross-border offers are allowed.';
COMMENT ON COLUMN loan_offers.offer_amount IS
'Proposed lending amount stated by lender, in the listing''s own currency
 (loan_offers.request_id -> loan_requests.country -> countries.currency_code).
 Platform never holds or moves this money.';
COMMENT ON COLUMN loan_offers.terms_locked_at IS
'Stage 4: lender bid terms are locked when the bid is submitted.';


-- ============================================
-- TABLE: watchlist
-- ============================================

CREATE TABLE watchlist (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    request_id  UUID NOT NULL REFERENCES loan_requests(id) ON DELETE CASCADE,
    added_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (user_id, request_id)
);


-- ============================================
-- TABLE: contact_reveals
-- Post-acceptance contact sharing.
-- Triggered only after a borrower accepts a lender's offer.
-- Reveals legal name, phone, and email of both parties.
-- Logged in audit_logs. Irreversible once triggered.
-- Platform never discloses identity outside this flow, in any market.
-- ============================================

CREATE TABLE contact_reveals (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    offer_id    UUID NOT NULL REFERENCES loan_offers(id) ON DELETE CASCADE,
    request_id  UUID NOT NULL REFERENCES loan_requests(id) ON DELETE CASCADE,

    -- Which party triggered the reveal (must be the borrower who accepted)
    revealed_by UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,

    status      reveal_status_enum NOT NULL DEFAULT 'pending',
    revealed_at TIMESTAMP,

    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- only one reveal record per accepted offer
    UNIQUE (offer_id)
);

COMMENT ON TABLE contact_reveals IS
'Opt-in identity disclosure triggered when a borrower accepts an offer.
 Reveals legal name, phone, and email of both parties.
 Irreversible once revealed. Enforced at the API layer, not just the UI.
 Platform never discloses identity outside this flow. No fee charged today — non-custodial.
 A flat, disclosed contact-unlock fee is a proposed, not-yet-committed change — see
 the transactions table and BUILD_PLAN.md.';


-- ============================================
-- TABLE: agreements
-- Structured locked loan agreement.
-- Auto-generated and locked after bid acceptance.
-- Contact reveal is available only after the contract is locked.
-- ============================================

CREATE TABLE agreements (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    offer_id                    UUID NOT NULL UNIQUE REFERENCES loan_offers(id) ON DELETE CASCADE,
    request_id                  UUID NOT NULL REFERENCES loan_requests(id) ON DELETE CASCADE,

    -- Locked repayment terms copied from the accepted lender bid
    repayment_frequency         repayment_frequency_enum NOT NULL,
    repayment_amount            BIGINT NOT NULL CONSTRAINT chk_agr_repayment_positive CHECK (repayment_amount > 0),
    repayment_period            INT NOT NULL CONSTRAINT chk_agr_period_positive CHECK (repayment_period > 0),
    total_repayment_amount      BIGINT NOT NULL CONSTRAINT chk_agr_total_positive CHECK (total_repayment_amount > 0),
    late_payment_penalty_pct    NUMERIC(5,2) NOT NULL DEFAULT 0 CONSTRAINT chk_agr_penalty_range CHECK (late_payment_penalty_pct >= 0 AND late_payment_penalty_pct <= 100),

    -- Agreement text + snapshot (for audit trail)
    agreement_text              TEXT NOT NULL,
    agreement_snapshot          JSONB,  -- Full snapshot at lock time for immutability, includes currency_code

    -- Contract is generated locked by accept_offer.
    status                      agreement_status_enum NOT NULL DEFAULT 'locked',
    borrower_agreed_at          TIMESTAMP,
    lender_agreed_at            TIMESTAMP,
    locked_at                   TIMESTAMP,

    created_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- only one agreement per accepted offer
    UNIQUE (offer_id)
);

COMMENT ON TABLE agreements IS
'Locked loan agreement. Auto-generated after bid acceptance.
 Late payment penalty applies only to missed installments, not the total loan.
 Agreement is read-only after generation (snapshot captured immediately, including currency_code
 so a generated contract never displays a bare number without its currency).
 All agreement events are logged in audit_logs for traceability.';

-- ============================================
-- TABLES: reviews and trust_aggregates
-- A "completed deal" means a locked agreement whose contact has been revealed.
-- It deliberately does not imply repayment, which happens off-platform.
-- Trust aggregates are GLOBAL per user, not per country — see BUILD_PLAN.md
-- "Multi-Country Expansion Model" for the rationale (reputation doesn't
-- reset at a border).
-- ============================================

CREATE TABLE reviews (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contract_id UUID NOT NULL REFERENCES agreements(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    reviewee_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    rating      SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment     TEXT CHECK (comment IS NULL OR char_length(comment) <= 500),
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (contract_id, reviewer_id),
    CHECK (reviewer_id <> reviewee_id)
);

CREATE TABLE trust_aggregates (
    user_id                    UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    rating_avg                 NUMERIC(3,2),
    review_count               INT NOT NULL DEFAULT 0,
    completed_deals_count      INT NOT NULL DEFAULT 0,
    is_repeat_participant      BOOLEAN NOT NULL DEFAULT FALSE,
    response_time_bucket       TEXT,
    success_rate               NUMERIC(5,2),
    reliability_score          INT,
    updated_at                 TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (response_time_bucket IN ('responds_quickly', 'responds_within_a_day', 'responds_slowly') OR response_time_bucket IS NULL),
    CHECK (reliability_score BETWEEN 0 AND 100 OR reliability_score IS NULL)
);

COMMENT ON TABLE reviews IS
'Immutable, one-per-party review for a completed on-platform deal. It never represents off-platform repayment behaviour.';
COMMENT ON TABLE trust_aggregates IS
'Cached, platform-scoped reputation aggregates. One row per user, GLOBAL across every EAC
 market they have participated in — never one row per user per country. Public fields and
 Pro-only analytical fields are exposed through separate views.';

-- Indexes
CREATE INDEX idx_agr_offer_id    ON agreements (offer_id);
CREATE INDEX idx_agr_request_id  ON agreements (request_id);
CREATE INDEX idx_agr_status      ON agreements (status);
CREATE INDEX idx_reviews_reviewee ON reviews (reviewee_id, created_at DESC);
CREATE INDEX idx_reviews_contract ON reviews (contract_id);

-- NOTE: trg_agreements_updated_at trigger moved to the TRIGGERS section
-- below (after fn_set_updated_at() is defined) — see "-- agreements" there.


-- ============================================
-- TABLE: notifications
-- ============================================

CREATE TABLE notifications (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    type        notification_type_enum NOT NULL,
    title       TEXT NOT NULL,
    body        TEXT NOT NULL,
    data        JSONB,

    is_read     BOOLEAN NOT NULL DEFAULT FALSE,
    read_at     TIMESTAMP,

    -- optional deep-link references
    request_id  UUID REFERENCES loan_requests(id)  ON DELETE SET NULL,
    offer_id    UUID REFERENCES loan_offers(id)     ON DELETE SET NULL,

    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- ============================================
-- TABLE: audit_logs  (append-only; UPDATE/DELETE blocked by RLS)
-- ============================================

CREATE TABLE audit_logs (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id      UUID REFERENCES profiles(id) ON DELETE SET NULL,

    event_type   audit_event_type_enum NOT NULL,
    entity_type  VARCHAR(50),
    entity_id    UUID,
    action       VARCHAR(100),
    description  TEXT,

    ip_address   INET,
    user_agent   TEXT,

    old_values   JSONB,
    new_values   JSONB,
    metadata     JSONB,

    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE audit_logs IS 'Immutable audit trail. NEVER update or delete rows. Enforced by RLS.';


-- ============================================
-- TABLE: refresh_tokens  (manual rotation audit chain)
-- ============================================

CREATE TABLE refresh_tokens (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    token_hash  TEXT NOT NULL UNIQUE,   -- bcrypt hash of the actual token
    replaced_by UUID REFERENCES refresh_tokens(id) ON DELETE SET NULL,
    revoked     BOOLEAN NOT NULL DEFAULT FALSE,
    revoked_at  TIMESTAMP,

    issued_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at  TIMESTAMP NOT NULL,

    ip_address  INET,
    user_agent  TEXT
);

COMMENT ON TABLE refresh_tokens IS
'Rotation chain: when a token is used, replaced_by is set to the new token id.
 If a revoked token is presented again, token_reuse_detected is logged to audit_logs.';


-- ============================================
-- TABLE: referrals
-- ============================================

CREATE TABLE referrals (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referrer_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    referred_email   TEXT NOT NULL,
    referred_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,

    code             TEXT NOT NULL UNIQUE,
    is_activated     BOOLEAN NOT NULL DEFAULT FALSE,
    activated_at     TIMESTAMP,
    reward_applied   BOOLEAN NOT NULL DEFAULT FALSE,

    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- ============================================
-- TABLE: transactions  (Stage 6 — Flutterwave or equivalent aggregator)
-- Scoped STRICTLY to Nipanze's own revenue: subscription charges, and the
-- contact-unlock fee IF that open decision is ever resolved to "yes".
-- NEVER touches money between a borrower and a lender — that stays
-- entirely off-platform per Architecture Constraint #1. Only a verified
-- webhook may set status = 'successful'; the client-side redirect after
-- payment is never trusted to grant access on its own.
-- ============================================

CREATE TABLE transactions (
    id                       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id                  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    type                     TEXT NOT NULL CONSTRAINT chk_tx_type CHECK (type IN ('subscription', 'contact_unlock')),
    amount                   BIGINT NOT NULL CONSTRAINT chk_tx_amount_positive CHECK (amount > 0),
    currency_code            TEXT NOT NULL,
    country                  TEXT NOT NULL REFERENCES countries(code),   -- payer's country at time of charge

    provider                 TEXT NOT NULL DEFAULT 'flutterwave',        -- plain text, not enum, so a second processor can be added later
    provider_tx_ref          TEXT NOT NULL UNIQUE,                        -- idempotency key Nipanze generates, sent to the provider
    provider_tx_id           TEXT,                                        -- provider's own reference, populated on webhook confirm

    status                   TEXT NOT NULL DEFAULT 'pending'
                                CONSTRAINT chk_tx_status CHECK (status IN ('pending', 'successful', 'failed', 'reversed')),

    related_subscription_id  UUID REFERENCES subscriptions(id),
    related_reveal_id        UUID REFERENCES contact_reveals(id),

    webhook_verified_at      TIMESTAMP,   -- set only after the provider's webhook signature check passes

    created_at               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE transactions IS
'Payment records for Nipanze''s own revenue only (subscriptions, and the contact-unlock fee
 if ever adopted) — never P2P loan funds. provider_tx_ref is generated by Nipanze before the
 charge is initiated so retries and webhook replays are idempotent. status only ever reaches
 ''successful'' via the signature-verified webhook handler (a service-role Edge Function),
 never via the client-side post-payment redirect. A user''s subscriptions.plan upgrades only
 after a linked transaction reaches ''successful'' — never optimistically.';
COMMENT ON COLUMN transactions.provider IS
'Plain text, not an enum, specifically so a second processor can be added later (e.g. a
 card-only fallback, or a different aggregator for a market Flutterwave covers thinly) without
 a schema migration.';

CREATE INDEX idx_tx_user_id  ON transactions (user_id);
CREATE INDEX idx_tx_status   ON transactions (status);
CREATE INDEX idx_tx_country  ON transactions (country);


-- ============================================
-- INDEXES
-- ============================================

-- profiles
CREATE INDEX idx_profiles_is_admin       ON profiles (is_admin) WHERE is_admin = TRUE;
CREATE INDEX idx_profiles_account_status ON profiles (account_status);

-- subscriptions
CREATE INDEX idx_sub_user_id  ON subscriptions (user_id);
CREATE INDEX idx_sub_plan     ON subscriptions (plan);
CREATE INDEX idx_sub_status   ON subscriptions (status);

-- kyc_verifications
CREATE INDEX idx_kyc_user_id ON kyc_verifications (user_id);
CREATE INDEX idx_kyc_status  ON kyc_verifications (status);

-- loan_requests
CREATE INDEX idx_lr_borrower_id   ON loan_requests (borrower_id);
CREATE INDEX idx_lr_status        ON loan_requests (status);
CREATE INDEX idx_lr_expires_at    ON loan_requests (expires_at);
CREATE INDEX idx_lr_district      ON loan_requests (district);
CREATE INDEX idx_lr_status_exp    ON loan_requests (status, expires_at);
CREATE INDEX idx_lr_active        ON loan_requests (status) WHERE status = 'active';

-- loan_offers
CREATE INDEX idx_lo_request_id    ON loan_offers (request_id);
CREATE INDEX idx_lo_lender_id     ON loan_offers (lender_id);
CREATE INDEX idx_lo_status        ON loan_offers (status);
CREATE INDEX idx_lo_req_status    ON loan_offers (request_id, status);
CREATE INDEX idx_lo_lender_status ON loan_offers (lender_id, status, offered_at DESC);

-- watchlist
CREATE INDEX idx_wl_user_id    ON watchlist (user_id);
CREATE INDEX idx_wl_request_id ON watchlist (request_id);

-- contact_reveals
CREATE INDEX idx_cr_offer_id   ON contact_reveals (offer_id);
CREATE INDEX idx_cr_request_id ON contact_reveals (request_id);

-- notifications
CREATE INDEX idx_notif_user_id   ON notifications (user_id);
CREATE INDEX idx_notif_user_read ON notifications (user_id, is_read);
CREATE INDEX idx_notif_created   ON notifications (created_at DESC);

-- audit_logs
CREATE INDEX idx_al_user_id    ON audit_logs (user_id);
CREATE INDEX idx_al_event_type ON audit_logs (event_type);
CREATE INDEX idx_al_entity     ON audit_logs (entity_type, entity_id);
CREATE INDEX idx_al_created    ON audit_logs (created_at DESC);

-- refresh_tokens
CREATE INDEX idx_rt_user_id ON refresh_tokens (user_id);
CREATE INDEX idx_rt_hash    ON refresh_tokens (token_hash);
CREATE INDEX idx_rt_expires ON refresh_tokens (expires_at);
CREATE INDEX idx_rt_active  ON refresh_tokens (user_id, expires_at) WHERE revoked = FALSE;


-- ============================================
-- FUNCTIONS: Pro Advanced Marketplace Filters (v4.2)
-- fn_income_bracket() buckets exact income into a coarse category so it can
-- be filtered on without ever exposing the exact monthly income figure.
-- ============================================

CREATE OR REPLACE FUNCTION fn_income_bracket(p_income BIGINT)
RETURNS TEXT
LANGUAGE sql IMMUTABLE
AS $$
    SELECT CASE
        WHEN p_income IS NULL THEN NULL
        WHEN p_income < 2000000  THEN 'under_2m'
        WHEN p_income < 5000000  THEN '2m_5m'
        WHEN p_income < 10000000 THEN '5m_10m'
        ELSE 'over_10m'
    END;
$$;

COMMENT ON FUNCTION fn_income_bracket(BIGINT) IS
'Buckets an exact monthly income figure into a coarse category (under_2m / 2m_5m / 5m_10m /
 over_10m) for Pro Advanced Filters. Never exposes the exact figure.';


-- ============================================
-- VIEWS
-- ============================================

-- --------------------------------------------
-- v_loan_listings
-- Anonymised public marketplace feed.
-- borrower_id, phone, email, full_name, and national ID are intentionally excluded.
-- Exposes enough structured context for lenders to make informed offers.
-- v5.0: now includes country and currency_code (joined from countries) so
-- every amount is shown alongside the currency it's denominated in.
-- --------------------------------------------
CREATE VIEW v_loan_listings AS
SELECT
    lr.id                                                                     AS request_id,
    lr.title,
    lr.purpose,
    lr.district,
    lr.country,
    c.currency_code,
    lr.duration_months,
    lr.requested_amount,
    lr.preferred_repayment_plan,
    lr.repayment_amount_per_period,
    lr.repayment_timeline,
    lr.suggested_interest_rate_pct,
    lr.suggested_late_fee_pct,
    lr.suggested_repayment_frequency,
    lr.suggested_installment_amount,
    lr.terms_locked_at,
    lr.status,
    lr.number_of_offers,
    CASE
        WHEN lr.number_of_offers = 0 THEN 'low'
        WHEN lr.number_of_offers <= 2 THEN 'medium'
        ELSE 'high'
    END                                                                       AS offer_coverage_tier,
    lr.listed_at,
    lr.expires_at,
    -- KYC badge (status only — no personal verification documents)
    k.status                                                                  AS kyc_status,
    -- Public, privacy-safe trust signals for the request owner. GLOBAL across
    -- every EAC country the owner has participated in, not just this listing's market.
    ta.rating_avg                                                             AS trust_rating_avg,
    COALESCE(ta.review_count, 0)                                              AS trust_review_count,
    COALESCE(ta.completed_deals_count, 0)                                     AS trust_completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE)                                AS trust_is_repeat_participant,
    (p.phone_verified_at IS NOT NULL)                                        AS trust_phone_verified,
    ta.response_time_bucket                                                   AS trust_response_time_bucket,
    (k.status = 'approved')                                                   AS trust_is_verified,
    -- time-remaining helpers
    GREATEST(lr.expires_at - NOW(), INTERVAL '0')                            AS time_remaining,
    (lr.expires_at < NOW() + INTERVAL '24 hours')                            AS closing_soon_24h,
    (lr.expires_at < NOW() + INTERVAL '6 hours')                             AS closing_soon_6h,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.preferred_bank ELSE NULL END                                    AS preferred_bank,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.institution_type ELSE NULL END                                  AS institution_type,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.is_bank_agent ELSE FALSE END                                    AS is_bank_agent,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN TRUE ELSE FALSE END                                               AS show_professional_tag,
    CASE WHEN EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN lr.has_collateral ELSE FALSE END                                  AS has_collateral,
    CASE WHEN EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN lr.collateral_details ELSE NULL END                               AS collateral_details,
    CASE WHEN EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN lr.collateral_estimated_value ELSE NULL END                       AS collateral_estimated_value,
    CASE WHEN EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN lr.collateral_location ELSE NULL END                              AS collateral_location
FROM  loan_requests   lr
JOIN  profiles p ON p.id = lr.borrower_id
JOIN  countries c ON c.code = lr.country
LEFT  JOIN kyc_verifications k ON k.user_id = lr.borrower_id
LEFT  JOIN trust_aggregates ta ON ta.user_id = lr.borrower_id
WHERE lr.status = 'active'
  AND (
    auth.uid() IS NULL OR lr.borrower_id <> auth.uid()
  )
  AND NOT private.is_blocked_from_future_request(lr.borrower_id, auth.uid(), lr.listed_at)
  AND (
    auth.uid() IS NULL OR NOT EXISTS (
      SELECT 1 FROM public.loan_offers lo
      WHERE lo.request_id = lr.id
        AND lo.lender_id = auth.uid()
        AND lo.status IN ('pending', 'accepted')
    )
  );

COMMENT ON VIEW v_loan_listings IS
'Anonymised marketplace feed across every EAC market. borrower_id, contact details, and
 private documents are never present. Repayment fields and Pro-tier suggestions help lenders
 make an informed bid without exposing income source. country/currency_code are always
 returned together with every amount. The Flutter client filters this feed to the user''s
 own country by default (MarketplaceRepository), with an explicit toggle to browse others —
 this view itself does not restrict by country, matching the "global browse" policy in
 BUILD_PLAN.md.';

-- Detail view for a single active loan listing.
-- Mirrors v_loan_listings but does not hide rows where the caller has already
-- made an offer; the marketplace feed still uses v_loan_listings.
CREATE VIEW v_loan_listing_details AS
SELECT
    lr.id                                                                     AS request_id,
    lr.title,
    lr.purpose,
    lr.district,
    lr.country,
    c.currency_code,
    lr.duration_months,
    lr.requested_amount,
    lr.preferred_repayment_plan,
    lr.repayment_amount_per_period,
    lr.repayment_timeline,
    lr.suggested_interest_rate_pct,
    lr.suggested_late_fee_pct,
    lr.suggested_repayment_frequency,
    lr.suggested_installment_amount,
    lr.terms_locked_at,
    lr.status,
    lr.number_of_offers,
    CASE
        WHEN lr.number_of_offers = 0 THEN 'low'
        WHEN lr.number_of_offers <= 2 THEN 'medium'
        ELSE 'high'
    END                                                                       AS offer_coverage_tier,
    lr.listed_at,
    lr.expires_at,
    k.status                                                                  AS kyc_status,
    ta.rating_avg                                                             AS trust_rating_avg,
    COALESCE(ta.review_count, 0)                                              AS trust_review_count,
    COALESCE(ta.completed_deals_count, 0)                                     AS trust_completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE)                                AS trust_is_repeat_participant,
    (p.phone_verified_at IS NOT NULL)                                        AS trust_phone_verified,
    ta.response_time_bucket                                                   AS trust_response_time_bucket,
    (k.status = 'approved')                                                   AS trust_is_verified,
    GREATEST(lr.expires_at - NOW(), INTERVAL '0')                            AS time_remaining,
    (lr.expires_at < NOW() + INTERVAL '24 hours')                            AS closing_soon_24h,
    (lr.expires_at < NOW() + INTERVAL '6 hours')                             AS closing_soon_6h,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.preferred_bank ELSE NULL END                                    AS preferred_bank,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.institution_type ELSE NULL END                                  AS institution_type,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.is_bank_agent ELSE FALSE END                                    AS is_bank_agent,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN TRUE ELSE FALSE END                                               AS show_professional_tag,
    CASE WHEN EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN lr.has_collateral ELSE FALSE END                                  AS has_collateral,
    CASE WHEN EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN lr.collateral_details ELSE NULL END                               AS collateral_details,
    CASE WHEN EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN lr.collateral_estimated_value ELSE NULL END                       AS collateral_estimated_value,
    CASE WHEN EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN lr.collateral_location ELSE NULL END                              AS collateral_location
FROM  loan_requests lr
JOIN  profiles p ON p.id = lr.borrower_id
JOIN  countries c ON c.code = lr.country
LEFT  JOIN kyc_verifications k ON k.user_id = lr.borrower_id
LEFT  JOIN trust_aggregates ta ON ta.user_id = lr.borrower_id
WHERE lr.status = 'active'
  AND NOT private.is_blocked_from_future_request(lr.borrower_id, auth.uid(), lr.listed_at);

COMMENT ON VIEW v_loan_listing_details IS
'Single-listing detail view for active loan requests. Unlike v_loan_listings, it remains
 visible to users who already placed an offer, so the detail page can load after offer
 submission. Collateral and professional tags remain Pro-masked.';


-- --------------------------------------------
-- v_user_marketplace_activity
-- Dashboard view — one query covers both borrower requests and lender offers.
-- Used in the Positions / My Requests / My Offers screens.
-- --------------------------------------------
CREATE VIEW v_user_marketplace_activity WITH (security_invoker = true) AS
SELECT
    p.id                                                                      AS user_id,
    p.full_name,
    p.country,
    p.account_status,
    -- borrower side
    COUNT(DISTINCT lr.id) FILTER (
        WHERE lr.borrower_id = p.id AND lr.status = 'active'
    )                                                                         AS active_requests,
    COUNT(DISTINCT lr.id) FILTER (
        WHERE lr.borrower_id = p.id AND lr.status = 'contracted'
    )                                                                         AS contracted_as_borrower,
    COUNT(DISTINCT lr.id) FILTER (
        WHERE lr.borrower_id = p.id AND lr.status = 'expired'
    )                                                                         AS expired_requests,
    -- lender side
    COUNT(DISTINCT lo.id) FILTER (
        WHERE lo.lender_id = p.id AND lo.status = 'pending'
    )                                                                         AS pending_offers,
    COUNT(DISTINCT lo.id) FILTER (
        WHERE lo.lender_id = p.id AND lo.status = 'accepted'
    )                                                                         AS accepted_offers,
    -- subscription
    s.plan                                                                    AS subscription_plan,
    s.status                                                                  AS subscription_status,
    s.expires_at                                                              AS subscription_expires_at,
    -- kyc
    k.status                                                                  AS kyc_status
FROM  profiles          p
LEFT  JOIN subscriptions      s  ON s.user_id     = p.id AND s.status = 'active'
LEFT  JOIN kyc_verifications  k  ON k.user_id     = p.id
LEFT  JOIN loan_requests      lr ON lr.borrower_id = p.id
LEFT  JOIN loan_offers        lo ON lo.lender_id   = p.id
GROUP BY p.id, s.plan, s.status, s.expires_at, k.status;

COMMENT ON VIEW v_user_marketplace_activity IS
'Dashboard summary covering both borrower requests and lender offers for a single user account.';

-- --------------------------------------------
-- Trust profile views
-- These contain no contact details. The public view is intentionally readable
-- without marketplace participation; the Pro view adds only derived insights.
-- Both are GLOBAL — not scoped or filtered by country in any way.
-- --------------------------------------------
CREATE VIEW v_trust_profile_public AS
SELECT
    p.id AS user_id,
    ta.rating_avg,
    COALESCE(ta.review_count, 0) AS review_count,
    COALESCE(ta.completed_deals_count, 0) AS completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE) AS is_repeat_participant,
    (p.phone_verified_at IS NOT NULL) AS phone_verified,
    ta.response_time_bucket,
    (k.status = 'approved') AS is_verified
FROM profiles p
LEFT JOIN trust_aggregates ta ON ta.user_id = p.id
LEFT JOIN kyc_verifications k ON k.user_id = p.id;

CREATE VIEW v_trust_profile_pro AS
SELECT
    tp.*,
    ta.success_rate,
    ta.reliability_score
FROM v_trust_profile_public tp
JOIN trust_aggregates ta ON ta.user_id = tp.user_id
WHERE EXISTS (
    SELECT 1 FROM subscriptions s
    WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
);


-- --------------------------------------------
-- v_lender_offers
-- Lender offer activity — for My Offers screen.
-- Does NOT expose borrower contact details.
-- v5.0: now includes country and currency_code, joined through the parent
-- listing (loan_offers has no country column of its own).
-- --------------------------------------------
CREATE VIEW v_lender_offers WITH (security_invoker = true) AS
SELECT
    lo.lender_id,
    lo.id                                                                     AS offer_id,
    lo.request_id,
    lr.title                                                                  AS listing_title,
    lr.purpose                                                                AS listing_purpose,
    lr.district,
    lr.country,
    c.currency_code,
    lr.duration_months,
    lr.requested_amount,
    lo.offer_amount,
    lo.interest_rate_pct,
    lo.late_fee_pct,
    lo.repayment_frequency,
    lo.installment_amount,
    lo.proposed_expectations,
    lo.terms_locked_at,
    lo.status                                                                 AS offer_status,
    lo.offered_at,
    lo.accepted_at,
    ta.rating_avg                                                             AS trust_rating_avg,
    COALESCE(ta.review_count, 0)                                              AS trust_review_count,
    COALESCE(ta.completed_deals_count, 0)                                     AS trust_completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE)                                AS trust_is_repeat_participant,
    (p.phone_verified_at IS NOT NULL)                                        AS trust_phone_verified,
    ta.response_time_bucket                                                   AS trust_response_time_bucket,
    (k.status = 'approved')                                                   AS trust_is_verified,
    -- contact reveal status (only populated after acceptance)
    cr.status                                                                 AS reveal_status,
    cr.revealed_at
FROM  loan_offers     lo
JOIN  loan_requests   lr ON lr.id      = lo.request_id
JOIN  countries       c  ON c.code     = lr.country
JOIN  profiles        p  ON p.id       = lo.lender_id
LEFT  JOIN kyc_verifications k ON k.user_id = lo.lender_id
LEFT  JOIN trust_aggregates ta ON ta.user_id = lo.lender_id
LEFT  JOIN contact_reveals cr ON cr.offer_id = lo.id;

COMMENT ON VIEW v_lender_offers IS
'Lender offer history with reveal status. Borrower contact details not exposed until
 reveal_status = revealed. country/currency_code are read through the parent listing
 (loan_requests), never stored on loan_offers itself.';


-- --------------------------------------------
-- v_marketplace_activity
-- Marketplace-wide KPIs for admin dashboard.
-- v5.0: now includes country, so admin can filter or group KPIs per market
-- instead of only seeing a single blended global figure.
-- --------------------------------------------
CREATE VIEW v_marketplace_activity WITH (security_invoker = true) AS
SELECT
    DATE_TRUNC('month', lr.listed_at)                                        AS month,
    lr.country,
    COUNT(lr.id)                                                              AS total_listings,
    COUNT(lr.id) FILTER (WHERE lr.status = 'active')                        AS active_listings,
    COUNT(lr.id) FILTER (WHERE lr.status = 'contracted')                    AS contracted_listings,
    COUNT(lr.id) FILTER (WHERE lr.status = 'expired')                       AS expired_listings,
    COUNT(DISTINCT lo.id) FILTER (WHERE lo.status = 'pending')              AS pending_offers,
    COUNT(DISTINCT lo.id) FILTER (WHERE lo.status = 'accepted')             AS accepted_offers,
    ROUND(
        COUNT(DISTINCT lo.request_id) * 100.0 / NULLIF(COUNT(lr.id), 0), 1
    )                                                                         AS match_rate_pct,
    (SELECT COUNT(*) FROM subscriptions
     WHERE status = 'active' AND plan != 'free')                             AS active_paid_subscribers
FROM  loan_requests lr
LEFT  JOIN loan_offers lo ON lo.request_id = lr.id
GROUP BY DATE_TRUNC('month', lr.listed_at), lr.country
ORDER BY month DESC, lr.country;

COMMENT ON VIEW v_marketplace_activity IS
'Admin KPIs, filterable/groupable by country. No monetary aggregates — non-custodial, and
 amounts are never summed across markets with different currencies (see BUILD_PLAN.md).
 Match rate measures how many listings received at least one offer.
 active_paid_subscribers is intentionally global, not per-country, in this base view.';


-- --------------------------------------------
-- v_marketplace_pro_filters  (Pro Advanced Marketplace Filters, v4.2)
-- Self-gating view: returns zero rows for any caller without an active Pro
-- subscription. Never exposes exact monthly income or employer/bank names —
-- only bucketed income and categorical employment type.
-- --------------------------------------------
CREATE VIEW v_marketplace_pro_filters WITH (security_invoker = true) AS
SELECT
    lr.id                                       AS request_id,
    lr.country,
    p.employment_type,
    fn_income_bracket(p.monthly_income)         AS income_bracket,
    (lr.suggested_interest_rate_pct IS NOT NULL) AS has_suggested_terms,
    (k.status = 'approved')                      AS owner_verified
FROM  loan_requests lr
JOIN  profiles p ON p.id = lr.borrower_id
LEFT  JOIN kyc_verifications k ON k.user_id = lr.borrower_id
WHERE lr.status = 'active'
  AND EXISTS (
      SELECT 1 FROM subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
  );

COMMENT ON VIEW v_marketplace_pro_filters IS
'Pro-only filter signals (employment type, bucketed income, suggested-terms flag, owner
 verification status) for a listing. Self-gated: returns zero rows for any caller without an
 active Pro subscription, so the DB is the enforcement point, not the Flutter client.';


-- --------------------------------------------
-- get_public_listing_offers
-- Public anonymized order book for active listings.
-- Does not expose real lender_id values.
-- --------------------------------------------
CREATE OR REPLACE FUNCTION get_public_listing_offers(p_request_id UUID)
RETURNS TABLE (
    id UUID,
    request_id UUID,
    lender_id TEXT,
    offer_amount BIGINT,
    interest_rate_pct NUMERIC,
    late_fee_pct NUMERIC,
    repayment_frequency TEXT,
    installment_amount BIGINT,
    proposed_expectations TEXT,
    terms_locked_at TIMESTAMP,
    status TEXT,
    offered_at TIMESTAMP,
    accepted_at TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = ''
AS $$
DECLARE
    v_is_owner BOOLEAN := FALSE;
    v_is_offer_maker BOOLEAN := FALSE;
BEGIN
    SELECT lr.borrower_id = auth.uid() INTO v_is_owner
    FROM public.loan_requests lr
    WHERE lr.id = p_request_id;

    SELECT EXISTS (
        SELECT 1 FROM public.loan_offers own
        WHERE own.request_id = p_request_id
          AND own.lender_id = auth.uid()
          AND own.status IN ('pending', 'accepted')
    ) INTO v_is_offer_maker;

    IF NOT COALESCE(v_is_owner, FALSE) AND NOT COALESCE(v_is_offer_maker, FALSE) THEN
        RETURN;
    END IF;

    IF COALESCE(v_is_owner, FALSE) THEN
        RETURN QUERY
        SELECT
            lo.id,
            lo.request_id,
            ('public-offer-' || ROW_NUMBER() OVER (ORDER BY lo.offered_at ASC))::TEXT AS lender_id,
            lo.offer_amount,
            lo.interest_rate_pct,
            lo.late_fee_pct,
            lo.repayment_frequency,
            lo.installment_amount,
            lo.proposed_expectations,
            lo.terms_locked_at,
            lo.status::TEXT,
            lo.offered_at,
            lo.accepted_at
        FROM public.loan_offers lo
        JOIN public.loan_requests lr ON lr.id = lo.request_id
        WHERE lo.request_id = p_request_id
          AND lo.status = 'pending'
          AND (lr.status = 'active' OR lr.borrower_id = auth.uid())
        ORDER BY lo.offered_at DESC;
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        lo.id,
        lo.request_id,
        ('your-offer')::TEXT AS lender_id,
        lo.offer_amount,
        lo.interest_rate_pct,
        lo.late_fee_pct,
        lo.repayment_frequency,
        lo.installment_amount,
        lo.proposed_expectations,
        lo.terms_locked_at,
        lo.status::TEXT,
        lo.offered_at,
        lo.accepted_at
    FROM public.loan_offers lo
    WHERE lo.request_id = p_request_id
      AND lo.lender_id = auth.uid()
      AND lo.status IN ('pending', 'accepted');
END;
$$;

COMMENT ON FUNCTION get_public_listing_offers(UUID) IS
'Participant-scoped bid book. Listing owners and offer-makers receive exact terms; all other viewers receive only v_loan_listings aggregate coverage.';


-- --------------------------------------------
-- check_phone_registered
-- Helper RPC for phone onboarding. Checks if a phone number is registered.
-- Returns the associated user's email if found, otherwise NULL.
-- --------------------------------------------
CREATE OR REPLACE FUNCTION public.check_phone_registered(p_phone TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_email TEXT;
    v_digits TEXT;
BEGIN
    v_digits := regexp_replace(p_phone, '[^\d]', '', 'g');

    SELECT au.email INTO v_email
    FROM auth.users au
    LEFT JOIN public.profiles p ON p.id = au.id
    WHERE p.phone = p_phone 
       OR au.phone = p_phone 
       OR au.email = p_phone
       OR (v_digits <> '' AND (au.email = v_digits || '@nipanze.test' OR p.phone = '+' || v_digits))
    LIMIT 1;

    RETURN v_email;
END;
$$;

GRANT EXECUTE ON FUNCTION public.check_phone_registered(TEXT) TO authenticated, anon;


-- --------------------------------------------
-- get_marketplace_pro_filtered
-- Applies Pro Advanced Filters on top of v_loan_listings. Raises if the
-- caller does not have an active Pro subscription, rather than silently
-- returning nothing, so client errors are explicit.
-- --------------------------------------------
CREATE OR REPLACE FUNCTION get_marketplace_pro_filtered(
    p_employment_type      employment_type_enum DEFAULT NULL,
    p_income_bracket       TEXT                  DEFAULT NULL,
    p_suggested_terms_only BOOLEAN               DEFAULT FALSE,
    p_verified_only        BOOLEAN               DEFAULT FALSE,
    p_country              TEXT                  DEFAULT NULL
)
RETURNS SETOF v_loan_listings
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM subscriptions
        WHERE user_id = auth.uid() AND status = 'active' AND plan = 'pro'
    ) THEN
        RAISE EXCEPTION 'NIPANZE_PRO_REQUIRED: Advanced marketplace filters require a Pro subscription.'
            USING ERRCODE = 'P0050';
    END IF;

    RETURN QUERY
    SELECT vl.*
    FROM v_loan_listings vl
    JOIN loan_requests lr ON lr.id = vl.request_id
    JOIN profiles p ON p.id = lr.borrower_id
    LEFT JOIN kyc_verifications k ON k.user_id = lr.borrower_id
    WHERE (p_employment_type IS NULL OR p.employment_type = p_employment_type)
      AND (p_income_bracket IS NULL OR fn_income_bracket(p.monthly_income) = p_income_bracket)
      AND (NOT p_suggested_terms_only OR lr.suggested_interest_rate_pct IS NOT NULL)
      AND (NOT p_verified_only OR k.status = 'approved')
      AND (p_country IS NULL OR vl.country = p_country);
END;
$$;

COMMENT ON FUNCTION get_marketplace_pro_filtered IS
'Pro-only marketplace filtering by employment type, bucketed income, suggested-terms
 presence, owner verification, and (optionally) country. Raises NIPANZE_PRO_REQUIRED for any
 caller without an active Pro subscription — the DB is the enforcement point, matching
 v_marketplace_pro_filters above.';


-- Rebuild a user's platform-scoped trust summary. This intentionally counts
-- only agreements that reached contact reveal, never repayment behaviour,
-- and is GLOBAL across every country the user has participated in.
CREATE OR REPLACE FUNCTION public.recompute_trust_aggregates(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_rating NUMERIC(3,2);
    v_reviews INT;
    v_deals INT;
    v_response_hours NUMERIC;
    v_bucket TEXT;
    v_success_rate NUMERIC(5,2);
    v_score INT;
BEGIN
    SELECT ROUND(AVG(rating)::NUMERIC, 2), COUNT(*)
      INTO v_rating, v_reviews
      FROM reviews WHERE reviewee_id = p_user_id;

    SELECT COUNT(*) INTO v_deals
    FROM agreements a
    JOIN loan_offers lo ON lo.id = a.offer_id
    JOIN loan_requests lr ON lr.id = a.request_id
    JOIN contact_reveals cr ON cr.offer_id = lo.id AND cr.status = 'revealed'
    WHERE lr.borrower_id = p_user_id OR lo.lender_id = p_user_id;

    SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY response_hours)
      INTO v_response_hours
    FROM (
        SELECT EXTRACT(EPOCH FROM (lo.offered_at - lr.listed_at)) / 3600.0 AS response_hours
        FROM loan_offers lo JOIN loan_requests lr ON lr.id = lo.request_id
        WHERE lo.lender_id = p_user_id
        UNION ALL
        SELECT EXTRACT(EPOCH FROM (first_offer_at - lr.listed_at)) / 3600.0
        FROM loan_requests lr
        JOIN LATERAL (
            SELECT MIN(lo.offered_at) AS first_offer_at
            FROM loan_offers lo WHERE lo.request_id = lr.id
        ) first_offer ON first_offer.first_offer_at IS NOT NULL
        WHERE lr.borrower_id = p_user_id
    ) response_times;

    v_bucket := CASE
        WHEN v_response_hours IS NULL THEN NULL
        WHEN v_response_hours <= 24 THEN 'responds_quickly'
        WHEN v_response_hours <= 72 THEN 'responds_within_a_day'
        ELSE 'responds_slowly'
    END;

    SELECT ROUND(
        100.0 * COUNT(*) FILTER (WHERE completed) / NULLIF(COUNT(*), 0), 2
    ) INTO v_success_rate
    FROM (
        SELECT lo.id,
               EXISTS (SELECT 1 FROM agreements a WHERE a.offer_id = lo.id) AS completed
        FROM loan_offers lo WHERE lo.lender_id = p_user_id
        UNION ALL
        SELECT lr.id,
               EXISTS (SELECT 1 FROM agreements a WHERE a.request_id = lr.id)
        FROM loan_requests lr WHERE lr.borrower_id = p_user_id
    ) participation;

    v_score := CASE WHEN v_rating IS NULL THEN NULL ELSE LEAST(100, ROUND(
        (v_rating / 5.0) * 60 + LEAST(v_deals, 4) * 5 +
        CASE v_bucket WHEN 'responds_quickly' THEN 20 WHEN 'responds_within_a_day' THEN 10 ELSE 0 END
    )::INT) END;

    INSERT INTO trust_aggregates (
        user_id, rating_avg, review_count, completed_deals_count,
        is_repeat_participant, response_time_bucket, success_rate, reliability_score, updated_at
    ) VALUES (
        p_user_id, v_rating, COALESCE(v_reviews, 0), COALESCE(v_deals, 0),
        COALESCE(v_deals, 0) >= 2, v_bucket, v_success_rate, v_score, NOW()
    ) ON CONFLICT (user_id) DO UPDATE SET
        rating_avg = EXCLUDED.rating_avg,
        review_count = EXCLUDED.review_count,
        completed_deals_count = EXCLUDED.completed_deals_count,
        is_repeat_participant = EXCLUDED.is_repeat_participant,
        response_time_bucket = EXCLUDED.response_time_bucket,
        success_rate = EXCLUDED.success_rate,
        reliability_score = EXCLUDED.reliability_score,
        updated_at = EXCLUDED.updated_at;
END;
$$;

CREATE OR REPLACE FUNCTION public.submit_review(
    p_contract_id UUID, p_rating SMALLINT, p_comment TEXT DEFAULT NULL
) RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    v_reviewer UUID := auth.uid();
    v_reviewee UUID;
    v_review_id UUID;
BEGIN
    IF v_reviewer IS NULL THEN RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED'; END IF;
    IF p_rating NOT BETWEEN 1 AND 5 THEN RAISE EXCEPTION 'NIPANZE_INVALID_RATING'; END IF;

    SELECT CASE WHEN lr.borrower_id = v_reviewer THEN lo.lender_id ELSE lr.borrower_id END
      INTO v_reviewee
    FROM agreements a
    JOIN loan_offers lo ON lo.id = a.offer_id
    JOIN loan_requests lr ON lr.id = a.request_id
    JOIN contact_reveals cr ON cr.offer_id = lo.id AND cr.status = 'revealed'
    WHERE a.id = p_contract_id
      AND (lr.borrower_id = v_reviewer OR lo.lender_id = v_reviewer);
    IF v_reviewee IS NULL THEN
        RAISE EXCEPTION 'NIPANZE_REVIEW_NOT_ELIGIBLE: Reviews require a completed on-platform deal.';
    END IF;

    INSERT INTO reviews (contract_id, reviewer_id, reviewee_id, rating, comment)
    VALUES (p_contract_id, v_reviewer, v_reviewee, p_rating, NULLIF(BTRIM(p_comment), ''))
    RETURNING id INTO v_review_id;
    PERFORM recompute_trust_aggregates(v_reviewee);
    INSERT INTO audit_logs (user_id, event_type, entity_type, entity_id, action)
    VALUES (v_reviewer, 'review_submitted', 'reviews', v_review_id, 'submit_review');
    RETURN v_review_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.trg_refresh_trust_from_reveal()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_borrower UUID; v_lender UUID;
BEGIN
    IF NEW.status = 'revealed' AND (TG_OP = 'INSERT' OR OLD.status IS DISTINCT FROM 'revealed') THEN
        SELECT lr.borrower_id, lo.lender_id INTO v_borrower, v_lender
        FROM loan_offers lo JOIN loan_requests lr ON lr.id = lo.request_id WHERE lo.id = NEW.offer_id;
        PERFORM recompute_trust_aggregates(v_borrower);
        PERFORM recompute_trust_aggregates(v_lender);
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_refresh_trust_on_reveal
AFTER INSERT OR UPDATE OF status ON contact_reveals
FOR EACH ROW EXECUTE FUNCTION trg_refresh_trust_from_reveal();


-- ============================================
-- FUNCTIONS (shared utilities)
-- ============================================

CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql
SET search_path = public AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- Generate locked contract text from accepted bid terms.
-- v5.0: accepts a currency code so the contract text never displays a bare
-- number without stating what currency it's denominated in.
CREATE OR REPLACE FUNCTION fn_generate_locked_contract_text(
    p_borrower_name TEXT,
    p_lender_name TEXT,
    p_loan_amount BIGINT,
    p_interest_rate_pct NUMERIC,
    p_total_repayment BIGINT,
    p_repayment_frequency TEXT,
    p_installment_amount BIGINT,
    p_duration_months INT,
    p_late_fee_pct NUMERIC,
    p_currency_code TEXT DEFAULT 'UGX'
)
RETURNS TEXT LANGUAGE plpgsql STABLE AS $$
BEGIN
    RETURN FORMAT(
'LOAN AGREEMENT

PARTIES
Borrower: %s
Lender: %s

LOCKED TERMS
Loan amount: %s %s
Interest rate: %s%%
Total repayment amount: %s %s
Repayment schedule: %s
Installment amount: %s %s
Duration: %s months
Start date: %s
End date: %s

LATE PAYMENT RULE
A %s%% penalty applies only to a missed installment amount, not to the total loan balance.

DISCLAIMER
Nipanze provides this agreement for convenience only. The final obligation is solely between borrower and lender. Nipanze does not enforce repayment or hold funds.

Audit timestamp: %s',
        COALESCE(p_borrower_name, 'Borrower'),
        COALESCE(p_lender_name, 'Lender'),
        p_currency_code,
        p_loan_amount,
        p_interest_rate_pct,
        p_currency_code,
        p_total_repayment,
        p_repayment_frequency,
        p_currency_code,
        p_installment_amount,
        p_duration_months,
        CURRENT_DATE,
        CURRENT_DATE + (p_duration_months || ' months')::INTERVAL,
        p_late_fee_pct,
        NOW()
    );
END;
$$;


-- ============================================
-- TRIGGER FUNCTIONS
-- ============================================

-- Set expires_at on loan_request insert using system_settings.
-- Resolves the per-country override if one exists, falling back to the
-- global default (country IS NULL) otherwise.
CREATE OR REPLACE FUNCTION trg_fn_set_listing_expiry()
RETURNS TRIGGER LANGUAGE plpgsql
SET search_path = public AS $$
DECLARE
    v_days INT;
BEGIN
    SELECT setting_value::INT INTO v_days
    FROM system_settings
    WHERE setting_key = 'listing_duration_days'
      AND (country = NEW.country OR country IS NULL)
    ORDER BY country NULLS LAST
    LIMIT 1;

    NEW.expires_at := NOW() + (v_days || ' days')::INTERVAL;
    RETURN NEW;
END;
$$;


-- v5.0: copies country from the borrower's profile onto a new loan_requests
-- row at insert time. Same "locked at post time" pattern as term-locking —
-- once set here, trg_fn_lock_request_terms() below guards it from edits.
CREATE OR REPLACE FUNCTION trg_fn_set_request_country()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
    IF NEW.country IS NULL THEN
        SELECT country INTO NEW.country FROM profiles WHERE id = NEW.borrower_id;
    END IF;
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION trg_fn_set_request_country IS
'v5.0: sets loan_requests.country from the borrower''s profiles.country at insert time,
 if not already supplied. Frozen thereafter by trg_fn_lock_request_terms().';


-- Block listing if account is not active
CREATE OR REPLACE FUNCTION trg_fn_require_active_account()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM profiles
        WHERE id = NEW.borrower_id AND account_status != 'active'
    ) THEN
        RAISE EXCEPTION 'NIPANZE_ACCOUNT_INACTIVE: Your account must be active to post a listing.'
            USING ERRCODE = 'P0001';
    END IF;
    RETURN NEW;
END;
$$;


-- Enforce plan-specific max concurrent active requests from system_settings.
-- Completed, contracted, expired, or cancelled requests do not count.
CREATE OR REPLACE FUNCTION trg_fn_max_concurrent_requests()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
    v_active_count INT;
    v_max          INT;
    v_plan         subscription_plan_enum;
BEGIN
    SELECT COALESCE(s.plan, 'free'::subscription_plan_enum) INTO v_plan
    FROM profiles p
    LEFT JOIN subscriptions s
      ON s.user_id = p.id
     AND s.status = 'active'
     AND (s.expires_at IS NULL OR s.expires_at > NOW())
    WHERE p.id = NEW.borrower_id
    LIMIT 1;

    v_plan := COALESCE(v_plan, 'free'::subscription_plan_enum);

    SELECT setting_value::INT INTO v_max
    FROM system_settings
    WHERE setting_key = ('max_active_requests_' || v_plan::TEXT)
      AND (country = NEW.country OR country IS NULL)
    ORDER BY country NULLS LAST
    LIMIT 1;

    IF v_max IS NULL THEN
        SELECT setting_value::INT INTO v_max
        FROM system_settings
        WHERE setting_key = 'max_concurrent_requests'
          AND (country = NEW.country OR country IS NULL)
        ORDER BY country NULLS LAST
        LIMIT 1;
    END IF;

    v_max := COALESCE(v_max, 2);

    SELECT COUNT(*) INTO v_active_count
    FROM loan_requests
    WHERE borrower_id = NEW.borrower_id AND status = 'active';

    IF v_active_count >= v_max THEN
        RAISE EXCEPTION 'NIPANZE_MAX_REQUESTS: You have reached the maximum of % active listings.', v_max
            USING ERRCODE = 'P0002';
    END IF;

    RETURN NEW;
END;
$$;


-- Validate optional Pro-tier term suggestions before insert.
CREATE OR REPLACE FUNCTION trg_fn_validate_request_terms()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
    v_plan subscription_plan_enum;
    v_has_suggestions BOOLEAN;
BEGIN
    v_has_suggestions :=
        NEW.suggested_interest_rate_pct IS NOT NULL OR
        NEW.suggested_late_fee_pct IS NOT NULL OR
        NEW.suggested_repayment_frequency IS NOT NULL OR
        NEW.suggested_installment_amount IS NOT NULL;

    IF v_has_suggestions THEN
        SELECT plan INTO v_plan
        FROM subscriptions
        WHERE user_id = NEW.borrower_id AND status = 'active'
        ORDER BY created_at DESC
        LIMIT 1;

        IF v_plan IS DISTINCT FROM 'pro'::subscription_plan_enum THEN
            RAISE EXCEPTION 'NIPANZE_PRO_REQUIRED: A Pro subscription is required to suggest interest, late fee, or repayment terms.'
                USING ERRCODE = 'P0004';
        END IF;
    END IF;

    NEW.terms_locked_at := COALESCE(NEW.terms_locked_at, NOW());
    RETURN NEW;
END;
$$;


-- Lock request term suggestions AND country after publish.
CREATE OR REPLACE FUNCTION trg_fn_lock_request_terms()
RETURNS TRIGGER LANGUAGE plpgsql
SET search_path = public AS $$
BEGIN
    IF OLD.terms_locked_at IS NOT NULL AND (
        OLD.suggested_interest_rate_pct IS DISTINCT FROM NEW.suggested_interest_rate_pct OR
        OLD.suggested_late_fee_pct IS DISTINCT FROM NEW.suggested_late_fee_pct OR
        OLD.suggested_repayment_frequency IS DISTINCT FROM NEW.suggested_repayment_frequency OR
        OLD.suggested_installment_amount IS DISTINCT FROM NEW.suggested_installment_amount
    ) THEN
        RAISE EXCEPTION 'NIPANZE_REQUEST_TERMS_LOCKED: Terms cannot be edited after publish.'
            USING ERRCODE = 'P0005';
    END IF;

    IF OLD.country IS DISTINCT FROM NEW.country THEN
        RAISE EXCEPTION 'NIPANZE_REQUEST_COUNTRY_LOCKED: A listing''s country is frozen at publish time and cannot be changed.'
            USING ERRCODE = 'P0006';
    END IF;

    RETURN NEW;
END;
$$;


-- Validate a lender offer before insert.
-- v5.0: no country check — cross-border offers are ALLOWED by default per
-- BUILD_PLAN.md. To restrict to single-market offers only, add a clause
-- here comparing (SELECT country FROM profiles WHERE id = NEW.lender_id)
-- against v_listing.country.
CREATE OR REPLACE FUNCTION trg_fn_validate_offer()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
    v_listing    loan_requests%ROWTYPE;
    v_min_offer  BIGINT;
    v_plan       subscription_plan_enum;
BEGIN
    -- Check listing exists and is active
    SELECT * INTO v_listing FROM loan_requests WHERE id = NEW.request_id;

    IF v_listing.status != 'active' THEN
        RAISE EXCEPTION 'NIPANZE_LISTING_NOT_ACTIVE: This listing is no longer accepting bids.'
            USING ERRCODE = 'P0010';
    END IF;

    IF v_listing.expires_at < NOW() THEN
        RAISE EXCEPTION 'NIPANZE_LISTING_EXPIRED: This listing has expired.'
            USING ERRCODE = 'P0011';
    END IF;

    -- Cannot offer on your own request
    IF v_listing.borrower_id = NEW.lender_id THEN
        RAISE EXCEPTION 'NIPANZE_SELF_OFFER: You cannot make a bid on your own listing.'
            USING ERRCODE = 'P0012';
    END IF;

    IF private.is_blocked_from_future_request(v_listing.borrower_id, NEW.lender_id, v_listing.listed_at) THEN
        RAISE EXCEPTION 'NIPANZE_BLOCKED: You cannot make a bid on this listing.'
            USING ERRCODE = 'P0017';
    END IF;

    -- Minimum offer amount (global default; per-country override takes precedence if present)
    SELECT setting_value::BIGINT INTO v_min_offer
    FROM system_settings
    WHERE setting_key = 'min_offer_amount'
      AND (country = v_listing.country OR country IS NULL)
    ORDER BY country NULLS LAST
    LIMIT 1;

    IF NEW.offer_amount < v_min_offer THEN
        RAISE EXCEPTION 'NIPANZE_MIN_OFFER: Bid amount must be at least %.', v_min_offer
            USING ERRCODE = 'P0013';
    END IF;

    -- Lender or Pro subscription required to make bids
    SELECT plan INTO v_plan
    FROM subscriptions
    WHERE user_id = NEW.lender_id AND status = 'active';

    IF v_plan NOT IN ('lender', 'pro') THEN
        RAISE EXCEPTION 'NIPANZE_SUBSCRIPTION_REQUIRED: A Lender or Pro subscription is required to make bids.'
            USING ERRCODE = 'P0014';
    END IF;

    IF NEW.interest_rate_pct IS NULL OR NEW.late_fee_pct IS NULL OR
       NEW.repayment_frequency IS NULL OR NEW.installment_amount IS NULL THEN
        RAISE EXCEPTION 'NIPANZE_BID_TERMS_REQUIRED: Interest, late fee, repayment schedule, and installment amount are required.'
            USING ERRCODE = 'P0016';
    END IF;

    NEW.terms_locked_at := COALESCE(NEW.terms_locked_at, NOW());
    RETURN NEW;
END;
$$;


-- Lock an accepted offer from further updates
CREATE OR REPLACE FUNCTION trg_fn_lock_accepted_offer()
RETURNS TRIGGER LANGUAGE plpgsql
SET search_path = public AS $$
BEGIN
    IF OLD.status = 'accepted' THEN
        RAISE EXCEPTION 'NIPANZE_OFFER_LOCKED: An accepted offer cannot be modified.'
            USING ERRCODE = 'P0015';
    END IF;
    RETURN NEW;
END;
$$;


-- Lock bid terms after submit. Status-only updates are still allowed.
CREATE OR REPLACE FUNCTION trg_fn_lock_offer_terms()
RETURNS TRIGGER LANGUAGE plpgsql
SET search_path = public AS $$
BEGIN
    IF OLD.terms_locked_at IS NOT NULL AND (
        OLD.offer_amount IS DISTINCT FROM NEW.offer_amount OR
        OLD.interest_rate_pct IS DISTINCT FROM NEW.interest_rate_pct OR
        OLD.late_fee_pct IS DISTINCT FROM NEW.late_fee_pct OR
        OLD.repayment_frequency IS DISTINCT FROM NEW.repayment_frequency OR
        OLD.installment_amount IS DISTINCT FROM NEW.installment_amount OR
        OLD.proposed_expectations IS DISTINCT FROM NEW.proposed_expectations
    ) THEN
        RAISE EXCEPTION 'NIPANZE_BID_TERMS_LOCKED: Bid terms cannot be edited after submit.'
            USING ERRCODE = 'P0017';
    END IF;
    RETURN NEW;
END;
$$;


-- Auto-expire an offer if expires_at has passed
CREATE OR REPLACE FUNCTION trg_fn_expire_offer()
RETURNS TRIGGER LANGUAGE plpgsql
SET search_path = public AS $$
BEGIN
    IF NEW.expires_at IS NOT NULL AND NEW.expires_at < CURRENT_TIMESTAMP AND NEW.status = 'pending' THEN
        NEW.status := 'expired'::offer_status_enum;
    END IF;
    RETURN NEW;
END;
$$;


-- Sync number_of_offers on loan_requests with pending offers.
CREATE OR REPLACE FUNCTION trg_fn_sync_offer_count()
RETURNS TRIGGER LANGUAGE plpgsql
SET search_path = public AS $$
DECLARE
    v_request_id UUID;
BEGIN
    v_request_id := COALESCE(NEW.request_id, OLD.request_id);

    UPDATE loan_requests lr
       SET number_of_offers = (
           SELECT COUNT(*)::INT
             FROM loan_offers lo
            WHERE lo.request_id = v_request_id
              AND lo.status = 'pending'
       )
     WHERE lr.id = v_request_id;

    RETURN COALESCE(NEW, OLD);
END;
$$;


-- ============================================
-- TRIGGERS
-- ============================================

-- countries
CREATE TRIGGER trg_countries_updated_at_noop
    BEFORE UPDATE ON countries
    FOR EACH ROW WHEN (FALSE)  -- placeholder no-op; countries has no updated_at column by design
    EXECUTE FUNCTION fn_set_updated_at();

-- profiles
CREATE TRIGGER trg_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- subscriptions
CREATE TRIGGER trg_subscriptions_updated_at
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- kyc_verifications
CREATE TRIGGER trg_kyc_updated_at
    BEFORE UPDATE ON kyc_verifications
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- system_settings
CREATE TRIGGER trg_system_settings_updated_at
    BEFORE UPDATE ON system_settings
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- loan_requests
CREATE TRIGGER trg_set_request_country
    BEFORE INSERT ON loan_requests
    FOR EACH ROW EXECUTE FUNCTION trg_fn_set_request_country();

CREATE TRIGGER trg_require_active_account
    BEFORE INSERT ON loan_requests
    FOR EACH ROW EXECUTE FUNCTION trg_fn_require_active_account();

CREATE TRIGGER trg_max_concurrent_requests
    BEFORE INSERT ON loan_requests
    FOR EACH ROW EXECUTE FUNCTION trg_fn_max_concurrent_requests();

CREATE TRIGGER trg_set_listing_expiry
    BEFORE INSERT ON loan_requests
    FOR EACH ROW EXECUTE FUNCTION trg_fn_set_listing_expiry();

CREATE TRIGGER trg_validate_request_terms
    BEFORE INSERT ON loan_requests
    FOR EACH ROW EXECUTE FUNCTION trg_fn_validate_request_terms();

CREATE TRIGGER trg_lock_request_terms
    BEFORE UPDATE ON loan_requests
    FOR EACH ROW EXECUTE FUNCTION trg_fn_lock_request_terms();

CREATE TRIGGER trg_loan_requests_updated_at
    BEFORE UPDATE ON loan_requests
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- loan_offers
CREATE TRIGGER trg_expire_offer
    BEFORE INSERT OR UPDATE ON loan_offers
    FOR EACH ROW EXECUTE FUNCTION trg_fn_expire_offer();

CREATE TRIGGER trg_validate_offer
    BEFORE INSERT ON loan_offers
    FOR EACH ROW EXECUTE FUNCTION trg_fn_validate_offer();

CREATE TRIGGER trg_lock_accepted_offer
    BEFORE UPDATE ON loan_offers
    FOR EACH ROW
    WHEN (OLD.status = 'accepted')
    EXECUTE FUNCTION trg_fn_lock_accepted_offer();

CREATE TRIGGER trg_lock_offer_terms
    BEFORE UPDATE ON loan_offers
    FOR EACH ROW EXECUTE FUNCTION trg_fn_lock_offer_terms();

CREATE TRIGGER trg_sync_offer_count
    AFTER INSERT OR UPDATE OR DELETE ON loan_offers
    FOR EACH ROW EXECUTE FUNCTION trg_fn_sync_offer_count();

CREATE TRIGGER trg_loan_offers_updated_at
    BEFORE UPDATE ON loan_offers
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- agreements (moved here from right after CREATE TABLE agreements —
-- fn_set_updated_at() must exist first)
CREATE TRIGGER trg_agreements_updated_at
    BEFORE UPDATE ON agreements
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- transactions
CREATE TRIGGER trg_transactions_updated_at
    BEFORE UPDATE ON transactions
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();


-- ============================================
-- RPC: accept_offer  (Stage 4: Creates locked agreement)
-- Atomic: accepts the chosen bid, rejects competing pending bids,
-- marks listing contracted, creates a locked agreement snapshot,
-- and notifies both parties.
-- Contact details are NOT returned here — unlock_contact is the only
-- API that reveals contact details after the contract is locked.
-- v5.0: the agreement snapshot and contract text now carry currency_code,
-- resolved from the listing's country.
-- ============================================

CREATE OR REPLACE FUNCTION private.accept_offer_internal(
    p_request_id  UUID,
    p_offer_id    UUID,
    p_borrower_id UUID,
    p_caller_id   UUID
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$
DECLARE
    v_listing public.loan_requests%ROWTYPE;
    v_offer public.loan_offers%ROWTYPE;
    v_borrower public.profiles%ROWTYPE;
    v_lender public.profiles%ROWTYPE;
    v_currency_code TEXT;
    v_agreement_id UUID;
    v_total_repayment BIGINT;
    v_agreement_text TEXT;
    v_snapshot JSONB;
BEGIN
    IF p_caller_id IS NULL OR p_caller_id != p_borrower_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Caller is not the borrower.'
            USING ERRCODE = 'P0021';
    END IF;

    SELECT * INTO v_listing FROM public.loan_requests WHERE id = p_request_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'NIPANZE_LISTING_NOT_FOUND' USING ERRCODE = 'P0020';
    END IF;
    IF v_listing.borrower_id != p_borrower_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Only the listing owner can accept a bid.'
            USING ERRCODE = 'P0021';
    END IF;
    IF v_listing.status != 'active' THEN
        RAISE EXCEPTION 'NIPANZE_LISTING_NOT_ACTIVE' USING ERRCODE = 'P0022';
    END IF;

    SELECT * INTO v_offer FROM public.loan_offers
     WHERE id = p_offer_id AND request_id = p_request_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'NIPANZE_OFFER_NOT_FOUND' USING ERRCODE = 'P0023';
    END IF;
    IF v_offer.status != 'pending' THEN
        RAISE EXCEPTION 'NIPANZE_OFFER_NOT_PENDING: This bid is no longer available.'
            USING ERRCODE = 'P0024';
    END IF;

    SELECT * INTO v_borrower FROM public.profiles WHERE id = p_borrower_id;
    SELECT * INTO v_lender FROM public.profiles WHERE id = v_offer.lender_id;
    SELECT currency_code INTO v_currency_code FROM public.countries WHERE code = v_listing.country;

    v_total_repayment := ROUND(v_offer.offer_amount * (1 + (v_offer.interest_rate_pct / 100.0)))::BIGINT;

    v_snapshot := JSONB_BUILD_OBJECT(
        'request_id', p_request_id,
        'offer_id', p_offer_id,
        'borrower_id', p_borrower_id,
        'lender_id', v_offer.lender_id,
        'country', v_listing.country,
        'currency_code', v_currency_code,
        'loan_amount', v_offer.offer_amount,
        'interest_rate_pct', v_offer.interest_rate_pct,
        'total_repayment_amount', v_total_repayment,
        'repayment_frequency', v_offer.repayment_frequency,
        'installment_amount', v_offer.installment_amount,
        'repayment_period', v_listing.duration_months,
        'late_fee_pct', v_offer.late_fee_pct,
        'late_fee_rule', 'Late fee applies only to missed installment amount, not total balance.',
        'start_date', CURRENT_DATE,
        'end_date', CURRENT_DATE + (v_listing.duration_months || ' months')::INTERVAL,
        'duration_months', v_listing.duration_months,
        'legal_disclaimer', 'Nipanze provides this agreement for convenience only. The final obligation is solely between borrower and lender. Nipanze does not enforce repayment or hold funds.',
        'locked_at', NOW()
    );

    v_agreement_text := public.fn_generate_locked_contract_text(
        v_borrower.full_name,
        v_lender.full_name,
        v_offer.offer_amount,
        v_offer.interest_rate_pct,
        v_total_repayment,
        v_offer.repayment_frequency,
        v_offer.installment_amount,
        v_listing.duration_months,
        v_offer.late_fee_pct,
        v_currency_code
    );

    UPDATE public.loan_offers SET status = 'accepted', accepted_at = NOW() WHERE id = p_offer_id;

    UPDATE public.loan_offers
       SET status = 'rejected', updated_at = NOW()
     WHERE request_id = p_request_id AND id != p_offer_id AND status = 'pending';

    UPDATE public.loan_requests
       SET status = 'contracted', contracted_at = NOW() WHERE id = p_request_id;

    INSERT INTO public.agreements (
        offer_id,
        request_id,
        repayment_frequency,
        repayment_amount,
        repayment_period,
        total_repayment_amount,
        late_payment_penalty_pct,
        agreement_text,
        agreement_snapshot,
        status,
        borrower_agreed_at,
        lender_agreed_at,
        locked_at
    )
    VALUES (
        p_offer_id,
        p_request_id,
        v_offer.repayment_frequency::public.repayment_frequency_enum,
        v_offer.installment_amount,
        v_listing.duration_months,
        v_total_repayment,
        v_offer.late_fee_pct,
        v_agreement_text,
        v_snapshot,
        'locked'::public.agreement_status_enum,
        NOW(),
        NOW(),
        NOW()
    )
    ON CONFLICT (offer_id) DO UPDATE
       SET repayment_period = EXCLUDED.repayment_period,
           total_repayment_amount = EXCLUDED.total_repayment_amount,
           agreement_text = EXCLUDED.agreement_text,
           agreement_snapshot = EXCLUDED.agreement_snapshot,
           status = 'locked'::public.agreement_status_enum,
           borrower_agreed_at = COALESCE(public.agreements.borrower_agreed_at, NOW()),
           lender_agreed_at = COALESCE(public.agreements.lender_agreed_at, NOW()),
           locked_at = COALESCE(public.agreements.locked_at, NOW())
    RETURNING id INTO v_agreement_id;

    INSERT INTO public.notifications (user_id, type, title, body, request_id, offer_id)
    VALUES
        (p_borrower_id, 'agreement_locked', 'Contract generated',
         'Your selected bid is locked into a contract. Unlock contact details to connect.',
         p_request_id, p_offer_id),
        (v_offer.lender_id, 'agreement_locked', 'Contract generated',
         'Your bid was accepted and locked into a contract. Contact unlock is now available.',
         p_request_id, p_offer_id);

    INSERT INTO public.audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
    VALUES
        (p_borrower_id, 'offer_accepted', 'loan_offers', p_offer_id, 'accept_offer', v_snapshot),
        (p_borrower_id, 'agreement_locked', 'agreements', v_agreement_id, 'generate_locked_contract', v_snapshot);

    RETURN v_agreement_id;
END;
$$;

GRANT EXECUTE ON FUNCTION private.accept_offer_internal(uuid, uuid, uuid, uuid) TO authenticated, service_role;

-- Wrapper: SECURITY INVOKER
CREATE OR REPLACE FUNCTION public.accept_offer(
    p_request_id  UUID,
    p_offer_id    UUID,
    p_borrower_id UUID
)
RETURNS UUID
LANGUAGE sql SECURITY INVOKER
SET search_path = public AS $$
    SELECT private.accept_offer_internal(p_request_id, p_offer_id, p_borrower_id, auth.uid());
$$;

REVOKE EXECUTE ON FUNCTION public.accept_offer(uuid, uuid, uuid) FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.accept_offer(uuid, uuid, uuid) TO authenticated, service_role;

COMMENT ON FUNCTION public.accept_offer IS
'Atomically accepts a bid, rejects others, marks listing contracted, and creates a locked agreement.
 Returns agreement_id. Contact details are not exposed until unlock_contact() is called.
 Platform never holds or moves funds. The agreement snapshot and contract text include
 currency_code, resolved from the listing''s country.';


-- ============================================
-- RPC: reveal_contact
-- ============================================

CREATE OR REPLACE FUNCTION private.reveal_contact_internal(
    p_reveal_id   UUID,
    p_borrower_id UUID,
    p_caller_id   UUID
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$
DECLARE
    v_reveal        public.contact_reveals%ROWTYPE;
    v_offer         public.loan_offers%ROWTYPE;
    v_borrower      public.profiles%ROWTYPE;
    v_lender        public.profiles%ROWTYPE;
    v_borrower_auth RECORD;
    v_lender_auth   RECORD;
    v_result        JSONB;
BEGIN
    -- Caller validation (must be the borrower)
    IF p_caller_id IS NULL OR p_caller_id != p_borrower_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Caller is not the borrower.'
            USING ERRCODE = 'P0031';
    END IF;

    SELECT * INTO v_reveal FROM public.contact_reveals WHERE id = p_reveal_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'NIPANZE_REVEAL_NOT_FOUND' USING ERRCODE = 'P0030';
    END IF;
    IF v_reveal.revealed_by != p_borrower_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Only the borrower who accepted can trigger reveal.'
            USING ERRCODE = 'P0031';
    END IF;
    IF v_reveal.status = 'revealed' THEN
        RAISE EXCEPTION 'NIPANZE_ALREADY_REVEALED: Contact details already revealed.'
            USING ERRCODE = 'P0032';
    END IF;

    SELECT * INTO v_offer    FROM public.loan_offers WHERE id = v_reveal.offer_id;
    SELECT * INTO v_borrower FROM public.profiles    WHERE id = p_borrower_id;
    SELECT * INTO v_lender   FROM public.profiles    WHERE id = v_offer.lender_id;

    -- auth.users requires service-role — SECURITY DEFINER gives this
    SELECT email INTO v_borrower_auth FROM auth.users WHERE id = p_borrower_id;
    SELECT email INTO v_lender_auth   FROM auth.users WHERE id = v_offer.lender_id;

    UPDATE public.contact_reveals SET status = 'revealed', revealed_at = NOW() WHERE id = p_reveal_id;

    v_result := JSONB_BUILD_OBJECT(
        'borrower', JSONB_BUILD_OBJECT(
            'full_name', v_borrower.full_name, 'phone', v_borrower.phone, 'email', v_borrower_auth.email),
        'lender', JSONB_BUILD_OBJECT(
            'full_name', v_lender.full_name, 'phone', v_lender.phone, 'email', v_lender_auth.email)
    );

    INSERT INTO public.notifications (user_id, type, title, body, request_id, offer_id)
    VALUES
        (p_borrower_id, 'contact_revealed', 'Contact details revealed',
         'You can now connect with your lender directly.', v_reveal.request_id, v_reveal.offer_id),
        (v_offer.lender_id, 'contact_revealed', 'Contact details revealed',
         'The borrower accepted your offer. You can now connect directly.', v_reveal.request_id, v_reveal.offer_id);

    INSERT INTO public.audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
    VALUES (p_borrower_id, 'contact_revealed', 'contact_reveals', p_reveal_id, 'reveal_contact',
        JSONB_BUILD_OBJECT(
            'offer_id',   v_reveal.offer_id,
            'request_id', v_reveal.request_id,
            'lender_id',  v_offer.lender_id,
            'revealed_at', NOW()
        ));

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION private.reveal_contact_internal(uuid, uuid, uuid) TO authenticated, service_role;

-- Wrapper: SECURITY INVOKER
CREATE OR REPLACE FUNCTION public.reveal_contact(
    p_reveal_id   UUID,
    p_borrower_id UUID
)
RETURNS JSONB
LANGUAGE sql SECURITY INVOKER
SET search_path = public AS $$
    SELECT private.reveal_contact_internal(p_reveal_id, p_borrower_id, auth.uid());
$$;

REVOKE EXECUTE ON FUNCTION public.reveal_contact(uuid, uuid) FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.reveal_contact(uuid, uuid) TO authenticated, service_role;

COMMENT ON FUNCTION public.reveal_contact IS
'Reveals legal name, phone, and email of both borrower and lender after an offer is accepted.
 Enforced at API layer. Irreversible. Returns contact JSONB to the calling client.
 Platform never stores or retransmits these details after this point.';


-- ============================================
-- RPC: unlock_contact (Stage 4)
-- After contract generation, borrower unlocks contact details.
-- Creates contact_reveal record (or updates existing one to 'revealed').
-- ============================================

CREATE OR REPLACE FUNCTION private.unlock_contact_internal(
    p_agreement_id UUID,
    p_caller_id    UUID
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$
DECLARE
    v_agreement  public.agreements%ROWTYPE;
    v_offer      public.loan_offers%ROWTYPE;
    v_reveal     public.contact_reveals%ROWTYPE;
    v_borrower   public.profiles%ROWTYPE;
    v_lender     public.profiles%ROWTYPE;
    v_borrower_auth RECORD;
    v_lender_auth RECORD;
    v_borrower_id UUID;
    v_lender_id UUID;
    v_result JSONB;
BEGIN
    SELECT * INTO v_agreement FROM public.agreements WHERE id = p_agreement_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'NIPANZE_AGREEMENT_NOT_FOUND' USING ERRCODE = 'P0041';
    END IF;

    IF v_agreement.status != 'locked' THEN
        RAISE EXCEPTION 'NIPANZE_AGREEMENT_NOT_LOCKED: Agreement must be locked before unlocking contact.'
            USING ERRCODE = 'P0045';
    END IF;

    SELECT * INTO v_offer FROM public.loan_offers WHERE id = v_agreement.offer_id;
    SELECT borrower_id INTO v_borrower_id FROM public.loan_requests WHERE id = v_agreement.request_id;
    v_lender_id := v_offer.lender_id;

    -- Caller validation (must be either borrower or lender)
    IF p_caller_id != v_borrower_id AND p_caller_id != v_lender_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Only deal participants can unlock contact details.'
            USING ERRCODE = 'P0046';
    END IF;

    -- Get profiles
    SELECT * INTO v_borrower FROM public.profiles WHERE id = v_borrower_id;
    SELECT * INTO v_lender FROM public.profiles WHERE id = v_lender_id;

    -- Get email from auth.users (requires SECURITY DEFINER)
    SELECT email INTO v_borrower_auth FROM auth.users WHERE id = v_borrower_id;
    SELECT email INTO v_lender_auth FROM auth.users WHERE id = v_lender_id;

    -- Get or create contact_reveal
    SELECT * INTO v_reveal FROM public.contact_reveals WHERE offer_id = v_agreement.offer_id;
    IF v_reveal IS NULL THEN
        INSERT INTO public.contact_reveals (offer_id, request_id, revealed_by, status, revealed_at)
        VALUES (v_agreement.offer_id, v_agreement.request_id, p_caller_id, 'revealed', NOW())
        RETURNING * INTO v_reveal;
    ELSE
        UPDATE public.contact_reveals
           SET status = 'revealed', revealed_at = NOW()
         WHERE id = v_reveal.id;
        v_reveal.status := 'revealed';
        v_reveal.revealed_at := NOW();
    END IF;

    -- Result includes contact details
    v_result := JSONB_BUILD_OBJECT(
        'agreement_id', v_agreement.id,
        'revealed_at', v_reveal.revealed_at,
        'borrower', JSONB_BUILD_OBJECT(
            'full_name', v_borrower.full_name,
            'phone', v_borrower.phone,
            'email', v_borrower_auth.email
        ),
        'lender', JSONB_BUILD_OBJECT(
            'full_name', v_lender.full_name,
            'phone', v_lender.phone,
            'email', v_lender_auth.email
        )
    );

    -- Notify both parties
    INSERT INTO public.notifications (user_id, type, title, body, request_id, offer_id)
    VALUES
        (v_borrower_id, 'contact_revealed', 'Contact details unlocked',
         'You can now connect with your lender directly.',
         v_agreement.request_id, v_agreement.offer_id),
        (v_lender_id, 'contact_revealed', 'Borrower unlocked contact',
         'You can now connect with the borrower directly.',
         v_agreement.request_id, v_agreement.offer_id);

    -- Audit
    INSERT INTO public.audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
    VALUES (p_caller_id, 'contact_revealed', 'contact_reveals', v_reveal.id, 'unlock_contact',
        JSONB_BUILD_OBJECT(
            'agreement_id', p_agreement_id,
            'revealed_at', NOW()
        ));

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION private.unlock_contact_internal(uuid, uuid) TO authenticated, service_role;

-- Wrapper: SECURITY INVOKER
CREATE OR REPLACE FUNCTION public.unlock_contact(p_agreement_id UUID)
RETURNS JSONB
LANGUAGE sql SECURITY INVOKER
SET search_path = public AS $$
    SELECT private.unlock_contact_internal(p_agreement_id, auth.uid());
$$;

REVOKE EXECUTE ON FUNCTION public.unlock_contact(uuid) FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.unlock_contact(uuid) TO authenticated, service_role;

COMMENT ON FUNCTION public.unlock_contact IS
'Borrower unlocks contact details after agreement is locked by bid acceptance.
 Reveals legal name, phone, and email of both parties. Irreversible. Returns contact JSONB.
 Platform never stores or retransmits these details after this point.';


-- ============================================
-- ROW-LEVEL SECURITY
-- ============================================

ALTER TABLE countries            ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings      ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles             ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions        ENABLE ROW LEVEL SECURITY;
ALTER TABLE kyc_verifications    ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_blocks          ENABLE ROW LEVEL SECURITY;
ALTER TABLE loan_requests        ENABLE ROW LEVEL SECURITY;
ALTER TABLE loan_offers          ENABLE ROW LEVEL SECURITY;
ALTER TABLE watchlist            ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_reveals      ENABLE ROW LEVEL SECURITY;
ALTER TABLE agreements           ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews              ENABLE ROW LEVEL SECURITY;
ALTER TABLE trust_aggregates     ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications        ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs           ENABLE ROW LEVEL SECURITY;
ALTER TABLE refresh_tokens       ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals            ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions         ENABLE ROW LEVEL SECURITY;


-- Helper function to safely fetch the current active user's subscription plan.
CREATE OR REPLACE FUNCTION public.get_my_subscription_plan()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_plan TEXT;
BEGIN
    SELECT plan::TEXT INTO v_plan
    FROM public.subscriptions
    WHERE user_id = auth.uid()
      AND status = 'active'
    ORDER BY created_at DESC
    LIMIT 1;

    IF v_plan IS NULL THEN
        RETURN 'free';
    END IF;
    RETURN v_plan;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_subscription_plan() TO authenticated;


-- is_admin() lives in the `private` schema so it is NOT exposed
-- via the PostgREST REST API (/rpc/is_admin) but is still
-- callable by RLS policies and other SECURITY DEFINER functions.
-- (schema itself already created near the top of this file)

CREATE OR REPLACE FUNCTION private.is_admin()
RETURNS BOOLEAN LANGUAGE SQL SECURITY DEFINER STABLE
SET search_path = public AS $$
    SELECT EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE
    );
$$;

GRANT USAGE  ON SCHEMA private TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.is_admin() TO authenticated, service_role;

CREATE OR REPLACE FUNCTION private.is_blocked_from_future_request(
    p_owner_id UUID,
    p_viewer_id UUID,
    p_listed_at TIMESTAMP
)
RETURNS BOOLEAN LANGUAGE SQL SECURITY DEFINER STABLE
SET search_path = public AS $$
    SELECT p_owner_id IS NOT NULL
       AND p_viewer_id IS NOT NULL
       AND p_owner_id <> p_viewer_id
       AND EXISTS (
           SELECT 1
           FROM user_blocks ub
           WHERE ub.blocker_id = p_owner_id
             AND ub.blocked_id = p_viewer_id
             AND ub.created_at <= COALESCE(p_listed_at, CURRENT_TIMESTAMP)
       );
$$;

GRANT EXECUTE ON FUNCTION private.is_blocked_from_future_request(UUID, UUID, TIMESTAMP)
    TO authenticated, service_role;


-- countries — public reference data, readable by everyone; admin-only writes
CREATE POLICY "countries: public read"
    ON countries FOR SELECT TO authenticated, anon USING (TRUE);
CREATE POLICY "countries: admin write"
    ON countries FOR ALL TO authenticated USING (private.is_admin());

-- system_settings
CREATE POLICY "system_settings: authenticated read"
    ON system_settings FOR SELECT TO authenticated USING (is_public = TRUE OR private.is_admin());
CREATE POLICY "system_settings: admin write"
    ON system_settings FOR ALL TO authenticated USING (private.is_admin());

-- profiles
CREATE POLICY "profiles: own or admin read"
    ON profiles FOR SELECT TO authenticated
    USING (id = auth.uid() OR private.is_admin());
CREATE POLICY "profiles: own update"
    ON profiles FOR UPDATE TO authenticated
    USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- subscriptions
CREATE POLICY "subscriptions: own or admin read"
    ON subscriptions FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR private.is_admin());
CREATE POLICY "subscriptions: own insert"
    ON subscriptions FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());
CREATE POLICY "subscriptions: own update"
    ON subscriptions FOR UPDATE TO authenticated
    USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "subscriptions: admin write"
    ON subscriptions FOR ALL TO authenticated USING (private.is_admin());


-- kyc_verifications
CREATE POLICY "kyc: own or admin read"
    ON kyc_verifications FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR private.is_admin());
CREATE POLICY "kyc: own insert"
    ON kyc_verifications FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());
CREATE POLICY "kyc: own or admin update"
    ON kyc_verifications FOR UPDATE TO authenticated
    USING (user_id = auth.uid() OR private.is_admin());

-- user_blocks
CREATE POLICY "user_blocks: blocker manages rows"
    ON user_blocks FOR ALL TO authenticated
    USING (blocker_id = auth.uid() OR private.is_admin())
    WITH CHECK (blocker_id = auth.uid() OR private.is_admin());

-- loan_requests
-- NOTE: "global browse" policy (BUILD_PLAN.md) — this does NOT restrict
-- reads to the caller's own country. The Flutter client applies the
-- country default via MarketplaceRepository. If hard per-country RLS
-- isolation is ever adopted instead, add:
--   AND (country = (SELECT country FROM profiles WHERE id = auth.uid()) OR borrower_id = auth.uid() OR private.is_admin())
CREATE POLICY "loan_requests: marketplace read"
    ON loan_requests FOR SELECT TO authenticated
    USING (
        borrower_id = auth.uid()
        OR private.is_admin()
        OR (
            status = 'active'
            AND NOT private.is_blocked_from_future_request(borrower_id, auth.uid(), listed_at)
        )
    );
CREATE POLICY "loan_requests: own insert"
    ON loan_requests FOR INSERT TO authenticated
    WITH CHECK (borrower_id = auth.uid());
CREATE POLICY "loan_requests: own or admin update"
    ON loan_requests FOR UPDATE TO authenticated
    USING (borrower_id = auth.uid() OR private.is_admin());
CREATE POLICY "loan_requests: admin delete"
    ON loan_requests FOR DELETE TO authenticated USING (private.is_admin());

-- loan_offers
-- Borrowers see offers on their own listings; lenders see their own offers; admins see all.
-- No country restriction — cross-border offers are allowed by default (see trg_fn_validate_offer).
CREATE POLICY "loan_offers: relevant parties read"
    ON loan_offers FOR SELECT TO authenticated
    USING (
        lender_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM loan_requests lr
             WHERE lr.id = loan_offers.request_id AND lr.borrower_id = auth.uid()
        )
        OR private.is_admin()
    );
CREATE POLICY "loan_offers: lender insert"
    ON loan_offers FOR INSERT TO authenticated
    WITH CHECK (
        lender_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM loan_requests lr
             WHERE lr.id = loan_offers.request_id
               AND NOT private.is_blocked_from_future_request(lr.borrower_id, auth.uid(), lr.listed_at)
        )
    );
CREATE POLICY "loan_offers: lender withdraw or admin"
    ON loan_offers FOR UPDATE TO authenticated
    USING (
        (lender_id = auth.uid() AND status = 'pending')
        OR private.is_admin()
    )
    WITH CHECK (
        (lender_id = auth.uid() AND status = 'withdrawn')
        OR private.is_admin()
    );

-- watchlist
CREATE POLICY "watchlist: own rows"
    ON watchlist FOR ALL TO authenticated
    USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- agreements
-- Only the matched parties (borrower / lender) can see the locked agreement.
CREATE POLICY "agreements: matched parties read"
    ON agreements FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM loan_requests lr
             WHERE lr.id = agreements.request_id AND lr.borrower_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM loan_offers lo
             WHERE lo.id = agreements.offer_id AND lo.lender_id = auth.uid()
        )
        OR private.is_admin()
    );
CREATE POLICY "agreements: service role insert"
    ON agreements FOR INSERT TO service_role WITH CHECK (TRUE);
CREATE POLICY "agreements: service role update"
    ON agreements FOR UPDATE TO service_role USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY "agreements: admin all"
    ON agreements FOR ALL TO authenticated USING (private.is_admin());

-- Reviews are written only through submit_review(), which validates both
-- parties and the revealed agreement. Raw review data is readable only by
-- its author/admin; public reputation is exposed through the safe views.
CREATE POLICY "reviews: author or admin read"
    ON reviews FOR SELECT TO authenticated
    USING (reviewer_id = auth.uid() OR private.is_admin());
CREATE POLICY "reviews: no direct writes"
    ON reviews FOR ALL TO authenticated USING (FALSE) WITH CHECK (FALSE);
CREATE POLICY "trust aggregates: admin only"
    ON trust_aggregates FOR SELECT TO authenticated USING (private.is_admin());

-- contact_reveals
-- Only the parties on the matched offer (borrower / lender) can see the reveal record.
CREATE POLICY "contact_reveals: matched parties read"
    ON contact_reveals FOR SELECT TO authenticated
    USING (
        revealed_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM loan_offers lo
             WHERE lo.id = contact_reveals.offer_id AND lo.lender_id = auth.uid()
        )
        OR private.is_admin()
    );
CREATE POLICY "contact_reveals: own insert"
    ON contact_reveals FOR INSERT TO authenticated
    WITH CHECK (revealed_by = auth.uid());
CREATE POLICY "contact_reveals: admin write"
    ON contact_reveals FOR ALL TO authenticated USING (private.is_admin());

-- notifications
CREATE POLICY "notifications: own rows"
    ON notifications FOR SELECT TO authenticated USING (
        user_id = auth.uid()
        AND (
            request_id IS NULL
            OR NOT EXISTS (
                SELECT 1 FROM loan_requests lr
                 WHERE lr.id = notifications.request_id
                   AND private.is_blocked_from_future_request(lr.borrower_id, auth.uid(), lr.listed_at)
            )
        )
    );
CREATE POLICY "notifications: own mark read"
    ON notifications FOR UPDATE TO authenticated
    USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "notifications: admin write"
    ON notifications FOR ALL TO authenticated USING (private.is_admin());

-- audit_logs  (append-only — UPDATE and DELETE are blocked)
CREATE POLICY "audit_logs: own or admin read"
    ON audit_logs FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR private.is_admin());
CREATE POLICY "audit_logs: insert only"
    ON audit_logs FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "audit_logs: no update"
    ON audit_logs FOR UPDATE TO authenticated USING (FALSE);
CREATE POLICY "audit_logs: no delete"
    ON audit_logs FOR DELETE TO authenticated USING (FALSE);

-- refresh_tokens
CREATE POLICY "refresh_tokens: own or admin read"
    ON refresh_tokens FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR private.is_admin());
CREATE POLICY "refresh_tokens: own insert"
    ON refresh_tokens FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "refresh_tokens: own update"
    ON refresh_tokens FOR UPDATE TO authenticated USING (user_id = auth.uid());

-- referrals
CREATE POLICY "referrals: own or admin read"
    ON referrals FOR SELECT TO authenticated
    USING (referrer_id = auth.uid() OR private.is_admin());
CREATE POLICY "referrals: own insert"
    ON referrals FOR INSERT TO authenticated WITH CHECK (referrer_id = auth.uid());
CREATE POLICY "referrals: admin write"
    ON referrals FOR ALL TO authenticated USING (private.is_admin());

-- transactions — own or admin read; all writes go through the service-role
-- webhook Edge Function, never directly from the Flutter client.
CREATE POLICY "transactions: own or admin read"
    ON transactions FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR private.is_admin());
CREATE POLICY "transactions: service role write"
    ON transactions FOR ALL TO service_role USING (TRUE) WITH CHECK (TRUE);


-- ============================================
-- REALTIME PUBLICATIONS
-- ============================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        CREATE PUBLICATION supabase_realtime;
    END IF;
END $$;

ALTER PUBLICATION supabase_realtime ADD TABLE loan_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE loan_offers;
ALTER PUBLICATION supabase_realtime ADD TABLE agreements;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE contact_reveals;


-- ============================================
-- DATABASE COMMENT
-- ============================================

DO $$
DECLARE db TEXT;
BEGIN
    SELECT current_database() INTO db;
    EXECUTE FORMAT('COMMENT ON DATABASE %I IS %L', db,
        'Nipanze v5.0 — Non-custodial loan listing matchmaking marketplace across the East '
        'African Community, Uganda-first. Unified marketplace: no stored borrower/lender role, '
        'capability comes from subscription_plan. Country is explicit, indexed, and locked at '
        'creation for listings; trust signals are global, not per-country. Borrowing is free. '
        'Lender offers require a subscription. Contact revealed only after offer acceptance. '
        'Platform never holds or tracks funds between borrower and lender, in any market.');
END $$;


-- ============================================
-- STORAGE BUCKETS
-- ============================================
-- Create via Supabase CLI or dashboard:
--   supabase storage create verification-documents --public=false

-- ============================================
-- STORAGE RLS POLICIES: verification-documents
-- ============================================
-- Files are stored under <user_uuid>/<docType>_<timestamp>.<ext>
-- Policy: each user may only access their own folder.

-- Users can upload their own KYC documents
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename  = 'objects'
      AND policyname = 'Users can upload their own KYC documents'
  ) THEN
    CREATE POLICY "Users can upload their own KYC documents"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
      bucket_id = 'verification-documents'
      AND (storage.foldername(name))[1] = auth.uid()::text
    );
  END IF;
END $$;

-- Users can read (view) their own KYC documents
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename  = 'objects'
      AND policyname = 'Users can view their own KYC documents'
  ) THEN
    CREATE POLICY "Users can view their own KYC documents"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
      bucket_id = 'verification-documents'
      AND (storage.foldername(name))[1] = auth.uid()::text
    );
  END IF;
END $$;

-- Users can replace (upsert) their own KYC documents
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename  = 'objects'
      AND policyname = 'Users can update their own KYC documents'
  ) THEN
    CREATE POLICY "Users can update their own KYC documents"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (
      bucket_id = 'verification-documents'
      AND (storage.foldername(name))[1] = auth.uid()::text
    );
  END IF;
END $$;

-- Admins (service_role) can read all KYC documents for review
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename  = 'objects'
      AND policyname = 'Admins can view all KYC documents'
  ) THEN
    CREATE POLICY "Admins can view all KYC documents"
    ON storage.objects FOR SELECT
    TO service_role
    USING (bucket_id = 'verification-documents');
  END IF;
END $$;

-- ============================================
-- FUNCTION SECURITY (Disable public access for SECURITY DEFINER functions)
-- ============================================

-- Revoke public/authenticated/anon access on trigger/internal functions
REVOKE EXECUTE ON FUNCTION public.handle_new_auth_user() FROM public, authenticated, anon;
REVOKE EXECUTE ON FUNCTION public.trg_fn_require_active_account() FROM public, authenticated, anon;
REVOKE EXECUTE ON FUNCTION public.trg_fn_max_concurrent_requests() FROM public, authenticated, anon;
REVOKE EXECUTE ON FUNCTION public.trg_fn_validate_offer() FROM public, authenticated, anon;
REVOKE EXECUTE ON FUNCTION public.trg_fn_set_request_country() FROM public, authenticated, anon;

-- Revoke public/anon access on client-facing RPCs and restrict to authenticated/service_role
-- is_admin is in the private schema — only grant to authenticated for RLS use
REVOKE EXECUTE ON FUNCTION private.is_admin() FROM public, anon;
GRANT  EXECUTE ON FUNCTION private.is_admin() TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.accept_offer(uuid, uuid, uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.accept_offer(uuid, uuid, uuid) TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.reveal_contact(uuid, uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.reveal_contact(uuid, uuid) TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.get_my_subscription_plan() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.get_my_subscription_plan() TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION get_marketplace_pro_filtered(employment_type_enum, TEXT, BOOLEAN, BOOLEAN, TEXT) FROM public, anon;
GRANT EXECUTE ON FUNCTION get_marketplace_pro_filtered(employment_type_enum, TEXT, BOOLEAN, BOOLEAN, TEXT) TO authenticated, service_role;


-- ============================================
-- VIEW: v_lender_rate_history
-- Safe, identity-preserving view for lender rate sparklines.
-- Exposes only numeric trend data — no borrower info, no PII.
-- ============================================
CREATE OR REPLACE VIEW public.v_lender_rate_history
WITH (security_invoker = true) AS
SELECT
    lender_id,
    interest_rate_pct,
    late_fee_pct,
    installment_amount,
    offered_at,
    ROW_NUMBER() OVER (
        PARTITION BY lender_id ORDER BY offered_at DESC
    ) AS rn
FROM public.loan_offers
WHERE status IN ('pending', 'accepted', 'rejected');


-- ============================================
-- RPC: consume_free_unlock()
-- Atomically decrements free_unlocks_remaining for the calling user.
-- Returns new remaining count. Raises NIPANZE_NO_FREE_UNLOCKS if count=0.
-- ============================================
CREATE OR REPLACE FUNCTION public.consume_free_unlock()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id   UUID := auth.uid();
    v_remaining INT;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED';
    END IF;

    SELECT free_unlocks_remaining
      INTO v_remaining
      FROM profiles
     WHERE id = v_user_id
       FOR UPDATE;

    IF v_remaining IS NULL THEN
        RAISE EXCEPTION 'NIPANZE_PROFILE_NOT_FOUND';
    END IF;

    IF v_remaining <= 0 THEN
        RAISE EXCEPTION 'NIPANZE_NO_FREE_UNLOCKS';
    END IF;

    UPDATE profiles
       SET free_unlocks_remaining = free_unlocks_remaining - 1,
           updated_at             = NOW()
     WHERE id = v_user_id
    RETURNING free_unlocks_remaining INTO v_remaining;

    RETURN v_remaining;
END;
$$;

COMMENT ON FUNCTION public.consume_free_unlock() IS
'Atomically decrements free_unlocks_remaining for the calling authenticated user. '
'Returns new remaining count. Raises NIPANZE_NO_FREE_UNLOCKS if count is already 0.';


-- ============================================
-- END OF SCHEMA v5.0
-- ============================================
-- Grants for views
GRANT SELECT ON countries TO authenticated, anon;
GRANT SELECT ON v_loan_listings TO authenticated, anon;
GRANT SELECT ON v_loan_listing_details TO authenticated, anon;
GRANT SELECT ON v_user_marketplace_activity TO authenticated, anon;
GRANT SELECT ON v_lender_offers TO authenticated, anon;
GRANT SELECT ON v_marketplace_activity TO authenticated, anon;
GRANT SELECT ON v_marketplace_pro_filters TO authenticated;
GRANT SELECT ON v_trust_profile_public TO authenticated, anon;
GRANT SELECT ON v_trust_profile_pro TO authenticated;
GRANT EXECUTE ON FUNCTION fn_income_bracket(BIGINT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.submit_review(UUID, SMALLINT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.recompute_trust_aggregates(UUID) TO service_role;

-- Explicitly grant privileges on schema and tables
GRANT USAGE ON SCHEMA public TO authenticated, anon, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated, service_role;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO authenticated, anon, service_role;
GRANT EXECUTE ON FUNCTION public.check_phone_registered(TEXT) TO authenticated, anon, service_role;

GRANT SELECT ON public.v_lender_rate_history TO authenticated;
GRANT EXECUTE ON FUNCTION public.consume_free_unlock() TO authenticated;


-- ==============================================================================
-- 2. BASE SEED DATA (sql/seed.sql)
-- ==============================================================================

-- ============================================
-- NIPANZE Seed Data  sql/seed.sql
-- Version: 5.1 (Country-organized, user counts matched across all countries)
-- Matches schema v5.0 exactly (countries table, profiles.country,
-- loan_requests.country, subscriptions.amount_minor_units, no
-- loan_offers.country -- country is always read through request_id).
-- ============================================
--
-- v5.1: every country now has the SAME number of users as Uganda (17),
-- mirroring Uganda's role mix so each country's block is a drop-in
-- parallel of the others:
--   8 active borrowers (free plan)
--   5 lenders (mix of 'lender' / 'pro' plans)
--   1 pending_verification borrower (tests the account-status gate)
--   2 admins (is_admin = TRUE)
--   1 test user
-- = 17 users per country x 8 countries (UG + KE, TZ, RW, BI, SS, CD, SO)
--   = 136 total seeded users.
--
-- Organization: Part A seeds users country-by-country (auth.users ->
-- profiles -> subscriptions), so any single country's users can be
-- inspected, reset, or re-run independently. Part B (marketplace data)
-- is separate because loan_offers can legitimately cross borders
-- (trg_fn_validate_offer allows this by default) -- a request seeded in
-- one country's block may carry an offer from a lender seeded in a
-- different country's block, so requests/offers/agreements/reveals are
-- grouped together afterward, by the request's country, in listing order.
--
-- Password for ALL accounts: Test1234!
--
-- FIXED UUIDs -- Uganda (unchanged from prior versions): ...0001-...0017
-- FIXED UUIDs -- new countries, 17 consecutive IDs each, in this order:
--   Kenya       ...0018-...0034   (borrowers 018-025, lenders 026-030, pending 031, admins 032-033, test 034)
--   Tanzania    ...0035-...0051   (borrowers 035-042, lenders 043-047, pending 048, admins 049-050, test 051)
--   Rwanda      ...0052-...0068   (borrowers 052-059, lenders 060-064, pending 065, admins 066-067, test 068)
--   Burundi     ...0069-...0085   (borrowers 069-076, lenders 077-081, pending 082, admins 083-084, test 085)
--   South Sudan ...0086-...0102   (borrowers 086-093, lenders 094-098, pending 099, admins 100-101, test 102)
--   DR Congo    ...0103-...0119   (borrowers 103-110, lenders 111-115, pending 116, admins 117-118, test 119)
--   Somalia     ...0120-...0136   (borrowers 120-127, lenders 128-132, pending 133, admins 134-135, test 136)
--
-- Each country's borrower[0] and lender[0] (first names in each list) are
-- the ones referenced in the marketplace demo data in Part B, so e.g.
-- Kenya's "Wanjiru Kamau" (...0018) and "Otieno Mwangi" (...0026) keep
-- their names and roles from earlier seed versions.
-- ============================================


-- ============================================================
-- PART A -- USERS, ORGANIZED BY COUNTRY
-- ============================================================
-- COUNTRY: UGANDA (UG)
-- ============================================

-- ---- UG: auth.users ----
INSERT INTO auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    is_super_admin, role, aud,
    confirmation_token, recovery_token,
    email_change_token_new, email_change,
    email_change_token_current, phone_change,
    phone_change_token, reauthentication_token
) VALUES
('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000', 'david.mukasa@gmail.com', crypt('Test1234!', gen_salt('bf')),
 NOW(), '2024-01-15 08:30:00', '2024-01-15 08:30:00', '{"provider":"email","providers":["email"]}', '{"full_name":"David Mukasa","country_code":"UG"}',
 FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000000', 'sarah.namukasa@yahoo.com', crypt('Test1234!', gen_salt('bf')),
 NOW(), '2024-01-18 10:45:00', '2024-01-18 10:45:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Sarah Namukasa","country_code":"UG"}',
 FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000000', 'james.okello@outlook.com', crypt('Test1234!', gen_salt('bf')),
 NOW(), '2024-01-20 14:20:00', '2024-01-20 14:20:00', '{"provider":"email","providers":["email"]}', '{"full_name":"James Okello","country_code":"UG"}',
 FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000000', 'maria.nakato@gmail.com', crypt('Test1234!', gen_salt('bf')),
 NOW(), '2024-01-22 09:10:00', '2024-01-22 09:10:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Maria Nakato","country_code":"UG"}',
 FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000000', 'robert.ssemwanga@gmail.com', crypt('Test1234!', gen_salt('bf')),
 NOW(), '2024-01-25 11:30:00', '2024-01-25 11:30:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Robert Ssemwanga","country_code":"UG"}',
 FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000000', 'info@greenleafagro.co.ug', crypt('Test1234!', gen_salt('bf')),
 NOW(), '2024-02-18 09:20:00', '2024-02-18 09:20:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Michael Semakula","country_code":"UG"}',
 FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000000', 'contact@kampalatech.ug', crypt('Test1234!', gen_salt('bf')),
 NOW(), '2024-02-20 11:40:00', '2024-02-20 11:40:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Sandra Namutebi","country_code":"UG"}',
 FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000000', 'invest@pearlcapital.ug', crypt('Test1234!', gen_salt('bf')),
 NOW(), '2024-03-01 10:10:00', '2024-03-01 10:10:00', '{"provider":"email","providers":["email"]}', '{"full_name":"William Kasujja","country_code":"UG"}',
 FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000000', 'funds@victoriainvest.co.ug', crypt('Test1234!', gen_salt('bf')),
 NOW(), '2024-03-03 12:30:00', '2024-03-03 12:30:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Catherine Namboze","country_code":"UG"}',
 FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000000', 'lending@equatorfinance.ug', crypt('Test1234!', gen_salt('bf')),
 NOW(), '2024-03-05 09:45:00', '2024-03-05 09:45:00', '{"provider":"email","providers":["email"]}', '{"full_name":"George Mulindwa","country_code":"UG"}',
 FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000000', 'frank.omondi@gmail.com', crypt('Test1234!', gen_salt('bf')),
 NOW(), '2024-03-08 14:15:00', '2024-03-08 14:15:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Frank Omondi","country_code":"UG"}',
 FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000000', 'lucy.nambi@yahoo.com', crypt('Test1234!', gen_salt('bf')),
 NOW(), '2024-03-10 11:20:00', '2024-03-10 11:20:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Lucy Nambi","country_code":"UG"}',
 FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000013', '00000000-0000-0000-0000-000000000000', 'charles.mwesigwa@gmail.com', crypt('Test1234!', gen_salt('bf')),
 NOW(), '2024-03-12 16:40:00', '2024-03-12 16:40:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Charles Mwesigwa","country_code":"UG"}',
 FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000014', '00000000-0000-0000-0000-000000000000', 'alice.namuli@gmail.com', crypt('Test1234!', gen_salt('bf')),
 NOW(), '2026-01-25 09:15:00', '2026-01-25 09:15:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Alice Namuli","country_code":"UG"}',
 FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000000', 'admin1@nipanze.ug', crypt('Test1234!', gen_salt('bf')),
 NOW(), '2024-01-01 08:00:00', '2024-01-01 08:00:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Admin One","country_code":"UG"}',
 FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000016', '00000000-0000-0000-0000-000000000000', 'admin2@nipanze.ug', crypt('Test1234!', gen_salt('bf')),
 NOW(), '2024-01-01 08:00:00', '2024-01-01 08:00:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Admin Two","country_code":"UG"}',
 FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000017', '00000000-0000-0000-0000-000000000000', 'test.user@gmail.com', crypt('Test1234!', gen_salt('bf')),
 NOW(), '2026-02-06 10:00:00', '2026-02-06 10:00:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Test User","country_code":"UG"}',
 FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', '')
ON CONFLICT (id) DO NOTHING;

-- ---- UG: profiles / subscriptions fallback provisioning ----
-- (Guards against the on_auth_user_created trigger not firing if these
-- auth.users rows already existed from a prior run — see header note.)
INSERT INTO public.profiles (id, full_name, account_status, is_admin, country)
SELECT au.id, COALESCE(au.raw_user_meta_data->>'full_name', SPLIT_PART(au.email, '@', 1)), 'pending_verification', FALSE, 'UG'
FROM auth.users au
WHERE au.id::text LIKE '10000000-0000-0000-0000-0000000000%'
  AND au.id::text ~ '0000000000(0[1-9]|1[0-7])$'
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.subscriptions (user_id, plan, status, amount_minor_units)
SELECT au.id, 'free', 'active', 0
FROM auth.users au
WHERE au.id::text ~ '0000000000(0[1-9]|1[0-7])$'
ON CONFLICT (user_id) WHERE status = 'active' DO NOTHING;

-- ---- UG: profile details ----
UPDATE profiles SET full_name='David Mukasa', phone='+256701234567', district='Central', country='UG',
    employment_type='government_employee', employer_name='Uganda Revenue Authority', monthly_income=4500000, income_currency='UGX',
    account_status='active', created_at='2024-01-15 08:30:00'
WHERE id='10000000-0000-0000-0000-000000000001';

UPDATE profiles SET full_name='Sarah Namukasa', phone='+256702345678', district='Central', country='UG',
    employment_type='employed', employer_name='Stanbic Bank Uganda', monthly_income=3200000, income_currency='UGX',
    account_status='active', created_at='2024-01-18 10:45:00'
WHERE id='10000000-0000-0000-0000-000000000002';

UPDATE profiles SET full_name='James Okello', phone='+256703456789', district='Central', country='UG',
    employment_type='employed', employer_name='MTN Uganda', monthly_income=5800000, income_currency='UGX',
    account_status='active', created_at='2024-01-20 14:20:00'
WHERE id='10000000-0000-0000-0000-000000000003';

UPDATE profiles SET full_name='Maria Nakato', phone='+256704567890', district='Central', country='UG',
    employment_type='small_business_owner', employer_name='Nakato Boutique', monthly_income=2800000, income_currency='UGX',
    account_status='active', created_at='2024-01-22 09:10:00'
WHERE id='10000000-0000-0000-0000-000000000004';

UPDATE profiles SET full_name='Robert Ssemwanga', phone='+256705678901', district='Central', country='UG',
    employment_type='employed', employer_name='DFCU Bank', monthly_income=6500000, income_currency='UGX',
    account_status='active', created_at='2024-01-25 11:30:00'
WHERE id='10000000-0000-0000-0000-000000000005';

UPDATE profiles SET full_name='Michael Semakula', phone='+256711234567', district='Central', country='UG',
    employment_type='business_owner', employer_name='GreenLeaf Agro Solutions Ltd', monthly_income=15000000, income_currency='UGX',
    account_status='active', created_at='2024-02-18 09:20:00'
WHERE id='10000000-0000-0000-0000-000000000006';

UPDATE profiles SET full_name='Sandra Namutebi', phone='+256712345678', district='Central', country='UG',
    employment_type='business_owner', employer_name='Kampala Tech Innovations', monthly_income=12000000, income_currency='UGX',
    account_status='active', created_at='2024-02-20 11:40:00'
WHERE id='10000000-0000-0000-0000-000000000007';

UPDATE profiles SET full_name='William Kasujja', phone='+256716789012', district='Central', country='UG',
    employment_type='business_owner', employer_name='Pearl Capital Investment Fund', monthly_income=25000000, income_currency='UGX',
    account_status='active', created_at='2024-03-01 10:10:00'
WHERE id='10000000-0000-0000-0000-000000000008';

UPDATE profiles SET full_name='Catherine Namboze', phone='+256717890123', district='Central', country='UG',
    employment_type='business_owner', employer_name='Victoria Investment Group', monthly_income=22000000, income_currency='UGX',
    account_status='active', created_at='2024-03-03 12:30:00'
WHERE id='10000000-0000-0000-0000-000000000009';

UPDATE profiles SET full_name='George Mulindwa', phone='+256718901234', district='Central', country='UG',
    employment_type='business_owner', employer_name='Equator Finance Corporation', monthly_income=28000000, income_currency='UGX',
    account_status='active', created_at='2024-03-05 09:45:00'
WHERE id='10000000-0000-0000-0000-000000000010';

UPDATE profiles SET full_name='Frank Omondi', phone='+256719012345', district='Eastern', country='UG',
    employment_type='employed', employer_name='Bank of Africa', monthly_income=3300000, income_currency='UGX',
    account_status='active', created_at='2024-03-08 14:15:00'
WHERE id='10000000-0000-0000-0000-000000000011';

UPDATE profiles SET full_name='Lucy Nambi', phone='+256720123456', district='Central', country='UG',
    employment_type='employed', employer_name='National Social Security Fund', monthly_income=2900000, income_currency='UGX',
    account_status='active', created_at='2024-03-10 11:20:00'
WHERE id='10000000-0000-0000-0000-000000000012';

UPDATE profiles SET full_name='Charles Mwesigwa', phone='+256721234567', district='Western', country='UG',
    employment_type='employed', employer_name='Shell Uganda', monthly_income=5200000, income_currency='UGX',
    account_status='active', created_at='2024-03-12 16:40:00'
WHERE id='10000000-0000-0000-0000-000000000013';

-- Alice Namuli — pending_verification (tests the account-status gate)
UPDATE profiles SET full_name='Alice Namuli', phone='+256726789012', district='Central', country='UG',
    employment_type='employed', employer_name='Equity Bank', monthly_income=2700000, income_currency='UGX',
    account_status='pending_verification', created_at='2026-01-25 09:15:00'
WHERE id='10000000-0000-0000-0000-000000000014';

-- Admins (is_admin boolean is the only role concept — no `role` column)
UPDATE profiles SET full_name='Admin One', phone='+256700000001', district='Central', country='UG',
    account_status='active', is_admin=TRUE, created_at='2024-01-01 08:00:00'
WHERE id='10000000-0000-0000-0000-000000000015';

UPDATE profiles SET full_name='Admin Two', phone='+256700000002', district='Central', country='UG',
    account_status='active', is_admin=TRUE, created_at='2024-01-01 08:00:00'
WHERE id='10000000-0000-0000-0000-000000000016';

-- Test user — tests onboarding gate
UPDATE profiles SET full_name='Test User', phone='+256799999999', district='Central', country='UG',
    account_status='active', created_at='2026-02-06 10:00:00'
WHERE id='10000000-0000-0000-0000-000000000017';

-- ---- UG: KYC (optional; not required to post a request) ----
INSERT INTO kyc_verifications (
    id, user_id, status, national_id_type, national_id_number,
    national_id_front_url, national_id_back_url, selfie_url,
    id_verified, selfie_verified, verified_by,
    submitted_at, reviewed_at, expires_at, created_at
) VALUES
('a1000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'approved', 'national_id', 'CM88015KL234567', 'https://storage.nipanze.ug/kyc/user-001-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-001-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-001-selfie.jpg', TRUE, TRUE, '10000000-0000-0000-0000-000000000015', '2024-01-15 09:15:00', '2024-01-16 10:30:00', '2027-01-15 00:00:00', '2024-01-15 09:15:00'),
('a1000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', 'approved', 'national_id', 'CM92022NM345678', 'https://storage.nipanze.ug/kyc/user-002-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-002-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-002-selfie.jpg', TRUE, TRUE, '10000000-0000-0000-0000-000000000015', '2024-01-18 11:00:00', '2024-01-19 11:45:00', '2027-01-18 00:00:00', '2024-01-18 11:00:00'),
('a1000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000003', 'approved', 'national_id', 'CM85011OK345679', 'https://storage.nipanze.ug/kyc/user-003-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-003-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-003-selfie.jpg', TRUE, TRUE, '10000000-0000-0000-0000-000000000016', '2024-01-20 14:30:00', '2024-01-21 09:30:00', '2027-01-20 00:00:00', '2024-01-20 14:30:00'),
('a1000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000004', 'approved', 'national_id', 'CM90014NK567890', 'https://storage.nipanze.ug/kyc/user-004-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-004-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-004-selfie.jpg', TRUE, TRUE, '10000000-0000-0000-0000-000000000016', '2024-01-22 09:30:00', '2024-01-23 14:30:00', '2027-01-22 00:00:00', '2024-01-22 09:30:00'),
('a1000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000005', 'approved', 'national_id', 'CM87030SS678901', 'https://storage.nipanze.ug/kyc/user-005-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-005-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-005-selfie.jpg', TRUE, TRUE, '10000000-0000-0000-0000-000000000015', '2024-01-25 11:45:00', '2024-01-25 16:00:00', '2027-01-25 00:00:00', '2024-01-25 11:45:00'),
('a1000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000006', 'approved', 'national_id', 'CM80020SM456789', 'https://storage.nipanze.ug/kyc/user-006-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-006-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-006-selfie.jpg', TRUE, TRUE, '10000000-0000-0000-0000-000000000016', '2024-02-18 09:00:00', '2024-02-19 10:30:00', '2027-02-18 00:00:00', '2024-02-18 09:00:00'),
('a1000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000007', 'approved', 'national_id', 'CM83015SN789012', 'https://storage.nipanze.ug/kyc/user-007-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-007-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-007-selfie.jpg', TRUE, TRUE, '10000000-0000-0000-0000-000000000015', '2024-02-20 10:00:00', '2024-02-21 11:00:00', '2027-02-20 00:00:00', '2024-02-20 10:00:00'),
('a1000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000008', 'approved', 'national_id', 'CM75018WK890123', 'https://storage.nipanze.ug/kyc/user-008-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-008-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-008-selfie.jpg', TRUE, TRUE, '10000000-0000-0000-0000-000000000015', '2024-03-01 09:00:00', '2024-03-02 10:00:00', '2027-03-01 00:00:00', '2024-03-01 09:00:00'),
('a1000000-0000-0000-0000-000000000009', '10000000-0000-0000-0000-000000000009', 'approved', 'national_id', 'CM77012CN901234', 'https://storage.nipanze.ug/kyc/user-009-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-009-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-009-selfie.jpg', TRUE, TRUE, '10000000-0000-0000-0000-000000000016', '2024-03-03 11:00:00', '2024-03-04 11:00:00', '2027-03-03 00:00:00', '2024-03-03 11:00:00'),
('a1000000-0000-0000-0000-000000000010', '10000000-0000-0000-0000-000000000010', 'approved', 'national_id', 'CM79025GM012345', 'https://storage.nipanze.ug/kyc/user-010-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-010-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-010-selfie.jpg', TRUE, TRUE, '10000000-0000-0000-0000-000000000015', '2024-03-05 09:00:00', '2024-03-06 10:00:00', '2027-03-05 00:00:00', '2024-03-05 09:00:00'),
('a1000000-0000-0000-0000-000000000011', '10000000-0000-0000-0000-000000000011', 'approved', 'national_id', 'CM91114OM789012', 'https://storage.nipanze.ug/kyc/user-011-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-011-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-011-selfie.jpg', TRUE, TRUE, '10000000-0000-0000-0000-000000000016', '2024-03-08 09:30:00', '2024-03-09 14:00:00', '2027-03-08 00:00:00', '2024-03-08 09:30:00'),
('a1000000-0000-0000-0000-000000000012', '10000000-0000-0000-0000-000000000012', 'approved', 'national_id', 'CM88047NB890123', 'https://storage.nipanze.ug/kyc/user-012-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-012-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-012-selfie.jpg', TRUE, TRUE, '10000000-0000-0000-0000-000000000015', '2024-03-10 09:00:00', '2024-03-11 11:00:00', '2027-03-10 00:00:00', '2024-03-10 09:00:00'),
('a1000000-0000-0000-0000-000000000013', '10000000-0000-0000-0000-000000000013', 'approved', 'national_id', 'CM84021MW901234', 'https://storage.nipanze.ug/kyc/user-013-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-013-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-013-selfie.jpg', TRUE, TRUE, '10000000-0000-0000-0000-000000000016', '2024-03-12 12:00:00', '2024-03-13 15:00:00', '2027-03-12 00:00:00', '2024-03-12 12:00:00'),
('a1000000-0000-0000-0000-000000000014', '10000000-0000-0000-0000-000000000014', 'pending', 'national_id', 'CM93255NM789013', 'https://storage.nipanze.ug/kyc/user-014-id-front.jpg', 'https://storage.nipanze.ug/kyc/user-014-id-back.jpg', 'https://storage.nipanze.ug/kyc/user-014-selfie.jpg', FALSE, FALSE, NULL, '2026-01-25 10:30:00', NULL, NULL, '2026-01-25 10:30:00')
ON CONFLICT (user_id) DO NOTHING;

-- ---- UG: subscriptions (upgrade lenders; borrowers stay on free) ----
UPDATE subscriptions SET plan='lender', status='active', amount_minor_units=35000,  started_at='2024-02-18 10:00:00', expires_at='2028-02-18 10:00:00', auto_renew=TRUE  WHERE user_id='10000000-0000-0000-0000-000000000006';
UPDATE subscriptions SET plan='lender', status='active', amount_minor_units=35000,  started_at='2024-02-20 12:00:00', expires_at='2028-02-20 12:00:00', auto_renew=TRUE  WHERE user_id='10000000-0000-0000-0000-000000000007';
UPDATE subscriptions SET plan='pro',    status='active', amount_minor_units=150000, started_at='2024-03-01 11:00:00', expires_at='2028-03-01 11:00:00', auto_renew=TRUE  WHERE user_id='10000000-0000-0000-0000-000000000008';
UPDATE subscriptions SET plan='pro',    status='active', amount_minor_units=150000, started_at='2024-03-03 13:00:00', expires_at='2028-03-03 13:00:00', auto_renew=TRUE  WHERE user_id='10000000-0000-0000-0000-000000000009';
UPDATE subscriptions SET plan='lender', status='active', amount_minor_units=35000,  started_at='2024-03-05 10:00:00', expires_at='2028-03-05 10:00:00', auto_renew=TRUE  WHERE user_id='10000000-0000-0000-0000-000000000010';
UPDATE subscriptions SET plan='pro',    status='active', amount_minor_units=150000, started_at='2024-01-20 15:00:00', expires_at='2028-01-20 15:00:00', auto_renew=TRUE  WHERE user_id='10000000-0000-0000-0000-000000000003';
UPDATE subscriptions SET plan='lender', status='active', amount_minor_units=35000,  started_at='2024-01-25 12:00:00', expires_at='2028-01-25 12:00:00', auto_renew=TRUE  WHERE user_id='10000000-0000-0000-0000-000000000005';
-- remaining UG borrowers (001, 002, 004, 011, 012, 013, 014, 017) stay free — no update needed


-- ============================================
-- ============================================
-- COUNTRY: KENYA (KE) — 17 users, mirrors Uganda's structure
-- 8 active borrowers, 5 lenders (lender/pro), 1 pending-verification borrower,
-- 2 admins, 1 test user.
-- ============================================

INSERT INTO auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    is_super_admin, role, aud,
    confirmation_token, recovery_token,
    email_change_token_new, email_change,
    email_change_token_current, phone_change,
    phone_change_token, reauthentication_token
) VALUES
('10000000-0000-0000-0000-000000000018', '00000000-0000-0000-0000-000000000000', 'wanjiru.kamau@nipanze-ke.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-10 08:00:00', '2026-02-10 08:00:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Wanjiru Kamau","country_code":"KE"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000019', '00000000-0000-0000-0000-000000000000', 'njoroge.kariuki@nipanze-ke.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-11 08:03:00', '2026-02-11 08:03:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Njoroge Kariuki","country_code":"KE"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000000', 'achieng.odhiambo@nipanze-ke.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-12 08:06:00', '2026-02-12 08:06:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Achieng Odhiambo","country_code":"KE"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000000', 'chebet.korir@nipanze-ke.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-13 08:09:00', '2026-02-13 08:09:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Chebet Korir","country_code":"KE"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000022', '00000000-0000-0000-0000-000000000000', 'mutua.kilonzo@nipanze-ke.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-14 08:12:00', '2026-02-14 08:12:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Mutua Kilonzo","country_code":"KE"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000023', '00000000-0000-0000-0000-000000000000', 'wambui.gathoni@nipanze-ke.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-15 08:15:00', '2026-02-15 08:15:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Wambui Gathoni","country_code":"KE"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000024', '00000000-0000-0000-0000-000000000000', 'omondi.owino@nipanze-ke.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-16 08:18:00', '2026-02-16 08:18:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Omondi Owino","country_code":"KE"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000025', '00000000-0000-0000-0000-000000000000', 'nyambura.macharia@nipanze-ke.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-17 08:21:00', '2026-02-17 08:21:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Nyambura Macharia","country_code":"KE"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000026', '00000000-0000-0000-0000-000000000000', 'otieno.mwangi@nipanze-ke.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-18 08:24:00', '2026-02-18 08:24:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Otieno Mwangi","country_code":"KE"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000027', '00000000-0000-0000-0000-000000000000', 'kiptoo.rotich@nipanze-ke.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-19 08:27:00', '2026-02-19 08:27:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Kiptoo Rotich","country_code":"KE"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000028', '00000000-0000-0000-0000-000000000000', 'wanjiku.muriithi@nipanze-ke.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-20 08:30:00', '2026-02-20 08:30:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Wanjiku Muriithi","country_code":"KE"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000029', '00000000-0000-0000-0000-000000000000', 'mburu.njuguna@nipanze-ke.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-21 08:33:00', '2026-02-21 08:33:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Mburu Njuguna","country_code":"KE"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000030', '00000000-0000-0000-0000-000000000000', 'adhiambo.onyango@nipanze-ke.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-22 08:36:00', '2026-02-22 08:36:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Adhiambo Onyango","country_code":"KE"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000000', 'akinyi.otieno@nipanze-ke.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-23 08:39:00', '2026-02-23 08:39:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Akinyi Otieno","country_code":"KE"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000032', '00000000-0000-0000-0000-000000000000', 'admin.kenya.one@nipanze-ke.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-24 08:42:00', '2026-02-24 08:42:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Admin Kenya One","country_code":"KE"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000033', '00000000-0000-0000-0000-000000000000', 'admin.kenya.two@nipanze-ke.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-10 08:45:00', '2026-02-10 08:45:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Admin Kenya Two","country_code":"KE"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000034', '00000000-0000-0000-0000-000000000000', 'test.user.kenya@nipanze-ke.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-11 08:48:00', '2026-02-11 08:48:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Test User Kenya","country_code":"KE"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', '')
ON CONFLICT (id) DO NOTHING;

-- Kenya: profiles (bulk upsert — sets full details regardless of whether
-- the on_auth_user_created trigger already created a bare row)
INSERT INTO public.profiles (
    id, full_name, phone, district, country, employment_type, employer_name,
    monthly_income, income_currency, phone_verified_at, account_status, is_admin, created_at
) VALUES
('10000000-0000-0000-0000-000000000018', 'Wanjiru Kamau', '+254710002466', 'Nairobi', 'KE', 'employed', 'Wanjiru Household Income', 150000, 'KES', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000019', 'Njoroge Kariuki', '+254710002603', 'Nairobi', 'KE', 'government_employee', 'Njoroge Household Income', 195000, 'KES', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000020', 'Achieng Odhiambo', '+254710002740', 'Nairobi', 'KE', 'self_employed', 'Achieng Household Income', 120000, 'KES', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000021', 'Chebet Korir', '+254710002877', 'Nairobi', 'KE', 'small_business_owner', 'Chebet Household Income', 165000, 'KES', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000022', 'Mutua Kilonzo', '+254710003014', 'Nairobi', 'KE', 'employed', 'Mutua Household Income', 135000, 'KES', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000023', 'Wambui Gathoni', '+254710003151', 'Nairobi', 'KE', 'government_employee', 'Wambui Household Income', 225000, 'KES', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000024', 'Omondi Owino', '+254710003288', 'Nairobi', 'KE', 'self_employed', 'Omondi Household Income', 105000, 'KES', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000025', 'Nyambura Macharia', '+254710003425', 'Nairobi', 'KE', 'small_business_owner', 'Nyambura Household Income', 180000, 'KES', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000026', 'Otieno Mwangi', '+254720003926', 'Nairobi', 'KE', 'business_owner', 'Otieno Capital Partners', 700000, 'KES', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000027', 'Kiptoo Rotich', '+254720004077', 'Nairobi', 'KE', 'business_owner', 'Kiptoo Capital Partners', 420000, 'KES', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000028', 'Wanjiku Muriithi', '+254720004228', 'Nairobi', 'KE', 'business_owner', 'Wanjiku Capital Partners', 1540000, 'KES', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000029', 'Mburu Njuguna', '+254720004379', 'Nairobi', 'KE', 'business_owner', 'Mburu Capital Partners', 560000, 'KES', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000030', 'Adhiambo Onyango', '+254720004530', 'Nairobi', 'KE', 'business_owner', 'Adhiambo Capital Partners', 1750000, 'KES', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000031', 'Akinyi Otieno', '+25473000000', 'Nairobi', 'KE', 'employed', 'Local Employer Ltd', 135000, 'KES', NULL, 'pending_verification', FALSE, '2026-02-10 08:10:00'),
('10000000-0000-0000-0000-000000000032', 'Admin Kenya One', '+254700000000', 'Nairobi', 'KE', NULL, NULL, NULL, 'KES', NULL, 'active', TRUE, '2026-01-01 08:00:00'),
('10000000-0000-0000-0000-000000000033', 'Admin Kenya Two', '+254700000001', 'Nairobi', 'KE', NULL, NULL, NULL, 'KES', NULL, 'active', TRUE, '2026-01-01 08:00:00'),
('10000000-0000-0000-0000-000000000034', 'Test User Kenya', '+254799999999', 'Nairobi', 'KE', NULL, NULL, NULL, 'KES', NULL, 'active', FALSE, '2026-02-10 08:15:00')
ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name, phone = EXCLUDED.phone, district = EXCLUDED.district,
    country = EXCLUDED.country, employment_type = EXCLUDED.employment_type,
    employer_name = EXCLUDED.employer_name, monthly_income = EXCLUDED.monthly_income,
    income_currency = EXCLUDED.income_currency, phone_verified_at = EXCLUDED.phone_verified_at,
    account_status = EXCLUDED.account_status, is_admin = EXCLUDED.is_admin;

-- Kenya: subscriptions (borrowers/pending/admins/test stay free; lenders upgraded)
INSERT INTO public.subscriptions (user_id, plan, status, amount_minor_units, started_at, expires_at, auto_renew) VALUES
('10000000-0000-0000-0000-000000000018', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000019', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000020', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000021', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000022', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000023', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000024', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000025', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000026', 'lender', 'active', 1633, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000027', 'lender', 'active', 1633, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000028', 'pro', 'active', 7000, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000029', 'lender', 'active', 1633, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000030', 'pro', 'active', 7000, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000031', 'free', 'active', 0, '2026-02-10 08:10:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000032', 'free', 'active', 0, '2024-01-01 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000033', 'free', 'active', 0, '2024-01-01 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000034', 'free', 'active', 0, '2026-02-10 08:15:00', NULL, TRUE)
ON CONFLICT (user_id) DO UPDATE SET
    plan = EXCLUDED.plan, status = EXCLUDED.status, amount_minor_units = EXCLUDED.amount_minor_units,
    started_at = EXCLUDED.started_at, expires_at = EXCLUDED.expires_at, auto_renew = EXCLUDED.auto_renew;

-- ============================================
-- COUNTRY: TANZANIA (TZ) — 17 users, mirrors Uganda's structure
-- 8 active borrowers, 5 lenders (lender/pro), 1 pending-verification borrower,
-- 2 admins, 1 test user.
-- ============================================

INSERT INTO auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    is_super_admin, role, aud,
    confirmation_token, recovery_token,
    email_change_token_new, email_change,
    email_change_token_current, phone_change,
    phone_change_token, reauthentication_token
) VALUES
('10000000-0000-0000-0000-000000000035', '00000000-0000-0000-0000-000000000000', 'amina.juma@nipanze-tz.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-10 08:00:00', '2026-02-10 08:00:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Amina Juma","country_code":"TZ"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000036', '00000000-0000-0000-0000-000000000000', 'mwakalinga.ndege@nipanze-tz.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-11 08:03:00', '2026-02-11 08:03:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Mwakalinga Ndege","country_code":"TZ"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000037', '00000000-0000-0000-0000-000000000000', 'hassan.mbwana@nipanze-tz.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-12 08:06:00', '2026-02-12 08:06:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Hassan Mbwana","country_code":"TZ"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000038', '00000000-0000-0000-0000-000000000000', 'fatuma.kisoma@nipanze-tz.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-13 08:09:00', '2026-02-13 08:09:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Fatuma Kisoma","country_code":"TZ"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000039', '00000000-0000-0000-0000-000000000000', 'juma.mwakisu@nipanze-tz.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-14 08:12:00', '2026-02-14 08:12:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Juma Mwakisu","country_code":"TZ"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000040', '00000000-0000-0000-0000-000000000000', 'neema.kileo@nipanze-tz.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-15 08:15:00', '2026-02-15 08:15:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Neema Kileo","country_code":"TZ"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000041', '00000000-0000-0000-0000-000000000000', 'salum.ally@nipanze-tz.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-16 08:18:00', '2026-02-16 08:18:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Salum Ally","country_code":"TZ"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000042', '00000000-0000-0000-0000-000000000000', 'zainab.rashidi@nipanze-tz.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-17 08:21:00', '2026-02-17 08:21:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Zainab Rashidi","country_code":"TZ"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000043', '00000000-0000-0000-0000-000000000000', 'baraka.mushi@nipanze-tz.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-18 08:24:00', '2026-02-18 08:24:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Baraka Mushi","country_code":"TZ"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000044', '00000000-0000-0000-0000-000000000000', 'godfrey.massawe@nipanze-tz.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-19 08:27:00', '2026-02-19 08:27:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Godfrey Massawe","country_code":"TZ"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000045', '00000000-0000-0000-0000-000000000000', 'rehema.chuma@nipanze-tz.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-20 08:30:00', '2026-02-20 08:30:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Rehema Chuma","country_code":"TZ"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000046', '00000000-0000-0000-0000-000000000000', 'emmanuel.sanga@nipanze-tz.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-21 08:33:00', '2026-02-21 08:33:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Emmanuel Sanga","country_code":"TZ"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000047', '00000000-0000-0000-0000-000000000000', 'halima.mnyapala@nipanze-tz.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-22 08:36:00', '2026-02-22 08:36:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Halima Mnyapala","country_code":"TZ"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000048', '00000000-0000-0000-0000-000000000000', 'fadhili.mrema@nipanze-tz.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-23 08:39:00', '2026-02-23 08:39:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Fadhili Mrema","country_code":"TZ"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000049', '00000000-0000-0000-0000-000000000000', 'admin.tanzania.one@nipanze-tz.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-24 08:42:00', '2026-02-24 08:42:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Admin Tanzania One","country_code":"TZ"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000050', '00000000-0000-0000-0000-000000000000', 'admin.tanzania.two@nipanze-tz.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-10 08:45:00', '2026-02-10 08:45:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Admin Tanzania Two","country_code":"TZ"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000051', '00000000-0000-0000-0000-000000000000', 'test.user.tanzania@nipanze-tz.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-11 08:48:00', '2026-02-11 08:48:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Test User Tanzania","country_code":"TZ"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', '')
ON CONFLICT (id) DO NOTHING;

-- Tanzania: profiles (bulk upsert — sets full details regardless of whether
-- the on_auth_user_created trigger already created a bare row)
INSERT INTO public.profiles (
    id, full_name, phone, district, country, employment_type, employer_name,
    monthly_income, income_currency, phone_verified_at, account_status, is_admin, created_at
) VALUES
('10000000-0000-0000-0000-000000000035', 'Amina Juma', '+255710004795', 'Dar es Salaam', 'TZ', 'employed', 'Amina Household Income', 1800000, 'TZS', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000036', 'Mwakalinga Ndege', '+255710004932', 'Dar es Salaam', 'TZ', 'government_employee', 'Mwakalinga Household Income', 2340000, 'TZS', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000037', 'Hassan Mbwana', '+255710005069', 'Dar es Salaam', 'TZ', 'self_employed', 'Hassan Household Income', 1440000, 'TZS', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000038', 'Fatuma Kisoma', '+255710005206', 'Dar es Salaam', 'TZ', 'small_business_owner', 'Fatuma Household Income', 1980000, 'TZS', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000039', 'Juma Mwakisu', '+255710005343', 'Dar es Salaam', 'TZ', 'employed', 'Juma Household Income', 1620000, 'TZS', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000040', 'Neema Kileo', '+255710005480', 'Dar es Salaam', 'TZ', 'government_employee', 'Neema Household Income', 2700000, 'TZS', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000041', 'Salum Ally', '+255710005617', 'Dar es Salaam', 'TZ', 'self_employed', 'Salum Household Income', 1260000, 'TZS', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000042', 'Zainab Rashidi', '+255710005754', 'Dar es Salaam', 'TZ', 'small_business_owner', 'Zainab Household Income', 2160000, 'TZS', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000043', 'Baraka Mushi', '+255720006493', 'Dar es Salaam', 'TZ', 'business_owner', 'Baraka Capital Partners', 8500000, 'TZS', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000044', 'Godfrey Massawe', '+255720006644', 'Dar es Salaam', 'TZ', 'business_owner', 'Godfrey Capital Partners', 5100000, 'TZS', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000045', 'Rehema Chuma', '+255720006795', 'Dar es Salaam', 'TZ', 'business_owner', 'Rehema Capital Partners', 18700000, 'TZS', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000046', 'Emmanuel Sanga', '+255720006946', 'Dar es Salaam', 'TZ', 'business_owner', 'Emmanuel Capital Partners', 6800000, 'TZS', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000047', 'Halima Mnyapala', '+255720007097', 'Dar es Salaam', 'TZ', 'business_owner', 'Halima Capital Partners', 21250000, 'TZS', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000048', 'Fadhili Mrema', '+25573000000', 'Dar es Salaam', 'TZ', 'employed', 'Local Employer Ltd', 1620000, 'TZS', NULL, 'pending_verification', FALSE, '2026-02-10 08:10:00'),
('10000000-0000-0000-0000-000000000049', 'Admin Tanzania One', '+255700000000', 'Dar es Salaam', 'TZ', NULL, NULL, NULL, 'TZS', NULL, 'active', TRUE, '2026-01-01 08:00:00'),
('10000000-0000-0000-0000-000000000050', 'Admin Tanzania Two', '+255700000001', 'Dar es Salaam', 'TZ', NULL, NULL, NULL, 'TZS', NULL, 'active', TRUE, '2026-01-01 08:00:00'),
('10000000-0000-0000-0000-000000000051', 'Test User Tanzania', '+255799999999', 'Dar es Salaam', 'TZ', NULL, NULL, NULL, 'TZS', NULL, 'active', FALSE, '2026-02-10 08:15:00')
ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name, phone = EXCLUDED.phone, district = EXCLUDED.district,
    country = EXCLUDED.country, employment_type = EXCLUDED.employment_type,
    employer_name = EXCLUDED.employer_name, monthly_income = EXCLUDED.monthly_income,
    income_currency = EXCLUDED.income_currency, phone_verified_at = EXCLUDED.phone_verified_at,
    account_status = EXCLUDED.account_status, is_admin = EXCLUDED.is_admin;

-- Tanzania: subscriptions (borrowers/pending/admins/test stay free; lenders upgraded)
INSERT INTO public.subscriptions (user_id, plan, status, amount_minor_units, started_at, expires_at, auto_renew) VALUES
('10000000-0000-0000-0000-000000000035', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000036', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000037', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000038', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000039', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000040', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000041', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000042', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000043', 'lender', 'active', 19833, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000044', 'lender', 'active', 19833, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000045', 'pro', 'active', 85000, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000046', 'lender', 'active', 19833, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000047', 'pro', 'active', 85000, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000048', 'free', 'active', 0, '2026-02-10 08:10:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000049', 'free', 'active', 0, '2024-01-01 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000050', 'free', 'active', 0, '2024-01-01 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000051', 'free', 'active', 0, '2026-02-10 08:15:00', NULL, TRUE)
ON CONFLICT (user_id) DO UPDATE SET
    plan = EXCLUDED.plan, status = EXCLUDED.status, amount_minor_units = EXCLUDED.amount_minor_units,
    started_at = EXCLUDED.started_at, expires_at = EXCLUDED.expires_at, auto_renew = EXCLUDED.auto_renew;

-- ============================================
-- COUNTRY: RWANDA (RW) — 17 users, mirrors Uganda's structure
-- 8 active borrowers, 5 lenders (lender/pro), 1 pending-verification borrower,
-- 2 admins, 1 test user.
-- ============================================

INSERT INTO auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    is_super_admin, role, aud,
    confirmation_token, recovery_token,
    email_change_token_new, email_change,
    email_change_token_current, phone_change,
    phone_change_token, reauthentication_token
) VALUES
('10000000-0000-0000-0000-000000000052', '00000000-0000-0000-0000-000000000000', 'uwase.claudine@nipanze-rw.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-10 08:00:00', '2026-02-10 08:00:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Uwase Claudine","country_code":"RW"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000053', '00000000-0000-0000-0000-000000000000', 'mugisha.emmanuel@nipanze-rw.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-11 08:03:00', '2026-02-11 08:03:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Mugisha Emmanuel","country_code":"RW"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000054', '00000000-0000-0000-0000-000000000000', 'ingabire.solange@nipanze-rw.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-12 08:06:00', '2026-02-12 08:06:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Ingabire Solange","country_code":"RW"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000055', '00000000-0000-0000-0000-000000000000', 'habimana.eric@nipanze-rw.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-13 08:09:00', '2026-02-13 08:09:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Habimana Eric","country_code":"RW"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000056', '00000000-0000-0000-0000-000000000000', 'uwimana.alice@nipanze-rw.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-14 08:12:00', '2026-02-14 08:12:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Uwimana Alice","country_code":"RW"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000057', '00000000-0000-0000-0000-000000000000', 'nsengimana.jean@nipanze-rw.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-15 08:15:00', '2026-02-15 08:15:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Nsengimana Jean","country_code":"RW"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000058', '00000000-0000-0000-0000-000000000000', 'mukamana.diane@nipanze-rw.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-16 08:18:00', '2026-02-16 08:18:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Mukamana Diane","country_code":"RW"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000059', '00000000-0000-0000-0000-000000000000', 'bizimana.patrick@nipanze-rw.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-17 08:21:00', '2026-02-17 08:21:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Bizimana Patrick","country_code":"RW"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000060', '00000000-0000-0000-0000-000000000000', 'rugamba.innocent@nipanze-rw.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-18 08:24:00', '2026-02-18 08:24:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Rugamba Innocent","country_code":"RW"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000061', '00000000-0000-0000-0000-000000000000', 'mutesi.christine@nipanze-rw.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-19 08:27:00', '2026-02-19 08:27:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Mutesi Christine","country_code":"RW"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000062', '00000000-0000-0000-0000-000000000000', 'karangwa.vincent@nipanze-rw.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-20 08:30:00', '2026-02-20 08:30:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Karangwa Vincent","country_code":"RW"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000063', '00000000-0000-0000-0000-000000000000', 'nyiraneza.josiane@nipanze-rw.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-21 08:33:00', '2026-02-21 08:33:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Nyiraneza Josiane","country_code":"RW"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000064', '00000000-0000-0000-0000-000000000000', 'twagirayezu.faustin@nipanze-rw.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-22 08:36:00', '2026-02-22 08:36:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Twagirayezu Faustin","country_code":"RW"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000065', '00000000-0000-0000-0000-000000000000', 'ishimwe.sandrine@nipanze-rw.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-23 08:39:00', '2026-02-23 08:39:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Ishimwe Sandrine","country_code":"RW"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000066', '00000000-0000-0000-0000-000000000000', 'admin.rwanda.one@nipanze-rw.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-24 08:42:00', '2026-02-24 08:42:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Admin Rwanda One","country_code":"RW"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000067', '00000000-0000-0000-0000-000000000000', 'admin.rwanda.two@nipanze-rw.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-10 08:45:00', '2026-02-10 08:45:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Admin Rwanda Two","country_code":"RW"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000068', '00000000-0000-0000-0000-000000000000', 'test.user.rwanda@nipanze-rw.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-11 08:48:00', '2026-02-11 08:48:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Test User Rwanda","country_code":"RW"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', '')
ON CONFLICT (id) DO NOTHING;

-- Rwanda: profiles (bulk upsert — sets full details regardless of whether
-- the on_auth_user_created trigger already created a bare row)
INSERT INTO public.profiles (
    id, full_name, phone, district, country, employment_type, employer_name,
    monthly_income, income_currency, phone_verified_at, account_status, is_admin, created_at
) VALUES
('10000000-0000-0000-0000-000000000052', 'Uwase Claudine', '+250710007124', 'Kigali', 'RW', 'employed', 'Uwase Household Income', 750000, 'RWF', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000053', 'Mugisha Emmanuel', '+250710007261', 'Kigali', 'RW', 'government_employee', 'Mugisha Household Income', 975000, 'RWF', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000054', 'Ingabire Solange', '+250710007398', 'Kigali', 'RW', 'self_employed', 'Ingabire Household Income', 600000, 'RWF', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000055', 'Habimana Eric', '+250710007535', 'Kigali', 'RW', 'small_business_owner', 'Habimana Household Income', 825000, 'RWF', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000056', 'Uwimana Alice', '+250710007672', 'Kigali', 'RW', 'employed', 'Uwimana Household Income', 675000, 'RWF', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000057', 'Nsengimana Jean', '+250710007809', 'Kigali', 'RW', 'government_employee', 'Nsengimana Household Income', 1125000, 'RWF', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000058', 'Mukamana Diane', '+250710007946', 'Kigali', 'RW', 'self_employed', 'Mukamana Household Income', 525000, 'RWF', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000059', 'Bizimana Patrick', '+250710008083', 'Kigali', 'RW', 'small_business_owner', 'Bizimana Household Income', 900000, 'RWF', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000060', 'Rugamba Innocent', '+250720009060', 'Kigali', 'RW', 'business_owner', 'Rugamba Capital Partners', 3800000, 'RWF', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000061', 'Mutesi Christine', '+250720009211', 'Kigali', 'RW', 'business_owner', 'Mutesi Capital Partners', 2280000, 'RWF', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000062', 'Karangwa Vincent', '+250720009362', 'Kigali', 'RW', 'business_owner', 'Karangwa Capital Partners', 8360000, 'RWF', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000063', 'Nyiraneza Josiane', '+250720009513', 'Kigali', 'RW', 'business_owner', 'Nyiraneza Capital Partners', 3040000, 'RWF', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000064', 'Twagirayezu Faustin', '+250720009664', 'Kigali', 'RW', 'business_owner', 'Twagirayezu Capital Partners', 9500000, 'RWF', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000065', 'Ishimwe Sandrine', '+25073000000', 'Kigali', 'RW', 'employed', 'Local Employer Ltd', 675000, 'RWF', NULL, 'pending_verification', FALSE, '2026-02-10 08:10:00'),
('10000000-0000-0000-0000-000000000066', 'Admin Rwanda One', '+250700000000', 'Kigali', 'RW', NULL, NULL, NULL, 'RWF', NULL, 'active', TRUE, '2026-01-01 08:00:00'),
('10000000-0000-0000-0000-000000000067', 'Admin Rwanda Two', '+250700000001', 'Kigali', 'RW', NULL, NULL, NULL, 'RWF', NULL, 'active', TRUE, '2026-01-01 08:00:00'),
('10000000-0000-0000-0000-000000000068', 'Test User Rwanda', '+250799999999', 'Kigali', 'RW', NULL, NULL, NULL, 'RWF', NULL, 'active', FALSE, '2026-02-10 08:15:00')
ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name, phone = EXCLUDED.phone, district = EXCLUDED.district,
    country = EXCLUDED.country, employment_type = EXCLUDED.employment_type,
    employer_name = EXCLUDED.employer_name, monthly_income = EXCLUDED.monthly_income,
    income_currency = EXCLUDED.income_currency, phone_verified_at = EXCLUDED.phone_verified_at,
    account_status = EXCLUDED.account_status, is_admin = EXCLUDED.is_admin;

-- Rwanda: subscriptions (borrowers/pending/admins/test stay free; lenders upgraded)
INSERT INTO public.subscriptions (user_id, plan, status, amount_minor_units, started_at, expires_at, auto_renew) VALUES
('10000000-0000-0000-0000-000000000052', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000053', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000054', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000055', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000056', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000057', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000058', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000059', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000060', 'lender', 'active', 8866, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000061', 'lender', 'active', 8866, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000062', 'pro', 'active', 38000, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000063', 'lender', 'active', 8866, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000064', 'pro', 'active', 38000, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000065', 'free', 'active', 0, '2026-02-10 08:10:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000066', 'free', 'active', 0, '2024-01-01 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000067', 'free', 'active', 0, '2024-01-01 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000068', 'free', 'active', 0, '2026-02-10 08:15:00', NULL, TRUE)
ON CONFLICT (user_id) DO UPDATE SET
    plan = EXCLUDED.plan, status = EXCLUDED.status, amount_minor_units = EXCLUDED.amount_minor_units,
    started_at = EXCLUDED.started_at, expires_at = EXCLUDED.expires_at, auto_renew = EXCLUDED.auto_renew;

-- ============================================
-- COUNTRY: BURUNDI (BI) — 17 users, mirrors Uganda's structure
-- 8 active borrowers, 5 lenders (lender/pro), 1 pending-verification borrower,
-- 2 admins, 1 test user.
-- ============================================

INSERT INTO auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    is_super_admin, role, aud,
    confirmation_token, recovery_token,
    email_change_token_new, email_change,
    email_change_token_current, phone_change,
    phone_change_token, reauthentication_token
) VALUES
('10000000-0000-0000-0000-000000000069', '00000000-0000-0000-0000-000000000000', 'ndayishimiye.aline@nipanze-bi.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-10 08:00:00', '2026-02-10 08:00:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Ndayishimiye Aline","country_code":"BI"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000070', '00000000-0000-0000-0000-000000000000', 'nkurunziza.gilbert@nipanze-bi.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-11 08:03:00', '2026-02-11 08:03:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Nkurunziza Gilbert","country_code":"BI"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000071', '00000000-0000-0000-0000-000000000000', 'niyonzima.chantal@nipanze-bi.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-12 08:06:00', '2026-02-12 08:06:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Niyonzima Chantal","country_code":"BI"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000072', '00000000-0000-0000-0000-000000000000', 'bigirimana.willy@nipanze-bi.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-13 08:09:00', '2026-02-13 08:09:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Bigirimana Willy","country_code":"BI"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000073', '00000000-0000-0000-0000-000000000000', 'nizigiyimana.solange@nipanze-bi.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-14 08:12:00', '2026-02-14 08:12:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Nizigiyimana Solange","country_code":"BI"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000074', '00000000-0000-0000-0000-000000000000', 'hakizimana.eric@nipanze-bi.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-15 08:15:00', '2026-02-15 08:15:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Hakizimana Eric","country_code":"BI"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000075', '00000000-0000-0000-0000-000000000000', 'nduwimana.aisha@nipanze-bi.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-16 08:18:00', '2026-02-16 08:18:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Nduwimana Aisha","country_code":"BI"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000076', '00000000-0000-0000-0000-000000000000', 'ntahonkiriye.fabrice@nipanze-bi.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-17 08:21:00', '2026-02-17 08:21:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Ntahonkiriye Fabrice","country_code":"BI"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000077', '00000000-0000-0000-0000-000000000000', 'nshimirimana.pacifique@nipanze-bi.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-18 08:24:00', '2026-02-18 08:24:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Nshimirimana Pacifique","country_code":"BI"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000078', '00000000-0000-0000-0000-000000000000', 'ndikumana.alexis@nipanze-bi.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-19 08:27:00', '2026-02-19 08:27:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Ndikumana Alexis","country_code":"BI"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000079', '00000000-0000-0000-0000-000000000000', 'nizeyimana.beatrice@nipanze-bi.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-20 08:30:00', '2026-02-20 08:30:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Nizeyimana Beatrice","country_code":"BI"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000080', '00000000-0000-0000-0000-000000000000', 'nsabimana.olivier@nipanze-bi.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-21 08:33:00', '2026-02-21 08:33:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Nsabimana Olivier","country_code":"BI"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000081', '00000000-0000-0000-0000-000000000000', 'ntirampeba.clarisse@nipanze-bi.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-22 08:36:00', '2026-02-22 08:36:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Ntirampeba Clarisse","country_code":"BI"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000082', '00000000-0000-0000-0000-000000000000', 'irakoze.divine@nipanze-bi.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-23 08:39:00', '2026-02-23 08:39:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Irakoze Divine","country_code":"BI"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000083', '00000000-0000-0000-0000-000000000000', 'admin.burundi.one@nipanze-bi.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-24 08:42:00', '2026-02-24 08:42:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Admin Burundi One","country_code":"BI"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000084', '00000000-0000-0000-0000-000000000000', 'admin.burundi.two@nipanze-bi.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-10 08:45:00', '2026-02-10 08:45:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Admin Burundi Two","country_code":"BI"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000085', '00000000-0000-0000-0000-000000000000', 'test.user.burundi@nipanze-bi.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-11 08:48:00', '2026-02-11 08:48:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Test User Burundi","country_code":"BI"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', '')
ON CONFLICT (id) DO NOTHING;

-- Burundi: profiles (bulk upsert — sets full details regardless of whether
-- the on_auth_user_created trigger already created a bare row)
INSERT INTO public.profiles (
    id, full_name, phone, district, country, employment_type, employer_name,
    monthly_income, income_currency, phone_verified_at, account_status, is_admin, created_at
) VALUES
('10000000-0000-0000-0000-000000000069', 'Ndayishimiye Aline', '+257710009453', 'Bujumbura', 'BI', 'employed', 'Ndayishimiye Household Income', 850000, 'BIF', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000070', 'Nkurunziza Gilbert', '+257710009590', 'Bujumbura', 'BI', 'government_employee', 'Nkurunziza Household Income', 1105000, 'BIF', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000071', 'Niyonzima Chantal', '+257710009727', 'Bujumbura', 'BI', 'self_employed', 'Niyonzima Household Income', 680000, 'BIF', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000072', 'Bigirimana Willy', '+257710009864', 'Bujumbura', 'BI', 'small_business_owner', 'Bigirimana Household Income', 935000, 'BIF', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000073', 'Nizigiyimana Solange', '+257710010001', 'Bujumbura', 'BI', 'employed', 'Nizigiyimana Household Income', 765000, 'BIF', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000074', 'Hakizimana Eric', '+257710010138', 'Bujumbura', 'BI', 'government_employee', 'Hakizimana Household Income', 1275000, 'BIF', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000075', 'Nduwimana Aisha', '+257710010275', 'Bujumbura', 'BI', 'self_employed', 'Nduwimana Household Income', 595000, 'BIF', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000076', 'Ntahonkiriye Fabrice', '+257710010412', 'Bujumbura', 'BI', 'small_business_owner', 'Ntahonkiriye Household Income', 1020000, 'BIF', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000077', 'Nshimirimana Pacifique', '+257720011627', 'Bujumbura', 'BI', 'business_owner', 'Nshimirimana Capital Partners', 4700000, 'BIF', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000078', 'Ndikumana Alexis', '+257720011778', 'Bujumbura', 'BI', 'business_owner', 'Ndikumana Capital Partners', 2820000, 'BIF', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000079', 'Nizeyimana Beatrice', '+257720011929', 'Bujumbura', 'BI', 'business_owner', 'Nizeyimana Capital Partners', 10340000, 'BIF', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000080', 'Nsabimana Olivier', '+257720012080', 'Bujumbura', 'BI', 'business_owner', 'Nsabimana Capital Partners', 3760000, 'BIF', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000081', 'Ntirampeba Clarisse', '+257720012231', 'Bujumbura', 'BI', 'business_owner', 'Ntirampeba Capital Partners', 11750000, 'BIF', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000082', 'Irakoze Divine', '+25773000000', 'Bujumbura', 'BI', 'employed', 'Local Employer Ltd', 765000, 'BIF', NULL, 'pending_verification', FALSE, '2026-02-10 08:10:00'),
('10000000-0000-0000-0000-000000000083', 'Admin Burundi One', '+257700000000', 'Bujumbura', 'BI', NULL, NULL, NULL, 'BIF', NULL, 'active', TRUE, '2026-01-01 08:00:00'),
('10000000-0000-0000-0000-000000000084', 'Admin Burundi Two', '+257700000001', 'Bujumbura', 'BI', NULL, NULL, NULL, 'BIF', NULL, 'active', TRUE, '2026-01-01 08:00:00'),
('10000000-0000-0000-0000-000000000085', 'Test User Burundi', '+257799999999', 'Bujumbura', 'BI', NULL, NULL, NULL, 'BIF', NULL, 'active', FALSE, '2026-02-10 08:15:00')
ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name, phone = EXCLUDED.phone, district = EXCLUDED.district,
    country = EXCLUDED.country, employment_type = EXCLUDED.employment_type,
    employer_name = EXCLUDED.employer_name, monthly_income = EXCLUDED.monthly_income,
    income_currency = EXCLUDED.income_currency, phone_verified_at = EXCLUDED.phone_verified_at,
    account_status = EXCLUDED.account_status, is_admin = EXCLUDED.is_admin;

-- Burundi: subscriptions (borrowers/pending/admins/test stay free; lenders upgraded)
INSERT INTO public.subscriptions (user_id, plan, status, amount_minor_units, started_at, expires_at, auto_renew) VALUES
('10000000-0000-0000-0000-000000000069', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000070', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000071', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000072', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000073', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000074', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000075', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000076', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000077', 'lender', 'active', 10966, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000078', 'lender', 'active', 10966, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000079', 'pro', 'active', 47000, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000080', 'lender', 'active', 10966, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000081', 'pro', 'active', 47000, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000082', 'free', 'active', 0, '2026-02-10 08:10:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000083', 'free', 'active', 0, '2024-01-01 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000084', 'free', 'active', 0, '2024-01-01 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000085', 'free', 'active', 0, '2026-02-10 08:15:00', NULL, TRUE)
ON CONFLICT (user_id) DO UPDATE SET
    plan = EXCLUDED.plan, status = EXCLUDED.status, amount_minor_units = EXCLUDED.amount_minor_units,
    started_at = EXCLUDED.started_at, expires_at = EXCLUDED.expires_at, auto_renew = EXCLUDED.auto_renew;

-- ============================================
-- COUNTRY: SOUTH SUDAN (SS) — 17 users, mirrors Uganda's structure
-- 8 active borrowers, 5 lenders (lender/pro), 1 pending-verification borrower,
-- 2 admins, 1 test user.
-- ============================================

INSERT INTO auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    is_super_admin, role, aud,
    confirmation_token, recovery_token,
    email_change_token_new, email_change,
    email_change_token_current, phone_change,
    phone_change_token, reauthentication_token
) VALUES
('10000000-0000-0000-0000-000000000086', '00000000-0000-0000-0000-000000000000', 'akol.deng@nipanze-ss.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-10 08:00:00', '2026-02-10 08:00:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Akol Deng","country_code":"SS"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000087', '00000000-0000-0000-0000-000000000000', 'achol.mayen@nipanze-ss.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-11 08:03:00', '2026-02-11 08:03:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Achol Mayen","country_code":"SS"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000088', '00000000-0000-0000-0000-000000000000', 'garang.bior@nipanze-ss.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-12 08:06:00', '2026-02-12 08:06:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Garang Bior","country_code":"SS"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000089', '00000000-0000-0000-0000-000000000000', 'nyibol.kuot@nipanze-ss.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-13 08:09:00', '2026-02-13 08:09:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Nyibol Kuot","country_code":"SS"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000090', '00000000-0000-0000-0000-000000000000', 'deng.majok@nipanze-ss.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-14 08:12:00', '2026-02-14 08:12:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Deng Majok","country_code":"SS"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000091', '00000000-0000-0000-0000-000000000000', 'akech.aluel@nipanze-ss.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-15 08:15:00', '2026-02-15 08:15:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Akech Aluel","country_code":"SS"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000092', '00000000-0000-0000-0000-000000000000', 'malual.chol@nipanze-ss.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-16 08:18:00', '2026-02-16 08:18:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Malual Chol","country_code":"SS"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000093', '00000000-0000-0000-0000-000000000000', 'adut.manyang@nipanze-ss.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-17 08:21:00', '2026-02-17 08:21:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Adut Manyang","country_code":"SS"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000094', '00000000-0000-0000-0000-000000000000', 'nyandeng.malual@nipanze-ss.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-18 08:24:00', '2026-02-18 08:24:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Nyandeng Malual","country_code":"SS"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000095', '00000000-0000-0000-0000-000000000000', 'wek.ajak@nipanze-ss.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-19 08:27:00', '2026-02-19 08:27:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Wek Ajak","country_code":"SS"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000096', '00000000-0000-0000-0000-000000000000', 'achuoth.mabior@nipanze-ss.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-20 08:30:00', '2026-02-20 08:30:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Achuoth Mabior","country_code":"SS"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000097', '00000000-0000-0000-0000-000000000000', 'nyanchiew.gatkuoth@nipanze-ss.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-21 08:33:00', '2026-02-21 08:33:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Nyanchiew Gatkuoth","country_code":"SS"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000098', '00000000-0000-0000-0000-000000000000', 'riek.machot@nipanze-ss.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-22 08:36:00', '2026-02-22 08:36:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Riek Machot","country_code":"SS"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000099', '00000000-0000-0000-0000-000000000000', 'ayen.lual@nipanze-ss.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-23 08:39:00', '2026-02-23 08:39:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Ayen Lual","country_code":"SS"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000100', '00000000-0000-0000-0000-000000000000', 'admin.south.sudan.one@nipanze-ss.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-24 08:42:00', '2026-02-24 08:42:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Admin South Sudan One","country_code":"SS"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000000', 'admin.south.sudan.two@nipanze-ss.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-10 08:45:00', '2026-02-10 08:45:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Admin South Sudan Two","country_code":"SS"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000000', 'test.user.south.sudan@nipanze-ss.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-11 08:48:00', '2026-02-11 08:48:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Test User South Sudan","country_code":"SS"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', '')
ON CONFLICT (id) DO NOTHING;

-- South Sudan: profiles (bulk upsert — sets full details regardless of whether
-- the on_auth_user_created trigger already created a bare row)
INSERT INTO public.profiles (
    id, full_name, phone, district, country, employment_type, employer_name,
    monthly_income, income_currency, phone_verified_at, account_status, is_admin, created_at
) VALUES
('10000000-0000-0000-0000-000000000086', 'Akol Deng', '+211710011782', 'Juba', 'SS', 'employed', 'Akol Household Income', 300000, 'SSP', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000087', 'Achol Mayen', '+211710011919', 'Juba', 'SS', 'government_employee', 'Achol Household Income', 390000, 'SSP', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000088', 'Garang Bior', '+211710012056', 'Juba', 'SS', 'self_employed', 'Garang Household Income', 240000, 'SSP', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000089', 'Nyibol Kuot', '+211710012193', 'Juba', 'SS', 'small_business_owner', 'Nyibol Household Income', 330000, 'SSP', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000090', 'Deng Majok', '+211710012330', 'Juba', 'SS', 'employed', 'Deng Household Income', 270000, 'SSP', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000091', 'Akech Aluel', '+211710012467', 'Juba', 'SS', 'government_employee', 'Akech Household Income', 450000, 'SSP', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000092', 'Malual Chol', '+211710012604', 'Juba', 'SS', 'self_employed', 'Malual Household Income', 210000, 'SSP', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000093', 'Adut Manyang', '+211710012741', 'Juba', 'SS', 'small_business_owner', 'Adut Household Income', 360000, 'SSP', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000094', 'Nyandeng Malual', '+211720014194', 'Juba', 'SS', 'business_owner', 'Nyandeng Capital Partners', 1600000, 'SSP', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000095', 'Wek Ajak', '+211720014345', 'Juba', 'SS', 'business_owner', 'Wek Capital Partners', 960000, 'SSP', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000096', 'Achuoth Mabior', '+211720014496', 'Juba', 'SS', 'business_owner', 'Achuoth Capital Partners', 3520000, 'SSP', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000097', 'Nyanchiew Gatkuoth', '+211720014647', 'Juba', 'SS', 'business_owner', 'Nyanchiew Capital Partners', 1280000, 'SSP', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000098', 'Riek Machot', '+211720014798', 'Juba', 'SS', 'business_owner', 'Riek Capital Partners', 4000000, 'SSP', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000099', 'Ayen Lual', '+21173000000', 'Juba', 'SS', 'employed', 'Local Employer Ltd', 270000, 'SSP', NULL, 'pending_verification', FALSE, '2026-02-10 08:10:00'),
('10000000-0000-0000-0000-000000000100', 'Admin South Sudan One', '+211700000000', 'Juba', 'SS', NULL, NULL, NULL, 'SSP', NULL, 'active', TRUE, '2026-01-01 08:00:00'),
('10000000-0000-0000-0000-000000000101', 'Admin South Sudan Two', '+211700000001', 'Juba', 'SS', NULL, NULL, NULL, 'SSP', NULL, 'active', TRUE, '2026-01-01 08:00:00'),
('10000000-0000-0000-0000-000000000102', 'Test User South Sudan', '+211799999999', 'Juba', 'SS', NULL, NULL, NULL, 'SSP', NULL, 'active', FALSE, '2026-02-10 08:15:00')
ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name, phone = EXCLUDED.phone, district = EXCLUDED.district,
    country = EXCLUDED.country, employment_type = EXCLUDED.employment_type,
    employer_name = EXCLUDED.employer_name, monthly_income = EXCLUDED.monthly_income,
    income_currency = EXCLUDED.income_currency, phone_verified_at = EXCLUDED.phone_verified_at,
    account_status = EXCLUDED.account_status, is_admin = EXCLUDED.is_admin;

-- South Sudan: subscriptions (borrowers/pending/admins/test stay free; lenders upgraded)
INSERT INTO public.subscriptions (user_id, plan, status, amount_minor_units, started_at, expires_at, auto_renew) VALUES
('10000000-0000-0000-0000-000000000086', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000087', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000088', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000089', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000090', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000091', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000092', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000093', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000094', 'lender', 'active', 3733, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000095', 'lender', 'active', 3733, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000096', 'pro', 'active', 16000, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000097', 'lender', 'active', 3733, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000098', 'pro', 'active', 16000, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000099', 'free', 'active', 0, '2026-02-10 08:10:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000100', 'free', 'active', 0, '2024-01-01 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000101', 'free', 'active', 0, '2024-01-01 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000102', 'free', 'active', 0, '2026-02-10 08:15:00', NULL, TRUE)
ON CONFLICT (user_id) DO UPDATE SET
    plan = EXCLUDED.plan, status = EXCLUDED.status, amount_minor_units = EXCLUDED.amount_minor_units,
    started_at = EXCLUDED.started_at, expires_at = EXCLUDED.expires_at, auto_renew = EXCLUDED.auto_renew;

-- ============================================
-- COUNTRY: DR CONGO (CD) — 17 users, mirrors Uganda's structure
-- 8 active borrowers, 5 lenders (lender/pro), 1 pending-verification borrower,
-- 2 admins, 1 test user.
-- ============================================

INSERT INTO auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    is_super_admin, role, aud,
    confirmation_token, recovery_token,
    email_change_token_new, email_change,
    email_change_token_current, phone_change,
    phone_change_token, reauthentication_token
) VALUES
('10000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000000', 'mbuyi.ilunga@nipanze-cd.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-10 08:00:00', '2026-02-10 08:00:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Mbuyi Ilunga","country_code":"CD"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000104', '00000000-0000-0000-0000-000000000000', 'kabongo.tshimanga@nipanze-cd.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-11 08:03:00', '2026-02-11 08:03:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Kabongo Tshimanga","country_code":"CD"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000105', '00000000-0000-0000-0000-000000000000', 'mwamba.kalala@nipanze-cd.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-12 08:06:00', '2026-02-12 08:06:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Mwamba Kalala","country_code":"CD"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000106', '00000000-0000-0000-0000-000000000000', 'ntumba.kasongo@nipanze-cd.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-13 08:09:00', '2026-02-13 08:09:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Ntumba Kasongo","country_code":"CD"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000107', '00000000-0000-0000-0000-000000000000', 'kalenga.mutombo@nipanze-cd.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-14 08:12:00', '2026-02-14 08:12:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Kalenga Mutombo","country_code":"CD"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000108', '00000000-0000-0000-0000-000000000000', 'lukusa.ngoy@nipanze-cd.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-15 08:15:00', '2026-02-15 08:15:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Lukusa Ngoy","country_code":"CD"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000109', '00000000-0000-0000-0000-000000000000', 'mujinga.banza@nipanze-cd.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-16 08:18:00', '2026-02-16 08:18:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Mujinga Banza","country_code":"CD"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000110', '00000000-0000-0000-0000-000000000000', 'kasongo.ilunga@nipanze-cd.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-17 08:21:00', '2026-02-17 08:21:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Kasongo Ilunga","country_code":"CD"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000111', '00000000-0000-0000-0000-000000000000', 'kalonji.mukendi@nipanze-cd.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-18 08:24:00', '2026-02-18 08:24:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Kalonji Mukendi","country_code":"CD"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000112', '00000000-0000-0000-0000-000000000000', 'tshibangu.mbayo@nipanze-cd.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-19 08:27:00', '2026-02-19 08:27:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Tshibangu Mbayo","country_code":"CD"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000113', '00000000-0000-0000-0000-000000000000', 'mutombo.kanyinda@nipanze-cd.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-20 08:30:00', '2026-02-20 08:30:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Mutombo Kanyinda","country_code":"CD"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000114', '00000000-0000-0000-0000-000000000000', 'nkulu.ngalula@nipanze-cd.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-21 08:33:00', '2026-02-21 08:33:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Nkulu Ngalula","country_code":"CD"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000115', '00000000-0000-0000-0000-000000000000', 'ilunga.mwepu@nipanze-cd.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-22 08:36:00', '2026-02-22 08:36:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Ilunga Mwepu","country_code":"CD"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000116', '00000000-0000-0000-0000-000000000000', 'kanku.mbuyi@nipanze-cd.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-23 08:39:00', '2026-02-23 08:39:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Kanku Mbuyi","country_code":"CD"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000117', '00000000-0000-0000-0000-000000000000', 'admin.dr.congo.one@nipanze-cd.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-24 08:42:00', '2026-02-24 08:42:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Admin DR Congo One","country_code":"CD"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000118', '00000000-0000-0000-0000-000000000000', 'admin.dr.congo.two@nipanze-cd.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-10 08:45:00', '2026-02-10 08:45:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Admin DR Congo Two","country_code":"CD"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000119', '00000000-0000-0000-0000-000000000000', 'test.user.dr.congo@nipanze-cd.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-11 08:48:00', '2026-02-11 08:48:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Test User DR Congo","country_code":"CD"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', '')
ON CONFLICT (id) DO NOTHING;

-- DR Congo: profiles (bulk upsert — sets full details regardless of whether
-- the on_auth_user_created trigger already created a bare row)
INSERT INTO public.profiles (
    id, full_name, phone, district, country, employment_type, employer_name,
    monthly_income, income_currency, phone_verified_at, account_status, is_admin, created_at
) VALUES
('10000000-0000-0000-0000-000000000103', 'Mbuyi Ilunga', '+243710014111', 'Kinshasa', 'CD', 'employed', 'Mbuyi Household Income', 1100000, 'CDF', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000104', 'Kabongo Tshimanga', '+243710014248', 'Kinshasa', 'CD', 'government_employee', 'Kabongo Household Income', 1430000, 'CDF', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000105', 'Mwamba Kalala', '+243710014385', 'Kinshasa', 'CD', 'self_employed', 'Mwamba Household Income', 880000, 'CDF', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000106', 'Ntumba Kasongo', '+243710014522', 'Kinshasa', 'CD', 'small_business_owner', 'Ntumba Household Income', 1210000, 'CDF', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000107', 'Kalenga Mutombo', '+243710014659', 'Kinshasa', 'CD', 'employed', 'Kalenga Household Income', 990000, 'CDF', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000108', 'Lukusa Ngoy', '+243710014796', 'Kinshasa', 'CD', 'government_employee', 'Lukusa Household Income', 1650000, 'CDF', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000109', 'Mujinga Banza', '+243710014933', 'Kinshasa', 'CD', 'self_employed', 'Mujinga Household Income', 770000, 'CDF', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000110', 'Kasongo Ilunga', '+243710015070', 'Kinshasa', 'CD', 'small_business_owner', 'Kasongo Household Income', 1320000, 'CDF', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000111', 'Kalonji Mukendi', '+243720016761', 'Kinshasa', 'CD', 'business_owner', 'Kalonji Capital Partners', 6000000, 'CDF', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000112', 'Tshibangu Mbayo', '+243720016912', 'Kinshasa', 'CD', 'business_owner', 'Tshibangu Capital Partners', 3600000, 'CDF', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000113', 'Mutombo Kanyinda', '+243720017063', 'Kinshasa', 'CD', 'business_owner', 'Mutombo Capital Partners', 13200000, 'CDF', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000114', 'Nkulu Ngalula', '+243720017214', 'Kinshasa', 'CD', 'business_owner', 'Nkulu Capital Partners', 4800000, 'CDF', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000115', 'Ilunga Mwepu', '+243720017365', 'Kinshasa', 'CD', 'business_owner', 'Ilunga Capital Partners', 15000000, 'CDF', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000116', 'Kanku Mbuyi', '+24373000000', 'Kinshasa', 'CD', 'employed', 'Local Employer Ltd', 990000, 'CDF', NULL, 'pending_verification', FALSE, '2026-02-10 08:10:00'),
('10000000-0000-0000-0000-000000000117', 'Admin DR Congo One', '+243700000000', 'Kinshasa', 'CD', NULL, NULL, NULL, 'CDF', NULL, 'active', TRUE, '2026-01-01 08:00:00'),
('10000000-0000-0000-0000-000000000118', 'Admin DR Congo Two', '+243700000001', 'Kinshasa', 'CD', NULL, NULL, NULL, 'CDF', NULL, 'active', TRUE, '2026-01-01 08:00:00'),
('10000000-0000-0000-0000-000000000119', 'Test User DR Congo', '+243799999999', 'Kinshasa', 'CD', NULL, NULL, NULL, 'CDF', NULL, 'active', FALSE, '2026-02-10 08:15:00')
ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name, phone = EXCLUDED.phone, district = EXCLUDED.district,
    country = EXCLUDED.country, employment_type = EXCLUDED.employment_type,
    employer_name = EXCLUDED.employer_name, monthly_income = EXCLUDED.monthly_income,
    income_currency = EXCLUDED.income_currency, phone_verified_at = EXCLUDED.phone_verified_at,
    account_status = EXCLUDED.account_status, is_admin = EXCLUDED.is_admin;

-- DR Congo: subscriptions (borrowers/pending/admins/test stay free; lenders upgraded)
INSERT INTO public.subscriptions (user_id, plan, status, amount_minor_units, started_at, expires_at, auto_renew) VALUES
('10000000-0000-0000-0000-000000000103', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000104', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000105', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000106', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000107', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000108', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000109', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000110', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000111', 'lender', 'active', 14000, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000112', 'lender', 'active', 14000, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000113', 'pro', 'active', 60000, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000114', 'lender', 'active', 14000, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000115', 'pro', 'active', 60000, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000116', 'free', 'active', 0, '2026-02-10 08:10:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000117', 'free', 'active', 0, '2024-01-01 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000118', 'free', 'active', 0, '2024-01-01 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000119', 'free', 'active', 0, '2026-02-10 08:15:00', NULL, TRUE)
ON CONFLICT (user_id) DO UPDATE SET
    plan = EXCLUDED.plan, status = EXCLUDED.status, amount_minor_units = EXCLUDED.amount_minor_units,
    started_at = EXCLUDED.started_at, expires_at = EXCLUDED.expires_at, auto_renew = EXCLUDED.auto_renew;

-- ============================================
-- COUNTRY: SOMALIA (SO) — 17 users, mirrors Uganda's structure
-- 8 active borrowers, 5 lenders (lender/pro), 1 pending-verification borrower,
-- 2 admins, 1 test user.
-- ============================================

INSERT INTO auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    is_super_admin, role, aud,
    confirmation_token, recovery_token,
    email_change_token_new, email_change,
    email_change_token_current, phone_change,
    phone_change_token, reauthentication_token
) VALUES
('10000000-0000-0000-0000-000000000120', '00000000-0000-0000-0000-000000000000', 'hodan.ali@nipanze-so.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-10 08:00:00', '2026-02-10 08:00:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Hodan Ali","country_code":"SO"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000121', '00000000-0000-0000-0000-000000000000', 'abdirahman.yusuf@nipanze-so.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-11 08:03:00', '2026-02-11 08:03:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Abdirahman Yusuf","country_code":"SO"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000122', '00000000-0000-0000-0000-000000000000', 'fadumo.hassan@nipanze-so.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-12 08:06:00', '2026-02-12 08:06:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Fadumo Hassan","country_code":"SO"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000123', '00000000-0000-0000-0000-000000000000', 'cabdullahi.nur@nipanze-so.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-13 08:09:00', '2026-02-13 08:09:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Cabdullahi Nur","country_code":"SO"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000124', '00000000-0000-0000-0000-000000000000', 'sahra.mohamed@nipanze-so.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-14 08:12:00', '2026-02-14 08:12:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Sahra Mohamed","country_code":"SO"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000125', '00000000-0000-0000-0000-000000000000', 'mohamed.farah@nipanze-so.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-15 08:15:00', '2026-02-15 08:15:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Mohamed Farah","country_code":"SO"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000126', '00000000-0000-0000-0000-000000000000', 'halima.isse@nipanze-so.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-16 08:18:00', '2026-02-16 08:18:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Halima Isse","country_code":"SO"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000127', '00000000-0000-0000-0000-000000000000', 'bashir.aden@nipanze-so.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-17 08:21:00', '2026-02-17 08:21:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Bashir Aden","country_code":"SO"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000128', '00000000-0000-0000-0000-000000000000', 'abdullahi.warsame@nipanze-so.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-18 08:24:00', '2026-02-18 08:24:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Abdullahi Warsame","country_code":"SO"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000129', '00000000-0000-0000-0000-000000000000', 'cabdiraxman.warfaa@nipanze-so.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-19 08:27:00', '2026-02-19 08:27:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Cabdiraxman Warfaa","country_code":"SO"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000130', '00000000-0000-0000-0000-000000000000', 'ifrah.guuleed@nipanze-so.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-20 08:30:00', '2026-02-20 08:30:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Ifrah Guuleed","country_code":"SO"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000131', '00000000-0000-0000-0000-000000000000', 'xasan.nuur@nipanze-so.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-21 08:33:00', '2026-02-21 08:33:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Xasan Nuur","country_code":"SO"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000132', '00000000-0000-0000-0000-000000000000', 'zamzam.aweys@nipanze-so.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-22 08:36:00', '2026-02-22 08:36:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Zamzam Aweys","country_code":"SO"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000133', '00000000-0000-0000-0000-000000000000', 'ubax.farah@nipanze-so.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-23 08:39:00', '2026-02-23 08:39:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Ubax Farah","country_code":"SO"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000134', '00000000-0000-0000-0000-000000000000', 'admin.somalia.one@nipanze-so.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-24 08:42:00', '2026-02-24 08:42:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Admin Somalia One","country_code":"SO"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000135', '00000000-0000-0000-0000-000000000000', 'admin.somalia.two@nipanze-so.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-10 08:45:00', '2026-02-10 08:45:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Admin Somalia Two","country_code":"SO"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000136', '00000000-0000-0000-0000-000000000000', 'test.user.somalia@nipanze-so.test', crypt('Test1234!', gen_salt('bf')), NOW(), '2026-02-11 08:48:00', '2026-02-11 08:48:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Test User Somalia","country_code":"SO"}', FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', '')
ON CONFLICT (id) DO NOTHING;

-- Somalia: profiles (bulk upsert — sets full details regardless of whether
-- the on_auth_user_created trigger already created a bare row)
INSERT INTO public.profiles (
    id, full_name, phone, district, country, employment_type, employer_name,
    monthly_income, income_currency, phone_verified_at, account_status, is_admin, created_at
) VALUES
('10000000-0000-0000-0000-000000000120', 'Hodan Ali', '+252710016440', 'Mogadishu', 'SO', 'employed', 'Hodan Household Income', 3800000, 'SOS', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000121', 'Abdirahman Yusuf', '+252710016577', 'Mogadishu', 'SO', 'government_employee', 'Abdirahman Household Income', 4940000, 'SOS', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000122', 'Fadumo Hassan', '+252710016714', 'Mogadishu', 'SO', 'self_employed', 'Fadumo Household Income', 3040000, 'SOS', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000123', 'Cabdullahi Nur', '+252710016851', 'Mogadishu', 'SO', 'small_business_owner', 'Cabdullahi Household Income', 4180000, 'SOS', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000124', 'Sahra Mohamed', '+252710016988', 'Mogadishu', 'SO', 'employed', 'Sahra Household Income', 3420000, 'SOS', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000125', 'Mohamed Farah', '+252710017125', 'Mogadishu', 'SO', 'government_employee', 'Mohamed Household Income', 5700000, 'SOS', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000126', 'Halima Isse', '+252710017262', 'Mogadishu', 'SO', 'self_employed', 'Halima Household Income', 2660000, 'SOS', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000127', 'Bashir Aden', '+252710017399', 'Mogadishu', 'SO', 'small_business_owner', 'Bashir Household Income', 4560000, 'SOS', NULL, 'active', FALSE, '2026-02-10 08:00:00'),
('10000000-0000-0000-0000-000000000128', 'Abdullahi Warsame', '+252720019328', 'Mogadishu', 'SO', 'business_owner', 'Abdullahi Capital Partners', 16000000, 'SOS', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000129', 'Cabdiraxman Warfaa', '+252720019479', 'Mogadishu', 'SO', 'business_owner', 'Cabdiraxman Capital Partners', 9600000, 'SOS', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000130', 'Ifrah Guuleed', '+252720019630', 'Mogadishu', 'SO', 'business_owner', 'Ifrah Capital Partners', 35200000, 'SOS', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000131', 'Xasan Nuur', '+252720019781', 'Mogadishu', 'SO', 'business_owner', 'Xasan Capital Partners', 12800000, 'SOS', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000132', 'Zamzam Aweys', '+252720019932', 'Mogadishu', 'SO', 'business_owner', 'Zamzam Capital Partners', 40000000, 'SOS', '2026-02-10 09:00:00', 'active', FALSE, '2026-02-10 08:05:00'),
('10000000-0000-0000-0000-000000000133', 'Ubax Farah', '+25273000000', 'Mogadishu', 'SO', 'employed', 'Local Employer Ltd', 3420000, 'SOS', NULL, 'pending_verification', FALSE, '2026-02-10 08:10:00'),
('10000000-0000-0000-0000-000000000134', 'Admin Somalia One', '+252700000000', 'Mogadishu', 'SO', NULL, NULL, NULL, 'SOS', NULL, 'active', TRUE, '2026-01-01 08:00:00'),
('10000000-0000-0000-0000-000000000135', 'Admin Somalia Two', '+252700000001', 'Mogadishu', 'SO', NULL, NULL, NULL, 'SOS', NULL, 'active', TRUE, '2026-01-01 08:00:00'),
('10000000-0000-0000-0000-000000000136', 'Test User Somalia', '+252799999999', 'Mogadishu', 'SO', NULL, NULL, NULL, 'SOS', NULL, 'active', FALSE, '2026-02-10 08:15:00')
ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name, phone = EXCLUDED.phone, district = EXCLUDED.district,
    country = EXCLUDED.country, employment_type = EXCLUDED.employment_type,
    employer_name = EXCLUDED.employer_name, monthly_income = EXCLUDED.monthly_income,
    income_currency = EXCLUDED.income_currency, phone_verified_at = EXCLUDED.phone_verified_at,
    account_status = EXCLUDED.account_status, is_admin = EXCLUDED.is_admin;

-- Somalia: subscriptions (borrowers/pending/admins/test stay free; lenders upgraded)
INSERT INTO public.subscriptions (user_id, plan, status, amount_minor_units, started_at, expires_at, auto_renew) VALUES
('10000000-0000-0000-0000-000000000120', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000121', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000122', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000123', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000124', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000125', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000126', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000127', 'free', 'active', 0, '2026-02-10 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000128', 'lender', 'active', 37333, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000129', 'lender', 'active', 37333, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000130', 'pro', 'active', 160000, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000131', 'lender', 'active', 37333, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000132', 'pro', 'active', 160000, '2026-02-10 09:00:00', '2028-02-10 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000133', 'free', 'active', 0, '2026-02-10 08:10:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000134', 'free', 'active', 0, '2024-01-01 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000135', 'free', 'active', 0, '2024-01-01 08:00:00', NULL, TRUE),
('10000000-0000-0000-0000-000000000136', 'free', 'active', 0, '2026-02-10 08:15:00', NULL, TRUE)
ON CONFLICT (user_id) DO UPDATE SET
    plan = EXCLUDED.plan, status = EXCLUDED.status, amount_minor_units = EXCLUDED.amount_minor_units,
    started_at = EXCLUDED.started_at, expires_at = EXCLUDED.expires_at, auto_renew = EXCLUDED.auto_renew;
-- ============================================================
-- PART B -- MARKETPLACE DATA (loan_requests, loan_offers,
-- agreements, contact_reveals). Grouped by the request's country,
-- but offers may legitimately come from a lender in a different
-- country -- cross-border bidding is allowed by default (v5.0).
-- ============================================================

SET session_replication_role = 'replica';
-- ---- loan_requests: UGANDA ----
INSERT INTO loan_requests (
    id, borrower_id, country, title, purpose, requested_amount, duration_months,
    income_source, preferred_repayment_plan, repayment_amount_per_period, repayment_timeline,
    district, status, listed_at, expires_at, contracted_at, number_of_offers, views_count, created_at
) VALUES
('c1000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'UG',
 'Home Renovation Loan', 'Kitchen and bathroom upgrade at family home in Kampala',
 5000000, 12, 'Salary — UGX 4,500,000', 'monthly', 450000, '12 months starting March 2024', 'Central',
 'contracted', '2024-02-01 09:00:00', NOW() + INTERVAL '10 days', NOW() + INTERVAL '10 days', 2, 87, '2024-02-01 08:45:00'),

('c1000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', 'UG',
 'Professional Certification', 'Financial management certification at Makerere University Business School',
 3500000, 12, 'Salary — UGX 3,200,000', 'monthly', 320000, '12 months starting April 2024', 'Central',
 'contracted', '2024-03-01 10:00:00', NOW() + INTERVAL '12 days', '2024-03-05 11:00:00', 1, 54, '2024-03-01 09:45:00'),

('c1000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000003', 'UG',
 'Business Expansion — IT Equipment', 'Purchase servers and networking equipment for growing IT consultancy',
 8000000, 18, 'Salary — UGX 5,800,000', 'monthly', 500000, '18 months starting February 2026', 'Central',
 'active', NOW() - INTERVAL '2 days', NOW() + INTERVAL '15 days', NULL, 3, 112, NOW() - INTERVAL '2 days 15 minutes'),

('c1000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000004', 'UG',
 'Boutique Inventory Stock', 'Pre-season clothing stock purchase for Nakato Boutique ahead of Easter season',
 3500000, 12, 'Business income — UGX 2,800,000', 'monthly', 320000, '12 months starting February 2026', 'Central',
 'active', NOW() - INTERVAL '3 days', NOW() + INTERVAL '14 days', NULL, 1, 35, NOW() - INTERVAL '3 days 15 minutes'),

('c1000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000011', 'UG',
 'Medical Expense Cover', 'Surgery and recovery costs at Mulago National Referral Hospital',
 4500000, 18, 'Salary — UGX 3,300,000', 'monthly', 280000, '18 months starting February 2026', 'Eastern',
 'active', NOW() - INTERVAL '1 day', NOW() + INTERVAL '16 days', NULL, 1, 41, NOW() - INTERVAL '1 day 15 minutes'),

('c1000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000012', 'UG',
 'Farm Equipment Purchase', 'Irrigation pump and tilling equipment for family farm in Wakiso district',
 6000000, 24, 'Salary — UGX 2,900,000', 'monthly', 280000, '24 months starting February 2026', 'Central',
 'active', NOW() - INTERVAL '4 days', NOW() + INTERVAL '13 days', NULL, 3, 18, NOW() - INTERVAL '4 days 15 minutes'),

('c1000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000013', 'UG',
 'Vehicle Purchase — Delivery Van', 'Toyota Hiace for goods delivery business serving Mbarara and Kampala',
 9000000, 24, 'Salary — UGX 5,200,000', 'monthly', 420000, '24 months starting January 2026', 'Western',
 'active', NOW() - INTERVAL '5 days', NOW() + INTERVAL '15 days', NULL, 3, 67, NOW() - INTERVAL '5 days 15 minutes'),

('c1000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000005', 'UG',
 'Business Working Capital', 'Short-term working capital to fulfil supplier contracts at DFCU Bank',
 7000000, 6, 'Salary — UGX 6,500,000', 'monthly', 1200000, '6 months starting February 2026', 'Central',
 'active', NOW() - INTERVAL '6 days 20 hours', NOW() + INTERVAL '14 days', NULL, 2, 29, NOW() - INTERVAL '6 days 21 hours');
-- ---- loan_requests: other EAC countries (one each, demonstrating cross-border marketplace) ----
INSERT INTO loan_requests (
    id, borrower_id, country, title, purpose, requested_amount, duration_months,
    income_source, preferred_repayment_plan, repayment_amount_per_period, repayment_timeline,
    district, status, listed_at, expires_at, contracted_at, number_of_offers, views_count, created_at
) VALUES
-- Kenya — contracted (accepted locally, one rejected cross-border offer)
('c2000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000018', 'KE',
 'Boda-boda Motorcycle Purchase', 'Buy a motorcycle for boda-boda transport business in Nairobi',
 150000, 12, 'Salary — KES 150,000', 'monthly', 14375, '12 months starting March 2026', 'Nairobi',
 'contracted', NOW() - INTERVAL '7 days', NOW() + INTERVAL '8 days', NOW() - INTERVAL '2 days', 2, 19, NOW() - INTERVAL '7 days 10 minutes'),

-- TZ — active, cross-border offer pending
('c2000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000035', 'TZ',
 'Tailoring Machine Purchase', 'Industrial sewing machine to expand a home tailoring business in Dar es Salaam',
 800000, 12, 'Salary — TZS 2,100,000', 'monthly', 71000, '12 months starting March 2026', 'Dar es Salaam',
 'active', NOW() - INTERVAL '6 days', NOW() + INTERVAL '9 days', NULL, 1, 18, NOW() - INTERVAL '6 days 10 minutes'),

-- RW — active, cross-border offer pending
('c2000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000052', 'RW',
 'University Tuition Fees', 'Second-year tuition fees at a private university in Kigali',
 600000, 10, 'Salary — RWF 850,000', 'monthly', 67500, '10 months starting March 2026', 'Kigali',
 'active', NOW() - INTERVAL '5 days', NOW() + INTERVAL '10 days', NULL, 1, 17, NOW() - INTERVAL '5 days 10 minutes'),

-- BI — active, cross-border offer pending
('c2000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000069', 'BI',
 'Retail Shop Stock Restock', 'Restocking a small retail shop in central Bujumbura ahead of a busy season',
 700000, 12, 'Salary — BIF 950,000', 'monthly', 64750, '12 months starting March 2026', 'Bujumbura',
 'active', NOW() - INTERVAL '4 days', NOW() + INTERVAL '11 days', NULL, 1, 16, NOW() - INTERVAL '4 days 10 minutes'),

-- SS — active, cross-border offer pending
('c2000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000086', 'SS',
 'Water Borehole Drilling', 'Community borehole drilling to secure a clean water supply near Juba',
 250000, 18, 'Salary — SSP 300,000', 'monthly', 15500, '18 months starting March 2026', 'Juba',
 'active', NOW() - INTERVAL '3 days', NOW() + INTERVAL '12 days', NULL, 1, 15, NOW() - INTERVAL '3 days 10 minutes'),

-- CD — active, cross-border offer pending
('c2000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000103', 'CD',
 'Generator Purchase for Shop', 'Backup generator to keep a small retail shop in Kinshasa running during outages',
 900000, 12, 'Salary — CDF 1,100,000', 'monthly', 83250, '12 months starting March 2026', 'Kinshasa',
 'active', NOW() - INTERVAL '2 days', NOW() + INTERVAL '13 days', NULL, 1, 14, NOW() - INTERVAL '2 days 10 minutes'),

-- SO — active, cross-border offer pending
('c2000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000120', 'SO',
 'Sewing Equipment Expansion', 'Additional sewing machines and materials to grow a tailoring business in Mogadishu',
 3500000, 12, 'Salary — SOS 4,200,000', 'monthly', 340000, '12 months starting March 2026', 'Mogadishu',
 'active', NOW() - INTERVAL '1 days', NOW() + INTERVAL '14 days', NULL, 1, 13, NOW() - INTERVAL '1 days 10 minutes');

-- ---- loan_offers: other EAC countries (all cross-border by design) ----
INSERT INTO loan_offers (
    id, request_id, lender_id, offer_amount, interest_rate_pct, late_fee_pct,
    repayment_frequency, installment_amount, proposed_expectations,
    terms_locked_at, status, offered_at, accepted_at, created_at
) VALUES
-- Kenya listing: local lender accepted
('d2000000-0000-0000-0000-000000000001', 'c2000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000026',
 150000, 15.0, 2.0, 'monthly', 14375, 'Can fund the full motorcycle purchase at 15% per annum, monthly repayments.',
 NOW() - INTERVAL '7 days', 'accepted', NOW() - INTERVAL '7 days', NOW() - INTERVAL '2 days', NOW() - INTERVAL '7 days'),

-- Kenya listing: Tanzanian cross-border lender rejected
('d2000000-0000-0000-0000-000000000002', 'c2000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000043',
 150000, 16.5, 2.0, 'monthly', 14655, 'Willing to fund cross-border at 16.5% per annum.',
 NOW() - INTERVAL '6 days', 'rejected', NOW() - INTERVAL '6 days', NULL, NOW() - INTERVAL '6 days'),

-- TZ listing — cross-border offer from a RW lender
('d2000000-0000-0000-0000-000000000003', 'c2000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000060',
 800000, 13.0, 2.0, 'monthly', 75333, 'Cross-border offer at 13.0% per annum.',
 NOW() - INTERVAL '5 days', 'pending', NOW() - INTERVAL '5 days', NULL, NOW() - INTERVAL '5 days'),

-- RW listing — cross-border offer from a BI lender
('d2000000-0000-0000-0000-000000000004', 'c2000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000077',
 600000, 12.5, 2.0, 'monthly', 67500, 'Cross-border offer at 12.5% per annum.',
 NOW() - INTERVAL '4 days', 'pending', NOW() - INTERVAL '4 days', NULL, NOW() - INTERVAL '4 days'),

-- BI listing — cross-border offer from a SS lender
('d2000000-0000-0000-0000-000000000005', 'c2000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000094',
 700000, 14.0, 2.0, 'monthly', 66500, 'Cross-border offer at 14.0% per annum.',
 NOW() - INTERVAL '3 days', 'pending', NOW() - INTERVAL '3 days', NULL, NOW() - INTERVAL '3 days'),

-- SS listing — cross-border offer from a CD lender
('d2000000-0000-0000-0000-000000000006', 'c2000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000111',
 250000, 17.0, 2.0, 'monthly', 16250, 'Cross-border offer at 17.0% per annum.',
 NOW() - INTERVAL '2 days', 'pending', NOW() - INTERVAL '2 days', NULL, NOW() - INTERVAL '2 days'),

-- CD listing — cross-border offer from a SO lender
('d2000000-0000-0000-0000-000000000007', 'c2000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000128',
 900000, 15.5, 2.0, 'monthly', 86625, 'Cross-border offer at 15.5% per annum.',
 NOW() - INTERVAL '1 days', 'pending', NOW() - INTERVAL '1 days', NULL, NOW() - INTERVAL '1 days'),

-- SO listing — cross-border offer from a KE lender
('d2000000-0000-0000-0000-000000000008', 'c2000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000026',
 3500000, 18.0, 2.0, 'monthly', 344166, 'Cross-border offer at 18.0% per annum.',
 NOW() - INTERVAL '0 days', 'pending', NOW() - INTERVAL '0 days', NULL, NOW() - INTERVAL '0 days');
-- ---- loan_offers: UGANDA (unchanged from prior seed) ----
INSERT INTO loan_offers (
    id, request_id, lender_id, offer_amount, interest_rate_pct, late_fee_pct,
    repayment_frequency, installment_amount, proposed_expectations,
    terms_locked_at, status, offered_at, accepted_at, created_at
) VALUES
('d1000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000008',
 5000000, 11.0, 2.0, 'monthly', 462500, 'I can provide the full amount at 11% per annum. Monthly instalments work for me.',
 '2024-02-02 10:30:00', 'accepted', '2024-02-02 10:30:00', NOW() + INTERVAL '10 days', '2024-02-02 10:30:00'),

('d1000000-0000-0000-0000-000000000002', 'c1000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000009',
 5000000, 11.5, 2.0, 'monthly', 464583, 'Happy to lend the full amount. Expecting 11.5% per annum with monthly repayments.',
 '2024-02-03 09:00:00', 'rejected', '2024-02-03 09:00:00', NULL, '2024-02-03 09:00:00'),

('d1000000-0000-0000-0000-000000000003', 'c1000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000009',
 3500000, 14.0, 2.0, 'monthly', 332500, 'Willing to fund the full amount at 14% per annum. Monthly repayments as proposed.',
 '2024-03-02 11:00:00', 'accepted', '2024-03-02 11:00:00', '2024-03-05 11:00:00', '2024-03-02 11:00:00'),

('d1000000-0000-0000-0000-000000000004', 'c1000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000008',
 8000000, 10.0, 2.0, 'monthly', 488888, 'Can cover the full amount at 10% per annum. Happy with 18-month monthly instalments.',
 '2026-01-21 11:20:00', 'pending', '2026-01-21 11:20:00', NULL, '2026-01-21 11:20:00'),

('d1000000-0000-0000-0000-000000000005', 'c1000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000010',
 8000000, 10.5, 2.0, 'monthly', 491111, 'Offering full amount at 10.5% per annum. Monthly instalments over 18 months.',
 '2026-01-23 13:15:00', 'pending', '2026-01-23 13:15:00', NULL, '2026-01-23 13:15:00'),

('d1000000-0000-0000-0000-000000000010', 'c1000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000009',
 3000000, 9.5, 2.0, 'monthly', 182500, 'Can contribute UGX 3M toward the equipment purchase at 9.5% per annum, repayable monthly.',
 '2026-01-24 08:40:00', 'pending', '2026-01-24 08:40:00', NULL, '2026-01-24 08:40:00'),

('d1000000-0000-0000-0000-000000000006', 'c1000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000006',
 3500000, 14.0, 2.0, 'monthly', 332500, 'Can fund the full requested amount at 14% per annum. Monthly repayments as stated.',
 '2026-01-27 10:30:00', 'pending', '2026-01-27 10:30:00', NULL, '2026-01-27 10:30:00'),

('d1000000-0000-0000-0000-000000000007', 'c1000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000011',
 4500000, 14.5, 1.5, 'monthly', 286250, 'Prepared to lend the full amount at 14.5% per annum given the medical urgency.',
 '2026-01-28 09:15:00', 'pending', '2026-01-28 09:15:00', NULL, '2026-01-28 09:15:00'),

('d1000000-0000-0000-0000-000000000011', 'c1000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000006',
 3000000, 12.0, 2.0, 'monthly', 140000, 'Can fund UGX 3M now for the pump purchase. Comfortable with the 24-month repayment timeline.',
 NOW() - INTERVAL '3 days 7 hours', 'pending', NOW() - INTERVAL '3 days 7 hours', NULL, NOW() - INTERVAL '3 days 7 hours'),

('d1000000-0000-0000-0000-000000000012', 'c1000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000008',
 6000000, 13.0, 2.0, 'monthly', 282500, 'Can fund the full equipment amount if repayments begin as proposed in February.',
 NOW() - INTERVAL '2 days 18 hours', 'pending', NOW() - INTERVAL '2 days 18 hours', NULL, NOW() - INTERVAL '2 days 18 hours'),

('d1000000-0000-0000-0000-000000000013', 'c1000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000010',
 4000000, 11.5, 2.0, 'monthly', 185833, 'Can cover UGX 4M for the tilling equipment, with monthly payments over 24 months.',
 NOW() - INTERVAL '1 day 9 hours', 'pending', NOW() - INTERVAL '1 day 9 hours', NULL, NOW() - INTERVAL '1 day 9 hours'),

('d1000000-0000-0000-0000-000000000008', 'c1000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000006',
 9000000, 11.0, 2.0, 'monthly', 416250, 'Happy to fund the full van purchase. Expecting 11% per annum over 24 months.',
 NOW() - INTERVAL '4 days 23 hours', 'pending', NOW() - INTERVAL '4 days 23 hours', NULL, NOW() - INTERVAL '4 days 23 hours'),

('d1000000-0000-0000-0000-000000000014', 'c1000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000008',
 3000000, 12.5, 2.0, 'monthly', 140625, 'Can offer UGX 3M as partial funding for the van deposit and initial repairs.',
 NOW() - INTERVAL '3 days 12 hours', 'pending', NOW() - INTERVAL '3 days 12 hours', NULL, NOW() - INTERVAL '3 days 12 hours'),

('d1000000-0000-0000-0000-000000000015', 'c1000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000009',
 5000000, 11.5, 2.0, 'monthly', 232291, 'Can fund UGX 5M toward the van purchase with slightly faster monthly repayment preferred.',
 NOW() - INTERVAL '2 days 6 hours', 'pending', NOW() - INTERVAL '2 days 6 hours', NULL, NOW() - INTERVAL '2 days 6 hours'),

('d1000000-0000-0000-0000-000000000009', 'c1000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000010',
 7000000, 9.5, 2.0, 'monthly', 1277500, 'Can provide full working capital at 9.5% per annum. Six monthly repayments.',
 NOW() - INTERVAL '2 hours', 'pending', NOW() - INTERVAL '2 hours', NULL, NOW() - INTERVAL '2 hours'),

('d1000000-0000-0000-0000-000000000016', 'c1000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000008',
 3000000, 10.0, 2.0, 'monthly', 550000, 'Can cover UGX 3M of the working capital need if the supplier contract is confirmed.',
 NOW() - INTERVAL '45 minutes', 'pending', NOW() - INTERVAL '45 minutes', NULL, NOW() - INTERVAL '45 minutes');

-- ---- agreements: UGANDA (unchanged) + KENYA (cross-border-flow demo) ----
INSERT INTO public.agreements (
    id, offer_id, request_id, repayment_frequency, repayment_amount, repayment_period,
    total_repayment_amount, late_payment_penalty_pct, agreement_text, agreement_snapshot, status,
    borrower_agreed_at, lender_agreed_at, locked_at
) VALUES
('a9000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000001',
 'monthly'::public.repayment_frequency_enum, 462500, 12, 5550000, 2.00,
 'LOAN AGREEMENT between David Mukasa and William Kasujja. Principal: UGX 5,000,000 at 11% interest. Repayments: Monthly UGX 462,500.',
 '{"payment_frequency": "monthly", "payment_amount": 462500, "penalty_pct": 2.00, "repayment_period": 12, "total_repayment_amount": 5550000, "duration_months": 12, "loan_amount": 5000000, "interest_rate_pct": 11.0, "currency_code": "UGX"}'::jsonb,
 'locked'::public.agreement_status_enum, '2024-02-06 14:30:00', '2024-02-06 14:30:00', '2024-02-06 14:30:00'),

('a9000000-0000-0000-0000-000000000002', 'd1000000-0000-0000-0000-000000000003', 'c1000000-0000-0000-0000-000000000002',
 'monthly'::public.repayment_frequency_enum, 332500, 12, 3990000, 2.00,
 'LOAN AGREEMENT between Sarah Namukasa and Catherine Namboze. Principal: UGX 3,500,000 at 14% interest. Repayments: Monthly UGX 332,500.',
 '{"payment_frequency": "monthly", "payment_amount": 332500, "penalty_pct": 2.00, "repayment_period": 12, "total_repayment_amount": 3990000, "duration_months": 12, "loan_amount": 3500000, "interest_rate_pct": 14.0, "currency_code": "UGX"}'::jsonb,
 'locked'::public.agreement_status_enum, '2024-03-05 11:00:00', '2024-03-05 11:00:00', '2024-03-05 11:00:00'),

('a9000000-0000-0000-0000-000000000003', 'd2000000-0000-0000-0000-000000000001', 'c2000000-0000-0000-0000-000000000001',
 'monthly'::public.repayment_frequency_enum, 14375, 12, 172500, 2.00,
 'LOAN AGREEMENT between Wanjiru Kamau and Otieno Mwangi. Principal: KES 150,000 at 15% interest. Repayments: Monthly KES 14,375.',
 '{"payment_frequency": "monthly", "payment_amount": 14375, "penalty_pct": 2.00, "repayment_period": 12, "total_repayment_amount": 172500, "duration_months": 12, "loan_amount": 150000, "interest_rate_pct": 15.0, "currency_code": "KES"}'::jsonb,
 'locked'::public.agreement_status_enum, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days');

SET session_replication_role = 'origin';

-- ---- contact_reveals ----
INSERT INTO contact_reveals (id, offer_id, request_id, revealed_by, status, revealed_at, created_at) VALUES
('f1000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000001',
 '10000000-0000-0000-0000-000000000001', 'revealed', NOW() + INTERVAL '13 days', '2024-02-06 14:31:00'),

('f1000000-0000-0000-0000-000000000002', 'd1000000-0000-0000-0000-000000000003', 'c1000000-0000-0000-0000-000000000002',
 '10000000-0000-0000-0000-000000000002', 'pending', NULL, '2024-03-05 11:01:00'),

('f1000000-0000-0000-0000-000000000003', 'd2000000-0000-0000-0000-000000000001', 'c2000000-0000-0000-0000-000000000001',
 '10000000-0000-0000-0000-000000000018', 'revealed', NOW() - INTERVAL '1 day', NOW() - INTERVAL '2 days')
ON CONFLICT (offer_id) DO NOTHING;

-- ============================================================
-- PART C -- WATCHLIST, NOTIFICATIONS, REFERRALS
-- ============================================================

INSERT INTO watchlist (id, user_id, request_id, added_at) VALUES
('e3000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000005', 'c1000000-0000-0000-0000-000000000003', '2026-01-21 08:00:00'),
('e3000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000008', 'c1000000-0000-0000-0000-000000000005', '2026-01-26 11:00:00'),
('e3000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000009', 'c1000000-0000-0000-0000-000000000004', '2026-01-25 14:00:00'),
('e3000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000007', 'c1000000-0000-0000-0000-000000000008', NOW() - INTERVAL '3 hours'),
('e3000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000012', 'c1000000-0000-0000-0000-000000000003', '2026-01-22 10:00:00'),
('e3000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000094', 'c2000000-0000-0000-0000-000000000006', NOW() - INTERVAL '1 day'),
('e3000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000043', 'c2000000-0000-0000-0000-000000000007', NOW() - INTERVAL '12 hours')
ON CONFLICT (user_id, request_id) DO NOTHING;

INSERT INTO notifications (id, user_id, type, title, body, is_read, request_id, offer_id, created_at) VALUES
-- David Mukasa (UG) -- offer accepted, contact revealed
('e4000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'offer_accepted', 'Offer accepted',
 'You accepted Pearl Capital''s offer. Contact details have been shared.', TRUE, 'c1000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-000000000001', NOW() + INTERVAL '11 days'),
('e4000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000008', 'offer_accepted', 'Your offer was accepted',
 'David Mukasa accepted your offer. Contact details have been shared.', TRUE, 'c1000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-000000000001', NOW() + INTERVAL '11 days'),
('e4000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', 'contact_revealed', 'Contact details revealed',
 'You can now connect with Pearl Capital Investment Fund directly.', TRUE, 'c1000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-000000000001', '2024-02-07 10:00:00'),
('e4000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000008', 'contact_revealed', 'Contact details revealed',
 'The borrower has revealed contact details. You can now connect directly.', TRUE, 'c1000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-000000000001', '2024-02-07 10:00:00'),
-- Sarah Namukasa (UG) -- offer accepted, contact pending reveal
('e4000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000002', 'offer_accepted', 'Offer accepted',
 'You accepted Victoria Investment Group''s offer. Reveal contact details to connect.', FALSE, 'c1000000-0000-0000-0000-000000000002', 'd1000000-0000-0000-0000-000000000003', '2024-03-05 11:01:00'),
('e4000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000009', 'offer_accepted', 'Your offer was accepted',
 'Sarah Namukasa accepted your offer. Waiting for contact details to be revealed.', FALSE, 'c1000000-0000-0000-0000-000000000002', 'd1000000-0000-0000-0000-000000000003', '2024-03-05 11:01:00'),
-- James Okello (UG) -- offers received
('e4000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000003', 'offer_received', 'New offer received',
 'Pearl Capital Investment Fund made an offer on your listing.', FALSE, 'c1000000-0000-0000-0000-000000000003', 'd1000000-0000-0000-0000-000000000004', '2026-01-21 11:21:00'),
('e4000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000003', 'offer_received', 'New offer received',
 'Equator Finance Corporation made an offer on your listing.', FALSE, 'c1000000-0000-0000-0000-000000000003', 'd1000000-0000-0000-0000-000000000005', '2026-01-23 13:16:00'),
-- Maria Nakato (UG) -- offer received
('e4000000-0000-0000-0000-000000000009', '10000000-0000-0000-0000-000000000004', 'offer_received', 'New offer received',
 'GreenLeaf Agro Solutions made an offer on your listing.', FALSE, 'c1000000-0000-0000-0000-000000000004', 'd1000000-0000-0000-0000-000000000006', '2026-01-27 10:31:00'),
-- Robert Ssemwanga (UG) -- closing soon
('e4000000-0000-0000-0000-000000000010', '10000000-0000-0000-0000-000000000005', 'closing_soon_6h', 'Listing closing soon',
 'Your listing "Business Working Capital" closes in under 6 hours.', FALSE, 'c1000000-0000-0000-0000-000000000008', NULL, NOW() - INTERVAL '1 hour'),
-- David's second lender rejected
('e4000000-0000-0000-0000-000000000011', '10000000-0000-0000-0000-000000000009', 'offer_rejected', 'Your offer was not selected',
 'David Mukasa selected a different offer. Your offer on "Home Renovation Loan" was not chosen.', TRUE, 'c1000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-000000000002', NOW() + INTERVAL '12 days'),
-- Kenya — offer accepted, contact revealed (cross-border flow demo)
('e4000000-0000-0000-0000-000000000012', '10000000-0000-0000-0000-000000000018', 'offer_accepted', 'Offer accepted',
 'You accepted Otieno Mwangi''s offer. Contact details have been shared.', TRUE, 'c2000000-0000-0000-0000-000000000001', 'd2000000-0000-0000-0000-000000000001', NOW() - INTERVAL '2 days'),
('e4000000-0000-0000-0000-000000000013', '10000000-0000-0000-0000-000000000026', 'offer_accepted', 'Your offer was accepted',
 'Wanjiru Kamau accepted your offer. Contact details have been shared.', TRUE, 'c2000000-0000-0000-0000-000000000001', 'd2000000-0000-0000-0000-000000000001', NOW() - INTERVAL '2 days'),
('e4000000-0000-0000-0000-000000000014', '10000000-0000-0000-0000-000000000018', 'contact_revealed', 'Contact details revealed',
 'You can now connect with Otieno Mwangi directly.', TRUE, 'c2000000-0000-0000-0000-000000000001', 'd2000000-0000-0000-0000-000000000001', NOW() - INTERVAL '1 day'),
('e4000000-0000-0000-0000-000000000015', '10000000-0000-0000-0000-000000000026', 'contact_revealed', 'Contact details revealed',
 'The borrower has revealed contact details. You can now connect directly.', TRUE, 'c2000000-0000-0000-0000-000000000001', 'd2000000-0000-0000-0000-000000000001', NOW() - INTERVAL '1 day'),
('e4000000-0000-0000-0000-000000000016', '10000000-0000-0000-0000-000000000043', 'offer_rejected', 'Your offer was not selected',
 'Wanjiru Kamau selected a different offer. Your cross-border offer was not chosen.', TRUE, 'c2000000-0000-0000-0000-000000000001', 'd2000000-0000-0000-0000-000000000002', NOW() - INTERVAL '2 days'),
-- New-country offer_received notifications
('e4000000-0000-0000-0000-000000000017', '10000000-0000-0000-0000-000000000035', 'offer_received', 'New offer received',
 'A lender from Rwanda made a cross-border offer on your listing.', FALSE, 'c2000000-0000-0000-0000-000000000002', 'd2000000-0000-0000-0000-000000000003', NOW() - INTERVAL '6 days'),
('e4000000-0000-0000-0000-000000000018', '10000000-0000-0000-0000-000000000052', 'offer_received', 'New offer received',
 'A lender from Burundi made a cross-border offer on your listing.', FALSE, 'c2000000-0000-0000-0000-000000000003', 'd2000000-0000-0000-0000-000000000004', NOW() - INTERVAL '5 days'),
('e4000000-0000-0000-0000-000000000019', '10000000-0000-0000-0000-000000000069', 'offer_received', 'New offer received',
 'A lender from South Sudan made a cross-border offer on your listing.', FALSE, 'c2000000-0000-0000-0000-000000000004', 'd2000000-0000-0000-0000-000000000005', NOW() - INTERVAL '4 days'),
('e4000000-0000-0000-0000-000000000020', '10000000-0000-0000-0000-000000000086', 'offer_received', 'New offer received',
 'A lender from DR Congo made a cross-border offer on your listing.', FALSE, 'c2000000-0000-0000-0000-000000000005', 'd2000000-0000-0000-0000-000000000006', NOW() - INTERVAL '3 days'),
('e4000000-0000-0000-0000-000000000021', '10000000-0000-0000-0000-000000000103', 'offer_received', 'New offer received',
 'A lender from Somalia made a cross-border offer on your listing.', FALSE, 'c2000000-0000-0000-0000-000000000006', 'd2000000-0000-0000-0000-000000000007', NOW() - INTERVAL '2 days'),
('e4000000-0000-0000-0000-000000000022', '10000000-0000-0000-0000-000000000120', 'offer_received', 'New offer received',
 'A lender from Kenya made a cross-border offer on your listing.', FALSE, 'c2000000-0000-0000-0000-000000000007', 'd2000000-0000-0000-0000-000000000008', NOW() - INTERVAL '1 days')
ON CONFLICT DO NOTHING;

INSERT INTO referrals (id, referrer_id, referred_email, referred_user_id, code, is_activated, activated_at, reward_applied, created_at) VALUES
('e5000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'frank.omondi@gmail.com', '10000000-0000-0000-0000-000000000011', 'NIP-DAVID-01', TRUE, '2024-03-08 15:00:00', TRUE, '2024-03-01 10:00:00'),
('e5000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000008', 'lucy.nambi@yahoo.com', '10000000-0000-0000-0000-000000000012', 'NIP-PEARL-01', TRUE, '2024-03-10 12:00:00', TRUE, '2024-03-05 09:00:00'),
('e5000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000003', 'charles.mwesigwa@gmail.com', '10000000-0000-0000-0000-000000000013', 'NIP-JAMES-01', TRUE, '2024-03-12 17:00:00', FALSE, '2024-03-08 11:00:00'),
('e5000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000001', 'newuser@example.com', NULL, 'NIP-DAVID-02', FALSE, NULL, FALSE, '2026-01-20 09:00:00'),
('e5000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000018', 'otieno.mwangi@nipanze-ke.test', '10000000-0000-0000-0000-000000000026', 'NIP-WANJIRU-01', TRUE, '2026-02-10 08:05:00', TRUE, '2026-02-09 12:00:00')
ON CONFLICT DO NOTHING;
-- ============================================================
-- PART D — VERIFICATION
-- ============================================================

SELECT c.code, c.name, c.currency_code, c.is_active, COUNT(p.id) AS user_count
FROM countries c
LEFT JOIN profiles p ON p.country = c.code AND p.id::text LIKE '10000000%'
GROUP BY c.code, c.name, c.currency_code, c.is_active
ORDER BY c.code;

SELECT table_name, record_count FROM (
    SELECT 'auth.users'           AS table_name, COUNT(*) AS record_count FROM auth.users           WHERE id::text LIKE '10000000%'
    UNION ALL SELECT 'profiles',                 COUNT(*) FROM profiles                              WHERE id::text LIKE '10000000%'
    UNION ALL SELECT 'subscriptions',            COUNT(*) FROM subscriptions
    UNION ALL SELECT 'kyc_verifications',        COUNT(*) FROM kyc_verifications
    UNION ALL SELECT 'loan_requests',            COUNT(*) FROM loan_requests
    UNION ALL SELECT 'loan_offers',              COUNT(*) FROM loan_offers
    UNION ALL SELECT 'agreements',               COUNT(*) FROM agreements
    UNION ALL SELECT 'contact_reveals',          COUNT(*) FROM contact_reveals
    UNION ALL SELECT 'watchlist',                COUNT(*) FROM watchlist
    UNION ALL SELECT 'notifications',            COUNT(*) FROM notifications
    UNION ALL SELECT 'referrals',                COUNT(*) FROM referrals
) t ORDER BY table_name;

SELECT p.country, p.full_name, au.email,
       au.email_confirmed_at IS NOT NULL AS confirmed,
       p.account_status, p.is_admin,
       s.plan AS subscription_plan, s.status AS subscription_status
FROM profiles p
LEFT JOIN auth.users  au ON au.id = p.id
LEFT JOIN subscriptions s ON s.user_id = p.id AND s.status = 'active'
WHERE p.id::text LIKE '10000000%'
ORDER BY p.country, p.created_at;

SELECT lr.country, lr.title, lr.district, lr.requested_amount,
       lr.repayment_amount_per_period, lr.number_of_offers, lr.status, lr.expires_at,
       (lr.expires_at < NOW() + INTERVAL '24 hours') AS closing_soon
FROM loan_requests lr
WHERE lr.status = 'active'
ORDER BY lr.country, lr.listed_at DESC;

SELECT lr.country AS listing_country, p_lender.country AS lender_country,
       lo.status AS offer_status, lo.offer_amount, lr.title AS listing_title,
       cr.status AS reveal_status
FROM loan_offers lo
JOIN loan_requests lr ON lr.id = lo.request_id
JOIN profiles p_lender ON p_lender.id = lo.lender_id
LEFT JOIN contact_reveals cr ON cr.offer_id = lo.id
ORDER BY lr.country, lo.offered_at;

SELECT '✅ Nipanze seed v5.1 inserted successfully — 8 countries x 17 users each (136 total), identical role structure per country, full cross-border marketplace demo, no schema mismatches' AS status;


-- ==============================================================================
-- 3. CONSOLIDATED PATCHES & EXTENSIONS (sql/patch.sql)
-- ==============================================================================

-- ============================================
-- NIPANZE Combined Database Patch
--
-- Apply after sql/schema.sql and sql/seed.sql for an existing database.
-- This file consolidates the former sql/patch_*.sql fragments so the sql/
-- directory keeps the three main database scripts: schema.sql, seed.sql,
-- and patch.sql.
--
-- Sections are intentionally ordered so later patches can depend on objects
-- created by earlier sections.
-- ============================================


-- ============================================================
-- BEGIN MERGED SECTION: fix_permissions_patch.sql
-- ============================================================

-- ============================================================
-- FIX SCHEMA & RPC PERMISSIONS FOR SUPABASE CLOUD
-- Run this script in your Supabase SQL Editor (https://app.supabase.com)
-- to resolve "permission denied for schema public" (42501)
-- ============================================================

-- 1. Grant USAGE on public schema to all API roles
GRANT USAGE ON SCHEMA public TO authenticated, anon, service_role;

-- 2. Grant table permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated, service_role;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO anon;

-- 3. Grant sequence permissions
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO authenticated, anon, service_role;

-- 4. Re-create check_phone_registered function with SECURITY DEFINER and grant execution
CREATE OR REPLACE FUNCTION public.check_phone_registered(p_phone TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_email TEXT;
    v_digits TEXT;
BEGIN
    v_digits := regexp_replace(p_phone, '[^\d]', '', 'g');

    SELECT au.email INTO v_email
    FROM auth.users au
    LEFT JOIN public.profiles p ON p.id = au.id
    WHERE p.phone = p_phone
       OR au.phone = p_phone
       OR au.email = p_phone
       OR (v_digits <> '' AND (au.email = v_digits || '@nipanze.test' OR p.phone = '+' || v_digits))
    LIMIT 1;

    RETURN v_email;
END;
$$;

GRANT EXECUTE ON FUNCTION public.check_phone_registered(TEXT) TO authenticated, anon, service_role;

-- 4b. Re-create handle_new_auth_user function with SECURITY DEFINER
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_country TEXT;
    v_phone TEXT;
BEGIN
    v_country := UPPER(COALESCE(NEW.raw_user_meta_data->>'country_code', 'UG'));
    IF NOT EXISTS (SELECT 1 FROM public.countries WHERE code = v_country) THEN
        v_country := 'UG';
    END IF;

    v_phone := COALESCE(NEW.raw_user_meta_data->>'phone', NEW.phone);

    INSERT INTO public.profiles (
        id, full_name, phone, account_status, is_admin, country
    )
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', SPLIT_PART(NEW.email, '@', 1)),
        v_phone,
        'pending_verification',
        FALSE,
        v_country
    )
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        phone = COALESCE(EXCLUDED.phone, public.profiles.phone),
        country = COALESCE(EXCLUDED.country, public.profiles.country);

    -- Auto confirm mock email users for phone sign ups
    IF NEW.email LIKE '%@nipanze.test' AND NEW.email_confirmed_at IS NULL THEN
        UPDATE auth.users SET email_confirmed_at = NOW() WHERE id = NEW.id;
    END IF;

    -- Every new user gets a free subscription (can browse marketplace and post requests)
    INSERT INTO public.subscriptions (user_id, plan, status, amount_minor_units)
    VALUES (NEW.id, 'free', 'active', 0)
    ON CONFLICT (user_id) WHERE status = 'active' DO NOTHING;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_auth_user();

-- 5. Profiles RLS Policies (ensure anon & authenticated can insert/update profile rows)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own or public profiles" ON public.profiles;
CREATE POLICY "Users can view own or public profiles"
  ON public.profiles FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id OR auth.uid() IS NOT NULL);

-- 6. Subscriptions RLS Policies (ensure authenticated users can insert and update their own subscription rows)
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "subscriptions: own or admin read" ON public.subscriptions;
DROP POLICY IF EXISTS "subscriptions: own read" ON public.subscriptions;
CREATE POLICY "subscriptions: own or admin read"
  ON public.subscriptions FOR SELECT TO authenticated
  USING (auth.uid() = user_id OR (private.is_admin() IS NOT NULL AND private.is_admin()));

DROP POLICY IF EXISTS "subscriptions: own insert" ON public.subscriptions;
CREATE POLICY "subscriptions: own insert"
  ON public.subscriptions FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "subscriptions: own update" ON public.subscriptions;
CREATE POLICY "subscriptions: own update"
  ON public.subscriptions FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- END MERGED SECTION: fix_permissions_patch.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_schema_v6.sql
-- ============================================================

-- ============================================
-- NIPANZE — Patch v5.0 → v6.0
-- Paste into Supabase Cloud SQL Editor and run once, top to bottom.
-- Idempotent: safe to re-run (uses IF NOT EXISTS / ON CONFLICT / DO blocks
-- / CREATE OR REPLACE throughout). Written against the v5.0 schema.sql you
-- shared — every object below either ALTERs an existing v5.0 object or
-- CREATEs a genuinely new one; nothing from v5.0 is dropped.
--
-- What this patch does, matching README.md / BUILD_PLAN.md v6.0:
--   PART 1 — Multi-Market fix: retires the 8-country EAC list, adopts the
--            7-market list (UG/KE/TZ/RW/NG/ZA/EG), adds countries.forex_enabled,
--            adds the new `currencies` table (7 market currencies + USD),
--            adds system_settings.allow_foreign_currency_loans.
--   PART 2 — Forex module (Stage 4.7): forex_requests, forex_offers,
--            forex_agreements, forex_contact_reveals — mirroring the
--            existing loan_requests/loan_offers/agreements/contact_reveals
--            pattern exactly (locked bidding, selective transparency,
--            country-locked-at-insert, no country column on offers).
--   PART 3 — Trust & reviews extended to be module-agnostic: reviews gains
--            a nullable forex_contract_id sibling to contract_id;
--            recompute_trust_aggregates() now unions loan + forex
--            completed deals into ONE global aggregate per user.
--   PART 4 — Watchlist/notifications made forex-aware (nullable FK columns
--            added, nothing existing removed).
--   PART 5 — RLS, Realtime publication, and grants for every new object.
--
-- Safe to run against real data: PART 1 will NOT delete a retired EAC
-- country row if it's still referenced by an existing profile or listing —
-- it pauses it (is_active/forex_enabled = FALSE) instead and raises a
-- NOTICE so you can migrate that data first if needed.
-- ============================================


-- ============================================
-- PART 1 — MULTI-MARKET FIX (8-country EAC → 7-market)
-- ============================================

-- 1.1 countries.forex_enabled — independent gate from is_active (lending)
ALTER TABLE countries ADD COLUMN IF NOT EXISTS forex_enabled BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN countries.forex_enabled IS
'v6.0: independent gate from is_active. is_active controls LENDING availability in this
 market; forex_enabled controls FOREX availability. A market can go live for one without
 the other — see currencies.forex_trading_enabled for the additional per-currency gate.';

-- 1.2 Retire Burundi / South Sudan / DR Congo / Somalia (the old EAC-only
-- scope). Only deletes if nothing references them yet; otherwise pauses them.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM profiles WHERE country IN ('BI','SS','CD','SO'))
       AND NOT EXISTS (SELECT 1 FROM loan_requests WHERE country IN ('BI','SS','CD','SO'))
    THEN
        DELETE FROM countries WHERE code IN ('BI','SS','CD','SO');
        RAISE NOTICE 'Removed retired EAC-only countries (BI, SS, CD, SO) — no existing data referenced them.';
    ELSE
        UPDATE countries SET is_active = FALSE, forex_enabled = FALSE WHERE code IN ('BI','SS','CD','SO');
        RAISE NOTICE 'BI/SS/CD/SO still referenced by existing profiles/listings — paused (is_active/forex_enabled = FALSE) instead of deleted. Migrate that data manually if you want them fully removed.';
    END IF;
END $$;

-- 1.3 Add the three new v6.0 markets — Nigeria, South Africa, Egypt
INSERT INTO countries (code, name, currency_code, phone_prefix, is_active, forex_enabled) VALUES
    ('NG', 'Nigeria',      'NGN', '+234', FALSE, FALSE),
    ('ZA', 'South Africa', 'ZAR', '+27',  FALSE, FALSE),
    ('EG', 'Egypt',        'EGP', '+20',  FALSE, FALSE)
ON CONFLICT (code) DO NOTHING;

-- Sanity: countries should now be exactly the 7-market v6.0 list
-- (UG active for lending; KE/TZ/RW/NG/ZA/EG inactive until each clears
-- its own Stage 6 launch review; forex_enabled FALSE for all 7 for now).

-- 1.4 New table: currencies (v6.0)
CREATE TABLE IF NOT EXISTS currencies (
    code                    TEXT PRIMARY KEY,          -- ISO 4217
    name                    TEXT NOT NULL,
    is_market_currency      BOOLEAN NOT NULL DEFAULT FALSE,
    market_country          TEXT REFERENCES countries(code),
    forex_trading_enabled   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_cur_market_country CHECK (
        (is_market_currency = FALSE AND market_country IS NULL) OR
        (is_market_currency = TRUE  AND market_country IS NOT NULL)
    )
);

COMMENT ON TABLE currencies IS
'v6.0 reference table, decoupled from countries on purpose. A currency existing here
 (usable for loans, denominated amounts, subscription billing) does NOT imply it is cleared
 for forex trading — that is the separate forex_trading_enabled flag, which defaults to FALSE
 for every currency, including the 7 market currencies, until independently reviewed.';

INSERT INTO currencies (code, name, is_market_currency, market_country, forex_trading_enabled) VALUES
    ('UGX', 'Ugandan Shilling',       TRUE,  'UG', FALSE),
    ('KES', 'Kenyan Shilling',        TRUE,  'KE', FALSE),
    ('TZS', 'Tanzanian Shilling',     TRUE,  'TZ', FALSE),
    ('RWF', 'Rwandan Franc',          TRUE,  'RW', FALSE),
    ('NGN', 'Nigerian Naira',         TRUE,  'NG', FALSE),
    ('ZAR', 'South African Rand',     TRUE,  'ZA', FALSE),
    ('EGP', 'Egyptian Pound',         TRUE,  'EG', FALSE),
    ('USD', 'US Dollar',              FALSE, NULL, FALSE)
ON CONFLICT (code) DO NOTHING;

CREATE INDEX IF NOT EXISTS idx_currencies_forex_enabled
    ON currencies (forex_trading_enabled) WHERE forex_trading_enabled = TRUE;

-- 1.5 system_settings: allow_foreign_currency_loans (global default = FALSE)
INSERT INTO system_settings (setting_key, country, setting_value, setting_type, category, description, is_public)
VALUES ('allow_foreign_currency_loans', NULL, 'false', 'boolean', 'marketplace',
        'Whether a loan request may be posted in USD instead of the market''s own currency (global default; override per country).',
        TRUE)
ON CONFLICT (setting_key, COALESCE(country, '__global__')) DO NOTHING;


-- ============================================
-- PART 2 — FOREX MODULE (Stage 4.7)
-- Mirrors the loan_requests / loan_offers / agreements / contact_reveals
-- pattern exactly: free to post, Lender+ to offer, Pro-only preferred rate,
-- locked bidding, country copied+frozen at insert, no country column on
-- offers (read through the parent request).
-- ============================================

-- 2.1 forex_requests
CREATE TABLE IF NOT EXISTS forex_requests (
    id                     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    requester_id           UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
    country                TEXT NOT NULL REFERENCES countries(code),

    currency_held          TEXT NOT NULL REFERENCES currencies(code),
    currency_needed        TEXT NOT NULL REFERENCES currencies(code),
    amount                 BIGINT NOT NULL CONSTRAINT chk_fr_amount_positive CHECK (amount > 0),
    preferred_rate         NUMERIC(14,6) CONSTRAINT chk_fr_preferred_rate_positive
                                CHECK (preferred_rate IS NULL OR preferred_rate > 0),
    settlement_preference  TEXT NOT NULL,   -- in-person / mobile money / bank transfer / other — disclosed only, never brokered
    is_urgent              BOOLEAN NOT NULL DEFAULT FALSE,

    terms_locked_at        TIMESTAMP,
    number_of_offers       INT NOT NULL DEFAULT 0,
    status                 loan_status_enum NOT NULL DEFAULT 'active',

    listed_at               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at               TIMESTAMP,
    contracted_at             TIMESTAMP,
    cancelled_at               TIMESTAMP,
    views_count                 INT NOT NULL DEFAULT 0,

    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_fr_pair_distinct CHECK (currency_held <> currency_needed)
);

COMMENT ON TABLE forex_requests IS
'Peer-to-peer currency-exchange requests. Free to post. requester_id masked on all public
 views, identical boundary to loan_requests.borrower_id. country is copied from the
 requester''s profile at insert time and frozen thereafter. preferred_rate is Pro-only,
 locked on publish. currency_held/currency_needed must both have forex_trading_enabled = TRUE
 at the time of insert (enforced by trg_fn_validate_forex_request).';
COMMENT ON COLUMN forex_requests.requester_id IS
'NEVER exposed in v_forex_listings or any marketplace query. Contact revealed only post-acceptance.';

CREATE INDEX IF NOT EXISTS idx_fx_req_country        ON forex_requests (country);
CREATE INDEX IF NOT EXISTS idx_fx_req_country_status  ON forex_requests (country, status);
CREATE INDEX IF NOT EXISTS idx_fx_req_requester_id    ON forex_requests (requester_id);
CREATE INDEX IF NOT EXISTS idx_fx_req_status          ON forex_requests (status);
CREATE INDEX IF NOT EXISTS idx_fx_req_pair            ON forex_requests (currency_held, currency_needed);

-- 2.2 forex_offers — deliberately no country column, see comment
CREATE TABLE IF NOT EXISTS forex_offers (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id        UUID NOT NULL REFERENCES forex_requests(id) ON DELETE CASCADE,
    offer_maker_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,

    rate_offered      NUMERIC(14,6) NOT NULL CONSTRAINT chk_fo_rate_positive CHECK (rate_offered > 0),
    amount_available  BIGINT NOT NULL CONSTRAINT chk_fo_amount_positive CHECK (amount_available > 0),
    terms             TEXT,   -- settlement method / timing detail, locked on submit

    terms_locked_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status            offer_status_enum NOT NULL DEFAULT 'pending',

    offered_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    accepted_at       TIMESTAMP,
    withdrawn_at      TIMESTAMP,
    expires_at        TIMESTAMP,

    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (request_id, offer_maker_id)
);

COMMENT ON TABLE forex_offers IS
'Offers against a forex request. NO country column, by design — an offer''s country is
 always its parent request''s country, read through request_id -> forex_requests.country,
 exactly the same pattern as loan_offers. Cross-border offers are allowed (no country check
 in trg_fn_validate_forex_offer), matching loan_offers.';

CREATE INDEX IF NOT EXISTS idx_fx_off_request_id     ON forex_offers (request_id);
CREATE INDEX IF NOT EXISTS idx_fx_off_offer_maker_id ON forex_offers (offer_maker_id);
CREATE INDEX IF NOT EXISTS idx_fx_off_status         ON forex_offers (status);
CREATE INDEX IF NOT EXISTS idx_fx_off_req_status     ON forex_offers (request_id, status);

-- 2.3 forex_agreements — mirrors `agreements`
CREATE TABLE IF NOT EXISTS forex_agreements (
    id                     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    offer_id               UUID NOT NULL UNIQUE REFERENCES forex_offers(id) ON DELETE CASCADE,
    request_id             UUID NOT NULL REFERENCES forex_requests(id) ON DELETE CASCADE,

    rate_agreed            NUMERIC(14,6) NOT NULL CONSTRAINT chk_fa_rate_positive CHECK (rate_agreed > 0),
    amount_agreed          BIGINT NOT NULL CONSTRAINT chk_fa_amount_positive CHECK (amount_agreed > 0),
    settlement_terms       TEXT,

    agreement_text         TEXT NOT NULL,
    agreement_snapshot      JSONB,

    status                  agreement_status_enum NOT NULL DEFAULT 'locked',
    requester_agreed_at      TIMESTAMP,
    offer_maker_agreed_at     TIMESTAMP,
    locked_at                  TIMESTAMP,

    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE forex_agreements IS
'Locked exchange agreement. Auto-generated after a forex offer is accepted, exactly mirroring
 agreements for loans. Nipanze never performs the exchange or holds currency — the disclaimer
 reflects that instead of the loan-specific late-fee language.';

CREATE INDEX IF NOT EXISTS idx_fa_offer_id   ON forex_agreements (offer_id);
CREATE INDEX IF NOT EXISTS idx_fa_request_id ON forex_agreements (request_id);
CREATE INDEX IF NOT EXISTS idx_fa_status     ON forex_agreements (status);

-- 2.4 forex_contact_reveals — mirrors `contact_reveals`
CREATE TABLE IF NOT EXISTS forex_contact_reveals (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    offer_id     UUID NOT NULL REFERENCES forex_offers(id) ON DELETE CASCADE,
    request_id   UUID NOT NULL REFERENCES forex_requests(id) ON DELETE CASCADE,
    revealed_by  UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
    status       reveal_status_enum NOT NULL DEFAULT 'pending',
    revealed_at  TIMESTAMP,
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (offer_id)
);

COMMENT ON TABLE forex_contact_reveals IS
'Post-acceptance contact sharing for a forex deal. Identical boundary to contact_reveals:
 irreversible once revealed, enforced at the API layer only via unlock_forex_contact().';

CREATE INDEX IF NOT EXISTS idx_fcr_offer_id   ON forex_contact_reveals (offer_id);
CREATE INDEX IF NOT EXISTS idx_fcr_request_id ON forex_contact_reveals (request_id);


-- ============================================
-- PART 3 — TRUST & REVIEWS: extend to be module-agnostic
-- ============================================

-- 3.1 reviews: add a forex sibling to contract_id, keep exactly one populated
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS forex_contract_id UUID REFERENCES forex_agreements(id) ON DELETE CASCADE;
ALTER TABLE reviews ALTER COLUMN contract_id DROP NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_reviews_one_contract'
    ) THEN
        ALTER TABLE reviews ADD CONSTRAINT chk_reviews_one_contract CHECK (
            (contract_id IS NOT NULL AND forex_contract_id IS NULL) OR
            (contract_id IS NULL AND forex_contract_id IS NOT NULL)
        );
    END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS uidx_reviews_forex_contract_reviewer
    ON reviews (forex_contract_id, reviewer_id) WHERE forex_contract_id IS NOT NULL;

COMMENT ON COLUMN reviews.forex_contract_id IS
'v6.0: sibling to contract_id for forex-originated deals. Exactly one of contract_id /
 forex_contract_id is set per row (chk_reviews_one_contract) — a review is always for
 either a loan agreement or a forex agreement, never both, but both feed the same
 trust_aggregates row for the reviewee.';

-- 3.2 watchlist: forex-aware
ALTER TABLE watchlist ADD COLUMN IF NOT EXISTS forex_request_id UUID REFERENCES forex_requests(id) ON DELETE CASCADE;
ALTER TABLE watchlist ALTER COLUMN request_id DROP NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_wl_one_target'
    ) THEN
        ALTER TABLE watchlist ADD CONSTRAINT chk_wl_one_target CHECK (
            (request_id IS NOT NULL AND forex_request_id IS NULL) OR
            (request_id IS NULL AND forex_request_id IS NOT NULL)
        );
    END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS uidx_wl_user_forex_request
    ON watchlist (user_id, forex_request_id) WHERE forex_request_id IS NOT NULL;

-- 3.3 notifications: forex deep-link columns
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS forex_request_id UUID REFERENCES forex_requests(id) ON DELETE SET NULL;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS forex_offer_id   UUID REFERENCES forex_offers(id)   ON DELETE SET NULL;


-- ============================================
-- PART 4 — TRIGGER FUNCTIONS (forex-specific; loan-side functions unchanged)
-- ============================================

CREATE OR REPLACE FUNCTION trg_fn_set_forex_request_country()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
    IF NEW.country IS NULL THEN
        SELECT country INTO NEW.country FROM profiles WHERE id = NEW.requester_id;
    END IF;
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION trg_fn_set_forex_request_country IS
'v6.0: sets forex_requests.country from the requester''s profiles.country at insert time,
 if not already supplied. Frozen thereafter by trg_fn_lock_forex_request_terms(). Mirrors
 trg_fn_set_request_country() for loans.';

CREATE OR REPLACE FUNCTION trg_fn_require_active_account_forex()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM profiles WHERE id = NEW.requester_id AND account_status != 'active'
    ) THEN
        RAISE EXCEPTION 'NIPANZE_ACCOUNT_INACTIVE: Your account must be active to post a forex request.'
            USING ERRCODE = 'P0101';
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION trg_fn_validate_forex_request()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
    v_held_ok       BOOLEAN;
    v_needed_ok     BOOLEAN;
    v_forex_enabled BOOLEAN;
    v_plan          subscription_plan_enum;
    v_req_country   TEXT;
BEGIN
    v_req_country := COALESCE(NEW.country, (SELECT country FROM profiles WHERE id = NEW.requester_id));

    SELECT forex_enabled INTO v_forex_enabled FROM countries WHERE code = v_req_country;
    IF NOT COALESCE(v_forex_enabled, FALSE) THEN
        RAISE EXCEPTION 'NIPANZE_FOREX_NOT_ENABLED: Forex is not yet enabled in this market.'
            USING ERRCODE = 'P0102';
    END IF;

    SELECT forex_trading_enabled INTO v_held_ok   FROM currencies WHERE code = NEW.currency_held;
    SELECT forex_trading_enabled INTO v_needed_ok FROM currencies WHERE code = NEW.currency_needed;
    IF NOT COALESCE(v_held_ok, FALSE) OR NOT COALESCE(v_needed_ok, FALSE) THEN
        RAISE EXCEPTION 'NIPANZE_CURRENCY_NOT_TRADEABLE: One or both currencies are not cleared for forex trading.'
            USING ERRCODE = 'P0103';
    END IF;

    IF NEW.preferred_rate IS NOT NULL THEN
        SELECT plan INTO v_plan FROM subscriptions
        WHERE user_id = NEW.requester_id AND status = 'active'
        ORDER BY created_at DESC LIMIT 1;

        IF v_plan IS DISTINCT FROM 'pro'::subscription_plan_enum THEN
            RAISE EXCEPTION 'NIPANZE_PRO_REQUIRED: A Pro subscription is required to suggest a preferred exchange rate.'
                USING ERRCODE = 'P0104';
        END IF;
    END IF;

    NEW.terms_locked_at := COALESCE(NEW.terms_locked_at, NOW());
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION trg_fn_validate_forex_request IS
'Server-side currency-eligibility + forex_enabled + Pro-gate check for a new forex request —
 mirrors trg_fn_validate_request_terms() for loans, matching Stage 4.7 exit criteria: a
 currency pair with either leg forex_trading_enabled = FALSE is rejected even if the client
 UI is bypassed.';

CREATE OR REPLACE FUNCTION trg_fn_lock_forex_request_terms()
RETURNS TRIGGER LANGUAGE plpgsql
SET search_path = public AS $$
BEGIN
    IF OLD.terms_locked_at IS NOT NULL AND OLD.preferred_rate IS DISTINCT FROM NEW.preferred_rate THEN
        RAISE EXCEPTION 'NIPANZE_FOREX_REQUEST_TERMS_LOCKED: Preferred rate cannot be edited after publish.'
            USING ERRCODE = 'P0105';
    END IF;

    IF OLD.country IS DISTINCT FROM NEW.country THEN
        RAISE EXCEPTION 'NIPANZE_FOREX_REQUEST_COUNTRY_LOCKED: A forex listing''s country is frozen at publish time and cannot be changed.'
            USING ERRCODE = 'P0106';
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION trg_fn_validate_forex_offer()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
    v_listing forex_requests%ROWTYPE;
    v_plan    subscription_plan_enum;
BEGIN
    SELECT * INTO v_listing FROM forex_requests WHERE id = NEW.request_id;

    IF v_listing.status != 'active' THEN
        RAISE EXCEPTION 'NIPANZE_FOREX_LISTING_NOT_ACTIVE: This forex request is no longer accepting offers.'
            USING ERRCODE = 'P0110';
    END IF;

    IF v_listing.expires_at < NOW() THEN
        RAISE EXCEPTION 'NIPANZE_FOREX_LISTING_EXPIRED: This forex request has expired.'
            USING ERRCODE = 'P0111';
    END IF;

    IF v_listing.requester_id = NEW.offer_maker_id THEN
        RAISE EXCEPTION 'NIPANZE_SELF_OFFER: You cannot make an offer on your own forex request.'
            USING ERRCODE = 'P0112';
    END IF;

    SELECT plan INTO v_plan FROM subscriptions
    WHERE user_id = NEW.offer_maker_id AND status = 'active';

    IF v_plan IS NULL OR v_plan NOT IN ('lender', 'pro') THEN
        RAISE EXCEPTION 'NIPANZE_SUBSCRIPTION_REQUIRED: A Lender or Pro subscription is required to make forex offers.'
            USING ERRCODE = 'P0113';
    END IF;

    IF NEW.rate_offered IS NULL OR NEW.amount_available IS NULL THEN
        RAISE EXCEPTION 'NIPANZE_FOREX_OFFER_TERMS_REQUIRED: Rate offered and available amount are required.'
            USING ERRCODE = 'P0114';
    END IF;

    NEW.terms_locked_at := COALESCE(NEW.terms_locked_at, NOW());
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION trg_fn_validate_forex_offer IS
'Mirrors trg_fn_validate_offer() for loans. No country-match check — cross-border forex
 offers are allowed by default, matching loan_offers and the Multi-Market Architecture
 "resolved for v6.0: allowed" decision.';

CREATE OR REPLACE FUNCTION trg_fn_lock_forex_offer_terms()
RETURNS TRIGGER LANGUAGE plpgsql
SET search_path = public AS $$
BEGIN
    IF OLD.terms_locked_at IS NOT NULL AND (
        OLD.rate_offered     IS DISTINCT FROM NEW.rate_offered OR
        OLD.amount_available IS DISTINCT FROM NEW.amount_available OR
        OLD.terms            IS DISTINCT FROM NEW.terms
    ) THEN
        RAISE EXCEPTION 'NIPANZE_FOREX_OFFER_TERMS_LOCKED: Forex offer terms cannot be edited after submit.'
            USING ERRCODE = 'P0115';
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION trg_fn_lock_accepted_forex_offer()
RETURNS TRIGGER LANGUAGE plpgsql
SET search_path = public AS $$
BEGIN
    IF OLD.status = 'accepted' THEN
        RAISE EXCEPTION 'NIPANZE_FOREX_OFFER_LOCKED: An accepted forex offer cannot be modified.'
            USING ERRCODE = 'P0116';
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION trg_fn_sync_forex_offer_count()
RETURNS TRIGGER LANGUAGE plpgsql
SET search_path = public AS $$
DECLARE
    v_request_id UUID;
BEGIN
    v_request_id := COALESCE(NEW.request_id, OLD.request_id);

    UPDATE forex_requests fr
       SET number_of_offers = (
           SELECT COUNT(*)::INT FROM forex_offers fo
            WHERE fo.request_id = v_request_id AND fo.status = 'pending'
       )
     WHERE fr.id = v_request_id;

    RETURN COALESCE(NEW, OLD);
END;
$$;


-- ============================================
-- PART 5 — TRIGGERS (forex tables)
-- Reuses generic v5.0 functions where they're already table-agnostic:
--   trg_fn_set_listing_expiry() — only touches NEW.country / NEW.expires_at
--   trg_fn_expire_offer()       — only touches NEW.expires_at / NEW.status
--   fn_set_updated_at()         — generic updated_at setter
-- ============================================

DROP TRIGGER IF EXISTS trg_set_forex_request_country ON forex_requests;
CREATE TRIGGER trg_set_forex_request_country
    BEFORE INSERT ON forex_requests
    FOR EACH ROW EXECUTE FUNCTION trg_fn_set_forex_request_country();

DROP TRIGGER IF EXISTS trg_require_active_account_forex ON forex_requests;
CREATE TRIGGER trg_require_active_account_forex
    BEFORE INSERT ON forex_requests
    FOR EACH ROW EXECUTE FUNCTION trg_fn_require_active_account_forex();

DROP TRIGGER IF EXISTS trg_validate_forex_request ON forex_requests;
CREATE TRIGGER trg_validate_forex_request
    BEFORE INSERT ON forex_requests
    FOR EACH ROW EXECUTE FUNCTION trg_fn_validate_forex_request();

DROP TRIGGER IF EXISTS trg_set_forex_listing_expiry ON forex_requests;
CREATE TRIGGER trg_set_forex_listing_expiry
    BEFORE INSERT ON forex_requests
    FOR EACH ROW EXECUTE FUNCTION trg_fn_set_listing_expiry();

DROP TRIGGER IF EXISTS trg_lock_forex_request_terms ON forex_requests;
CREATE TRIGGER trg_lock_forex_request_terms
    BEFORE UPDATE ON forex_requests
    FOR EACH ROW EXECUTE FUNCTION trg_fn_lock_forex_request_terms();

DROP TRIGGER IF EXISTS trg_forex_requests_updated_at ON forex_requests;
CREATE TRIGGER trg_forex_requests_updated_at
    BEFORE UPDATE ON forex_requests
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_expire_forex_offer ON forex_offers;
CREATE TRIGGER trg_expire_forex_offer
    BEFORE INSERT OR UPDATE ON forex_offers
    FOR EACH ROW EXECUTE FUNCTION trg_fn_expire_offer();

DROP TRIGGER IF EXISTS trg_validate_forex_offer ON forex_offers;
CREATE TRIGGER trg_validate_forex_offer
    BEFORE INSERT ON forex_offers
    FOR EACH ROW EXECUTE FUNCTION trg_fn_validate_forex_offer();

DROP TRIGGER IF EXISTS trg_lock_accepted_forex_offer ON forex_offers;
CREATE TRIGGER trg_lock_accepted_forex_offer
    BEFORE UPDATE ON forex_offers
    FOR EACH ROW WHEN (OLD.status = 'accepted')
    EXECUTE FUNCTION trg_fn_lock_accepted_forex_offer();

DROP TRIGGER IF EXISTS trg_lock_forex_offer_terms ON forex_offers;
CREATE TRIGGER trg_lock_forex_offer_terms
    BEFORE UPDATE ON forex_offers
    FOR EACH ROW EXECUTE FUNCTION trg_fn_lock_forex_offer_terms();

DROP TRIGGER IF EXISTS trg_sync_forex_offer_count ON forex_offers;
CREATE TRIGGER trg_sync_forex_offer_count
    AFTER INSERT OR UPDATE OR DELETE ON forex_offers
    FOR EACH ROW EXECUTE FUNCTION trg_fn_sync_forex_offer_count();

DROP TRIGGER IF EXISTS trg_forex_offers_updated_at ON forex_offers;
CREATE TRIGGER trg_forex_offers_updated_at
    BEFORE UPDATE ON forex_offers
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_forex_agreements_updated_at ON forex_agreements;
CREATE TRIGGER trg_forex_agreements_updated_at
    BEFORE UPDATE ON forex_agreements
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();


-- ============================================
-- KYC-aware concurrency limits (loan + forex)
-- Adds system settings and server-side enforcement so KYC-approved
-- users can have higher concurrent active listings if configured.
-- ============================================

-- Insert configurable limits (idempotent)
INSERT INTO system_settings (setting_key, country, setting_value, setting_type, category, description, is_public)
VALUES
  ('max_concurrent_requests_verified', NULL, '5', 'number', 'limits', 'Maximum active loan requests per borrower when KYC is approved', TRUE),
  ('max_concurrent_forex_requests', NULL, '3', 'number', 'limits', 'Maximum active forex requests per requester (global default)', TRUE),
  ('max_concurrent_forex_requests_verified', NULL, '5', 'number', 'limits', 'Maximum active forex requests per requester when KYC is approved', TRUE)
ON CONFLICT (setting_key, COALESCE(country, '__global__')) DO NOTHING;


-- Replace loan max-concurrent function to respect KYC approval
CREATE OR REPLACE FUNCTION trg_fn_max_concurrent_requests()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
    v_active_count INT;
    v_max          INT;
    v_kyc_status   kyc_status_enum;
    v_setting_key  TEXT := 'max_concurrent_requests';
BEGIN
    SELECT status INTO v_kyc_status FROM kyc_verifications WHERE user_id = NEW.borrower_id;
    IF v_kyc_status = 'approved' THEN
        v_setting_key := 'max_concurrent_requests_verified';
    END IF;

    SELECT setting_value::INT INTO v_max
    FROM system_settings WHERE setting_key = v_setting_key AND country IS NULL
    ORDER BY country NULLS LAST LIMIT 1;

    SELECT COUNT(*) INTO v_active_count
    FROM loan_requests
    WHERE borrower_id = NEW.borrower_id AND status = 'active';

    IF v_active_count >= COALESCE(v_max, 0) THEN
        RAISE EXCEPTION 'NIPANZE_MAX_REQUESTS: You have reached the maximum of % active listings.', COALESCE(v_max, 0)
            USING ERRCODE = 'P0002';
    END IF;

    RETURN NEW;
END;
$$;


-- Add forex max-concurrent enforcement (new function + trigger)
CREATE OR REPLACE FUNCTION trg_fn_max_concurrent_forex_requests()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
    v_active_count INT;
    v_max          INT;
    v_kyc_status   kyc_status_enum;
    v_setting_key  TEXT := 'max_concurrent_forex_requests';
BEGIN
    SELECT status INTO v_kyc_status FROM kyc_verifications WHERE user_id = NEW.requester_id;
    IF v_kyc_status = 'approved' THEN
        v_setting_key := 'max_concurrent_forex_requests_verified';
    END IF;

    SELECT setting_value::INT INTO v_max
    FROM system_settings WHERE setting_key = v_setting_key AND country IS NULL
    ORDER BY country NULLS LAST LIMIT 1;

    SELECT COUNT(*) INTO v_active_count
    FROM forex_requests
    WHERE requester_id = NEW.requester_id AND status = 'active';

    IF v_active_count >= COALESCE(v_max, 0) THEN
        RAISE EXCEPTION 'NIPANZE_MAX_FOREX_REQUESTS: You have reached the maximum of % active forex listings.', COALESCE(v_max, 0)
            USING ERRCODE = 'P0102';
    END IF;

    RETURN NEW;
END;
$$;

-- Attach trigger to forex_requests
DROP TRIGGER IF EXISTS trg_max_concurrent_forex_requests ON forex_requests;
CREATE TRIGGER trg_max_concurrent_forex_requests
    BEFORE INSERT ON forex_requests
    FOR EACH ROW EXECUTE FUNCTION trg_fn_max_concurrent_forex_requests();


-- ============================================
-- PART 6 — VIEWS (forex marketplace + offers)
-- ============================================

-- v_forex_listings — mirrors v_loan_listings exactly: requester_id, phone,
-- email, full_name, national ID never exposed; rate_coverage_tier replaces
-- offer_coverage_tier; individual offered rates never shown here.
CREATE OR REPLACE VIEW v_forex_listings AS
SELECT
    fr.id                                                                     AS request_id,
    fr.currency_held,
    fr.currency_needed,
    fr.amount,
    fr.country,
    fr.settlement_preference,
    fr.is_urgent,
    fr.preferred_rate,
    fr.terms_locked_at,
    fr.status,
    fr.number_of_offers,
    CASE
        WHEN fr.number_of_offers = 0 THEN 'low'
        WHEN fr.number_of_offers <= 2 THEN 'medium'
        ELSE 'high'
    END                                                                       AS rate_coverage_tier,
    fr.listed_at,
    fr.expires_at,
    k.status                                                                  AS kyc_status,
    ta.rating_avg                                                             AS trust_rating_avg,
    COALESCE(ta.review_count, 0)                                              AS trust_review_count,
    COALESCE(ta.completed_deals_count, 0)                                     AS trust_completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE)                                AS trust_is_repeat_participant,
    (p.phone_verified_at IS NOT NULL)                                        AS trust_phone_verified,
    ta.response_time_bucket                                                   AS trust_response_time_bucket,
    (k.status = 'approved')                                                   AS trust_is_verified,
    GREATEST(fr.expires_at - NOW(), INTERVAL '0')                            AS time_remaining,
    (fr.expires_at < NOW() + INTERVAL '24 hours')                            AS closing_soon_24h,
    (fr.expires_at < NOW() + INTERVAL '6 hours')                             AS closing_soon_6h
FROM  forex_requests  fr
JOIN  profiles p ON p.id = fr.requester_id
LEFT  JOIN kyc_verifications k  ON k.user_id = fr.requester_id
LEFT  JOIN trust_aggregates  ta ON ta.user_id = fr.requester_id
WHERE fr.status = 'active'
  AND (
    auth.uid() IS NULL OR fr.requester_id <> auth.uid()
  )
  AND (
    auth.uid() IS NULL OR NOT EXISTS (
      SELECT 1 FROM public.forex_offers fo
      WHERE fo.request_id = fr.id
        AND fo.offer_maker_id = auth.uid()
        AND fo.status IN ('pending', 'accepted')
    )
  );

COMMENT ON VIEW v_forex_listings IS
'Anonymised forex marketplace feed, mirroring v_loan_listings. requester_id, contact
 details, and private documents are never present. preferred_rate is shown only when the
 owner is Pro and chose to set it (public, since it is the owner''s own suggestion — offer
 rates from other users are never shown here). rate_coverage_tier is the forex analogue of
 offer_coverage_tier.';

-- v_forex_offers — mirrors v_lender_offers, participant-scoped exact terms
CREATE OR REPLACE VIEW v_forex_offers WITH (security_invoker = true) AS
SELECT
    fo.offer_maker_id,
    fo.id                                                                     AS offer_id,
    fo.request_id,
    fr.currency_held,
    fr.currency_needed,
    fr.amount                                                                 AS requested_amount,
    fr.country,
    fr.settlement_preference,
    fo.rate_offered,
    fo.amount_available,
    fo.terms,
    fo.terms_locked_at,
    fo.status                                                                 AS offer_status,
    fo.offered_at,
    fo.accepted_at,
    ta.rating_avg                                                             AS trust_rating_avg,
    COALESCE(ta.review_count, 0)                                              AS trust_review_count,
    COALESCE(ta.completed_deals_count, 0)                                     AS trust_completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE)                                AS trust_is_repeat_participant,
    (p.phone_verified_at IS NOT NULL)                                        AS trust_phone_verified,
    ta.response_time_bucket                                                   AS trust_response_time_bucket,
    (k.status = 'approved')                                                   AS trust_is_verified,
    fcr.status                                                                AS reveal_status,
    fcr.revealed_at
FROM  forex_offers    fo
JOIN  forex_requests  fr ON fr.id = fo.request_id
JOIN  profiles        p  ON p.id  = fo.offer_maker_id
LEFT  JOIN kyc_verifications k   ON k.user_id  = fo.offer_maker_id
LEFT  JOIN trust_aggregates  ta  ON ta.user_id = fo.offer_maker_id
LEFT  JOIN forex_contact_reveals fcr ON fcr.offer_id = fo.id;

COMMENT ON VIEW v_forex_offers IS
'Forex offer history with reveal status, mirroring v_lender_offers. Requester contact
 details not exposed until reveal_status = revealed.';

-- get_public_forex_offers — mirrors get_public_listing_offers
CREATE OR REPLACE FUNCTION get_public_forex_offers(p_request_id UUID)
RETURNS TABLE (
    id UUID,
    request_id UUID,
    offer_maker_id TEXT,
    rate_offered NUMERIC,
    amount_available BIGINT,
    terms TEXT,
    terms_locked_at TIMESTAMP,
    status TEXT,
    offered_at TIMESTAMP,
    accepted_at TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = ''
AS $$
DECLARE
    v_is_owner       BOOLEAN := FALSE;
    v_is_offer_maker BOOLEAN := FALSE;
BEGIN
    SELECT fr.requester_id = auth.uid() INTO v_is_owner
    FROM public.forex_requests fr
    WHERE fr.id = p_request_id;

    SELECT EXISTS (
        SELECT 1 FROM public.forex_offers own
        WHERE own.request_id = p_request_id
          AND own.offer_maker_id = auth.uid()
          AND own.status IN ('pending', 'accepted')
    ) INTO v_is_offer_maker;

    IF NOT COALESCE(v_is_owner, FALSE) AND NOT COALESCE(v_is_offer_maker, FALSE) THEN
        RETURN;
    END IF;

    IF COALESCE(v_is_owner, FALSE) THEN
        RETURN QUERY
        SELECT
            fo.id,
            fo.request_id,
            ('public-offer-' || ROW_NUMBER() OVER (ORDER BY fo.offered_at ASC))::TEXT AS offer_maker_id,
            fo.rate_offered,
            fo.amount_available,
            fo.terms,
            fo.terms_locked_at,
            fo.status::TEXT,
            fo.offered_at,
            fo.accepted_at
        FROM public.forex_offers fo
        JOIN public.forex_requests fr ON fr.id = fo.request_id
        WHERE fo.request_id = p_request_id
          AND fo.status = 'pending'
          AND (fr.status = 'active' OR fr.requester_id = auth.uid())
        ORDER BY fo.offered_at DESC;
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        fo.id,
        fo.request_id,
        ('your-offer')::TEXT AS offer_maker_id,
        fo.rate_offered,
        fo.amount_available,
        fo.terms,
        fo.terms_locked_at,
        fo.status::TEXT,
        fo.offered_at,
        fo.accepted_at
    FROM public.forex_offers fo
    WHERE fo.request_id = p_request_id
      AND fo.offer_maker_id = auth.uid()
      AND fo.status IN ('pending', 'accepted');
END;
$$;

COMMENT ON FUNCTION get_public_forex_offers(UUID) IS
'Participant-scoped forex bid book, mirroring get_public_listing_offers(). Listing owners
 and offer-makers receive exact terms; all other viewers receive only v_forex_listings
 aggregate coverage (rate_coverage_tier).';


-- ============================================
-- PART 7 — RPCs: accept_forex_offer, unlock_forex_contact
-- Same private/public SECURITY DEFINER-wrapper pattern as accept_offer /
-- unlock_contact for loans.
-- ============================================

CREATE OR REPLACE FUNCTION private.accept_forex_offer_internal(
    p_request_id   UUID,
    p_offer_id     UUID,
    p_requester_id UUID,
    p_caller_id    UUID
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$
DECLARE
    v_listing        public.forex_requests%ROWTYPE;
    v_offer          public.forex_offers%ROWTYPE;
    v_requester      public.profiles%ROWTYPE;
    v_offer_maker    public.profiles%ROWTYPE;
    v_agreement_id   UUID;
    v_agreement_text TEXT;
    v_snapshot       JSONB;
BEGIN
    IF p_caller_id IS NULL OR p_caller_id != p_requester_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Caller is not the request owner.'
            USING ERRCODE = 'P0121';
    END IF;

    SELECT * INTO v_listing FROM public.forex_requests WHERE id = p_request_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'NIPANZE_FOREX_LISTING_NOT_FOUND' USING ERRCODE = 'P0120';
    END IF;
    IF v_listing.requester_id != p_requester_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Only the listing owner can accept an offer.'
            USING ERRCODE = 'P0121';
    END IF;
    IF v_listing.status != 'active' THEN
        RAISE EXCEPTION 'NIPANZE_FOREX_LISTING_NOT_ACTIVE' USING ERRCODE = 'P0122';
    END IF;

    SELECT * INTO v_offer FROM public.forex_offers
     WHERE id = p_offer_id AND request_id = p_request_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'NIPANZE_FOREX_OFFER_NOT_FOUND' USING ERRCODE = 'P0123';
    END IF;
    IF v_offer.status != 'pending' THEN
        RAISE EXCEPTION 'NIPANZE_FOREX_OFFER_NOT_PENDING: This offer is no longer available.'
            USING ERRCODE = 'P0124';
    END IF;

    SELECT * INTO v_requester   FROM public.profiles WHERE id = p_requester_id;
    SELECT * INTO v_offer_maker FROM public.profiles WHERE id = v_offer.offer_maker_id;

    v_snapshot := JSONB_BUILD_OBJECT(
        'request_id', p_request_id,
        'offer_id', p_offer_id,
        'requester_id', p_requester_id,
        'offer_maker_id', v_offer.offer_maker_id,
        'country', v_listing.country,
        'currency_held', v_listing.currency_held,
        'currency_needed', v_listing.currency_needed,
        'amount_agreed', v_offer.amount_available,
        'rate_agreed', v_offer.rate_offered,
        'settlement_terms', v_offer.terms,
        'legal_disclaimer', 'Nipanze provides this agreement for convenience only. The final exchange is solely between the two parties. Nipanze does not perform the exchange or hold currency.',
        'locked_at', NOW()
    );

    v_agreement_text := FORMAT(
'EXCHANGE AGREEMENT

PARTIES
Requester: %s
Offer-maker: %s

LOCKED TERMS
Currency held by requester: %s
Currency needed by requester: %s
Amount: %s %s
Rate agreed: %s
Settlement terms: %s

DISCLAIMER
Nipanze provides this agreement for convenience only. The final exchange is solely between
the two parties. Nipanze does not perform the exchange or hold currency.

Audit timestamp: %s',
        COALESCE(v_requester.full_name, 'Requester'),
        COALESCE(v_offer_maker.full_name, 'Offer-maker'),
        v_listing.currency_held,
        v_listing.currency_needed,
        v_listing.currency_held, v_offer.amount_available,
        v_offer.rate_offered,
        COALESCE(v_offer.terms, 'As agreed off-platform'),
        NOW()
    );

    UPDATE public.forex_offers SET status = 'accepted', accepted_at = NOW() WHERE id = p_offer_id;

    UPDATE public.forex_offers
       SET status = 'rejected', updated_at = NOW()
     WHERE request_id = p_request_id AND id != p_offer_id AND status = 'pending';

    UPDATE public.forex_requests
       SET status = 'contracted', contracted_at = NOW() WHERE id = p_request_id;

    INSERT INTO public.forex_agreements (
        offer_id, request_id, rate_agreed, amount_agreed, settlement_terms,
        agreement_text, agreement_snapshot, status,
        requester_agreed_at, offer_maker_agreed_at, locked_at
    )
    VALUES (
        p_offer_id, p_request_id, v_offer.rate_offered, v_offer.amount_available, v_offer.terms,
        v_agreement_text, v_snapshot, 'locked'::public.agreement_status_enum,
        NOW(), NOW(), NOW()
    )
    ON CONFLICT (offer_id) DO UPDATE
       SET rate_agreed = EXCLUDED.rate_agreed,
           amount_agreed = EXCLUDED.amount_agreed,
           agreement_text = EXCLUDED.agreement_text,
           agreement_snapshot = EXCLUDED.agreement_snapshot,
           status = 'locked'::public.agreement_status_enum,
           requester_agreed_at = COALESCE(public.forex_agreements.requester_agreed_at, NOW()),
           offer_maker_agreed_at = COALESCE(public.forex_agreements.offer_maker_agreed_at, NOW()),
           locked_at = COALESCE(public.forex_agreements.locked_at, NOW())
    RETURNING id INTO v_agreement_id;

    INSERT INTO public.notifications (user_id, type, title, body, forex_request_id, forex_offer_id)
    VALUES
        (p_requester_id, 'agreement_locked', 'Exchange agreement generated',
         'Your selected offer is locked into an exchange agreement. Unlock contact details to connect.',
         p_request_id, p_offer_id),
        (v_offer.offer_maker_id, 'agreement_locked', 'Exchange agreement generated',
         'Your offer was accepted and locked into an exchange agreement. Contact unlock is now available.',
         p_request_id, p_offer_id);

    INSERT INTO public.audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
    VALUES
        (p_requester_id, 'offer_accepted', 'forex_offers', p_offer_id, 'accept_forex_offer', v_snapshot),
        (p_requester_id, 'agreement_locked', 'forex_agreements', v_agreement_id, 'generate_locked_forex_agreement', v_snapshot);

    RETURN v_agreement_id;
END;
$$;

GRANT EXECUTE ON FUNCTION private.accept_forex_offer_internal(uuid, uuid, uuid, uuid) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.accept_forex_offer(
    p_request_id   UUID,
    p_offer_id     UUID,
    p_requester_id UUID
)
RETURNS UUID
LANGUAGE sql SECURITY INVOKER
SET search_path = public AS $$
    SELECT private.accept_forex_offer_internal(p_request_id, p_offer_id, p_requester_id, auth.uid());
$$;

REVOKE EXECUTE ON FUNCTION public.accept_forex_offer(uuid, uuid, uuid) FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.accept_forex_offer(uuid, uuid, uuid) TO authenticated, service_role;

COMMENT ON FUNCTION public.accept_forex_offer IS
'Atomically accepts a forex offer, rejects competing offers, marks the request contracted,
 and creates a locked forex_agreement. Mirrors accept_offer() for loans. Contact details are
 not exposed until unlock_forex_contact() is called.';


CREATE OR REPLACE FUNCTION private.unlock_forex_contact_internal(
    p_agreement_id UUID,
    p_caller_id    UUID
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$
DECLARE
    v_agreement       public.forex_agreements%ROWTYPE;
    v_offer           public.forex_offers%ROWTYPE;
    v_reveal          public.forex_contact_reveals%ROWTYPE;
    v_requester       public.profiles%ROWTYPE;
    v_offer_maker     public.profiles%ROWTYPE;
    v_requester_auth  RECORD;
    v_offer_maker_auth RECORD;
    v_requester_id    UUID;
    v_offer_maker_id  UUID;
    v_result          JSONB;
BEGIN
    SELECT * INTO v_agreement FROM public.forex_agreements WHERE id = p_agreement_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'NIPANZE_FOREX_AGREEMENT_NOT_FOUND' USING ERRCODE = 'P0141';
    END IF;

    IF v_agreement.status != 'locked' THEN
        RAISE EXCEPTION 'NIPANZE_FOREX_AGREEMENT_NOT_LOCKED: Agreement must be locked before unlocking contact.'
            USING ERRCODE = 'P0145';
    END IF;

    SELECT * INTO v_offer FROM public.forex_offers WHERE id = v_agreement.offer_id;
    SELECT requester_id INTO v_requester_id FROM public.forex_requests WHERE id = v_agreement.request_id;
    v_offer_maker_id := v_offer.offer_maker_id;

    IF p_caller_id != v_requester_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Only the request owner can unlock contact details.'
            USING ERRCODE = 'P0146';
    END IF;

    SELECT * INTO v_requester   FROM public.profiles WHERE id = v_requester_id;
    SELECT * INTO v_offer_maker FROM public.profiles WHERE id = v_offer_maker_id;

    SELECT email INTO v_requester_auth   FROM auth.users WHERE id = v_requester_id;
    SELECT email INTO v_offer_maker_auth FROM auth.users WHERE id = v_offer_maker_id;

    SELECT * INTO v_reveal FROM public.forex_contact_reveals WHERE offer_id = v_agreement.offer_id;
    IF v_reveal IS NULL THEN
        INSERT INTO public.forex_contact_reveals (offer_id, request_id, revealed_by, status, revealed_at)
        VALUES (v_agreement.offer_id, v_agreement.request_id, v_requester_id, 'revealed', NOW())
        RETURNING * INTO v_reveal;
    ELSE
        UPDATE public.forex_contact_reveals
           SET status = 'revealed', revealed_at = NOW()
         WHERE id = v_reveal.id;
        v_reveal.status := 'revealed';
        v_reveal.revealed_at := NOW();
    END IF;

    v_result := JSONB_BUILD_OBJECT(
        'agreement_id', v_agreement.id,
        'revealed_at', v_reveal.revealed_at,
        'requester', JSONB_BUILD_OBJECT(
            'full_name', v_requester.full_name, 'phone', v_requester.phone, 'email', v_requester_auth.email),
        'offer_maker', JSONB_BUILD_OBJECT(
            'full_name', v_offer_maker.full_name, 'phone', v_offer_maker.phone, 'email', v_offer_maker_auth.email)
    );

    INSERT INTO public.notifications (user_id, type, title, body, forex_request_id, forex_offer_id)
    VALUES
        (v_requester_id, 'contact_revealed', 'Contact details unlocked',
         'You can now connect with the offer-maker directly.', v_agreement.request_id, v_agreement.offer_id),
        (v_offer_maker_id, 'contact_revealed', 'Requester unlocked contact',
         'You can now connect with the requester directly.', v_agreement.request_id, v_agreement.offer_id);

    INSERT INTO public.audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
    VALUES (p_caller_id, 'contact_revealed', 'forex_contact_reveals', v_reveal.id, 'unlock_forex_contact',
        JSONB_BUILD_OBJECT('agreement_id', p_agreement_id, 'revealed_at', NOW()));

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION private.unlock_forex_contact_internal(uuid, uuid) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.unlock_forex_contact(p_agreement_id UUID)
RETURNS JSONB
LANGUAGE sql SECURITY INVOKER
SET search_path = public AS $$
    SELECT private.unlock_forex_contact_internal(p_agreement_id, auth.uid());
$$;

REVOKE EXECUTE ON FUNCTION public.unlock_forex_contact(uuid) FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.unlock_forex_contact(uuid) TO authenticated, service_role;

COMMENT ON FUNCTION public.unlock_forex_contact IS
'Requester unlocks contact details after a forex agreement is locked. Mirrors
 unlock_contact() for loans. Irreversible. Returns contact JSONB.';


-- ============================================
-- PART 8 — TRUST: make recompute_trust_aggregates() module-agnostic
-- (one row per user, combining loan + forex completed deals into a single
-- global aggregate — see BUILD_PLAN.md Trust & Reputation System v6.0)
-- ============================================

CREATE OR REPLACE FUNCTION public.recompute_trust_aggregates(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_rating NUMERIC(3,2);
    v_reviews INT;
    v_deals INT;
    v_response_hours NUMERIC;
    v_bucket TEXT;
    v_success_rate NUMERIC(5,2);
    v_score INT;
BEGIN
    -- Ratings/reviews: reviews.reviewee_id already covers both loan and forex
    -- rows (contract_id / forex_contract_id), no change needed here.
    SELECT ROUND(AVG(rating)::NUMERIC, 2), COUNT(*)
      INTO v_rating, v_reviews
      FROM reviews WHERE reviewee_id = p_user_id;

    -- Completed deals: loan contracts UNION forex contracts, one combined count.
    SELECT COUNT(*) INTO v_deals
    FROM (
        SELECT a.id FROM agreements a
        JOIN loan_offers lo ON lo.id = a.offer_id
        JOIN loan_requests lr ON lr.id = a.request_id
        JOIN contact_reveals cr ON cr.offer_id = lo.id AND cr.status = 'revealed'
        WHERE lr.borrower_id = p_user_id OR lo.lender_id = p_user_id

        UNION ALL

        SELECT fa.id FROM forex_agreements fa
        JOIN forex_offers fo ON fo.id = fa.offer_id
        JOIN forex_requests fr ON fr.id = fa.request_id
        JOIN forex_contact_reveals fcr ON fcr.offer_id = fo.id AND fcr.status = 'revealed'
        WHERE fr.requester_id = p_user_id OR fo.offer_maker_id = p_user_id
    ) combined_deals;

    -- Response time: loan offers/requests UNION forex offers/requests
    SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY response_hours)
      INTO v_response_hours
    FROM (
        SELECT EXTRACT(EPOCH FROM (lo.offered_at - lr.listed_at)) / 3600.0 AS response_hours
        FROM loan_offers lo JOIN loan_requests lr ON lr.id = lo.request_id
        WHERE lo.lender_id = p_user_id
        UNION ALL
        SELECT EXTRACT(EPOCH FROM (first_offer_at - lr.listed_at)) / 3600.0
        FROM loan_requests lr
        JOIN LATERAL (
            SELECT MIN(lo.offered_at) AS first_offer_at
            FROM loan_offers lo WHERE lo.request_id = lr.id
        ) first_offer ON first_offer.first_offer_at IS NOT NULL
        WHERE lr.borrower_id = p_user_id
        UNION ALL
        SELECT EXTRACT(EPOCH FROM (fo.offered_at - fr.listed_at)) / 3600.0
        FROM forex_offers fo JOIN forex_requests fr ON fr.id = fo.request_id
        WHERE fo.offer_maker_id = p_user_id
        UNION ALL
        SELECT EXTRACT(EPOCH FROM (first_fx_offer_at - fr.listed_at)) / 3600.0
        FROM forex_requests fr
        JOIN LATERAL (
            SELECT MIN(fo.offered_at) AS first_fx_offer_at
            FROM forex_offers fo WHERE fo.request_id = fr.id
        ) first_fx_offer ON first_fx_offer.first_fx_offer_at IS NOT NULL
        WHERE fr.requester_id = p_user_id
    ) response_times;

    v_bucket := CASE
        WHEN v_response_hours IS NULL THEN NULL
        WHEN v_response_hours <= 24 THEN 'responds_quickly'
        WHEN v_response_hours <= 72 THEN 'responds_within_a_day'
        ELSE 'responds_slowly'
    END;

    -- Success rate: loan offers/requests UNION forex offers/requests
    SELECT ROUND(
        100.0 * COUNT(*) FILTER (WHERE completed) / NULLIF(COUNT(*), 0), 2
    ) INTO v_success_rate
    FROM (
        SELECT lo.id, EXISTS (SELECT 1 FROM agreements a WHERE a.offer_id = lo.id) AS completed
        FROM loan_offers lo WHERE lo.lender_id = p_user_id
        UNION ALL
        SELECT lr.id, EXISTS (SELECT 1 FROM agreements a WHERE a.request_id = lr.id)
        FROM loan_requests lr WHERE lr.borrower_id = p_user_id
        UNION ALL
        SELECT fo.id, EXISTS (SELECT 1 FROM forex_agreements fa WHERE fa.offer_id = fo.id)
        FROM forex_offers fo WHERE fo.offer_maker_id = p_user_id
        UNION ALL
        SELECT fr.id, EXISTS (SELECT 1 FROM forex_agreements fa WHERE fa.request_id = fr.id)
        FROM forex_requests fr WHERE fr.requester_id = p_user_id
    ) participation;

    v_score := CASE WHEN v_rating IS NULL THEN NULL ELSE LEAST(100, ROUND(
        (v_rating / 5.0) * 60 + LEAST(v_deals, 4) * 5 +
        CASE v_bucket WHEN 'responds_quickly' THEN 20 WHEN 'responds_within_a_day' THEN 10 ELSE 0 END
    )::INT) END;

    INSERT INTO trust_aggregates (
        user_id, rating_avg, review_count, completed_deals_count,
        is_repeat_participant, response_time_bucket, success_rate, reliability_score, updated_at
    ) VALUES (
        p_user_id, v_rating, COALESCE(v_reviews, 0), COALESCE(v_deals, 0),
        COALESCE(v_deals, 0) >= 2, v_bucket, v_success_rate, v_score, NOW()
    ) ON CONFLICT (user_id) DO UPDATE SET
        rating_avg = EXCLUDED.rating_avg,
        review_count = EXCLUDED.review_count,
        completed_deals_count = EXCLUDED.completed_deals_count,
        is_repeat_participant = EXCLUDED.is_repeat_participant,
        response_time_bucket = EXCLUDED.response_time_bucket,
        success_rate = EXCLUDED.success_rate,
        reliability_score = EXCLUDED.reliability_score,
        updated_at = EXCLUDED.updated_at;
END;
$$;

COMMENT ON FUNCTION public.recompute_trust_aggregates IS
'v6.0: rebuilds a user''s GLOBAL trust aggregate from BOTH loan and forex on-platform
 events (never off-platform repayment/settlement behaviour). completed_deals_count,
 response_time_bucket, and success_rate all UNION across modules into one combined
 figure — there is no separate "forex score."';

-- submit_forex_review — mirrors submit_review() for forex-originated contracts
CREATE OR REPLACE FUNCTION public.submit_forex_review(
    p_contract_id UUID, p_rating SMALLINT, p_comment TEXT DEFAULT NULL
) RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    v_reviewer UUID := auth.uid();
    v_reviewee UUID;
    v_review_id UUID;
BEGIN
    IF v_reviewer IS NULL THEN RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED'; END IF;
    IF p_rating NOT BETWEEN 1 AND 5 THEN RAISE EXCEPTION 'NIPANZE_INVALID_RATING'; END IF;

    SELECT CASE WHEN fr.requester_id = v_reviewer THEN fo.offer_maker_id ELSE fr.requester_id END
      INTO v_reviewee
    FROM forex_agreements fa
    JOIN forex_offers fo ON fo.id = fa.offer_id
    JOIN forex_requests fr ON fr.id = fa.request_id
    JOIN forex_contact_reveals fcr ON fcr.offer_id = fo.id AND fcr.status = 'revealed'
    WHERE fa.id = p_contract_id
      AND (fr.requester_id = v_reviewer OR fo.offer_maker_id = v_reviewer);
    IF v_reviewee IS NULL THEN
        RAISE EXCEPTION 'NIPANZE_REVIEW_NOT_ELIGIBLE: Reviews require a completed on-platform forex deal.';
    END IF;

    INSERT INTO reviews (forex_contract_id, reviewer_id, reviewee_id, rating, comment)
    VALUES (p_contract_id, v_reviewer, v_reviewee, p_rating, NULLIF(BTRIM(p_comment), ''))
    RETURNING id INTO v_review_id;
    PERFORM recompute_trust_aggregates(v_reviewee);
    INSERT INTO audit_logs (user_id, event_type, entity_type, entity_id, action)
    VALUES (v_reviewer, 'review_submitted', 'reviews', v_review_id, 'submit_forex_review');
    RETURN v_review_id;
END;
$$;

COMMENT ON FUNCTION public.submit_forex_review IS
'Mirrors submit_review() for forex-originated contracts. Writes to reviews.forex_contract_id
 instead of reviews.contract_id; feeds the same trust_aggregates row as loan reviews.';

-- Trust refresh on forex contact reveal — mirrors trg_refresh_trust_from_reveal
CREATE OR REPLACE FUNCTION public.trg_refresh_trust_from_forex_reveal()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_requester UUID; v_offer_maker UUID;
BEGIN
    IF NEW.status = 'revealed' AND (TG_OP = 'INSERT' OR OLD.status IS DISTINCT FROM 'revealed') THEN
        SELECT fr.requester_id, fo.offer_maker_id INTO v_requester, v_offer_maker
        FROM forex_offers fo JOIN forex_requests fr ON fr.id = fo.request_id WHERE fo.id = NEW.offer_id;
        PERFORM recompute_trust_aggregates(v_requester);
        PERFORM recompute_trust_aggregates(v_offer_maker);
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_refresh_trust_on_forex_reveal ON forex_contact_reveals;
CREATE TRIGGER trg_refresh_trust_on_forex_reveal
AFTER INSERT OR UPDATE OF status ON forex_contact_reveals
FOR EACH ROW EXECUTE FUNCTION trg_refresh_trust_from_forex_reveal();


-- ============================================
-- PART 9 — ROW-LEVEL SECURITY (new tables)
-- ============================================

ALTER TABLE currencies             ENABLE ROW LEVEL SECURITY;
ALTER TABLE forex_requests         ENABLE ROW LEVEL SECURITY;
ALTER TABLE forex_offers           ENABLE ROW LEVEL SECURITY;
ALTER TABLE forex_agreements       ENABLE ROW LEVEL SECURITY;
ALTER TABLE forex_contact_reveals  ENABLE ROW LEVEL SECURITY;

-- currencies — public reference data, admin-only writes
DROP POLICY IF EXISTS "currencies: public read" ON currencies;
CREATE POLICY "currencies: public read"
    ON currencies FOR SELECT TO authenticated, anon USING (TRUE);
DROP POLICY IF EXISTS "currencies: admin write" ON currencies;
CREATE POLICY "currencies: admin write"
    ON currencies FOR ALL TO authenticated USING (private.is_admin());

-- forex_requests — mirrors "loan_requests: ..." policies (global browse)
DROP POLICY IF EXISTS "forex_requests: marketplace read" ON forex_requests;
CREATE POLICY "forex_requests: marketplace read"
    ON forex_requests FOR SELECT TO authenticated
    USING (status = 'active' OR requester_id = auth.uid() OR private.is_admin());
DROP POLICY IF EXISTS "forex_requests: own insert" ON forex_requests;
CREATE POLICY "forex_requests: own insert"
    ON forex_requests FOR INSERT TO authenticated
    WITH CHECK (requester_id = auth.uid());
DROP POLICY IF EXISTS "forex_requests: own or admin update" ON forex_requests;
CREATE POLICY "forex_requests: own or admin update"
    ON forex_requests FOR UPDATE TO authenticated
    USING (requester_id = auth.uid() OR private.is_admin());
DROP POLICY IF EXISTS "forex_requests: admin delete" ON forex_requests;
CREATE POLICY "forex_requests: admin delete"
    ON forex_requests FOR DELETE TO authenticated USING (private.is_admin());

-- forex_offers — mirrors "loan_offers: ..." policies
DROP POLICY IF EXISTS "forex_offers: relevant parties read" ON forex_offers;
CREATE POLICY "forex_offers: relevant parties read"
    ON forex_offers FOR SELECT TO authenticated
    USING (
        offer_maker_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM forex_requests fr
             WHERE fr.id = forex_offers.request_id AND fr.requester_id = auth.uid()
        )
        OR private.is_admin()
    );
DROP POLICY IF EXISTS "forex_offers: offer_maker insert" ON forex_offers;
CREATE POLICY "forex_offers: offer_maker insert"
    ON forex_offers FOR INSERT TO authenticated
    WITH CHECK (offer_maker_id = auth.uid());
DROP POLICY IF EXISTS "forex_offers: offer_maker withdraw or admin" ON forex_offers;
CREATE POLICY "forex_offers: offer_maker withdraw or admin"
    ON forex_offers FOR UPDATE TO authenticated
    USING ((offer_maker_id = auth.uid() AND status = 'pending') OR private.is_admin());

-- forex_agreements — mirrors "agreements: ..." policies
DROP POLICY IF EXISTS "forex_agreements: matched parties read" ON forex_agreements;
CREATE POLICY "forex_agreements: matched parties read"
    ON forex_agreements FOR SELECT TO authenticated
    USING (
        EXISTS (SELECT 1 FROM forex_requests fr WHERE fr.id = forex_agreements.request_id AND fr.requester_id = auth.uid())
        OR EXISTS (SELECT 1 FROM forex_offers fo WHERE fo.id = forex_agreements.offer_id AND fo.offer_maker_id = auth.uid())
        OR private.is_admin()
    );
DROP POLICY IF EXISTS "forex_agreements: service role insert" ON forex_agreements;
CREATE POLICY "forex_agreements: service role insert"
    ON forex_agreements FOR INSERT TO service_role WITH CHECK (TRUE);
DROP POLICY IF EXISTS "forex_agreements: service role update" ON forex_agreements;
CREATE POLICY "forex_agreements: service role update"
    ON forex_agreements FOR UPDATE TO service_role USING (TRUE) WITH CHECK (TRUE);
DROP POLICY IF EXISTS "forex_agreements: admin all" ON forex_agreements;
CREATE POLICY "forex_agreements: admin all"
    ON forex_agreements FOR ALL TO authenticated USING (private.is_admin());

-- forex_contact_reveals — mirrors "contact_reveals: ..." policies
DROP POLICY IF EXISTS "forex_contact_reveals: matched parties read" ON forex_contact_reveals;
CREATE POLICY "forex_contact_reveals: matched parties read"
    ON forex_contact_reveals FOR SELECT TO authenticated
    USING (
        revealed_by = auth.uid()
        OR EXISTS (SELECT 1 FROM forex_offers fo WHERE fo.id = forex_contact_reveals.offer_id AND fo.offer_maker_id = auth.uid())
        OR private.is_admin()
    );
DROP POLICY IF EXISTS "forex_contact_reveals: own insert" ON forex_contact_reveals;
CREATE POLICY "forex_contact_reveals: own insert"
    ON forex_contact_reveals FOR INSERT TO authenticated
    WITH CHECK (revealed_by = auth.uid());
DROP POLICY IF EXISTS "forex_contact_reveals: admin write" ON forex_contact_reveals;
CREATE POLICY "forex_contact_reveals: admin write"
    ON forex_contact_reveals FOR ALL TO authenticated USING (private.is_admin());


-- ============================================
-- PART 10 — REALTIME PUBLICATION
-- ============================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = 'forex_requests'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE forex_requests;
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = 'forex_offers'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE forex_offers;
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = 'forex_agreements'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE forex_agreements;
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = 'forex_contact_reveals'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE forex_contact_reveals;
    END IF;
END $$;


-- ============================================
-- PART 11 — GRANTS
-- ============================================

GRANT SELECT ON currencies         TO authenticated, anon;
GRANT SELECT ON v_forex_listings   TO authenticated, anon;
GRANT SELECT ON v_forex_offers     TO authenticated, anon;

GRANT EXECUTE ON FUNCTION get_public_forex_offers(UUID)                 TO authenticated;
REVOKE EXECUTE ON FUNCTION get_public_forex_offers(UUID) FROM anon;

REVOKE EXECUTE ON FUNCTION public.accept_forex_offer(uuid, uuid, uuid) FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.accept_forex_offer(uuid, uuid, uuid) TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.unlock_forex_contact(uuid) FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.unlock_forex_contact(uuid) TO authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.submit_forex_review(UUID, SMALLINT, TEXT) TO authenticated;

-- Blanket grants for the new tables, matching the blanket grants already
-- present at the end of the v5.0 schema for existing tables.
GRANT SELECT, INSERT, UPDATE, DELETE ON forex_requests, forex_offers, forex_agreements, forex_contact_reveals, currencies
    TO authenticated, service_role;
GRANT SELECT, INSERT, UPDATE ON forex_requests, forex_offers
    TO anon;


-- ============================================
-- PART 12 — DATABASE COMMENT (bump version marker)
-- ============================================

DO $$
DECLARE db TEXT;
BEGIN
    SELECT current_database() INTO db;
    EXECUTE FORMAT('COMMENT ON DATABASE %I IS %L', db,
        'Nipanze v6.0 — Non-custodial Loans + Forex matchmaking marketplace across a 7-market '
        'expansion list (UG live, KE/TZ/RW/NG/ZA/EG planned), Uganda-first. Two feature-modules '
        '(Loans, Forex) on one shared schema, auth, subscription_plan, trust system, and '
        'selective-transparency machinery. Country is explicit, indexed, and locked at creation '
        'for both loan and forex listings; trust signals are global across every market AND both '
        'modules. Posting is free on either module. Making offers requires a Lender/Pro '
        'subscription. Contact revealed only after offer acceptance. Platform never holds, '
        'converts, or tracks funds or currency between matched users, in any market, on either module.');
END $$;


-- ============================================
-- END OF PATCH v5.0 → v6.0
--
-- Post-run sanity checks you may want to run:
--   SELECT code, name, is_active, forex_enabled FROM countries ORDER BY code;
--   SELECT code, forex_trading_enabled FROM currencies ORDER BY code;
--   SELECT * FROM v_forex_listings LIMIT 5;
--   SELECT proname FROM pg_proc WHERE proname LIKE '%forex%' ORDER BY proname;
--
-- Still open / not in this patch (flagged in BUILD_PLAN.md, not schema work):
--   - system_settings per-country overrides for min/max amounts etc. (insert
--     rows with country set as each market approaches its own Stage 6 launch)
--   - Flutter app layer: ForexCreatePage, ForexDetailPage, SendRateReceivePanel,
--     MyForexRequestsPage, marketplace All/Loans/Forex filter row
--   - Flipping any country.is_active / countries.forex_enabled / any
--     currencies.forex_trading_enabled to TRUE — all default FALSE, on purpose,
--     pending each market/currency's own compliance review per BUILD_PLAN.md
-- ============================================

-- ============================================================
-- END MERGED SECTION: patch_schema_v6.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_seed_v6.sql
-- ============================================================

-- ============================================
-- NIPANZE — Patch v6.1: backfill missing profile text values
-- Paste into Supabase Cloud SQL Editor and run once. Idempotent.
--
-- What this fixes:
--   1. profiles.district = NULL for any real (non-seed) sign-up — the
--      on_auth_user_created trigger never set it, so onboarding "district"
--      never had a value. Backfilled to a sensible per-country default
--      (matches the seed script's own choice of city per market) and only
--      touches rows that are currently NULL — never overwrites a value a
--      user actually entered.
--   2. profiles.income_currency silently wrong for real sign-ups — the
--      column default is 'UGX', and handle_new_auth_user() never set it,
--      so e.g. a Kenya sign-up got 'UGX' instead of 'KES'. Backfilled from
--      countries.currency_code for any row that doesn't already match its
--      own country's currency.
--   3. Root cause fixed: handle_new_auth_user() now sets income_currency
--      from countries.currency_code at insert time, so future sign-ups
--      never hit this again. district is intentionally left for the user
--      to fill in during onboarding (no good default at signup time,
--      before they've picked a district) — only backfilled here for the
--      rows that already exist without one.
-- ============================================


-- 1. Backfill district for any profile currently NULL, using the same
-- per-market default city the seed script already uses for that country.
-- Only touches NULL rows — never overwrites a real user-entered value.
UPDATE profiles p
SET district = CASE p.country
    WHEN 'UG' THEN 'Central'
    WHEN 'KE' THEN 'Nairobi'
    WHEN 'TZ' THEN 'Dar es Salaam'
    WHEN 'RW' THEN 'Kigali'
    WHEN 'BI' THEN 'Bujumbura'
    WHEN 'SS' THEN 'Juba'
    WHEN 'CD' THEN 'Kinshasa'
    WHEN 'SO' THEN 'Mogadishu'
    WHEN 'NG' THEN 'Lagos'
    WHEN 'ZA' THEN 'Johannesburg'
    WHEN 'EG' THEN 'Cairo'
    ELSE p.district
END
WHERE p.district IS NULL;

-- 2. Backfill income_currency for any profile whose value doesn't match
-- its own country's currency (covers both NULL and the silently-wrong
-- 'UGX' default from real sign-ups outside Uganda).
UPDATE profiles p
SET income_currency = c.currency_code
FROM countries c
WHERE p.country = c.code
  AND (p.income_currency IS NULL OR p.income_currency <> c.currency_code);

-- 3. Fix the root cause: handle_new_auth_user() now resolves and sets
-- income_currency from countries.currency_code, exactly the same way it
-- already resolves country. Everything else in the function is unchanged.
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_country TEXT;
    v_currency TEXT;
BEGIN
    v_country := UPPER(COALESCE(NEW.raw_user_meta_data->>'country_code', 'UG'));
    IF NOT EXISTS (SELECT 1 FROM public.countries WHERE code = v_country) THEN
        v_country := 'UG';
    END IF;

    SELECT currency_code INTO v_currency FROM public.countries WHERE code = v_country;
    v_currency := COALESCE(v_currency, 'UGX');

    INSERT INTO public.profiles (
        id, full_name, account_status, is_admin, country, income_currency
    )
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', SPLIT_PART(NEW.email, '@', 1)),
        'pending_verification',
        FALSE,
        v_country,
        v_currency
    )
    ON CONFLICT (id) DO NOTHING;

    -- Every new user gets a free subscription (can browse marketplace and post requests)
    INSERT INTO public.subscriptions (user_id, plan, status, amount_minor_units)
    VALUES (NEW.id, 'free', 'active', 0)
    ON CONFLICT (user_id) WHERE status = 'active' DO NOTHING;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.handle_new_auth_user IS
'v6.1: now also resolves income_currency from countries.currency_code at signup (previously
 left at the column default of UGX regardless of the new user''s country). Syncs auth.users →
 public.profiles on every registration, resolves the new profile''s country (defaulting to UG
 if the onboarding suggestion is missing or unrecognized), and provisions a free subscription.';


-- ============================================
-- Post-run sanity check:
--   SELECT id, full_name, country, district, income_currency FROM profiles
--   WHERE id::text NOT LIKE '10000000%' ORDER BY created_at;
-- Should show every non-seed profile with a non-null district and an
-- income_currency matching its own country's currency.
-- ============================================

-- ============================================================
-- END MERGED SECTION: patch_seed_v6.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_seed_forex.sql
-- ============================================================

-- ============================================
-- NIPANZE — Patch v6.2: Forex seed data
-- Paste into Supabase Cloud SQL Editor and run once. Idempotent.
--
-- The v6.0 schema patch (the Patch v6 Schema section in this file) added the Forex module tables, but
-- sql/seed.sql predates it and has no forex data at all — every currency
-- still has forex_trading_enabled = FALSE and no market has
-- countries.forex_enabled = TRUE, so v_forex_listings is empty and there's
-- nothing to develop or demo against.
--
-- This patch:
--   1. Enables forex for Uganda (countries.forex_enabled) and clears UGX/KES
--      for trading (currencies.forex_trading_enabled) — the minimum needed
--      for a UGX → KES demo pair, matching "Uganda can go live for forex
--      independently of other markets" from BUILD_PLAN.md.
--   2. Adds the two forex-specific test accounts named in BUILD_PLAN.md's
--      Test Accounts table: mutesi.grace@gmail.com (UG, Lender) and
--      nonparticipant.tester@gmail.com (UG, Free).
--   3. Seeds one ACTIVE UGX → KES forex_request (mutesi.grace) with two
--      pending offers from existing UG lenders — for selective-transparency
--      testing (participant vs non-participant view).
--   4. Seeds one CONTRACTED forex_request+offer+agreement+contact_reveal+
--      review — for trust-aggregate testing (confirms a forex deal feeds
--      the SAME global trust_aggregates row as a loan deal would).
--   5. Recomputes trust_aggregates for every user touched, since the
--      contracted flow is inserted with triggers bypassed (session_replication_role
--      = replica), the same pattern sql/seed.sql already uses for loan
--      agreements/contact_reveals.
--
-- Safe to re-run: every INSERT is ON CONFLICT DO NOTHING; the UPDATEs in
-- step 1 are idempotent by nature.
-- ============================================


-- ============================================
-- STEP 1 — Clear Uganda + UGX/KES for forex (minimum viable demo pair)
-- ============================================

UPDATE countries SET forex_enabled = TRUE WHERE code = 'UG';

UPDATE currencies SET forex_trading_enabled = TRUE WHERE code IN ('UGX', 'KES');

-- Sanity: SELECT code, forex_enabled FROM countries WHERE code = 'UG';
--         SELECT code, forex_trading_enabled FROM currencies WHERE code IN ('UGX','KES');


-- ============================================
-- STEP 2 — Forex-specific test accounts (per BUILD_PLAN.md Test Accounts)
-- ============================================

INSERT INTO auth.users (
    id, instance_id, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    is_super_admin, role, aud,
    confirmation_token, recovery_token,
    email_change_token_new, email_change,
    email_change_token_current, phone_change,
    phone_change_token, reauthentication_token
) VALUES
('10000000-0000-0000-0000-000000000137', '00000000-0000-0000-0000-000000000000', 'mutesi.grace@gmail.com', crypt('Test1234!', gen_salt('bf')),
 NOW(), '2026-03-01 09:00:00', '2026-03-01 09:00:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Mutesi Grace","country_code":"UG"}',
 FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', ''),
('10000000-0000-0000-0000-000000000138', '00000000-0000-0000-0000-000000000000', 'nonparticipant.tester@gmail.com', crypt('Test1234!', gen_salt('bf')),
 NOW(), '2026-03-01 09:05:00', '2026-03-01 09:05:00', '{"provider":"email","providers":["email"]}', '{"full_name":"Nonparticipant Tester","country_code":"UG"}',
 FALSE, 'authenticated', 'authenticated', '', '', '', '', '', '', '', '')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (
    id, full_name, phone, district, country, employment_type, employer_name,
    monthly_income, income_currency, phone_verified_at, account_status, is_admin, created_at
) VALUES
('10000000-0000-0000-0000-000000000137', 'Mutesi Grace', '+256722334455', 'Central', 'UG', 'small_business_owner', 'Grace Forex Traders', 3800000, 'UGX', '2026-03-01 09:10:00', 'active', FALSE, '2026-03-01 09:00:00'),
('10000000-0000-0000-0000-000000000138', 'Nonparticipant Tester', '+256722556677', 'Central', 'UG', 'employed', 'Local Employer Ltd', 2600000, 'UGX', NULL, 'active', FALSE, '2026-03-01 09:05:00')
ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name, phone = EXCLUDED.phone, district = EXCLUDED.district,
    country = EXCLUDED.country, employment_type = EXCLUDED.employment_type,
    employer_name = EXCLUDED.employer_name, monthly_income = EXCLUDED.monthly_income,
    income_currency = EXCLUDED.income_currency, phone_verified_at = EXCLUDED.phone_verified_at,
    account_status = EXCLUDED.account_status;

INSERT INTO public.subscriptions (user_id, plan, status, amount_minor_units, started_at, expires_at, auto_renew) VALUES
('10000000-0000-0000-0000-000000000137', 'lender', 'active', 35000, '2026-03-01 09:00:00', '2028-03-01 09:00:00', TRUE),
('10000000-0000-0000-0000-000000000138', 'free',   'active', 0,     '2026-03-01 09:05:00', NULL, TRUE)
ON CONFLICT (user_id) DO UPDATE SET
    plan = EXCLUDED.plan, status = EXCLUDED.status, amount_minor_units = EXCLUDED.amount_minor_units,
    started_at = EXCLUDED.started_at, expires_at = EXCLUDED.expires_at, auto_renew = EXCLUDED.auto_renew;


-- ============================================
-- STEP 3 — Forex listings, offers, agreement, reveal, review
-- Triggers bypassed (session_replication_role = replica) for the same
-- reason sql/seed.sql already bypasses them on loan_requests/loan_offers/
-- agreements: seed timestamps and pre-computed snapshot data don't need to
-- re-run the same server-side validation that already ran for real traffic.
-- ============================================

SET session_replication_role = 'replica';

-- 3-pre. Additional ACTIVE UGX → KES listings (appear BEFORE the primary
-- demo listings so the Forex tab is populated with a realistic feed)

INSERT INTO forex_requests (
    id, requester_id, country, currency_held, currency_needed, amount,
    preferred_rate, settlement_preference, is_urgent, terms_locked_at,
    number_of_offers, status, listed_at, expires_at, created_at
) VALUES
-- Listing A: small urgent transfer
('c3000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000008', 'UG',
 'UGX', 'KES', 500000, 0.0285, 'Mobile money (Airtel Money), Kampala', TRUE,
 NOW() - INTERVAL '1 hour', 1, 'active', NOW() - INTERVAL '1 hour', NOW() + INTERVAL '6 days',
 NOW() - INTERVAL '1 hour'),
-- Listing B: mid-range in-person exchange
('c3000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000009', 'UG',
 'UGX', 'KES', 1200000, NULL, 'In-person exchange, Kampala CBD', FALSE,
 NOW() - INTERVAL '5 hours', 0, 'active', NOW() - INTERVAL '5 hours', NOW() + INTERVAL '7 days',
 NOW() - INTERVAL '5 hours'),
-- Listing C: larger bank-transfer exchange
('c3000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000010', 'UG',
 'UGX', 'KES', 3500000, 0.0291, 'Bank transfer (Equity Bank)', FALSE,
 NOW() - INTERVAL '18 hours', 2, 'active', NOW() - INTERVAL '18 hours', NOW() + INTERVAL '4 days',
 NOW() - INTERVAL '18 hours')
ON CONFLICT (id) DO NOTHING;

INSERT INTO forex_offers (
    id, request_id, offer_maker_id, rate_offered, amount_available, terms,
    terms_locked_at, status, offered_at, created_at
) VALUES
-- Offer on Listing A
('d3000000-0000-0000-0000-000000000010', 'c3000000-0000-0000-0000-000000000003',
 '10000000-0000-0000-0000-000000000011', 0.0284, 500000, 'Can settle via Airtel Money same day.',
 NOW() - INTERVAL '30 minutes', 'pending', NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '30 minutes'),
-- Offer 1 on Listing C
('d3000000-0000-0000-0000-000000000011', 'c3000000-0000-0000-0000-000000000005',
 '10000000-0000-0000-0000-000000000012', 0.0290, 3500000, 'Bank transfer within 48 hours, Equity Bank.',
 NOW() - INTERVAL '12 hours', 'pending', NOW() - INTERVAL '12 hours', NOW() - INTERVAL '12 hours'),
-- Offer 2 on Listing C
('d3000000-0000-0000-0000-000000000012', 'c3000000-0000-0000-0000-000000000005',
 '10000000-0000-0000-0000-000000000013', 0.0292, 3000000, 'Partial amount OK; bank transfer within 2 days.',
 NOW() - INTERVAL '8 hours', 'pending', NOW() - INTERVAL '8 hours', NOW() - INTERVAL '8 hours')
ON CONFLICT (id) DO NOTHING;

-- 3a. ACTIVE listing — two pending offers, for selective-transparency testing
INSERT INTO forex_requests (
    id, requester_id, country, currency_held, currency_needed, amount,
    preferred_rate, settlement_preference, is_urgent, terms_locked_at,
    number_of_offers, status, listed_at, expires_at, created_at
) VALUES
('c3000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000137', 'UG',
 'UGX', 'KES', 2000000, NULL, 'Mobile money (MTN MoMo), Kampala', FALSE,
 NOW() - INTERVAL '2 days', 2, 'active', NOW() - INTERVAL '2 days', NOW() + INTERVAL '5 days',
 NOW() - INTERVAL '2 days')
ON CONFLICT (id) DO NOTHING;

INSERT INTO forex_offers (
    id, request_id, offer_maker_id, rate_offered, amount_available, terms,
    terms_locked_at, status, offered_at, created_at
) VALUES
('d3000000-0000-0000-0000-000000000001', 'c3000000-0000-0000-0000-000000000001',
 '10000000-0000-0000-0000-000000000008', 0.0286, 2000000, 'Can settle via bank transfer within 24 hours.',
 NOW() - INTERVAL '1 day 12 hours', 'pending', NOW() - INTERVAL '1 day 12 hours', NOW() - INTERVAL '1 day 12 hours'),
('d3000000-0000-0000-0000-000000000002', 'c3000000-0000-0000-0000-000000000001',
 '10000000-0000-0000-0000-000000000009', 0.0290, 1500000, 'Prefer mobile money settlement, can do partial amount.',
 NOW() - INTERVAL '20 hours', 'pending', NOW() - INTERVAL '20 hours', NOW() - INTERVAL '20 hours')
ON CONFLICT (id) DO NOTHING;

-- 3b. CONTRACTED listing — accepted offer, locked agreement, revealed
-- contact, one review — for global trust-aggregate testing
INSERT INTO forex_requests (
    id, requester_id, country, currency_held, currency_needed, amount,
    preferred_rate, settlement_preference, is_urgent, terms_locked_at,
    number_of_offers, status, listed_at, expires_at, contracted_at, created_at
) VALUES
('c3000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000137', 'UG',
 'UGX', 'KES', 900000, NULL, 'In-person exchange, Kampala city centre', FALSE,
 NOW() - INTERVAL '10 days', 1, 'contracted', NOW() - INTERVAL '10 days', NOW() - INTERVAL '3 days',
 NOW() - INTERVAL '7 days', NOW() - INTERVAL '10 days')
ON CONFLICT (id) DO NOTHING;

INSERT INTO forex_offers (
    id, request_id, offer_maker_id, rate_offered, amount_available, terms,
    terms_locked_at, status, offered_at, accepted_at, created_at
) VALUES
('d3000000-0000-0000-0000-000000000003', 'c3000000-0000-0000-0000-000000000002',
 '10000000-0000-0000-0000-000000000010', 0.0288, 900000, 'Can meet in person same week.',
 NOW() - INTERVAL '9 days', 'accepted', NOW() - INTERVAL '9 days', NOW() - INTERVAL '7 days', NOW() - INTERVAL '9 days')
ON CONFLICT (id) DO NOTHING;

INSERT INTO forex_agreements (
    id, offer_id, request_id, rate_agreed, amount_agreed, settlement_terms,
    agreement_text, agreement_snapshot, status,
    requester_agreed_at, offer_maker_agreed_at, locked_at
) VALUES
('b1000000-0000-0000-0000-000000000001', 'd3000000-0000-0000-0000-000000000003', 'c3000000-0000-0000-0000-000000000002',
 0.0288, 900000, 'In-person exchange, Kampala city centre',
 'EXCHANGE AGREEMENT between Mutesi Grace and George Mulindwa. UGX 900,000 at rate 0.0288 (UGX -> KES). Settlement: in-person exchange, Kampala city centre.',
 '{"request_id":"c3000000-0000-0000-0000-000000000002","offer_id":"d3000000-0000-0000-0000-000000000003","requester_id":"10000000-0000-0000-0000-000000000137","offer_maker_id":"10000000-0000-0000-0000-000000000010","country":"UG","currency_held":"UGX","currency_needed":"KES","amount_agreed":900000,"rate_agreed":0.0288,"settlement_terms":"In-person exchange, Kampala city centre"}'::jsonb,
 'locked'::agreement_status_enum, NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days')
ON CONFLICT (offer_id) DO NOTHING;

INSERT INTO forex_contact_reveals (id, offer_id, request_id, revealed_by, status, revealed_at, created_at) VALUES
('f2000000-0000-0000-0000-000000000001', 'd3000000-0000-0000-0000-000000000003', 'c3000000-0000-0000-0000-000000000002',
 '10000000-0000-0000-0000-000000000137', 'revealed', NOW() - INTERVAL '6 days', NOW() - INTERVAL '7 days')
ON CONFLICT (offer_id) DO NOTHING;

INSERT INTO reviews (id, forex_contract_id, reviewer_id, reviewee_id, rating, comment, created_at) VALUES
('e6000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001',
 '10000000-0000-0000-0000-000000000137', '10000000-0000-0000-0000-000000000010', 5,
 'Smooth exchange, met on time and rate was exactly as agreed.', NOW() - INTERVAL '5 days')
ON CONFLICT (forex_contract_id, reviewer_id) WHERE forex_contract_id IS NOT NULL DO NOTHING;

SET session_replication_role = 'origin';


-- ============================================
-- STEP 4 — Watchlist + notifications (small, realistic touch)
-- ============================================

INSERT INTO watchlist (id, user_id, forex_request_id, added_at) VALUES
('e8000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000138', 'c3000000-0000-0000-0000-000000000001', NOW() - INTERVAL '1 day')
ON CONFLICT (user_id, forex_request_id) WHERE forex_request_id IS NOT NULL DO NOTHING;

INSERT INTO notifications (id, user_id, type, title, body, is_read, forex_request_id, forex_offer_id, created_at) VALUES
('e7000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000137', 'offer_received', 'New forex offer received',
 'William Kasujja made an offer on your UGX → KES exchange request.', FALSE,
 'c3000000-0000-0000-0000-000000000001', 'd3000000-0000-0000-0000-000000000001', NOW() - INTERVAL '1 day 12 hours'),
('e7000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000137', 'offer_received', 'New forex offer received',
 'Catherine Namboze made an offer on your UGX → KES exchange request.', FALSE,
 'c3000000-0000-0000-0000-000000000001', 'd3000000-0000-0000-0000-000000000002', NOW() - INTERVAL '20 hours'),
('e7000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000137', 'contact_revealed', 'Contact details unlocked',
 'You can now connect with George Mulindwa directly.', TRUE,
 'c3000000-0000-0000-0000-000000000002', 'd3000000-0000-0000-0000-000000000003', NOW() - INTERVAL '6 days'),
('e7000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000010', 'contact_revealed', 'Requester unlocked contact',
 'You can now connect with the requester directly.', TRUE,
 'c3000000-0000-0000-0000-000000000002', 'd3000000-0000-0000-0000-000000000003', NOW() - INTERVAL '6 days')
ON CONFLICT DO NOTHING;


-- ============================================
-- STEP 5 — Recompute trust aggregates for every user touched
-- (triggers were bypassed in Step 3, so this does what
-- trg_refresh_trust_on_forex_reveal would normally have done automatically)
-- ============================================

SELECT public.recompute_trust_aggregates('10000000-0000-0000-0000-000000000137'); -- Mutesi Grace
SELECT public.recompute_trust_aggregates('10000000-0000-0000-0000-000000000010'); -- George Mulindwa


-- ============================================
-- VERIFICATION
-- ============================================

SELECT '✅ Forex seed v6.2 inserted — UG+forex_enabled, UGX/KES tradeable, 2 test accounts, 1 active listing (2 pending offers), 1 contracted listing (agreement+reveal+review)' AS status;

SELECT request_id, currency_held, currency_needed, amount, country, status, number_of_offers, rate_coverage_tier
FROM v_forex_listings
ORDER BY listed_at DESC;

SELECT ta.user_id, p.full_name, ta.rating_avg, ta.review_count, ta.completed_deals_count, ta.is_repeat_participant
FROM trust_aggregates ta
JOIN profiles p ON p.id = ta.user_id
WHERE ta.user_id IN (
    '10000000-0000-0000-0000-000000000137',
    '10000000-0000-0000-0000-000000000010'
);

-- ============================================================
-- END MERGED SECTION: patch_seed_forex.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_seed_forex2.sql
-- ============================================================

-- ============================================
-- NIPANZE — Patch v6.3: Extra UGX → KES forex listings
-- Paste into Supabase Cloud SQL Editor and run once. Idempotent.
--
-- Prerequisite: the Forex Seed Data v6.2 section in this file must already be applied.
--
-- Adds 3 more ACTIVE UGX → KES forex_requests with varied amounts,
-- settlement methods, and offer counts — so the Forex tab shows a
-- realistic populated feed matching the marketplace mockup.
--
-- Safe to re-run: every INSERT is ON CONFLICT DO NOTHING.
-- ============================================


SET session_replication_role = 'replica';

-- ── forex_requests ───────────────────────────────────────────────────────────

INSERT INTO forex_requests (
    id, requester_id, country, currency_held, currency_needed, amount,
    preferred_rate, settlement_preference, is_urgent, terms_locked_at,
    number_of_offers, status, listed_at, expires_at, created_at
) VALUES
-- Listing A: small urgent Airtel Money transfer
('c3000000-0000-0000-0000-000000000003',
 '10000000-0000-0000-0000-000000000008', 'UG',
 'UGX', 'KES', 500000, 0.0285,
 'Mobile money (Airtel Money), Kampala', TRUE,
 NOW() - INTERVAL '1 hour', 1, 'active',
 NOW() - INTERVAL '1 hour', NOW() + INTERVAL '6 days',
 NOW() - INTERVAL '1 hour'),

-- Listing B: mid-range in-person exchange, no offers yet
('c3000000-0000-0000-0000-000000000004',
 '10000000-0000-0000-0000-000000000009', 'UG',
 'UGX', 'KES', 1200000, NULL,
 'In-person exchange, Kampala CBD', FALSE,
 NOW() - INTERVAL '5 hours', 0, 'active',
 NOW() - INTERVAL '5 hours', NOW() + INTERVAL '7 days',
 NOW() - INTERVAL '5 hours'),

-- Listing C: larger bank-transfer exchange with 2 offers
('c3000000-0000-0000-0000-000000000005',
 '10000000-0000-0000-0000-000000000010', 'UG',
 'UGX', 'KES', 3500000, 0.0291,
 'Bank transfer (Equity Bank)', FALSE,
 NOW() - INTERVAL '18 hours', 2, 'active',
 NOW() - INTERVAL '18 hours', NOW() + INTERVAL '4 days',
 NOW() - INTERVAL '18 hours')
ON CONFLICT (id) DO NOTHING;

-- ── forex_offers ─────────────────────────────────────────────────────────────

INSERT INTO forex_offers (
    id, request_id, offer_maker_id, rate_offered, amount_available, terms,
    terms_locked_at, status, offered_at, created_at
) VALUES
-- Offer on Listing A
('d3000000-0000-0000-0000-000000000010',
 'c3000000-0000-0000-0000-000000000003',
 '10000000-0000-0000-0000-000000000011',
 0.0284, 500000, 'Can settle via Airtel Money same day.',
 NOW() - INTERVAL '30 minutes', 'pending',
 NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '30 minutes'),

-- Offer 1 on Listing C
('d3000000-0000-0000-0000-000000000011',
 'c3000000-0000-0000-0000-000000000005',
 '10000000-0000-0000-0000-000000000012',
 0.0290, 3500000, 'Bank transfer within 48 hours, Equity Bank.',
 NOW() - INTERVAL '12 hours', 'pending',
 NOW() - INTERVAL '12 hours', NOW() - INTERVAL '12 hours'),

-- Offer 2 on Listing C
('d3000000-0000-0000-0000-000000000012',
 'c3000000-0000-0000-0000-000000000005',
 '10000000-0000-0000-0000-000000000013',
 0.0292, 3000000, 'Partial amount OK; bank transfer within 2 days.',
 NOW() - INTERVAL '8 hours', 'pending',
 NOW() - INTERVAL '8 hours', NOW() - INTERVAL '8 hours')
ON CONFLICT (id) DO NOTHING;

SET session_replication_role = 'origin';


-- ── VERIFICATION ─────────────────────────────────────────────────────────────

SELECT '✅ Forex seed v6.3 inserted — 3 extra UGX→KES active listings' AS status;

SELECT request_id, currency_held, currency_needed, amount,
       settlement_preference, status, number_of_offers, listed_at
FROM v_forex_listings
ORDER BY listed_at DESC;

-- ============================================================
-- END MERGED SECTION: patch_seed_forex2.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_seed_forex3.sql
-- ============================================================

-- ============================================
-- NIPANZE — Patch v6.4: Multi-currency forex seed (popular EA + Africa pairs)
-- Paste into Supabase Cloud SQL Editor and run once. Idempotent.
--
-- Prerequisite: the Patch v6 Schema section in this file and the Forex Seed Data v6.2 section in this file must
-- already be applied. the Extra UGX to KES Forex Listings section in this file is optional.
--
-- What this does:
--   1. Enables forex_enabled for all active/seeded markets (UG, KE, TZ, RW,
--      NG, ZA, EG — and BI/SS/CD/SO which have seed users).
--   2. Enables forex_trading_enabled for all 8 currencies (UGX, KES, TZS,
--      RWF, NGN, ZAR, EGP, USD).
--   3. Seeds 16 diverse active forex_requests across the most popular
--      cross-border currency pairs in East + broader Africa, using existing
--      seeded user IDs from seed.sql. All are P2P — no platform-held funds.
--
-- Currency pairs covered:
--   UGX ↔ KES  (Uganda ↔ Kenya)        — most popular corridor
--   UGX ↔ TZS  (Uganda ↔ Tanzania)
--   UGX ↔ RWF  (Uganda ↔ Rwanda)
--   KES ↔ TZS  (Kenya ↔ Tanzania)
--   KES ↔ NGN  (Kenya ↔ Nigeria)
--   KES ↔ ZAR  (Kenya ↔ South Africa)
--   KES ↔ USD  (Kenya ↔ USD — remittance)
--   TZS ↔ RWF  (Tanzania ↔ Rwanda)
--   TZS ↔ USD  (Tanzania ↔ USD)
--   RWF ↔ USD  (Rwanda ↔ USD)
--   NGN ↔ USD  (Nigeria ↔ USD — very high volume corridor)
--   ZAR ↔ USD  (South Africa ↔ USD)
--   ZAR ↔ NGN  (South Africa ↔ Nigeria)
--   EGP ↔ USD  (Egypt ↔ USD)
--   UGX ↔ USD  (Uganda ↔ USD)
--   NGN ↔ ZAR  (Nigeria ↔ South Africa)
--
-- UUID ranges per country (from seed.sql):
--   UG: 001-017  | KE: 018-034 | TZ: 035-051 | RW: 052-068
--   BI: 069-085  | SS: 086-102 | CD: 103-119  | SO: 120-136
--   Forex test accounts: 137 (Mutesi Grace/UG), 138 (Nonparticipant/UG)
--
-- Safe to re-run: all INSERTs are ON CONFLICT DO NOTHING.
-- ============================================


-- ============================================
-- STEP 1 — Enable forex for all markets + all currencies
-- ============================================

-- All seeded countries — forex is P2P, no platform funds held
UPDATE countries
SET forex_enabled = TRUE
WHERE code IN ('UG','KE','TZ','RW','BI','SS','CD','SO','NG','ZA','EG');

-- All market currencies + USD cleared for trading
UPDATE currencies
SET forex_trading_enabled = TRUE
WHERE code IN ('UGX','KES','TZS','RWF','NGN','ZAR','EGP','USD');


-- ============================================
-- STEP 2 — Seed diverse forex_requests + offers
-- ============================================

SET session_replication_role = 'replica';

INSERT INTO forex_requests (
    id, requester_id, country, currency_held, currency_needed, amount,
    preferred_rate, settlement_preference, is_urgent, terms_locked_at,
    number_of_offers, status, listed_at, expires_at, created_at
) VALUES

-- ── UGX → KES (Uganda → Kenya) ───────────────────────────────────────────────
-- Listing F01: UGX → KES, MTN MoMo
('c4000000-0000-0000-0000-000000000001',
 '10000000-0000-0000-0000-000000000003', 'UG',
 'UGX', 'KES', 800000, NULL,
 'Mobile money (MTN MoMo), Kampala', FALSE,
 NOW() - INTERVAL '3 hours', 1, 'active',
 NOW() - INTERVAL '3 hours', NOW() + INTERVAL '5 days',
 NOW() - INTERVAL '3 hours'),

-- Listing F02: UGX → KES, in-person Busia border
('c4000000-0000-0000-0000-000000000002',
 '10000000-0000-0000-0000-000000000004', 'UG',
 'UGX', 'KES', 4500000, 0.0289,
 'In-person exchange, Busia border', FALSE,
 NOW() - INTERVAL '8 hours', 2, 'active',
 NOW() - INTERVAL '8 hours', NOW() + INTERVAL '6 days',
 NOW() - INTERVAL '8 hours'),

-- ── UGX → TZS (Uganda → Tanzania) ────────────────────────────────────────────
-- Listing F03
('c4000000-0000-0000-0000-000000000003',
 '10000000-0000-0000-0000-000000000005', 'UG',
 'UGX', 'TZS', 1000000, NULL,
 'Mobile money (MTN MoMo), Kampala', FALSE,
 NOW() - INTERVAL '6 hours', 0, 'active',
 NOW() - INTERVAL '6 hours', NOW() + INTERVAL '7 days',
 NOW() - INTERVAL '6 hours'),

-- ── UGX → RWF (Uganda → Rwanda) ───────────────────────────────────────────────
-- Listing F04
('c4000000-0000-0000-0000-000000000004',
 '10000000-0000-0000-0000-000000000006', 'UG',
 'UGX', 'RWF', 2000000, NULL,
 'Mobile money (Airtel Money), Kampala', TRUE,
 NOW() - INTERVAL '2 hours', 1, 'active',
 NOW() - INTERVAL '2 hours', NOW() + INTERVAL '4 days',
 NOW() - INTERVAL '2 hours'),

-- ── KES → UGX (Kenya → Uganda) ────────────────────────────────────────────────
-- Listing F05
('c4000000-0000-0000-0000-000000000005',
 '10000000-0000-0000-0000-000000000018', 'KE',
 'KES', 'UGX', 25000, NULL,
 'M-Pesa transfer, Nairobi', FALSE,
 NOW() - INTERVAL '4 hours', 1, 'active',
 NOW() - INTERVAL '4 hours', NOW() + INTERVAL '6 days',
 NOW() - INTERVAL '4 hours'),

-- ── KES → TZS (Kenya → Tanzania) ─────────────────────────────────────────────
-- Listing F06
('c4000000-0000-0000-0000-000000000006',
 '10000000-0000-0000-0000-000000000019', 'KE',
 'KES', 'TZS', 30000, NULL,
 'M-Pesa transfer, Mombasa', FALSE,
 NOW() - INTERVAL '10 hours', 2, 'active',
 NOW() - INTERVAL '10 hours', NOW() + INTERVAL '5 days',
 NOW() - INTERVAL '10 hours'),

-- ── KES → NGN (Kenya → Nigeria) ──────────────────────────────────────────────
-- Listing F07
('c4000000-0000-0000-0000-000000000007',
 '10000000-0000-0000-0000-000000000020', 'KE',
 'KES', 'NGN', 50000, NULL,
 'Bank transfer, Nairobi', FALSE,
 NOW() - INTERVAL '14 hours', 0, 'active',
 NOW() - INTERVAL '14 hours', NOW() + INTERVAL '7 days',
 NOW() - INTERVAL '14 hours'),

-- ── KES → USD (Kenya → USD, remittance) ──────────────────────────────────────
-- Listing F08: urgent
('c4000000-0000-0000-0000-000000000008',
 '10000000-0000-0000-0000-000000000021', 'KE',
 'KES', 'USD', 40000, 0.0077,
 'Bank transfer, Nairobi', TRUE,
 NOW() - INTERVAL '30 minutes', 1, 'active',
 NOW() - INTERVAL '30 minutes', NOW() + INTERVAL '3 days',
 NOW() - INTERVAL '30 minutes'),

-- ── KES → ZAR (Kenya → South Africa) ─────────────────────────────────────────
-- Listing F09
('c4000000-0000-0000-0000-000000000009',
 '10000000-0000-0000-0000-000000000022', 'KE',
 'KES', 'ZAR', 60000, NULL,
 'Bank transfer, Nairobi', FALSE,
 NOW() - INTERVAL '20 hours', 1, 'active',
 NOW() - INTERVAL '20 hours', NOW() + INTERVAL '6 days',
 NOW() - INTERVAL '20 hours'),

-- ── TZS → KES (Tanzania → Kenya) ─────────────────────────────────────────────
-- Listing F10
('c4000000-0000-0000-0000-000000000010',
 '10000000-0000-0000-0000-000000000035', 'TZ',
 'TZS', 'KES', 600000, NULL,
 'Mobile money (M-Pesa TZ), Dar es Salaam', FALSE,
 NOW() - INTERVAL '7 hours', 0, 'active',
 NOW() - INTERVAL '7 hours', NOW() + INTERVAL '7 days',
 NOW() - INTERVAL '7 hours'),

-- ── TZS → USD (Tanzania → USD) ───────────────────────────────────────────────
-- Listing F11
('c4000000-0000-0000-0000-000000000011',
 '10000000-0000-0000-0000-000000000036', 'TZ',
 'TZS', 'USD', 2500000, NULL,
 'Bank transfer (CRDB Bank), Dar es Salaam', FALSE,
 NOW() - INTERVAL '22 hours', 1, 'active',
 NOW() - INTERVAL '22 hours', NOW() + INTERVAL '5 days',
 NOW() - INTERVAL '22 hours'),

-- ── RWF → USD (Rwanda → USD) ─────────────────────────────────────────────────
-- Listing F12
('c4000000-0000-0000-0000-000000000012',
 '10000000-0000-0000-0000-000000000052', 'RW',
 'RWF', 'USD', 1200000, NULL,
 'Bank transfer (Bank of Kigali)', FALSE,
 NOW() - INTERVAL '16 hours', 2, 'active',
 NOW() - INTERVAL '16 hours', NOW() + INTERVAL '6 days',
 NOW() - INTERVAL '16 hours'),

-- ── NGN → USD (Nigeria → USD — very high volume) ─────────────────────────────
-- Listing F13: urgent, large
('c4000000-0000-0000-0000-000000000013',
 '10000000-0000-0000-0000-000000000012', 'UG',
 'NGN', 'USD', 500000, NULL,
 'Bank transfer (GTBank)', TRUE,
 NOW() - INTERVAL '45 minutes', 3, 'active',
 NOW() - INTERVAL '45 minutes', NOW() + INTERVAL '3 days',
 NOW() - INTERVAL '45 minutes'),

-- ── ZAR → USD (South Africa → USD) ──────────────────────────────────────────
-- Listing F14
('c4000000-0000-0000-0000-000000000014',
 '10000000-0000-0000-0000-000000000013', 'UG',
 'ZAR', 'USD', 8000, 0.054,
 'Bank transfer (FNB South Africa)', FALSE,
 NOW() - INTERVAL '12 hours', 1, 'active',
 NOW() - INTERVAL '12 hours', NOW() + INTERVAL '7 days',
 NOW() - INTERVAL '12 hours'),

-- ── UGX → USD (Uganda → USD, remittance) ─────────────────────────────────────
-- Listing F15
('c4000000-0000-0000-0000-000000000015',
 '10000000-0000-0000-0000-000000000007', 'UG',
 'UGX', 'USD', 5000000, NULL,
 'Bank transfer (Centenary Bank), Kampala', FALSE,
 NOW() - INTERVAL '9 hours', 1, 'active',
 NOW() - INTERVAL '9 hours', NOW() + INTERVAL '6 days',
 NOW() - INTERVAL '9 hours'),

-- ── EGP → USD (Egypt → USD) ──────────────────────────────────────────────────
-- Listing F16
('c4000000-0000-0000-0000-000000000016',
 '10000000-0000-0000-0000-000000000014', 'UG',
 'EGP', 'USD', 30000, NULL,
 'Bank transfer (CIB Egypt)', FALSE,
 NOW() - INTERVAL '18 hours', 0, 'active',
 NOW() - INTERVAL '18 hours', NOW() + INTERVAL '7 days',
 NOW() - INTERVAL '18 hours')

ON CONFLICT (id) DO NOTHING;


-- ── forex_offers ─────────────────────────────────────────────────────────────

INSERT INTO forex_offers (
    id, request_id, offer_maker_id, rate_offered, amount_available, terms,
    terms_locked_at, status, offered_at, created_at
) VALUES

-- Offer on F01 (UGX→KES)
('d4000000-0000-0000-0000-000000000001',
 'c4000000-0000-0000-0000-000000000001',
 '10000000-0000-0000-0000-000000000026',
 0.0287, 800000, 'Can settle via M-Pesa same day.',
 NOW() - INTERVAL '2 hours', 'pending',
 NOW() - INTERVAL '2 hours', NOW() - INTERVAL '2 hours'),

-- Offer 1 on F02 (UGX→KES, Busia)
('d4000000-0000-0000-0000-000000000002',
 'c4000000-0000-0000-0000-000000000002',
 '10000000-0000-0000-0000-000000000026',
 0.0288, 4500000, 'In-person Busia border, flexible timing.',
 NOW() - INTERVAL '6 hours', 'pending',
 NOW() - INTERVAL '6 hours', NOW() - INTERVAL '6 hours'),

-- Offer 2 on F02 (UGX→KES, Busia)
('d4000000-0000-0000-0000-000000000003',
 'c4000000-0000-0000-0000-000000000002',
 '10000000-0000-0000-0000-000000000027',
 0.0291, 3000000, 'Bank transfer Equity Kenya, within 24h.',
 NOW() - INTERVAL '4 hours', 'pending',
 NOW() - INTERVAL '4 hours', NOW() - INTERVAL '4 hours'),

-- Offer on F04 (UGX→RWF)
('d4000000-0000-0000-0000-000000000004',
 'c4000000-0000-0000-0000-000000000004',
 '10000000-0000-0000-0000-000000000060',
 3.82, 2000000, 'Airtel Money Rwanda, same-day settlement.',
 NOW() - INTERVAL '1 hour', 'pending',
 NOW() - INTERVAL '1 hour', NOW() - INTERVAL '1 hour'),

-- Offer on F05 (KES→UGX)
('d4000000-0000-0000-0000-000000000005',
 'c4000000-0000-0000-0000-000000000005',
 '10000000-0000-0000-0000-000000000008',
 34.5, 25000, 'MTN MoMo, Kampala. Can settle within 2 hours.',
 NOW() - INTERVAL '3 hours', 'pending',
 NOW() - INTERVAL '3 hours', NOW() - INTERVAL '3 hours'),

-- Offer 1 on F06 (KES→TZS)
('d4000000-0000-0000-0000-000000000006',
 'c4000000-0000-0000-0000-000000000006',
 '10000000-0000-0000-0000-000000000043',
 22.8, 30000, 'M-Pesa Tanzania, same-day.',
 NOW() - INTERVAL '8 hours', 'pending',
 NOW() - INTERVAL '8 hours', NOW() - INTERVAL '8 hours'),

-- Offer 2 on F06 (KES→TZS)
('d4000000-0000-0000-0000-000000000007',
 'c4000000-0000-0000-0000-000000000006',
 '10000000-0000-0000-0000-000000000044',
 23.1, 25000, 'Bank transfer CRDB Tanzania, 24h.',
 NOW() - INTERVAL '5 hours', 'pending',
 NOW() - INTERVAL '5 hours', NOW() - INTERVAL '5 hours'),

-- Offer on F08 (KES→USD, urgent)
('d4000000-0000-0000-0000-000000000008',
 'c4000000-0000-0000-0000-000000000008',
 '10000000-0000-0000-0000-000000000028',
 0.0076, 40000, 'Bank transfer KCB Kenya, within 4 hours.',
 NOW() - INTERVAL '20 minutes', 'pending',
 NOW() - INTERVAL '20 minutes', NOW() - INTERVAL '20 minutes'),

-- Offer on F09 (KES→ZAR)
('d4000000-0000-0000-0000-000000000009',
 'c4000000-0000-0000-0000-000000000009',
 '10000000-0000-0000-0000-000000000029',
 0.138, 60000, 'Bank transfer FNB South Africa, 2 business days.',
 NOW() - INTERVAL '14 hours', 'pending',
 NOW() - INTERVAL '14 hours', NOW() - INTERVAL '14 hours'),

-- Offer on F11 (TZS→USD)
('d4000000-0000-0000-0000-000000000010',
 'c4000000-0000-0000-0000-000000000011',
 '10000000-0000-0000-0000-000000000045',
 0.00038, 2500000, 'CRDB Bank transfer, 24-48h.',
 NOW() - INTERVAL '18 hours', 'pending',
 NOW() - INTERVAL '18 hours', NOW() - INTERVAL '18 hours'),

-- Offer 1 on F12 (RWF→USD)
('d4000000-0000-0000-0000-000000000011',
 'c4000000-0000-0000-0000-000000000012',
 '10000000-0000-0000-0000-000000000061',
 0.00072, 1200000, 'Bank of Kigali transfer, 24h.',
 NOW() - INTERVAL '12 hours', 'pending',
 NOW() - INTERVAL '12 hours', NOW() - INTERVAL '12 hours'),

-- Offer 2 on F12 (RWF→USD)
('d4000000-0000-0000-0000-000000000012',
 'c4000000-0000-0000-0000-000000000012',
 '10000000-0000-0000-0000-000000000062',
 0.00073, 1000000, 'I&M Bank Rwanda, same-day for amounts under 500k.',
 NOW() - INTERVAL '8 hours', 'pending',
 NOW() - INTERVAL '8 hours', NOW() - INTERVAL '8 hours'),

-- Offer on F13 (NGN→USD, urgent, 3 offers)
('d4000000-0000-0000-0000-000000000013',
 'c4000000-0000-0000-0000-000000000013',
 '10000000-0000-0000-0000-000000000009',
 0.00062, 500000, 'GTBank Nigeria → USD wire, same day.',
 NOW() - INTERVAL '40 minutes', 'pending',
 NOW() - INTERVAL '40 minutes', NOW() - INTERVAL '40 minutes'),
('d4000000-0000-0000-0000-000000000014',
 'c4000000-0000-0000-0000-000000000013',
 '10000000-0000-0000-0000-000000000010',
 0.00063, 400000, 'Zenith Bank transfer, within 3 hours.',
 NOW() - INTERVAL '30 minutes', 'pending',
 NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '30 minutes'),
('d4000000-0000-0000-0000-000000000015',
 'c4000000-0000-0000-0000-000000000013',
 '10000000-0000-0000-0000-000000000011',
 0.00061, 500000, 'Access Bank transfer, competitive rate.',
 NOW() - INTERVAL '15 minutes', 'pending',
 NOW() - INTERVAL '15 minutes', NOW() - INTERVAL '15 minutes'),

-- Offer on F14 (ZAR→USD)
('d4000000-0000-0000-0000-000000000016',
 'c4000000-0000-0000-0000-000000000014',
 '10000000-0000-0000-0000-000000000015',
 0.053, 8000, 'FNB South Africa wire transfer, 1-2 days.',
 NOW() - INTERVAL '10 hours', 'pending',
 NOW() - INTERVAL '10 hours', NOW() - INTERVAL '10 hours'),

-- Offer on F15 (UGX→USD)
('d4000000-0000-0000-0000-000000000017',
 'c4000000-0000-0000-0000-000000000015',
 '10000000-0000-0000-0000-000000000016',
 0.000269, 5000000, 'Centenary Bank transfer, 24h.',
 NOW() - INTERVAL '7 hours', 'pending',
 NOW() - INTERVAL '7 hours', NOW() - INTERVAL '7 hours')

ON CONFLICT (id) DO NOTHING;

SET session_replication_role = 'origin';


-- ============================================
-- VERIFICATION
-- ============================================

SELECT '✅ Forex seed v6.4 — multi-currency pairs enabled across EA + Africa' AS status;

SELECT code, forex_enabled FROM countries
WHERE code IN ('UG','KE','TZ','RW','BI','SS','CD','SO','NG','ZA','EG')
ORDER BY code;

SELECT code, forex_trading_enabled FROM currencies ORDER BY code;

SELECT currency_held || ' → ' || currency_needed AS pair,
       COUNT(*) AS listings,
       SUM(number_of_offers) AS total_offers
FROM v_forex_listings
GROUP BY currency_held, currency_needed
ORDER BY listings DESC, pair;

-- ============================================================
-- END MERGED SECTION: patch_seed_forex3.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_subscription_pricing.sql
-- ============================================================

-- ============================================
-- PATCH: Subscription Pricing Per Currency / Market
-- Allows admin to configure monthly subscription fees (lender, pro)
-- for every active or supported currency market.
-- ============================================

CREATE TABLE IF NOT EXISTS public.subscription_prices (
    id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    country_code       TEXT NOT NULL REFERENCES public.countries(code) ON DELETE CASCADE,
    currency_code      TEXT NOT NULL,
    plan               public.subscription_plan_enum NOT NULL, -- 'lender', 'pro'
    price_amount       NUMERIC(12, 2) NOT NULL DEFAULT 0,
    price_minor_units  BIGINT NOT NULL DEFAULT 0,
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uidx_subscription_prices_country_plan UNIQUE (country_code, plan)
);

COMMENT ON TABLE public.subscription_prices IS
'Stores country/currency specific pricing for paid subscription plans (lender, pro). Admin managed.';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_subscription_prices_country ON public.subscription_prices (country_code);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION public.update_subscription_prices_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_subscription_prices_updated_at ON public.subscription_prices;
CREATE TRIGGER trg_subscription_prices_updated_at
    BEFORE UPDATE ON public.subscription_prices
    FOR EACH ROW
    EXECUTE FUNCTION public.update_subscription_prices_updated_at();

-- RLS Policies & Grants
ALTER TABLE public.subscription_prices ENABLE ROW LEVEL SECURITY;

-- Grants
GRANT ALL ON TABLE public.subscription_prices TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.subscription_prices TO authenticated;
GRANT SELECT ON TABLE public.subscription_prices TO anon;

DROP POLICY IF EXISTS "subscription_prices: public read" ON public.subscription_prices;
CREATE POLICY "subscription_prices: public read"
    ON public.subscription_prices FOR SELECT
    TO authenticated, anon
    USING (TRUE);

DROP POLICY IF EXISTS "subscription_prices: admin write" ON public.subscription_prices;
CREATE POLICY "subscription_prices: admin write"
    ON public.subscription_prices FOR ALL
    TO authenticated
    USING (private.is_admin());

-- Seed default pricing for supported EAC markets
INSERT INTO public.subscription_prices (country_code, currency_code, plan, price_amount, price_minor_units) VALUES
    ('UG', 'UGX', 'lender', 19900, 19900),
    ('UG', 'UGX', 'pro',    49900, 49900),
    ('KE', 'KES', 'lender', 690,   690),
    ('KE', 'KES', 'pro',    1790,  1790),
    ('TZ', 'TZS', 'lender', 12900, 12900),
    ('TZ', 'TZS', 'pro',    32900, 32900),
    ('RW', 'RWF', 'lender', 6500,  6500),
    ('RW', 'RWF', 'pro',    16500, 16500),
    ('BI', 'BIF', 'lender', 15000, 15000),
    ('BI', 'BIF', 'pro',    38000, 38000),
    ('SS', 'SSP', 'lender', 2500,  2500),
    ('SS', 'SSP', 'pro',    6500,  6500),
    ('CD', 'CDF', 'lender', 14000, 14000),
    ('CD', 'CDF', 'pro',    35000, 35000),
    ('SO', 'SOS', 'lender', 3000,  3000),
    ('SO', 'SOS', 'pro',    7500,  7500)
ON CONFLICT (country_code, plan) DO UPDATE SET
    price_amount = EXCLUDED.price_amount,
    price_minor_units = EXCLUDED.price_minor_units,
    currency_code = EXCLUDED.currency_code;

-- ============================================================
-- END MERGED SECTION: patch_subscription_pricing.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_market_baseline_rates.sql
-- ============================================================

-- Patch: Admin-controlled market baseline rates for interest and late payment
-- Uses system_settings with country overrides and a global default.

INSERT INTO system_settings (
  setting_key,
  country,
  setting_value,
  setting_type,
  category,
  description,
  is_public
) VALUES
  ('market_interest_rate_baseline_pct', NULL, '10.0', 'number', 'marketplace', 'Global default market interest rate baseline percentage controlled by admin.', TRUE),
  ('market_late_payment_rate_baseline_pct', NULL, '5.0', 'number', 'marketplace', 'Global default market late payment rate baseline percentage controlled by admin.', TRUE)
ON CONFLICT (setting_key, COALESCE(country, '__global__')) DO UPDATE
SET
  setting_value = EXCLUDED.setting_value,
  setting_type = EXCLUDED.setting_type,
  category = EXCLUDED.category,
  description = EXCLUDED.description,
  is_public = EXCLUDED.is_public,
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO system_settings (
  setting_key,
  country,
  setting_value,
  setting_type,
  category,
  description,
  is_public
) VALUES
  ('market_interest_rate_baseline_pct', 'UG', '10.0', 'number', 'marketplace', 'Uganda market baseline interest rate percentage controlled by admin.', TRUE),
  ('market_late_payment_rate_baseline_pct', 'UG', '5.0', 'number', 'marketplace', 'Uganda market baseline late payment rate percentage controlled by admin.', TRUE),
  ('market_interest_rate_baseline_pct', 'KE', '11.5', 'number', 'marketplace', 'Kenya market baseline interest rate percentage controlled by admin.', TRUE),
  ('market_late_payment_rate_baseline_pct', 'KE', '6.0', 'number', 'marketplace', 'Kenya market baseline late payment rate percentage controlled by admin.', TRUE),
  ('market_interest_rate_baseline_pct', 'TZ', '12.0', 'number', 'marketplace', 'Tanzania market baseline interest rate percentage controlled by admin.', TRUE),
  ('market_late_payment_rate_baseline_pct', 'TZ', '6.5', 'number', 'marketplace', 'Tanzania market baseline late payment rate percentage controlled by admin.', TRUE),
  ('market_interest_rate_baseline_pct', 'RW', '11.0', 'number', 'marketplace', 'Rwanda market baseline interest rate percentage controlled by admin.', TRUE),
  ('market_late_payment_rate_baseline_pct', 'RW', '6.0', 'number', 'marketplace', 'Rwanda market baseline late payment rate percentage controlled by admin.', TRUE),
  ('market_interest_rate_baseline_pct', 'NG', '13.0', 'number', 'marketplace', 'Nigeria market baseline interest rate percentage controlled by admin.', TRUE),
  ('market_late_payment_rate_baseline_pct', 'NG', '7.0', 'number', 'marketplace', 'Nigeria market baseline late payment rate percentage controlled by admin.', TRUE),
  ('market_interest_rate_baseline_pct', 'ZA', '9.5', 'number', 'marketplace', 'South Africa market baseline interest rate percentage controlled by admin.', TRUE),
  ('market_late_payment_rate_baseline_pct', 'ZA', '5.0', 'number', 'marketplace', 'South Africa market baseline late payment rate percentage controlled by admin.', TRUE),
  ('market_interest_rate_baseline_pct', 'EG', '12.5', 'number', 'marketplace', 'Egypt market baseline interest rate percentage controlled by admin.', TRUE),
  ('market_late_payment_rate_baseline_pct', 'EG', '6.5', 'number', 'marketplace', 'Egypt market baseline late payment rate percentage controlled by admin.', TRUE)
ON CONFLICT (setting_key, COALESCE(country, '__global__')) DO UPDATE
SET
  setting_value = EXCLUDED.setting_value,
  updated_at = CURRENT_TIMESTAMP;

-- ============================================================
-- END MERGED SECTION: patch_market_baseline_rates.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_professional_tags.sql
-- ============================================================

-- Nipanze professional tags patch
-- Paste this into Supabase SQL editor.
--
-- Adds profile metadata for preferred bank/deposit bank, bank-agent status,
-- and public professional tags for banks, forex exchange companies, SACCOs,
-- and companies. Tag fields are only exposed to active Pro users.

BEGIN;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS preferred_bank TEXT,
  ADD COLUMN IF NOT EXISTS institution_type TEXT,
  ADD COLUMN IF NOT EXISTS is_bank_agent BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS show_professional_tag BOOLEAN NOT NULL DEFAULT TRUE;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'profiles_institution_type_check'
      AND conrelid = 'public.profiles'::regclass
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_institution_type_check
      CHECK (
        institution_type IS NULL OR
        institution_type IN ('bank', 'forex_exchange', 'sacco', 'company')
      );
  END IF;
END $$;

COMMENT ON COLUMN public.profiles.preferred_bank IS
'User preferred bank/deposit bank. May also name the bank represented by a bank loan agent.';
COMMENT ON COLUMN public.profiles.institution_type IS
'Optional public professional account category: bank, forex_exchange, sacco, company.';
COMMENT ON COLUMN public.profiles.is_bank_agent IS
'True when the account holder is a bank loan agent.';
COMMENT ON COLUMN public.profiles.show_professional_tag IS
'User-controlled opt-out for showing professional tags in marketplace surfaces.';

-- Loan listings: add nullable tag fields for Pro viewers.
CREATE OR REPLACE VIEW public.v_loan_listings AS
SELECT
    lr.id                                                                     AS request_id,
    lr.title,
    lr.purpose,
    lr.district,
    lr.country,
    c.currency_code,
    lr.duration_months,
    lr.requested_amount,
    lr.preferred_repayment_plan,
    lr.repayment_amount_per_period,
    lr.repayment_timeline,
    lr.suggested_interest_rate_pct,
    lr.suggested_late_fee_pct,
    lr.suggested_repayment_frequency,
    lr.suggested_installment_amount,
    lr.terms_locked_at,
    lr.status,
    lr.number_of_offers,
    CASE
        WHEN lr.number_of_offers = 0 THEN 'low'
        WHEN lr.number_of_offers <= 2 THEN 'medium'
        ELSE 'high'
    END                                                                       AS offer_coverage_tier,
    lr.listed_at,
    lr.expires_at,
    k.status                                                                  AS kyc_status,
    ta.rating_avg                                                             AS trust_rating_avg,
    COALESCE(ta.review_count, 0)                                              AS trust_review_count,
    COALESCE(ta.completed_deals_count, 0)                                     AS trust_completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE)                                AS trust_is_repeat_participant,
    (p.phone_verified_at IS NOT NULL)                                        AS trust_phone_verified,
    ta.response_time_bucket                                                   AS trust_response_time_bucket,
    (k.status = 'approved')                                                   AS trust_is_verified,
    GREATEST(lr.expires_at - NOW(), INTERVAL '0')                            AS time_remaining,
    (lr.expires_at < NOW() + INTERVAL '24 hours')                            AS closing_soon_24h,
    (lr.expires_at < NOW() + INTERVAL '6 hours')                             AS closing_soon_6h,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.preferred_bank ELSE NULL END                                    AS preferred_bank,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.institution_type ELSE NULL END                                  AS institution_type,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.is_bank_agent ELSE FALSE END                                    AS is_bank_agent,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN TRUE ELSE FALSE END                                               AS show_professional_tag
FROM  public.loan_requests lr
JOIN  public.profiles p ON p.id = lr.borrower_id
JOIN  public.countries c ON c.code = lr.country
LEFT  JOIN public.kyc_verifications k ON k.user_id = lr.borrower_id
LEFT  JOIN public.trust_aggregates ta ON ta.user_id = lr.borrower_id
WHERE lr.status = 'active'
  AND (
    auth.uid() IS NULL OR lr.borrower_id <> auth.uid()
  )
  AND (
    auth.uid() IS NULL OR NOT EXISTS (
      SELECT 1 FROM public.loan_offers lo
      WHERE lo.request_id = lr.id
        AND lo.lender_id = auth.uid()
        AND lo.status IN ('pending', 'accepted')
    )
  );

-- Lender offer history: add nullable tag fields for Pro viewers.
CREATE OR REPLACE VIEW public.v_lender_offers WITH (security_invoker = true) AS
SELECT
    lo.lender_id,
    lo.id                                                                     AS offer_id,
    lo.request_id,
    lr.title                                                                  AS listing_title,
    lr.purpose                                                                AS listing_purpose,
    lr.district,
    lr.country,
    c.currency_code,
    lr.duration_months,
    lr.requested_amount,
    lo.offer_amount,
    lo.interest_rate_pct,
    lo.late_fee_pct,
    lo.repayment_frequency,
    lo.installment_amount,
    lo.proposed_expectations,
    lo.terms_locked_at,
    lo.status                                                                 AS offer_status,
    lo.offered_at,
    lo.accepted_at,
    ta.rating_avg                                                             AS trust_rating_avg,
    COALESCE(ta.review_count, 0)                                              AS trust_review_count,
    COALESCE(ta.completed_deals_count, 0)                                     AS trust_completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE)                                AS trust_is_repeat_participant,
    (p.phone_verified_at IS NOT NULL)                                        AS trust_phone_verified,
    ta.response_time_bucket                                                   AS trust_response_time_bucket,
    (k.status = 'approved')                                                   AS trust_is_verified,
    cr.status                                                                 AS reveal_status,
    cr.revealed_at,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.preferred_bank ELSE NULL END                                    AS preferred_bank,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.institution_type ELSE NULL END                                  AS institution_type,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.is_bank_agent ELSE FALSE END                                    AS is_bank_agent,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN TRUE ELSE FALSE END                                               AS show_professional_tag
FROM  public.loan_offers lo
JOIN  public.loan_requests lr ON lr.id = lo.request_id
JOIN  public.countries c ON c.code = lr.country
JOIN  public.profiles p ON p.id = lo.lender_id
LEFT  JOIN public.kyc_verifications k ON k.user_id = lo.lender_id
LEFT  JOIN public.trust_aggregates ta ON ta.user_id = lo.lender_id
LEFT  JOIN public.contact_reveals cr ON cr.offer_id = lo.id;

-- Changing RETURNS TABLE requires dropping the old function signature first.
DROP FUNCTION IF EXISTS public.get_public_listing_offers(UUID);

CREATE FUNCTION public.get_public_listing_offers(p_request_id UUID)
RETURNS TABLE (
    id UUID,
    request_id UUID,
    lender_id TEXT,
    offer_amount BIGINT,
    interest_rate_pct NUMERIC,
    late_fee_pct NUMERIC,
    repayment_frequency TEXT,
    installment_amount BIGINT,
    proposed_expectations TEXT,
    terms_locked_at TIMESTAMP,
    status TEXT,
    offered_at TIMESTAMP,
    accepted_at TIMESTAMP,
    preferred_bank TEXT,
    institution_type TEXT,
    is_bank_agent BOOLEAN,
    show_professional_tag BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = ''
AS $$
DECLARE
    v_is_owner BOOLEAN := FALSE;
    v_is_offer_maker BOOLEAN := FALSE;
    v_is_pro BOOLEAN := FALSE;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM public.subscriptions s
        WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) INTO v_is_pro;

    SELECT lr.borrower_id = auth.uid() INTO v_is_owner
    FROM public.loan_requests lr
    WHERE lr.id = p_request_id;

    SELECT EXISTS (
        SELECT 1 FROM public.loan_offers own
        WHERE own.request_id = p_request_id
          AND own.lender_id = auth.uid()
          AND own.status IN ('pending', 'accepted')
    ) INTO v_is_offer_maker;

    IF NOT COALESCE(v_is_owner, FALSE) AND NOT COALESCE(v_is_offer_maker, FALSE) THEN
        RETURN;
    END IF;

    IF COALESCE(v_is_owner, FALSE) THEN
        RETURN QUERY
        SELECT
            lo.id,
            lo.request_id,
            ('public-offer-' || ROW_NUMBER() OVER (ORDER BY lo.offered_at ASC))::TEXT AS lender_id,
            lo.offer_amount,
            lo.interest_rate_pct,
            lo.late_fee_pct,
            lo.repayment_frequency::TEXT,
            lo.installment_amount,
            lo.proposed_expectations,
            lo.terms_locked_at,
            lo.status::TEXT,
            lo.offered_at,
            lo.accepted_at,
            CASE WHEN v_is_pro AND p.show_professional_tag THEN p.preferred_bank ELSE NULL END,
            CASE WHEN v_is_pro AND p.show_professional_tag THEN p.institution_type ELSE NULL END,
            CASE WHEN v_is_pro AND p.show_professional_tag THEN p.is_bank_agent ELSE FALSE END,
            CASE WHEN v_is_pro AND p.show_professional_tag THEN TRUE ELSE FALSE END
        FROM public.loan_offers lo
        JOIN public.loan_requests lr ON lr.id = lo.request_id
        JOIN public.profiles p ON p.id = lo.lender_id
        WHERE lo.request_id = p_request_id
          AND lo.status = 'pending'
          AND (lr.status = 'active' OR lr.borrower_id = auth.uid())
        ORDER BY lo.offered_at DESC;
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        lo.id,
        lo.request_id,
        ('your-offer')::TEXT AS lender_id,
        lo.offer_amount,
        lo.interest_rate_pct,
        lo.late_fee_pct,
        lo.repayment_frequency::TEXT,
        lo.installment_amount,
        lo.proposed_expectations,
        lo.terms_locked_at,
        lo.status::TEXT,
        lo.offered_at,
        lo.accepted_at,
        CASE WHEN v_is_pro AND p.show_professional_tag THEN p.preferred_bank ELSE NULL END,
        CASE WHEN v_is_pro AND p.show_professional_tag THEN p.institution_type ELSE NULL END,
        CASE WHEN v_is_pro AND p.show_professional_tag THEN p.is_bank_agent ELSE FALSE END,
        CASE WHEN v_is_pro AND p.show_professional_tag THEN TRUE ELSE FALSE END
    FROM public.loan_offers lo
    JOIN public.profiles p ON p.id = lo.lender_id
    WHERE lo.request_id = p_request_id
      AND lo.lender_id = auth.uid()
      AND lo.status IN ('pending', 'accepted');
END;
$$;

COMMENT ON FUNCTION public.get_public_listing_offers(UUID) IS
'Participant-scoped loan bid book. Exact terms are visible only to listing owners and offer-makers. Professional tag fields are returned only to active Pro users and only when the offer-maker opted in.';

-- Forex marketplace/tag support. These statements require the forex schema
-- from sql/the Patch v6 Schema section in this file to already exist.
CREATE OR REPLACE VIEW public.v_forex_listings AS
SELECT
    fr.id                                                                     AS request_id,
    fr.currency_held,
    fr.currency_needed,
    fr.amount,
    fr.country,
    fr.settlement_preference,
    fr.is_urgent,
    fr.preferred_rate,
    fr.terms_locked_at,
    fr.status,
    fr.number_of_offers,
    CASE
        WHEN fr.number_of_offers = 0 THEN 'low'
        WHEN fr.number_of_offers <= 2 THEN 'medium'
        ELSE 'high'
    END                                                                       AS rate_coverage_tier,
    fr.listed_at,
    fr.expires_at,
    k.status                                                                  AS kyc_status,
    ta.rating_avg                                                             AS trust_rating_avg,
    COALESCE(ta.review_count, 0)                                              AS trust_review_count,
    COALESCE(ta.completed_deals_count, 0)                                     AS trust_completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE)                                AS trust_is_repeat_participant,
    (p.phone_verified_at IS NOT NULL)                                        AS trust_phone_verified,
    ta.response_time_bucket                                                   AS trust_response_time_bucket,
    (k.status = 'approved')                                                   AS trust_is_verified,
    GREATEST(fr.expires_at - NOW(), INTERVAL '0')                            AS time_remaining,
    (fr.expires_at < NOW() + INTERVAL '24 hours')                            AS closing_soon_24h,
    (fr.expires_at < NOW() + INTERVAL '6 hours')                             AS closing_soon_6h,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.preferred_bank ELSE NULL END                                    AS preferred_bank,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.institution_type ELSE NULL END                                  AS institution_type,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.is_bank_agent ELSE FALSE END                                    AS is_bank_agent,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN TRUE ELSE FALSE END                                               AS show_professional_tag
FROM  public.forex_requests fr
JOIN  public.profiles p ON p.id = fr.requester_id
LEFT  JOIN public.kyc_verifications k ON k.user_id = fr.requester_id
LEFT  JOIN public.trust_aggregates ta ON ta.user_id = fr.requester_id
WHERE fr.status = 'active'
  AND (
    auth.uid() IS NULL OR fr.requester_id <> auth.uid()
  )
  AND (
    auth.uid() IS NULL OR NOT EXISTS (
      SELECT 1 FROM public.forex_offers fo
      WHERE fo.request_id = fr.id
        AND fo.offer_maker_id = auth.uid()
        AND fo.status IN ('pending', 'accepted')
    )
  );

CREATE OR REPLACE VIEW public.v_forex_offers WITH (security_invoker = true) AS
SELECT
    fo.offer_maker_id,
    fo.id                                                                     AS offer_id,
    fo.request_id,
    fr.currency_held,
    fr.currency_needed,
    fr.amount                                                                 AS requested_amount,
    fr.country,
    fr.settlement_preference,
    fo.rate_offered,
    fo.amount_available,
    fo.terms,
    fo.terms_locked_at,
    fo.status                                                                 AS offer_status,
    fo.offered_at,
    fo.accepted_at,
    ta.rating_avg                                                             AS trust_rating_avg,
    COALESCE(ta.review_count, 0)                                              AS trust_review_count,
    COALESCE(ta.completed_deals_count, 0)                                     AS trust_completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE)                                AS trust_is_repeat_participant,
    (p.phone_verified_at IS NOT NULL)                                        AS trust_phone_verified,
    ta.response_time_bucket                                                   AS trust_response_time_bucket,
    (k.status = 'approved')                                                   AS trust_is_verified,
    fcr.status                                                                AS reveal_status,
    fcr.revealed_at,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.preferred_bank ELSE NULL END                                    AS preferred_bank,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.institution_type ELSE NULL END                                  AS institution_type,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.is_bank_agent ELSE FALSE END                                    AS is_bank_agent,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN TRUE ELSE FALSE END                                               AS show_professional_tag
FROM  public.forex_offers fo
JOIN  public.forex_requests fr ON fr.id = fo.request_id
JOIN  public.profiles p ON p.id = fo.offer_maker_id
LEFT  JOIN public.kyc_verifications k ON k.user_id = fo.offer_maker_id
LEFT  JOIN public.trust_aggregates ta ON ta.user_id = fo.offer_maker_id
LEFT  JOIN public.forex_contact_reveals fcr ON fcr.offer_id = fo.id;

DROP FUNCTION IF EXISTS public.get_public_forex_offers(UUID);

CREATE FUNCTION public.get_public_forex_offers(p_request_id UUID)
RETURNS TABLE (
    id UUID,
    request_id UUID,
    offer_maker_id TEXT,
    rate_offered NUMERIC,
    amount_available BIGINT,
    terms TEXT,
    terms_locked_at TIMESTAMP,
    status TEXT,
    offered_at TIMESTAMP,
    accepted_at TIMESTAMP,
    preferred_bank TEXT,
    institution_type TEXT,
    is_bank_agent BOOLEAN,
    show_professional_tag BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = ''
AS $$
DECLARE
    v_is_owner BOOLEAN := FALSE;
    v_is_offer_maker BOOLEAN := FALSE;
    v_is_pro BOOLEAN := FALSE;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM public.subscriptions s
        WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) INTO v_is_pro;

    SELECT fr.requester_id = auth.uid() INTO v_is_owner
    FROM public.forex_requests fr
    WHERE fr.id = p_request_id;

    SELECT EXISTS (
        SELECT 1 FROM public.forex_offers own
        WHERE own.request_id = p_request_id
          AND own.offer_maker_id = auth.uid()
          AND own.status IN ('pending', 'accepted')
    ) INTO v_is_offer_maker;

    IF NOT COALESCE(v_is_owner, FALSE) AND NOT COALESCE(v_is_offer_maker, FALSE) THEN
        RETURN;
    END IF;

    IF COALESCE(v_is_owner, FALSE) THEN
        RETURN QUERY
        SELECT
            fo.id,
            fo.request_id,
            ('public-offer-' || ROW_NUMBER() OVER (ORDER BY fo.offered_at ASC))::TEXT AS offer_maker_id,
            fo.rate_offered,
            fo.amount_available,
            fo.terms,
            fo.terms_locked_at,
            fo.status::TEXT,
            fo.offered_at,
            fo.accepted_at,
            CASE WHEN v_is_pro AND p.show_professional_tag THEN p.preferred_bank ELSE NULL END,
            CASE WHEN v_is_pro AND p.show_professional_tag THEN p.institution_type ELSE NULL END,
            CASE WHEN v_is_pro AND p.show_professional_tag THEN p.is_bank_agent ELSE FALSE END,
            CASE WHEN v_is_pro AND p.show_professional_tag THEN TRUE ELSE FALSE END
        FROM public.forex_offers fo
        JOIN public.forex_requests fr ON fr.id = fo.request_id
        JOIN public.profiles p ON p.id = fo.offer_maker_id
        WHERE fo.request_id = p_request_id
          AND fo.status = 'pending'
          AND (fr.status = 'active' OR fr.requester_id = auth.uid())
        ORDER BY fo.offered_at DESC;
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        fo.id,
        fo.request_id,
        ('your-offer')::TEXT AS offer_maker_id,
        fo.rate_offered,
        fo.amount_available,
        fo.terms,
        fo.terms_locked_at,
        fo.status::TEXT,
        fo.offered_at,
        fo.accepted_at,
        CASE WHEN v_is_pro AND p.show_professional_tag THEN p.preferred_bank ELSE NULL END,
        CASE WHEN v_is_pro AND p.show_professional_tag THEN p.institution_type ELSE NULL END,
        CASE WHEN v_is_pro AND p.show_professional_tag THEN p.is_bank_agent ELSE FALSE END,
        CASE WHEN v_is_pro AND p.show_professional_tag THEN TRUE ELSE FALSE END
    FROM public.forex_offers fo
    JOIN public.profiles p ON p.id = fo.offer_maker_id
    WHERE fo.request_id = p_request_id
      AND fo.offer_maker_id = auth.uid()
      AND fo.status IN ('pending', 'accepted');
END;
$$;

COMMENT ON FUNCTION public.get_public_forex_offers(UUID) IS
'Participant-scoped forex bid book. Exact terms are visible only to request owners and offer-makers. Professional tag fields are returned only to active Pro users and only when the offer-maker opted in.';

GRANT SELECT ON public.v_loan_listings TO authenticated, anon;
GRANT SELECT ON public.v_lender_offers TO authenticated, anon;
GRANT SELECT ON public.v_forex_listings TO authenticated, anon;
GRANT SELECT ON public.v_forex_offers TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.get_public_listing_offers(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_public_forex_offers(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_public_listing_offers(UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_public_forex_offers(UUID) FROM anon;

COMMIT;

-- ============================================================
-- END MERGED SECTION: patch_professional_tags.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_offer_countdown_public_offers.sql
-- ============================================================

-- Expose loan offer expiry to listing-detail participants for countdown UI.
-- Run this in the Supabase SQL editor after professional tags are installed.

BEGIN;

DROP FUNCTION IF EXISTS public.get_public_listing_offers(UUID);

CREATE FUNCTION public.get_public_listing_offers(p_request_id UUID)
RETURNS TABLE (
    id UUID,
    request_id UUID,
    lender_id TEXT,
    offer_amount BIGINT,
    interest_rate_pct NUMERIC,
    late_fee_pct NUMERIC,
    repayment_frequency TEXT,
    installment_amount BIGINT,
    proposed_expectations TEXT,
    terms_locked_at TIMESTAMP,
    status TEXT,
    offered_at TIMESTAMP,
    accepted_at TIMESTAMP,
    expires_at TIMESTAMP,
    preferred_bank TEXT,
    institution_type TEXT,
    is_bank_agent BOOLEAN,
    show_professional_tag BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = ''
AS $$
DECLARE
    v_is_owner BOOLEAN := FALSE;
    v_is_offer_maker BOOLEAN := FALSE;
    v_is_pro BOOLEAN := FALSE;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM public.subscriptions s
        WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) INTO v_is_pro;

    SELECT lr.borrower_id = auth.uid() INTO v_is_owner
    FROM public.loan_requests lr
    WHERE lr.id = p_request_id;

    SELECT EXISTS (
        SELECT 1 FROM public.loan_offers own
        WHERE own.request_id = p_request_id
          AND own.lender_id = auth.uid()
          AND own.status IN ('pending', 'accepted')
    ) INTO v_is_offer_maker;

    IF NOT COALESCE(v_is_owner, FALSE) AND NOT COALESCE(v_is_offer_maker, FALSE) THEN
        RETURN;
    END IF;

    IF COALESCE(v_is_owner, FALSE) THEN
        RETURN QUERY
        SELECT
            lo.id,
            lo.request_id,
            ('public-offer-' || ROW_NUMBER() OVER (ORDER BY lo.offered_at ASC))::TEXT AS lender_id,
            lo.offer_amount,
            lo.interest_rate_pct,
            lo.late_fee_pct,
            lo.repayment_frequency::TEXT,
            lo.installment_amount,
            lo.proposed_expectations,
            lo.terms_locked_at,
            lo.status::TEXT,
            lo.offered_at,
            lo.accepted_at,
            lo.expires_at,
            CASE WHEN v_is_pro AND p.show_professional_tag THEN p.preferred_bank ELSE NULL END,
            CASE WHEN v_is_pro AND p.show_professional_tag THEN p.institution_type ELSE NULL END,
            CASE WHEN v_is_pro AND p.show_professional_tag THEN p.is_bank_agent ELSE FALSE END,
            CASE WHEN v_is_pro AND p.show_professional_tag THEN TRUE ELSE FALSE END
        FROM public.loan_offers lo
        JOIN public.loan_requests lr ON lr.id = lo.request_id
        JOIN public.profiles p ON p.id = lo.lender_id
        WHERE lo.request_id = p_request_id
          AND lo.status = 'pending'
          AND (lr.status = 'active' OR lr.borrower_id = auth.uid())
        ORDER BY lo.offered_at DESC;
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        lo.id,
        lo.request_id,
        ('your-offer')::TEXT AS lender_id,
        lo.offer_amount,
        lo.interest_rate_pct,
        lo.late_fee_pct,
        lo.repayment_frequency::TEXT,
        lo.installment_amount,
        lo.proposed_expectations,
        lo.terms_locked_at,
        lo.status::TEXT,
        lo.offered_at,
        lo.accepted_at,
        lo.expires_at,
        CASE WHEN v_is_pro AND p.show_professional_tag THEN p.preferred_bank ELSE NULL END,
        CASE WHEN v_is_pro AND p.show_professional_tag THEN p.institution_type ELSE NULL END,
        CASE WHEN v_is_pro AND p.show_professional_tag THEN p.is_bank_agent ELSE FALSE END,
        CASE WHEN v_is_pro AND p.show_professional_tag THEN TRUE ELSE FALSE END
    FROM public.loan_offers lo
    JOIN public.profiles p ON p.id = lo.lender_id
    WHERE lo.request_id = p_request_id
      AND lo.lender_id = auth.uid()
      AND lo.status IN ('pending', 'accepted');
END;
$$;

COMMENT ON FUNCTION public.get_public_listing_offers(UUID) IS
'Participant-scoped loan bid book. Exact terms and offer expiry are visible only to listing owners and offer-makers. Professional tag fields are returned only to active Pro users and only when the offer-maker opted in.';

GRANT EXECUTE ON FUNCTION public.get_public_listing_offers(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_public_listing_offers(UUID) FROM anon;

CREATE OR REPLACE VIEW public.v_lender_offers WITH (security_invoker = true) AS
SELECT
    lo.lender_id,
    lo.id                                                                     AS offer_id,
    lo.request_id,
    lr.title                                                                  AS listing_title,
    lr.purpose                                                                AS listing_purpose,
    lr.district,
    lr.country,
    c.currency_code,
    lr.duration_months,
    lr.requested_amount,
    lo.offer_amount,
    lo.interest_rate_pct,
    lo.late_fee_pct,
    lo.repayment_frequency,
    lo.installment_amount,
    lo.proposed_expectations,
    lo.terms_locked_at,
    lo.status                                                                 AS offer_status,
    lo.offered_at,
    lo.accepted_at,
    ta.rating_avg                                                             AS trust_rating_avg,
    COALESCE(ta.review_count, 0)                                              AS trust_review_count,
    COALESCE(ta.completed_deals_count, 0)                                     AS trust_completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE)                                AS trust_is_repeat_participant,
    (p.phone_verified_at IS NOT NULL)                                        AS trust_phone_verified,
    ta.response_time_bucket                                                   AS trust_response_time_bucket,
    (k.status = 'approved')                                                   AS trust_is_verified,
    cr.status                                                                 AS reveal_status,
    cr.revealed_at,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.preferred_bank ELSE NULL END                                    AS preferred_bank,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.institution_type ELSE NULL END                                  AS institution_type,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.is_bank_agent ELSE FALSE END                                    AS is_bank_agent,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN TRUE ELSE FALSE END                                               AS show_professional_tag,
    lo.expires_at
FROM  public.loan_offers lo
JOIN  public.loan_requests lr ON lr.id = lo.request_id
JOIN  public.countries c ON c.code = lr.country
JOIN  public.profiles p ON p.id = lo.lender_id
LEFT  JOIN public.kyc_verifications k ON k.user_id = lo.lender_id
LEFT  JOIN public.trust_aggregates ta ON ta.user_id = lo.lender_id
LEFT  JOIN public.contact_reveals cr ON cr.offer_id = lo.id;

GRANT SELECT ON public.v_lender_offers TO authenticated, anon;

COMMIT;

-- ============================================================
-- END MERGED SECTION: patch_offer_countdown_public_offers.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_collateral_selection.sql
-- ============================================================

-- Collateral selection for loan request flow.
-- Run this in the Supabase SQL editor for an existing cloud database.

BEGIN;

ALTER TABLE public.loan_requests
    ADD COLUMN IF NOT EXISTS has_collateral BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS collateral_details TEXT,
    ADD COLUMN IF NOT EXISTS collateral_estimated_value BIGINT,
    ADD COLUMN IF NOT EXISTS collateral_location TEXT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_lr_collateral_value_positive'
          AND conrelid = 'public.loan_requests'::regclass
    ) THEN
        ALTER TABLE public.loan_requests
            ADD CONSTRAINT chk_lr_collateral_value_positive
            CHECK (
                collateral_estimated_value IS NULL
                OR collateral_estimated_value > 0
            );
    END IF;
END $$;

COMMENT ON COLUMN public.loan_requests.has_collateral IS
'Borrower-declared collateral choice. FALSE means No Collateral; TRUE means Secured.';
COMMENT ON COLUMN public.loan_requests.collateral_details IS
'Borrower-entered description of the collateral asset, shown as a marketplace risk signal.';
COMMENT ON COLUMN public.loan_requests.collateral_estimated_value IS
'Optional borrower-estimated collateral value in the listing currency.';
COMMENT ON COLUMN public.loan_requests.collateral_location IS
'Optional location of the collateral asset.';

CREATE OR REPLACE VIEW public.v_loan_listings AS
SELECT
    lr.id                                                                     AS request_id,
    lr.title,
    lr.purpose,
    lr.district,
    lr.country,
    c.currency_code,
    lr.duration_months,
    lr.requested_amount,
    lr.preferred_repayment_plan,
    lr.repayment_amount_per_period,
    lr.repayment_timeline,
    lr.suggested_interest_rate_pct,
    lr.suggested_late_fee_pct,
    lr.suggested_repayment_frequency,
    lr.suggested_installment_amount,
    lr.terms_locked_at,
    lr.status,
    lr.number_of_offers,
    CASE
        WHEN lr.number_of_offers = 0 THEN 'low'
        WHEN lr.number_of_offers <= 2 THEN 'medium'
        ELSE 'high'
    END                                                                       AS offer_coverage_tier,
    lr.listed_at,
    lr.expires_at,
    k.status                                                                  AS kyc_status,
    ta.rating_avg                                                             AS trust_rating_avg,
    COALESCE(ta.review_count, 0)                                              AS trust_review_count,
    COALESCE(ta.completed_deals_count, 0)                                     AS trust_completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE)                                AS trust_is_repeat_participant,
    (p.phone_verified_at IS NOT NULL)                                        AS trust_phone_verified,
    ta.response_time_bucket                                                   AS trust_response_time_bucket,
    (k.status = 'approved')                                                   AS trust_is_verified,
    GREATEST(lr.expires_at - NOW(), INTERVAL '0')                            AS time_remaining,
    (lr.expires_at < NOW() + INTERVAL '24 hours')                            AS closing_soon_24h,
    (lr.expires_at < NOW() + INTERVAL '6 hours')                             AS closing_soon_6h,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.preferred_bank ELSE NULL END                                    AS preferred_bank,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.institution_type ELSE NULL END                                  AS institution_type,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.is_bank_agent ELSE FALSE END                                    AS is_bank_agent,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN TRUE ELSE FALSE END                                               AS show_professional_tag,
    CASE WHEN EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN lr.has_collateral ELSE FALSE END                                  AS has_collateral,
    CASE WHEN EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN lr.collateral_details ELSE NULL END                               AS collateral_details,
    CASE WHEN EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN lr.collateral_estimated_value ELSE NULL END                       AS collateral_estimated_value,
    CASE WHEN EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN lr.collateral_location ELSE NULL END                              AS collateral_location
FROM  public.loan_requests lr
JOIN  public.profiles p ON p.id = lr.borrower_id
JOIN  public.countries c ON c.code = lr.country
LEFT  JOIN public.kyc_verifications k ON k.user_id = lr.borrower_id
LEFT  JOIN public.trust_aggregates ta ON ta.user_id = lr.borrower_id
WHERE lr.status = 'active'
  AND (
    auth.uid() IS NULL OR lr.borrower_id <> auth.uid()
  )
  AND (
    auth.uid() IS NULL OR NOT EXISTS (
      SELECT 1 FROM public.loan_offers lo
      WHERE lo.request_id = lr.id
        AND lo.lender_id = auth.uid()
        AND lo.status IN ('pending', 'accepted')
    )
  );

GRANT SELECT ON public.v_loan_listings TO authenticated, anon;

COMMIT;

-- ============================================================
-- END MERGED SECTION: patch_collateral_selection.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_seed_collateral_examples.sql
-- ============================================================

-- Demo collateral data for existing cloud loan requests.
-- Run after the Collateral Selection section in this file.
-- This makes a mixed marketplace: some requests are Secured, others have no collateral.

BEGIN;

-- Start from a clean mixed-demo baseline for active requests.
UPDATE public.loan_requests
SET
    has_collateral = FALSE,
    collateral_details = NULL,
    collateral_estimated_value = NULL,
    collateral_location = NULL,
    updated_at = CURRENT_TIMESTAMP
WHERE status = 'active';

WITH ranked AS (
    SELECT
        id,
        ROW_NUMBER() OVER (ORDER BY listed_at DESC, created_at DESC, id) AS rn
    FROM public.loan_requests
    WHERE status = 'active'
)
UPDATE public.loan_requests lr
SET
    has_collateral = TRUE,
    collateral_details = CASE (ranked.rn % 4)
        WHEN 1 THEN 'Land plot with local council ownership documents'
        WHEN 2 THEN 'Motorcycle used for delivery work'
        WHEN 3 THEN 'Shop electronics and inventory'
        ELSE 'Farming equipment and irrigation pump'
    END,
    collateral_estimated_value = CASE (ranked.rn % 4)
        WHEN 1 THEN 12000000
        WHEN 2 THEN 4500000
        WHEN 3 THEN 3000000
        ELSE 6500000
    END,
    collateral_location = CASE (ranked.rn % 4)
        WHEN 1 THEN lr.district
        WHEN 2 THEN lr.district
        WHEN 3 THEN lr.district
        ELSE lr.district
    END,
    updated_at = CURRENT_TIMESTAMP
FROM ranked
WHERE lr.id = ranked.id
  AND ranked.rn % 2 = 1;

COMMIT;

-- ============================================================
-- END MERGED SECTION: patch_seed_collateral_examples.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_loan_listing_detail_view.sql
-- ============================================================

-- Fix loan detail loading after a lender sends an offer.
-- Run this in the Supabase SQL editor.
--
-- v_loan_listings intentionally hides listings where the caller already has
-- a pending/accepted offer, so those listings disappear from the marketplace
-- feed. The detail screen still needs to load that request after offer submit,
-- so this detail-specific view keeps the same public/pro masking but does not
-- exclude participants.

BEGIN;

CREATE OR REPLACE VIEW public.v_loan_listing_details AS
SELECT
    lr.id                                                                     AS request_id,
    lr.title,
    lr.purpose,
    lr.district,
    lr.country,
    c.currency_code,
    lr.duration_months,
    lr.requested_amount,
    lr.preferred_repayment_plan,
    lr.repayment_amount_per_period,
    lr.repayment_timeline,
    lr.suggested_interest_rate_pct,
    lr.suggested_late_fee_pct,
    lr.suggested_repayment_frequency,
    lr.suggested_installment_amount,
    lr.terms_locked_at,
    lr.status,
    CASE
        WHEN auth.uid() = lr.borrower_id THEN lr.number_of_offers
        ELSE 0
    END                                                                       AS number_of_offers,
    CASE
        WHEN auth.uid() <> lr.borrower_id OR auth.uid() IS NULL THEN NULL
        WHEN lr.number_of_offers = 0 THEN 'low'
        WHEN lr.number_of_offers <= 2 THEN 'medium'
        ELSE 'high'
    END                                                                       AS offer_coverage_tier,
    lr.listed_at,
    lr.expires_at,
    k.status                                                                  AS kyc_status,
    ta.rating_avg                                                             AS trust_rating_avg,
    COALESCE(ta.review_count, 0)                                              AS trust_review_count,
    COALESCE(ta.completed_deals_count, 0)                                     AS trust_completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE)                                AS trust_is_repeat_participant,
    (p.phone_verified_at IS NOT NULL)                                        AS trust_phone_verified,
    ta.response_time_bucket                                                   AS trust_response_time_bucket,
    (k.status = 'approved')                                                   AS trust_is_verified,
    GREATEST(lr.expires_at - NOW(), INTERVAL '0')                            AS time_remaining,
    (lr.expires_at < NOW() + INTERVAL '24 hours')                            AS closing_soon_24h,
    (lr.expires_at < NOW() + INTERVAL '6 hours')                             AS closing_soon_6h,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.preferred_bank ELSE NULL END                                    AS preferred_bank,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.institution_type ELSE NULL END                                  AS institution_type,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN p.is_bank_agent ELSE FALSE END                                    AS is_bank_agent,
    CASE WHEN p.show_professional_tag AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN TRUE ELSE FALSE END                                               AS show_professional_tag,
    CASE WHEN auth.uid() = lr.borrower_id OR EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN lr.has_collateral ELSE FALSE END                                  AS has_collateral,
    CASE WHEN auth.uid() = lr.borrower_id OR EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN lr.collateral_details ELSE NULL END                               AS collateral_details,
    CASE WHEN auth.uid() = lr.borrower_id OR EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN lr.collateral_estimated_value ELSE NULL END                       AS collateral_estimated_value,
    CASE WHEN auth.uid() = lr.borrower_id OR EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
    ) THEN lr.collateral_location ELSE NULL END                              AS collateral_location
FROM  public.loan_requests lr
JOIN  public.profiles p ON p.id = lr.borrower_id
JOIN  public.countries c ON c.code = lr.country
LEFT  JOIN public.kyc_verifications k ON k.user_id = lr.borrower_id
LEFT  JOIN public.trust_aggregates ta ON ta.user_id = lr.borrower_id
WHERE lr.status = 'active';

GRANT SELECT ON public.v_loan_listing_details TO authenticated, anon;

COMMIT;

-- ============================================================
-- END MERGED SECTION: patch_loan_listing_detail_view.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_kyc_storage.sql
-- ============================================================

-- Patch: Enable storage bucket and RLS policies for KYC verification documents
-- Paste and run this script in your Supabase SQL Editor.

-- 1. Create the verification-documents storage bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'verification-documents',
  'verification-documents',
  TRUE,
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 2. Drop existing policies if any
DROP POLICY IF EXISTS "Users can upload their own KYC documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own KYC documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own KYC documents" ON storage.objects;
DROP POLICY IF EXISTS "Public read for verification documents" ON storage.objects;

-- 3. Storage RLS policies
CREATE POLICY "Users can upload their own KYC documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'verification-documents');

CREATE POLICY "Users can update their own KYC documents"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'verification-documents');

CREATE POLICY "Users can view their own KYC documents"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'verification-documents');

CREATE POLICY "Public read for verification documents"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'verification-documents');

-- ============================================================
-- END MERGED SECTION: patch_kyc_storage.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_reboot_expired_loan_requests.sql
-- ============================================================

-- Reboot expired loan requests for marketplace testing.
-- Run this in the Supabase SQL editor.
-- It reactivates expired loan requests and gives them 3 months from now.

BEGIN;

UPDATE public.loan_requests
SET
    status = 'active',
    listed_at = CURRENT_TIMESTAMP,
    expires_at = CURRENT_TIMESTAMP + INTERVAL '3 months',
    contracted_at = NULL,
    cancelled_at = NULL,
    updated_at = CURRENT_TIMESTAMP
WHERE (
        status = 'expired'
        OR (status = 'active' AND expires_at <= CURRENT_TIMESTAMP)
    )
  AND status NOT IN ('contracted', 'cancelled');

COMMIT;

-- ============================================================
-- END MERGED SECTION: patch_reboot_expired_loan_requests.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_plan_active_request_limits.sql
-- ============================================================

-- Plan-based active loan request limits.
-- Policy:
--   Free   = 2 active loan requests
--   Lender = 5 active loan requests
--   Pro    = 15 active loan requests
--
-- Only status = 'active' counts. Contracted, expired, and cancelled requests
-- free up capacity automatically.

INSERT INTO system_settings (
  setting_key,
  country,
  setting_value,
  setting_type,
  category,
  description,
  is_public
)
VALUES
  ('max_active_requests_free', NULL, '2', 'number', 'limits', 'Maximum active loan requests for Free subscribers', TRUE),
  ('max_active_requests_lender', NULL, '5', 'number', 'limits', 'Maximum active loan requests for Lender subscribers', TRUE),
  ('max_active_requests_pro', NULL, '15', 'number', 'limits', 'Maximum active loan requests for Pro subscribers', TRUE)
ON CONFLICT (setting_key, COALESCE(country, '__global__')) DO UPDATE
SET setting_value = EXCLUDED.setting_value,
    setting_type = EXCLUDED.setting_type,
    category = EXCLUDED.category,
    description = EXCLUDED.description,
    is_public = EXCLUDED.is_public,
    updated_at = NOW();

UPDATE system_settings
SET setting_value = '2',
    description = 'Legacy fallback maximum active loan requests per borrower',
    updated_at = NOW()
WHERE setting_key = 'max_concurrent_requests'
  AND country IS NULL;

CREATE OR REPLACE FUNCTION trg_fn_max_concurrent_requests()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
    v_active_count INT;
    v_max          INT;
    v_plan         subscription_plan_enum;
BEGIN
    SELECT COALESCE(s.plan, 'free'::subscription_plan_enum) INTO v_plan
    FROM profiles p
    LEFT JOIN subscriptions s
      ON s.user_id = p.id
     AND s.status = 'active'
     AND (s.expires_at IS NULL OR s.expires_at > NOW())
    WHERE p.id = NEW.borrower_id
    LIMIT 1;

    v_plan := COALESCE(v_plan, 'free'::subscription_plan_enum);

    SELECT setting_value::INT INTO v_max
    FROM system_settings
    WHERE setting_key = ('max_active_requests_' || v_plan::TEXT)
      AND (country = NEW.country OR country IS NULL)
    ORDER BY country NULLS LAST
    LIMIT 1;

    IF v_max IS NULL THEN
        SELECT setting_value::INT INTO v_max
        FROM system_settings
        WHERE setting_key = 'max_concurrent_requests'
          AND (country = NEW.country OR country IS NULL)
        ORDER BY country NULLS LAST
        LIMIT 1;
    END IF;

    v_max := COALESCE(v_max, 2);

    SELECT COUNT(*) INTO v_active_count
    FROM loan_requests
    WHERE borrower_id = NEW.borrower_id
      AND status = 'active';

    IF v_active_count >= v_max THEN
        RAISE EXCEPTION 'NIPANZE_MAX_REQUESTS: You have reached the maximum of % active listings.', v_max
            USING ERRCODE = 'P0002';
    END IF;

    RETURN NEW;
END;
$$;

-- ============================================================
-- END MERGED SECTION: patch_plan_active_request_limits.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_audit_subscriptions.sql
-- ============================================================

-- ============================================
-- PATCH: Audit triggers for subscriptions & transactions
-- Applies to: schema v5.0 (sql/schema.sql)
--
-- The audit_logs table already exists and money-relevant RPCs
-- (accept_offer, reveal_contact, unlock_contact, submit_review)
-- write to it explicitly. This patch closes the remaining gap:
-- subscription changes and transaction status transitions.
--
-- Run against the live Supabase project (SQL Editor), then verify:
--   SELECT event_type, count(*) FROM audit_logs GROUP BY 1;
-- ============================================

-- --------------------------------------------
-- 1. Subscription changes → audit_logs
--    Logs plan grants/upgrades/downgrades/expiries
--    using the existing 'subscription_changed' enum.
-- --------------------------------------------
CREATE OR REPLACE FUNCTION audit_subscription_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO audit_logs (user_id, event_type, entity_type, entity_id,
                            action, description, old_values, new_values)
    VALUES (
        NEW.user_id,
        'subscription_changed',
        'subscription',
        NEW.id,
        CASE
            WHEN TG_OP = 'INSERT' THEN 'subscription_created'
            WHEN OLD.status = 'active' AND NEW.status <> 'active' THEN 'subscription_ended'
            WHEN OLD.plan IS DISTINCT FROM NEW.plan THEN 'plan_changed'
            ELSE 'subscription_updated'
        END,
        CASE WHEN TG_OP = 'INSERT'
             THEN format('subscription created: plan=%s status=%s', NEW.plan, NEW.status)
             ELSE format('subscription updated: plan %s -> %s, status %s -> %s',
                         OLD.plan, NEW.plan, OLD.status, NEW.status)
        END,
        CASE WHEN TG_OP = 'INSERT' THEN NULL
             ELSE jsonb_build_object('plan', OLD.plan, 'status', OLD.status,
                                     'expires_at', OLD.expires_at,
                                     'amount_minor_units', OLD.amount_minor_units)
        END,
        jsonb_build_object('plan', NEW.plan, 'status', NEW.status,
                           'expires_at', NEW.expires_at,
                           'amount_minor_units', NEW.amount_minor_units,
                           'auto_renew', NEW.auto_renew)
    );
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_subscription ON subscriptions;
CREATE TRIGGER trg_audit_subscription
    AFTER INSERT OR UPDATE ON subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION audit_subscription_change();

-- --------------------------------------------
-- 2. Transaction status transitions → audit_logs
--    Money trail: pending -> successful/failed/reversed,
--    using the existing 'transaction_completed' enum.
--    Only logs when the status actually changes, so
--    idempotent webhook replays don't duplicate rows.
-- --------------------------------------------
CREATE OR REPLACE FUNCTION audit_transaction_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Only audit meaningful transitions (INSERT, or a real status change)
    IF TG_OP = 'UPDATE' AND OLD.status = NEW.status THEN
        RETURN NEW;
    END IF;

    INSERT INTO audit_logs (user_id, event_type, entity_type, entity_id,
                            action, description, old_values, new_values)
    VALUES (
        NEW.user_id,
        'transaction_completed',
        'transaction',
        NEW.id,
        CASE WHEN TG_OP = 'INSERT' THEN 'transaction_initiated'
             ELSE format('transaction_%s', NEW.status)
        END,
        format('tx %s (%s %s %s, ref=%s): %s -> %s',
               NEW.type, NEW.amount, NEW.currency_code, NEW.provider,
               NEW.provider_tx_ref,
               CASE WHEN TG_OP = 'INSERT' THEN 'none' ELSE OLD.status END,
               NEW.status),
        CASE WHEN TG_OP = 'INSERT' THEN NULL
             ELSE jsonb_build_object('status', OLD.status,
                                     'provider_tx_id', OLD.provider_tx_id,
                                     'webhook_verified_at', OLD.webhook_verified_at)
        END,
        jsonb_build_object('status', NEW.status,
                           'provider_tx_id', NEW.provider_tx_id,
                           'provider_tx_ref', NEW.provider_tx_ref,
                           'webhook_verified_at', NEW.webhook_verified_at)
    );
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_transaction ON transactions;
CREATE TRIGGER trg_audit_transaction
    AFTER INSERT OR UPDATE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION audit_transaction_change();


-- ============================================================
-- END MERGED SECTION: patch_audit_subscriptions.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_v4.2_referral_system_full.sql
-- ============================================================

-- ==============================================================================
-- NIPANZE REFERRAL & MARKETER AGENT SYSTEM - CONSOLIDATED PATCH (v4.2)
-- ==============================================================================
-- Idempotent standalone SQL patch. Run directly in Supabase SQL Editor.
-- Safe to execute repeatedly without errors or duplicate constraints.
-- ==============================================================================

-- 1. TABLES & STRUCTURES
--------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.referral_campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    country TEXT REFERENCES public.countries(code),
    start_date DATE,
    end_date DATE,
    status TEXT NOT NULL DEFAULT 'draft',
    qualification_event TEXT NOT NULL DEFAULT 'verified_referral',
    reward_type TEXT NOT NULL DEFAULT 'fixed',
    reward_amount BIGINT NOT NULL DEFAULT 0,
    reward_currency TEXT NOT NULL DEFAULT 'UGX',
    max_reward_per_referral BIGINT,
    campaign_budget BIGINT,
    max_referrals INTEGER,
    eligible_plans TEXT[] NOT NULL DEFAULT ARRAY['free','lender','pro']::TEXT[],
    terms TEXT,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.referral_marketers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    referral_code TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'active',
    default_campaign_id UUID REFERENCES public.referral_campaigns(id) ON DELETE SET NULL,
    joined_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_activity_at TIMESTAMP,
    risk_status TEXT NOT NULL DEFAULT 'clear',
    risk_reason TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.referrals
    ADD COLUMN IF NOT EXISTS campaign_id UUID REFERENCES public.referral_campaigns(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS referral_code TEXT,
    ADD COLUMN IF NOT EXISTS source TEXT,
    ADD COLUMN IF NOT EXISTS country TEXT REFERENCES public.countries(code),
    ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'registered',
    ADD COLUMN IF NOT EXISTS registered_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS verified_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS qualifying_event TEXT,
    ADD COLUMN IF NOT EXISTS qualified_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS reward_amount BIGINT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS reward_currency TEXT,
    ADD COLUMN IF NOT EXISTS reward_status TEXT NOT NULL DEFAULT 'none',
    ADD COLUMN IF NOT EXISTS payout_status TEXT NOT NULL DEFAULT 'none',
    ADD COLUMN IF NOT EXISTS fraud_status TEXT NOT NULL DEFAULT 'clear',
    ADD COLUMN IF NOT EXISTS fraud_reason TEXT,
    ADD COLUMN IF NOT EXISTS metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS referral_code TEXT UNIQUE,
    ADD COLUMN IF NOT EXISTS referred_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS referral_status TEXT NOT NULL DEFAULT 'none',
    ADD COLUMN IF NOT EXISTS marketing_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS marketing_country TEXT REFERENCES public.countries(code),
    ADD COLUMN IF NOT EXISTS marketing_joined_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS referred_at TIMESTAMP;

CREATE TABLE IF NOT EXISTS public.referral_rewards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    marketer_id UUID NOT NULL REFERENCES public.referral_marketers(id) ON DELETE CASCADE,
    referral_id UUID REFERENCES public.referrals(id) ON DELETE SET NULL,
    campaign_id UUID REFERENCES public.referral_campaigns(id) ON DELETE SET NULL,
    referred_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    reward_type TEXT NOT NULL DEFAULT 'fixed',
    amount BIGINT NOT NULL DEFAULT 0,
    currency TEXT NOT NULL DEFAULT 'UGX',
    status TEXT NOT NULL DEFAULT 'pending',
    reason TEXT,
    approved_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    approved_at TIMESTAMP,
    rejected_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    rejected_at TIMESTAMP,
    paid_at TIMESTAMP,
    campaign_reward_snapshot JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.referral_payouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    marketer_id UUID NOT NULL REFERENCES public.referral_marketers(id) ON DELETE CASCADE,
    amount BIGINT NOT NULL DEFAULT 0,
    currency TEXT NOT NULL DEFAULT 'UGX',
    payout_method TEXT,
    payout_destination_ref TEXT,
    status TEXT NOT NULL DEFAULT 'requested',
    failure_reason TEXT,
    requested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    approved_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    approved_at TIMESTAMP,
    completed_at TIMESTAMP,
    metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. CONSTRAINTS & INDEXES
--------------------------------------------------------------------------------

ALTER TABLE public.referrals DROP CONSTRAINT IF EXISTS chk_referrals_status;
ALTER TABLE public.referrals
    ADD CONSTRAINT chk_referrals_status CHECK (status IN ('clicked', 'registered', 'verified', 'qualified', 'reward_pending', 'reward_earned', 'paid', 'rejected', 'fraud_flagged', 'fraud_hold', 'cancelled'));

ALTER TABLE public.referrals DROP CONSTRAINT IF EXISTS chk_referrals_reward_status;
ALTER TABLE public.referrals
    ADD CONSTRAINT chk_referrals_reward_status CHECK (reward_status IN ('none', 'pending', 'earned', 'approved', 'rejected', 'paid', 'cancelled', 'fraud_hold'));

ALTER TABLE public.referrals DROP CONSTRAINT IF EXISTS chk_referrals_payout_status;
ALTER TABLE public.referrals
    ADD CONSTRAINT chk_referrals_payout_status CHECK (payout_status IN ('none', 'requested', 'under_review', 'approved', 'processing', 'paid', 'failed', 'cancelled'));

ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS chk_profiles_referral_status;
ALTER TABLE public.profiles
    ADD CONSTRAINT chk_profiles_referral_status CHECK (referral_status IN ('none', 'registered', 'verified', 'qualified', 'rejected', 'fraud_flagged', 'cancelled'));

CREATE INDEX IF NOT EXISTS idx_referrals_referred_user ON public.referrals(referred_user_id);
CREATE UNIQUE INDEX IF NOT EXISTS uidx_referrals_referred_user_once
    ON public.referrals(referred_user_id)
    WHERE referred_user_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uidx_referral_rewards_once_per_campaign
    ON public.referral_rewards(referral_id, campaign_id)
    WHERE referral_id IS NOT NULL AND campaign_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_profiles_referral_code ON public.profiles(referral_code);
CREATE INDEX IF NOT EXISTS idx_profiles_referred_by ON public.profiles(referred_by);

-- 3. NOTIFICATION TYPES ENUM
--------------------------------------------------------------------------------

DO $$
BEGIN
    ALTER TYPE public.notification_type_enum ADD VALUE IF NOT EXISTS 'referral_registered';
    ALTER TYPE public.notification_type_enum ADD VALUE IF NOT EXISTS 'referral_verified';
    ALTER TYPE public.notification_type_enum ADD VALUE IF NOT EXISTS 'referral_qualified';
    ALTER TYPE public.notification_type_enum ADD VALUE IF NOT EXISTS 'referral_reward_available';
    ALTER TYPE public.notification_type_enum ADD VALUE IF NOT EXISTS 'referral_reward_approved';
    ALTER TYPE public.notification_type_enum ADD VALUE IF NOT EXISTS 'referral_reward_paid';
    ALTER TYPE public.notification_type_enum ADD VALUE IF NOT EXISTS 'referral_reward_rejected';
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- 4. RLS POLICIES
--------------------------------------------------------------------------------

ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referral_marketers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referral_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referral_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referral_payouts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "referrals: own participant or admin read" ON public.referrals;
CREATE POLICY "referrals: own participant or admin read" ON public.referrals
    FOR SELECT TO authenticated
    USING (referrer_id = auth.uid() OR referred_user_id = auth.uid() OR private.is_admin());

DROP POLICY IF EXISTS "referrals: admin write" ON public.referrals;
CREATE POLICY "referrals: admin write" ON public.referrals
    FOR ALL TO authenticated USING (private.is_admin()) WITH CHECK (private.is_admin());

DROP POLICY IF EXISTS "referral_marketers: own or admin read" ON public.referral_marketers;
CREATE POLICY "referral_marketers: own or admin read" ON public.referral_marketers
    FOR SELECT TO authenticated
    USING (profile_id = auth.uid() OR private.is_admin());

DROP POLICY IF EXISTS "referral_campaigns: view active" ON public.referral_campaigns;
CREATE POLICY "referral_campaigns: view active" ON public.referral_campaigns
    FOR SELECT TO authenticated
    USING (status = 'active' OR private.is_admin());

DROP POLICY IF EXISTS "referral_rewards: own or admin read" ON public.referral_rewards;
CREATE POLICY "referral_rewards: own or admin read" ON public.referral_rewards
    FOR SELECT TO authenticated
    USING (referred_user_id = auth.uid() OR marketer_id IN (SELECT id FROM public.referral_marketers WHERE profile_id = auth.uid()) OR private.is_admin());

-- 5. RPC & HELPER FUNCTIONS
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION private.generate_referral_code(p_full_name TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_seed TEXT;
    v_code TEXT;
BEGIN
    v_seed := UPPER(REGEXP_REPLACE(COALESCE(NULLIF(SPLIT_PART(TRIM(p_full_name), ' ', 1), ''), 'USER'), '[^A-Z0-9]', '', 'g'));
    v_seed := LEFT(COALESCE(NULLIF(v_seed, ''), 'USER'), 5);

    LOOP
        v_code := v_seed || SUBSTRING(REPLACE(gen_random_uuid()::TEXT, '-', '') FROM 1 FOR 4);
        EXIT WHEN NOT EXISTS (
            SELECT 1 FROM public.referral_marketers WHERE UPPER(referral_code) = UPPER(v_code)
        ) AND NOT EXISTS (
            SELECT 1 FROM public.profiles WHERE UPPER(referral_code) = UPPER(v_code)
        );
    END LOOP;

    RETURN v_code;
END;
$$;

CREATE OR REPLACE FUNCTION public.ensure_my_referral_marketer(p_country TEXT DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_profile public.profiles%ROWTYPE;
    v_marketer public.referral_marketers%ROWTYPE;
    v_campaign_id UUID;
    v_country TEXT;
    v_code TEXT;
BEGIN
    -- Auto-heal missing profile if not created yet
    SELECT * INTO v_profile FROM public.profiles WHERE id = auth.uid();
    IF NOT FOUND THEN
        INSERT INTO public.profiles (id, email, full_name, account_status)
        VALUES (
            auth.uid(),
            COALESCE((SELECT email FROM auth.users WHERE id = auth.uid()), 'user@nipanze.app'),
            'Nipanze User',
            'active'
        )
        ON CONFLICT (id) DO NOTHING;

        SELECT * INTO v_profile FROM public.profiles WHERE id = auth.uid();
    END IF;

    v_country := UPPER(COALESCE(NULLIF(p_country, ''), v_profile.country, 'UG'));
    IF NOT EXISTS (SELECT 1 FROM public.countries WHERE code = v_country) THEN
        v_country := v_profile.country;
    END IF;

    SELECT id INTO v_campaign_id
    FROM public.referral_campaigns
    WHERE status = 'active'
      AND (country IS NULL OR country = v_country)
      AND (start_date IS NULL OR start_date <= CURRENT_DATE)
      AND (end_date IS NULL OR end_date >= CURRENT_DATE)
    ORDER BY country NULLS LAST, created_at DESC
    LIMIT 1;

    SELECT * INTO v_marketer
    FROM public.referral_marketers
    WHERE profile_id = v_profile.id;

    IF NOT FOUND THEN
        v_code := COALESCE(v_profile.referral_code, private.generate_referral_code(v_profile.full_name));
        INSERT INTO public.referral_marketers (
            profile_id, referral_code, status, default_campaign_id,
            joined_at, last_activity_at, metadata
        )
        VALUES (
            v_profile.id, v_code, 'active', v_campaign_id,
            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, '{}'::JSONB
        )
        RETURNING * INTO v_marketer;
    ELSE
        v_code := v_marketer.referral_code;
        UPDATE public.referral_marketers
        SET default_campaign_id = COALESCE(default_campaign_id, v_campaign_id),
            last_activity_at = CURRENT_TIMESTAMP,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = v_marketer.id
        RETURNING * INTO v_marketer;
    END IF;

    UPDATE public.profiles
    SET referral_code = COALESCE(referral_code, v_code),
        marketing_enabled = TRUE,
        marketing_country = COALESCE(marketing_country, v_country),
        marketing_joined_at = COALESCE(marketing_joined_at, CURRENT_TIMESTAMP),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = v_profile.id
    RETURNING * INTO v_profile;

    RETURN jsonb_build_object(
        'marketer_id', v_marketer.id,
        'user_id', v_profile.id,
        'referral_code', v_marketer.referral_code,
        'referral_link', 'https://nipanze.app/r/' || v_marketer.referral_code,
        'status', v_marketer.status,
        'marketing_enabled', v_profile.marketing_enabled,
        'marketing_country', v_profile.marketing_country,
        'joined_at', v_marketer.joined_at
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.ensure_my_referral_marketer(TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.attribute_my_referral(
    p_referral_code TEXT,
    p_source TEXT DEFAULT 'registration'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_code TEXT;
    v_source TEXT;
    v_user public.profiles%ROWTYPE;
    v_referrer_id UUID;
    v_marketer_id UUID;
    v_campaign_id UUID;
    v_referral_id UUID;
    v_referred_email TEXT;
BEGIN
    v_code := UPPER(TRIM(COALESCE(p_referral_code, '')));
    IF v_code = '' THEN
        RETURN jsonb_build_object('attributed', FALSE, 'reason', 'missing_code');
    END IF;

    SELECT * INTO v_user FROM public.profiles WHERE id = auth.uid();
    IF NOT FOUND THEN
        RETURN jsonb_build_object('attributed', FALSE, 'reason', 'profile_missing');
    END IF;

    IF v_user.referred_by IS NOT NULL THEN
        RETURN jsonb_build_object('attributed', FALSE, 'reason', 'already_attributed');
    END IF;

    SELECT rm.profile_id, rm.id, rm.default_campaign_id
    INTO v_referrer_id, v_marketer_id, v_campaign_id
    FROM public.referral_marketers rm
    WHERE UPPER(rm.referral_code) = v_code
      AND rm.status IN ('new', 'active')
    LIMIT 1;

    IF v_referrer_id IS NULL THEN
        SELECT p.id INTO v_referrer_id
        FROM public.profiles p
        WHERE UPPER(p.referral_code) = v_code
        LIMIT 1;

        IF v_referrer_id IS NOT NULL THEN
            SELECT rm.id, rm.default_campaign_id
            INTO v_marketer_id, v_campaign_id
            FROM public.referral_marketers rm
            WHERE rm.profile_id = v_referrer_id
            LIMIT 1;

            IF v_marketer_id IS NULL THEN
                INSERT INTO public.referral_marketers (
                    profile_id, referral_code, status, joined_at, last_activity_at
                )
                VALUES (v_referrer_id, v_code, 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                RETURNING id, default_campaign_id INTO v_marketer_id, v_campaign_id;
            END IF;
        END IF;
    END IF;

    IF v_referrer_id IS NULL THEN
        RETURN jsonb_build_object('attributed', FALSE, 'reason', 'code_not_found');
    END IF;

    IF v_referrer_id = v_user.id THEN
        RETURN jsonb_build_object('attributed', FALSE, 'reason', 'self_referral');
    END IF;

    IF EXISTS (SELECT 1 FROM public.referrals WHERE referred_user_id = v_user.id) THEN
        RETURN jsonb_build_object('attributed', FALSE, 'reason', 'already_recorded');
    END IF;

    IF v_campaign_id IS NULL THEN
        SELECT id INTO v_campaign_id
        FROM public.referral_campaigns
        WHERE status = 'active'
          AND (country IS NULL OR country = v_user.country)
          AND (start_date IS NULL OR start_date <= CURRENT_DATE)
          AND (end_date IS NULL OR end_date >= CURRENT_DATE)
        ORDER BY country NULLS LAST, created_at DESC
        LIMIT 1;
    END IF;

    SELECT email INTO v_referred_email FROM auth.users WHERE id = v_user.id;
    v_source := COALESCE(NULLIF(TRIM(p_source), ''), 'registration');

    INSERT INTO public.referrals (
        referrer_id, referred_email, referred_user_id, code, referral_code,
        campaign_id, source, country, status, registered_at, metadata
    )
    VALUES (
        v_referrer_id,
        COALESCE(v_referred_email, v_user.phone, v_user.id::TEXT),
        v_user.id,
        'ATTR-' || SUBSTRING(REPLACE(uuid_generate_v4()::TEXT, '-', '') FROM 1 FOR 12),
        v_code,
        v_campaign_id,
        v_source,
        v_user.country,
        'registered',
        CURRENT_TIMESTAMP,
        jsonb_build_object('attributed_by', 'attribute_my_referral')
    )
    RETURNING id INTO v_referral_id;

    UPDATE public.profiles
    SET referred_by = v_referrer_id,
        referral_status = 'registered',
        referred_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = v_user.id
      AND referred_by IS NULL;

    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
        v_referrer_id,
        'system',
        'New referral registered',
        COALESCE(NULLIF(v_user.full_name, ''), 'Someone') || ' joined Nipanze using your referral code.',
        jsonb_build_object('notification_kind', 'referral_registered', 'referral_id', v_referral_id, 'referred_user_id', v_user.id)
    );

    RETURN jsonb_build_object('attributed', TRUE, 'referral_id', v_referral_id);
EXCEPTION
    WHEN unique_violation THEN
        RETURN jsonb_build_object('attributed', FALSE, 'reason', 'already_recorded');
END;
$$;

GRANT EXECUTE ON FUNCTION public.attribute_my_referral(TEXT, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_my_referral_dashboard()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_marketer JSONB;
    v_profile_id UUID;
    v_summary JSONB;
    v_history JSONB;
    v_default_currency TEXT;
BEGIN
    v_marketer := public.ensure_my_referral_marketer(NULL);
    v_profile_id := auth.uid();

    SELECT COALESCE(c.currency_code, 'UGX') INTO v_default_currency
    FROM public.profiles p
    LEFT JOIN public.countries c ON c.code = COALESCE(p.country, p.marketing_country, 'UG')
    WHERE p.id = v_profile_id;
    v_default_currency := COALESCE(v_default_currency, 'UGX');

    SELECT jsonb_build_object(
        'total_referrals', COUNT(*)::INT,
        'registered', COUNT(*) FILTER (WHERE r.status = 'registered')::INT,
        'verified', COUNT(*) FILTER (WHERE r.status = 'verified')::INT,
        'qualified', COUNT(*) FILTER (WHERE r.status IN ('qualified', 'reward_pending', 'reward_earned', 'paid'))::INT,
        'pending_rewards', COALESCE(SUM(rr.amount) FILTER (WHERE rr.status = 'pending'), 0),
        'available_rewards', COALESCE(SUM(rr.amount) FILTER (WHERE rr.status = 'approved'), 0),
        'paid_rewards', COALESCE(SUM(rr.amount) FILTER (WHERE rr.status = 'paid'), 0),
        'total_earned', COALESCE(SUM(rr.amount) FILTER (WHERE rr.status IN ('pending', 'approved', 'paid')), 0),
        'total_paid', COALESCE(SUM(rr.amount) FILTER (WHERE rr.status = 'paid'), 0),
        'currency', COALESCE(MAX(rr.currency), MAX(r.reward_currency), v_default_currency)
    )
    INTO v_summary
    FROM public.referrals r
    LEFT JOIN public.referral_rewards rr ON rr.referral_id = r.id
    WHERE r.referrer_id = v_profile_id;

    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'id', r.id,
            'display_name', COALESCE(NULLIF(SPLIT_PART(TRIM(p.full_name), ' ', 1), ''), 'Nipanze user'),
            'registered_at', COALESCE(r.registered_at, r.created_at),
            'status', r.status,
            'qualification_status', CASE WHEN r.qualified_at IS NULL THEN 'pending' ELSE 'qualified' END,
            'reward_amount', COALESCE(rr.amount, r.reward_amount, 0),
            'reward_currency', COALESCE(rr.currency, r.reward_currency, c.reward_currency, 'UGX'),
            'reward_status', COALESCE(rr.status, r.reward_status, 'none'),
            'payout_status', r.payout_status,
            'source', r.source
        )
        ORDER BY COALESCE(r.registered_at, r.created_at) DESC
    ), '[]'::JSONB)
    INTO v_history
    FROM public.referrals r
    LEFT JOIN public.profiles p ON p.id = r.referred_user_id
    LEFT JOIN public.referral_campaigns c ON c.id = r.campaign_id
    LEFT JOIN public.referral_rewards rr ON rr.referral_id = r.id
    WHERE r.referrer_id = v_profile_id;

    RETURN jsonb_build_object(
        'marketer', COALESCE(v_marketer, '{}'::JSONB),
        'summary', COALESCE(v_summary, '{}'::JSONB),
        'history', COALESCE(v_history, '[]'::JSONB)
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_referral_dashboard() TO authenticated;


-- ============================================================
-- END MERGED SECTION: patch_v4.2_referral_system_full.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_referral_agent_system.sql
-- ============================================================

-- Nipanze Referral & Marketer/Referral Agent System
-- Standalone additive patch. Run after schema.sql and patch_marketer_department.sql.
-- Keeps marketer rewards separate from P2P loan and forex funds.

ALTER TABLE public.referrals
    ADD COLUMN IF NOT EXISTS campaign_id UUID REFERENCES public.referral_campaigns(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS referral_code TEXT,
    ADD COLUMN IF NOT EXISTS source TEXT,
    ADD COLUMN IF NOT EXISTS country TEXT REFERENCES public.countries(code),
    ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'registered',
    ADD COLUMN IF NOT EXISTS registered_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS verified_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS qualifying_event TEXT,
    ADD COLUMN IF NOT EXISTS qualified_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS reward_amount BIGINT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS reward_currency TEXT,
    ADD COLUMN IF NOT EXISTS reward_status TEXT NOT NULL DEFAULT 'none',
    ADD COLUMN IF NOT EXISTS payout_status TEXT NOT NULL DEFAULT 'none',
    ADD COLUMN IF NOT EXISTS fraud_status TEXT NOT NULL DEFAULT 'clear',
    ADD COLUMN IF NOT EXISTS fraud_reason TEXT,
    ADD COLUMN IF NOT EXISTS metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS referral_code TEXT UNIQUE,
    ADD COLUMN IF NOT EXISTS referred_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS referral_status TEXT NOT NULL DEFAULT 'none',
    ADD COLUMN IF NOT EXISTS marketing_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS marketing_country TEXT REFERENCES public.countries(code),
    ADD COLUMN IF NOT EXISTS marketing_joined_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS referred_at TIMESTAMP;

ALTER TABLE public.referrals DROP CONSTRAINT IF EXISTS chk_referrals_status;
ALTER TABLE public.referrals
    ADD CONSTRAINT chk_referrals_status CHECK (status IN ('clicked', 'registered', 'verified', 'qualified', 'reward_pending', 'reward_earned', 'paid', 'rejected', 'fraud_flagged', 'fraud_hold', 'cancelled'));
ALTER TABLE public.referrals DROP CONSTRAINT IF EXISTS chk_referrals_reward_status;
ALTER TABLE public.referrals
    ADD CONSTRAINT chk_referrals_reward_status CHECK (reward_status IN ('none', 'pending', 'earned', 'approved', 'rejected', 'paid', 'cancelled', 'fraud_hold'));
ALTER TABLE public.referrals DROP CONSTRAINT IF EXISTS chk_referrals_payout_status;
ALTER TABLE public.referrals
    ADD CONSTRAINT chk_referrals_payout_status CHECK (payout_status IN ('none', 'requested', 'under_review', 'approved', 'processing', 'paid', 'failed', 'cancelled'));
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS chk_profiles_referral_status;
ALTER TABLE public.profiles
    ADD CONSTRAINT chk_profiles_referral_status CHECK (referral_status IN ('none', 'registered', 'verified', 'qualified', 'rejected', 'fraud_flagged', 'cancelled'));

CREATE INDEX IF NOT EXISTS idx_referrals_referred_user ON public.referrals(referred_user_id);
CREATE UNIQUE INDEX IF NOT EXISTS uidx_referrals_referred_user_once
    ON public.referrals(referred_user_id)
    WHERE referred_user_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uidx_referral_rewards_once_per_campaign
    ON public.referral_rewards(referral_id, campaign_id)
    WHERE referral_id IS NOT NULL AND campaign_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_referral_code ON public.profiles(referral_code);
CREATE INDEX IF NOT EXISTS idx_profiles_referred_by ON public.profiles(referred_by);

DO $$
BEGIN
    ALTER TYPE public.notification_type_enum ADD VALUE IF NOT EXISTS 'referral_registered';
    ALTER TYPE public.notification_type_enum ADD VALUE IF NOT EXISTS 'referral_verified';
    ALTER TYPE public.notification_type_enum ADD VALUE IF NOT EXISTS 'referral_qualified';
    ALTER TYPE public.notification_type_enum ADD VALUE IF NOT EXISTS 'referral_reward_available';
    ALTER TYPE public.notification_type_enum ADD VALUE IF NOT EXISTS 'referral_reward_approved';
    ALTER TYPE public.notification_type_enum ADD VALUE IF NOT EXISTS 'referral_reward_paid';
    ALTER TYPE public.notification_type_enum ADD VALUE IF NOT EXISTS 'referral_reward_rejected';
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DROP POLICY IF EXISTS "referrals: own insert" ON public.referrals;
DROP POLICY IF EXISTS "referrals: own or admin read" ON public.referrals;
DROP POLICY IF EXISTS "referrals: own participant or admin read" ON public.referrals;
CREATE POLICY "referrals: own participant or admin read" ON public.referrals
    FOR SELECT TO authenticated
    USING (referrer_id = auth.uid() OR referred_user_id = auth.uid() OR private.is_admin());
DROP POLICY IF EXISTS "referrals: admin write" ON public.referrals;
CREATE POLICY "referrals: admin write" ON public.referrals
    FOR ALL TO authenticated USING (private.is_admin()) WITH CHECK (private.is_admin());

CREATE OR REPLACE FUNCTION private.generate_referral_code(p_full_name TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_seed TEXT;
    v_code TEXT;
BEGIN
    v_seed := UPPER(REGEXP_REPLACE(COALESCE(NULLIF(SPLIT_PART(TRIM(p_full_name), ' ', 1), ''), 'USER'), '[^A-Z0-9]', '', 'g'));
    v_seed := LEFT(COALESCE(NULLIF(v_seed, ''), 'USER'), 5);

    LOOP
        v_code := 'NIPANZE-' || v_seed || SUBSTRING(REPLACE(uuid_generate_v4()::TEXT, '-', '') FROM 1 FOR 4);
        EXIT WHEN NOT EXISTS (
            SELECT 1 FROM public.referral_marketers WHERE referral_code = v_code
        ) AND NOT EXISTS (
            SELECT 1 FROM public.profiles WHERE referral_code = v_code
        );
    END LOOP;

    RETURN v_code;
END;
$$;

CREATE OR REPLACE FUNCTION public.ensure_my_referral_marketer(p_country TEXT DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_profile public.profiles%ROWTYPE;
    v_marketer public.referral_marketers%ROWTYPE;
    v_campaign_id UUID;
    v_country TEXT;
    v_code TEXT;
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = auth.uid();
    IF NOT FOUND THEN
        INSERT INTO public.profiles (id, email, full_name, account_status)
        VALUES (
            auth.uid(),
            COALESCE((SELECT email FROM auth.users WHERE id = auth.uid()), 'user@nipanze.app'),
            'Nipanze User',
            'active'
        )
        ON CONFLICT (id) DO NOTHING;

        SELECT * INTO v_profile FROM public.profiles WHERE id = auth.uid();
    END IF;

    v_country := UPPER(COALESCE(NULLIF(p_country, ''), v_profile.country, 'UG'));
    IF NOT EXISTS (SELECT 1 FROM public.countries WHERE code = v_country) THEN
        v_country := v_profile.country;
    END IF;

    SELECT id INTO v_campaign_id
    FROM public.referral_campaigns
    WHERE status = 'active'
      AND (country IS NULL OR country = v_country)
      AND (start_date IS NULL OR start_date <= CURRENT_DATE)
      AND (end_date IS NULL OR end_date >= CURRENT_DATE)
    ORDER BY country NULLS LAST, created_at DESC
    LIMIT 1;

    SELECT * INTO v_marketer
    FROM public.referral_marketers
    WHERE profile_id = v_profile.id;

    IF NOT FOUND THEN
        v_code := COALESCE(v_profile.referral_code, private.generate_referral_code(v_profile.full_name));
        INSERT INTO public.referral_marketers (
            profile_id, referral_code, status, default_campaign_id,
            joined_at, last_activity_at, metadata
        )
        VALUES (
            v_profile.id, v_code, 'active', v_campaign_id,
            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, '{}'::JSONB
        )
        RETURNING * INTO v_marketer;
    ELSE
        v_code := v_marketer.referral_code;
        UPDATE public.referral_marketers
        SET default_campaign_id = COALESCE(default_campaign_id, v_campaign_id),
            last_activity_at = CURRENT_TIMESTAMP,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = v_marketer.id
        RETURNING * INTO v_marketer;
    END IF;

    UPDATE public.profiles
    SET referral_code = COALESCE(referral_code, v_code),
        marketing_enabled = TRUE,
        marketing_country = COALESCE(marketing_country, v_country),
        marketing_joined_at = COALESCE(marketing_joined_at, CURRENT_TIMESTAMP),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = v_profile.id
    RETURNING * INTO v_profile;

    RETURN jsonb_build_object(
        'marketer_id', v_marketer.id,
        'user_id', v_profile.id,
        'referral_code', v_marketer.referral_code,
        'referral_link', 'https://nipanze.app/r/' || v_marketer.referral_code,
        'status', v_marketer.status,
        'marketing_enabled', v_profile.marketing_enabled,
        'marketing_country', v_profile.marketing_country,
        'joined_at', v_marketer.joined_at
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.ensure_my_referral_marketer(TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.attribute_my_referral(
    p_referral_code TEXT,
    p_source TEXT DEFAULT 'registration'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_code TEXT;
    v_source TEXT;
    v_user public.profiles%ROWTYPE;
    v_referrer_id UUID;
    v_marketer_id UUID;
    v_campaign_id UUID;
    v_referral_id UUID;
    v_referred_email TEXT;
BEGIN
    v_code := UPPER(TRIM(COALESCE(p_referral_code, '')));
    IF v_code = '' THEN
        RETURN jsonb_build_object('attributed', FALSE, 'reason', 'missing_code');
    END IF;

    SELECT * INTO v_user FROM public.profiles WHERE id = auth.uid();
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Profile not found';
    END IF;

    IF v_user.referred_by IS NOT NULL THEN
        RETURN jsonb_build_object('attributed', FALSE, 'reason', 'already_attributed');
    END IF;

    SELECT rm.profile_id, rm.id, rm.default_campaign_id
    INTO v_referrer_id, v_marketer_id, v_campaign_id
    FROM public.referral_marketers rm
    WHERE UPPER(rm.referral_code) = v_code
      AND rm.status IN ('new', 'active')
    LIMIT 1;

    IF v_referrer_id IS NULL THEN
        SELECT p.id INTO v_referrer_id
        FROM public.profiles p
        WHERE UPPER(p.referral_code) = v_code
        LIMIT 1;

        IF v_referrer_id IS NOT NULL THEN
            SELECT rm.id, rm.default_campaign_id
            INTO v_marketer_id, v_campaign_id
            FROM public.referral_marketers rm
            WHERE rm.profile_id = v_referrer_id
            LIMIT 1;

            IF v_marketer_id IS NULL THEN
                INSERT INTO public.referral_marketers (
                    profile_id, referral_code, status, joined_at, last_activity_at
                )
                VALUES (v_referrer_id, v_code, 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                RETURNING id, default_campaign_id INTO v_marketer_id, v_campaign_id;
            END IF;
        END IF;
    END IF;

    IF v_referrer_id IS NULL THEN
        RETURN jsonb_build_object('attributed', FALSE, 'reason', 'code_not_found');
    END IF;

    IF v_referrer_id = v_user.id THEN
        RETURN jsonb_build_object('attributed', FALSE, 'reason', 'self_referral');
    END IF;

    IF EXISTS (SELECT 1 FROM public.referrals WHERE referred_user_id = v_user.id) THEN
        RETURN jsonb_build_object('attributed', FALSE, 'reason', 'already_recorded');
    END IF;

    IF v_campaign_id IS NULL THEN
        SELECT id INTO v_campaign_id
        FROM public.referral_campaigns
        WHERE status = 'active'
          AND (country IS NULL OR country = v_user.country)
          AND (start_date IS NULL OR start_date <= CURRENT_DATE)
          AND (end_date IS NULL OR end_date >= CURRENT_DATE)
        ORDER BY country NULLS LAST, created_at DESC
        LIMIT 1;
    END IF;

    SELECT email INTO v_referred_email FROM auth.users WHERE id = v_user.id;
    v_source := COALESCE(NULLIF(TRIM(p_source), ''), 'registration');

    INSERT INTO public.referrals (
        referrer_id, referred_email, referred_user_id, code, referral_code,
        campaign_id, source, country, status, registered_at, metadata
    )
    VALUES (
        v_referrer_id,
        COALESCE(v_referred_email, v_user.phone, v_user.id::TEXT),
        v_user.id,
        'ATTR-' || SUBSTRING(REPLACE(uuid_generate_v4()::TEXT, '-', '') FROM 1 FOR 12),
        v_code,
        v_campaign_id,
        v_source,
        v_user.country,
        'registered',
        CURRENT_TIMESTAMP,
        jsonb_build_object('attributed_by', 'attribute_my_referral')
    )
    RETURNING id INTO v_referral_id;

    UPDATE public.profiles
    SET referred_by = v_referrer_id,
        referral_status = 'registered',
        referred_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = v_user.id
      AND referred_by IS NULL;

    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
        v_referrer_id,
        'system',
        'New referral registered',
        COALESCE(NULLIF(v_user.full_name, ''), 'Someone') || ' joined Nipanze using your referral code.',
        jsonb_build_object('notification_kind', 'referral_registered', 'referral_id', v_referral_id, 'referred_user_id', v_user.id)
    );

    INSERT INTO public.audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
    VALUES (
        v_user.id,
        'register',
        'referrals',
        v_referral_id,
        'referral_attributed',
        jsonb_build_object('referrer_id', v_referrer_id, 'referral_code', v_code, 'source', v_source)
    );

    RETURN jsonb_build_object('attributed', TRUE, 'referral_id', v_referral_id);
EXCEPTION
    WHEN unique_violation THEN
        RETURN jsonb_build_object('attributed', FALSE, 'reason', 'already_recorded');
END;
$$;

GRANT EXECUTE ON FUNCTION public.attribute_my_referral(TEXT, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.qualify_referral_for_event(
    p_referred_user_id UUID,
    p_event TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_referral public.referrals%ROWTYPE;
    v_campaign public.referral_campaigns%ROWTYPE;
    v_marketer_id UUID;
    v_reward_id UUID;
BEGIN
    SELECT * INTO v_referral
    FROM public.referrals
    WHERE referred_user_id = p_referred_user_id
      AND status NOT IN ('rejected', 'fraud_flagged', 'fraud_hold', 'cancelled', 'paid')
    ORDER BY created_at ASC
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('qualified', FALSE, 'reason', 'no_referral');
    END IF;

    SELECT * INTO v_campaign
    FROM public.referral_campaigns
    WHERE id = v_referral.campaign_id
      AND status = 'active'
      AND qualification_event = p_event
      AND (country IS NULL OR country = v_referral.country)
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('qualified', FALSE, 'reason', 'no_matching_campaign');
    END IF;

    SELECT id INTO v_marketer_id
    FROM public.referral_marketers
    WHERE profile_id = v_referral.referrer_id
    LIMIT 1;

    IF v_marketer_id IS NULL THEN
        RETURN jsonb_build_object('qualified', FALSE, 'reason', 'marketer_missing');
    END IF;

    UPDATE public.referrals
    SET status = 'qualified',
        qualifying_event = p_event,
        qualified_at = COALESCE(qualified_at, CURRENT_TIMESTAMP),
        reward_amount = v_campaign.reward_amount,
        reward_currency = v_campaign.reward_currency,
        reward_status = CASE WHEN v_campaign.reward_amount > 0 THEN 'pending' ELSE 'none' END,
        payout_status = 'none',
        updated_at = CURRENT_TIMESTAMP
    WHERE id = v_referral.id
    RETURNING * INTO v_referral;

    UPDATE public.profiles
    SET referral_status = 'qualified',
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_referred_user_id;

    IF v_campaign.reward_amount > 0 THEN
        INSERT INTO public.referral_rewards (
            marketer_id, referral_id, campaign_id, referred_user_id,
            reward_type, amount, currency, status, reason, campaign_reward_snapshot
        )
        VALUES (
            v_marketer_id,
            v_referral.id,
            v_campaign.id,
            p_referred_user_id,
            v_campaign.reward_type,
            v_campaign.reward_amount,
            v_campaign.reward_currency,
            'pending',
            'Qualified by event: ' || p_event,
            jsonb_build_object(
                'campaign_id', v_campaign.id,
                'campaign', v_campaign.name,
                'reward_type', v_campaign.reward_type,
                'amount', v_campaign.reward_amount,
                'currency', v_campaign.reward_currency,
                'qualification_event', v_campaign.qualification_event
            )
        )
        ON CONFLICT DO NOTHING
        RETURNING id INTO v_reward_id;
    END IF;

    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
        v_referral.referrer_id,
        'system',
        'Referral qualified',
        'One of your referrals qualified for a Nipanze marketing reward.',
        jsonb_build_object('notification_kind', 'referral_qualified', 'referral_id', v_referral.id, 'reward_id', v_reward_id)
    );

    RETURN jsonb_build_object('qualified', TRUE, 'referral_id', v_referral.id, 'reward_id', v_reward_id);
END;
$$;

GRANT EXECUTE ON FUNCTION public.qualify_referral_for_event(UUID, TEXT) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.get_my_referral_dashboard()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_marketer JSONB;
    v_profile_id UUID;
    v_summary JSONB;
    v_history JSONB;
    v_default_currency TEXT;
BEGIN
    v_marketer := public.ensure_my_referral_marketer(NULL);
    v_profile_id := auth.uid();

    SELECT COALESCE(c.currency_code, 'UGX') INTO v_default_currency
    FROM public.profiles p
    LEFT JOIN public.countries c ON c.code = COALESCE(p.country, p.marketing_country, 'UG')
    WHERE p.id = v_profile_id;
    v_default_currency := COALESCE(v_default_currency, 'UGX');

    SELECT jsonb_build_object(
        'total_referrals', COUNT(*)::INT,
        'registered', COUNT(*) FILTER (WHERE r.status = 'registered')::INT,
        'verified', COUNT(*) FILTER (WHERE r.status = 'verified')::INT,
        'qualified', COUNT(*) FILTER (WHERE r.status IN ('qualified', 'reward_pending', 'reward_earned', 'paid'))::INT,
        'pending_rewards', COALESCE(SUM(rr.amount) FILTER (WHERE rr.status = 'pending'), 0),
        'available_rewards', COALESCE(SUM(rr.amount) FILTER (WHERE rr.status = 'approved'), 0),
        'paid_rewards', COALESCE(SUM(rr.amount) FILTER (WHERE rr.status = 'paid'), 0),
        'total_earned', COALESCE(SUM(rr.amount) FILTER (WHERE rr.status IN ('pending', 'approved', 'paid')), 0),
        'total_paid', COALESCE(SUM(rr.amount) FILTER (WHERE rr.status = 'paid'), 0),
        'currency', COALESCE(MAX(rr.currency), MAX(r.reward_currency), v_default_currency)
    )
    INTO v_summary
    FROM public.referrals r
    LEFT JOIN public.referral_rewards rr ON rr.referral_id = r.id
    WHERE r.referrer_id = v_profile_id;

    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'id', r.id,
            'display_name', COALESCE(NULLIF(SPLIT_PART(TRIM(p.full_name), ' ', 1), ''), 'Nipanze user'),
            'registered_at', COALESCE(r.registered_at, r.created_at),
            'status', r.status,
            'qualification_status', CASE WHEN r.qualified_at IS NULL THEN 'pending' ELSE 'qualified' END,
            'reward_amount', COALESCE(rr.amount, r.reward_amount, 0),
            'reward_currency', COALESCE(rr.currency, r.reward_currency, c.reward_currency, 'UGX'),
            'reward_status', COALESCE(rr.status, r.reward_status, 'none'),
            'payout_status', r.payout_status,
            'source', r.source
        )
        ORDER BY COALESCE(r.registered_at, r.created_at) DESC
    ), '[]'::JSONB)
    INTO v_history
    FROM public.referrals r
    LEFT JOIN public.profiles p ON p.id = r.referred_user_id
    LEFT JOIN public.referral_campaigns c ON c.id = r.campaign_id
    LEFT JOIN public.referral_rewards rr ON rr.referral_id = r.id
    WHERE r.referrer_id = v_profile_id;

    RETURN jsonb_build_object(
        'marketer', v_marketer,
        'summary', COALESCE(v_summary, '{}'::JSONB),
        'history', COALESCE(v_history, '[]'::JSONB)
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_referral_dashboard() TO authenticated;

CREATE OR REPLACE FUNCTION public.trg_referral_kyc_event()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.status = 'approved' AND (TG_OP = 'INSERT' OR OLD.status IS DISTINCT FROM NEW.status) THEN
        PERFORM public.qualify_referral_for_event(NEW.user_id, 'kyc_approved');
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_referral_kyc_event ON public.kyc_verifications;
CREATE TRIGGER trg_referral_kyc_event
    AFTER INSERT OR UPDATE OF status ON public.kyc_verifications
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_referral_kyc_event();

CREATE OR REPLACE FUNCTION public.trg_referral_subscription_event()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.status = 'active' AND (TG_OP = 'INSERT' OR OLD.status IS DISTINCT FROM NEW.status OR OLD.plan IS DISTINCT FROM NEW.plan) THEN
        PERFORM public.qualify_referral_for_event(NEW.user_id, 'first_paid_subscription');
        IF NEW.plan IN ('lender', 'pro') THEN
            PERFORM public.qualify_referral_for_event(NEW.user_id, 'first_lender_or_pro_subscription');
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_referral_subscription_event ON public.subscriptions;
CREATE TRIGGER trg_referral_subscription_event
    AFTER INSERT OR UPDATE OF status, plan ON public.subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_referral_subscription_event();


-- ============================================================
-- END MERGED SECTION: patch_referral_agent_system.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_marketer_department.sql
-- ============================================================

-- Nipanze Admin Portal: Marketer / Referral Department
-- Additive patch. Keeps marketer rewards separate from P2P loan and forex funds.

CREATE TABLE IF NOT EXISTS public.referral_campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    country TEXT REFERENCES public.countries(code),
    start_date DATE,
    end_date DATE,
    status TEXT NOT NULL DEFAULT 'draft'
        CONSTRAINT chk_referral_campaign_status CHECK (status IN ('draft', 'active', 'paused', 'ended', 'deactivated')),
    qualification_event TEXT NOT NULL DEFAULT 'verified_referral',
    reward_type TEXT NOT NULL DEFAULT 'fixed'
        CONSTRAINT chk_referral_campaign_reward_type CHECK (reward_type IN ('fixed', 'tiered', 'manual')),
    reward_amount BIGINT NOT NULL DEFAULT 0
        CONSTRAINT chk_referral_campaign_reward_amount CHECK (reward_amount >= 0),
    reward_currency TEXT NOT NULL DEFAULT 'UGX',
    max_reward_per_referral BIGINT,
    campaign_budget BIGINT,
    max_referrals INTEGER,
    eligible_plans TEXT[] NOT NULL DEFAULT ARRAY['free','lender','pro']::TEXT[],
    terms TEXT,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.referral_marketers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    referral_code TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'active'
        CONSTRAINT chk_referral_marketer_status CHECK (status IN ('new', 'active', 'suspended', 'deactivated', 'under_review')),
    default_campaign_id UUID REFERENCES public.referral_campaigns(id) ON DELETE SET NULL,
    joined_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_activity_at TIMESTAMP,
    risk_status TEXT NOT NULL DEFAULT 'clear'
        CONSTRAINT chk_referral_marketer_risk_status CHECK (risk_status IN ('clear', 'review', 'flagged')),
    risk_reason TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.referrals
    ADD COLUMN IF NOT EXISTS campaign_id UUID REFERENCES public.referral_campaigns(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS source TEXT,
    ADD COLUMN IF NOT EXISTS country TEXT REFERENCES public.countries(code),
    ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'registered'
        CONSTRAINT chk_referrals_status CHECK (status IN ('clicked', 'registered', 'verified', 'qualified', 'rejected', 'fraud_hold')),
    ADD COLUMN IF NOT EXISTS verified_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS qualifying_event TEXT,
    ADD COLUMN IF NOT EXISTS qualified_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS fraud_status TEXT NOT NULL DEFAULT 'clear'
        CONSTRAINT chk_referrals_fraud_status CHECK (fraud_status IN ('clear', 'review', 'flagged', 'cleared')),
    ADD COLUMN IF NOT EXISTS fraud_reason TEXT,
    ADD COLUMN IF NOT EXISTS metadata JSONB NOT NULL DEFAULT '{}'::JSONB;

CREATE TABLE IF NOT EXISTS public.referral_rewards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    marketer_id UUID NOT NULL REFERENCES public.referral_marketers(id) ON DELETE CASCADE,
    referral_id UUID REFERENCES public.referrals(id) ON DELETE SET NULL,
    campaign_id UUID REFERENCES public.referral_campaigns(id) ON DELETE SET NULL,
    referred_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    reward_type TEXT NOT NULL DEFAULT 'fixed',
    amount BIGINT NOT NULL CONSTRAINT chk_referral_reward_amount CHECK (amount >= 0),
    currency TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending'
        CONSTRAINT chk_referral_reward_status CHECK (status IN ('pending', 'approved', 'rejected', 'paid', 'cancelled', 'fraud_hold')),
    reason TEXT,
    approved_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    approved_at TIMESTAMP,
    rejected_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    rejected_at TIMESTAMP,
    paid_at TIMESTAMP,
    campaign_reward_snapshot JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.referral_payouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    marketer_id UUID NOT NULL REFERENCES public.referral_marketers(id) ON DELETE CASCADE,
    amount BIGINT NOT NULL CONSTRAINT chk_referral_payout_amount CHECK (amount >= 0),
    currency TEXT NOT NULL,
    payout_method TEXT,
    payout_destination_ref TEXT,
    status TEXT NOT NULL DEFAULT 'requested'
        CONSTRAINT chk_referral_payout_status CHECK (status IN ('requested', 'under_review', 'approved', 'processing', 'paid', 'failed', 'cancelled')),
    failure_reason TEXT,
    requested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    approved_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    approved_at TIMESTAMP,
    completed_at TIMESTAMP,
    metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.referral_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    marketer_id UUID REFERENCES public.referral_marketers(id) ON DELETE SET NULL,
    referral_id UUID REFERENCES public.referrals(id) ON DELETE SET NULL,
    campaign_id UUID REFERENCES public.referral_campaigns(id) ON DELETE SET NULL,
    event_type TEXT NOT NULL,
    actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_referral_marketers_profile ON public.referral_marketers(profile_id);
CREATE INDEX IF NOT EXISTS idx_referral_marketers_status ON public.referral_marketers(status);
CREATE INDEX IF NOT EXISTS idx_referral_marketers_campaign ON public.referral_marketers(default_campaign_id);
CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON public.referrals(referrer_id);
CREATE INDEX IF NOT EXISTS idx_referrals_campaign ON public.referrals(campaign_id);
CREATE INDEX IF NOT EXISTS idx_referrals_status ON public.referrals(status);
CREATE INDEX IF NOT EXISTS idx_referral_rewards_marketer ON public.referral_rewards(marketer_id);
CREATE INDEX IF NOT EXISTS idx_referral_rewards_status ON public.referral_rewards(status);
CREATE INDEX IF NOT EXISTS idx_referral_payouts_marketer ON public.referral_payouts(marketer_id);
CREATE INDEX IF NOT EXISTS idx_referral_payouts_status ON public.referral_payouts(status);
CREATE INDEX IF NOT EXISTS idx_referral_events_referral ON public.referral_events(referral_id);

ALTER TABLE public.referral_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referral_marketers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referral_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referral_payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referral_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "referral_campaigns: admin read" ON public.referral_campaigns;
CREATE POLICY "referral_campaigns: admin read" ON public.referral_campaigns
    FOR SELECT TO authenticated USING (private.is_admin());
DROP POLICY IF EXISTS "referral_campaigns: admin write" ON public.referral_campaigns;
CREATE POLICY "referral_campaigns: admin write" ON public.referral_campaigns
    FOR ALL TO authenticated USING (private.is_admin()) WITH CHECK (private.is_admin());

DROP POLICY IF EXISTS "referral_marketers: own or admin read" ON public.referral_marketers;
CREATE POLICY "referral_marketers: own or admin read" ON public.referral_marketers
    FOR SELECT TO authenticated USING (profile_id = auth.uid() OR private.is_admin());
DROP POLICY IF EXISTS "referral_marketers: admin write" ON public.referral_marketers;
CREATE POLICY "referral_marketers: admin write" ON public.referral_marketers
    FOR ALL TO authenticated USING (private.is_admin()) WITH CHECK (private.is_admin());

DROP POLICY IF EXISTS "referral_rewards: own or admin read" ON public.referral_rewards;
CREATE POLICY "referral_rewards: own or admin read" ON public.referral_rewards
    FOR SELECT TO authenticated USING (
        private.is_admin()
        OR EXISTS (
            SELECT 1 FROM public.referral_marketers rm
            WHERE rm.id = referral_rewards.marketer_id AND rm.profile_id = auth.uid()
        )
    );
DROP POLICY IF EXISTS "referral_rewards: admin write" ON public.referral_rewards;
CREATE POLICY "referral_rewards: admin write" ON public.referral_rewards
    FOR ALL TO authenticated USING (private.is_admin()) WITH CHECK (private.is_admin());

DROP POLICY IF EXISTS "referral_payouts: own or admin read" ON public.referral_payouts;
CREATE POLICY "referral_payouts: own or admin read" ON public.referral_payouts
    FOR SELECT TO authenticated USING (
        private.is_admin()
        OR EXISTS (
            SELECT 1 FROM public.referral_marketers rm
            WHERE rm.id = referral_payouts.marketer_id AND rm.profile_id = auth.uid()
        )
    );
DROP POLICY IF EXISTS "referral_payouts: admin write" ON public.referral_payouts;
CREATE POLICY "referral_payouts: admin write" ON public.referral_payouts
    FOR ALL TO authenticated USING (private.is_admin()) WITH CHECK (private.is_admin());

DROP POLICY IF EXISTS "referral_events: admin read" ON public.referral_events;
CREATE POLICY "referral_events: admin read" ON public.referral_events
    FOR SELECT TO authenticated USING (private.is_admin());
DROP POLICY IF EXISTS "referral_events: admin insert" ON public.referral_events;
CREATE POLICY "referral_events: admin insert" ON public.referral_events
    FOR INSERT TO authenticated WITH CHECK (private.is_admin());

COMMENT ON TABLE public.referral_rewards IS
'Nipanze marketing expense records only. These are never P2P loan funds, repayments, forex settlements, or platform revenue.';
COMMENT ON TABLE public.referral_payouts IS
'Marketer payout workflow for Nipanze-owned rewards. Built for future payment-provider integration and kept separate from transactions.';

CREATE OR REPLACE VIEW public.marketers AS
SELECT
    rm.id,
    rm.profile_id AS user_id,
    rm.referral_code AS marketer_code,
    rm.status,
    0::NUMERIC AS commission_rate,
    rm.joined_at,
    (
        SELECT COUNT(*)
        FROM public.referrals r
        WHERE r.referrer_id = rm.profile_id
    )::INTEGER AS total_referrals,
    (
        SELECT COUNT(*)
        FROM public.referrals r
        WHERE r.referrer_id = rm.profile_id
          AND r.status = 'qualified'
    )::INTEGER AS successful_referrals,
    (
        SELECT COALESCE(SUM(rr.amount), 0)
        FROM public.referral_rewards rr
        WHERE rr.marketer_id = rm.id
          AND rr.status = 'pending'
    )::BIGINT AS pending_rewards,
    (
        SELECT COALESCE(SUM(rr.amount), 0)
        FROM public.referral_rewards rr
        WHERE rr.marketer_id = rm.id
    )::BIGINT AS total_rewards,
    rm.updated_at
FROM public.referral_marketers rm;

COMMENT ON VIEW public.marketers IS
'Compatibility view for the client app. A marketer is still a normal profiles user with one referral_marketers row.';
GRANT SELECT ON public.marketers TO authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Demo marketer data
-- ---------------------------------------------------------------------------
-- These rows turn existing seeded Nipanze accounts into marketers. They do not
-- create a second login or a new account type. Test accounts keep using the
-- auth.users login from sql/seed.sql, normally with password Test1234!.

INSERT INTO public.referral_campaigns (
    id, name, description, country, start_date, end_date, status,
    qualification_event, reward_type, reward_amount, reward_currency,
    max_reward_per_referral, campaign_budget, max_referrals, eligible_plans,
    terms, created_by, created_at, updated_at
) VALUES
(
    'f0000000-0000-0000-0000-000000000001',
    'Uganda Launch Referrals',
    'Reward active marketers when referred users register and complete the configured launch qualification.',
    'UG',
    '2026-01-01',
    '2026-12-31',
    'active',
    'kyc_approved',
    'fixed',
    20000,
    'UGX',
    20000,
    5000000,
    500,
    ARRAY['free','lender','pro']::TEXT[],
    'Demo campaign for Uganda marketer testing. Reward is paid only after qualification review.',
    '10000000-0000-0000-0000-000000000015',
    '2026-01-01 08:00:00',
    '2026-01-01 08:00:00'
),
(
    'f0000000-0000-0000-0000-000000000002',
    'Kenya Launch Referrals',
    'Country-aware marketer rewards for Kenya launch testing.',
    'KE',
    '2026-02-01',
    '2026-12-31',
    'active',
    'verified_registration',
    'fixed',
    750,
    'KES',
    750,
    300000,
    400,
    ARRAY['free','lender','pro']::TEXT[],
    'Demo campaign for Kenya marketer testing. Currency stays KES.',
    '10000000-0000-0000-0000-000000000032',
    '2026-02-01 08:00:00',
    '2026-02-01 08:00:00'
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    country = EXCLUDED.country,
    status = EXCLUDED.status,
    qualification_event = EXCLUDED.qualification_event,
    reward_type = EXCLUDED.reward_type,
    reward_amount = EXCLUDED.reward_amount,
    reward_currency = EXCLUDED.reward_currency,
    max_reward_per_referral = EXCLUDED.max_reward_per_referral,
    campaign_budget = EXCLUDED.campaign_budget,
    max_referrals = EXCLUDED.max_referrals,
    eligible_plans = EXCLUDED.eligible_plans,
    terms = EXCLUDED.terms,
    updated_at = EXCLUDED.updated_at;

INSERT INTO public.referral_marketers (
    id, profile_id, referral_code, status, default_campaign_id,
    joined_at, last_activity_at, risk_status, risk_reason, metadata,
    created_at, updated_at
) VALUES
(
    'f1000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'NIP-DAVID',
    'active',
    'f0000000-0000-0000-0000-000000000001',
    '2026-01-05 09:00:00',
    '2026-02-08 16:20:00',
    'clear',
    NULL,
    '{"demo": true, "login_email": "david.mukasa@gmail.com"}'::JSONB,
    '2026-01-05 09:00:00',
    '2026-02-08 16:20:00'
),
(
    'f1000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000003',
    'NIP-JAMES',
    'active',
    'f0000000-0000-0000-0000-000000000001',
    '2026-01-08 10:30:00',
    '2026-02-09 13:15:00',
    'review',
    'Higher than usual signup velocity in one district; demo review item.',
    '{"demo": true, "login_email": "james.okello@outlook.com"}'::JSONB,
    '2026-01-08 10:30:00',
    '2026-02-09 13:15:00'
),
(
    'f1000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000018',
    'NIP-WANJIRU',
    'active',
    'f0000000-0000-0000-0000-000000000002',
    '2026-02-10 09:30:00',
    '2026-02-18 18:45:00',
    'clear',
    NULL,
    '{"demo": true, "login_email": "wanjiru.kamau@nipanze-ke.test"}'::JSONB,
    '2026-02-10 09:30:00',
    '2026-02-18 18:45:00'
),
(
    'f1000000-0000-0000-0000-000000000004',
    '10000000-0000-0000-0000-000000000017',
    'NIP-TESTUG',
    'new',
    'f0000000-0000-0000-0000-000000000001',
    '2026-02-06 11:00:00',
    '2026-02-06 11:00:00',
    'clear',
    NULL,
    '{"demo": true, "login_email": "test.user@gmail.com"}'::JSONB,
    '2026-02-06 11:00:00',
    '2026-02-06 11:00:00'
)
ON CONFLICT (profile_id) DO UPDATE SET
    referral_code = EXCLUDED.referral_code,
    status = EXCLUDED.status,
    default_campaign_id = EXCLUDED.default_campaign_id,
    joined_at = EXCLUDED.joined_at,
    last_activity_at = EXCLUDED.last_activity_at,
    risk_status = EXCLUDED.risk_status,
    risk_reason = EXCLUDED.risk_reason,
    metadata = EXCLUDED.metadata,
    updated_at = EXCLUDED.updated_at;

UPDATE public.referrals
SET campaign_id = 'f0000000-0000-0000-0000-000000000001',
    source = COALESCE(source, 'demo_seed'),
    country = COALESCE(country, 'UG'),
    status = CASE
        WHEN id IN ('e5000000-0000-0000-0000-000000000001', 'e5000000-0000-0000-0000-000000000003') THEN 'qualified'
        WHEN id = 'e5000000-0000-0000-0000-000000000004' THEN 'registered'
        ELSE status
    END,
    verified_at = CASE WHEN is_activated THEN COALESCE(verified_at, activated_at) ELSE verified_at END,
    qualifying_event = CASE
        WHEN id IN ('e5000000-0000-0000-0000-000000000001', 'e5000000-0000-0000-0000-000000000003') THEN 'kyc_approved'
        ELSE qualifying_event
    END,
    qualified_at = CASE
        WHEN id IN ('e5000000-0000-0000-0000-000000000001', 'e5000000-0000-0000-0000-000000000003') THEN COALESCE(qualified_at, activated_at)
        ELSE qualified_at
    END
WHERE id IN (
    'e5000000-0000-0000-0000-000000000001',
    'e5000000-0000-0000-0000-000000000003',
    'e5000000-0000-0000-0000-000000000004'
);

UPDATE public.referrals
SET campaign_id = 'f0000000-0000-0000-0000-000000000002',
    source = COALESCE(source, 'demo_seed'),
    country = COALESCE(country, 'KE'),
    status = 'qualified',
    verified_at = COALESCE(verified_at, activated_at),
    qualifying_event = 'verified_registration',
    qualified_at = COALESCE(qualified_at, activated_at)
WHERE id = 'e5000000-0000-0000-0000-000000000005';

INSERT INTO public.referral_rewards (
    id, marketer_id, referral_id, campaign_id, referred_user_id,
    reward_type, amount, currency, status, reason, approved_by,
    approved_at, paid_at, campaign_reward_snapshot, created_at, updated_at
) VALUES
(
    'f2000000-0000-0000-0000-000000000001',
    'f1000000-0000-0000-0000-000000000001',
    'e5000000-0000-0000-0000-000000000001',
    'f0000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000011',
    'fixed',
    20000,
    'UGX',
    'paid',
    'Qualified after KYC approval.',
    '10000000-0000-0000-0000-000000000015',
    '2026-02-01 10:00:00',
    '2026-02-03 14:00:00',
    '{"campaign": "Uganda Launch Referrals", "amount": 20000, "currency": "UGX", "qualification_event": "kyc_approved"}'::JSONB,
    '2026-02-01 09:00:00',
    '2026-02-03 14:00:00'
),
(
    'f2000000-0000-0000-0000-000000000002',
    'f1000000-0000-0000-0000-000000000002',
    'e5000000-0000-0000-0000-000000000003',
    'f0000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000013',
    'fixed',
    20000,
    'UGX',
    'pending',
    'Qualified referral awaiting reward approval.',
    NULL,
    NULL,
    NULL,
    '{"campaign": "Uganda Launch Referrals", "amount": 20000, "currency": "UGX", "qualification_event": "kyc_approved"}'::JSONB,
    '2026-02-04 09:00:00',
    '2026-02-04 09:00:00'
),
(
    'f2000000-0000-0000-0000-000000000003',
    'f1000000-0000-0000-0000-000000000003',
    'e5000000-0000-0000-0000-000000000005',
    'f0000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000026',
    'fixed',
    750,
    'KES',
    'approved',
    'Kenya launch referral verified.',
    '10000000-0000-0000-0000-000000000032',
    '2026-02-18 15:30:00',
    NULL,
    '{"campaign": "Kenya Launch Referrals", "amount": 750, "currency": "KES", "qualification_event": "verified_registration"}'::JSONB,
    '2026-02-18 12:00:00',
    '2026-02-18 15:30:00'
)
ON CONFLICT (id) DO UPDATE SET
    marketer_id = EXCLUDED.marketer_id,
    referral_id = EXCLUDED.referral_id,
    campaign_id = EXCLUDED.campaign_id,
    referred_user_id = EXCLUDED.referred_user_id,
    reward_type = EXCLUDED.reward_type,
    amount = EXCLUDED.amount,
    currency = EXCLUDED.currency,
    status = EXCLUDED.status,
    reason = EXCLUDED.reason,
    approved_by = EXCLUDED.approved_by,
    approved_at = EXCLUDED.approved_at,
    paid_at = EXCLUDED.paid_at,
    campaign_reward_snapshot = EXCLUDED.campaign_reward_snapshot,
    updated_at = EXCLUDED.updated_at;

INSERT INTO public.referral_payouts (
    id, marketer_id, amount, currency, payout_method, payout_destination_ref,
    status, requested_at, approved_by, approved_at, completed_at,
    failure_reason, metadata, created_at, updated_at
) VALUES
(
    'f3000000-0000-0000-0000-000000000001',
    'f1000000-0000-0000-0000-000000000001',
    20000,
    'UGX',
    'mobile_money',
    '+256701234567',
    'paid',
    '2026-02-02 09:00:00',
    '10000000-0000-0000-0000-000000000015',
    '2026-02-02 11:00:00',
    '2026-02-03 14:00:00',
    NULL,
    '{"demo": true, "provider_ready": false}'::JSONB,
    '2026-02-02 09:00:00',
    '2026-02-03 14:00:00'
),
(
    'f3000000-0000-0000-0000-000000000002',
    'f1000000-0000-0000-0000-000000000003',
    750,
    'KES',
    'mobile_money',
    '+254710002466',
    'approved',
    '2026-02-19 09:00:00',
    '10000000-0000-0000-0000-000000000032',
    '2026-02-19 11:00:00',
    NULL,
    NULL,
    '{"demo": true, "provider_ready": false}'::JSONB,
    '2026-02-19 09:00:00',
    '2026-02-19 11:00:00'
)
ON CONFLICT (id) DO UPDATE SET
    marketer_id = EXCLUDED.marketer_id,
    amount = EXCLUDED.amount,
    currency = EXCLUDED.currency,
    payout_method = EXCLUDED.payout_method,
    payout_destination_ref = EXCLUDED.payout_destination_ref,
    status = EXCLUDED.status,
    requested_at = EXCLUDED.requested_at,
    approved_by = EXCLUDED.approved_by,
    approved_at = EXCLUDED.approved_at,
    completed_at = EXCLUDED.completed_at,
    failure_reason = EXCLUDED.failure_reason,
    metadata = EXCLUDED.metadata,
    updated_at = EXCLUDED.updated_at;

INSERT INTO public.referral_events (
    id, marketer_id, referral_id, campaign_id, event_type, actor_id, metadata, created_at
) VALUES
('f4000000-0000-0000-0000-000000000001', 'f1000000-0000-0000-0000-000000000001', 'e5000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000001', 'referral_qualified', '10000000-0000-0000-0000-000000000015', '{"demo": true}'::JSONB, '2026-02-01 09:00:00'),
('f4000000-0000-0000-0000-000000000002', 'f1000000-0000-0000-0000-000000000002', 'e5000000-0000-0000-0000-000000000003', 'f0000000-0000-0000-0000-000000000001', 'referral_flagged_for_review', '10000000-0000-0000-0000-000000000015', '{"demo": true, "reason": "velocity review"}'::JSONB, '2026-02-04 09:30:00'),
('f4000000-0000-0000-0000-000000000003', 'f1000000-0000-0000-0000-000000000003', 'e5000000-0000-0000-0000-000000000005', 'f0000000-0000-0000-0000-000000000002', 'reward_approved', '10000000-0000-0000-0000-000000000032', '{"demo": true}'::JSONB, '2026-02-18 15:30:00')
ON CONFLICT (id) DO NOTHING;


-- ============================================================
-- END MERGED SECTION: patch_marketer_department.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_referral_client_rewards_available_status.sql
-- ============================================================

-- ==============================================================================
-- NIPANZE REFERRALS: CLIENT-FACING AVAILABLE REWARD STATUS
-- ==============================================================================
-- Paste this once after the referral/marketer tables and RPCs already exist.
-- Keeps existing "approved" reward rows working while exposing "available" to
-- normal users as the claimable reward state: pending -> available -> paid.
-- ==============================================================================

ALTER TABLE public.referrals DROP CONSTRAINT IF EXISTS chk_referrals_reward_status;
ALTER TABLE public.referrals
    ADD CONSTRAINT chk_referrals_reward_status
    CHECK (reward_status IN (
        'none',
        'pending',
        'earned',
        'available',
        'approved',
        'rejected',
        'paid',
        'cancelled',
        'fraud_hold'
    ));

ALTER TABLE public.referral_rewards DROP CONSTRAINT IF EXISTS chk_referral_reward_status;
ALTER TABLE public.referral_rewards
    ADD CONSTRAINT chk_referral_reward_status
    CHECK (status IN (
        'pending',
        'available',
        'approved',
        'rejected',
        'paid',
        'cancelled',
        'fraud_hold'
    ));

CREATE OR REPLACE FUNCTION public.get_my_referral_dashboard()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_marketer JSONB;
    v_profile_id UUID;
    v_summary JSONB;
    v_history JSONB;
    v_default_currency TEXT;
BEGIN
    v_marketer := public.ensure_my_referral_marketer(NULL);
    v_profile_id := auth.uid();

    SELECT COALESCE(c.currency_code, 'UGX') INTO v_default_currency
    FROM public.profiles p
    LEFT JOIN public.countries c ON c.code = COALESCE(p.country, p.marketing_country, 'UG')
    WHERE p.id = v_profile_id;
    v_default_currency := COALESCE(v_default_currency, 'UGX');

    SELECT jsonb_build_object(
        'total_referrals', COUNT(*)::INT,
        'registered', COUNT(*) FILTER (WHERE r.status = 'registered')::INT,
        'verified', COUNT(*) FILTER (WHERE r.status = 'verified')::INT,
        'qualified', COUNT(*) FILTER (WHERE r.status IN ('qualified', 'reward_pending', 'reward_earned', 'paid'))::INT,
        'pending_rewards', COALESCE(SUM(rr.amount) FILTER (WHERE rr.status = 'pending'), 0),
        'available_rewards', COALESCE(SUM(rr.amount) FILTER (WHERE rr.status IN ('available', 'approved')), 0),
        'paid_rewards', COALESCE(SUM(rr.amount) FILTER (WHERE rr.status = 'paid'), 0),
        'total_earned', COALESCE(SUM(rr.amount) FILTER (WHERE rr.status IN ('pending', 'available', 'approved', 'paid')), 0),
        'total_paid', COALESCE(SUM(rr.amount) FILTER (WHERE rr.status = 'paid'), 0),
        'currency', COALESCE(MAX(rr.currency), MAX(r.reward_currency), v_default_currency)
    )
    INTO v_summary
    FROM public.referrals r
    LEFT JOIN public.referral_rewards rr ON rr.referral_id = r.id
    WHERE r.referrer_id = v_profile_id;

    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'id', r.id,
            'display_name', COALESCE(NULLIF(SPLIT_PART(TRIM(p.full_name), ' ', 1), ''), 'Nipanze user'),
            'registered_at', COALESCE(r.registered_at, r.created_at),
            'status', r.status,
            'qualification_status', CASE WHEN r.qualified_at IS NULL THEN 'pending' ELSE 'qualified' END,
            'reward_amount', COALESCE(rr.amount, r.reward_amount, 0),
            'reward_currency', COALESCE(rr.currency, r.reward_currency, c.reward_currency, 'UGX'),
            'reward_status', CASE
                WHEN COALESCE(rr.status, r.reward_status, 'none') = 'approved' THEN 'available'
                ELSE COALESCE(rr.status, r.reward_status, 'none')
            END,
            'payout_status', r.payout_status,
            'source', r.source
        )
        ORDER BY COALESCE(r.registered_at, r.created_at) DESC
    ), '[]'::JSONB)
    INTO v_history
    FROM public.referrals r
    LEFT JOIN public.profiles p ON p.id = r.referred_user_id
    LEFT JOIN public.referral_campaigns c ON c.id = r.campaign_id
    LEFT JOIN public.referral_rewards rr ON rr.referral_id = r.id
    WHERE r.referrer_id = v_profile_id;

    RETURN jsonb_build_object(
        'marketer', COALESCE(v_marketer, '{}'::JSONB),
        'summary', COALESCE(v_summary, '{}'::JSONB),
        'history', COALESCE(v_history, '[]'::JSONB)
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_referral_dashboard() TO authenticated;


-- ============================================================
-- END MERGED SECTION: patch_referral_client_rewards_available_status.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_blocked_users_visibility.sql
-- ============================================================

-- Account-level directional blocks shared by Loans and Forex.
CREATE TABLE IF NOT EXISTS public.user_blocks (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blocker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_blocks_pair UNIQUE (blocker_id, blocked_id),
    CONSTRAINT chk_user_blocks_not_self CHECK (blocker_id <> blocked_id)
);

CREATE INDEX IF NOT EXISTS idx_user_blocks_blocker_id ON public.user_blocks (blocker_id);
CREATE INDEX IF NOT EXISTS idx_user_blocks_blocked_id ON public.user_blocks (blocked_id);

ALTER TABLE public.user_blocks ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION private.is_blocked_from_future_request(
    p_owner_id UUID,
    p_viewer_id UUID,
    p_listed_at TIMESTAMP
)
RETURNS BOOLEAN LANGUAGE SQL SECURITY DEFINER STABLE
SET search_path = public AS $$
    SELECT p_owner_id IS NOT NULL
       AND p_viewer_id IS NOT NULL
       AND p_owner_id <> p_viewer_id
       AND EXISTS (
           SELECT 1
           FROM public.user_blocks ub
           WHERE ub.blocker_id = p_owner_id
             AND ub.blocked_id = p_viewer_id
             AND ub.created_at <= COALESCE(p_listed_at, CURRENT_TIMESTAMP)
       );
$$;

GRANT EXECUTE ON FUNCTION private.is_blocked_from_future_request(UUID, UUID, TIMESTAMP)
    TO authenticated, service_role;

DROP POLICY IF EXISTS "user_blocks: blocker manages rows" ON public.user_blocks;
CREATE POLICY "user_blocks: blocker manages rows"
    ON public.user_blocks FOR ALL TO authenticated
    USING (blocker_id = auth.uid() OR private.is_admin())
    WITH CHECK (blocker_id = auth.uid() OR private.is_admin());

DROP POLICY IF EXISTS "loan_requests: marketplace read" ON public.loan_requests;
CREATE POLICY "loan_requests: marketplace read"
    ON public.loan_requests FOR SELECT TO authenticated
    USING (
        borrower_id = auth.uid()
        OR private.is_admin()
        OR (
            status = 'active'
            AND NOT private.is_blocked_from_future_request(borrower_id, auth.uid(), listed_at)
        )
    );

DROP POLICY IF EXISTS "loan_offers: lender insert" ON public.loan_offers;
CREATE POLICY "loan_offers: lender insert"
    ON public.loan_offers FOR INSERT TO authenticated
    WITH CHECK (
        lender_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM public.loan_requests lr
             WHERE lr.id = loan_offers.request_id
               AND NOT private.is_blocked_from_future_request(lr.borrower_id, auth.uid(), lr.listed_at)
        )
    );

CREATE OR REPLACE FUNCTION public.trg_fn_validate_offer()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
    v_listing    loan_requests%ROWTYPE;
    v_min_offer  BIGINT;
    v_plan       subscription_plan_enum;
BEGIN
    SELECT * INTO v_listing FROM loan_requests WHERE id = NEW.request_id;

    IF v_listing.status != 'active' THEN
        RAISE EXCEPTION 'NIPANZE_LISTING_NOT_ACTIVE: This listing is no longer accepting bids.'
            USING ERRCODE = 'P0010';
    END IF;

    IF v_listing.expires_at < NOW() THEN
        RAISE EXCEPTION 'NIPANZE_LISTING_EXPIRED: This listing has expired.'
            USING ERRCODE = 'P0011';
    END IF;

    IF v_listing.borrower_id = NEW.lender_id THEN
        RAISE EXCEPTION 'NIPANZE_SELF_OFFER: You cannot make a bid on your own listing.'
            USING ERRCODE = 'P0012';
    END IF;

    IF private.is_blocked_from_future_request(v_listing.borrower_id, NEW.lender_id, v_listing.listed_at) THEN
        RAISE EXCEPTION 'NIPANZE_BLOCKED: You cannot make a bid on this listing.'
            USING ERRCODE = 'P0017';
    END IF;

    SELECT setting_value::BIGINT INTO v_min_offer
    FROM system_settings
    WHERE setting_key = 'min_offer_amount'
      AND (country = v_listing.country OR country IS NULL)
    ORDER BY country NULLS LAST
    LIMIT 1;

    IF NEW.offer_amount < v_min_offer THEN
        RAISE EXCEPTION 'NIPANZE_MIN_OFFER: Bid amount must be at least %.', v_min_offer
            USING ERRCODE = 'P0013';
    END IF;

    SELECT plan INTO v_plan
    FROM subscriptions
    WHERE user_id = NEW.lender_id AND status = 'active';

    IF v_plan NOT IN ('lender', 'pro') THEN
        RAISE EXCEPTION 'NIPANZE_SUBSCRIPTION_REQUIRED: A Lender or Pro subscription is required to make bids.'
            USING ERRCODE = 'P0014';
    END IF;

    IF NEW.interest_rate_pct IS NULL OR NEW.late_fee_pct IS NULL OR
       NEW.repayment_frequency IS NULL OR NEW.installment_amount IS NULL THEN
        RAISE EXCEPTION 'NIPANZE_BID_TERMS_REQUIRED: Interest, late fee, repayment schedule, and installment amount are required.'
            USING ERRCODE = 'P0016';
    END IF;

    NEW.terms_locked_at := COALESCE(NEW.terms_locked_at, NOW());
    RETURN NEW;
END;
$$;

CREATE OR REPLACE VIEW public.v_loan_listings AS
SELECT
    lr.id AS request_id,
    lr.title,
    lr.purpose,
    lr.district,
    lr.country,
    c.currency_code,
    lr.duration_months,
    lr.requested_amount,
    lr.preferred_repayment_plan,
    lr.repayment_amount_per_period,
    lr.repayment_timeline,
    lr.suggested_interest_rate_pct,
    lr.suggested_late_fee_pct,
    lr.suggested_repayment_frequency,
    lr.suggested_installment_amount,
    lr.terms_locked_at,
    lr.status,
    lr.number_of_offers,
    CASE WHEN lr.number_of_offers = 0 THEN 'low' WHEN lr.number_of_offers <= 2 THEN 'medium' ELSE 'high' END AS offer_coverage_tier,
    lr.listed_at,
    lr.expires_at,
    k.status AS kyc_status,
    ta.rating_avg AS trust_rating_avg,
    COALESCE(ta.review_count, 0) AS trust_review_count,
    COALESCE(ta.completed_deals_count, 0) AS trust_completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE) AS trust_is_repeat_participant,
    (p.phone_verified_at IS NOT NULL) AS trust_phone_verified,
    ta.response_time_bucket AS trust_response_time_bucket,
    (k.status = 'approved') AS trust_is_verified,
    GREATEST(lr.expires_at - NOW(), INTERVAL '0') AS time_remaining,
    (lr.expires_at < NOW() + INTERVAL '24 hours') AS closing_soon_24h,
    (lr.expires_at < NOW() + INTERVAL '6 hours') AS closing_soon_6h,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN p.preferred_bank ELSE NULL END AS preferred_bank,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN p.institution_type ELSE NULL END AS institution_type,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN p.is_bank_agent ELSE FALSE END AS is_bank_agent,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN TRUE ELSE FALSE END AS show_professional_tag,
    CASE WHEN EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN lr.has_collateral ELSE FALSE END AS has_collateral,
    CASE WHEN EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN lr.collateral_details ELSE NULL END AS collateral_details,
    CASE WHEN EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN lr.collateral_estimated_value ELSE NULL END AS collateral_estimated_value,
    CASE WHEN EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN lr.collateral_location ELSE NULL END AS collateral_location
FROM public.loan_requests lr
JOIN public.profiles p ON p.id = lr.borrower_id
JOIN public.countries c ON c.code = lr.country
LEFT JOIN public.kyc_verifications k ON k.user_id = lr.borrower_id
LEFT JOIN public.trust_aggregates ta ON ta.user_id = lr.borrower_id
WHERE lr.status = 'active'
  AND (auth.uid() IS NULL OR lr.borrower_id <> auth.uid())
  AND NOT private.is_blocked_from_future_request(lr.borrower_id, auth.uid(), lr.listed_at)
  AND (
    auth.uid() IS NULL OR NOT EXISTS (
      SELECT 1 FROM public.loan_offers lo
      WHERE lo.request_id = lr.id
        AND lo.lender_id = auth.uid()
        AND lo.status IN ('pending', 'accepted')
    )
  );

CREATE OR REPLACE VIEW public.v_loan_listing_details AS
SELECT
    lr.id AS request_id,
    lr.title,
    lr.purpose,
    lr.district,
    lr.country,
    c.currency_code,
    lr.duration_months,
    lr.requested_amount,
    lr.preferred_repayment_plan,
    lr.repayment_amount_per_period,
    lr.repayment_timeline,
    lr.suggested_interest_rate_pct,
    lr.suggested_late_fee_pct,
    lr.suggested_repayment_frequency,
    lr.suggested_installment_amount,
    lr.terms_locked_at,
    lr.status,
    lr.number_of_offers,
    CASE WHEN lr.number_of_offers = 0 THEN 'low' WHEN lr.number_of_offers <= 2 THEN 'medium' ELSE 'high' END AS offer_coverage_tier,
    lr.listed_at,
    lr.expires_at,
    k.status AS kyc_status,
    ta.rating_avg AS trust_rating_avg,
    COALESCE(ta.review_count, 0) AS trust_review_count,
    COALESCE(ta.completed_deals_count, 0) AS trust_completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE) AS trust_is_repeat_participant,
    (p.phone_verified_at IS NOT NULL) AS trust_phone_verified,
    ta.response_time_bucket AS trust_response_time_bucket,
    (k.status = 'approved') AS trust_is_verified,
    GREATEST(lr.expires_at - NOW(), INTERVAL '0') AS time_remaining,
    (lr.expires_at < NOW() + INTERVAL '24 hours') AS closing_soon_24h,
    (lr.expires_at < NOW() + INTERVAL '6 hours') AS closing_soon_6h,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN p.preferred_bank ELSE NULL END,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN p.institution_type ELSE NULL END,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN p.is_bank_agent ELSE FALSE END,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN TRUE ELSE FALSE END,
    CASE WHEN EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN lr.has_collateral ELSE FALSE END,
    CASE WHEN EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN lr.collateral_details ELSE NULL END,
    CASE WHEN EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN lr.collateral_estimated_value ELSE NULL END,
    CASE WHEN EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN lr.collateral_location ELSE NULL END
FROM public.loan_requests lr
JOIN public.profiles p ON p.id = lr.borrower_id
JOIN public.countries c ON c.code = lr.country
LEFT JOIN public.kyc_verifications k ON k.user_id = lr.borrower_id
LEFT JOIN public.trust_aggregates ta ON ta.user_id = lr.borrower_id
WHERE lr.status = 'active'
  AND NOT private.is_blocked_from_future_request(lr.borrower_id, auth.uid(), lr.listed_at);

DO $$
BEGIN
    IF to_regclass('public.forex_requests') IS NOT NULL THEN
        DROP POLICY IF EXISTS "forex_requests: marketplace read" ON public.forex_requests;
        CREATE POLICY "forex_requests: marketplace read"
            ON public.forex_requests FOR SELECT TO authenticated
            USING (
                requester_id = auth.uid()
                OR private.is_admin()
                OR (
                    status = 'active'
                    AND NOT private.is_blocked_from_future_request(requester_id, auth.uid(), listed_at)
                )
            );

        DROP POLICY IF EXISTS "forex_offers: offer_maker insert" ON public.forex_offers;
        CREATE POLICY "forex_offers: offer_maker insert"
            ON public.forex_offers FOR INSERT TO authenticated
            WITH CHECK (
                offer_maker_id = auth.uid()
                AND EXISTS (
                    SELECT 1 FROM public.forex_requests fr
                     WHERE fr.id = forex_offers.request_id
                       AND NOT private.is_blocked_from_future_request(fr.requester_id, auth.uid(), fr.listed_at)
                )
            );
    END IF;
END $$;

CREATE OR REPLACE FUNCTION public.trg_fn_validate_forex_offer()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
    v_listing forex_requests%ROWTYPE;
    v_plan subscription_plan_enum;
BEGIN
    SELECT * INTO v_listing FROM forex_requests WHERE id = NEW.request_id;

    IF v_listing.status != 'active' THEN
        RAISE EXCEPTION 'NIPANZE_FOREX_LISTING_NOT_ACTIVE: This forex request is no longer accepting offers.'
            USING ERRCODE = 'P0010';
    END IF;

    IF v_listing.expires_at < NOW() THEN
        RAISE EXCEPTION 'NIPANZE_FOREX_LISTING_EXPIRED: This forex request has expired.'
            USING ERRCODE = 'P0011';
    END IF;

    IF v_listing.requester_id = NEW.offer_maker_id THEN
        RAISE EXCEPTION 'NIPANZE_SELF_OFFER: You cannot make an offer on your own forex request.'
            USING ERRCODE = 'P0012';
    END IF;

    IF private.is_blocked_from_future_request(v_listing.requester_id, NEW.offer_maker_id, v_listing.listed_at) THEN
        RAISE EXCEPTION 'NIPANZE_BLOCKED: You cannot make an offer on this forex request.'
            USING ERRCODE = 'P0017';
    END IF;

    SELECT plan INTO v_plan
    FROM subscriptions
    WHERE user_id = NEW.offer_maker_id AND status = 'active';

    IF v_plan NOT IN ('lender', 'pro') THEN
        RAISE EXCEPTION 'NIPANZE_SUBSCRIPTION_REQUIRED: A Lender or Pro subscription is required to make forex offers.'
            USING ERRCODE = 'P0014';
    END IF;

    NEW.terms_locked_at := COALESCE(NEW.terms_locked_at, NOW());
    RETURN NEW;
END;
$$;

CREATE OR REPLACE VIEW public.v_forex_listings AS
SELECT
    fr.id AS request_id,
    fr.currency_held,
    fr.currency_needed,
    fr.amount,
    fr.country,
    fr.settlement_preference,
    fr.is_urgent,
    fr.preferred_rate,
    fr.terms_locked_at,
    fr.status,
    fr.number_of_offers,
    CASE WHEN fr.number_of_offers = 0 THEN 'low' WHEN fr.number_of_offers <= 2 THEN 'medium' ELSE 'high' END AS rate_coverage_tier,
    fr.listed_at,
    fr.expires_at,
    k.status AS kyc_status,
    ta.rating_avg AS trust_rating_avg,
    COALESCE(ta.review_count, 0) AS trust_review_count,
    COALESCE(ta.completed_deals_count, 0) AS trust_completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE) AS trust_is_repeat_participant,
    (p.phone_verified_at IS NOT NULL) AS trust_phone_verified,
    ta.response_time_bucket AS trust_response_time_bucket,
    (k.status = 'approved') AS trust_is_verified,
    GREATEST(fr.expires_at - NOW(), INTERVAL '0') AS time_remaining,
    (fr.expires_at < NOW() + INTERVAL '24 hours') AS closing_soon_24h,
    (fr.expires_at < NOW() + INTERVAL '6 hours') AS closing_soon_6h,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN p.preferred_bank ELSE NULL END AS preferred_bank,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN p.institution_type ELSE NULL END AS institution_type,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN p.is_bank_agent ELSE FALSE END AS is_bank_agent,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN TRUE ELSE FALSE END AS show_professional_tag
FROM public.forex_requests fr
JOIN public.profiles p ON p.id = fr.requester_id
LEFT JOIN public.kyc_verifications k ON k.user_id = fr.requester_id
LEFT JOIN public.trust_aggregates ta ON ta.user_id = fr.requester_id
WHERE fr.status = 'active'
  AND (auth.uid() IS NULL OR fr.requester_id <> auth.uid())
  AND NOT private.is_blocked_from_future_request(fr.requester_id, auth.uid(), fr.listed_at)
  AND (
    auth.uid() IS NULL OR NOT EXISTS (
      SELECT 1 FROM public.forex_offers fo
      WHERE fo.request_id = fr.id
        AND fo.offer_maker_id = auth.uid()
        AND fo.status IN ('pending', 'accepted')
    )
  );

DROP POLICY IF EXISTS "notifications: own rows" ON public.notifications;
CREATE POLICY "notifications: own rows"
    ON public.notifications FOR SELECT TO authenticated USING (
        user_id = auth.uid()
        AND (
            request_id IS NULL
            OR NOT EXISTS (
                SELECT 1 FROM public.loan_requests lr
                 WHERE lr.id = notifications.request_id
                   AND private.is_blocked_from_future_request(lr.borrower_id, auth.uid(), lr.listed_at)
            )
        )
        AND (
            forex_request_id IS NULL
            OR NOT EXISTS (
                SELECT 1 FROM public.forex_requests fr
                 WHERE fr.id = notifications.forex_request_id
                   AND private.is_blocked_from_future_request(fr.requester_id, auth.uid(), fr.listed_at)
            )
        )
    );

GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_blocks TO authenticated, service_role;
GRANT SELECT ON public.v_loan_listings, public.v_loan_listing_details, public.v_forex_listings TO authenticated, anon;

-- ============================================================
-- END MERGED SECTION: patch_blocked_users_visibility.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_avatar_storage.sql
-- ============================================================

-- NIPANZE AVATAR STORAGE — STANDALONE PATCH
-- Paste this file into the Supabase SQL Editor and run it once.
-- Safe to run again: bucket and policies are recreated deterministically.

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Keep avatar files private. The app reads them through signed URLs.
INSERT INTO storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
VALUES (
  'avatars',
  'avatars',
  FALSE,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "avatars: users upload own files" ON storage.objects;
DROP POLICY IF EXISTS "avatars: users replace own files" ON storage.objects;
DROP POLICY IF EXISTS "avatars: users read own files" ON storage.objects;

CREATE POLICY "avatars: users upload own files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = (SELECT auth.uid()::text)
);

CREATE POLICY "avatars: users replace own files"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = (SELECT auth.uid()::text)
)
WITH CHECK (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = (SELECT auth.uid()::text)
);

CREATE POLICY "avatars: users read own files"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = (SELECT auth.uid()::text)
);

-- ============================================================
-- END MERGED SECTION: patch_avatar_storage.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_clean_referral_codes.sql
-- ============================================================

-- ==============================================================================
-- NIPANZE REFERRAL SYSTEM — CLEANUP & UPPERCASE PATCH (v2)
-- ==============================================================================
-- Run this script in your Supabase SQL Editor.
-- 1. Strips 'NIPANZE-' prefix from existing codes in profiles, marketers, & referrals.
-- 2. Converts all referral codes to UPPERCASE (so lowercase/caps lock won't confuse anyone).
-- 3. Updates generate_referral_code and ensure_my_referral_marketer functions.
-- ==============================================================================

-- 1. UPDATE EXISTING CODES IN DATABASE
--------------------------------------------------------------------------------

UPDATE public.referral_marketers
SET referral_code = UPPER(REGEXP_REPLACE(referral_code, '^NIPANZE-', '', 'i')),
    updated_at = CURRENT_TIMESTAMP
WHERE referral_code ILIKE 'NIPANZE-%' OR referral_code != UPPER(referral_code);

UPDATE public.profiles
SET referral_code = UPPER(REGEXP_REPLACE(referral_code, '^NIPANZE-', '', 'i')),
    updated_at = CURRENT_TIMESTAMP
WHERE referral_code ILIKE 'NIPANZE-%' OR referral_code != UPPER(referral_code);

UPDATE public.referrals
SET referral_code = UPPER(REGEXP_REPLACE(referral_code, '^NIPANZE-', '', 'i')),
    updated_at = CURRENT_TIMESTAMP
WHERE referral_code ILIKE 'NIPANZE-%' OR referral_code != UPPER(referral_code);


-- 2. UPDATE CODE GENERATOR (NO NIPANZE PREFIX & ALWAYS UPPERCASE)
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION private.generate_referral_code(p_full_name TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_seed TEXT;
    v_code TEXT;
BEGIN
    v_seed := UPPER(REGEXP_REPLACE(COALESCE(NULLIF(SPLIT_PART(TRIM(p_full_name), ' ', 1), ''), 'USER'), '[^A-Z0-9]', '', 'g'));
    v_seed := LEFT(COALESCE(NULLIF(v_seed, ''), 'USER'), 5);

    LOOP
        v_code := v_seed || UPPER(SUBSTRING(REPLACE(gen_random_uuid()::TEXT, '-', '') FROM 1 FOR 4));
        EXIT WHEN NOT EXISTS (
            SELECT 1 FROM public.referral_marketers WHERE UPPER(referral_code) = v_code
        ) AND NOT EXISTS (
            SELECT 1 FROM public.profiles WHERE UPPER(referral_code) = v_code
        );
    END LOOP;

    RETURN v_code;
END;
$$;


-- 3. UPDATE ENSURE FUNCTION TO AUTO-CLEAN EXISTING RECORDS ON FETCH
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.ensure_my_referral_marketer(p_country TEXT DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_profile  public.profiles%ROWTYPE;
    v_marketer public.referral_marketers%ROWTYPE;
    v_campaign_id UUID;
    v_country TEXT;
    v_code    TEXT;
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = auth.uid();
    IF NOT FOUND THEN
        INSERT INTO public.profiles (id, email, full_name, account_status)
        VALUES (
            auth.uid(),
            COALESCE((SELECT email FROM auth.users WHERE id = auth.uid()), 'user@nipanze.app'),
            'Nipanze User',
            'active'
        )
        ON CONFLICT (id) DO NOTHING;
        SELECT * INTO v_profile FROM public.profiles WHERE id = auth.uid();
    END IF;

    v_country := UPPER(COALESCE(NULLIF(p_country, ''), v_profile.country, 'UG'));
    IF NOT EXISTS (SELECT 1 FROM public.countries WHERE code = v_country) THEN
        v_country := v_profile.country;
    END IF;

    -- Clean up legacy prefix / mixed-case on v_profile.referral_code if present
    IF v_profile.referral_code IS NOT NULL AND (v_profile.referral_code ILIKE 'NIPANZE-%' OR v_profile.referral_code != UPPER(v_profile.referral_code)) THEN
        v_profile.referral_code := UPPER(REGEXP_REPLACE(v_profile.referral_code, '^NIPANZE-', '', 'i'));
        UPDATE public.profiles
        SET referral_code = v_profile.referral_code
        WHERE id = v_profile.id;
    END IF;

    SELECT id INTO v_campaign_id
    FROM public.referral_campaigns
    WHERE status = 'active'
      AND (country IS NULL OR country = v_country)
      AND (start_date IS NULL OR start_date <= CURRENT_DATE)
      AND (end_date   IS NULL OR end_date   >= CURRENT_DATE)
    ORDER BY country NULLS LAST, created_at DESC
    LIMIT 1;

    SELECT * INTO v_marketer
    FROM public.referral_marketers
    WHERE profile_id = v_profile.id;

    IF NOT FOUND THEN
        v_code := UPPER(COALESCE(v_profile.referral_code, private.generate_referral_code(v_profile.full_name)));
        INSERT INTO public.referral_marketers (
            profile_id, referral_code, status, default_campaign_id,
            joined_at, last_activity_at, metadata
        )
        VALUES (
            v_profile.id, v_code, 'active', v_campaign_id,
            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, '{}'::JSONB
        )
        RETURNING * INTO v_marketer;
    ELSE
        -- Auto-clean existing marketer record if it still has NIPANZE- or lowercase
        IF v_marketer.referral_code ILIKE 'NIPANZE-%' OR v_marketer.referral_code != UPPER(v_marketer.referral_code) THEN
            v_code := UPPER(REGEXP_REPLACE(v_marketer.referral_code, '^NIPANZE-', '', 'i'));
            UPDATE public.referral_marketers
            SET referral_code = v_code,
                default_campaign_id = COALESCE(default_campaign_id, v_campaign_id),
                last_activity_at    = CURRENT_TIMESTAMP,
                updated_at          = CURRENT_TIMESTAMP
            WHERE id = v_marketer.id
            RETURNING * INTO v_marketer;
        ELSE
            v_code := v_marketer.referral_code;
            UPDATE public.referral_marketers
            SET default_campaign_id = COALESCE(default_campaign_id, v_campaign_id),
                last_activity_at    = CURRENT_TIMESTAMP,
                updated_at          = CURRENT_TIMESTAMP
            WHERE id = v_marketer.id
            RETURNING * INTO v_marketer;
        END IF;
    END IF;

    UPDATE public.profiles
    SET referral_code        = COALESCE(referral_code, v_code),
        marketing_enabled    = TRUE,
        marketing_country    = COALESCE(marketing_country, v_country),
        marketing_joined_at  = COALESCE(marketing_joined_at, CURRENT_TIMESTAMP),
        updated_at           = CURRENT_TIMESTAMP
    WHERE id = v_profile.id
    RETURNING * INTO v_profile;

    RETURN jsonb_build_object(
        'marketer_id',       v_marketer.id,
        'user_id',           v_profile.id,
        'referral_code',     v_marketer.referral_code,
        'referral_link',     'https://nipanze.app/r/' || v_marketer.referral_code,
        'status',            v_marketer.status,
        'marketing_enabled', v_profile.marketing_enabled,
        'marketing_country', v_profile.marketing_country,
        'joined_at',         v_marketer.joined_at
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.ensure_my_referral_marketer(TEXT) TO authenticated;

-- ============================================================
-- END MERGED SECTION: patch_clean_referral_codes.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_20260830_platform_enhancements.sql
-- ============================================================

-- Platform enhancements: referral validation and account safety helpers.

CREATE OR REPLACE FUNCTION public.validate_referral_code(p_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_code          TEXT;
    v_user_id       UUID;
    v_referrer_id   UUID;
    v_referrer_name TEXT;
BEGIN
    v_code := UPPER(TRIM(COALESCE(p_code, '')));
    v_user_id := auth.uid();

    IF v_code = '' THEN
        RETURN jsonb_build_object(
            'valid', FALSE,
            'reason', 'missing_code',
            'message', 'Enter a referral code.',
            'referrer_name', NULL
        );
    END IF;

    SELECT rm.profile_id, COALESCE(p.full_name, 'Nipanze member')
    INTO   v_referrer_id, v_referrer_name
    FROM   public.referral_marketers rm
    LEFT JOIN public.profiles p ON p.id = rm.profile_id
    WHERE  UPPER(rm.referral_code) = v_code
      AND  rm.status IN ('new', 'active')
    LIMIT  1;

    IF v_referrer_id IS NULL THEN
        SELECT p.id, COALESCE(p.full_name, 'Nipanze member')
        INTO   v_referrer_id, v_referrer_name
        FROM   public.profiles p
        WHERE  UPPER(p.referral_code) = v_code
        LIMIT  1;
    END IF;

    IF v_referrer_id IS NULL THEN
        RETURN jsonb_build_object(
            'valid', FALSE,
            'reason', 'code_not_found',
            'message', 'Referral code was not found.',
            'referrer_name', NULL
        );
    END IF;

    IF v_user_id IS NOT NULL AND v_referrer_id = v_user_id THEN
        RETURN jsonb_build_object(
            'valid', FALSE,
            'reason', 'self_referral',
            'message', 'You cannot use your own referral code.',
            'referrer_name', v_referrer_name
        );
    END IF;

    IF v_user_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM public.referrals WHERE referred_user_id = v_user_id
    ) THEN
        RETURN jsonb_build_object(
            'valid', FALSE,
            'reason', 'already_recorded',
            'message', 'A referral code has already been used on this account.',
            'referrer_name', v_referrer_name
        );
    END IF;

    RETURN jsonb_build_object(
        'valid', TRUE,
        'reason', 'ok',
        'message', 'Referral code accepted.',
        'referrer_name', v_referrer_name
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.validate_referral_code(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_referral_code(TEXT) TO anon;

-- ============================================================
-- END MERGED SECTION: patch_20260830_platform_enhancements.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_20260831_bank_institution_matching.sql
-- ============================================================

-- SQL Patch: Bank & Credit Institution Matching
-- Enables borrowers to opt into institution matching for free, and allows Pro agents to filter matching listings.

-- 1. Add allow_institution_matching to profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS allow_institution_matching BOOLEAN DEFAULT FALSE NOT NULL;
COMMENT ON COLUMN public.profiles.allow_institution_matching IS
'When true, user opts into having their loan requests tagged and discoverable by verified bank/institution agents.';

-- 2. Update v_loan_listings to expose allow_institution_matching & preferred_bank when matching is enabled
-- DROP first because CREATE OR REPLACE cannot reorder/rename existing view columns
DROP VIEW IF EXISTS public.v_loan_listing_details CASCADE;
DROP VIEW IF EXISTS public.v_loan_listings CASCADE;
CREATE VIEW public.v_loan_listings AS
SELECT
    lr.id AS request_id,
    lr.title,
    lr.purpose,
    lr.district,
    lr.country,
    c.currency_code,
    lr.duration_months,
    lr.requested_amount,
    lr.preferred_repayment_plan,
    lr.repayment_amount_per_period,
    lr.repayment_timeline,
    lr.suggested_interest_rate_pct,
    lr.suggested_late_fee_pct,
    lr.suggested_repayment_frequency,
    lr.suggested_installment_amount,
    lr.terms_locked_at,
    lr.status,
    lr.number_of_offers,
    CASE WHEN lr.number_of_offers = 0 THEN 'low' WHEN lr.number_of_offers <= 2 THEN 'medium' ELSE 'high' END AS offer_coverage_tier,
    lr.listed_at,
    lr.expires_at,
    k.status AS kyc_status,
    ta.rating_avg AS trust_rating_avg,
    COALESCE(ta.review_count, 0) AS trust_review_count,
    COALESCE(ta.completed_deals_count, 0) AS trust_completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE) AS trust_is_repeat_participant,
    (p.phone_verified_at IS NOT NULL) AS trust_phone_verified,
    ta.response_time_bucket AS trust_response_time_bucket,
    (k.status = 'approved') AS trust_is_verified,
    GREATEST(lr.expires_at - NOW(), INTERVAL '0') AS time_remaining,
    (lr.expires_at < NOW() + INTERVAL '24 hours') AS closing_soon_24h,
    (lr.expires_at < NOW() + INTERVAL '6 hours') AS closing_soon_6h,
    p.allow_institution_matching,
    CASE
        WHEN p.allow_institution_matching THEN p.preferred_bank
        WHEN p.show_professional_tag AND EXISTS (
            SELECT 1 FROM public.subscriptions s
            WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
        ) THEN p.preferred_bank
        ELSE NULL
    END AS preferred_bank,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN p.institution_type ELSE NULL END AS institution_type,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN p.is_bank_agent ELSE FALSE END AS is_bank_agent,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN TRUE ELSE FALSE END AS show_professional_tag,
    CASE WHEN EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN lr.has_collateral ELSE FALSE END AS has_collateral,
    CASE WHEN EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN lr.collateral_details ELSE NULL END AS collateral_details,
    CASE WHEN EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN lr.collateral_estimated_value ELSE NULL END AS collateral_estimated_value,
    CASE WHEN EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN lr.collateral_location ELSE NULL END AS collateral_location
FROM public.loan_requests lr
JOIN public.profiles p ON p.id = lr.borrower_id
JOIN public.countries c ON c.code = lr.country
LEFT JOIN public.kyc_verifications k ON k.user_id = lr.borrower_id
LEFT JOIN public.trust_aggregates ta ON ta.user_id = lr.borrower_id
WHERE lr.status = 'active'
  AND (auth.uid() IS NULL OR lr.borrower_id <> auth.uid())
  AND NOT private.is_blocked_from_future_request(lr.borrower_id, auth.uid(), lr.listed_at)
  AND (
    auth.uid() IS NULL OR NOT EXISTS (
      SELECT 1 FROM public.loan_offers lo
      WHERE lo.request_id = lr.id
        AND lo.lender_id = auth.uid()
        AND lo.status IN ('pending', 'accepted')
    )
  );

-- 3. Update v_loan_listing_details
CREATE VIEW public.v_loan_listing_details AS
SELECT
    lr.id AS request_id,
    lr.title,
    lr.purpose,
    lr.district,
    lr.country,
    c.currency_code,
    lr.duration_months,
    lr.requested_amount,
    lr.preferred_repayment_plan,
    lr.repayment_amount_per_period,
    lr.repayment_timeline,
    lr.suggested_interest_rate_pct,
    lr.suggested_late_fee_pct,
    lr.suggested_repayment_frequency,
    lr.suggested_installment_amount,
    lr.terms_locked_at,
    lr.status,
    lr.number_of_offers,
    CASE WHEN lr.number_of_offers = 0 THEN 'low' WHEN lr.number_of_offers <= 2 THEN 'medium' ELSE 'high' END AS offer_coverage_tier,
    lr.listed_at,
    lr.expires_at,
    k.status AS kyc_status,
    ta.rating_avg AS trust_rating_avg,
    COALESCE(ta.review_count, 0) AS trust_review_count,
    COALESCE(ta.completed_deals_count, 0) AS trust_completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE) AS trust_is_repeat_participant,
    (p.phone_verified_at IS NOT NULL) AS trust_phone_verified,
    ta.response_time_bucket AS trust_response_time_bucket,
    (k.status = 'approved') AS trust_is_verified,
    GREATEST(lr.expires_at - NOW(), INTERVAL '0') AS time_remaining,
    (lr.expires_at < NOW() + INTERVAL '24 hours') AS closing_soon_24h,
    (lr.expires_at < NOW() + INTERVAL '6 hours') AS closing_soon_6h,
    p.allow_institution_matching,
    CASE
        WHEN p.allow_institution_matching THEN p.preferred_bank
        WHEN p.show_professional_tag AND EXISTS (
            SELECT 1 FROM public.subscriptions s
            WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro'
        ) THEN p.preferred_bank
        ELSE NULL
    END AS preferred_bank,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN p.institution_type ELSE NULL END AS institution_type,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN p.is_bank_agent ELSE FALSE END AS is_bank_agent,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN TRUE ELSE FALSE END AS show_professional_tag,
    CASE WHEN EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN lr.has_collateral ELSE FALSE END AS has_collateral,
    CASE WHEN EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN lr.collateral_details ELSE NULL END AS collateral_details,
    CASE WHEN EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN lr.collateral_estimated_value ELSE NULL END AS collateral_estimated_value,
    CASE WHEN EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN lr.collateral_location ELSE NULL END AS collateral_location
FROM public.loan_requests lr
JOIN public.profiles p ON p.id = lr.borrower_id
JOIN public.countries c ON c.code = lr.country
LEFT JOIN public.kyc_verifications k ON k.user_id = lr.borrower_id
LEFT JOIN public.trust_aggregates ta ON ta.user_id = lr.borrower_id
WHERE lr.status = 'active'
  AND NOT private.is_blocked_from_future_request(lr.borrower_id, auth.uid(), lr.listed_at);

-- 4. Update get_marketplace_pro_filtered to support p_institution_match_only
CREATE OR REPLACE FUNCTION get_marketplace_pro_filtered(
    p_employment_type        employment_type_enum DEFAULT NULL,
    p_income_bracket         TEXT                  DEFAULT NULL,
    p_suggested_terms_only   BOOLEAN               DEFAULT FALSE,
    p_verified_only          BOOLEAN               DEFAULT FALSE,
    p_country                TEXT                  DEFAULT NULL,
    p_institution_match_only BOOLEAN               DEFAULT FALSE
)
RETURNS SETOF v_loan_listings
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM subscriptions
        WHERE user_id = auth.uid() AND status = 'active' AND plan = 'pro'
    ) THEN
        RAISE EXCEPTION 'NIPANZE_PRO_REQUIRED: Advanced marketplace filters require a Pro subscription.'
            USING ERRCODE = 'P0050';
    END IF;

    RETURN QUERY
    SELECT vl.*
    FROM v_loan_listings vl
    JOIN loan_requests lr ON lr.id = vl.request_id
    JOIN profiles p ON p.id = lr.borrower_id
    LEFT JOIN kyc_verifications k ON k.user_id = lr.borrower_id
    WHERE (p_employment_type IS NULL OR p.employment_type = p_employment_type)
      AND (p_income_bracket IS NULL OR fn_income_bracket(p.monthly_income) = p_income_bracket)
      AND (NOT p_suggested_terms_only OR lr.suggested_interest_rate_pct IS NOT NULL)
      AND (NOT p_verified_only OR k.status = 'approved')
      AND (p_country IS NULL OR vl.country = p_country)
      AND (NOT p_institution_match_only OR p.allow_institution_matching = TRUE);
END;
$$;

GRANT SELECT ON public.v_loan_listings, public.v_loan_listing_details TO authenticated, anon;

COMMENT ON VIEW public.v_loan_listings IS
'Anonymised marketplace feed. allow_institution_matching and preferred_bank are now included.
 preferred_bank is exposed when the borrower opts in (allow_institution_matching = true)
 OR when the viewing agent is Pro. Collateral and professional tags remain Pro-masked.';

COMMENT ON VIEW public.v_loan_listing_details IS
'Single-listing detail view for active loan requests. Adds allow_institution_matching
 and conditional preferred_bank exposure matching v_loan_listings logic.';

-- ============================================================
-- END MERGED SECTION: patch_20260831_bank_institution_matching.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_20260902_unlock_contact_permissions.sql
-- ============================================================

-- ============================================================
-- Patch: Allow both Borrower and Lender in a locked deal to unlock contact details
-- Date: 2026-09-02
-- Description: Updates private.unlock_contact_internal to validate p_caller_id
--              against both borrower and lender IDs, and records p_caller_id
--              as revealed_by in contact_reveals.
-- ============================================================

CREATE OR REPLACE FUNCTION private.unlock_contact_internal(
    p_agreement_id UUID,
    p_caller_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$
DECLARE
    v_agreement  public.agreements%ROWTYPE;
    v_offer      public.loan_offers%ROWTYPE;
    v_reveal     public.contact_reveals%ROWTYPE;
    v_borrower   public.profiles%ROWTYPE;
    v_lender     public.profiles%ROWTYPE;
    v_borrower_auth RECORD;
    v_lender_auth RECORD;
    v_borrower_id UUID;
    v_lender_id UUID;
    v_result JSONB;
BEGIN
    SELECT * INTO v_agreement FROM public.agreements WHERE id = p_agreement_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'NIPANZE_AGREEMENT_NOT_FOUND' USING ERRCODE = 'P0041';
    END IF;

    IF v_agreement.status != 'locked' THEN
        RAISE EXCEPTION 'NIPANZE_AGREEMENT_NOT_LOCKED: Agreement must be locked before unlocking contact.'
            USING ERRCODE = 'P0045';
    END IF;

    SELECT * INTO v_offer FROM public.loan_offers WHERE id = v_agreement.offer_id;
    SELECT borrower_id INTO v_borrower_id FROM public.loan_requests WHERE id = v_agreement.request_id;
    v_lender_id := v_offer.lender_id;

    -- Caller validation (must be either borrower or lender)
    IF p_caller_id != v_borrower_id AND p_caller_id != v_lender_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Only deal participants can unlock contact details.'
            USING ERRCODE = 'P0046';
    END IF;

    -- Get profiles
    SELECT * INTO v_borrower FROM public.profiles WHERE id = v_borrower_id;
    SELECT * INTO v_lender FROM public.profiles WHERE id = v_lender_id;

    -- Get email from auth.users (requires SECURITY DEFINER)
    SELECT email INTO v_borrower_auth FROM auth.users WHERE id = v_borrower_id;
    SELECT email INTO v_lender_auth FROM auth.users WHERE id = v_lender_id;

    -- Get or create contact_reveal
    SELECT * INTO v_reveal FROM public.contact_reveals WHERE offer_id = v_agreement.offer_id;
    IF v_reveal IS NULL THEN
        INSERT INTO public.contact_reveals (offer_id, request_id, revealed_by, status, revealed_at)
        VALUES (v_agreement.offer_id, v_agreement.request_id, p_caller_id, 'revealed', NOW())
        RETURNING * INTO v_reveal;
    ELSE
        UPDATE public.contact_reveals
           SET status = 'revealed', revealed_at = NOW()
         WHERE id = v_reveal.id;
        v_reveal.status := 'revealed';
        v_reveal.revealed_at := NOW();
    END IF;

    -- Result includes contact details
    v_result := JSONB_BUILD_OBJECT(
        'agreement_id', v_agreement.id,
        'revealed_at', v_reveal.revealed_at,
        'borrower', JSONB_BUILD_OBJECT(
            'full_name', v_borrower.full_name,
            'phone', v_borrower.phone,
            'email', v_borrower_auth.email
        ),
        'lender', JSONB_BUILD_OBJECT(
            'full_name', v_lender.full_name,
            'phone', v_lender.phone,
            'email', v_lender_auth.email
        )
    );

    -- Notify both parties
    INSERT INTO public.notifications (user_id, type, title, body, request_id, offer_id)
    VALUES
        (v_borrower_id, 'contact_revealed', 'Contact details unlocked',
         'You can now connect with your lender directly.',
         v_agreement.request_id, v_agreement.offer_id),
        (v_lender_id, 'contact_revealed', 'Borrower unlocked contact',
         'You can now connect with the borrower directly.',
         v_agreement.request_id, v_agreement.offer_id);

    -- Audit
    INSERT INTO public.audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
    VALUES (p_caller_id, 'contact_revealed', 'contact_reveals', v_reveal.id, 'unlock_contact',
        JSONB_BUILD_OBJECT(
            'agreement_id', p_agreement_id,
            'revealed_at', NOW()
        ));

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION private.unlock_contact_internal(uuid, uuid) TO authenticated, service_role;

-- ============================================================
-- END MERGED SECTION: patch_20260902_unlock_contact_permissions.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_20260905_allow_offer_withdrawal.sql
-- ============================================================

-- Allow lenders to transition their own pending offers to withdrawn.
-- The USING clause checks the old row; WITH CHECK checks the updated row.
DROP POLICY IF EXISTS "loan_offers: lender withdraw or admin" ON public.loan_offers;
CREATE POLICY "loan_offers: lender withdraw or admin"
    ON public.loan_offers FOR UPDATE TO authenticated
    USING (
        (lender_id = auth.uid() AND status = 'pending')
        OR private.is_admin()
    )
    WITH CHECK (
        (lender_id = auth.uid() AND status = 'withdrawn')
        OR private.is_admin()
    );

-- ============================================================
-- END MERGED SECTION: patch_20260905_allow_offer_withdrawal.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_fix_forex_seed_nairobi_equity.sql
-- ============================================================

-- Clean repeated Kenya forex settlement strings so the marketplace card shows either:
--   - a single settlement label, and
--   - the Nairobi location separately,
-- without duplicate bank names or repeated labels in one string.

BEGIN;

-- Generic bank settlement: keep the location in the city field, not repeated in the label.
UPDATE public.forex_requests
SET settlement_preference = 'Bank transfer, Nairobi'
WHERE country = 'KE' AND (
    lower(settlement_preference) LIKE '%equity bank%' OR
    lower(settlement_preference) LIKE '%kcb%' OR
    lower(settlement_preference) LIKE '%bank transfer%'
);

-- M-Pesa settlement: no repeated mobile label or extra bank wording.
UPDATE public.forex_requests
SET settlement_preference = 'M-Pesa transfer, Nairobi'
WHERE country = 'KE' AND (
    lower(settlement_preference) LIKE '%m-pesa%' OR
    lower(settlement_preference) LIKE '%mpesa%' OR
    lower(settlement_preference) LIKE '%mobile money%'
);

-- Keep only a single Nairobi city entry for Kenya examples.
UPDATE public.forex_requests
SET settlement_preference = 'M-Pesa transfer, Nairobi'
WHERE country = 'KE'
  AND lower(settlement_preference) = 'm-pesa transfer, nairobi';

COMMIT;

-- ============================================================
-- END MERGED SECTION: patch_fix_forex_seed_nairobi_equity.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_forex_request_district.sql
-- ============================================================

-- Standalone Supabase Cloud patch: add district/location to forex_requests
-- and expose it through the public forex listings view.

BEGIN;

ALTER TABLE public.forex_requests
  ADD COLUMN IF NOT EXISTS district TEXT;

UPDATE public.forex_requests
SET district = 'Other'
WHERE district IS NULL;

ALTER TABLE public.forex_requests
  ALTER COLUMN district SET NOT NULL;

DROP VIEW IF EXISTS public.v_forex_listings;

CREATE VIEW public.v_forex_listings AS
SELECT
    fr.id                                                                     AS request_id,
    fr.currency_held,
    fr.currency_needed,
    fr.amount,
    fr.country,
    fr.district,
    fr.settlement_preference,
    fr.is_urgent,
    fr.preferred_rate,
    fr.terms_locked_at,
    fr.status,
    fr.number_of_offers,
    CASE
        WHEN fr.number_of_offers = 0 THEN 'low'
        WHEN fr.number_of_offers <= 2 THEN 'medium'
        ELSE 'high'
    END                                                                       AS rate_coverage_tier,
    fr.listed_at,
    fr.expires_at,
    k.status                                                                  AS kyc_status,
    ta.rating_avg                                                             AS trust_rating_avg,
    COALESCE(ta.review_count, 0)                                              AS trust_review_count,
    COALESCE(ta.completed_deals_count, 0)                                     AS trust_completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE)                                  AS trust_is_repeat_participant,
    (p.phone_verified_at IS NOT NULL)                                         AS trust_phone_verified,
    ta.response_time_bucket                                                   AS trust_response_time_bucket,
    (k.status = 'approved')                                                   AS trust_is_verified,
    GREATEST(fr.expires_at - NOW(), INTERVAL '0')                            AS time_remaining,
    (fr.expires_at < NOW() + INTERVAL '24 hours')                             AS closing_soon_24h,
    (fr.expires_at < NOW() + INTERVAL '6 hours')                             AS closing_soon_6h
FROM public.forex_requests fr
JOIN public.profiles p ON p.id = fr.requester_id
LEFT JOIN public.kyc_verifications k ON k.user_id = fr.requester_id
LEFT JOIN public.trust_aggregates ta ON ta.user_id = fr.requester_id
WHERE fr.status = 'active'
  AND (
    auth.uid() IS NULL OR fr.requester_id <> auth.uid()
  )
  AND (
    auth.uid() IS NULL OR NOT EXISTS (
      SELECT 1 FROM public.forex_offers fo
      WHERE fo.request_id = fr.id
        AND fo.offer_maker_id = auth.uid()
        AND fo.status IN ('pending', 'accepted')
    )
  );

GRANT SELECT ON public.v_forex_listings TO authenticated, anon;

COMMIT;

-- ============================================================
-- END MERGED SECTION: patch_forex_request_district.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_forex_settlement_detail.sql
-- ============================================================

-- Standalone Supabase Cloud patch: split forex settlement into method + detail.
-- Keeps legacy settlement_preference values readable while allowing richer bank/
-- mobile-money / in-person provider details.

BEGIN;

ALTER TABLE public.forex_requests
  ADD COLUMN IF NOT EXISTS settlement_method TEXT,
  ADD COLUMN IF NOT EXISTS settlement_details TEXT;

UPDATE public.forex_requests fr
SET
  settlement_method = CASE
    WHEN fr.settlement_method IS NOT NULL AND trim(fr.settlement_method) <> '' THEN trim(fr.settlement_method)
    WHEN lower(fr.settlement_preference) LIKE '%bank%' THEN 'bank'
    WHEN lower(fr.settlement_preference) LIKE '%m-pesa%' OR lower(fr.settlement_preference) LIKE '%mpesa%' OR lower(fr.settlement_preference) LIKE '%mobile%' OR lower(fr.settlement_preference) LIKE '%money%' THEN 'mobile_money'
    WHEN lower(fr.settlement_preference) LIKE '%person%' OR lower(fr.settlement_preference) LIKE '%cash%' OR lower(fr.settlement_preference) LIKE '%pickup%' THEN 'in_person'
    ELSE 'other'
  END,
  settlement_details = CASE
    WHEN fr.settlement_details IS NOT NULL AND trim(fr.settlement_details) <> '' THEN trim(fr.settlement_details)
    WHEN fr.settlement_preference IS NULL OR trim(fr.settlement_preference) = '' THEN NULL
    WHEN lower(fr.settlement_preference) LIKE '%bank%' THEN NULLIF(
      trim(regexp_replace(fr.settlement_preference, '(?i)\b(bank transfer|bank|transfer)\b', '', 'g')),
      ''
    )
    WHEN lower(fr.settlement_preference) LIKE '%m-pesa%' OR lower(fr.settlement_preference) LIKE '%mpesa%' OR lower(fr.settlement_preference) LIKE '%mobile%' OR lower(fr.settlement_preference) LIKE '%money%' THEN NULLIF(
      trim(regexp_replace(fr.settlement_preference, '(?i)\b(mobile money|mobile|money)\b', '', 'g')),
      ''
    )
    WHEN lower(fr.settlement_preference) LIKE '%person%' OR lower(fr.settlement_preference) LIKE '%cash%' OR lower(fr.settlement_preference) LIKE '%pickup%' THEN NULLIF(
      trim(regexp_replace(fr.settlement_preference, '(?i)\b(in person|cash|pickup)\b', '', 'g')),
      ''
    )
    ELSE NULLIF(trim(fr.settlement_preference), '')
  END
WHERE fr.settlement_method IS NULL OR fr.settlement_details IS NULL;

ALTER TABLE public.forex_requests
  ALTER COLUMN settlement_method SET DEFAULT 'other';

DROP VIEW IF EXISTS public.v_forex_listings;

CREATE VIEW public.v_forex_listings AS
SELECT
    fr.id                                                                     AS request_id,
    fr.currency_held,
    fr.currency_needed,
    fr.amount,
    fr.country,
    fr.district,
    CASE
        WHEN fr.settlement_details IS NOT NULL AND trim(fr.settlement_details) <> '' THEN
            CASE fr.settlement_method
                WHEN 'bank' THEN 'Bank transfer — ' || fr.settlement_details
                WHEN 'mobile_money' THEN 'Mobile money — ' || fr.settlement_details
                WHEN 'in_person' THEN 'In person — ' || fr.settlement_details
                ELSE 'Other — ' || fr.settlement_details
            END
        WHEN fr.settlement_preference IS NOT NULL AND trim(fr.settlement_preference) <> '' THEN fr.settlement_preference
        WHEN fr.settlement_method = 'bank' THEN 'Bank transfer'
        WHEN fr.settlement_method = 'mobile_money' THEN 'Mobile money'
        WHEN fr.settlement_method = 'in_person' THEN 'In person'
        ELSE 'Other'
    END                                                                       AS settlement_preference,
    fr.settlement_method,
    fr.settlement_details,
    fr.is_urgent,
    fr.preferred_rate,
    fr.terms_locked_at,
    fr.status,
    fr.number_of_offers,
    CASE
        WHEN fr.number_of_offers = 0 THEN 'low'
        WHEN fr.number_of_offers <= 2 THEN 'medium'
        ELSE 'high'
    END                                                                       AS rate_coverage_tier,
    fr.listed_at,
    fr.expires_at,
    k.status                                                                  AS kyc_status,
    ta.rating_avg                                                             AS trust_rating_avg,
    COALESCE(ta.review_count, 0)                                              AS trust_review_count,
    COALESCE(ta.completed_deals_count, 0)                                     AS trust_completed_deals_count,
    COALESCE(ta.is_repeat_participant, FALSE)                                  AS trust_is_repeat_participant,
    (p.phone_verified_at IS NOT NULL)                                         AS trust_phone_verified,
    ta.response_time_bucket                                                   AS trust_response_time_bucket,
    (k.status = 'approved')                                                   AS trust_is_verified,
    GREATEST(fr.expires_at - NOW(), INTERVAL '0')                            AS time_remaining,
    (fr.expires_at < NOW() + INTERVAL '24 hours')                             AS closing_soon_24h,
    (fr.expires_at < NOW() + INTERVAL '6 hours')                              AS closing_soon_6h,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN p.preferred_bank ELSE NULL END AS preferred_bank,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN p.institution_type ELSE NULL END AS institution_type,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN p.is_bank_agent ELSE FALSE END AS is_bank_agent,
    CASE WHEN p.show_professional_tag AND EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.user_id = auth.uid() AND s.status = 'active' AND s.plan = 'pro') THEN TRUE ELSE FALSE END AS show_professional_tag
FROM public.forex_requests fr
JOIN public.profiles p ON p.id = fr.requester_id
LEFT JOIN public.kyc_verifications k ON k.user_id = fr.requester_id
LEFT JOIN public.trust_aggregates ta ON ta.user_id = fr.requester_id
WHERE fr.status = 'active'
  AND (
    auth.uid() IS NULL OR fr.requester_id <> auth.uid()
  )
  AND NOT private.is_blocked_from_future_request(fr.requester_id, auth.uid(), fr.listed_at)
  AND (
    auth.uid() IS NULL OR NOT EXISTS (
      SELECT 1 FROM public.forex_offers fo
      WHERE fo.request_id = fr.id
        AND fo.offer_maker_id = auth.uid()
        AND fo.status IN ('pending', 'accepted')
    )
  );

GRANT SELECT ON public.v_forex_listings TO authenticated, anon;

COMMIT;

-- ============================================================
-- END MERGED SECTION: patch_forex_settlement_detail.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_more_ug_kenya_loan_requests.sql
-- ============================================================

-- More Uganda + Kenya loan requests for demo/testing
-- Safe to run multiple times: uses ON CONFLICT DO NOTHING.

BEGIN;

-- -----------------------------------------------------------------------------
-- Uganda loan requests
-- -----------------------------------------------------------------------------
INSERT INTO loan_requests (
    id, borrower_id, country, title, purpose, requested_amount, duration_months,
    income_source, preferred_repayment_plan, repayment_amount_per_period,
    repayment_timeline, district, status, listed_at, expires_at, contracted_at,
    number_of_offers, views_count, created_at
) VALUES
    (
        'c1000000-0000-0000-0000-000000001101', '10000000-0000-0000-0000-000000000005', 'UG',
        'School Fees Top-Up', 'Pay the second semester tuition balance for my diploma at Kyambogo University',
        2200000, 12, 'Salary — UGX 4,500,000', 'monthly', 210000,
        '12 months starting April 2026', 'Kampala', 'active',
        NOW() - INTERVAL '1 day', NOW() + INTERVAL '18 days', NULL, 0, 44,
        NOW() - INTERVAL '1 day'
    ),
    (
        'c1000000-0000-0000-0000-000000001102', '10000000-0000-0000-0000-000000000006', 'UG',
        'Clinic Equipment Upgrade', 'Replace old clinic devices and buy basic diagnostic tools for a small family clinic',
        4800000, 18, 'Salary — UGX 3,200,000', 'monthly', 280000,
        '18 months starting May 2026', 'Wakiso', 'active',
        NOW() - INTERVAL '2 days', NOW() + INTERVAL '17 days', NULL, 1, 57,
        NOW() - INTERVAL '2 days'
    ),
    (
        'c1000000-0000-0000-0000-000000001103', '10000000-0000-0000-0000-000000000007', 'UG',
        'Agribusiness Expansion', 'Expand maize and cassava trading with a second pickup truck route to western Uganda',
        7600000, 24, 'Salary — UGX 5,800,000', 'monthly', 360000,
        '24 months starting April 2026', 'Mukono', 'active',
        NOW() - INTERVAL '3 days', NOW() + INTERVAL '16 days', NULL, 2, 62,
        NOW() - INTERVAL '3 days'
    ),
    (
        'c1000000-0000-0000-0000-000000001104', '10000000-0000-0000-0000-000000000008', 'UG',
        'Bakery Working Capital', 'Buy flour, packaging, and fuel for a growing bakery serving weekend orders in Ntinda',
        3100000, 9, 'Business income — UGX 2,800,000', 'monthly', 390000,
        '9 months starting May 2026', 'Central', 'active',
        NOW() - INTERVAL '4 days', NOW() + INTERVAL '14 days', NULL, 0, 31,
        NOW() - INTERVAL '4 days'
    ),
    (
        'c1000000-0000-0000-0000-000000001105', '10000000-0000-0000-0000-000000000010', 'UG',
        'Emergency Medical Treatment', 'Cover emergency surgery and post-op care after a recent accident',
        4200000, 12, 'Salary — UGX 3,300,000', 'monthly', 390000,
        '12 months starting April 2026', 'Eastern', 'active',
        NOW() - INTERVAL '1 day', NOW() + INTERVAL '20 days', NULL, 1, 49,
        NOW() - INTERVAL '1 day'
    ),
    (
        'c1000000-0000-0000-0000-000000001106', '10000000-0000-0000-0000-000000000015', 'UG',
        'Solar Home Installation', 'Install a rooftop solar setup for my family home and small office in Entebbe',
        5400000, 18, 'Salary — UGX 2,900,000', 'monthly', 330000,
        '18 months starting June 2026', 'Entebbe', 'active',
        NOW() - INTERVAL '5 days', NOW() + INTERVAL '12 days', NULL, 1, 28,
        NOW() - INTERVAL '5 days'
    ),
    (
        'c1000000-0000-0000-0000-000000001107', '10000000-0000-0000-0000-000000000016', 'UG',
        'Commercial Van Deposit', 'Pay the deposit for a second delivery van to support a growing logistics business',
        8800000, 24, 'Salary — UGX 5,200,000', 'monthly', 410000,
        '24 months starting May 2026', 'Mbarara', 'active',
        NOW() - INTERVAL '6 days', NOW() + INTERVAL '15 days', NULL, 2, 54,
        NOW() - INTERVAL '6 days'
    ),
    (
        'c1000000-0000-0000-0000-000000001108', '10000000-0000-0000-0000-000000000017', 'UG',
        'Short-Term Inventory Finance', 'Restock hardware items and construction supplies before the wet-season market rush',
        6500000, 6, 'Salary — UGX 6,500,000', 'monthly', 1150000,
        '6 months starting April 2026', 'Mbale', 'active',
        NOW() - INTERVAL '7 days', NOW() + INTERVAL '11 days', NULL, 1, 36,
        NOW() - INTERVAL '7 days'
    )
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- Kenya loan requests
-- -----------------------------------------------------------------------------
INSERT INTO loan_requests (
    id, borrower_id, country, title, purpose, requested_amount, duration_months,
    income_source, preferred_repayment_plan, repayment_amount_per_period,
    repayment_timeline, district, status, listed_at, expires_at, contracted_at,
    number_of_offers, views_count, created_at
) VALUES
    (
        'c2000000-0000-0000-0000-000000001101', '10000000-0000-0000-0000-000000000018', 'KE',
        'Phone Repair Business Boost', 'Buy spare parts and tools for a growing phone repair kiosk in Westlands',
        180000, 12, 'Salary — KES 150,000', 'monthly', 17000,
        '12 months starting May 2026', 'Nairobi', 'active',
        NOW() - INTERVAL '2 days', NOW() + INTERVAL '19 days', NULL, 1, 52,
        NOW() - INTERVAL '2 days'
    ),
    (
        'c2000000-0000-0000-0000-000000001102', '10000000-0000-0000-0000-000000000019', 'KE',
        'School Fees Support', 'Pay school fees for my daughter in her final year of high school',
        240000, 10, 'Salary — KES 195,000', 'monthly', 26000,
        '10 months starting April 2026', 'Nairobi', 'active',
        NOW() - INTERVAL '3 days', NOW() + INTERVAL '18 days', NULL, 0, 41,
        NOW() - INTERVAL '3 days'
    ),
    (
        'c2000000-0000-0000-0000-000000001103', '10000000-0000-0000-0000-000000000020', 'KE',
        'Furniture Shop Inventory', 'Buy stock and display furniture for a growing home-furnishing kiosk',
        360000, 12, 'Salary — KES 120,000', 'monthly', 32000,
        '12 months starting June 2026', 'Mombasa', 'active',
        NOW() - INTERVAL '4 days', NOW() + INTERVAL '17 days', NULL, 1, 38,
        NOW() - INTERVAL '4 days'
    ),
    (
        'c2000000-0000-0000-0000-000000001104', '10000000-0000-0000-0000-000000000021', 'KE',
        'Taxi Insurance Renewal', 'Renew insurance and buy an extra tyre kit for my matatu business',
        420000, 18, 'Salary — KES 165,000', 'monthly', 28000,
        '18 months starting May 2026', 'Nakuru', 'active',
        NOW() - INTERVAL '2 days', NOW() + INTERVAL '15 days', NULL, 2, 46,
        NOW() - INTERVAL '2 days'
    ),
    (
        'c2000000-0000-0000-0000-000000001105', '10000000-0000-0000-0000-000000000022', 'KE',
        'Small Shop Refit', 'Upgrade shelves, paint work, and signage for a small retail shop in Kisumu',
        560000, 15, 'Salary — KES 135,000', 'monthly', 42000,
        '15 months starting April 2026', 'Kisumu', 'active',
        NOW() - INTERVAL '5 days', NOW() + INTERVAL '13 days', NULL, 1, 35,
        NOW() - INTERVAL '5 days'
    ),
    (
        'c2000000-0000-0000-0000-000000001106', '10000000-0000-0000-0000-000000000023', 'KE',
        'Micro-Clinic Setup', 'Set up a basic maternity and consultation room for a community clinic',
        690000, 24, 'Salary — KES 225,000', 'monthly', 33000,
        '24 months starting June 2026', 'Nairobi', 'active',
        NOW() - INTERVAL '6 days', NOW() + INTERVAL '12 days', NULL, 2, 60,
        NOW() - INTERVAL '6 days'
    ),
    (
        'c2000000-0000-0000-0000-000000001107', '10000000-0000-0000-0000-000000000024', 'KE',
        'Car Repair and Spare Parts', 'Fix my delivery van and buy essential spare parts for my courier route',
        310000, 12, 'Salary — KES 105,000', 'monthly', 29000,
        '12 months starting May 2026', 'Eldoret', 'active',
        NOW() - INTERVAL '1 day', NOW() + INTERVAL '20 days', NULL, 0, 27,
        NOW() - INTERVAL '1 day'
    ),
    (
        'c2000000-0000-0000-0000-000000001108', '10000000-0000-0000-0000-000000000025', 'KE',
        'Second-Hand Machinery Purchase', 'Buy used milling equipment to expand a family grain business in Nakuru',
        820000, 18, 'Salary — KES 180,000', 'monthly', 48000,
        '18 months starting April 2026', 'Nakuru', 'active',
        NOW() - INTERVAL '3 days', NOW() + INTERVAL '16 days', NULL, 1, 44,
        NOW() - INTERVAL '3 days'
    )
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- A few matching offers so they show up in the UI immediately
-- -----------------------------------------------------------------------------
INSERT INTO loan_offers (
    id, request_id, lender_id, offer_amount, interest_rate_pct, late_fee_pct,
    repayment_frequency, installment_amount, proposed_expectations,
    terms_locked_at, status, offered_at, accepted_at, created_at
) VALUES
    (
        'd1000000-0000-0000-0000-000000001101', 'c1000000-0000-0000-0000-000000001101', '10000000-0000-0000-0000-000000000026',
        2200000, 13.5, 2.0, 'monthly', 210000,
        'Can fund the full school fee gap with monthly repayments over 12 months.',
        NOW() - INTERVAL '18 hours', 'pending', NOW() - INTERVAL '18 hours', NULL,
        NOW() - INTERVAL '18 hours'
    ),
    (
        'd1000000-0000-0000-0000-000000001102', 'c1000000-0000-0000-0000-000000001103', '10000000-0000-0000-0000-000000000027',
        7600000, 15.0, 2.0, 'monthly', 340000,
        'Can support the agri-expansion plan at 15% APR with a monthly structure.',
        NOW() - INTERVAL '22 hours', 'pending', NOW() - INTERVAL '22 hours', NULL,
        NOW() - INTERVAL '22 hours'
    ),
    (
        'd1000000-0000-0000-0000-000000001103', 'c1000000-0000-0000-0000-000000001106', '10000000-0000-0000-0000-000000000028',
        5400000, 14.0, 2.0, 'monthly', 320000,
        'Happy to finance the solar installation as a clean-energy related request.',
        NOW() - INTERVAL '16 hours', 'pending', NOW() - INTERVAL '16 hours', NULL,
        NOW() - INTERVAL '16 hours'
    ),
    (
        'd2000000-0000-0000-0000-000000001101', 'c2000000-0000-0000-0000-000000001101', '10000000-0000-0000-0000-000000000026',
        180000, 15.0, 2.0, 'monthly', 17000,
        'Can support the repair business growth with a simple monthly plan.',
        NOW() - INTERVAL '20 hours', 'pending', NOW() - INTERVAL '20 hours', NULL,
        NOW() - INTERVAL '20 hours'
    ),
    (
        'd2000000-0000-0000-0000-000000001102', 'c2000000-0000-0000-0000-000000001104', '10000000-0000-0000-0000-000000000027',
        420000, 16.0, 2.0, 'monthly', 28000,
        'Can offer a flexible plan for the taxi insurance and tyre equipment cost.',
        NOW() - INTERVAL '14 hours', 'pending', NOW() - INTERVAL '14 hours', NULL,
        NOW() - INTERVAL '14 hours'
    ),
    (
        'd2000000-0000-0000-0000-000000001103', 'c2000000-0000-0000-0000-000000001106', '10000000-0000-0000-0000-000000000028',
        690000, 15.5, 2.0, 'monthly', 33000,
        'I can support the community health setup with a structured monthly plan.',
        NOW() - INTERVAL '19 hours', 'pending', NOW() - INTERVAL '19 hours', NULL,
        NOW() - INTERVAL '19 hours'
    )
ON CONFLICT (id) DO NOTHING;

COMMIT;

-- ============================================================
-- END MERGED SECTION: patch_more_ug_kenya_loan_requests.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: patch_needs_sample_requests.sql
-- ============================================================

-- Sample Needs marketplace requests: 10 each for every country listed below.
-- Safe to paste into the Supabase SQL editor.
-- The marketplace view is refreshed so the seeded rows appear in the app.

create table if not exists public.needs_requests (
  request_id uuid primary key default gen_random_uuid(),
  title text not null,
  specification text not null default '',
  category text not null default 'Other',
  budget integer not null default 0 check (budget >= 0),
  currency text not null default 'UGX',
  location text not null default '',
  country text not null default 'UG',
  urgency text not null default 'Flexible',
  status text not null default 'active',
  listed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  trust_is_verified boolean not null default false
);

-- Create or refresh the read model used by the Flutter marketplace.
create or replace view public.v_needs_listings as
select
  request_id,
  title,
  specification,
  category,
  budget,
  currency,
  location,
  country,
  urgency,
  status,
  listed_at,
  created_at,
  trust_is_verified
from public.needs_requests
where status = 'active';

grant select on public.needs_requests to anon, authenticated;
grant select on public.v_needs_listings to anon, authenticated;

insert into public.needs_requests (
  request_id, title, specification, category, budget, currency,
  location, country, urgency, status, listed_at, trust_is_verified
)
values
  ('d1000000-0000-0000-0000-000000000001',
   'Solar Home System',
   'Need a 200W solar panel, battery, controller, and installation for a two-room home.',
   'Home & Energy', 1850000, 'UGX', 'Gulu', 'UG', 'This month', 'active', now() - interval '2 hours', true),
  ('d1000000-0000-0000-0000-000000000002',
   'Commercial Fridge',
   'Display fridge for a small yoghurt and fresh juice shop near the main taxi stage.',
   'Business Equipment', 3200000, 'UGX', 'Mbarara', 'UG', 'Within 30 days', 'active', now() - interval '5 hours', false),
  ('d1000000-0000-0000-0000-000000000003',
   'School Desks',
   'Thirty-five durable desks and chairs for a growing primary school in Wakiso.',
   'Education', 4200000, 'UGX', 'Wakiso', 'UG', 'Urgent', 'active', now() - interval '1 day', true),
  ('d1000000-0000-0000-0000-000000000004',
   'Water Storage Tank',
   'A 10,000 litre tank and raised stand for a community water point serving nearby homes.',
   'Community', 2900000, 'UGX', 'Lira', 'UG', 'Within 30 days', 'active', now() - interval '1 day 4 hours', true),
  ('d1000000-0000-0000-0000-000000000005',
   'Restaurant Kitchen Equipment',
   'Two-burner cooker, stainless work table, pots, and serving equipment for a new cafe.',
   'Business Equipment', 5600000, 'UGX', 'Kampala Central', 'UG', 'This month', 'active', now() - interval '2 days', false),
  ('d1000000-0000-0000-0000-000000000006',
   'Motorcycle Spare Parts',
   'Bulk brake pads, chains, cables, and tyres to restock a motorcycle parts shop.',
   'Inventory', 950000, 'KES', 'Nairobi', 'KE', 'Within 30 days', 'active', now() - interval '2 days 6 hours', false),
  ('d1000000-0000-0000-0000-000000000007',
   'Irrigation Pump',
   'Petrol irrigation pump and hose for a vegetable plot supplying local markets.',
   'Agriculture', 780000, 'TZS', 'Arusha', 'TZ', 'Before next planting season', 'active', now() - interval '3 days', true),
  ('d1000000-0000-0000-0000-000000000008',
   'Laptop for Graphic Design',
   'Reliable laptop with at least 16GB RAM for freelance design and video editing work.',
   'Technology', 1450000, 'RWF', 'Kigali', 'RW', 'Within 30 days', 'active', now() - interval '3 days 5 hours', false)
  ,('d1000000-0000-0000-0000-000000000009',
   'Borehole Repair',
   'Replace the damaged pump and restore clean water access for a village health centre.',
   'Community', 2300000, 'UGX', 'Hoima', 'UG', 'Urgent', 'active', now() - interval '4 days', true)
  ,('d1000000-0000-0000-0000-000000000010',
   'Tailoring Machine',
   'Industrial sewing machine for a small tailoring workshop employing three young people.',
   'Business Equipment', 1750000, 'UGX', 'Jinja', 'UG', 'Within 30 days', 'active', now() - interval '4 days 6 hours', false)
  ,('d1000000-0000-0000-0000-000000000011',
   'Motorcycle for Farm Deliveries',
   'Reliable motorcycle to transport produce from a family farm to the local market.',
   'Agriculture', 6800000, 'UGX', 'Mbale', 'UG', 'This month', 'active', now() - interval '5 days', true)
  ,('d1000000-0000-0000-0000-000000000012',
   'Maternity Ward Supplies',
   'Delivery kits, sterilisation supplies, and washable sheets for a rural maternity ward.',
   'Health', 1600000, 'UGX', 'Fort Portal', 'UG', 'Urgent', 'active', now() - interval '5 days 5 hours', true)
  ,('d1000000-0000-0000-0000-000000000013',
   'Beehives and Protective Gear',
   'Ten modern hives, smoker, veil, and protective suits for a new beekeeping group.',
   'Agriculture', 1250000, 'UGX', 'Arua', 'UG', 'Before next season', 'active', now() - interval '6 days', false)
  ,('d1000000-0000-0000-0000-000000000014',
   'Shop Shelving',
   'Metal shelving and a counter for a neighbourhood household goods shop.',
   'Business Equipment', 980000, 'KES', 'Kisumu', 'KE', 'Within 30 days', 'active', now() - interval '4 days 8 hours', false)
  ,('d1000000-0000-0000-0000-000000000015',
   'School Computer Lab',
   'Ten refurbished desktop computers, network equipment, and setup for a secondary school.',
   'Education', 850000, 'KES', 'Nakuru', 'KE', 'This term', 'active', now() - interval '4 days 12 hours', true)
  ,('d1000000-0000-0000-0000-000000000016',
   'Greenhouse Materials',
   'Polythene, irrigation lines, and seed trays for a small commercial vegetable greenhouse.',
   'Agriculture', 420000, 'KES', 'Eldoret', 'KE', 'Before next planting season', 'active', now() - interval '5 days 8 hours', false)
  ,('d1000000-0000-0000-0000-000000000017',
   'Clinic Solar Backup',
   'Battery and inverter backup to keep vaccine refrigeration running during outages.',
   'Health', 690000, 'KES', 'Mombasa', 'KE', 'Urgent', 'active', now() - interval '6 days 4 hours', true)
  ,('d1000000-0000-0000-0000-000000000018',
   'Mobile Food Cart',
   'Food cart, gas burner, and insulated containers for a breakfast business.',
   'Business Equipment', 280000, 'KES', 'Thika', 'KE', 'Within 30 days', 'active', now() - interval '6 days 10 hours', false)
  ,('d1000000-0000-0000-0000-000000000019',
   'Fishing Nets and Cooler',
   'Legal fishing nets and a solar cooler for a lakeside fishing cooperative.',
   'Livelihoods', 1650000, 'TZS', 'Mwanza', 'TZ', 'This month', 'active', now() - interval '4 days 9 hours', true)
  ,('d1000000-0000-0000-0000-000000000020',
   'School Water Filter',
   'Large-capacity filtration system and storage containers for a rural primary school.',
   'Education', 1100000, 'TZS', 'Dodoma', 'TZ', 'Urgent', 'active', now() - interval '4 days 14 hours', true)
  ,('d1000000-0000-0000-0000-000000000021',
   'Poultry House Materials',
   'Timber, wire mesh, feeders, and drinkers for a 500-bird poultry project.',
   'Agriculture', 2400000, 'TZS', 'Morogoro', 'TZ', 'Within 30 days', 'active', now() - interval '5 days 2 hours', false)
  ,('d1000000-0000-0000-0000-000000000022',
   'Phone Repair Tools',
   'Professional microscope, heat station, and precision tools for a phone repair kiosk.',
   'Technology', 1350000, 'TZS', 'Dar es Salaam', 'TZ', 'This month', 'active', now() - interval '5 days 12 hours', false)
  ,('d1000000-0000-0000-0000-000000000023',
   'Community Library Books',
   'Age-appropriate textbooks, story books, and shelves for a community reading room.',
   'Education', 1750000, 'TZS', 'Mbeya', 'TZ', 'Flexible', 'active', now() - interval '6 days 2 hours', true)
  ,('d1000000-0000-0000-0000-000000000024',
   'Bakery Oven',
   'Electric deck oven to increase daily bread production for a growing bakery.',
   'Business Equipment', 480000, 'RWF', 'Huye', 'RW', 'This month', 'active', now() - interval '4 days 10 hours', false)
  ,('d1000000-0000-0000-0000-000000000025',
   'Rainwater Harvesting Tanks',
   'Two tanks and guttering for a community centre that hosts youth programmes.',
   'Community', 920000, 'RWF', 'Musanze', 'RW', 'Before rainy season', 'active', now() - interval '4 days 16 hours', true)
  ,('d1000000-0000-0000-0000-000000000026',
   'Motorcycle Delivery Box',
   'Insulated delivery box and safety gear for a small food delivery service.',
   'Business Equipment', 260000, 'RWF', 'Kigali', 'RW', 'Within 30 days', 'active', now() - interval '5 days 4 hours', false)
  ,('d1000000-0000-0000-0000-000000000027',
   'Piglet Starter Stock',
   'Healthy piglets, pen materials, and initial feed for a family farming project.',
   'Agriculture', 1150000, 'RWF', 'Rubavu', 'RW', 'This month', 'active', now() - interval '5 days 18 hours', true)
  ,('d1000000-0000-0000-0000-000000000028',
   'Community First Aid Kit',
   'First aid supplies, stretcher, and basic protective equipment for a village response team.',
   'Health', 390000, 'RWF', 'Nyagatare', 'RW', 'Urgent', 'active', now() - interval '6 days 8 hours', false)
  ,('d1000000-0000-0000-0000-000000000029',
   'Fresh Produce Stall',
   'Lockable market stall, crates, and weighing scale for a fresh produce business.',
   'Business Equipment', 315000, 'KES', 'Nairobi', 'KE', 'This month', 'active', now() - interval '7 days', true)
  ,('d1000000-0000-0000-0000-000000000030',
   'Rainwater Tank',
   '5,000 litre tank and gutters for a household in a water-scarce neighbourhood.',
   'Home & Energy', 185000, 'KES', 'Machakos', 'KE', 'Before rainy season', 'active', now() - interval '7 days 6 hours', false)
  ,('d1000000-0000-0000-0000-000000000031',
   'Motorcycle Safety Gear',
   'Helmets, reflective jackets, and rain gear for a small delivery team.',
   'Transport', 125000, 'KES', 'Kakamega', 'KE', 'Within 30 days', 'active', now() - interval '8 days', false)
  ,('d1000000-0000-0000-0000-000000000032',
   'Dairy Feed and Chiller',
   'Three months of dairy feed and a small milk chiller for a cooperative.',
   'Agriculture', 610000, 'KES', 'Nyeri', 'KE', 'Urgent', 'active', now() - interval '8 days 5 hours', true)
  ,('d1000000-0000-0000-0000-000000000033',
   'Solar Street Light',
   'Solar street light and pole to improve safety near a market entrance.',
   'Community', 850000, 'TZS', 'Tanga', 'TZ', 'This month', 'active', now() - interval '7 days 4 hours', true)
  ,('d1000000-0000-0000-0000-000000000034',
   'Tailoring Fabric Stock',
   'Cotton fabric, thread, zips, and buttons for school uniform orders.',
   'Inventory', 1650000, 'TZS', 'Zanzibar', 'TZ', 'Within 30 days', 'active', now() - interval '7 days 10 hours', false)
  ,('d1000000-0000-0000-0000-000000000035',
   'Poultry Vaccination Supplies',
   'Vaccines, feeders, and drinkers for a small poultry farmers association.',
   'Agriculture', 980000, 'TZS', 'Shinyanga', 'TZ', 'Urgent', 'active', now() - interval '8 days 3 hours', true)
  ,('d1000000-0000-0000-0000-000000000036',
   'Solar Study Lamps',
   'Rechargeable study lamps for students in an off-grid village school.',
   'Education', 730000, 'TZS', 'Kigoma', 'TZ', 'This term', 'active', now() - interval '8 days 12 hours', false)
  ,('d1000000-0000-0000-0000-000000000037',
   'Milk Collection Canisters',
   'Food-grade milk cans and a weighing scale for a cooperative collection point.',
   'Agriculture', 610000, 'RWF', 'Gicumbi', 'RW', 'This month', 'active', now() - interval '7 days 8 hours', true)
  ,('d1000000-0000-0000-0000-000000000038',
   'Classroom Desks',
   'Twenty-five desks and chairs for a growing lower secondary school.',
   'Education', 1750000, 'RWF', 'Rwamagana', 'RW', 'Urgent', 'active', now() - interval '7 days 14 hours', false)
  ,('d1000000-0000-0000-0000-000000000039',
   'Phone Charging Kiosk',
   'Solar charging kiosk, cables, and secure counter for a rural trading centre.',
   'Business Equipment', 890000, 'RWF', 'Kayonza', 'RW', 'Within 30 days', 'active', now() - interval '8 days 6 hours', true)
  ,('d1000000-0000-0000-0000-000000000040',
   'Vegetable Seed Starter Pack',
   'Seeds, trays, compost, and watering cans for a youth farming group.',
   'Agriculture', 290000, 'RWF', 'Nyanza', 'RW', 'Before next planting season', 'active', now() - interval '8 days 18 hours', false)
  ,('d1000000-0000-0000-0000-000000000041',
   'Cassava Processing Machine',
   'Small motorised cassava grater and press for a women-led farming cooperative.',
   'Agriculture', 6800000, 'BIF', 'Gitega', 'BI', 'This month', 'active', now() - interval '9 days', true)
  ,('d1000000-0000-0000-0000-000000000042',
   'Classroom Roofing Sheets',
   'Corrugated roofing sheets and timber to repair two classrooms before the rains.',
   'Education', 4200000, 'BIF', 'Ngozi', 'BI', 'Urgent', 'active', now() - interval '9 days 5 hours', false)
  ,('d1000000-0000-0000-0000-000000000043',
   'Market Stall Materials',
   'Timber, iron sheets, and a lockable counter for a small produce stall.',
   'Business Equipment', 2100000, 'BIF', 'Bujumbura', 'BI', 'Within 30 days', 'active', now() - interval '10 days', true)
  ,('d1000000-0000-0000-0000-000000000044',
   'Village Water Tank',
   'Large storage tank and stand for a village water collection point.',
   'Community', 5500000, 'BIF', 'Muyinga', 'BI', 'Urgent', 'active', now() - interval '10 days 6 hours', true)
  ,('d1000000-0000-0000-0000-000000000045',
   'Solar Charging Station',
   'Solar panel, battery, and charging cabinet for a rural trading centre.',
   'Home & Energy', 3600000, 'BIF', 'Makamba', 'BI', 'This month', 'active', now() - interval '11 days', false)
  ,('d1000000-0000-0000-0000-000000000046',
   'Fishing Boat Repair',
   'Timber, paint, and engine service for a cooperative fishing boat.',
   'Livelihoods', 7800000, 'CDF', 'Goma', 'CD', 'Urgent', 'active', now() - interval '9 days 8 hours', true)
  ,('d1000000-0000-0000-0000-000000000047',
   'Pharmacy Shelving',
   'Lockable shelving, counter, and storage bins for a community pharmacy.',
   'Health', 4200000, 'CDF', 'Bukavu', 'CD', 'Within 30 days', 'active', now() - interval '9 days 14 hours', false)
  ,('d1000000-0000-0000-0000-000000000048',
   'School Solar Kit',
   'Solar panels, batteries, and lights for a primary school with no grid connection.',
   'Education', 9500000, 'CDF', 'Lubumbashi', 'CD', 'This term', 'active', now() - interval '10 days 4 hours', true)
  ,('d1000000-0000-0000-0000-000000000049',
   'Water Pump',
   'Solar water pump and pipes for a small community garden.',
   'Agriculture', 6400000, 'CDF', 'Kisangani', 'CD', 'Before next planting season', 'active', now() - interval '10 days 12 hours', false)
  ,('d1000000-0000-0000-0000-000000000050',
   'Tailoring Workshop Tools',
   'Three sewing machines, cutting table, and starter fabric for a youth workshop.',
   'Business Equipment', 5800000, 'CDF', 'Kinshasa', 'CD', 'This month', 'active', now() - interval '11 days 6 hours', true)
  ,('d1000000-0000-0000-0000-000000000051',
   'Fishing Nets',
   'Durable legal fishing nets and insulated storage boxes for coastal fishers.',
   'Livelihoods', 185000, 'SOS', 'Mogadishu', 'SO', 'This month', 'active', now() - interval '9 days 10 hours', true)
  ,('d1000000-0000-0000-0000-000000000052',
   'Clinic Medical Refrigerator',
   'Solar vaccine refrigerator and temperature monitor for a rural clinic.',
   'Health', 420000, 'SOS', 'Hargeisa', 'SO', 'Urgent', 'active', now() - interval '9 days 16 hours', false)
  ,('d1000000-0000-0000-0000-000000000053',
   'Water Truck Storage Tank',
   'Poly tanks and distribution hoses for a drought-response water point.',
   'Community', 310000, 'SOS', 'Baidoa', 'SO', 'Urgent', 'active', now() - interval '10 days 8 hours', true)
  ,('d1000000-0000-0000-0000-000000000054',
   'Solar Lights for School',
   'Rechargeable solar lights for classrooms and evening study sessions.',
   'Education', 165000, 'SOS', 'Kismayo', 'SO', 'This term', 'active', now() - interval '10 days 18 hours', false)
  ,('d1000000-0000-0000-0000-000000000055',
   'Small Grocery Stock',
   'Rice, flour, cooking oil, and shelves to open a neighbourhood grocery shop.',
   'Inventory', 280000, 'SOS', 'Garowe', 'SO', 'Within 30 days', 'active', now() - interval '11 days 12 hours', true)
  ,('d1000000-0000-0000-0000-000000000056',
   'Maize Milling Machine',
   'Small diesel maize mill to serve farming communities near a market centre.',
   'Agriculture', 1850000, 'SSP', 'Juba', 'SS', 'This month', 'active', now() - interval '9 days 12 hours', true)
  ,('d1000000-0000-0000-0000-000000000057',
   'Borehole Pump Repair',
   'Replacement pump and fittings to restore water access for a settlement.',
   'Community', 1250000, 'SSP', 'Wau', 'SS', 'Urgent', 'active', now() - interval '9 days 18 hours', false)
  ,('d1000000-0000-0000-0000-000000000058',
   'School Desks and Boards',
   'Desks, benches, and writing boards for two temporary classrooms.',
   'Education', 980000, 'SSP', 'Malakal', 'SS', 'This term', 'active', now() - interval '10 days 10 hours', true)
  ,('d1000000-0000-0000-0000-000000000059',
   'Solar Clinic Backup',
   'Solar battery system to keep essential lights and medical equipment running.',
   'Health', 2400000, 'SSP', 'Yei', 'SS', 'Urgent', 'active', now() - interval '10 days 20 hours', false)
  ,('d1000000-0000-0000-0000-000000000060',
   'Goat Farming Starter Group',
   'Starter goats, shelter materials, and veterinary supplies for a women’s group.',
   'Agriculture', 1450000, 'SSP', 'Aweil', 'SS', 'Within 30 days', 'active', now() - interval '11 days 18 hours', true)
  ,('d1000000-0000-0000-0000-000000000061',
   'Rice Huller',
   'Small rice huller and spare belts for a farming cooperative.',
   'Agriculture', 7200000, 'BIF', 'Kirundo', 'BI', 'This month', 'active', now() - interval '12 days', false)
  ,('d1000000-0000-0000-0000-000000000062',
   'Maternity Supplies',
   'Reusable delivery kits, steriliser, and basic supplies for a rural health post.',
   'Health', 2900000, 'BIF', 'Cibitoke', 'BI', 'Urgent', 'active', now() - interval '12 days 6 hours', true)
  ,('d1000000-0000-0000-0000-000000000063',
   'Motorcycle Delivery Box',
   'Secure delivery box and rain gear for a pharmacy delivery rider.',
   'Transport', 1100000, 'BIF', 'Rumonge', 'BI', 'Within 30 days', 'active', now() - interval '13 days', false)
  ,('d1000000-0000-0000-0000-000000000064',
   'Community Library Books',
   'Children’s readers, textbooks, and shelves for a community reading room.',
   'Education', 2500000, 'BIF', 'Kayanza', 'BI', 'Flexible', 'active', now() - interval '13 days 8 hours', true)
  ,('d1000000-0000-0000-0000-000000000065',
   'Market Cold Box',
   'Solar-powered cold box for preserving fish and fresh produce at the market.',
   'Business Equipment', 6100000, 'CDF', 'Matadi', 'CD', 'This month', 'active', now() - interval '12 days 8 hours', false)
  ,('d1000000-0000-0000-0000-000000000066',
   'Community Grain Store',
   'Metal sheets, timber, and pallets to build a dry grain storage room.',
   'Community', 8700000, 'CDF', 'Mbuji-Mayi', 'CD', 'Before harvest', 'active', now() - interval '12 days 14 hours', true)
  ,('d1000000-0000-0000-0000-000000000067',
   'Computer Training Lab',
   'Six refurbished laptops and a small solar backup for digital skills training.',
   'Technology', 11200000, 'CDF', 'Beni', 'CD', 'This term', 'active', now() - interval '13 days 4 hours', false)
  ,('d1000000-0000-0000-0000-000000000068',
   'Beekeeping Equipment',
   'Modern hives, smoker, protective suits, and starter colonies for a cooperative.',
   'Agriculture', 4900000, 'CDF', 'Uvira', 'CD', 'Before next season', 'active', now() - interval '13 days 12 hours', true)
  ,('d1000000-0000-0000-0000-000000000069',
   'Fish Market Stall',
   'Lockable stall, scales, and insulated containers for a fish vendor.',
   'Business Equipment', 240000, 'SOS', 'Berbera', 'SO', 'Within 30 days', 'active', now() - interval '12 days 12 hours', false)
  ,('d1000000-0000-0000-0000-000000000070',
   'Community Water Filters',
   'Household water filters and safe storage containers for a displaced community.',
   'Community', 195000, 'SOS', 'Doolow', 'SO', 'Urgent', 'active', now() - interval '12 days 18 hours', true)
  ,('d1000000-0000-0000-0000-000000000071',
   'Solar Phone Charging Kiosk',
   'Solar charging station and secure kiosk for a busy transport stop.',
   'Business Equipment', 335000, 'SOS', 'Bosaso', 'SO', 'This month', 'active', now() - interval '13 days 6 hours', false)
  ,('d1000000-0000-0000-0000-000000000072',
   'School Learning Materials',
   'Exercise books, pens, chalk, and basic teaching materials for a primary school.',
   'Education', 155000, 'SOS', 'Beledweyne', 'SO', 'This term', 'active', now() - interval '13 days 16 hours', true)
  ,('d1000000-0000-0000-0000-000000000073',
   'Vegetable Garden Irrigation',
   'Drip lines, water tank, and hand tools for an urban vegetable garden.',
   'Agriculture', 1180000, 'SSP', 'Torit', 'SS', 'Before next planting season', 'active', now() - interval '12 days 16 hours', false)
  ,('d1000000-0000-0000-0000-000000000074',
   'Community Pharmacy Shelves',
   'Lockable shelves and medicine storage bins for a community pharmacy.',
   'Health', 980000, 'SSP', 'Rumbek', 'SS', 'Within 30 days', 'active', now() - interval '12 days 22 hours', true)
  ,('d1000000-0000-0000-0000-000000000075',
   'Market Stall Construction',
   'Iron sheets, timber, and a lock for a small dry goods stall.',
   'Business Equipment', 720000, 'SSP', 'Bor', 'SS', 'This month', 'active', now() - interval '13 days 10 hours', false)
  ,('d1000000-0000-0000-0000-000000000076',
   'Handwashing Stations',
   'Water tanks, stands, and soap dispensers for a school and nearby market.',
   'Community', 560000, 'SSP', 'Bentiu', 'SS', 'Urgent', 'active', now() - interval '13 days 20 hours', true)
  ,('d1000000-0000-0000-0000-000000000077',
   'Groundnut Sheller',
   'Manual sheller and storage sacks for a small farmers’ association.',
   'Agriculture', 840000, 'BIF', 'Bubanza', 'BI', 'Before harvest', 'active', now() - interval '14 days', true)
  ,('d1000000-0000-0000-0000-000000000078',
   'Solar Sewing Workshop',
   'Two sewing machines and solar backup for a women’s tailoring workshop.',
    'Business Equipment', 530000, 'SOS', 'Hargeisa', 'SO', 'This month', 'active', now() - interval '14 days 6 hours', false)
  ,('d1000000-0000-0000-0000-000000000079',
   'Classroom Water Filter',
   'Water filter and storage containers for a rural primary school.',
   'Education', 1450000, 'CDF', 'Kikwit', 'CD', 'Urgent', 'active', now() - interval '14 days 12 hours', true)
  ,('d1000000-0000-0000-0000-000000000080',
   'Livestock Vaccination Kit',
   'Cold box, syringes, and veterinary supplies for a pastoralist community.',
   'Agriculture', 630000, 'SSP', 'Yambio', 'SS', 'Before next season', 'active', now() - interval '14 days 18 hours', false)
  ,('d1000000-0000-0000-0000-000000000081',
   'Solar Power Kit',
   'Solar panels, battery, and inverter for a small household and home office.',
   'Home & Energy', 850000, 'NGN', 'Abuja', 'NG', 'This month', 'active', now() - interval '15 days', true)
  ,('d1000000-0000-0000-0000-000000000082',
   'Poultry Feed Stock',
   'Starter feed and drinkers for a 300-bird poultry business.',
   'Agriculture', 420000, 'NGN', 'Ibadan', 'NG', 'Within 30 days', 'active', now() - interval '15 days 5 hours', false)
  ,('d1000000-0000-0000-0000-000000000083',
   'School Projector',
   'Reliable projector and screen for lessons at a community secondary school.',
   'Education', 680000, 'NGN', 'Lagos', 'NG', 'This term', 'active', now() - interval '16 days', true)
  ,('d1000000-0000-0000-0000-000000000084',
   'Water Borehole Pump',
   'Submersible pump and pipes to restore water access for a farming settlement.',
   'Community', 1250000, 'NGN', 'Kaduna', 'NG', 'Urgent', 'active', now() - interval '16 days 6 hours', true)
  ,('d1000000-0000-0000-0000-000000000085',
   'Tailoring Equipment',
   'Two sewing machines, cutting table, and fabric for a women’s tailoring group.',
   'Business Equipment', 950000, 'NGN', 'Enugu', 'NG', 'This month', 'active', now() - interval '17 days', false)
  ,('d1000000-0000-0000-0000-000000000086',
   'Clinic Examination Bed',
   'Examination bed, privacy screen, and basic diagnostic equipment for a clinic.',
   'Health', 56000, 'EGP', 'Cairo', 'EG', 'Within 30 days', 'active', now() - interval '15 days 8 hours', true)
  ,('d1000000-0000-0000-0000-000000000087',
   'Bakery Mixer',
   'Commercial dough mixer and trays for a neighbourhood bakery.',
   'Business Equipment', 74000, 'EGP', 'Alexandria', 'EG', 'This month', 'active', now() - interval '15 days 14 hours', false)
  ,('d1000000-0000-0000-0000-000000000088',
   'Irrigation Drip Lines',
   'Drip irrigation lines and water tank for a vegetable farm outside the city.',
   'Agriculture', 48000, 'EGP', 'Giza', 'EG', 'Before next planting season', 'active', now() - interval '16 days 4 hours', true)
  ,('d1000000-0000-0000-0000-000000000089',
   'School Desks',
   'Forty desks and chairs for a public school with growing enrolment.',
   'Education', 92000, 'EGP', 'Aswan', 'EG', 'Urgent', 'active', now() - interval '16 days 12 hours', false)
  ,('d1000000-0000-0000-0000-000000000090',
   'Cold Storage Chest',
   'Energy-efficient chest freezer for a small fish and frozen food business.',
   'Business Equipment', 63000, 'EGP', 'Port Said', 'EG', 'Within 30 days', 'active', now() - interval '17 days 6 hours', true)
  ,('d1000000-0000-0000-0000-000000000091',
   'Community Garden Tools',
   'Wheelbarrows, hand tools, compost, and seedlings for a shared food garden.',
   'Community', 18500, 'ZAR', 'Johannesburg', 'ZA', 'This month', 'active', now() - interval '15 days 10 hours', true)
  ,('d1000000-0000-0000-0000-000000000092',
   'Mobile Food Trailer',
   'Compact food trailer, gas burner, and serving equipment for a new vendor.',
   'Business Equipment', 78000, 'ZAR', 'Cape Town', 'ZA', 'Within 30 days', 'active', now() - interval '15 days 18 hours', false)
  ,('d1000000-0000-0000-0000-000000000093',
   'Solar Water Pump',
   'Solar pump and storage tank for a small vegetable farm.',
   'Agriculture', 46500, 'ZAR', 'Polokwane', 'ZA', 'Before next planting season', 'active', now() - interval '16 days 8 hours', true)
  ,('d1000000-0000-0000-0000-000000000094',
   'Computer Lab Upgrade',
   'Refurbished computers and network equipment for a township learning centre.',
   'Technology', 92000, 'ZAR', 'Durban', 'ZA', 'This term', 'active', now() - interval '16 days 16 hours', false)
  ,('d1000000-0000-0000-0000-000000000095',
   'Clinic Backup Battery',
   'Battery and inverter backup for vaccine refrigeration and emergency lighting.',
   'Health', 38500, 'ZAR', 'Mthatha', 'ZA', 'Urgent', 'active', now() - interval '17 days 12 hours', true)
  ,('d1000000-0000-0000-0000-000000000096',
   'Farming Tunnel Materials',
   'Plastic tunnel, irrigation fittings, and seedlings for a community farm.',
   'Agriculture', 52000, 'ZAR', 'Mbombela', 'ZA', 'This month', 'active', now() - interval '18 days', false)
  ,('d1000000-0000-0000-0000-000000000097',
   'School Library Shelves',
   'Shelving and age-appropriate books for a rural primary school library.',
   'Education', 27500, 'ZAR', 'Kimberley', 'ZA', 'This term', 'active', now() - interval '18 days 6 hours', true)
  ,('d1000000-0000-0000-0000-000000000098',
   'Hair Salon Equipment',
   'Salon chair, hair dryer, mirrors, and starter products for a new business.',
   'Business Equipment', 34000, 'ZAR', 'Soweto', 'ZA', 'Within 30 days', 'active', now() - interval '18 days 12 hours', false)
  ,('d1000000-0000-0000-0000-000000000099',
   'Rainwater Harvesting System',
   'Gutters, tanks, and filtration for a community centre.',
   'Home & Energy', 61500, 'ZAR', 'Gqeberha', 'ZA', 'Before rainy season', 'active', now() - interval '19 days', true)
  ,('d1000000-0000-0000-0000-000000000100',
   'Small Delivery Vehicle',
   'Used compact vehicle for delivering groceries and farm produce locally.',
   'Transport', 145000, 'ZAR', 'Pretoria', 'ZA', 'This month', 'active', now() - interval '19 days 8 hours', false)
  ,('d1000000-0000-0000-0000-000000000101',
   'Market Cold Cabinet',
   'Glass-door refrigerator for a small dairy and fresh juice shop.',
   'Business Equipment', 690000, 'NGN', 'Benin City', 'NG', 'Within 30 days', 'active', now() - interval '16 days 10 hours', true)
  ,('d1000000-0000-0000-0000-000000000102',
   'Borehole Storage Tank',
   'Water tank and stand for a school and surrounding households.',
   'Community', 530000, 'NGN', 'Jos', 'NG', 'Urgent', 'active', now() - interval '16 days 18 hours', false)
  ,('d1000000-0000-0000-0000-000000000103',
   'Farm Produce Crates',
   'Reusable crates and weighing scale for transporting vegetables to market.',
   'Agriculture', 275000, 'NGN', 'Abeokuta', 'NG', 'This month', 'active', now() - interval '17 days 10 hours', true)
  ,('d1000000-0000-0000-0000-000000000104',
   'Community First Aid Supplies',
   'First aid kits, stretcher, and protective supplies for a volunteer response team.',
   'Health', 410000, 'NGN', 'Maiduguri', 'NG', 'Urgent', 'active', now() - interval '18 days 4 hours', false)
  ,('d1000000-0000-0000-0000-000000000105',
   'Learning Tablets',
   'Ten durable tablets and charging case for an after-school learning programme.',
   'Technology', 980000, 'NGN', 'Kano', 'NG', 'This term', 'active', now() - interval '19 days 4 hours', true)
  ,('d1000000-0000-0000-0000-000000000106',
   'Solar Irrigation Controller',
   'Controller, panels, and pipes for a small farm irrigation system.',
   'Agriculture', 38500, 'EGP', 'Luxor', 'EG', 'Before next planting season', 'active', now() - interval '17 days 14 hours', false)
  ,('d1000000-0000-0000-0000-000000000107',
   'Vocational Training Tools',
   'Basic carpentry tools and workbenches for a youth skills programme.',
   'Education', 47000, 'EGP', 'Sohag', 'EG', 'This month', 'active', now() - interval '18 days 8 hours', true)
  ,('d1000000-0000-0000-0000-000000000108',
   'Small Grocery Shelves',
   'Metal shelving, counter, and storage bins for a family grocery shop.',
   'Business Equipment', 32500, 'EGP', 'Mansoura', 'EG', 'Within 30 days', 'active', now() - interval '18 days 16 hours', false)
  ,('d1000000-0000-0000-0000-000000000109',
   'Water Filtration Unit',
   'Commercial filter and safe storage tank for a community water point.',
   'Community', 54000, 'EGP', 'Faiyum', 'EG', 'Urgent', 'active', now() - interval '19 days 12 hours', true)
  ,('d1000000-0000-0000-0000-000000000110',
   'Medical Transport Motorbike',
   'Motorbike and secure case for delivering medicines to remote villages.',
    'Health', 118000, 'EGP', 'Minya', 'EG', 'This month', 'active', now() - interval '20 days', false)
on conflict (request_id) do update set
  title = excluded.title,
  specification = excluded.specification,
  category = excluded.category,
  budget = excluded.budget,
  currency = excluded.currency,
  location = excluded.location,
  country = excluded.country,
  urgency = excluded.urgency,
  status = excluded.status,
  listed_at = excluded.listed_at,
  trust_is_verified = excluded.trust_is_verified;

select country, count(*) as request_count
from public.needs_requests
where request_id::text like 'd1000000-%'
group by country
order by country;

-- ============================================================
-- END MERGED SECTION: patch_needs_sample_requests.sql
-- ============================================================


-- ============================================================
-- BEGIN MERGED SECTION: 20260916_enable_needs_request_posting.sql
-- ============================================================

-- Enable authenticated users to post Needs requests.
-- This leaves existing seeded rows intact while adding ownership for new rows.

alter table if exists public.needs_requests
  add column if not exists requester_id uuid references auth.users(id)
    on delete set null;

create index if not exists needs_requests_requester_id_idx
  on public.needs_requests(requester_id);

create index if not exists needs_requests_active_country_idx
  on public.needs_requests(country, listed_at desc)
  where status = 'active';

alter table if exists public.needs_requests enable row level security;

drop policy if exists "Anyone can read active needs requests"
  on public.needs_requests;
create policy "Anyone can read active needs requests"
  on public.needs_requests
  for select
  to anon, authenticated
  using (status = 'active');

drop policy if exists "Authenticated users can create own needs requests"
  on public.needs_requests;
create policy "Authenticated users can create own needs requests"
  on public.needs_requests
  for insert
  to authenticated
  with check (requester_id = auth.uid());

drop policy if exists "Users can update own needs requests"
  on public.needs_requests;
create policy "Users can update own needs requests"
  on public.needs_requests
  for update
  to authenticated
  using (requester_id = auth.uid())
  with check (requester_id = auth.uid());

create or replace view public.v_needs_listings as
select
  request_id,
  title,
  specification,
  category,
  budget,
  currency,
  location,
  country,
  urgency,
  status,
  listed_at,
  created_at,
  trust_is_verified
from public.needs_requests
where status = 'active';

grant select on public.needs_requests to anon, authenticated;
grant insert, update on public.needs_requests to authenticated;
grant select on public.v_needs_listings to anon, authenticated;

-- ============================================================
-- END MERGED SECTION: 20260916_enable_needs_request_posting.sql
-- ============================================================
