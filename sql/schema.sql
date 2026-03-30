-- ============================================
-- NIPANZE Database Schema
-- Version: 5.0 (Non-Custodial, Production-Ready)
-- PostgreSQL 14+ · Flutter + Supabase
--
-- Non-custodial peer-to-peer loan listing marketplace.
-- Uganda-first. Anonymity by default. No fund movement on-platform.
-- Platform NEVER holds, tracks, or processes money.
-- ============================================


-- ============================================
-- EXTENSIONS
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


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
    'employed', 'self_employed', 'business_owner', 'student', 'other'
);

CREATE TYPE subscription_plan_enum AS ENUM (
    'watchlist', 'borrower', 'lender', 'pro'
);

CREATE TYPE subscription_status_enum AS ENUM (
    'active', 'expired', 'cancelled', 'grace_period'
);

CREATE TYPE risk_category_enum AS ENUM (
    'low', 'medium', 'high'
);

CREATE TYPE loan_status_enum AS ENUM (
    'pending_kyc', 'active', 'contracted', 'expired', 'cancelled'
);

CREATE TYPE bid_status_enum AS ENUM (
    'pending', 'accepted', 'rejected', 'withdrawn', 'expired'
);

CREATE TYPE contract_status_enum AS ENUM (
    'draft', 'in_execution', 'completed', 'defaulted', 'disputed'
);

CREATE TYPE negotiator_status_enum AS ENUM (
    'available', 'busy', 'inactive'
);

CREATE TYPE reveal_status_enum AS ENUM (
    'pending', 'revealed'
);

CREATE TYPE notification_type_enum AS ENUM (
    'bid_received', 'bid_accepted', 'bid_rejected', 'bid_withdrawn',
    'negotiator_assigned', 'contract_draft_available',
    'kyc_approved', 'kyc_rejected',
    'closing_soon_24h', 'closing_soon_6h',
    'watchlist_new_bid', 'watchlist_rate_change',
    'contact_revealed', 'system'
);

CREATE TYPE audit_event_type_enum AS ENUM (
    'login', 'logout', 'register', 'password_reset',
    'token_refresh', 'token_reuse_detected',
    'login_failed', 'account_locked',
    'kyc_submitted', 'kyc_approved', 'kyc_rejected',
    'listing_created', 'listing_cancelled',
    'bid_placed', 'bid_withdrawn', 'bid_accepted',
    'contact_revealed', 'subscription_changed',
    'admin_action'
);

CREATE TYPE setting_type_enum AS ENUM (
    'string', 'number', 'boolean', 'json'
);


-- ============================================
-- AUTH BRIDGE
-- Syncs auth.users → public.profiles on registration.
-- Also creates a free watchlist subscription automatically.
-- NOTE: lender_token uses a temporary random value on insert.
--       The seed script nulls and re-sets all tokens explicitly
--       to avoid UNIQUE collisions from RANDOM().
-- ============================================

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (
        id, full_name, account_status, role,
        credit_score, reputation_tier
    )
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', SPLIT_PART(NEW.email, '@', 1)),
        'pending_verification',
        'user',
        50,
        'bronze'
    )
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.subscriptions (user_id, plan, status, amount_ugx)
    VALUES (NEW.id, 'watchlist', 'active', 0)
    ON CONFLICT DO NOTHING;

    RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_auth_user();

COMMENT ON FUNCTION public.handle_new_auth_user IS
'Syncs auth.users → public.profiles on every registration and provisions a free watchlist subscription.';


-- ============================================
-- TABLE: profiles  (extends auth.users 1-to-1)
-- ============================================

CREATE TABLE profiles (
    id                  UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

    full_name           TEXT,
    phone               TEXT UNIQUE,
    district            TEXT,
    employment_type     employment_type_enum,
    employer_name       TEXT,
    monthly_income_ugx  BIGINT,

    account_status      account_status_enum NOT NULL DEFAULT 'pending_verification',
    role                TEXT NOT NULL DEFAULT 'user'
                            CONSTRAINT chk_role CHECK (role IN ('user', 'admin', 'negotiator')),

    credit_score        INT NOT NULL DEFAULT 50
                            CONSTRAINT chk_credit_score CHECK (credit_score BETWEEN 0 AND 100),
    reputation_tier     TEXT NOT NULL DEFAULT 'bronze'
                            CONSTRAINT chk_reputation_tier
                            CHECK (reputation_tier IN ('platinum', 'gold', 'silver', 'bronze', 'restricted')),

    -- Stable anonymous token shown in the order book (e.g. L-#482). Never reveals identity.
    -- Default uses RANDOM(); seed script explicitly sets all tokens to avoid collisions.
    lender_token        TEXT UNIQUE NOT NULL
                            DEFAULT 'L-#' || FLOOR(RANDOM() * 9000 + 1000)::TEXT,

    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  profiles               IS 'Core user profile. Extends auth.users 1-to-1.';
COMMENT ON COLUMN profiles.credit_score  IS 'Internal 0-100 score. Never exposed raw to other users — only reputation_tier is public.';
COMMENT ON COLUMN profiles.lender_token  IS 'Stable anonymous token shown in the order book. Consistent per user, never reveals identity.';


-- ============================================
-- TABLE: system_settings  (key-value, admin-managed)
-- ============================================

CREATE TABLE system_settings (
    setting_id    UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    setting_key   VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    setting_type  setting_type_enum NOT NULL DEFAULT 'string',
    category      VARCHAR(50),
    description   TEXT,
    is_public     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE system_settings IS 'Platform configuration. All business limits read from here at runtime.';


-- ============================================
-- DEFAULT SYSTEM SETTINGS
-- ============================================

INSERT INTO system_settings (setting_key, setting_value, setting_type, category, description, is_public) VALUES
    ('min_loan_amount',         '100000',   'number',  'limits',      'Minimum loan amount in UGX',                           TRUE),
    ('max_loan_amount',         '50000000', 'number',  'limits',      'Maximum loan amount in UGX',                           TRUE),
    ('min_interest_rate',       '5',        'number',  'limits',      'Minimum interest rate %',                              TRUE),
    ('max_interest_rate',       '30',       'number',  'limits',      'Maximum interest rate %',                              TRUE),
    ('min_lender_investment',   '100000',   'number',  'limits',      'Minimum bid amount per lender in UGX',                 TRUE),
    ('max_concurrent_loans',    '3',        'number',  'limits',      'Maximum active loan listings per borrower',            TRUE),
    ('listing_duration_days',   '7',        'number',  'marketplace', 'Days a loan request stays listed before expiry',       TRUE),
    ('kyc_validity_months',     '12',       'number',  'compliance',  'Months until KYC expires and re-verification required',TRUE),
    ('platform_currency',       'UGX',      'string',  'general',     'Platform operating currency',                          TRUE),
    ('auto_logout_minutes',     '30',       'number',  'security',    'Idle session timeout in minutes',                      FALSE),
    ('access_token_minutes',    '15',       'number',  'security',    'Access JWT TTL in minutes',                            FALSE),
    ('refresh_token_days',      '7',        'number',  'security',    'Refresh token TTL in days',                            FALSE);


-- ============================================
-- TABLE: subscriptions
-- ============================================

CREATE TABLE subscriptions (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    plan        subscription_plan_enum   NOT NULL DEFAULT 'watchlist',
    status      subscription_status_enum NOT NULL DEFAULT 'active',

    started_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at  TIMESTAMP,
    amount_ugx  BIGINT NOT NULL DEFAULT 0,
    auto_renew  BOOLEAN NOT NULL DEFAULT TRUE,

    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  subscriptions IS 'One active subscription per user at any time. watchlist plan = free (amount_ugx = 0).';


-- ============================================
-- TABLE: kyc_verifications
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

COMMENT ON TABLE kyc_verifications IS 'KYC records. status=approved required before loan creation (DB trigger enforced).';


-- ============================================
-- TABLE: loan_requests  (borrower listings)
-- ============================================

CREATE TABLE loan_requests (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    borrower_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,

    title             TEXT NOT NULL,
    purpose           TEXT NOT NULL,
    requested_amount  BIGINT NOT NULL,
    duration_months   INT NOT NULL
                          CONSTRAINT chk_lr_duration CHECK (duration_months BETWEEN 1 AND 60),
    max_interest_rate NUMERIC(5,2) NOT NULL
                          CONSTRAINT chk_lr_rate CHECK (max_interest_rate BETWEEN 0 AND 100),

    district          TEXT NOT NULL,
    risk_category     risk_category_enum NOT NULL DEFAULT 'medium',

    -- Band range shown publicly (e.g. 'A+'). Raw credit_score from profiles is never exposed.
    credit_score_band TEXT NOT NULL DEFAULT 'B',

    -- bid count only — no monetary aggregates (non-custodial: platform never tracks fund totals)
    number_of_bids    INT NOT NULL DEFAULT 0,

    status            loan_status_enum NOT NULL DEFAULT 'active',

    listed_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at        TIMESTAMP,           -- set by trigger on insert
    contracted_at     TIMESTAMP,
    cancelled_at      TIMESTAMP,

    supporting_documents JSONB,
    views_count       INT NOT NULL DEFAULT 0,

    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_lr_amount_positive CHECK (requested_amount > 0)
);

COMMENT ON TABLE  loan_requests             IS 'Borrower funding requests. borrower_id masked on all public views and endpoints.';
COMMENT ON COLUMN loan_requests.borrower_id IS 'NEVER exposed in v_loan_listings or any marketplace query. Anonymity enforced at view level.';
COMMENT ON COLUMN loan_requests.number_of_bids IS 'Count of bids only. No monetary totals stored — platform is non-custodial.';


-- ============================================
-- TABLE: loan_bids  (lender offers on a listing)
-- ============================================

CREATE TABLE loan_bids (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id  UUID NOT NULL REFERENCES loan_requests(id) ON DELETE CASCADE,
    lender_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,

    amount        BIGINT NOT NULL
                      CONSTRAINT chk_lb_amount_positive CHECK (amount > 0),
    interest_rate NUMERIC(5,2) NOT NULL
                      CONSTRAINT chk_lb_rate CHECK (interest_rate BETWEEN 0 AND 100),

    status        bid_status_enum NOT NULL DEFAULT 'pending',
    auto_accept   BOOLEAN NOT NULL DEFAULT FALSE,

    placed_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    accepted_at   TIMESTAMP,
    withdrawn_at  TIMESTAMP,
    expires_at    TIMESTAMP,

    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- a lender can have only one active bid per listing
    UNIQUE (request_id, lender_id)
);

COMMENT ON COLUMN loan_bids.lender_id IS 'Internal FK. Lenders are shown as lender_token in the order book, never by lender_id.';
COMMENT ON COLUMN loan_bids.amount IS 'Proposed loan amount stated by lender. Platform never holds or moves this money.';


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
-- TABLE: negotiators  (vetted professionals assignable to matched deals)
-- ============================================

CREATE TABLE negotiators (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id      UUID REFERENCES profiles(id) ON DELETE SET NULL,

    full_name       TEXT NOT NULL,
    phone           TEXT NOT NULL,
    email           TEXT NOT NULL,
    credentials     TEXT,       -- e.g. 'Licensed Attorney · KCCA No. 00123'
    specialisation  TEXT,

    status          negotiator_status_enum NOT NULL DEFAULT 'available',
    deals_completed INT NOT NULL DEFAULT 0,
    avg_rating      NUMERIC(3,2),

    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- ============================================
-- TABLE: contracts
-- Records the agreed terms between matched parties.
-- Platform NEVER tracks balances, repayments, or fund movements.
-- All financial settlement happens directly between parties off-platform.
-- ============================================

CREATE TABLE contracts (
    id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id            UUID NOT NULL REFERENCES loan_requests(id) ON DELETE RESTRICT,
    bid_id                UUID NOT NULL REFERENCES loan_bids(id) ON DELETE RESTRICT,
    borrower_id           UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
    lender_id             UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
    negotiator_id         UUID REFERENCES negotiators(id) ON DELETE SET NULL,

    status                contract_status_enum NOT NULL DEFAULT 'draft',

    -- agreed terms (informational record only — no fund movement on platform)
    amount                BIGINT NOT NULL
                              CONSTRAINT chk_c_amount_positive CHECK (amount > 0),
    interest_rate         NUMERIC(5,2) NOT NULL
                              CONSTRAINT chk_c_rate CHECK (interest_rate BETWEEN 0 AND 100),
    duration_months       INT NOT NULL,
    purpose               TEXT NOT NULL,
    district              TEXT NOT NULL,

    -- indicative repayment schedule figures (for reference / PDF generation only)
    indicative_monthly_payment_ugx  BIGINT,
    indicative_total_repayment_ugx  BIGINT,
    indicative_total_interest_ugx   BIGINT,

    repayment_start_date  DATE,
    maturity_date         DATE,

    governing_law         TEXT NOT NULL DEFAULT 'Laws of Uganda',
    pdf_url               VARCHAR(500),    -- populated by Edge Function

    borrower_confirmed    BOOLEAN NOT NULL DEFAULT FALSE,
    borrower_confirmed_at TIMESTAMP,
    lender_confirmed      BOOLEAN NOT NULL DEFAULT FALSE,
    lender_confirmed_at   TIMESTAMP,
    contract_activated_at TIMESTAMP,

    created_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (request_id),   -- one contract per listing
    UNIQUE (bid_id)        -- one contract per accepted bid
);

COMMENT ON TABLE  contracts IS
'Records agreed loan terms. Informational only — platform never holds funds, tracks balances, or processes payments.
 All financial settlement is direct between borrower and lender off-platform.';


-- ============================================
-- TABLE: repayment_schedules
-- Indicative amortisation schedule for reference only.
-- Nipanze does NOT initiate, process, verify, or track payments.
-- ============================================

CREATE TABLE repayment_schedules (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contract_id       UUID NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,

    instalment_number INT NOT NULL CONSTRAINT chk_rs_instalment CHECK (instalment_number >= 1),
    due_date          DATE NOT NULL,

    principal_ugx     BIGINT NOT NULL CONSTRAINT chk_rs_principal CHECK (principal_ugx > 0),
    interest_ugx      BIGINT NOT NULL CONSTRAINT chk_rs_interest  CHECK (interest_ugx >= 0),
    total_ugx         BIGINT GENERATED ALWAYS AS (principal_ugx + interest_ugx) STORED,

    -- Participant-reported status only. Never verified or enforced by platform.
    reported_status   TEXT NOT NULL DEFAULT 'pending'
                          CONSTRAINT chk_rs_reported_status
                          CHECK (reported_status IN ('pending', 'reported_paid', 'reported_late', 'disputed')),
    reported_at       TIMESTAMP,
    reported_by       UUID REFERENCES profiles(id) ON DELETE SET NULL,

    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (contract_id, instalment_number)
);

COMMENT ON TABLE repayment_schedules IS
'Indicative amortisation schedule lines. Nipanze does not initiate, process, or verify payments.
 Status is participant-reported only. Non-custodial by design.';


-- ============================================
-- TABLE: negotiator_assignments  (join between contract and negotiator)
-- ============================================

CREATE TABLE negotiator_assignments (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contract_id     UUID NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    negotiator_id   UUID NOT NULL REFERENCES negotiators(id) ON DELETE RESTRICT,

    assigned_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at    TIMESTAMP,
    notes           TEXT,

    UNIQUE (contract_id)  -- one active negotiator per contract
);


-- ============================================
-- TABLE: negotiator_assessments  (feed into credit scoring)
-- ============================================

CREATE TABLE negotiator_assessments (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assignment_id       UUID NOT NULL REFERENCES negotiator_assignments(id) ON DELETE CASCADE,
    assessed_user_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    repayment_behaviour INT CONSTRAINT chk_na_repayment  CHECK (repayment_behaviour BETWEEN 1 AND 5),
    contract_adherence  INT CONSTRAINT chk_na_adherence  CHECK (contract_adherence  BETWEEN 1 AND 5),
    dispute_handling    INT CONSTRAINT chk_na_dispute    CHECK (dispute_handling    BETWEEN 1 AND 5),
    overall_rating      INT CONSTRAINT chk_na_overall    CHECK (overall_rating      BETWEEN 1 AND 5),

    notes               TEXT,
    submitted_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE negotiator_assessments IS
'Structured assessments from vetted negotiators. Feed directly into sp_calculate_reputation_score.
 Never shown raw to the assessed user — score effect only.';


-- ============================================
-- TABLE: contact_reveals  (opt-in identity disclosure post-acceptance)
-- ============================================

CREATE TABLE contact_reveals (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contract_id         UUID NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    revealed_by         UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,

    reveals_borrower    BOOLEAN NOT NULL DEFAULT FALSE,
    reveals_lender      BOOLEAN NOT NULL DEFAULT FALSE,
    reveals_negotiator  BOOLEAN NOT NULL DEFAULT FALSE,

    status              reveal_status_enum NOT NULL DEFAULT 'pending',
    revealed_at         TIMESTAMP,

    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- each party can reveal once per contract
    UNIQUE (contract_id, revealed_by)
);

COMMENT ON TABLE contact_reveals IS
'Opt-in identity disclosure after a bid is accepted.
 Irreversible once revealed. Platform never discloses identity outside this flow.
 No fee charged on-platform — non-custodial.';


-- ============================================
-- TABLE: credit_score_events  (audit trail for score changes)
-- ============================================

CREATE TABLE credit_score_events (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id           UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    score_before      INT NOT NULL,
    score_after       INT NOT NULL,
    delta             INT GENERATED ALWAYS AS (score_after - score_before) STORED,

    -- factor: 'participation', 'risk_accuracy', 'consistency', 'assessment'
    factor            TEXT NOT NULL,
    source            TEXT,   -- e.g. contract_id or assessment_id

    recalculated_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


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
    request_id  UUID REFERENCES loan_requests(id) ON DELETE SET NULL,
    contract_id UUID REFERENCES contracts(id)     ON DELETE SET NULL,
    bid_id      UUID REFERENCES loan_bids(id)     ON DELETE SET NULL,

    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- ============================================
-- TABLE: audit_logs  (append-only; DELETE/UPDATE blocked by RLS)
-- ============================================

CREATE TABLE audit_logs (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id        UUID REFERENCES profiles(id) ON DELETE SET NULL,

    event_type     audit_event_type_enum NOT NULL,
    entity_type    VARCHAR(50),
    entity_id      UUID,
    action         VARCHAR(100),
    description    TEXT,

    ip_address     INET,
    user_agent     TEXT,

    old_values     JSONB,
    new_values     JSONB,
    metadata       JSONB,

    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
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
 If a revoked token is seen again, token_reuse_detected is logged to audit_logs.';


-- ============================================
-- TABLE: api_keys  (Pro plan subscribers only)
-- ============================================

CREATE TABLE api_keys (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    key_hash     TEXT NOT NULL UNIQUE,  -- bcrypt hash; raw key shown once at creation
    label        TEXT,
    is_active    BOOLEAN NOT NULL DEFAULT TRUE,
    daily_limit  INT NOT NULL DEFAULT 1000,

    last_used_at TIMESTAMP,
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    revoked_at   TIMESTAMP
);


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
-- INDEXES
-- ============================================

-- profiles
CREATE INDEX idx_profiles_role           ON profiles (role);
CREATE INDEX idx_profiles_account_status ON profiles (account_status);
CREATE INDEX idx_profiles_lender_token   ON profiles (lender_token);
CREATE INDEX idx_profiles_credit_score   ON profiles (credit_score DESC);
CREATE INDEX idx_profiles_rep_tier       ON profiles (reputation_tier);

-- subscriptions
CREATE INDEX idx_sub_user_id    ON subscriptions (user_id);
CREATE INDEX idx_sub_plan       ON subscriptions (plan);
CREATE INDEX idx_sub_status     ON subscriptions (status);
CREATE UNIQUE INDEX uidx_sub_active_user ON subscriptions (user_id) WHERE status = 'active';

-- kyc_verifications
CREATE INDEX idx_kyc_user_id ON kyc_verifications (user_id);
CREATE INDEX idx_kyc_status  ON kyc_verifications (status);

-- loan_requests
CREATE INDEX idx_lr_borrower_id   ON loan_requests (borrower_id);
CREATE INDEX idx_lr_status        ON loan_requests (status);
CREATE INDEX idx_lr_risk_category ON loan_requests (risk_category);
CREATE INDEX idx_lr_expires_at    ON loan_requests (expires_at);
CREATE INDEX idx_lr_district      ON loan_requests (district);
CREATE INDEX idx_lr_status_exp    ON loan_requests (status, expires_at);
CREATE INDEX idx_lr_active        ON loan_requests (status) WHERE status = 'active';

-- loan_bids
CREATE INDEX idx_lb_request_id    ON loan_bids (request_id);
CREATE INDEX idx_lb_lender_id     ON loan_bids (lender_id);
CREATE INDEX idx_lb_status        ON loan_bids (status);
CREATE INDEX idx_lb_interest      ON loan_bids (interest_rate);
CREATE INDEX idx_lb_req_status    ON loan_bids (request_id, status);
CREATE INDEX idx_lb_lender_status ON loan_bids (lender_id, status, placed_at DESC);

-- watchlist
CREATE INDEX idx_wl_user_id    ON watchlist (user_id);
CREATE INDEX idx_wl_request_id ON watchlist (request_id);

-- contracts
CREATE INDEX idx_c_borrower_id   ON contracts (borrower_id);
CREATE INDEX idx_c_lender_id     ON contracts (lender_id);
CREATE INDEX idx_c_status        ON contracts (status);
CREATE INDEX idx_c_negotiator_id ON contracts (negotiator_id);
CREATE INDEX idx_c_active        ON contracts (status) WHERE status = 'in_execution';

-- repayment_schedules
CREATE INDEX idx_rs_contract_id  ON repayment_schedules (contract_id);
CREATE INDEX idx_rs_due_date     ON repayment_schedules (due_date);
CREATE INDEX idx_rs_reported     ON repayment_schedules (reported_status);

-- negotiator_assessments
CREATE INDEX idx_na_assessed_user ON negotiator_assessments (assessed_user_id);

-- credit_score_events
CREATE INDEX idx_cse_user_id      ON credit_score_events (user_id);
CREATE INDEX idx_cse_recalculated ON credit_score_events (recalculated_at DESC);

-- notifications
CREATE INDEX idx_notif_user_id   ON notifications (user_id);
CREATE INDEX idx_notif_user_read ON notifications (user_id, is_read);
CREATE INDEX idx_notif_created   ON notifications (created_at DESC);

-- audit_logs
CREATE INDEX idx_al_user_id    ON audit_logs (user_id);
CREATE INDEX idx_al_event_type ON audit_logs (event_type);
CREATE INDEX idx_al_entity     ON audit_logs (entity_type, entity_id);
CREATE INDEX idx_al_created    ON audit_logs (created_at DESC);
CREATE INDEX idx_al_ip         ON audit_logs (ip_address);

-- refresh_tokens
CREATE INDEX idx_rt_user_id ON refresh_tokens (user_id);
CREATE INDEX idx_rt_hash    ON refresh_tokens (token_hash);
CREATE INDEX idx_rt_expires ON refresh_tokens (expires_at);
CREATE INDEX idx_rt_active  ON refresh_tokens (user_id, expires_at) WHERE revoked = FALSE;

-- api_keys
CREATE INDEX idx_ak_user_id ON api_keys (user_id);


-- ============================================
-- VIEWS
-- ============================================

-- Anonymised marketplace view — borrower_id intentionally excluded
CREATE VIEW v_loan_listings AS
SELECT
    lr.id                                                               AS request_id,
    lr.title,
    lr.purpose,
    lr.district,
    lr.duration_months,
    lr.requested_amount,
    lr.max_interest_rate,
    lr.risk_category,
    lr.credit_score_band,
    lr.status,
    lr.listed_at,
    lr.expires_at,
    lr.number_of_bids,
    -- best (lowest) rate among pending bids
    MIN(lb.interest_rate) FILTER (WHERE lb.status = 'pending')         AS best_bid_rate,
    -- time remaining helpers
    GREATEST(lr.expires_at - NOW(), INTERVAL '0')                      AS time_remaining,
    (lr.expires_at < NOW() + INTERVAL '24 hours')                      AS closing_soon_24h,
    (lr.expires_at < NOW() + INTERVAL '6 hours')                       AS closing_soon_6h
FROM  loan_requests lr
LEFT  JOIN loan_bids lb ON lb.request_id = lr.id
WHERE lr.status = 'active'
GROUP BY lr.id;

COMMENT ON VIEW v_loan_listings IS
'Anonymised marketplace feed. borrower_id, raw credit_score, and monetary bid aggregates are never present.';


CREATE VIEW v_user_portfolio AS
SELECT
    p.id                                                                AS user_id,
    p.full_name,
    p.reputation_tier,
    p.credit_score,
    -- borrower side
    COUNT(DISTINCT lr.id) FILTER (
        WHERE lr.borrower_id = p.id AND lr.status = 'active'
    )                                                                   AS active_listings,
    COUNT(DISTINCT lr.id) FILTER (
        WHERE lr.borrower_id = p.id AND lr.status = 'contracted'
    )                                                                   AS contracted_as_borrower,
    -- lender side
    COUNT(DISTINCT lb.id) FILTER (
        WHERE lb.lender_id = p.id AND lb.status = 'pending'
    )                                                                   AS active_bids,
    COUNT(DISTINCT lb.id) FILTER (
        WHERE lb.lender_id = p.id AND lb.status = 'accepted'
    )                                                                   AS contracted_as_lender,
    -- subscription
    s.plan                                                              AS subscription_plan,
    s.status                                                            AS subscription_status,
    s.expires_at                                                        AS subscription_expires_at,
    -- kyc
    k.status                                                            AS kyc_status,
    k.expires_at                                                        AS kyc_expires_at
FROM  profiles          p
LEFT  JOIN subscriptions      s  ON s.user_id    = p.id AND s.status = 'active'
LEFT  JOIN kyc_verifications  k  ON k.user_id    = p.id
LEFT  JOIN loan_requests      lr ON lr.borrower_id = p.id
LEFT  JOIN loan_bids          lb ON lb.lender_id   = p.id
GROUP BY p.id, s.plan, s.status, s.expires_at, k.status, k.expires_at;


CREATE VIEW v_lender_bids AS
SELECT
    lb.lender_id,
    lb.id                                                               AS bid_id,
    lb.request_id,
    lr.title                                                            AS listing_title,
    lr.district,
    lr.duration_months,
    lr.risk_category,
    lb.amount                                                           AS bid_amount,
    lb.interest_rate                                                    AS bid_rate,
    lb.status                                                           AS bid_status,
    lb.placed_at,
    lb.accepted_at,
    c.id                                                                AS contract_id,
    c.status                                                            AS contract_status,
    c.repayment_start_date
FROM  loan_bids      lb
JOIN  loan_requests  lr ON lr.id    = lb.request_id
LEFT  JOIN contracts c  ON c.bid_id = lb.id;

COMMENT ON VIEW v_lender_bids IS
'Lender bid history with contract linkage. No monetary balance or repayment tracking — non-custodial.';


CREATE VIEW v_loan_performance AS
SELECT
    DATE_TRUNC('month', lr.listed_at)                                   AS month,
    COUNT(lr.id)                                                        AS total_listings,
    COUNT(lr.id) FILTER (WHERE lr.status = 'active')                   AS active_listings,
    COUNT(lr.id) FILTER (WHERE lr.status = 'contracted')               AS contracted_listings,
    COUNT(lr.id) FILTER (WHERE lr.status = 'expired')                  AS expired_listings,
    ROUND(AVG(lb.interest_rate) FILTER (
        WHERE lb.status IN ('pending', 'accepted')
    ), 2)                                                               AS avg_market_rate,
    ROUND(
        COUNT(DISTINCT lb.request_id) * 100.0
        / NULLIF(COUNT(lr.id), 0), 1
    )                                                                   AS match_rate_pct,
    (SELECT COUNT(*) FROM subscriptions
     WHERE status = 'active' AND plan != 'watchlist')                  AS active_paid_subscribers
FROM  loan_requests lr
LEFT  JOIN loan_bids lb ON lb.request_id = lr.id
GROUP BY DATE_TRUNC('month', lr.listed_at)
ORDER BY month DESC;

COMMENT ON VIEW v_loan_performance IS 'Admin analytics. No monetary aggregates — non-custodial.';


-- ============================================
-- FUNCTIONS (shared utilities)
-- ============================================

CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


CREATE OR REPLACE FUNCTION fn_score_to_tier(p_score INT)
RETURNS TEXT LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
    RETURN CASE
        WHEN p_score >= 85 THEN 'platinum'
        WHEN p_score >= 70 THEN 'gold'
        WHEN p_score >= 55 THEN 'silver'
        WHEN p_score >= 40 THEN 'bronze'
        ELSE                    'restricted'
    END;
END;
$$;

COMMENT ON FUNCTION fn_score_to_tier IS 'Maps credit_score 0-100 → reputation_tier label. IMMUTABLE.';


-- ============================================
-- TRIGGER FUNCTIONS
-- ============================================

-- Sync reputation_tier whenever credit_score changes
CREATE OR REPLACE FUNCTION trg_fn_sync_reputation_tier()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.credit_score IS DISTINCT FROM OLD.credit_score THEN
        NEW.reputation_tier := fn_score_to_tier(NEW.credit_score);
    END IF;
    RETURN NEW;
END;
$$;


-- Set expires_at on listing insert from system_settings
CREATE OR REPLACE FUNCTION trg_fn_set_listing_expiry()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_days INT;
BEGIN
    SELECT setting_value::INT INTO v_days
    FROM system_settings WHERE setting_key = 'listing_duration_days';
    NEW.expires_at := NOW() + (v_days || ' days')::INTERVAL;
    RETURN NEW;
END;
$$;


-- Block INSERT on loan_requests unless KYC is approved and not expired
CREATE OR REPLACE FUNCTION trg_fn_require_kyc_for_loan()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_kyc_status  kyc_status_enum;
    v_kyc_expires TIMESTAMP;
BEGIN
    SELECT status, expires_at
      INTO v_kyc_status, v_kyc_expires
      FROM kyc_verifications
     WHERE user_id = NEW.borrower_id;

    IF v_kyc_status IS NULL OR v_kyc_status != 'approved' THEN
        RAISE EXCEPTION 'NIPANZE_KYC_REQUIRED: KYC verification must be approved before listing.'
            USING ERRCODE = 'P0001';
    END IF;

    IF v_kyc_expires IS NOT NULL AND v_kyc_expires < NOW() THEN
        RAISE EXCEPTION 'NIPANZE_KYC_EXPIRED: Your KYC has expired. Please re-verify.'
            USING ERRCODE = 'P0002';
    END IF;

    RETURN NEW;
END;
$$;


-- Block listing creation if account is not active
CREATE OR REPLACE FUNCTION trg_fn_require_active_borrower()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM profiles WHERE id = NEW.borrower_id AND account_status != 'active'
    ) THEN
        RAISE EXCEPTION 'NIPANZE_ACCOUNT_INACTIVE: Your account must be active to post a listing.'
            USING ERRCODE = 'P0003';
    END IF;
    RETURN NEW;
END;
$$;


-- Block listing if no active borrower/pro subscription
CREATE OR REPLACE FUNCTION trg_fn_require_borrower_subscription()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_plan subscription_plan_enum;
BEGIN
    SELECT plan INTO v_plan
      FROM subscriptions
     WHERE user_id = NEW.borrower_id AND status = 'active';

    IF v_plan NOT IN ('borrower', 'pro') THEN
        RAISE EXCEPTION 'NIPANZE_SUBSCRIPTION_REQUIRED: A Borrower or Pro subscription is required to post a listing.'
            USING ERRCODE = 'P0004';
    END IF;
    RETURN NEW;
END;
$$;


-- Enforce max_concurrent_loans from system_settings
CREATE OR REPLACE FUNCTION trg_fn_max_concurrent_loans()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_active_count INT;
    v_max          INT;
    v_contracted   INT;
BEGIN
    SELECT setting_value::INT INTO v_max
    FROM system_settings WHERE setting_key = 'max_concurrent_loans';

    SELECT COUNT(*) INTO v_active_count
      FROM loan_requests
     WHERE borrower_id = NEW.borrower_id AND status = 'active';

    IF v_active_count >= v_max THEN
        RAISE EXCEPTION 'NIPANZE_MAX_LISTINGS: You have reached the maximum of % active listings.', v_max
            USING ERRCODE = 'P0005';
    END IF;

    SELECT COUNT(*) INTO v_contracted
      FROM loan_requests
     WHERE borrower_id = NEW.borrower_id AND status = 'contracted';

    IF v_contracted > 0 THEN
        RAISE EXCEPTION 'NIPANZE_CONTRACTED_ACTIVE: You cannot post a new listing while you have a contracted position.'
            USING ERRCODE = 'P0006';
    END IF;

    RETURN NEW;
END;
$$;


-- Validate a bid before insert
CREATE OR REPLACE FUNCTION trg_fn_validate_bid()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_listing       loan_requests%ROWTYPE;
    v_min_invest    BIGINT;
    v_plan          subscription_plan_enum;
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
        RAISE EXCEPTION 'NIPANZE_SELF_BID: You cannot bid on your own listing.'
            USING ERRCODE = 'P0012';
    END IF;

    IF NEW.interest_rate > v_listing.max_interest_rate THEN
        RAISE EXCEPTION 'NIPANZE_RATE_CEILING: Bid rate (%) cannot exceed the listing ceiling (%).',
            NEW.interest_rate, v_listing.max_interest_rate
            USING ERRCODE = 'P0013';
    END IF;

    SELECT setting_value::BIGINT INTO v_min_invest
    FROM system_settings WHERE setting_key = 'min_lender_investment';

    IF NEW.amount < v_min_invest THEN
        RAISE EXCEPTION 'NIPANZE_MIN_INVESTMENT: Bid amount must be at least UGX %.', v_min_invest
            USING ERRCODE = 'P0014';
    END IF;

    SELECT plan INTO v_plan
      FROM subscriptions
     WHERE user_id = NEW.lender_id AND status = 'active';

    IF v_plan NOT IN ('lender', 'pro') THEN
        RAISE EXCEPTION 'NIPANZE_LENDER_SUBSCRIPTION_REQUIRED: A Lender or Pro subscription is required to bid.'
            USING ERRCODE = 'P0015';
    END IF;

    RETURN NEW;
END;
$$;


-- Once a bid is accepted, lock it from further updates
CREATE OR REPLACE FUNCTION trg_fn_lock_accepted_bid()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.status = 'accepted' THEN
        RAISE EXCEPTION 'NIPANZE_BID_LOCKED: An accepted bid cannot be modified.'
            USING ERRCODE = 'P0016';
    END IF;
    RETURN NEW;
END;
$$;


-- Auto-expire a bid if expires_at has passed
CREATE OR REPLACE FUNCTION trg_fn_expire_bid()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.expires_at IS NOT NULL AND NEW.expires_at < CURRENT_TIMESTAMP AND NEW.status = 'pending' THEN
        NEW.status := 'expired'::bid_status_enum;
    END IF;
    RETURN NEW;
END;
$$;


-- Increment bid count on loan_requests when a bid is accepted
CREATE OR REPLACE FUNCTION trg_fn_increment_bid_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND NEW.status = 'accepted' AND OLD.status != 'accepted' THEN
        UPDATE loan_requests
           SET number_of_bids = number_of_bids + 1
         WHERE id = NEW.request_id;
    END IF;
    RETURN NEW;
END;
$$;


-- ============================================
-- TRIGGERS
-- ============================================

-- profiles
CREATE TRIGGER trg_sync_reputation_tier
    BEFORE UPDATE OF credit_score ON profiles
    FOR EACH ROW EXECUTE FUNCTION trg_fn_sync_reputation_tier();

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
CREATE TRIGGER trg_require_kyc_for_loan
    BEFORE INSERT ON loan_requests
    FOR EACH ROW EXECUTE FUNCTION trg_fn_require_kyc_for_loan();

CREATE TRIGGER trg_require_active_borrower
    BEFORE INSERT ON loan_requests
    FOR EACH ROW EXECUTE FUNCTION trg_fn_require_active_borrower();

CREATE TRIGGER trg_require_borrower_subscription
    BEFORE INSERT ON loan_requests
    FOR EACH ROW EXECUTE FUNCTION trg_fn_require_borrower_subscription();

CREATE TRIGGER trg_max_concurrent_loans
    BEFORE INSERT ON loan_requests
    FOR EACH ROW EXECUTE FUNCTION trg_fn_max_concurrent_loans();

CREATE TRIGGER trg_set_listing_expiry
    BEFORE INSERT ON loan_requests
    FOR EACH ROW EXECUTE FUNCTION trg_fn_set_listing_expiry();

CREATE TRIGGER trg_loan_requests_updated_at
    BEFORE UPDATE ON loan_requests
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- loan_bids
CREATE TRIGGER trg_expire_bid
    BEFORE INSERT OR UPDATE ON loan_bids
    FOR EACH ROW EXECUTE FUNCTION trg_fn_expire_bid();

CREATE TRIGGER trg_validate_bid
    BEFORE INSERT ON loan_bids
    FOR EACH ROW EXECUTE FUNCTION trg_fn_validate_bid();

CREATE TRIGGER trg_lock_accepted_bid
    BEFORE UPDATE ON loan_bids
    FOR EACH ROW
    WHEN (OLD.status = 'accepted')
    EXECUTE FUNCTION trg_fn_lock_accepted_bid();

CREATE TRIGGER trg_increment_bid_count
    AFTER UPDATE ON loan_bids
    FOR EACH ROW EXECUTE FUNCTION trg_fn_increment_bid_count();

CREATE TRIGGER trg_loan_bids_updated_at
    BEFORE UPDATE ON loan_bids
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- contracts
CREATE TRIGGER trg_contracts_updated_at
    BEFORE UPDATE ON contracts
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- repayment_schedules
CREATE TRIGGER trg_repayment_schedules_updated_at
    BEFORE UPDATE ON repayment_schedules
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- negotiators
CREATE TRIGGER trg_negotiators_updated_at
    BEFORE UPDATE ON negotiators
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();


-- ============================================
-- RPCs
-- ============================================

-- --------------------------------------------
-- accept_bid
-- Atomic: marks bid accepted, closes other bids,
-- sets listing to contracted, creates contract,
-- assigns negotiator, notifies both parties.
-- --------------------------------------------
CREATE OR REPLACE FUNCTION accept_bid(
    p_request_id  UUID,
    p_bid_id      UUID,
    p_borrower_id UUID
)
RETURNS UUID    -- returns contract_id
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_listing       loan_requests%ROWTYPE;
    v_bid           loan_bids%ROWTYPE;
    v_contract_id   UUID;
    v_rate_mo       NUMERIC(20,10);
    v_monthly_pmt   BIGINT;
    v_total_repay   BIGINT;
    v_total_int     BIGINT;
BEGIN
    SELECT * INTO v_listing FROM loan_requests WHERE id = p_request_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'NIPANZE_LISTING_NOT_FOUND' USING ERRCODE = 'P0020';
    END IF;
    IF v_listing.borrower_id != p_borrower_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Only the listing owner can accept a bid.' USING ERRCODE = 'P0021';
    END IF;
    IF v_listing.status != 'active' THEN
        RAISE EXCEPTION 'NIPANZE_LISTING_NOT_ACTIVE' USING ERRCODE = 'P0022';
    END IF;

    SELECT * INTO v_bid FROM loan_bids WHERE id = p_bid_id AND request_id = p_request_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'NIPANZE_BID_NOT_FOUND' USING ERRCODE = 'P0023';
    END IF;
    IF v_bid.status != 'pending' THEN
        RAISE EXCEPTION 'NIPANZE_BID_NOT_PENDING: This bid is no longer available.' USING ERRCODE = 'P0024';
    END IF;

    -- 1. Accept the chosen bid
    UPDATE loan_bids SET status = 'accepted', accepted_at = NOW() WHERE id = p_bid_id;

    -- 2. Reject all other pending bids on this listing
    UPDATE loan_bids SET status = 'rejected', updated_at = NOW()
     WHERE request_id = p_request_id AND id != p_bid_id AND status = 'pending';

    -- 3. Mark listing as contracted
    UPDATE loan_requests SET status = 'contracted', contracted_at = NOW() WHERE id = p_request_id;

    -- 4. Calculate indicative amortisation figures (for contract PDF reference only)
    v_rate_mo     := v_bid.interest_rate / 100.0 / 12.0;
    v_monthly_pmt := ROUND(
        v_bid.amount * (v_rate_mo * POWER(1 + v_rate_mo, v_listing.duration_months))
        / (POWER(1 + v_rate_mo, v_listing.duration_months) - 1)
    );
    v_total_repay := v_monthly_pmt * v_listing.duration_months;
    v_total_int   := v_total_repay - v_bid.amount;

    -- 5. Create draft contract (informational record — no fund movement)
    INSERT INTO contracts (
        request_id, bid_id, borrower_id, lender_id,
        amount, interest_rate, duration_months, purpose, district,
        indicative_monthly_payment_ugx,
        indicative_total_repayment_ugx,
        indicative_total_interest_ugx
    ) VALUES (
        p_request_id, p_bid_id, p_borrower_id, v_bid.lender_id,
        v_bid.amount, v_bid.interest_rate, v_listing.duration_months,
        v_listing.purpose, v_listing.district,
        v_monthly_pmt, v_total_repay, v_total_int
    )
    RETURNING id INTO v_contract_id;

    -- 6. Assign negotiator (non-blocking)
    BEGIN
        PERFORM sp_assign_negotiator(v_contract_id);
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO audit_logs (event_type, entity_type, entity_id, action, description)
        VALUES ('admin_action', 'contract', v_contract_id, 'negotiator_assignment_failed',
                'Auto-assignment failed. Manual assignment required.');
    END;

    -- 7. Notify both parties
    INSERT INTO notifications (user_id, type, title, body, request_id, contract_id, bid_id)
    VALUES
        (p_borrower_id, 'bid_accepted',
         'Bid accepted', 'Your listing has been matched. A negotiator has been assigned.',
         p_request_id, v_contract_id, p_bid_id),
        (v_bid.lender_id, 'bid_accepted',
         'Your bid was accepted', 'Your offer has been accepted. A negotiator will be in touch.',
         p_request_id, v_contract_id, p_bid_id);

    -- 8. Audit
    INSERT INTO audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
    VALUES (p_borrower_id, 'bid_accepted', 'contract', v_contract_id, 'accept_bid',
            JSONB_BUILD_OBJECT(
                'request_id',  p_request_id,
                'bid_id',      p_bid_id,
                'contract_id', v_contract_id,
                'lender_id',   v_bid.lender_id
            ));

    RETURN v_contract_id;
END;
$$;

COMMENT ON FUNCTION accept_bid IS
'Atomically accepts a bid, rejects others, creates contract with indicative amortisation figures.
 Returns contract_id. Platform never holds or moves funds.';


-- --------------------------------------------
-- sp_assign_negotiator
-- --------------------------------------------
CREATE OR REPLACE FUNCTION sp_assign_negotiator(p_contract_id UUID)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_negotiator_id UUID;
BEGIN
    SELECT n.id INTO v_negotiator_id
      FROM negotiators n
     WHERE n.status = 'available'
       AND n.id NOT IN (
           SELECT na.negotiator_id
             FROM negotiator_assignments na
             JOIN contracts c ON c.id = na.contract_id
            WHERE c.status IN ('draft', 'in_execution')
       )
     ORDER BY n.deals_completed ASC, RANDOM()
     LIMIT 1;

    IF v_negotiator_id IS NULL THEN
        SELECT na2.negotiator_id INTO v_negotiator_id
          FROM negotiator_assignments na2
          JOIN contracts c2 ON c2.id = na2.contract_id
         WHERE c2.status IN ('draft', 'in_execution')
         GROUP BY na2.negotiator_id
         ORDER BY COUNT(*) ASC
         LIMIT 1;
    END IF;

    IF v_negotiator_id IS NULL THEN
        RAISE EXCEPTION 'NIPANZE_NO_NEGOTIATOR: No negotiators are available.' USING ERRCODE = 'P0030';
    END IF;

    INSERT INTO negotiator_assignments (contract_id, negotiator_id)
    VALUES (p_contract_id, v_negotiator_id);

    UPDATE contracts SET negotiator_id = v_negotiator_id WHERE id = p_contract_id;

    INSERT INTO notifications (user_id, type, title, body, contract_id)
    SELECT c.borrower_id, 'negotiator_assigned',
           'Negotiator assigned', 'A negotiator has been assigned to facilitate your deal.',
           p_contract_id
      FROM contracts c WHERE c.id = p_contract_id;

    INSERT INTO notifications (user_id, type, title, body, contract_id)
    SELECT c.lender_id, 'negotiator_assigned',
           'Negotiator assigned', 'A negotiator has been assigned to facilitate your deal.',
           p_contract_id
      FROM contracts c WHERE c.id = p_contract_id;

    RETURN v_negotiator_id;
END;
$$;


-- --------------------------------------------
-- sp_generate_repayment_schedule
-- Generates indicative amortisation schedule lines.
-- For reference / PDF use only. Not for payment tracking.
-- --------------------------------------------
CREATE OR REPLACE FUNCTION sp_generate_repayment_schedule(p_contract_id UUID)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    v_amount        BIGINT;
    v_rate          NUMERIC(5,2);
    v_months        INT;
    v_start         DATE;
    v_monthly_pmt   BIGINT;
    v_remaining     BIGINT;
    v_interest_pmt  BIGINT;
    v_principal_pmt BIGINT;
    v_due           DATE;
    i               INT := 1;
BEGIN
    SELECT amount, interest_rate, duration_months,
           COALESCE(contract_activated_at::DATE, CURRENT_DATE)
      INTO v_amount, v_rate, v_months, v_start
      FROM contracts WHERE id = p_contract_id;

    IF v_amount IS NULL THEN
        RAISE EXCEPTION 'Contract % not found.', p_contract_id;
    END IF;

    v_monthly_pmt := ROUND(
        v_amount * ((v_rate/100/12) * POWER(1 + v_rate/100/12, v_months))
        / (POWER(1 + v_rate/100/12, v_months) - 1)
    );

    v_remaining := v_amount;
    v_due       := v_start;

    WHILE i <= v_months LOOP
        v_due           := v_due + INTERVAL '1 month';
        v_interest_pmt  := ROUND(v_remaining * v_rate / 100 / 12);
        v_principal_pmt := v_monthly_pmt - v_interest_pmt;

        IF i = v_months THEN
            v_principal_pmt := v_remaining;
            v_monthly_pmt   := v_principal_pmt + v_interest_pmt;
        END IF;

        INSERT INTO repayment_schedules
            (contract_id, instalment_number, due_date, principal_ugx, interest_ugx)
        VALUES
            (p_contract_id, i, v_due, v_principal_pmt, v_interest_pmt);

        v_remaining := v_remaining - v_principal_pmt;
        i := i + 1;
    END LOOP;
END;
$$;

COMMENT ON FUNCTION sp_generate_repayment_schedule IS
'Generates indicative amortisation schedule for reference / PDF only.
 Call ONCE after contract activation. Platform does not track payments.';


-- --------------------------------------------
-- sp_calculate_reputation_score
-- Weighted 0-100 score based on participation and negotiator assessments.
-- Repayment component is based solely on negotiator assessment data,
-- not platform-tracked payment events (non-custodial).
-- --------------------------------------------
CREATE OR REPLACE FUNCTION sp_calculate_reputation_score(p_user_id UUID)
RETURNS INT LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_old_score           INT;
    v_new_score           INT;
    v_participation       NUMERIC := 50;
    v_consistency         NUMERIC := 50;
    v_assessment_score    NUMERIC := 50;
    v_completed_contracts INT;
    v_withdrawn_bids      INT;
    v_total_bids          INT;
BEGIN
    SELECT credit_score INTO v_old_score FROM profiles WHERE id = p_user_id;

    -- Component 1: Participation history (40%)
    SELECT COUNT(*) FILTER (WHERE c.status = 'completed')
      INTO v_completed_contracts
      FROM contracts c
     WHERE c.borrower_id = p_user_id
        OR c.lender_id   = p_user_id;

    v_participation := LEAST(100, v_completed_contracts * 10 + 50);

    -- Component 2: Consistency — bid withdrawal rate as lender (30%)
    SELECT COUNT(*) FILTER (WHERE lb.status = 'withdrawn'),
           COUNT(*)
      INTO v_withdrawn_bids, v_total_bids
      FROM loan_bids lb
     WHERE lb.lender_id = p_user_id;

    IF v_total_bids > 0 THEN
        v_consistency := GREATEST(0, 100 - (100.0 * v_withdrawn_bids / v_total_bids));
    END IF;

    -- Component 3: Negotiator assessments (30%)
    SELECT COALESCE(
        AVG((na.repayment_behaviour + na.contract_adherence + na.dispute_handling + na.overall_rating) / 4.0) * 20,
        50
    ) INTO v_assessment_score
      FROM negotiator_assessments na
     WHERE na.assessed_user_id = p_user_id;

    -- Weighted total
    v_new_score := GREATEST(0, LEAST(100, ROUND(
        v_participation  * 0.40 +
        v_consistency    * 0.30 +
        v_assessment_score * 0.30
    )::INT));

    IF v_new_score != v_old_score THEN
        INSERT INTO credit_score_events
            (user_id, score_before, score_after, factor, source)
        VALUES
            (p_user_id, v_old_score, v_new_score, 'full_recalculation', 'sp_calculate_reputation_score');

        UPDATE profiles SET credit_score = v_new_score WHERE id = p_user_id;
    END IF;

    RETURN v_new_score;
END;
$$;

COMMENT ON FUNCTION sp_calculate_reputation_score IS
'Weighted reputation score 0-100 based on participation, consistency, and negotiator assessments.
 No repayment-tracking component — non-custodial by design.';


-- ============================================
-- ROW-LEVEL SECURITY
-- ============================================

ALTER TABLE system_settings        ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles               ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions          ENABLE ROW LEVEL SECURITY;
ALTER TABLE kyc_verifications      ENABLE ROW LEVEL SECURITY;
ALTER TABLE loan_requests          ENABLE ROW LEVEL SECURITY;
ALTER TABLE loan_bids              ENABLE ROW LEVEL SECURITY;
ALTER TABLE watchlist              ENABLE ROW LEVEL SECURITY;
ALTER TABLE contracts              ENABLE ROW LEVEL SECURITY;
ALTER TABLE repayment_schedules    ENABLE ROW LEVEL SECURITY;
ALTER TABLE negotiators            ENABLE ROW LEVEL SECURITY;
ALTER TABLE negotiator_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE negotiator_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_reveals        ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_score_events    ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications          ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs             ENABLE ROW LEVEL SECURITY;
ALTER TABLE refresh_tokens         ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_keys               ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals              ENABLE ROW LEVEL SECURITY;


CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN LANGUAGE SQL SECURITY DEFINER STABLE AS $$
    SELECT EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
    );
$$;


-- system_settings
CREATE POLICY "system_settings: authenticated read"
    ON system_settings FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "system_settings: admin write"
    ON system_settings FOR UPDATE TO authenticated USING (is_admin());

-- profiles
CREATE POLICY "profiles: own row"
    ON profiles FOR SELECT TO authenticated
    USING (id = auth.uid() OR is_admin());
CREATE POLICY "profiles: own update"
    ON profiles FOR UPDATE TO authenticated
    USING (id = auth.uid()) WITH CHECK (id = auth.uid());
CREATE POLICY "profiles: admin all"
    ON profiles FOR ALL TO authenticated USING (is_admin());

-- subscriptions
CREATE POLICY "subscriptions: own row"
    ON subscriptions FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR is_admin());
CREATE POLICY "subscriptions: admin write"
    ON subscriptions FOR ALL TO authenticated USING (is_admin());

-- kyc_verifications
CREATE POLICY "kyc: own row"
    ON kyc_verifications FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR is_admin());
CREATE POLICY "kyc: own insert"
    ON kyc_verifications FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());
CREATE POLICY "kyc: own or admin update"
    ON kyc_verifications FOR UPDATE TO authenticated
    USING (user_id = auth.uid() OR is_admin());

-- loan_requests
CREATE POLICY "loan_requests: marketplace select"
    ON loan_requests FOR SELECT TO authenticated
    USING (status = 'active' OR borrower_id = auth.uid() OR is_admin());
CREATE POLICY "loan_requests: own insert"
    ON loan_requests FOR INSERT TO authenticated
    WITH CHECK (borrower_id = auth.uid());
CREATE POLICY "loan_requests: own update"
    ON loan_requests FOR UPDATE TO authenticated
    USING (borrower_id = auth.uid() OR is_admin());
CREATE POLICY "loan_requests: admin delete"
    ON loan_requests FOR DELETE TO authenticated USING (is_admin());

-- loan_bids
CREATE POLICY "loan_bids: lender own bids"
    ON loan_bids FOR SELECT TO authenticated
    USING (
        lender_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM loan_requests lr
             WHERE lr.id = loan_bids.request_id AND lr.borrower_id = auth.uid()
        )
        OR is_admin()
    );
CREATE POLICY "loan_bids: lender insert"
    ON loan_bids FOR INSERT TO authenticated
    WITH CHECK (lender_id = auth.uid());
CREATE POLICY "loan_bids: lender withdraw"
    ON loan_bids FOR UPDATE TO authenticated
    USING (
        (lender_id = auth.uid() AND status = 'pending')
        OR is_admin()
    );

-- watchlist
CREATE POLICY "watchlist: own rows"
    ON watchlist FOR ALL TO authenticated
    USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- contracts
CREATE POLICY "contracts: matched parties"
    ON contracts FOR SELECT TO authenticated
    USING (borrower_id = auth.uid() OR lender_id = auth.uid() OR is_admin());
CREATE POLICY "contracts: matched parties update"
    ON contracts FOR UPDATE TO authenticated
    USING (borrower_id = auth.uid() OR lender_id = auth.uid() OR is_admin());

-- repayment_schedules
CREATE POLICY "repayment_schedules: matched parties"
    ON repayment_schedules FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM contracts c
             WHERE c.id = repayment_schedules.contract_id
               AND (c.borrower_id = auth.uid() OR c.lender_id = auth.uid())
        )
        OR is_admin()
    );
CREATE POLICY "repayment_schedules: participants update"
    ON repayment_schedules FOR UPDATE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM contracts c
             WHERE c.id = repayment_schedules.contract_id
               AND (c.borrower_id = auth.uid() OR c.lender_id = auth.uid())
        )
        OR is_admin()
    );
CREATE POLICY "repayment_schedules: admin write"
    ON repayment_schedules FOR ALL TO authenticated USING (is_admin());

-- negotiators
CREATE POLICY "negotiators: authenticated read"
    ON negotiators FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "negotiators: admin write"
    ON negotiators FOR ALL TO authenticated USING (is_admin());

-- negotiator_assignments
CREATE POLICY "negotiator_assignments: matched parties"
    ON negotiator_assignments FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM contracts c
             WHERE c.id = negotiator_assignments.contract_id
               AND (c.borrower_id = auth.uid() OR c.lender_id = auth.uid())
        )
        OR is_admin()
    );
CREATE POLICY "negotiator_assignments: admin write"
    ON negotiator_assignments FOR ALL TO authenticated USING (is_admin());

-- negotiator_assessments
CREATE POLICY "negotiator_assessments: own row"
    ON negotiator_assessments FOR SELECT TO authenticated
    USING (assessed_user_id = auth.uid() OR is_admin());
CREATE POLICY "negotiator_assessments: admin write"
    ON negotiator_assessments FOR ALL TO authenticated USING (is_admin());

-- contact_reveals
CREATE POLICY "contact_reveals: own rows"
    ON contact_reveals FOR SELECT TO authenticated
    USING (revealed_by = auth.uid() OR is_admin());
CREATE POLICY "contact_reveals: own insert"
    ON contact_reveals FOR INSERT TO authenticated
    WITH CHECK (revealed_by = auth.uid());
CREATE POLICY "contact_reveals: admin write"
    ON contact_reveals FOR ALL TO authenticated USING (is_admin());

-- credit_score_events
CREATE POLICY "credit_score_events: own rows"
    ON credit_score_events FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR is_admin());

-- notifications
CREATE POLICY "notifications: own rows"
    ON notifications FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "notifications: own mark read"
    ON notifications FOR UPDATE TO authenticated
    USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "notifications: admin write"
    ON notifications FOR ALL TO authenticated USING (is_admin());

-- audit_logs
CREATE POLICY "audit_logs: own read"
    ON audit_logs FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR is_admin());
CREATE POLICY "audit_logs: insert only"
    ON audit_logs FOR INSERT TO authenticated WITH CHECK (TRUE);
CREATE POLICY "audit_logs: no update"
    ON audit_logs FOR UPDATE TO authenticated USING (FALSE);
CREATE POLICY "audit_logs: no delete"
    ON audit_logs FOR DELETE TO authenticated USING (FALSE);

-- refresh_tokens
CREATE POLICY "refresh_tokens: own rows"
    ON refresh_tokens FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR is_admin());
CREATE POLICY "refresh_tokens: own insert"
    ON refresh_tokens FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "refresh_tokens: own update"
    ON refresh_tokens FOR UPDATE TO authenticated USING (user_id = auth.uid());

-- api_keys
CREATE POLICY "api_keys: own rows"
    ON api_keys FOR SELECT TO authenticated
    USING (user_id = auth.uid() OR is_admin());
CREATE POLICY "api_keys: own write"
    ON api_keys FOR ALL TO authenticated
    USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- referrals
CREATE POLICY "referrals: own rows"
    ON referrals FOR SELECT TO authenticated
    USING (referrer_id = auth.uid() OR is_admin());
CREATE POLICY "referrals: own insert"
    ON referrals FOR INSERT TO authenticated WITH CHECK (referrer_id = auth.uid());
CREATE POLICY "referrals: admin write"
    ON referrals FOR ALL TO authenticated USING (is_admin());


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
ALTER PUBLICATION supabase_realtime ADD TABLE loan_bids;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE contracts;


-- ============================================
-- DATABASE COMMENT
-- ============================================

DO $$
DECLARE db TEXT;
BEGIN
    SELECT current_database() INTO db;
    EXECUTE FORMAT('COMMENT ON DATABASE %I IS %L', db,
        'Nipanze v5.0 — Non-custodial loan listing marketplace. Uganda-first. Anonymity by default. Platform never holds or tracks funds.');
END $$;


-- ============================================
-- STORAGE BUCKETS
-- ============================================
-- Create via Supabase CLI or dashboard:
--   supabase storage create kyc-documents --public=false
--   supabase storage create contracts     --public=false

-- ============================================
-- END OF SCHEMA v5.0
-- ============================================