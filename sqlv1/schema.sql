-- ============================================
-- OpenCapital Database Schema
-- Version: 3.0 (Fully Integrated)
-- PostgreSQL 14+
-- ============================================
-- Non-custodial peer-to-peer lending marketplace.
-- Platform never holds funds. All lending capital
-- must originate from users' own deposits — never
-- from borrowed disbursements.
--
-- Deploy (fresh):
--   createdb opencapital
--   psql -U postgres -d opencapital -f schema.sql
--
-- Tables (19):
--   users, user_profiles,
--   password_reset_tokens, email_verification_tokens, refresh_tokens,
--   kyc_verifications, risk_assessments,
--   wallet_balances,
--   loan_requests, bids, loan_contracts, contract_bids,
--   disbursements, loan_repayments, repayment_transactions,
--   audit_logs, notifications, user_notes, system_settings
-- ============================================


-- ============================================
-- EXTENSIONS
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ============================================
-- ENUMS
-- ============================================

-- User identity & access
CREATE TYPE user_role_enum AS ENUM (
    'borrower',
    'lender',
    'both',
    'admin'
);

CREATE TYPE user_status_enum AS ENUM (
    'active',
    'suspended',
    'deactivated',
    'pending_verification'
);

-- Reputation tier derived from reputation_score (0-100):
--   platinum >= 85  |  gold >= 70  |  silver >= 55
--   bronze   >= 40  |  restricted  < 40
CREATE TYPE reputation_tier_enum AS ENUM (
    'restricted',
    'bronze',
    'silver',
    'gold',
    'platinum'
);

-- KYC
CREATE TYPE kyc_status_enum AS ENUM (
    'not_started',
    'pending',
    'approved',
    'rejected',
    'expired'
);

-- Risk
CREATE TYPE risk_category_enum AS ENUM (
    'low',
    'medium',
    'high',
    'very_high'
);

-- Loan lifecycle
CREATE TYPE loan_request_status_enum AS ENUM (
    'draft',
    'active',
    'partially_funded',
    'fully_funded',
    'expired',
    'cancelled',
    'contracted'
);

CREATE TYPE bid_status_enum AS ENUM (
    'pending',
    'accepted',
    'rejected',
    'withdrawn',
    'expired'
);

CREATE TYPE contract_status_enum AS ENUM (
    'draft',
    'active',
    'completed',
    'defaulted',
    'cancelled'
);

-- Payments
CREATE TYPE payment_method_enum AS ENUM (
    'mobile_money',
    'bank_transfer',
    'card',
    'wallet'
);

CREATE TYPE disbursement_status_enum AS ENUM (
    'pending',
    'processing',
    'completed',
    'failed',
    'cancelled'
);

CREATE TYPE repayment_status_enum AS ENUM (
    'pending',
    'paid',
    'overdue',
    'partial',
    'defaulted'
);

CREATE TYPE transaction_status_enum AS ENUM (
    'pending',
    'processing',
    'completed',
    'failed',
    'reversed'
);

-- Audit
CREATE TYPE event_category_enum AS ENUM (
    'authentication',
    'user_management',
    'loan_request',
    'bid',
    'contract',
    'payment',
    'system',
    'security'
);

CREATE TYPE event_status_enum AS ENUM (
    'success',
    'failure',
    'warning'
);

-- Settings
CREATE TYPE setting_type_enum AS ENUM (
    'string',
    'number',
    'boolean',
    'json'
);


-- ============================================
-- TABLE: users
-- Core authentication and identity record.
-- One row per account. role='both' enables
-- borrowing and lending from the same account.
--
-- reputation_score (0-100) is recalculated after
-- every contract event via sp_calculate_reputation_score().
-- reputation_tier is auto-synced by trg_sync_reputation_tier
-- (fires BEFORE UPDATE, alphabetically before trg_users_updated_at).
-- ============================================

CREATE TABLE users (
    user_id       UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    email         VARCHAR(255) UNIQUE NOT NULL,
    phone_number  VARCHAR(20)  UNIQUE,
    password_hash VARCHAR(255) NOT NULL,

    -- Role & status
    role   user_role_enum   NOT NULL DEFAULT 'borrower',
    status user_status_enum NOT NULL DEFAULT 'pending_verification',

    -- Email / phone verification
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    phone_verified BOOLEAN NOT NULL DEFAULT FALSE,

    -- Two-factor auth
    two_factor_enabled BOOLEAN     NOT NULL DEFAULT FALSE,
    two_factor_secret  VARCHAR(255),

    -- Login tracking & brute-force protection
    last_login_at         TIMESTAMP,
    last_login_ip         VARCHAR(45),
    failed_login_attempts INT       NOT NULL DEFAULT 0,
    locked_until          TIMESTAMP,

    -- Reputation system
    -- Score formula: repayment_performance*40% + participation_history*20%
    --                + risk_accuracy*20% + consistency_reliability*20%
    -- tier is auto-maintained by trg_sync_reputation_tier — never write it directly.
    reputation_score INT                  NOT NULL DEFAULT 50
        CONSTRAINT chk_reputation_score CHECK (reputation_score BETWEEN 0 AND 100),
    reputation_tier  reputation_tier_enum NOT NULL DEFAULT 'bronze',

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  users                  IS 'Core accounts. role=both enables same account to borrow and lend.';
COMMENT ON COLUMN users.reputation_score IS 'Behavior score 0-100. Recalculate with sp_calculate_reputation_score() after contract events.';
COMMENT ON COLUMN users.reputation_tier  IS 'Auto-synced from reputation_score by trg_sync_reputation_tier. Never write directly.';


-- ============================================
-- TABLE: user_profiles
-- Extended personal, address, employment, and
-- business information.
-- ANONYMITY RULE: district is the only address
-- field exposed publicly on loan listings.
-- Full details revealed post-contract to parties.
-- ============================================

CREATE TABLE user_profiles (
    profile_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id    UUID UNIQUE NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,

    -- Personal (all masked on public endpoints)
    first_name    VARCHAR(100),
    last_name     VARCHAR(100),
    date_of_birth DATE,
    gender        VARCHAR(20),

    -- Address (only district exposed publicly pre-contract)
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city          VARCHAR(100),
    district      VARCHAR(100),  -- only public field
    country       VARCHAR(100) NOT NULL DEFAULT 'Uganda',
    postal_code   VARCHAR(20),

    -- Employment (masked publicly)
    employment_status VARCHAR(50),
    employer_name     VARCHAR(255),
    job_title         VARCHAR(100),
    monthly_income    DECIMAL(15, 2),

    -- Business (SME / corporate borrowers)
    business_name                VARCHAR(255),
    business_registration_number VARCHAR(100),
    business_type                VARCHAR(100),
    years_in_business            INT,

    -- Profile completeness tracking
    profile_completed             BOOLEAN NOT NULL DEFAULT FALSE,
    profile_completion_percentage INT     NOT NULL DEFAULT 0,

    avatar_url VARCHAR(500),

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  user_profiles          IS 'Extended profile. Only district is exposed on public loan listings.';
COMMENT ON COLUMN user_profiles.district IS 'Only address field shown publicly pre-contract. Full address revealed post-contract to parties only.';


-- ============================================
-- TABLE: password_reset_tokens
-- Single-use, expires after 1 hour.
-- ============================================

CREATE TABLE password_reset_tokens (
    token_id   UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id    UUID         NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,  -- SHA-256 of raw token
    expires_at TIMESTAMP    NOT NULL,
    used       BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE password_reset_tokens IS 'Single-use password reset tokens. Expire 1 hour after creation.';


-- ============================================
-- TABLE: email_verification_tokens
-- ============================================

CREATE TABLE email_verification_tokens (
    verification_id UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID         NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    email           VARCHAR(255) NOT NULL,
    token_hash      VARCHAR(255) NOT NULL,
    expires_at      TIMESTAMP    NOT NULL,
    verified_at     TIMESTAMP,
    created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE email_verification_tokens IS 'Email confirmation tokens sent on registration or email change.';


-- ============================================
-- TABLE: refresh_tokens
-- Secure JWT refresh token store.
-- Raw token is NEVER stored — only its SHA-256 hash.
--
-- Rotation protocol (called on every /auth/refresh):
--   1. Look up token_hash in this table
--   2. Verify not revoked and not expired
--   3. Set revoked=TRUE, revoked_at=NOW() on old row
--   4. INSERT new row, set replaced_by=new_token_id on old row
--   5. Return new access + refresh token pair
--
-- Reuse attack detection:
--   If a revoked token is presented, walk the replaced_by
--   chain and revoke the entire family.
-- ============================================

CREATE TABLE refresh_tokens (
    token_id    UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID         NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,

    token_hash  VARCHAR(255) UNIQUE NOT NULL,  -- SHA-256, never plaintext

    -- Session context for multi-device support
    user_agent  TEXT,
    ip_address  VARCHAR(45),

    -- Lifecycle
    expires_at TIMESTAMP NOT NULL,  -- created_at + system_settings.refresh_token_days
    revoked    BOOLEAN   NOT NULL DEFAULT FALSE,
    revoked_at TIMESTAMP,

    -- Rotation chain: points to the token that superseded this one
    replaced_by UUID REFERENCES refresh_tokens(token_id) ON DELETE SET NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  refresh_tokens             IS 'JWT refresh tokens. Rotate on /auth/refresh. Revoke on /auth/logout. SHA-256 hash only.';
COMMENT ON COLUMN refresh_tokens.replaced_by IS 'Chain for reuse-attack detection. If revoked token reused, revoke entire chain.';


-- ============================================
-- TABLE: kyc_verifications
-- One active verification record per user.
-- status='approved' is required before any loan
-- can be created (enforced by trg_require_kyc_for_loan).
-- Admin sets verified_by on approval/rejection.
-- KYC expires after system_settings.kyc_validity_months.
-- ============================================

CREATE TABLE kyc_verifications (
    verification_id UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID            NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,

    status          kyc_status_enum NOT NULL DEFAULT 'not_started',

    -- Government ID
    id_type        VARCHAR(50),
    id_number      VARCHAR(100),
    id_front_url   VARCHAR(500),
    id_back_url    VARCHAR(500),
    id_verified    BOOLEAN   NOT NULL DEFAULT FALSE,
    id_verified_at TIMESTAMP,

    -- Liveness check
    selfie_url         VARCHAR(500),
    selfie_verified    BOOLEAN   NOT NULL DEFAULT FALSE,
    selfie_verified_at TIMESTAMP,

    -- Proof of address
    proof_of_address_url         VARCHAR(500),
    proof_of_address_verified    BOOLEAN   NOT NULL DEFAULT FALSE,
    proof_of_address_verified_at TIMESTAMP,

    -- Business documents (SME / corporate borrowers only)
    business_registration_url VARCHAR(500),
    business_license_url      VARCHAR(500),
    tax_clearance_url         VARCHAR(500),

    -- Admin review
    verified_by        UUID REFERENCES users(user_id) ON DELETE SET NULL,
    verification_notes TEXT,
    rejection_reason   TEXT,

    submitted_at TIMESTAMP,
    verified_at  TIMESTAMP,
    expires_at   TIMESTAMP,  -- verified_at + kyc_validity_months

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  kyc_verifications         IS 'KYC records. status=approved required before loan creation (DB trigger enforced).';
COMMENT ON COLUMN kyc_verifications.expires_at IS 'Re-KYC required after expiry. Set to verified_at + system_settings.kyc_validity_months.';


-- ============================================
-- TABLE: risk_assessments
-- Credit and risk scoring per user.
-- A new row is inserted each time scores are
-- recalculated (is_current on old row set FALSE).
-- sp_calculate_credit_score() populates credit_score.
-- Only the credit score band (e.g. "600-649") is
-- ever shown publicly — never the raw number.
-- ============================================

CREATE TABLE risk_assessments (
    assessment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id       UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,

    -- Scores
    credit_score  INT               CONSTRAINT chk_credit_score CHECK (credit_score BETWEEN 300 AND 850),
    risk_score    DECIMAL(5, 2)     CONSTRAINT chk_risk_score   CHECK (risk_score   BETWEEN 0   AND 100),
    risk_category risk_category_enum,

    -- Component factor scores
    income_verification_score       INT,
    employment_stability_score      INT,
    debt_to_income_ratio            DECIMAL(5, 2),
    previous_loan_performance_score INT,

    -- Metadata
    assessment_date  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assessed_by      UUID REFERENCES users(user_id) ON DELETE SET NULL,
    assessment_notes TEXT,

    -- Validity window
    valid_until TIMESTAMP,
    is_current  BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  risk_assessments           IS 'Credit & risk scores. is_current=TRUE is live. Old rows kept for audit.';
COMMENT ON COLUMN risk_assessments.credit_score IS '300-850. Calculated by sp_calculate_credit_score(). Only band (e.g. 600-649) exposed publicly.';


-- ============================================
-- TABLE: wallet_balances
-- Core fund segregation. One row per user,
-- created automatically on registration by
-- trg_auto_create_wallet.
--
-- Three segregated pools — enforced at DB level:
--
--   lendable_balance      Own deposited funds.
--                         The ONLY pool eligible for bid amounts.
--                         "Available to Lend" in UI = this column.
--
--   locked_repayment      Reserved for scheduled repayments on
--                         active borrowed contracts.
--                         Cannot be withdrawn or lent while locked.
--
--   non_lendable_borrowed Funds received from loan disbursements.
--                         PERMANENTLY ineligible for lending.
--                         Can never flow into lendable_balance.
--
-- Trigger chain for a full loan lifecycle:
--   deposit          → lendable_balance   ↑
--   bid placed       → (validated: lendable_balance >= bid_amount)
--   bid accepted     → lendable_balance ↓, locked_repayment ↑  (lender)
--   disbursement     → non_lendable_borrowed ↑                 (borrower)
--   repayment paid   → non_lendable_borrowed ↓ / lendable ↓    (borrower)
--                    → lendable_balance ↑, locked_repayment ↓   (lender)
-- ============================================

CREATE TABLE wallet_balances (
    wallet_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id   UUID UNIQUE NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,

    lendable_balance      DECIMAL(15, 2) NOT NULL DEFAULT 0
        CONSTRAINT chk_lendable_non_negative     CHECK (lendable_balance >= 0),

    locked_repayment      DECIMAL(15, 2) NOT NULL DEFAULT 0
        CONSTRAINT chk_locked_non_negative       CHECK (locked_repayment >= 0),

    non_lendable_borrowed DECIMAL(15, 2) NOT NULL DEFAULT 0
        CONSTRAINT chk_non_lendable_non_negative CHECK (non_lendable_borrowed >= 0),

    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  wallet_balances                       IS 'Fund segregation. Prevents re-lending of borrowed capital. Auto-created on user registration.';
COMMENT ON COLUMN wallet_balances.lendable_balance      IS 'Own deposited capital. Only pool that funds bids. UI "Available to Lend" = this value.';
COMMENT ON COLUMN wallet_balances.locked_repayment      IS 'Reserved for upcoming repayments. Cannot be withdrawn or re-lent.';
COMMENT ON COLUMN wallet_balances.non_lendable_borrowed IS 'Received from loan disbursements. Permanently ineligible for lending.';


-- ============================================
-- TABLE: loan_requests
-- A borrower's funding request, listed publicly
-- with PII masked until contract acceptance.
--
-- Publicly safe fields (returned by GET /loans):
--   request_id, requested_amount, duration_months,
--   max_interest_rate, purpose, district,
--   risk_category, credit_score_band,
--   funding_percentage, number_of_bids, listed_at
--
-- Masked fields (never in public response):
--   borrower_id identity, email, phone, name, dob,
--   full address, employment, documents
-- ============================================

CREATE TABLE loan_requests (
    request_id  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    borrower_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,

    -- Loan terms
    requested_amount    DECIMAL(15, 2) NOT NULL,
    purpose             VARCHAR(255)   NOT NULL,
    purpose_description TEXT,
    duration_months     INT            NOT NULL,
    max_interest_rate   DECIMAL(5, 2),

    -- Funding progress (maintained by trg_update_funding_progress)
    total_bid_amount   DECIMAL(15, 2) NOT NULL DEFAULT 0,
    number_of_bids     INT            NOT NULL DEFAULT 0,
    funding_percentage DECIMAL(5, 2)  NOT NULL DEFAULT 0,

    -- Lifecycle
    status     loan_request_status_enum NOT NULL DEFAULT 'draft',
    listed_at  TIMESTAMP,
    expires_at TIMESTAMP,  -- set to listed_at + system_settings.listing_duration_days
    funded_at  TIMESTAMP,

    -- Supporting documents (JSONB array of {name, url, type})
    supporting_documents JSONB,

    views_count INT NOT NULL DEFAULT 0,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_lr_amount_positive  CHECK (requested_amount > 0),
    CONSTRAINT chk_lr_duration_positive CHECK (duration_months > 0),
    CONSTRAINT chk_lr_max_rate          CHECK (max_interest_rate IS NULL OR max_interest_rate BETWEEN 0 AND 100),
    CONSTRAINT chk_lr_funding_pct       CHECK (funding_percentage BETWEEN 0 AND 100)
);

COMMENT ON TABLE  loan_requests           IS 'Borrower funding requests. PII masked on public endpoints pre-contract.';
COMMENT ON COLUMN loan_requests.expires_at IS 'Set to listed_at + listing_duration_days from system_settings.';


-- ============================================
-- TABLE: bids
-- A lender's offer to fund a loan_request.
-- bid_amount must not exceed lendable_balance
-- (enforced by trg_enforce_lendable_on_bid).
-- Funds locked on acceptance by trg_lock_funds_on_accept.
-- Funding progress updated by trg_update_funding_progress.
-- ============================================

CREATE TABLE bids (
    bid_id     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id UUID NOT NULL REFERENCES loan_requests(request_id) ON DELETE CASCADE,
    lender_id  UUID NOT NULL REFERENCES users(user_id)            ON DELETE CASCADE,

    bid_amount    DECIMAL(15, 2) NOT NULL,
    interest_rate DECIMAL(5, 2)  NOT NULL,

    status      bid_status_enum NOT NULL DEFAULT 'pending',
    auto_accept BOOLEAN         NOT NULL DEFAULT FALSE,

    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    accepted_at  TIMESTAMP,
    withdrawn_at TIMESTAMP,
    expires_at   TIMESTAMP,

    CONSTRAINT chk_bid_amount_positive CHECK (bid_amount > 0),
    CONSTRAINT chk_bid_rate            CHECK (interest_rate BETWEEN 0 AND 100)
);

COMMENT ON TABLE bids IS 'Lender bids on loan requests. bid_amount drawn from lendable_balance only (DB enforced).';


-- ============================================
-- TABLE: loan_contracts
-- Executed agreement between borrower and one or
-- more lenders. Created after bid acceptance.
--
-- Activation sequence:
--   1. Borrower signs   → borrower_signed = TRUE
--   2. Each lender signs → contract_bids.lender_signed = TRUE
--   3. Last lender signs → trg_check_all_lenders_signed sets
--                          all_lenders_signed = TRUE,
--                          contract_activated_at = NOW()
--   4. API calls        → sp_calculate_repayment_schedule(contract_id)
--
-- Status maintained by trg_update_contract_on_repayment.
-- ============================================

CREATE TABLE loan_contracts (
    contract_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id  UUID NOT NULL REFERENCES loan_requests(request_id),
    borrower_id UUID NOT NULL REFERENCES users(user_id),

    -- Terms
    total_amount           DECIMAL(15, 2) NOT NULL,
    weighted_interest_rate DECIMAL(5, 2)  NOT NULL,
    duration_months        INT            NOT NULL,

    -- Computed payment schedule summary (detail in loan_repayments)
    monthly_payment DECIMAL(15, 2) NOT NULL,
    total_repayment DECIMAL(15, 2) NOT NULL,
    total_interest  DECIMAL(15, 2) NOT NULL,

    -- Lifecycle
    status contract_status_enum NOT NULL DEFAULT 'draft',

    -- Borrower signature
    borrower_signed       BOOLEAN   NOT NULL DEFAULT FALSE,
    borrower_signed_at    TIMESTAMP,
    borrower_signature_ip VARCHAR(45),

    -- Lender signatures (detail per lender in contract_bids)
    all_lenders_signed    BOOLEAN   NOT NULL DEFAULT FALSE,  -- set by trg_check_all_lenders_signed
    contract_activated_at TIMESTAMP,

    -- Document
    contract_document_url VARCHAR(500),
    contract_hash         VARCHAR(255),  -- SHA-256 of signed PDF for tamper detection

    -- Disbursement
    disbursed        BOOLEAN        NOT NULL DEFAULT FALSE,
    disbursed_at     TIMESTAMP,
    disbursed_amount DECIMAL(15, 2),

    -- Repayment tracking (maintained by trg_update_contract_on_repayment)
    total_repaid        DECIMAL(15, 2) NOT NULL DEFAULT 0,
    outstanding_balance DECIMAL(15, 2),
    next_payment_date   DATE,
    last_payment_date   DATE,
    days_overdue        INT            NOT NULL DEFAULT 0,
    maturity_date       DATE,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_lc_amount_positive CHECK (total_amount > 0),
    CONSTRAINT chk_lc_rate            CHECK (weighted_interest_rate BETWEEN 0 AND 100),
    CONSTRAINT chk_lc_outstanding     CHECK (outstanding_balance IS NULL OR outstanding_balance >= 0),
    CONSTRAINT chk_lc_total_repaid    CHECK (total_repaid >= 0)
);

COMMENT ON TABLE  loan_contracts                     IS 'Executed contracts. sp_calculate_repayment_schedule() called on activation.';
COMMENT ON COLUMN loan_contracts.contract_hash       IS 'SHA-256 of signed PDF. Used for tamper detection and audit.';
COMMENT ON COLUMN loan_contracts.all_lenders_signed  IS 'Set TRUE by trg_check_all_lenders_signed when every contract_bids row is signed.';


-- ============================================
-- TABLE: contract_bids
-- Junction table: links each accepted bid to its
-- contract. One row per lender per contract.
-- Per-lender signature tracked here.
-- trg_check_all_lenders_signed fires on UPDATE.
-- ============================================

CREATE TABLE contract_bids (
    contract_bid_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contract_id     UUID NOT NULL REFERENCES loan_contracts(contract_id) ON DELETE CASCADE,
    bid_id          UUID NOT NULL REFERENCES bids(bid_id),
    lender_id       UUID NOT NULL REFERENCES users(user_id),

    amount        DECIMAL(15, 2) NOT NULL,
    interest_rate DECIMAL(5, 2)  NOT NULL,

    -- Per-lender signature tracking
    lender_signed       BOOLEAN   NOT NULL DEFAULT FALSE,
    lender_signed_at    TIMESTAMP,
    lender_signature_ip VARCHAR(45),

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (bid_id, contract_id),

    CONSTRAINT chk_cb_amount_positive CHECK (amount > 0),
    CONSTRAINT chk_cb_rate            CHECK (interest_rate BETWEEN 0 AND 100)
);

COMMENT ON TABLE  contract_bids              IS 'One row per lender per contract. lender_signed drives all_lenders_signed on parent contract.';
COMMENT ON COLUMN contract_bids.lender_signed IS 'Set TRUE when lender signs. trg_check_all_lenders_signed auto-activates contract when all sign.';


-- ============================================
-- TABLE: disbursements
-- One row per lender-to-borrower fund transfer
-- within a contract. provider_response stores
-- the raw provider webhook/API payload.
-- trg_credit_borrower_on_disbursement fires when
-- status transitions to 'completed'.
-- ============================================

CREATE TABLE disbursements (
    disbursement_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contract_id     UUID NOT NULL REFERENCES loan_contracts(contract_id),
    bid_id          UUID NOT NULL REFERENCES bids(bid_id),
    lender_id       UUID NOT NULL REFERENCES users(user_id),
    borrower_id     UUID NOT NULL REFERENCES users(user_id),

    amount DECIMAL(15, 2) NOT NULL,

    -- Payment rail
    payment_method    payment_method_enum NOT NULL,
    payment_provider  VARCHAR(100),   -- 'mtn_momo' | 'airtel_money' | 'bank_transfer'
    payment_reference VARCHAR(255),

    status disbursement_status_enum NOT NULL DEFAULT 'pending',

    initiated_at TIMESTAMP,
    completed_at TIMESTAMP,
    failed_at    TIMESTAMP,

    -- Provider data
    transaction_id    VARCHAR(255),
    provider_response JSONB,   -- raw webhook payload for reconciliation
    failure_reason    TEXT,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  disbursements                   IS 'Fund transfers from each lender to borrower. completed status triggers borrower wallet credit.';
COMMENT ON COLUMN disbursements.provider_response IS 'Raw provider webhook payload. Preserve for reconciliation and audit.';


-- ============================================
-- TABLE: loan_repayments
-- One row per installment. Generated by
-- sp_calculate_repayment_schedule() on contract
-- activation. Status changes trigger
-- trg_update_contract_on_repayment and
-- trg_debit_borrower_on_repayment.
-- ============================================

CREATE TABLE loan_repayments (
    repayment_id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contract_id        UUID NOT NULL REFERENCES loan_contracts(contract_id) ON DELETE CASCADE,

    -- Scheduled
    installment_number INT            NOT NULL,
    due_date           DATE           NOT NULL,
    amount_due         DECIMAL(15, 2) NOT NULL,
    principal_due      DECIMAL(15, 2) NOT NULL,
    interest_due       DECIMAL(15, 2) NOT NULL,

    -- Status
    status repayment_status_enum NOT NULL DEFAULT 'pending',

    -- Actuals
    amount_paid    DECIMAL(15, 2) NOT NULL DEFAULT 0,
    principal_paid DECIMAL(15, 2) NOT NULL DEFAULT 0,
    interest_paid  DECIMAL(15, 2) NOT NULL DEFAULT 0,
    late_fee       DECIMAL(15, 2) NOT NULL DEFAULT 0,

    paid_at   TIMESTAMP,
    days_late INT NOT NULL DEFAULT 0,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_rep_amount_due    CHECK (amount_due > 0),
    CONSTRAINT chk_rep_principal_due CHECK (principal_due > 0),
    CONSTRAINT chk_rep_interest_due  CHECK (interest_due >= 0),
    CONSTRAINT chk_rep_amount_paid   CHECK (amount_paid >= 0)
);

COMMENT ON TABLE loan_repayments IS 'Amortization schedule rows. Generated by sp_calculate_repayment_schedule() on activation.';


-- ============================================
-- TABLE: repayment_transactions
-- Actual payment events against installments.
-- One installment can have multiple transactions
-- (partial payments, retries).
-- trg_release_lender_funds fires on status →
-- 'completed'.
-- ============================================

CREATE TABLE repayment_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    repayment_id   UUID NOT NULL REFERENCES loan_repayments(repayment_id),
    contract_id    UUID NOT NULL REFERENCES loan_contracts(contract_id),
    bid_id         UUID NOT NULL REFERENCES bids(bid_id),
    borrower_id    UUID NOT NULL REFERENCES users(user_id),
    lender_id      UUID NOT NULL REFERENCES users(user_id),

    amount           DECIMAL(15, 2) NOT NULL,
    principal_amount DECIMAL(15, 2) NOT NULL,
    interest_amount  DECIMAL(15, 2) NOT NULL,

    -- Payment rail
    payment_method    payment_method_enum NOT NULL,
    payment_provider  VARCHAR(100),
    payment_reference VARCHAR(255),

    status transaction_status_enum NOT NULL DEFAULT 'pending',

    initiated_at TIMESTAMP,
    completed_at TIMESTAMP,

    -- Provider data
    provider_transaction_id VARCHAR(255),
    provider_response       JSONB,
    failure_reason          TEXT,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE repayment_transactions IS 'Payment events per installment. completed status releases lender locked_repayment funds.';


-- ============================================
-- TABLE: audit_logs
-- Append-only compliance trail.
-- NEVER UPDATE OR DELETE ROWS.
-- Written by audit-logger middleware on every
-- POST / PUT / PATCH / DELETE API call.
-- ============================================

CREATE TABLE audit_logs (
    log_id  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(user_id) ON DELETE SET NULL,

    -- Event classification
    event_type     VARCHAR(100)        NOT NULL,
    event_category event_category_enum NOT NULL,
    entity_type    VARCHAR(50),
    entity_id      UUID,
    action         VARCHAR(100)        NOT NULL,
    description    TEXT,

    -- Request context
    ip_address     VARCHAR(45),
    user_agent     TEXT,
    request_url    VARCHAR(500),
    request_method VARCHAR(10),

    -- Change data capture
    old_values JSONB,
    new_values JSONB,

    -- Outcome
    status        event_status_enum NOT NULL DEFAULT 'success',
    error_message TEXT,

    -- Correlation: groups all events from one API request
    correlation_id UUID,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE audit_logs IS 'Immutable audit trail. NEVER update or delete rows. Written by audit middleware on every write operation.';


-- ============================================
-- TABLE: notifications
-- In-app notification feed per user.
-- Written by notification service on key events.
-- data JSONB carries context for deep-linking
-- (e.g. {bid_id, loan_id, contract_id}).
-- ============================================

CREATE TABLE notifications (
    notification_id UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID         NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    type            VARCHAR(50)  NOT NULL,  -- 'bid_received' | 'bid_accepted' | 'repayment_due' | etc.
    title           VARCHAR(255) NOT NULL,
    message         TEXT         NOT NULL,
    data            JSONB,
    read            BOOLEAN      NOT NULL DEFAULT FALSE,
    read_at         TIMESTAMP,
    created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE notifications IS 'In-app notification feed. data JSONB carries deep-link context.';


-- ============================================
-- TABLE: user_notes
-- Internal CRM notes written by admin / support.
-- Never visible to the subject user.
-- ============================================

CREATE TABLE user_notes (
    note_id    UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id    UUID        NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    created_by UUID        NOT NULL REFERENCES users(user_id) ON DELETE SET NULL,
    note_type  VARCHAR(50) NOT NULL DEFAULT 'general',
    content    TEXT        NOT NULL,
    is_internal BOOLEAN    NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE user_notes IS 'Admin CRM notes. is_internal=TRUE — never expose to subject user.';


-- ============================================
-- TABLE: system_settings
-- Runtime platform configuration.
-- Seeded below. Fetch in app layer with:
--   SELECT setting_value FROM system_settings WHERE setting_key = 'min_loan_amount';
-- is_public=TRUE values served to clients for
-- front-end validation.
-- ============================================

CREATE TABLE system_settings (
    setting_id    UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    setting_key   VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    setting_type  setting_type_enum NOT NULL DEFAULT 'string',
    category      VARCHAR(50),
    description   TEXT,
    is_public     BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  system_settings          IS 'Runtime config. Cache in app layer. is_public=TRUE values served by /settings endpoint.';
COMMENT ON COLUMN system_settings.is_public IS 'If TRUE, returned by public /settings endpoint for client-side form validation.';


-- ============================================
-- INDEXES
-- ============================================

-- users
CREATE INDEX idx_users_email         ON users(email);
CREATE INDEX idx_users_phone         ON users(phone_number);
CREATE INDEX idx_users_status        ON users(status);
CREATE INDEX idx_users_role_status   ON users(role, status);
CREATE INDEX idx_users_reputation    ON users(reputation_score DESC);
CREATE INDEX idx_users_rep_tier      ON users(reputation_tier);

-- user_profiles
CREATE INDEX idx_profiles_user       ON user_profiles(user_id);

-- password_reset_tokens
CREATE INDEX idx_prt_hash            ON password_reset_tokens(token_hash);
CREATE INDEX idx_prt_expires         ON password_reset_tokens(expires_at);

-- email_verification_tokens
CREATE INDEX idx_evt_hash            ON email_verification_tokens(token_hash);
CREATE INDEX idx_evt_expires         ON email_verification_tokens(expires_at);

-- refresh_tokens
CREATE INDEX idx_rt_user             ON refresh_tokens(user_id);
CREATE INDEX idx_rt_hash             ON refresh_tokens(token_hash);
CREATE INDEX idx_rt_expires          ON refresh_tokens(expires_at);
-- Partial: only active tokens — hot path for /auth/refresh
CREATE INDEX idx_rt_active           ON refresh_tokens(user_id, expires_at)
    WHERE revoked = FALSE;

-- kyc_verifications
CREATE INDEX idx_kyc_user            ON kyc_verifications(user_id);
CREATE INDEX idx_kyc_status          ON kyc_verifications(status);

-- risk_assessments
CREATE INDEX idx_risk_user           ON risk_assessments(user_id);
CREATE INDEX idx_risk_category       ON risk_assessments(risk_category);
-- Partial: fast fetch of current assessment
CREATE INDEX idx_risk_current        ON risk_assessments(user_id)
    WHERE is_current = TRUE;

-- wallet_balances
CREATE INDEX idx_wallet_user         ON wallet_balances(user_id);

-- loan_requests
CREATE INDEX idx_lr_borrower         ON loan_requests(borrower_id);
CREATE INDEX idx_lr_status           ON loan_requests(status);
CREATE INDEX idx_lr_expires          ON loan_requests(expires_at);
CREATE INDEX idx_lr_status_expires   ON loan_requests(status, expires_at);
CREATE INDEX idx_lr_borrower_status  ON loan_requests(borrower_id, status, created_at DESC);
-- Partial: marketplace listing query
CREATE INDEX idx_lr_active           ON loan_requests(status)
    WHERE status IN ('active', 'partially_funded');

-- bids
CREATE INDEX idx_bids_request        ON bids(request_id);
CREATE INDEX idx_bids_lender         ON bids(lender_id);
CREATE INDEX idx_bids_status         ON bids(status);
CREATE INDEX idx_bids_rate           ON bids(interest_rate);
CREATE INDEX idx_bids_request_status ON bids(request_id, status);
CREATE INDEX idx_bids_lender_status  ON bids(lender_id, status, created_at DESC);

-- loan_contracts
CREATE INDEX idx_lc_borrower         ON loan_contracts(borrower_id);
CREATE INDEX idx_lc_status           ON loan_contracts(status);
CREATE INDEX idx_lc_next_payment     ON loan_contracts(next_payment_date);
CREATE INDEX idx_lc_borrower_status  ON loan_contracts(borrower_id, status);
CREATE INDEX idx_lc_status_payment   ON loan_contracts(status, next_payment_date);
-- Partial: active contracts only
CREATE INDEX idx_lc_active           ON loan_contracts(status)
    WHERE status = 'active';

-- contract_bids
CREATE INDEX idx_cb_contract         ON contract_bids(contract_id);
CREATE INDEX idx_cb_bid              ON contract_bids(bid_id);
CREATE INDEX idx_cb_lender           ON contract_bids(lender_id);
-- Partial: "has everyone signed?" check
CREATE INDEX idx_cb_unsigned         ON contract_bids(contract_id)
    WHERE lender_signed = FALSE;

-- disbursements
CREATE INDEX idx_disb_contract       ON disbursements(contract_id);
CREATE INDEX idx_disb_status         ON disbursements(status);
CREATE INDEX idx_disb_borrower       ON disbursements(borrower_id);

-- loan_repayments
CREATE INDEX idx_rep_contract        ON loan_repayments(contract_id);
CREATE INDEX idx_rep_due_date        ON loan_repayments(due_date);
CREATE INDEX idx_rep_status          ON loan_repayments(status);
CREATE INDEX idx_rep_due_status      ON loan_repayments(due_date, status);
-- Partial: reminder scheduler query
CREATE INDEX idx_rep_pending_due     ON loan_repayments(status, due_date)
    WHERE status = 'pending';

-- repayment_transactions
CREATE INDEX idx_rpt_repayment       ON repayment_transactions(repayment_id);
CREATE INDEX idx_rpt_status          ON repayment_transactions(status);
CREATE INDEX idx_rpt_lender          ON repayment_transactions(lender_id);
CREATE INDEX idx_rpt_borrower        ON repayment_transactions(borrower_id);

-- audit_logs
CREATE INDEX idx_al_user             ON audit_logs(user_id);
CREATE INDEX idx_al_event_type       ON audit_logs(event_type);
CREATE INDEX idx_al_entity           ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_al_created          ON audit_logs(created_at DESC);
CREATE INDEX idx_al_correlation      ON audit_logs(correlation_id);

-- notifications
CREATE INDEX idx_notif_user_read     ON notifications(user_id, read);
CREATE INDEX idx_notif_user_created  ON notifications(user_id, created_at DESC);

-- user_notes
CREATE INDEX idx_notes_user          ON user_notes(user_id, created_at DESC);

-- system_settings
CREATE INDEX idx_ss_key              ON system_settings(setting_key);
CREATE INDEX idx_ss_category         ON system_settings(category);


-- ============================================
-- SYSTEM SETTINGS SEED DATA
-- ============================================

INSERT INTO system_settings (setting_key, setting_value, setting_type, category, description, is_public) VALUES
    ('platform_fee_percentage', '1.5',      'number',  'fees',        'Platform fee as % of loan amount',                     TRUE),
    ('min_loan_amount',         '100000',   'number',  'limits',      'Minimum loan amount in UGX',                           TRUE),
    ('max_loan_amount',         '50000000', 'number',  'limits',      'Maximum loan amount in UGX',                           TRUE),
    ('min_loan_duration',       '1',        'number',  'limits',      'Minimum loan duration in months',                      TRUE),
    ('max_loan_duration',       '36',       'number',  'limits',      'Maximum loan duration in months',                      TRUE),
    ('min_interest_rate',       '5',        'number',  'limits',      'Minimum interest rate %',                              TRUE),
    ('max_interest_rate',       '30',       'number',  'limits',      'Maximum interest rate %',                              TRUE),
    ('listing_duration_days',   '7',        'number',  'marketplace', 'Days a loan request stays listed before expiry',       TRUE),
    ('kyc_required',            'true',     'boolean', 'compliance',  'KYC approval required before loan creation',           TRUE),
    ('kyc_validity_months',     '12',       'number',  'compliance',  'Months until KYC expires and re-verification required',TRUE),
    ('auto_matching_enabled',   'true',     'boolean', 'marketplace', 'Enable automatic bid-to-loan matching',                FALSE),
    ('late_fee_percentage',     '5',        'number',  'fees',        'Late fee as % of overdue amount',                      TRUE),
    ('grace_period_days',       '7',        'number',  'repayments',  'Days grace before installment marked overdue',         TRUE),
    ('default_threshold_days',  '90',       'number',  'repayments',  'Days overdue before contract marked defaulted',        FALSE),
    ('max_concurrent_loans',    '3',        'number',  'limits',      'Maximum active borrowed contracts per borrower',       TRUE),
    ('min_lender_investment',   '50000',    'number',  'limits',      'Minimum bid amount per lender in UGX',                 TRUE),
    ('auto_logout_minutes',     '30',       'number',  'security',    'Idle session timeout in minutes',                      FALSE),
    ('access_token_minutes',    '15',       'number',  'security',    'Access JWT TTL in minutes',                            FALSE),
    ('refresh_token_days',      '7',        'number',  'security',    'Refresh token TTL in days',                            FALSE);


-- ============================================
-- VIEWS
-- ============================================

-- Active loans — admin dashboard and overdue monitoring
CREATE VIEW v_active_loans AS
SELECT
    lc.contract_id,
    lc.borrower_id,
    up.first_name || ' ' || up.last_name AS borrower_name,
    lc.total_amount,
    lc.weighted_interest_rate,
    lc.duration_months,
    lc.outstanding_balance,
    lc.total_repaid,
    lc.next_payment_date,
    lc.days_overdue,
    lc.status,
    lc.created_at
FROM loan_contracts lc
JOIN user_profiles  up ON lc.borrower_id = up.user_id
WHERE lc.status = 'active';

COMMENT ON VIEW v_active_loans IS 'All active contracts with borrower names. Admin dashboard and overdue detection.';


-- User portfolio — dashboard home page
CREATE VIEW v_user_portfolio AS
SELECT
    u.user_id,
    u.email,
    up.first_name || ' ' || up.last_name AS full_name,
    u.reputation_score,
    u.reputation_tier,

    -- Borrower aggregate
    COUNT(DISTINCT lr.request_id)         AS total_loan_requests,
    COUNT(DISTINCT lc_b.contract_id)      AS active_loans_as_borrower,
    COALESCE(SUM(lc_b.outstanding_balance), 0) AS total_outstanding_debt,

    -- Lender aggregate
    COUNT(DISTINCT b.bid_id)              AS total_bids_placed,
    COUNT(DISTINCT cb.contract_id)        AS total_lent_contracts,
    COALESCE(SUM(CASE WHEN b.status = 'accepted' THEN b.bid_amount END), 0) AS total_invested,

    -- Wallet (three segregated pools)
    COALESCE(wb.lendable_balance, 0)      AS lendable_balance,
    COALESCE(wb.locked_repayment, 0)      AS locked_repayment,
    COALESCE(wb.non_lendable_borrowed, 0) AS non_lendable_borrowed

FROM users u
LEFT JOIN user_profiles  up   ON u.user_id  = up.user_id
LEFT JOIN wallet_balances wb  ON u.user_id  = wb.user_id
LEFT JOIN loan_requests   lr  ON u.user_id  = lr.borrower_id
LEFT JOIN loan_contracts  lc_b ON u.user_id = lc_b.borrower_id
LEFT JOIN bids            b   ON u.user_id  = b.lender_id
LEFT JOIN contract_bids   cb  ON u.user_id  = cb.lender_id
GROUP BY
    u.user_id, u.email, up.first_name, up.last_name,
    u.reputation_score, u.reputation_tier,
    wb.lendable_balance, wb.locked_repayment, wb.non_lendable_borrowed;

COMMENT ON VIEW v_user_portfolio IS 'Dashboard home: borrower stats + lender stats + wallet balances in one query.';


-- Lender returns — Returns page
CREATE VIEW v_lender_investments AS
SELECT
    l.user_id                              AS lender_id,
    up.first_name || ' ' || up.last_name   AS lender_name,
    l.reputation_score,
    l.reputation_tier,
    COALESCE(wb.lendable_balance, 0)       AS lendable_balance,
    COUNT(DISTINCT cb.contract_id)         AS total_contracts,
    COUNT(DISTINCT cb.bid_id)              AS total_accepted_bids,
    COALESCE(SUM(cb.amount), 0)            AS total_invested,
    COALESCE(SUM(CASE WHEN lc.status = 'active'    THEN cb.amount END), 0) AS active_investments,
    COALESCE(SUM(CASE WHEN lc.status = 'completed' THEN cb.amount END), 0) AS completed_investments,
    COALESCE(SUM(CASE WHEN lc.status = 'defaulted' THEN cb.amount END), 0) AS defaulted_investments,
    ROUND(AVG(cb.interest_rate), 2)        AS avg_interest_rate
FROM users           l
JOIN  user_profiles  up ON l.user_id  = up.user_id
JOIN  contract_bids  cb ON l.user_id  = cb.lender_id
JOIN  loan_contracts lc ON cb.contract_id = lc.contract_id
LEFT JOIN wallet_balances wb ON l.user_id = wb.user_id
WHERE l.role IN ('lender', 'both')
GROUP BY
    l.user_id, up.first_name, up.last_name,
    l.reputation_score, l.reputation_tier,
    wb.lendable_balance;

COMMENT ON VIEW v_lender_investments IS 'Lender Returns page: invested amounts, returns, default exposure, avg rate.';


-- Platform performance — Analytics charts and monthly reports
CREATE VIEW v_loan_performance AS
SELECT
    DATE_TRUNC('month', lc.created_at)       AS month,
    COUNT(lc.contract_id)                    AS total_loans,
    COALESCE(SUM(lc.total_amount), 0)        AS total_loan_amount,
    ROUND(AVG(lc.weighted_interest_rate), 2) AS avg_interest_rate,
    SUM(CASE WHEN lc.status = 'active'    THEN 1 ELSE 0 END) AS active_loans,
    SUM(CASE WHEN lc.status = 'completed' THEN 1 ELSE 0 END) AS completed_loans,
    SUM(CASE WHEN lc.status = 'defaulted' THEN 1 ELSE 0 END) AS defaulted_loans,
    ROUND(
        100.0 * SUM(CASE WHEN lc.status = 'defaulted' THEN 1 ELSE 0 END)
              / NULLIF(COUNT(lc.contract_id), 0),
        2
    ) AS default_rate_pct
FROM loan_contracts lc
GROUP BY DATE_TRUNC('month', lc.created_at)
ORDER BY month DESC;

COMMENT ON VIEW v_loan_performance IS 'Monthly platform KPIs: volume, default rate, avg rate. Feed analytics charts and reports.';


-- ============================================
-- FUNCTIONS
-- ============================================

-- ── Utility ────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION fn_set_updated_at IS 'Generic updated_at stamper attached to all mutable tables.';


-- ── Reputation ─────────────────────────────────────────────────────────────

-- Pure score-to-tier mapping. IMMUTABLE = safe for computed indexes.
CREATE OR REPLACE FUNCTION fn_score_to_tier(p_score INT)
RETURNS reputation_tier_enum LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
    RETURN CASE
        WHEN p_score >= 85 THEN 'platinum'::reputation_tier_enum
        WHEN p_score >= 70 THEN 'gold'::reputation_tier_enum
        WHEN p_score >= 55 THEN 'silver'::reputation_tier_enum
        WHEN p_score >= 40 THEN 'bronze'::reputation_tier_enum
        ELSE                    'restricted'::reputation_tier_enum
    END;
END;
$$;

COMMENT ON FUNCTION fn_score_to_tier IS 'Maps reputation_score 0-100 → reputation_tier_enum. IMMUTABLE — safe for indexes.';


-- Recalculate reputation_score for a user.
-- Call after contract completion, default, or repayment events:
--   UPDATE users
--   SET reputation_score = sp_calculate_reputation_score(user_id)
--   WHERE user_id = $1;
-- trg_sync_reputation_tier will auto-update reputation_tier.
CREATE OR REPLACE FUNCTION sp_calculate_reputation_score(p_user_id UUID)
RETURNS INT LANGUAGE plpgsql AS $$
DECLARE
    -- Component scores (0-100 each)
    v_repayment_score     NUMERIC := 50;
    v_participation_score NUMERIC := 50;
    v_risk_accuracy_score NUMERIC := 50;
    v_consistency_score   NUMERIC := 50;

    v_total_repayments   INT;
    v_on_time_repayments INT;
    v_total_days_late    INT;
    v_completed_contracts INT;
    v_withdrawn_bids     INT;
    v_total_bids         INT;
BEGIN
    -- ── Component 1: Repayment Performance (40%) ──────────────────────────
    -- On-time rate minus cumulative late-day penalty (max -50)
    SELECT
        COUNT(*),
        COUNT(*) FILTER (WHERE status = 'paid' AND days_late = 0),
        COALESCE(SUM(days_late), 0)
    INTO v_total_repayments, v_on_time_repayments, v_total_days_late
    FROM loan_repayments lr
    JOIN loan_contracts  lc ON lr.contract_id = lc.contract_id
    WHERE lc.borrower_id = p_user_id
      AND lr.status IN ('paid', 'overdue', 'defaulted');

    IF v_total_repayments > 0 THEN
        v_repayment_score := LEAST(100,
            (100.0 * v_on_time_repayments / v_total_repayments)
            - LEAST(50, v_total_days_late * 0.5)
        );
    END IF;

    -- ── Component 2: Participation History (20%) ──────────────────────────
    -- 10 points per completed contract as borrower or lender, capped at 100
    SELECT COUNT(*) FILTER (WHERE status = 'completed')
    INTO   v_completed_contracts
    FROM   loan_contracts
    WHERE  borrower_id = p_user_id
       OR  contract_id IN (SELECT contract_id FROM contract_bids WHERE lender_id = p_user_id);

    v_participation_score := LEAST(100, v_completed_contracts * 10);

    -- ── Component 3: Risk Accuracy (20%) ──────────────────────────────────
    -- How well behaviour matches the stated risk profile (proxy via repayment score)
    v_risk_accuracy_score := CASE
        WHEN v_repayment_score >= 70 THEN 100
        WHEN v_repayment_score >= 50 THEN  70
        WHEN v_repayment_score >= 30 THEN  40
        ELSE                               20
    END;

    -- ── Component 4: Consistency & Reliability (20%) ──────────────────────
    -- Penalise withdrawn-bid ratio
    SELECT
        COUNT(*) FILTER (WHERE status = 'withdrawn'),
        COUNT(*)
    INTO v_withdrawn_bids, v_total_bids
    FROM bids WHERE lender_id = p_user_id;

    IF v_total_bids > 0 THEN
        v_consistency_score := GREATEST(0,
            100 - (100.0 * v_withdrawn_bids / v_total_bids)
        );
    END IF;

    -- ── Weighted final ─────────────────────────────────────────────────────
    RETURN GREATEST(0, LEAST(100, ROUND(
        v_repayment_score     * 0.40 +
        v_participation_score * 0.20 +
        v_risk_accuracy_score * 0.20 +
        v_consistency_score   * 0.20
    )));
END;
$$;

COMMENT ON FUNCTION sp_calculate_reputation_score IS
'Weighted reputation score (0-100). Call after contract events then:
 UPDATE users SET reputation_score = sp_calculate_reputation_score(user_id) WHERE user_id = $1;';


-- ── Credit Score ───────────────────────────────────────────────────────────

-- Calculates credit score (300-850) from profile + history.
-- Called by scoring-engine.ts; result stored in risk_assessments.credit_score.
-- Only the score band (e.g. "600-649") is ever shown publicly.
CREATE OR REPLACE FUNCTION sp_calculate_credit_score(p_user_id UUID)
RETURNS INT LANGUAGE plpgsql AS $$
DECLARE
    v_base             INT     := 500;
    v_income_score     NUMERIC := 0;
    v_employment_score NUMERIC := 0;
    v_payment_score    NUMERIC := 100;
    v_debt_score       NUMERIC := 100;
BEGIN
    -- Income (0-100)
    SELECT CASE
        WHEN monthly_income >= 10000000 THEN 100
        WHEN monthly_income >=  5000000 THEN  80
        WHEN monthly_income >=  2000000 THEN  60
        WHEN monthly_income >=  1000000 THEN  40
        ELSE                                  20
    END INTO v_income_score
    FROM user_profiles WHERE user_id = p_user_id;

    -- Employment (0-100)
    SELECT CASE
        WHEN employment_status = 'employed' AND employer_name IS NOT NULL THEN 100
        WHEN employment_status = 'self_employed'                          THEN  80
        ELSE                                                                    40
    END INTO v_employment_score
    FROM user_profiles WHERE user_id = p_user_id;

    -- Payment history (0-150)
    SELECT COALESCE(
        ROUND(100.0 * COUNT(*) FILTER (WHERE status = 'paid') / NULLIF(COUNT(*), 0))
        + GREATEST(-50, 50 - COALESCE(SUM(days_late), 0) * 0.5),
        100
    ) INTO v_payment_score
    FROM loan_repayments lr
    JOIN loan_contracts  lc ON lr.contract_id = lc.contract_id
    WHERE lc.borrower_id = p_user_id;

    -- Debt utilisation (0-100)
    SELECT CASE
        WHEN COALESCE(SUM(lc.outstanding_balance), 0) = 0                                       THEN 100
        WHEN COALESCE(SUM(lc.outstanding_balance), 0) / NULLIF(up.monthly_income, 0) <= 0.30   THEN  80
        WHEN COALESCE(SUM(lc.outstanding_balance), 0) / NULLIF(up.monthly_income, 0) <= 0.60   THEN  60
        WHEN COALESCE(SUM(lc.outstanding_balance), 0) / NULLIF(up.monthly_income, 0) <= 1.00   THEN  40
        ELSE                                                                                           20
    END INTO v_debt_score
    FROM loan_contracts lc
    JOIN user_profiles  up ON lc.borrower_id = up.user_id
    WHERE lc.borrower_id = p_user_id AND lc.status = 'active';

    RETURN GREATEST(300, LEAST(850, ROUND(
        v_base +
        v_income_score     * 0.15 +
        v_employment_score * 0.20 +
        v_payment_score    * 0.40 +
        v_debt_score       * 0.25
    )));
END;
$$;

COMMENT ON FUNCTION sp_calculate_credit_score IS
'Credit score 300-850. income(15%)+employment(20%)+payment_history(40%)+debt(25%).
 Called by scoring-engine.ts. Result in risk_assessments.credit_score. Band only exposed publicly.';


-- ── Repayment Schedule ──────────────────────────────────────────────────────

-- Generates amortization rows in loan_repayments using annuity formula.
-- Call ONCE after contract_activated_at is set:
--   SELECT sp_calculate_repayment_schedule('<contract_id>');
CREATE OR REPLACE FUNCTION sp_calculate_repayment_schedule(p_contract_id UUID)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    v_amount        DECIMAL(15,2);
    v_rate          DECIMAL(5,2);
    v_months        INT;
    v_start         DATE;
    v_monthly_pmt   DECIMAL(15,2);
    v_remaining     DECIMAL(15,2);
    v_interest_pmt  DECIMAL(15,2);
    v_principal_pmt DECIMAL(15,2);
    v_due           DATE;
    i               INT := 1;
BEGIN
    SELECT total_amount,
           weighted_interest_rate,
           duration_months,
           COALESCE(contract_activated_at::DATE, CURRENT_DATE)
    INTO   v_amount, v_rate, v_months, v_start
    FROM   loan_contracts WHERE contract_id = p_contract_id;

    IF v_amount IS NULL THEN
        RAISE EXCEPTION 'Contract % not found.', p_contract_id;
    END IF;

    -- Annuity formula: PMT = PV * r(1+r)^n / ((1+r)^n - 1)
    v_monthly_pmt := v_amount *
        ((v_rate/100/12) * POWER(1 + v_rate/100/12, v_months)) /
        (POWER(1 + v_rate/100/12, v_months) - 1);

    v_remaining := v_amount;
    v_due       := v_start;

    WHILE i <= v_months LOOP
        v_due           := v_due + INTERVAL '1 month';
        v_interest_pmt  := v_remaining * v_rate / 100 / 12;
        v_principal_pmt := v_monthly_pmt - v_interest_pmt;

        -- Final instalment: absorb rounding drift
        IF i = v_months THEN
            v_principal_pmt := v_remaining;
            v_monthly_pmt   := v_principal_pmt + v_interest_pmt;
        END IF;

        INSERT INTO loan_repayments
            (contract_id, installment_number, due_date,
             amount_due, principal_due, interest_due)
        VALUES
            (p_contract_id, i, v_due,
             ROUND(v_monthly_pmt, 2),
             ROUND(v_principal_pmt, 2),
             ROUND(v_interest_pmt, 2));

        v_remaining := v_remaining - v_principal_pmt;
        i := i + 1;
    END LOOP;
END;
$$;

COMMENT ON FUNCTION sp_calculate_repayment_schedule IS
'Generates amortization schedule into loan_repayments. Call ONCE after contract activation.';


-- ── Monthly Report ──────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION sp_generate_monthly_report(p_year INT, p_month INT)
RETURNS TABLE (
    total_loans       BIGINT,
    total_principal   DECIMAL(15,2),
    total_interest    DECIMAL(15,2),
    total_repaid      DECIMAL(15,2),
    default_rate_pct  DECIMAL(5,2),
    avg_interest_rate DECIMAL(5,2)
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*)::BIGINT,
        COALESCE(SUM(total_amount),   0),
        COALESCE(SUM(total_interest), 0),
        COALESCE(SUM(total_repaid),   0),
        ROUND(
            100.0 * COUNT(*) FILTER (WHERE status = 'defaulted')
                  / NULLIF(COUNT(*), 0),
            2
        ),
        ROUND(AVG(weighted_interest_rate), 2)
    FROM loan_contracts
    WHERE EXTRACT(YEAR  FROM created_at) = p_year
      AND EXTRACT(MONTH FROM created_at) = p_month;
END;
$$;

COMMENT ON FUNCTION sp_generate_monthly_report IS 'Regulatory monthly report. Admin panel and compliance exports.';


-- ============================================
-- TRIGGER FUNCTIONS
-- ============================================

-- ── Reputation tier auto-sync ──────────────────────────────────────────────
-- BEFORE UPDATE on users. Fires before fn_set_updated_at
-- (alphabetically: trg_sync_reputation_tier < trg_users_updated_at).
CREATE OR REPLACE FUNCTION trg_fn_sync_reputation_tier()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.reputation_score IS DISTINCT FROM OLD.reputation_score THEN
        NEW.reputation_tier := fn_score_to_tier(NEW.reputation_score);
    END IF;
    RETURN NEW;
END;
$$;


-- ── Auto-create wallet on user INSERT ──────────────────────────────────────
CREATE OR REPLACE FUNCTION trg_fn_auto_create_wallet()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO wallet_balances (user_id)
    VALUES (NEW.user_id)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$;


-- ── Enforce lendable balance BEFORE bid INSERT ─────────────────────────────
-- Rejects bid if lendable_balance < bid_amount.
-- non_lendable_borrowed is never available here — enforced by the column split.
CREATE OR REPLACE FUNCTION trg_fn_enforce_lendable_on_bid()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_lendable DECIMAL(15,2);
BEGIN
    SELECT lendable_balance INTO v_lendable
    FROM   wallet_balances WHERE user_id = NEW.lender_id;

    IF v_lendable IS NULL THEN
        RAISE EXCEPTION
            'Wallet not found for user %. Please deposit funds before bidding.',
            NEW.lender_id;
    END IF;

    IF v_lendable < NEW.bid_amount THEN
        RAISE EXCEPTION
            'Insufficient lendable balance. Available: % UGX, Required: % UGX.',
            v_lendable, NEW.bid_amount;
    END IF;

    RETURN NEW;
END;
$$;


-- ── Lock lender funds when bid accepted ────────────────────────────────────
-- pending → accepted: lendable_balance ↓, locked_repayment ↑
CREATE OR REPLACE FUNCTION trg_fn_lock_funds_on_accept()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.status = 'accepted' AND OLD.status <> 'accepted' THEN
        UPDATE wallet_balances
        SET lendable_balance = lendable_balance - NEW.bid_amount,
            locked_repayment = locked_repayment + NEW.bid_amount
        WHERE user_id = NEW.lender_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION
                'Wallet not found for lender % during bid acceptance.', NEW.lender_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


-- ── Restore lender funds if accepted bid is withdrawn ──────────────────────
-- Only triggers on accepted → withdrawn (pending → withdrawn has no locked funds).
CREATE OR REPLACE FUNCTION trg_fn_restore_funds_on_withdraw()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_locked DECIMAL(15,2);
BEGIN
    IF NEW.status = 'withdrawn' AND OLD.status = 'accepted' THEN
        SELECT locked_repayment INTO v_locked
        FROM   wallet_balances WHERE user_id = NEW.lender_id;

        IF COALESCE(v_locked, 0) >= NEW.bid_amount THEN
            UPDATE wallet_balances
            SET locked_repayment = locked_repayment - NEW.bid_amount,
                lendable_balance = lendable_balance + NEW.bid_amount
            WHERE user_id = NEW.lender_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


-- ── Update loan funding progress when bid accepted ─────────────────────────
CREATE OR REPLACE FUNCTION trg_fn_update_funding_progress()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_total_bid DECIMAL(15,2);
    v_requested DECIMAL(15,2);
    v_pct       DECIMAL(5,2);
BEGIN
    IF NEW.status = 'accepted' AND OLD.status <> 'accepted' THEN
        SELECT total_bid_amount, requested_amount
        INTO   v_total_bid, v_requested
        FROM   loan_requests WHERE request_id = NEW.request_id;

        v_pct := ((v_total_bid + NEW.bid_amount) / v_requested) * 100;

        UPDATE loan_requests
        SET total_bid_amount   = total_bid_amount + NEW.bid_amount,
            number_of_bids     = number_of_bids + 1,
            funding_percentage = v_pct,
            status = CASE
                WHEN v_pct >= 100 THEN 'fully_funded'::loan_request_status_enum
                WHEN v_pct >    0 THEN 'partially_funded'::loan_request_status_enum
                ELSE status
            END
        WHERE request_id = NEW.request_id;
    END IF;
    RETURN NEW;
END;
$$;


-- ── Credit borrower wallet on disbursement completion ─────────────────────
-- Adds disbursed amount to non_lendable_borrowed ONLY.
-- This money can NEVER move to lendable_balance.
CREATE OR REPLACE FUNCTION trg_fn_credit_borrower_on_disbursement()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.status = 'completed' AND OLD.status <> 'completed' THEN
        INSERT INTO wallet_balances (user_id, non_lendable_borrowed)
        VALUES (NEW.borrower_id, NEW.amount)
        ON CONFLICT (user_id) DO UPDATE
        SET non_lendable_borrowed = wallet_balances.non_lendable_borrowed + NEW.amount;
    END IF;
    RETURN NEW;
END;
$$;


-- ── Debit borrower wallet when repayment paid ──────────────────────────────
-- Draws from non_lendable_borrowed first, then lendable_balance.
CREATE OR REPLACE FUNCTION trg_fn_debit_borrower_on_repayment()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_borrower_id   UUID;
    v_non_lendable  DECIMAL(15,2);
    v_from_borrowed DECIMAL(15,2);
    v_from_lendable DECIMAL(15,2);
BEGIN
    IF NEW.status = 'paid' AND OLD.status <> 'paid' THEN
        SELECT borrower_id INTO v_borrower_id
        FROM   loan_contracts WHERE contract_id = NEW.contract_id;

        SELECT non_lendable_borrowed INTO v_non_lendable
        FROM   wallet_balances WHERE user_id = v_borrower_id;

        v_from_borrowed := LEAST(COALESCE(v_non_lendable, 0), NEW.amount_paid);
        v_from_lendable := GREATEST(0, NEW.amount_paid - v_from_borrowed);

        UPDATE wallet_balances
        SET non_lendable_borrowed = non_lendable_borrowed - v_from_borrowed,
            lendable_balance      = lendable_balance      - v_from_lendable
        WHERE user_id = v_borrower_id;
    END IF;
    RETURN NEW;
END;
$$;


-- ── Release lender locked funds on repayment transaction completion ─────────
-- Returns principal + interest to lendable_balance.
CREATE OR REPLACE FUNCTION trg_fn_release_lender_funds()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.status = 'completed' THEN
        UPDATE wallet_balances
        SET lendable_balance = lendable_balance + NEW.amount,
            locked_repayment = GREATEST(0, locked_repayment - NEW.principal_amount)
        WHERE user_id = NEW.lender_id;
    END IF;
    RETURN NEW;
END;
$$;


-- ── Update contract status and balances after repayment change ─────────────
-- Marks contracts completed / defaulted / active.
-- default_threshold_days read from system_settings.
CREATE OR REPLACE FUNCTION trg_fn_update_contract_on_repayment()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_contract_id  UUID;
    v_total_due    DECIMAL(15,2);
    v_total_paid   DECIMAL(15,2);
    v_max_late     INT;
    v_threshold    INT;
    v_new_status   contract_status_enum;
BEGIN
    v_contract_id := CASE WHEN TG_OP = 'DELETE' THEN OLD.contract_id ELSE NEW.contract_id END;

    SELECT
        COALESCE(SUM(amount_due),  0),
        COALESCE(SUM(amount_paid), 0),
        COALESCE(MAX(days_late),   0)
    INTO v_total_due, v_total_paid, v_max_late
    FROM loan_repayments WHERE contract_id = v_contract_id;

    SELECT COALESCE(setting_value::INT, 90)
    INTO   v_threshold
    FROM   system_settings WHERE setting_key = 'default_threshold_days';

    v_new_status := CASE
        WHEN v_total_paid >= v_total_due THEN 'completed'::contract_status_enum
        WHEN v_max_late   >  v_threshold THEN 'defaulted'::contract_status_enum
        ELSE                                  'active'::contract_status_enum
    END;

    UPDATE loan_contracts
    SET status              = v_new_status,
        outstanding_balance = total_amount - v_total_paid,
        total_repaid        = v_total_paid,
        days_overdue        = v_max_late
    WHERE contract_id = v_contract_id;

    RETURN NEW;
END;
$$;


-- ── Auto-activate contract when all lenders sign ───────────────────────────
CREATE OR REPLACE FUNCTION trg_fn_check_all_lenders_signed()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_unsigned INT;
BEGIN
    IF NEW.lender_signed = TRUE AND OLD.lender_signed = FALSE THEN
        SELECT COUNT(*) INTO v_unsigned
        FROM   contract_bids
        WHERE  contract_id = NEW.contract_id AND lender_signed = FALSE;

        IF v_unsigned = 0 THEN
            UPDATE loan_contracts
            SET all_lenders_signed    = TRUE,
                contract_activated_at = CURRENT_TIMESTAMP
            WHERE contract_id = NEW.contract_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


-- ── Expire pending bids past their expires_at ─────────────────────────────
CREATE OR REPLACE FUNCTION trg_fn_expire_bid()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.expires_at IS NOT NULL
       AND NEW.expires_at < CURRENT_TIMESTAMP
       AND NEW.status = 'pending'
    THEN
        NEW.status := 'expired'::bid_status_enum;
    END IF;
    RETURN NEW;
END;
$$;


-- ── KYC gate: block loan creation without approval ─────────────────────────
CREATE OR REPLACE FUNCTION trg_fn_require_kyc_for_loan()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM kyc_verifications
        WHERE user_id = NEW.borrower_id AND status = 'approved'
    ) THEN
        RAISE EXCEPTION
            'KYC approval required before creating a loan request.';
    END IF;
    RETURN NEW;
END;
$$;


-- ── Active status gate: block loan creation ────────────────────────────────
CREATE OR REPLACE FUNCTION trg_fn_require_active_borrower()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM users
        WHERE user_id = NEW.borrower_id AND status <> 'active'
    ) THEN
        RAISE EXCEPTION
            'Account must be in active status to create a loan request.';
    END IF;
    RETURN NEW;
END;
$$;


-- ============================================
-- TRIGGERS
-- ============================================
-- PostgreSQL fires BEFORE triggers in alphabetical name order
-- within the same table + timing + event.
-- On users BEFORE UPDATE: trg_sync_reputation_tier fires first,
-- then trg_users_updated_at — correct: tier updated before stamp.

-- ── users ──────────────────────────────────────────────────────────────────
CREATE TRIGGER trg_auto_create_wallet
    AFTER INSERT ON users
    FOR EACH ROW EXECUTE FUNCTION trg_fn_auto_create_wallet();

CREATE TRIGGER trg_sync_reputation_tier          -- fires BEFORE trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION trg_fn_sync_reputation_tier();

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- ── user_profiles ──────────────────────────────────────────────────────────
CREATE TRIGGER trg_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- ── kyc_verifications ──────────────────────────────────────────────────────
CREATE TRIGGER trg_kyc_updated_at
    BEFORE UPDATE ON kyc_verifications
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- ── wallet_balances ────────────────────────────────────────────────────────
CREATE TRIGGER trg_wallet_updated_at
    BEFORE UPDATE ON wallet_balances
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- ── system_settings ────────────────────────────────────────────────────────
CREATE TRIGGER trg_system_settings_updated_at
    BEFORE UPDATE ON system_settings
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- ── loan_requests ──────────────────────────────────────────────────────────
CREATE TRIGGER trg_require_kyc_for_loan
    BEFORE INSERT ON loan_requests
    FOR EACH ROW EXECUTE FUNCTION trg_fn_require_kyc_for_loan();

CREATE TRIGGER trg_require_active_borrower
    BEFORE INSERT ON loan_requests
    FOR EACH ROW EXECUTE FUNCTION trg_fn_require_active_borrower();

CREATE TRIGGER trg_loan_requests_updated_at
    BEFORE UPDATE ON loan_requests
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- ── bids ───────────────────────────────────────────────────────────────────
-- BEFORE INSERT: expire check first, then wallet check
CREATE TRIGGER trg_expire_bid
    BEFORE INSERT OR UPDATE ON bids
    FOR EACH ROW EXECUTE FUNCTION trg_fn_expire_bid();

CREATE TRIGGER trg_enforce_lendable_on_bid        -- fires after trg_expire_bid (alphabetical)
    BEFORE INSERT ON bids
    FOR EACH ROW EXECUTE FUNCTION trg_fn_enforce_lendable_on_bid();

-- AFTER UPDATE: lock funds then update progress (both fire, order safe)
CREATE TRIGGER trg_lock_funds_on_accept
    AFTER UPDATE ON bids
    FOR EACH ROW EXECUTE FUNCTION trg_fn_lock_funds_on_accept();

CREATE TRIGGER trg_restore_funds_on_withdraw
    AFTER UPDATE ON bids
    FOR EACH ROW EXECUTE FUNCTION trg_fn_restore_funds_on_withdraw();

CREATE TRIGGER trg_update_funding_progress
    AFTER UPDATE ON bids
    FOR EACH ROW EXECUTE FUNCTION trg_fn_update_funding_progress();

CREATE TRIGGER trg_bids_updated_at
    BEFORE UPDATE ON bids
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- ── loan_contracts ─────────────────────────────────────────────────────────
CREATE TRIGGER trg_loan_contracts_updated_at
    BEFORE UPDATE ON loan_contracts
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- ── contract_bids ──────────────────────────────────────────────────────────
CREATE TRIGGER trg_check_all_lenders_signed
    AFTER UPDATE ON contract_bids
    FOR EACH ROW EXECUTE FUNCTION trg_fn_check_all_lenders_signed();

-- ── disbursements ──────────────────────────────────────────────────────────
CREATE TRIGGER trg_credit_borrower_on_disbursement
    AFTER UPDATE ON disbursements
    FOR EACH ROW EXECUTE FUNCTION trg_fn_credit_borrower_on_disbursement();

CREATE TRIGGER trg_disbursements_updated_at
    BEFORE UPDATE ON disbursements
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- ── loan_repayments ────────────────────────────────────────────────────────
CREATE TRIGGER trg_update_contract_on_repayment
    AFTER INSERT OR UPDATE OR DELETE ON loan_repayments
    FOR EACH ROW EXECUTE FUNCTION trg_fn_update_contract_on_repayment();

CREATE TRIGGER trg_debit_borrower_on_repayment
    AFTER UPDATE ON loan_repayments
    FOR EACH ROW EXECUTE FUNCTION trg_fn_debit_borrower_on_repayment();

CREATE TRIGGER trg_loan_repayments_updated_at
    BEFORE UPDATE ON loan_repayments
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- ── repayment_transactions ─────────────────────────────────────────────────
CREATE TRIGGER trg_release_lender_funds
    AFTER INSERT OR UPDATE ON repayment_transactions
    FOR EACH ROW EXECUTE FUNCTION trg_fn_release_lender_funds();

CREATE TRIGGER trg_repayment_transactions_updated_at
    BEFORE UPDATE ON repayment_transactions
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();


-- ============================================
-- DATABASE COMMENT
-- ============================================

DO $$
DECLARE db TEXT;
BEGIN
    SELECT current_database() INTO db;
    EXECUTE format(
        'COMMENT ON DATABASE %I IS %L',
        db,
        'OpenCapital v3.0 — Non-custodial peer-to-peer lending. Uganda.'
    );
END $$;


-- ============================================
-- DEPLOYMENT CHECKLIST
-- ============================================
--
-- Fresh install:
--   createdb opencapital
--   psql -U postgres -d opencapital -f schema.sql
--
-- Required before going to production:
--   1. SSL: set sslmode=require on all connections
--   2. App user:
--        CREATE USER opencapital_app WITH PASSWORD '...';
--        GRANT SELECT, INSERT, UPDATE, DELETE
--          ON ALL TABLES IN SCHEMA public TO opencapital_app;
--        GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO opencapital_app;
--        REVOKE DELETE ON audit_logs FROM opencapital_app; -- append-only
--   3. Connection pooling: PgBouncer in transaction mode
--   4. Backups: WAL archiving + daily base backup (pg_basebackup or managed snapshots)
--   5. Monitoring: pg_stat_statements, log_min_duration_statement = 500ms
--   6. Vacuuming: autovacuum tuned on audit_logs, bids, loan_repayments
--   7. Read replica for v_loan_performance + sp_generate_monthly_report queries
--   8. Partitioning consideration at scale:
--        audit_logs           → PARTITION BY RANGE (created_at) monthly
--        repayment_transactions → PARTITION BY RANGE (created_at) monthly
--   9. Row Level Security (RLS) if multi-tenant features added later