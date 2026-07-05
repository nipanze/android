-- ============================================
-- NIPANZE Database Schema
-- Version: 4.0 (Non-Custodial Matchmaking Marketplace)
-- PostgreSQL 14+ · Flutter + Supabase
--
-- Non-custodial peer-to-peer loan listing marketplace.
-- Uganda-first. Borrowing is free. Lender offers require a subscription.
-- Platform NEVER holds, tracks, or processes money.
-- Contact details are revealed only after a borrower accepts an offer.
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
    'agreement_generated',
    'agreement_accepted',
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
    'agreement_generated', 'agreement_borrower_agreed', 'agreement_lender_agreed', 'agreement_locked',
    'contact_revealed',
    'subscription_changed',
    'admin_action'
);

CREATE TYPE setting_type_enum AS ENUM (
    'string', 'number', 'boolean', 'json'
);


-- ============================================
-- AUTH BRIDGE
-- Syncs auth.users → public.profiles on registration.
-- Also creates a free subscription automatically.
-- ============================================

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (
        id, full_name, account_status, role
    )
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', SPLIT_PART(NEW.email, '@', 1)),
        'pending_verification',
        'user'
    )
    ON CONFLICT (id) DO NOTHING;

    -- Every new user gets a free subscription (can browse marketplace and post requests)
    INSERT INTO public.subscriptions (user_id, plan, status, amount_ugx)
    VALUES (NEW.id, 'free', 'active', 0)
    ON CONFLICT DO NOTHING;

    RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_auth_user();

COMMENT ON FUNCTION public.handle_new_auth_user IS
'Syncs auth.users → public.profiles on every registration and provisions a free subscription.
 Free plan allows marketplace browsing and posting loan requests at no cost.';


-- ============================================
-- TABLE: profiles  (extends auth.users 1-to-1)
-- ============================================

CREATE TABLE profiles (
    id               UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

    full_name        TEXT,
    phone            TEXT UNIQUE,
    district         TEXT,
    employment_type  employment_type_enum,
    employer_name    TEXT,
    monthly_income_ugx BIGINT,

    account_status   account_status_enum NOT NULL DEFAULT 'pending_verification',
    role             TEXT NOT NULL DEFAULT 'user'
                         CONSTRAINT chk_role CHECK (role IN ('user', 'admin')),

    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  profiles IS 'Core user profile. Extends auth.users 1-to-1. One account supports both borrower and lender activity.';
COMMENT ON COLUMN profiles.phone IS 'Masked until contact reveal is triggered post-offer-acceptance.';


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
    ('min_loan_amount',         '100000',   'number',  'limits',      'Minimum loan request amount in UGX',                   TRUE),
    ('max_loan_amount',         '50000000', 'number',  'limits',      'Maximum loan request amount in UGX',                   TRUE),
    ('min_offer_amount',        '100000',   'number',  'limits',      'Minimum offer amount per lender in UGX',               TRUE),
    ('max_concurrent_requests', '3',        'number',  'limits',      'Maximum active loan requests per borrower',             TRUE),
    ('listing_duration_days',   '7',        'number',  'marketplace', 'Days a loan request stays listed before expiry',       TRUE),
    ('kyc_validity_months',     '12',       'number',  'compliance',  'Months until KYC expires and re-verification required', TRUE),
    ('platform_currency',       'UGX',      'string',  'general',     'Platform operating currency',                          TRUE),
    ('auto_logout_minutes',     '30',       'number',  'security',    'Idle session timeout in minutes',                      FALSE),
    ('access_token_minutes',    '15',       'number',  'security',    'Access JWT TTL in minutes',                            FALSE),
    ('refresh_token_days',      '7',        'number',  'security',    'Refresh token TTL in days',                            FALSE);


-- ============================================
-- TABLE: subscriptions
-- Free plan → browse + post requests (no cost).
-- Lender plan → make offers (paid subscription required).
-- ============================================

CREATE TABLE subscriptions (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    plan        subscription_plan_enum   NOT NULL DEFAULT 'free',
    status      subscription_status_enum NOT NULL DEFAULT 'active',

    started_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at  TIMESTAMP,
    amount_ugx  BIGINT NOT NULL DEFAULT 0,
    auto_renew  BOOLEAN NOT NULL DEFAULT TRUE,

    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  subscriptions IS
'One active subscription per user. free = no cost, browse and post requests.
 lender or pro plan required to make offers.';

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
 Not required to post a loan request — borrowing is free and open.';


-- ============================================
-- TABLE: loan_requests  (borrower listings)
-- Borrowers post structured funding requests for free.
-- Contact details are never exposed until an offer is accepted.
-- ============================================

CREATE TABLE loan_requests (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    borrower_id                 UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,

    title                       TEXT NOT NULL,
    purpose                     TEXT NOT NULL,
    requested_amount            BIGINT NOT NULL CONSTRAINT chk_lr_amount_positive CHECK (requested_amount > 0),
    duration_months             INT NOT NULL
                                    CONSTRAINT chk_lr_duration CHECK (duration_months BETWEEN 1 AND 60),

    -- Borrower's income context. Stored for request review, but not exposed
    -- through the public marketplace listing view.
    income_source               TEXT NOT NULL,          -- e.g. 'Monthly salary from Kampala City Council'
    preferred_repayment_plan    TEXT NOT NULL,          -- e.g. 'Monthly instalments'
    repayment_amount_per_period BIGINT NOT NULL         -- e.g. 200000 UGX per month
                                    CONSTRAINT chk_lr_repayment_positive CHECK (repayment_amount_per_period > 0),
    repayment_timeline          TEXT NOT NULL,          -- e.g. '4 months starting March 2026'

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
 Income and repayment fields give lenders enough context to make an informed offer.';
COMMENT ON COLUMN loan_requests.borrower_id IS
'NEVER exposed in v_loan_listings or any marketplace query. Contact revealed only post-acceptance.';
COMMENT ON COLUMN loan_requests.number_of_offers IS
'Count of offers only. No monetary totals stored — platform is non-custodial.';


-- ============================================
-- TABLE: loan_offers  (lender offers on a borrower request)
-- Lenders must have an active lender/pro subscription to make offers.
-- Lender identity is hidden from the borrower until the offer is accepted.
-- ============================================

CREATE TABLE loan_offers (
    id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id           UUID NOT NULL REFERENCES loan_requests(id) ON DELETE CASCADE,
    lender_id            UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,

    offer_amount         BIGINT NOT NULL CONSTRAINT chk_lo_amount_positive CHECK (offer_amount > 0),
    proposed_expectations TEXT,   -- optional: lender's proposed terms or expectations

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
'Internal FK. Lender identity hidden from borrower until the offer is accepted.';
COMMENT ON COLUMN loan_offers.offer_amount IS
'Proposed lending amount stated by lender. Platform never holds or moves this money.';


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
-- Platform never discloses identity outside this flow.
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
 Platform never discloses identity outside this flow. No fee charged — non-custodial.';


-- ============================================
-- TABLE: agreements
-- Structured loan agreement template + confirmation workflow.
-- Auto-generated after offer acceptance.
-- Both parties must agree before contact reveal.
-- Locked (read-only) after mutual confirmation.
-- ============================================

CREATE TABLE agreements (
    id                          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    offer_id                    UUID NOT NULL UNIQUE REFERENCES loan_offers(id) ON DELETE CASCADE,
    request_id                  UUID NOT NULL REFERENCES loan_requests(id) ON DELETE CASCADE,

    -- Repayment terms (editable before both parties lock)
    repayment_frequency         repayment_frequency_enum NOT NULL,
    repayment_amount            BIGINT NOT NULL CONSTRAINT chk_agr_repayment_positive CHECK (repayment_amount > 0),
    late_payment_penalty_pct    NUMERIC(5,2) NOT NULL DEFAULT 0 CONSTRAINT chk_agr_penalty_range CHECK (late_payment_penalty_pct >= 0 AND late_payment_penalty_pct <= 100),

    -- Agreement text + snapshot (for audit trail)
    agreement_text              TEXT NOT NULL,
    agreement_snapshot          JSONB,  -- Full snapshot at lock time for immutability

    -- Confirmation tracking
    status                      agreement_status_enum NOT NULL DEFAULT 'pending',
    borrower_agreed_at          TIMESTAMP,
    lender_agreed_at            TIMESTAMP,
    locked_at                   TIMESTAMP,

    created_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- only one agreement per accepted offer
    UNIQUE (offer_id)
);

COMMENT ON TABLE agreements IS
'Loan agreement template & confirmation workflow. Auto-generated after offer acceptance.
 Both borrower and lender must agree before the agreement locks and contact details can be revealed.
 Late payment penalty applies only to missed installments, not the total loan.
 Agreement becomes read-only (snapshot captured) after both parties confirm.
 All agreement events are logged in audit_logs for traceability.';

-- Indexes  
CREATE INDEX idx_agr_offer_id    ON agreements (offer_id);
CREATE INDEX idx_agr_request_id  ON agreements (request_id);
CREATE INDEX idx_agr_status      ON agreements (status);

-- Auto-trigger updated_at
CREATE TRIGGER trg_agreements_updated_at
    BEFORE UPDATE ON agreements
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();


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
-- INDEXES
-- ============================================

-- profiles
CREATE INDEX idx_profiles_role           ON profiles (role);
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
-- VIEWS
-- ============================================

-- --------------------------------------------
-- v_loan_listings
-- Anonymised public marketplace feed.
-- borrower_id, phone, email, full_name, and national ID are intentionally excluded.
-- Exposes enough structured context for lenders to make informed offers.
-- --------------------------------------------
CREATE VIEW v_loan_listings WITH (security_invoker = true) AS
SELECT
    lr.id                                                                     AS request_id,
    lr.title,
    lr.purpose,
    lr.district,
    lr.duration_months,
    lr.requested_amount,
    lr.preferred_repayment_plan,
    lr.repayment_amount_per_period,
    lr.repayment_timeline,
    lr.status,
    lr.number_of_offers,
    lr.listed_at,
    lr.expires_at,
    -- KYC badge (status only — no personal verification documents)
    k.status                                                                  AS kyc_status,
    -- time-remaining helpers
    GREATEST(lr.expires_at - NOW(), INTERVAL '0')                            AS time_remaining,
    (lr.expires_at < NOW() + INTERVAL '24 hours')                            AS closing_soon_24h,
    (lr.expires_at < NOW() + INTERVAL '6 hours')                             AS closing_soon_6h
FROM  loan_requests   lr
LEFT  JOIN kyc_verifications k ON k.user_id = lr.borrower_id
WHERE lr.status = 'active';

COMMENT ON VIEW v_loan_listings IS
'Anonymised marketplace feed. borrower_id, contact details, and private documents are never present.
 Repayment fields give lenders enough context to make an informed offer without exposing income source.';


-- --------------------------------------------
-- v_user_marketplace_activity
-- Dashboard view — one query covers both borrower requests and lender offers.
-- Used in the Positions / My Requests / My Offers screens.
-- --------------------------------------------
CREATE VIEW v_user_marketplace_activity WITH (security_invoker = true) AS
SELECT
    p.id                                                                      AS user_id,
    p.full_name,
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
-- v_lender_offers
-- Lender offer activity — for My Offers screen.
-- Does NOT expose borrower contact details.
-- --------------------------------------------
CREATE VIEW v_lender_offers WITH (security_invoker = true) AS
SELECT
    lo.lender_id,
    lo.id                                                                     AS offer_id,
    lo.request_id,
    lr.title                                                                  AS listing_title,
    lr.purpose                                                                AS listing_purpose,
    lr.district,
    lr.duration_months,
    lr.requested_amount,
    lo.offer_amount,
    lo.proposed_expectations,
    lo.status                                                                 AS offer_status,
    lo.offered_at,
    lo.accepted_at,
    -- contact reveal status (only populated after acceptance)
    cr.status                                                                 AS reveal_status,
    cr.revealed_at
FROM  loan_offers     lo
JOIN  loan_requests   lr ON lr.id      = lo.request_id
LEFT  JOIN contact_reveals cr ON cr.offer_id = lo.id;

COMMENT ON VIEW v_lender_offers IS
'Lender offer history with reveal status. Borrower contact details not exposed until reveal_status = revealed.';


-- --------------------------------------------
-- v_marketplace_activity
-- Marketplace-wide KPIs for admin dashboard.
-- --------------------------------------------
CREATE VIEW v_marketplace_activity WITH (security_invoker = true) AS
SELECT
    DATE_TRUNC('month', lr.listed_at)                                        AS month,
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
GROUP BY DATE_TRUNC('month', lr.listed_at)
ORDER BY month DESC;

COMMENT ON VIEW v_marketplace_activity IS
'Admin KPIs. No monetary aggregates — non-custodial. Match rate measures how many listings received at least one offer.';


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
    proposed_expectations TEXT,
    status TEXT,
    offered_at TIMESTAMP,
    accepted_at TIMESTAMP
)
LANGUAGE SQL
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT
        lo.id,
        lo.request_id,
        ('public-offer-' || ROW_NUMBER() OVER (ORDER BY lo.offered_at ASC))::TEXT AS lender_id,
        lo.offer_amount,
        lo.proposed_expectations,
        lo.status::TEXT,
        lo.offered_at,
        lo.accepted_at
    FROM loan_offers lo
    JOIN loan_requests lr ON lr.id = lo.request_id
    WHERE lo.request_id = p_request_id
      AND lo.status = 'pending'
      AND lr.status = 'active'
    ORDER BY lo.offered_at DESC;
$$;

COMMENT ON FUNCTION get_public_listing_offers(UUID) IS
'Public anonymized offer book for active listings. Does not expose lender_id or borrower details.';


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

-- Generate default agreement text from offer and loan request data
CREATE OR REPLACE FUNCTION fn_generate_agreement_text(
    p_borrower_name TEXT,
    p_lender_name TEXT,
    p_loan_amount BIGINT,
    p_repayment_frequency TEXT,
    p_repayment_amount BIGINT,
    p_duration_months INT,
    p_penalty_pct NUMERIC
)
RETURNS TEXT LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
    RETURN FORMAT(
        '
LOAN AGREEMENT TEMPLATE

This document is a non-binding template provided by Nipanze for convenience.
The final agreement and all legal obligations are solely between the borrower and lender.

PARTIES:
- Borrower: %s
- Lender: %s

LOAN TERMS:
- Principal Amount: UGX %s
- Repayment Frequency: %s
- Repayment Amount Per Period: UGX %s
- Total Loan Duration: %s months

LATE PAYMENT PENALTY:
A penalty of %s%% applies ONLY to the amount of a missed installment, NOT to the total loan.
This ensures fair treatment and prevents excessive debt growth.

DISCLAIMER:
Nipanze does not hold or move funds. Both parties agree to complete all financial transactions
directly and outside this platform. This agreement is for reference only. The parties alone are
responsible for all repayment obligations and dispute resolution.

Generated on: %s
',
        p_borrower_name,
        p_lender_name,
        p_loan_amount,
        p_repayment_frequency,
        p_repayment_amount,
        p_duration_months,
        p_penalty_pct,
        NOW()
    );
END;
$$;


-- ============================================
-- TRIGGER FUNCTIONS
-- ============================================

-- Set expires_at on loan_request insert using system_settings
CREATE OR REPLACE FUNCTION trg_fn_set_listing_expiry()
RETURNS TRIGGER LANGUAGE plpgsql
SET search_path = public AS $$
DECLARE
    v_days INT;
BEGIN
    SELECT setting_value::INT INTO v_days
    FROM system_settings WHERE setting_key = 'listing_duration_days';
    NEW.expires_at := NOW() + (v_days || ' days')::INTERVAL;
    RETURN NEW;
END;
$$;


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


-- Enforce max concurrent active requests from system_settings
CREATE OR REPLACE FUNCTION trg_fn_max_concurrent_requests()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
    v_active_count INT;
    v_max          INT;
BEGIN
    SELECT setting_value::INT INTO v_max
    FROM system_settings WHERE setting_key = 'max_concurrent_requests';

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


-- Validate a lender offer before insert
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
        RAISE EXCEPTION 'NIPANZE_LISTING_NOT_ACTIVE: This listing is no longer accepting offers.'
            USING ERRCODE = 'P0010';
    END IF;

    IF v_listing.expires_at < NOW() THEN
        RAISE EXCEPTION 'NIPANZE_LISTING_EXPIRED: This listing has expired.'
            USING ERRCODE = 'P0011';
    END IF;

    -- Lenders cannot offer on their own request
    IF v_listing.borrower_id = NEW.lender_id THEN
        RAISE EXCEPTION 'NIPANZE_SELF_OFFER: You cannot make an offer on your own listing.'
            USING ERRCODE = 'P0012';
    END IF;

    -- Minimum offer amount
    SELECT setting_value::BIGINT INTO v_min_offer
    FROM system_settings WHERE setting_key = 'min_offer_amount';

    IF NEW.offer_amount < v_min_offer THEN
        RAISE EXCEPTION 'NIPANZE_MIN_OFFER: Offer amount must be at least UGX %.', v_min_offer
            USING ERRCODE = 'P0013';
    END IF;

    -- Lender or Pro subscription required to make offers
    SELECT plan INTO v_plan
    FROM subscriptions
    WHERE user_id = NEW.lender_id AND status = 'active';

    IF v_plan NOT IN ('lender', 'pro') THEN
        RAISE EXCEPTION 'NIPANZE_SUBSCRIPTION_REQUIRED: A Lender or Pro subscription is required to make offers.'
            USING ERRCODE = 'P0014';
    END IF;

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
CREATE TRIGGER trg_require_active_account
    BEFORE INSERT ON loan_requests
    FOR EACH ROW EXECUTE FUNCTION trg_fn_require_active_account();

CREATE TRIGGER trg_max_concurrent_requests
    BEFORE INSERT ON loan_requests
    FOR EACH ROW EXECUTE FUNCTION trg_fn_max_concurrent_requests();

CREATE TRIGGER trg_set_listing_expiry
    BEFORE INSERT ON loan_requests
    FOR EACH ROW EXECUTE FUNCTION trg_fn_set_listing_expiry();

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

CREATE TRIGGER trg_sync_offer_count
    AFTER INSERT OR UPDATE OR DELETE ON loan_offers
    FOR EACH ROW EXECUTE FUNCTION trg_fn_sync_offer_count();

CREATE TRIGGER trg_loan_offers_updated_at
    BEFORE UPDATE ON loan_offers
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();


-- ============================================
-- RPC: accept_offer  (Stage 4+: Creates agreement)
-- Atomic: marks offer accepted, rejects all other pending offers
-- on the same request, sets listing to contracted, creates an
-- agreement record (structured deal agreement), and notifies both parties.
-- Contact details are NOT revealed here — that happens after both
-- parties confirm the agreement and borrower calls unlock_contact.
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
    v_listing       public.loan_requests%ROWTYPE;
    v_offer         public.loan_offers%ROWTYPE;
    v_borrower      public.profiles%ROWTYPE;
    v_lender        public.profiles%ROWTYPE;
    v_agreement_id  UUID;
    v_agreement_text TEXT;
    v_penalty_pct   NUMERIC;
BEGIN
    -- Caller validation (must be the borrower)
    IF p_caller_id IS NULL OR p_caller_id != p_borrower_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Caller is not the borrower.'
            USING ERRCODE = 'P0021';
    END IF;

    SELECT * INTO v_listing FROM public.loan_requests WHERE id = p_request_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'NIPANZE_LISTING_NOT_FOUND' USING ERRCODE = 'P0020';
    END IF;
    IF v_listing.borrower_id != p_borrower_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Only the listing owner can accept an offer.'
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
        RAISE EXCEPTION 'NIPANZE_OFFER_NOT_PENDING: This offer is no longer available.'
            USING ERRCODE = 'P0024';
    END IF;

    -- Get party profiles
    SELECT * INTO v_borrower FROM public.profiles WHERE id = p_borrower_id;
    SELECT * INTO v_lender FROM public.profiles WHERE id = v_offer.lender_id;

    -- Accept chosen offer
    UPDATE public.loan_offers SET status = 'accepted', accepted_at = NOW() WHERE id = p_offer_id;

    -- Reject all other pending offers
    UPDATE public.loan_offers
       SET status = 'rejected', updated_at = NOW()
     WHERE request_id = p_request_id AND id != p_offer_id AND status = 'pending';

    -- Mark listing contracted
    UPDATE public.loan_requests
       SET status = 'contracted', contracted_at = NOW() WHERE id = p_request_id;

    -- Default penalty is 0% (will be editable by parties)
    v_penalty_pct := 0;

    -- Generate default agreement text
    v_agreement_text := public.fn_generate_agreement_text(
        v_borrower.full_name,
        v_lender.full_name,
        v_offer.offer_amount,
        v_listing.preferred_repayment_plan,
        v_listing.repayment_amount_per_period,
        v_listing.duration_months,
        v_penalty_pct
    );

    -- Create agreement (in 'pending' status — both parties must confirm)
    INSERT INTO public.agreements (
        offer_id, request_id,
        repayment_frequency, repayment_amount, late_payment_penalty_pct,
        agreement_text
    )
    VALUES (
        p_offer_id, p_request_id,
        v_listing.preferred_repayment_plan::public.repayment_frequency_enum,
        v_listing.repayment_amount_per_period,
        v_penalty_pct,
        v_agreement_text
    )
    RETURNING id INTO v_agreement_id;

    -- Notify both parties
    INSERT INTO public.notifications (user_id, type, title, body, request_id, offer_id)
    VALUES
        (p_borrower_id, 'agreement_generated', 'Deal agreement ready',
         'Review and confirm the structured loan agreement to unlock contact details.',
         p_request_id, p_offer_id),
        (v_offer.lender_id, 'agreement_generated', 'Deal agreement ready',
         'Review and confirm the structured loan agreement to connect with the borrower.',
         p_request_id, p_offer_id);

    -- Audit
    INSERT INTO public.audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
    VALUES (p_borrower_id, 'offer_accepted', 'loan_offers', p_offer_id, 'accept_offer',
        JSONB_BUILD_OBJECT(
            'request_id',  p_request_id,
            'offer_id',    p_offer_id,
            'agreement_id', v_agreement_id,
            'lender_id',   v_offer.lender_id,
            'accepted_at', NOW()
        ));

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
'Atomically accepts an offer, rejects others, marks listing contracted, creates pending contact_reveal.
 Returns reveal_id. Contact details are not exposed until reveal_contact() is called.
 Platform never holds or moves funds.';


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
-- RPC: confirm_agreement (Stage 4)
-- Each party (borrower or lender) confirms the agreement.
-- Once both have agreed, agreement locks and contact_reveal is created.
-- ============================================

CREATE OR REPLACE FUNCTION private.confirm_agreement_internal(
    p_agreement_id UUID,
    p_caller_id    UUID
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '' AS $$
DECLARE
    v_agreement  public.agreements%ROWTYPE;
    v_offer      public.loan_offers%ROWTYPE;
    v_borrower_id UUID;
    v_lender_id  UUID;
    v_result     JSONB;
BEGIN
    SELECT * INTO v_agreement FROM public.agreements WHERE id = p_agreement_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'NIPANZE_AGREEMENT_NOT_FOUND' USING ERRCODE = 'P0041';
    END IF;
   
    IF v_agreement.status = 'locked' THEN
        RAISE EXCEPTION 'NIPANZE_AGREEMENT_LOCKED: This agreement has already been locked.'
            USING ERRCODE = 'P0042';
    END IF;

    SELECT * INTO v_offer FROM public.loan_offers WHERE id = v_agreement.offer_id;
    
    SELECT borrower_id INTO v_borrower_id FROM public.loan_requests WHERE id = v_agreement.request_id;
    v_lender_id := v_offer.lender_id;

    -- Determine who is confirming
    IF p_caller_id = v_borrower_id THEN
        -- Borrower confirming
        IF v_agreement.status IN ('pending', 'lender_agreed') THEN
            UPDATE public.agreements
               SET status = CASE
                       WHEN status = 'pending' THEN 'borrower_agreed'::public.agreement_status_enum
                       WHEN status = 'lender_agreed' THEN 'locked'::public.agreement_status_enum
                   END,
                   borrower_agreed_at = COALESCE(borrower_agreed_at, NOW()),
                   locked_at = CASE WHEN status = 'lender_agreed' THEN NOW() ELSE NULL END,
                   agreement_snapshot = CASE WHEN status = 'lender_agreed' THEN JSONB_BUILD_OBJECT(
                       'payment_frequency', repayment_frequency::TEXT,
                       'payment_amount', repayment_amount,
                       'penalty_pct', late_payment_penalty_pct,
                       'locked_at', NOW()
                   ) ELSE NULL END
             WHERE id = p_agreement_id;
        ELSE
            RAISE EXCEPTION 'NIPANZE_AGREEMENT_INVALID_STATE: Cannot confirm agreement in this state.'
                USING ERRCODE = 'P0043';
        END IF;
    ELSIF p_caller_id = v_lender_id THEN
        -- Lender confirming
        IF v_agreement.status IN ('pending', 'borrower_agreed') THEN
            UPDATE public.agreements
               SET status = CASE
                       WHEN status = 'pending' THEN 'lender_agreed'::public.agreement_status_enum
                       WHEN status = 'borrower_agreed' THEN 'locked'::public.agreement_status_enum
                   END,
                   lender_agreed_at = COALESCE(lender_agreed_at, NOW()),
                   locked_at = CASE WHEN status = 'borrower_agreed' THEN NOW() ELSE NULL END,
                   agreement_snapshot = CASE WHEN status = 'borrower_agreed' THEN JSONB_BUILD_OBJECT(
                       'payment_frequency', repayment_frequency::TEXT,
                       'payment_amount', repayment_amount,
                       'penalty_pct', late_payment_penalty_pct,
                       'locked_at', NOW()
                   ) ELSE NULL END
             WHERE id = p_agreement_id;
        ELSE
            RAISE EXCEPTION 'NIPANZE_AGREEMENT_INVALID_STATE: Cannot confirm agreement in this state.'
                USING ERRCODE = 'P0043';
        END IF;
    ELSE
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Only borrower or lender can confirm this agreement.'
            USING ERRCODE = 'P0044';
    END IF;

    -- Re-fetch to get updated state
    SELECT * INTO v_agreement FROM public.agreements WHERE id = p_agreement_id;

    -- If now locked, create contact_reveal record
    IF v_agreement.status = 'locked' THEN
        INSERT INTO public.contact_reveals (offer_id, request_id, revealed_by)
        VALUES (v_agreement.offer_id, v_agreement.request_id, v_borrower_id)
        ON CONFLICT DO NOTHING;

        -- Notify both parties that agreement is locked
        INSERT INTO public.notifications (user_id, type, title, body, request_id, offer_id)
        VALUES
            (v_borrower_id, 'agreement_locked', 'Deal agreement locked',
             'Both parties confirmed the agreement. You can now unlock contact details to connect.',
             v_agreement.request_id, v_agreement.offer_id),
            (v_lender_id, 'agreement_locked', 'Deal agreement locked',
             'Both parties confirmed the agreement. Waiting for contact details to be unlocked.',
             v_agreement.request_id, v_agreement.offer_id);

        -- Audit
        INSERT INTO public.audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
        VALUES (p_caller_id, 'agreement_locked', 'agreements', p_agreement_id, 'confirm_agreement',
            JSONB_BUILD_OBJECT(
                'agreement_id', p_agreement_id,
                'locked_at', NOW()
            ));
    ELSE
        -- Notify the other party that one party has agreed
        IF p_caller_id = v_borrower_id THEN
            INSERT INTO public.notifications (user_id, type, title, body, request_id, offer_id)
            VALUES
                (v_lender_id, 'agreement_accepted', 'Borrower confirmed agreement',
                 'The borrower confirmed the deal agreement. Please review and confirm to proceed.',
                 v_agreement.request_id, v_agreement.offer_id);
        ELSE
            INSERT INTO public.notifications (user_id, type, title, body, request_id, offer_id)
            VALUES
                (v_borrower_id, 'agreement_accepted', 'Lender confirmed agreement',
                 'The lender confirmed the deal agreement. Please review and confirm to proceed.',
                 v_agreement.request_id, v_agreement.offer_id);
        END IF;

        -- Audit
        INSERT INTO public.audit_logs (user_id, event_type, entity_type, entity_id, action, new_values)
        VALUES (p_caller_id,
            CASE WHEN p_caller_id = v_borrower_id THEN 'agreement_borrower_agreed' ELSE 'agreement_lender_agreed' END,
            'agreements', p_agreement_id, 'confirm_agreement',
            JSONB_BUILD_OBJECT('caller_id', p_caller_id, 'agreed_at', NOW()));
    END IF;

    v_result := JSONB_BUILD_OBJECT(
        'agreement_id', v_agreement.id,
        'status', v_agreement.status::TEXT,
        'borrower_agreed', (v_agreement.borrower_agreed_at IS NOT NULL),
        'lender_agreed', (v_agreement.lender_agreed_at IS NOT NULL),
        'locked', (v_agreement.status = 'locked')
    );

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION private.confirm_agreement_internal(uuid, uuid) TO authenticated, service_role;

-- Wrapper: SECURITY INVOKER
CREATE OR REPLACE FUNCTION public.confirm_agreement(p_agreement_id UUID)
RETURNS JSONB
LANGUAGE sql SECURITY INVOKER
SET search_path = public AS $$
    SELECT private.confirm_agreement_internal(p_agreement_id, auth.uid());
$$;

REVOKE EXECUTE ON FUNCTION public.confirm_agreement(uuid) FROM public, anon;
GRANT  EXECUTE ON FUNCTION public.confirm_agreement(uuid) TO authenticated, service_role;

COMMENT ON FUNCTION public.confirm_agreement IS
'Party (borrower or lender) confirms they agree to the structured loan agreement.
 Once both parties confirm, the agreement locks and a contact_reveal record is created.
 Returns agreement status. Contact reveal happens via unlock_contact only after lock.';


-- ============================================
-- RPC: unlock_contact (Stage 4)
-- After agreement is locked, borrower unlocks contact details.
-- Creates contact_reveal record (or updates existing one to ''revealed'').
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

    -- Caller validation (must be the borrower)
    IF p_caller_id != v_borrower_id THEN
        RAISE EXCEPTION 'NIPANZE_UNAUTHORIZED: Only the borrower can unlock contact details.'
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
        VALUES (v_agreement.offer_id, v_agreement.request_id, v_borrower_id, 'revealed', NOW())
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
'Borrower unlocks contact details after agreement is locked and both parties have confirmed.
 Reveals legal name, phone, and email of both parties. Irreversible. Returns contact JSONB.
 Platform never stores or retransmits these details after this point.';


-- ============================================
-- ROW-LEVEL SECURITY
-- ============================================

ALTER TABLE system_settings     ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles            ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE kyc_verifications   ENABLE ROW LEVEL SECURITY;
ALTER TABLE loan_requests       ENABLE ROW LEVEL SECURITY;
ALTER TABLE loan_offers         ENABLE ROW LEVEL SECURITY;
ALTER TABLE watchlist           ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_reveals     ENABLE ROW LEVEL SECURITY;
ALTER TABLE agreements          ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications       ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs          ENABLE ROW LEVEL SECURITY;
ALTER TABLE refresh_tokens      ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals           ENABLE ROW LEVEL SECURITY;


-- is_admin lives in the `private` schema so it is NOT exposed
-- via the PostgREST REST API (/rpc/is_admin) but is still
-- callable by RLS policies and other SECURITY DEFINER functions.
CREATE SCHEMA IF NOT EXISTS private;

CREATE OR REPLACE FUNCTION private.is_admin()
RETURNS BOOLEAN LANGUAGE SQL SECURITY DEFINER STABLE
SET search_path = public AS $$
    SELECT EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
    );
$$;

GRANT USAGE  ON SCHEMA private TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION private.is_admin() TO authenticated, service_role;


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

-- loan_requests
CREATE POLICY "loan_requests: marketplace read"
    ON loan_requests FOR SELECT TO authenticated
    USING (status = 'active' OR borrower_id = auth.uid() OR private.is_admin());
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
    WITH CHECK (lender_id = auth.uid());
CREATE POLICY "loan_offers: lender withdraw or admin"
    ON loan_offers FOR UPDATE TO authenticated
    USING (
        (lender_id = auth.uid() AND status = 'pending')
        OR private.is_admin()
    );

-- watchlist
CREATE POLICY "watchlist: own rows"
    ON watchlist FOR ALL TO authenticated
    USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- agreements
-- Only the matched parties (borrower / lender) can see and update the agreement.
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
CREATE POLICY "agreements: matched parties update"
    ON agreements FOR UPDATE TO authenticated
    USING (
        (
            EXISTS (
                SELECT 1 FROM loan_requests lr
                 WHERE lr.id = agreements.request_id AND lr.borrower_id = auth.uid()
            )
            OR EXISTS (
                SELECT 1 FROM loan_offers lo
                 WHERE lo.id = agreements.offer_id AND lo.lender_id = auth.uid()
            )
        )
        AND status != 'locked'  -- Locked agreements cannot be updated
    );
CREATE POLICY "agreements: service role insert"
    ON agreements FOR INSERT TO service_role WITH CHECK (TRUE);
CREATE POLICY "agreements: admin all"
    ON agreements FOR ALL TO authenticated USING (private.is_admin());

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
    ON notifications FOR SELECT TO authenticated USING (user_id = auth.uid());
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
        'Nipanze v4.0 — Non-custodial loan listing matchmaking marketplace. Uganda-first. '
        'Borrowing is free. Lender offers require a subscription. '
        'Contact revealed only after offer acceptance. Platform never holds or tracks funds.');
END $$;


-- ============================================
-- STORAGE BUCKETS
-- ============================================
-- Create via Supabase CLI or dashboard:
--   supabase storage create verification-documents --public=false

-- ============================================
-- FUNCTION SECURITY (Disable public access for SECURITY DEFINER functions)
-- ============================================

-- Revoke public/authenticated/anon access on trigger/internal functions
REVOKE EXECUTE ON FUNCTION public.handle_new_auth_user() FROM public, authenticated, anon;
REVOKE EXECUTE ON FUNCTION public.trg_fn_require_active_account() FROM public, authenticated, anon;
REVOKE EXECUTE ON FUNCTION public.trg_fn_max_concurrent_requests() FROM public, authenticated, anon;
REVOKE EXECUTE ON FUNCTION public.trg_fn_validate_offer() FROM public, authenticated, anon;

-- Revoke public/anon access on client-facing RPCs and restrict to authenticated/service_role
-- is_admin is now in private schema — only grant to authenticated for RLS use
REVOKE EXECUTE ON FUNCTION private.is_admin() FROM public, anon;
GRANT  EXECUTE ON FUNCTION private.is_admin() TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.accept_offer(uuid, uuid, uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.accept_offer(uuid, uuid, uuid) TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.reveal_contact(uuid, uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.reveal_contact(uuid, uuid) TO authenticated, service_role;


-- ============================================
-- END OF SCHEMA v4.0
-- ============================================
-- Grants for views
GRANT SELECT ON v_loan_listings TO authenticated, anon;
GRANT SELECT ON v_user_marketplace_activity TO authenticated, anon;
GRANT SELECT ON v_lender_offers TO authenticated, anon;
GRANT SELECT ON v_marketplace_activity TO authenticated, anon;

-- Explicitly grant privileges on all tables
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated, service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO authenticated, service_role;
