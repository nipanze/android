# Stage 3.5 Implementation Checklist

> **Quick Reference** — Print or keep open while implementing  
> **Estimated Time:** 1.5-2 hours  
> **Cloud Project:** `lqfpeookpjtbiuhlhjut.supabase.co`  

---

## ✅ Pre-Flight Checklist

- [ ] Stage 3 complete (all 5 nav tabs working)
- [ ] `.env.local` has cloud credentials
- [ ] Supabase Dashboard access working
- [ ] Flutter SDK available (`flutter --version`)
- [ ] Android SDK / Android Studio available
- [ ] Physical Android device or emulator ready

---

## 📋 Phase 1: Apply Schema & Seed (30 mins)

### SQL Editor → New Query

1. **schema.sql**
   - [ ] Copy `sql/schema.sql` (entire file)
   - [ ] Paste into Supabase SQL Editor
   - [ ] Click Run
   - [ ] ✅ Wait for Success (2-3 mins)
   - [ ] Check Status tab (no errors)

2. **seed.sql**
   - [ ] Copy `sql/seed.sql` (entire file)
   - [ ] New query → Paste
   - [ ] Click Run
   - [ ] ✅ Wait for Success (1 min)
   - [ ] Check: Authentication → 17 users visible

3. **cloud_patch.sql**
   - [ ] Copy `sql/cloud_patch.sql` (entire file)
   - [ ] New query → Paste
   - [ ] Click Run
   - [ ] ✅ Wait for Success (30 secs)

4. **stage-3.5-apply.sql**
   - [ ] Copy `sql/stage-3.5-apply.sql` (entire file)
   - [ ] New query → Paste
   - [ ] Click Run
   - [ ] ✅ Wait for Success (30 secs)
   - [ ] Verify: Storage → `verification-documents` bucket exists

---

## 🔍 Phase 2: Verify Data Masking (15 mins)

### Run Verification Script

- [ ] Copy `sql/stage-3.5-verify.sql` (entire file)
- [ ] New query → Paste → Run
- [ ] Check output for:
  - [ ] 9 tables exist
  - [ ] 4 views with `security_invoker = true`
  - [ ] NO `borrower_id` in `v_loan_listings`
  - [ ] NO lender contact in `v_lender_offers`
  - [ ] `verification-documents` bucket exists
  - [ ] 17 test accounts loaded

### Individual Tests (optional but recommended)

- [ ] Test 1: v_loan_listings columns (no borrower_id)
- [ ] Test 2: v_lender_offers columns (no lender contact)
- [ ] Test 3: contact_reveals gating

---

## 🧪 Phase 3: Test End-to-End (30 mins)

### 3.1 Borrower Flow

- [ ] `./run_cloud.sh web` (start app)
- [ ] Login: `david.mukasa@gmail.com` / `Test1234!`
- [ ] ✅ 5 tabs visible: Markets | Watchlist | Request | Positions | Account
- [ ] ✅ Marketplace shows listings (anonymised)
- [ ] ✅ Create request → appears in Positions → My Requests
- [ ] ✅ Save to Watchlist → appears in Watchlist tab

### 3.2 Lender Flow

- [ ] Logout
- [ ] Login: `invest@pearlcapital.ug` / `Test1234!` (Pro subscription)
- [ ] ✅ Browse Marketplace
- [ ] ✅ Make offer → appears in Positions → My Offers
- [ ] ✅ Withdraw offer → removed from My Offers

### 3.3 Contact Reveal Gating

- [ ] Login as borrower with pending offer
- [ ] ✅ Accept offer (if implemented)
- [ ] ✅ Contact details NOT visible yet (Stage 4 feature)

### 3.4 KYC Upload

- [ ] Login as any user
- [ ] ✅ Account → KYC Verification
- [ ] ✅ Upload document (camera/gallery)
- [ ] ✅ Check Supabase Storage → `verification-documents` bucket → file appears

---

## 🏗️ Phase 4: Build APK (20 mins)

1. **Clean & Build**
   ```bash
   [ ] flutter clean
   [ ] flutter build apk --release \
         --dart-define=SUPABASE_URL="https://lqfpeookpjtbiuhlhjut.supabase.co" \
         --dart-define=SUPABASE_ANON_KEY="sb_publishable_NF2TuHf3NEfowGgK7QTEuw_UQ9b-0YK"
   ```
   - [ ] ✅ Build completes (30-50 MB APK)
   - [ ] Output: `build/app/outputs/flutter-app-release.apk`

2. **Install on Device**
   ```bash
   [ ] Connect Android device via USB
   [ ] Enable USB Debugging on device
   [ ] adb install -r build/app/outputs/flutter-app-release.apk
   ```
   - [ ] ✅ APK installs without errors
   - [ ] ✅ Nipanze icon appears on home screen

3. **Test on Device**
   - [ ] ✅ App launches
   - [ ] ✅ Login works
   - [ ] ✅ Marketplace loads
   - [ ] ✅ No red error banners
   - [ ] ✅ Check logcat: `adb logcat | grep flutter` (no crashes)

---

## ✅ Final Verification (Phase 5)

### Schema & Data
- [ ] ✅ Schema v4.0 applied
- [ ] ✅ Seed v2.0 with 17 test accounts
- [ ] ✅ Cloud patch applied
- [ ] ✅ Storage bucket created

### Security
- [ ] ✅ v_loan_listings does NOT expose borrower_id
- [ ] ✅ v_loan_listings does NOT expose phone/email/full_name
- [ ] ✅ v_lender_offers does NOT expose lender contact pre-reveal
- [ ] ✅ Contact reveal gated by RLS
- [ ] ✅ All 9 tables have RLS enabled

### Functionality
- [ ] ✅ Borrower can post, browse, save watchlist (web + APK)
- [ ] ✅ Lender can make & withdraw offers (web + APK)
- [ ] ✅ KYC document upload works
- [ ] ✅ No crashes on physical Android device
- [ ] ✅ Refresh token rotation enabled (Supabase Dashboard)

---

## 🚨 Troubleshooting Quick Fixes

| Problem | Solution |
|---|---|
| Schema fails with "table already exists" | All tables already applied. Skip and proceed to seed. |
| Seed fails with "duplicate key error" | Users already loaded. Proceed to cloud_patch.sql. |
| `v_loan_listings` returns empty | Verify active listings exist: `SELECT * FROM loan_requests WHERE status = 'active'` |
| KYC upload permission denied | Check bucket RLS: `SELECT * FROM storage.buckets` |
| APK crashes on launch | Run logcat: `adb logcat \| grep flutter` and check error message |
| Marketplace loads but shows nothing | Login as `authenticated` user (not anon). Check RLS policies. |

---

## 📍 Important URLs & Credentials

**Supabase Dashboard:**  
```
https://supabase.com/dashboard/project/lqfpeookpjtbiuhlhjut
```

**Cloud Project URL:**
```
https://lqfpeookpjtbiuhlhjut.supabase.co
```

**Test Accounts (all passwords: `Test1234!`)**
- Borrower: `david.mukasa@gmail.com`
- Lender (Pro): `invest@pearlcapital.ug`
- Both: `james.okello@outlook.com`
- Admin: `admin1@nipanze.ug`

**File Paths**
- Implementation Guide: `STAGE_3.5_GUIDE.md`
- Schema: `sql/schema.sql`
- Seed: `sql/seed.sql`
- Cloud Patch: `sql/cloud_patch.sql`
- Setup Script: `sql/stage-3.5-apply.sql`
- Verify Script: `sql/stage-3.5-verify.sql`

---

## 🎯 Success = All Boxes Checked ✅

When complete:
1. ✅ Schema + seed applied to cloud
2. ✅ Data masking verified (no leaks)
3. ✅ All flows tested (web + APK)
4. ✅ APK runs on physical device (no crashes)
5. ✅ Ready for Stage 4 — Contact Reveal

---

*Stage 3.5 — Cloud Migration & Auth Hardening*  
*Nipanze Platform · contact@nipanze.ug*
