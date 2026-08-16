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
