# Stage 3.5 Quick Start — Implementation Checklist

**Status:** ✅ Stage 3 Complete | ⏳ Stage 3.5 Ready to Start

---

## 🚀 QUICK START (Choose One)

### Option A: I'm Starting Fresh
Follow this order exactly:

```
1. Read: STAGE_3.5_GUIDE.md (5 minute overview)
2. Run: sql/stage-3.5-status.sql (see current state)
3. Phase 1: Apply schema.sql → seed.sql → cloud_patch.sql → stage-3.5-apply.sql
4. Phase 2: Run stage-3.5-verify.sql (audit masking)
5. Phase 3: Test end-to-end (./run_cloud.sh web)
6. Phase 4: Build APK + test on device
5. Done: All boxes checked ✅
```

**Time:** ~2 hours

---

### Option B: I Just Want Status
```bash
# See what's been done already:
1. Supabase SQL Editor → New query
2. Copy sql/stage-3.5-status.sql
3. Run
4. See ✅ / ❌ / ⚠️  for each section
5. Know exactly what to do next
```

**Time:** ~5 minutes

---

## 📂 Implementation Files Location

All files are in your project:

| File | Purpose | What to Do |
|---|---|---|
| `STAGE_3.5_GUIDE.md` | **Detailed 5-phase guide** | Read first |
| `STAGE_3.5_CHECKLIST.md` | Quick reference checklists | Keep open while working |
| `sql/schema.sql` | Create tables/views/RLS | Copy → Paste → Run in SQL Editor |
| `sql/seed.sql` | Load 17 test accounts | Copy → Paste → Run in SQL Editor |
| `sql/cloud_patch.sql` | Fix RLS + views | Copy → Paste → Run in SQL Editor |
| `sql/stage-3.5-apply.sql` | Create storage + final setup | Copy → Paste → Run in SQL Editor |
| `sql/stage-3.5-verify.sql` | Audit data masking | Copy → Paste → Run to verify |
| `sql/stage-3.5-status.sql` | Check what's complete | Copy → Paste → Run to diagnose |

---

## ⚡ The 4-Step Process

```
STEP 1: Apply SQL (Supabase SQL Editor)
├─ schema.sql (core tables/RLS)
├─ seed.sql (test data)
├─ cloud_patch.sql (views + permissions)
└─ stage-3.5-apply.sql (storage)
   ↓
STEP 2: Verify (SQL audit)
├─ stage-3.5-status.sql (health check)
└─ stage-3.5-verify.sql (security audit)
   ↓
STEP 3: Test App (Web + APK)
├─ ./run_cloud.sh web (test flows)
├─ flutter build apk --release (build APK)
└─ adb install + test on device (final test)
   ↓
STEP 4: Done ✅
   └─ All boxes checked in STAGE_3.5_CHECKLIST.md
```

---

## 🎯 What Gets Done

After completing Stage 3.5, you will have:

✅ **Schema v4.0** on cloud (17 tables)  
✅ **Seed v2.0** applied (17 test accounts)  
✅ **RLS policies** enforced (no data leaks)  
✅ **Storage bucket** for KYC documents  
✅ **Data masking** verified (borrower_id hidden, contact reveal gated)  
✅ **APK released** (tested on physical Android device)  

---

## 📍 Cloud Project Details

**Project:** Nipanze  
**URL:** `https://lqfpeookpjtbiuhlhjut.supabase.co`  

**Your .env.local already has:**
```
SUPABASE_URL=https://lqfpeookpjtbiuhlhjut.supabase.co
SUPABASE_ANON_KEY=sb_publishable_...
SUPABASE_SERVICE_ROLE_KEY=eyJ...
```

All credentials are ready. No setup needed.

---

## 🧪 Test Accounts (Password: `Test1234!`)

| Email | Role | Subscription | Use For |
|---|---|---|---|
| david.mukasa@gmail.com | Borrower | Free | Testing requests |
| invest@pearlcapital.ug | Lender | Pro | Making offers |
| james.okello@outlook.com | Both | Pro | Both flows |
| admin1@nipanze.ug | Admin | Free | Admin features |

---

## ⏱️ Timeline

| Phase | Duration | What Happens |
|---|---|---|
| 1: Apply SQL | 5-10 mins | Schema + seed uploaded to cloud |
| 2: Verify | 5 mins | Audit script confirms no leaks |
| 3a: Test web | 10 mins | Test borrower + lender flows |
| 3b: Build APK | 15 mins | Create release build |
| 3c: Test device | 10 mins | Install + test on Android |
| **TOTAL** | **~60 mins** | |

---

## ❓ Questions?

**Q: What if I've already partially completed this?**  
A: Run `sql/stage-3.5-status.sql` to see exactly what's done and what's left.

**Q: What if SQL fails?**  
A: Check the error message. Likely causes:
- Table already exists → Skip that file
- Permission error → Check SUPABASE_SERVICE_ROLE_KEY in .env.local
- See troubleshooting in STAGE_3.5_GUIDE.md

**Q: Can I test on web first before APK?**  
A: Yes! That's phase 3a. Good idea to test web first.

**Q: What happens in Stage 4?**  
A: Contact reveal flow (blurred contact card → unblur animation).

---

## ✅ Success Checks

By the end, you should be able to:

- [ ] Login as borrower, post request, browse marketplace, save watchlist
- [ ] Login as lender, browse, make offer, withdraw offer
- [ ] Upload KYC document (camera/gallery)
- [ ] Run `sql/stage-3.5-verify.sql` and see all ✅ (no ⚠️)
- [ ] Build and install APK on physical Android device
- [ ] Open app on device, login, and use core flows (no crashes)

**If all checked:** Stage 3.5 complete ✅

---

## 📖 Recommended Reading Order

1. **This file** (right now) — 5 min overview
2. **STAGE_3.5_GUIDE.md** (detailed) — 10 min read
3. **STAGE_3.5_CHECKLIST.md** (keep open) — reference while working
4. Then start implementation!

---

## 🎯 Goal

Complete Stage 3.5 by:
- **Tomorrow?** Yes, it's 2 hours of work
- **Today?** Yes, it's 2 hours of work
- **In 30 mins?** No, take your time — test thoroughly

---

**You've got this! 💪**

*Next stop: Stage 4 — Contact Reveal*

---

*Nipanze Platform · Cloud Migration & Auth Hardening*  
*Created: March 2026*
