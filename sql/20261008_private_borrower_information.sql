-- Keep reusable borrower details out of general profiles and marketplace rows.
-- Re-runnable; historical Needs category rows are retained but disabled.

CREATE TABLE IF NOT EXISTS public.borrower_information (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    employment_status TEXT NOT NULL
        CHECK (employment_status IN (
            'government_employed',
            'private_sector',
            'self_employed',
            'business_owner',
            'student',
            'unemployed',
            'other'
        )),
    employer_business_name TEXT,
    is_government_employee BOOLEAN NOT NULL,
    monthly_income_range TEXT NOT NULL
        CHECK (monthly_income_range IN (
            'no_regular_income',
            'under_500k',
            '500k_1m',
            '1m_2m',
            '2m_3m',
            'over_3m'
        )),
    income_currency VARCHAR(3) NOT NULL
        CHECK (income_currency ~ '^[A-Z]{3}$'),
    other_income_source TEXT,
    preferred_bank TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.borrower_information IS
    'Private reusable borrower information. Owner-only RLS; never join into public marketplace views.';

ALTER TABLE public.borrower_information ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "borrower_information: owner read"
    ON public.borrower_information;
CREATE POLICY "borrower_information: owner read"
    ON public.borrower_information FOR SELECT TO authenticated
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS "borrower_information: owner insert"
    ON public.borrower_information;
CREATE POLICY "borrower_information: owner insert"
    ON public.borrower_information FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "borrower_information: owner update"
    ON public.borrower_information;
CREATE POLICY "borrower_information: owner update"
    ON public.borrower_information FOR UPDATE TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

REVOKE ALL ON TABLE public.borrower_information FROM PUBLIC, anon;
GRANT SELECT, INSERT, UPDATE
    ON TABLE public.borrower_information TO authenticated;

CREATE OR REPLACE FUNCTION public.set_borrower_information_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_borrower_information_updated_at
    ON public.borrower_information;
CREATE TRIGGER trg_borrower_information_updated_at
    BEFORE UPDATE ON public.borrower_information
    FOR EACH ROW
    EXECUTE FUNCTION public.set_borrower_information_updated_at();

-- Keep existing requests and category references for history; only disable
-- the retired financial category and its capabilities for new Needs flows.
UPDATE public.need_categories
SET is_active = FALSE
WHERE slug = 'financial_services';

UPDATE public.need_capabilities
SET is_active = FALSE
WHERE category_slug = 'financial_services';

CREATE OR REPLACE FUNCTION public.reject_financial_needs_category()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    IF NEW.category_slug = 'financial_services' THEN
        RAISE EXCEPTION 'Financial services requests belong in Loans or Forex, not Needs.'
            USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_reject_financial_needs_category
    ON public.needs_requests;
CREATE TRIGGER trg_reject_financial_needs_category
    BEFORE INSERT OR UPDATE OF category_slug ON public.needs_requests
    FOR EACH ROW
    EXECUTE FUNCTION public.reject_financial_needs_category();
