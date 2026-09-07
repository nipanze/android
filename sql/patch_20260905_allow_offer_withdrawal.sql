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