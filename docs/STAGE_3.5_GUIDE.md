# Stage 3.5 Implementation Guide — Cloud Migration & Auth Hardening

> **Duration:** 1-2 hours  
> **Environment:** Supabase Cloud (`lqfpeookpjtbiuhlhjut.supabase.co`)  
> **Testing:** Physical Android device + Web browser  

---

## Prerequisites ✅

Verify these are in place before starting:

- ✅ Stage 3 complete (all 5 nav tabs functional)
- ✅ `.env.local` has `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`
- ✅ Cloud project accessible via Supabase Dashboard
- ✅ Schema v4.0 ready in `sql/schema.sql`
- ✅ Seed v2.0 ready in `sql/seed.sql`

---

## Phase 1: Apply Schema & Seed to Cloud (30 mins)

### Step 1.1: Apply Schema v4.0

1. Open [Supabase Dashboard](https://supabase.com/dashboard)
2. Navigate to your project → **SQL Editor**
3. Click **"New query"** button
4. Copy entire contents of `sql/schema.sql` (from your project)
5. Paste into the SQL Editor
6. Click **"Run"** button
7. Wait for completion → you should see ✅ **Success** message
   - The script creates ~20 tables, views, functions, and RLS policies
   - This may take 2-3 minutes
8. Check **Status** tab for errors

**Expected output:** No errors. Tables listed in left sidebar:
- `profiles`, `subscriptions`, `loan_requests`, `loan_offers`
- `kyc_verifications`, `watchlist`, `contact_reveals`
- `notifications`, `audit_logs`, `system_settings`

---

### Step 1.2: Apply Seed Data v2.0

1. In the same **SQL Editor**, click **"New query"**
2. Copy entire contents of `sql/seed.sql`
3. Paste into the SQL Editor
4. Click **"Run"**
5. Wait for completion (~1 minute)
6. Verify test accounts created:
   - Click **Authentication** left panel
   - You should see 17 users (all with password `Test1234!`)
   - Examples: `david.mukasa@gmail.com`, `james.okello@outlook.com`, `admin1@nipanze.ug`

**Expected output:** 17 auth users created. Example rows visible in tables.

---

### Step 1.3: Apply Cloud Patch (RLS + Views)

1. In the same **SQL Editor**, click **"New query"**
2. Copy entire contents of `sql/cloud_patch.sql`
3. Paste into the SQL Editor
4. Click **"Run"**
5. Wait for completion (~30 seconds)

**Expected output:** No errors. Views updated to use `security_invoker = true`.

---

### Step 1.4: Apply Final Cloud Setup

1. In the same **SQL Editor**, click **"New query"**
2. Copy entire contents of `sql/stage-3.5-apply.sql`
3. Paste into the SQL Editor
4. Click **"Run"**
5. Wait for completion (~30 seconds)

**Expected output:**
```
✅ verification-documents bucket created
✅ RLS policies applied to storage
✅ All tables have RLS enabled
```

---

## Phase 2: Verify Data Masking (15 mins)

### Step 2.1: Run Verification Script

1. In **SQL Editor**, click **"New query"**
2. Copy entire contents of `sql/stage-3.5-verify.sql`
3. Paste and run

**Expected output:**
```
✅ 9 core tables exist
✅ 4 views defined with security_invoker=true
✅ v_loan_listings: NO borrower_id column
✅ v_lender_offers: NO lender contact columns
✅ RLS policies on all tables
✅ verification-documents bucket exists
✅ 17 test accounts loaded
```

---

### Step 2.2: Manual Data Masking Audit

Open a new **SQL Editor** query and run these individual tests:

**Test 1: v_loan_listings columns (should NOT include borrower_id)**
```sql
SELECT column_name FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'v_loan_listings'
ORDER BY ordinal_position;
```
**Expected:** `request_id`, `title`, `purpose`, `district`, `duration_months`, `requested_amount`, `preferred_repayment_plan`, `repayment_amount_per_period`, `repayment_timeline`, `status`, `number_of_offers`, `listed_at`, `expires_at`, `kyc_status`, `time_remaining`, `closing_soon_24h`, `closing_soon_6h`  
**NOT expected:** `borrower_id`, `phone`, `email`, `full_name`, `national_id`

**Test 2: v_lender_offers columns (should NOT expose lender contact pre-reveal)**
```sql
SELECT column_name FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'v_lender_offers'
ORDER BY ordinal_position;
```
**Expected:** `lender_id`, `offer_id`, `request_id`, `listing_title`, `listing_purpose`, `district`, `duration_months`, `requested_amount`, `offer_amount`, `proposed_expectations`, `offer_status`, `offered_at`, `accepted_at`, `reveal_status`, `revealed_at`  
**NOT expected:** `lender_phone`, `lender_email`, `lender_name` (contact reveal happens via `contact_reveals` table, not here)

**Test 3: Contact reveal gating (borrower contact NOT visible until reveal)**
```sql
SELECT * FROM contact_reveals WHERE status = 'revealed' LIMIT 1;
```
**Expected:** Only rows where `status = 'revealed'` contain borrower contact. Check that `borrower_phone`, `borrower_email` exist only after `status` changes.

---

## Phase 3: Test End-to-End Flow (30 mins)

### Step 3.1: Test Borrower Flow

1. **Start app against cloud:**
   ```bash
   cd /home/mango/Projects/nipanze
   ./run_cloud.sh web
   ```

2. **Login as borrower:**
   - Email: `david.mukasa@gmail.com`
   - Password: `Test1234!`

3. **Verify navigation:**
   - ✅ 5 tabs appear: Markets | Watchlist | Request | Positions | Account
   - ✅ Marketplace shows active listings (anonymised)
   - ✅ Account shows profile, subscription (Free)

4. **Test "Post Request" flow:**
   - Click **Request** tab → "Create a loan request"
   - Fill form: title, amount (e.g., 5,000,000), duration (6 months), etc.
   - Submit
   - Verify listing appears in *Positions → My Requests*

5. **Test "Save to Watchlist":**
   - Marketplace → Select a listing → Click star icon
   - Watchlist tab → Verify listing appears with urgency border (if <24h)

---

### Step 3.2: Test Lender Flow

1. **Logout and login as lender:**
   - Email: `invest@pearlcapital.ug` (Pro subscription)
   - Password: `Test1234!`

2. **Verify subscription**:
   - Account tab → "Lender" plan should show as active

3. **Make an offer:**
   - Marketplace → Select a listing → "Make an Offer" button
   - Enter amount and expectations
   - Submit
   - Verify offer appears in *Positions → My Offers*

4. **Test offer withdrawal:**
   - Positions → My Offers → Select an offer → "Withdraw" button
   - Confirm
   - Verify offer disappears

---

### Step 3.3: Test Offer Acceptance (Contact Reveal Gating)

1. **Login as borrower (david.mukasa@gmail.com)**
2. **Positions → My Requests → Select request with pending offers**
3. **Accept an offer** (if flow is implemented)
   - You should see contact reveal UI (even though full reveal is Stage 4)
4. **Positions → My Offers (as lender)** → Status should show `accepted`
5. **Verify contact details NOT visible yet** (that's Stage 4)

---

### Step 3.4: Test KYC Upload

1. **Login as any user**
2. **Account tab → "KYC Verification"** (if visible)
3. **Upload a test document:**
   - Take a photo or select file
   - Upload should succeed to `verification-documents` bucket
4. **Verify file in Supabase Storage:**
   - Dashboard → Storage → `verification-documents` bucket
   - Should see user-specific folder with uploaded files

---

## Phase 4: Build & Test APK (20 mins)

### Step 4.1: Build Release APK

```bash
cd /home/mango/Projects/nipanze
flutter clean
flutter build apk --release \
  --dart-define=SUPABASE_URL="https://lqfpeookpjtbiuhlhjut.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="sb_publishable_NF2TuHf3NEfowGgK7QTEuw_UQ9b-0YK"
```

**Expected output:**
```
✅ build/app/outputs/flutter-app-release.apk
```

Size: ~30-50 MB

---

### Step 4.2: Install on Physical Android Device

1. **Connect Android device** to your machine via USB
2. **Enable Developer Mode** on device (or use Android Emulator)
3. **Install APK:**
   ```bash
   adb install -r build/app/outputs/flutter-app-release.apk
   ```

4. **Launch app:**
   - Find **Nipanze** on home screen
   - Tap to open

---

### Step 4.3: Test on Physical Device

1. **Login** (same test accounts as web)
2. **Verify core flows:**
   - ✅ Browse marketplace (no crashes)
   - ✅ Post a request
   - ✅ Make an offer (with Pro account)
   - ✅ Open notifications
   - ✅ Upload KYC document (camera/gallery picker)
3. **Check for errors:**
   - Logcat: `adb logcat | grep flutter`
   - Look for red error banners in-app
   - Check Firebase Crashlytics (if configured)

---

## Phase 5: Verification Checklist ✅

### Schema & Data
- [ ] Schema v4.0 applied to cloud project
- [ ] Seed v2.0 applied (17 test accounts visible)
- [ ] Cloud patch applied (RLS + views updated)
- [ ] Storage bucket `verification-documents` created
- [ ] All core tables visible in Supabase Dashboard

### Data Masking
- [ ] v_loan_listings does NOT expose `borrower_id`
- [ ] v_loan_listings does NOT expose `phone`, `email`, `full_name`
- [ ] v_lender_offers does NOT expose lender contact pre-reveal
- [ ] Contact reveal gated via `contact_reveals` table + RLS
- [ ] Verification script shows all ✅

### RLS Security
- [ ] All 9 core tables have `ROW LEVEL SECURITY` enabled
- [ ] Users can only read their own profiles
- [ ] Borrowers can only read active listings
- [ ] Lenders can only see their own offers
- [ ] Offer withdrawal blocked for non-owners

### Auth Security
- [ ] Refresh token rotation enabled (check Supabase Dashboard)
- [ ] JWT expiry: 3600 seconds
- [ ] Session invalidation works on logout
- [ ] No errors in Firebase Crashlytics

### App Testing
- [ ] ✅ Borrower flow works end-to-end (web)
- [ ] ✅ Lender flow works end-to-end (web)
- [ ] ✅ Offer acceptance & withdrawal works
- [ ] ✅ KYC upload works (camera + gallery)
- [ ] ✅ Marketplace loads without crashes
- [ ] ✅ APK built and tested on physical Android device
- [ ] ✅ No red error banners or crashes on device

---

## Troubleshooting

### Schema Application Fails
**Problem:** SQL error when running schema.sql
**Solution:**
- Check if tables already exist: `SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'`
- If 20+ tables exist, skip schema.sql (already applied)
- If partial tables, clear first: `DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;` (⚠️ deletes all data)

### Seed Data Fails
**Problem:** Duplicate key error when inserting auth users
**Solution:**
- Seed data with fixed UUIDs may conflict if reapplied
- Check if users already exist: `SELECT COUNT(*) FROM auth.users`
- If already loaded, skip seed.sql

### View Returns Empty
**Problem:** `v_loan_listings` shows no results
**Solution:**
- Verify active listings exist: `SELECT COUNT(*) FROM loan_requests WHERE status = 'active'`
- Check RLS policies aren't over-restrictive
- Ensure you're logged in as `authenticated` role

### KYC Upload Fails
**Problem:** "permission denied" when uploading to storage
**Solution:**
- Check bucket exists: `SELECT * FROM storage.buckets WHERE name = 'verification-documents'`
- Verify RLS policies on bucket
- Ensure user_id in file path matches `auth.uid()`

### APK Crashes on Launch
**Problem:** App crashes immediately when opened on device
**Solution:**
- Check logcat: `adb logcat | grep flutter` to see error
- Verify SUPABASE_URL and SUPABASE_ANON_KEY are correct in APK build
- Check internet connectivity on device
- Rebuild with `flutter clean`

---

## Success Criteria ✅

You have successfully completed **Stage 3.5** when:

1. ✅ Schema v4.0 applied to cloud project (no errors)
2. ✅ Seed v2.0 loaded (17 test accounts visible)
3. ✅ Storage bucket created with RLS policies
4. ✅ Verification script shows all ✅ (no ⚠️ warnings)
5. ✅ Borrower can post request, see marketplace, save watchlist (web + APK)
6. ✅ Lender can make and withdraw offers (web + APK)
7. ✅ KYC document upload works (camera/gallery)
8. ✅ No data leaks: verification script confirms masking
9. ✅ APK tested on physical Android device (no crashes)
10. ✅ Refresh token rotation verified in Supabase Dashboard

---

## Next: Stage 4 — Contact Reveal (Coming Next)

Once Stage 3.5 is complete, Stage 4 adds:
- Contact reveal flow (blurred → unblur animation)
- Borrower triggers reveal
- Both parties see name, phone, email post-reveal
- Notifications sent to both on reveal
- Irreversible reveal (second attempt fails gracefully)

---

*Last updated: March 2026 · Nipanze Platform · contact@nipanze.ug*
