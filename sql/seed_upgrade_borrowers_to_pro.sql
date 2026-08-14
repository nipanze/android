-- Make specific seeded borrowers 'pro' so Pro-gated suggested terms succeed
-- Idempotent: updates existing subscriptions or inserts a fresh active Pro subscription

-- Borrower IDs used in seed_more_listings.sql that include suggested terms
-- 10000000...0001, 0002, 0018, 0003, 0005

DO $$
BEGIN
  -- Upsert helper: set active pro subscription for a user
  INSERT INTO public.subscriptions (user_id, plan, status, amount_minor_units, started_at, expires_at, auto_renew, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000001','pro','active',150000,NOW(), NOW() + INTERVAL '4 years', TRUE, NOW(), NOW())
    ON CONFLICT (user_id) WHERE status = 'active' DO UPDATE
      SET plan='pro', amount_minor_units=150000, started_at=NOW(), expires_at=NOW() + INTERVAL '4 years', auto_renew=TRUE, updated_at=NOW();

  INSERT INTO public.subscriptions (user_id, plan, status, amount_minor_units, started_at, expires_at, auto_renew, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000002','pro','active',150000,NOW(), NOW() + INTERVAL '4 years', TRUE, NOW(), NOW())
    ON CONFLICT (user_id) WHERE status = 'active' DO UPDATE
      SET plan='pro', amount_minor_units=150000, started_at=NOW(), expires_at=NOW() + INTERVAL '4 years', auto_renew=TRUE, updated_at=NOW();

  INSERT INTO public.subscriptions (user_id, plan, status, amount_minor_units, started_at, expires_at, auto_renew, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000018','pro','active',150000,NOW(), NOW() + INTERVAL '4 years', TRUE, NOW(), NOW())
    ON CONFLICT (user_id) WHERE status = 'active' DO UPDATE
      SET plan='pro', amount_minor_units=150000, started_at=NOW(), expires_at=NOW() + INTERVAL '4 years', auto_renew=TRUE, updated_at=NOW();

  INSERT INTO public.subscriptions (user_id, plan, status, amount_minor_units, started_at, expires_at, auto_renew, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000003','pro','active',150000,NOW(), NOW() + INTERVAL '4 years', TRUE, NOW(), NOW())
    ON CONFLICT (user_id) WHERE status = 'active' DO UPDATE
      SET plan='pro', amount_minor_units=150000, started_at=NOW(), expires_at=NOW() + INTERVAL '4 years', auto_renew=TRUE, updated_at=NOW();

  INSERT INTO public.subscriptions (user_id, plan, status, amount_minor_units, started_at, expires_at, auto_renew, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000005','pro','active',150000,NOW(), NOW() + INTERVAL '4 years', TRUE, NOW(), NOW())
    ON CONFLICT (user_id) WHERE status = 'active' DO UPDATE
      SET plan='pro', amount_minor_units=150000, started_at=NOW(), expires_at=NOW() + INTERVAL '4 years', auto_renew=TRUE, updated_at=NOW();

  INSERT INTO public.subscriptions (user_id, plan, status, amount_minor_units, started_at, expires_at, auto_renew, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000006','pro','active',150000,NOW(), NOW() + INTERVAL '4 years', TRUE, NOW(), NOW())
    ON CONFLICT (user_id) WHERE status = 'active' DO UPDATE
      SET plan='pro', amount_minor_units=150000, started_at=NOW(), expires_at=NOW() + INTERVAL '4 years', auto_renew=TRUE, updated_at=NOW();
END $$;
