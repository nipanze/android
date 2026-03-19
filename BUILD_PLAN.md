# OpenCapital — MVP Build Plan

> **Stack:** Flutter + Supabase (free tier) + Supabase CLI Local Stack
> **Database:** The production `sql/schema.sql` (19 tables + mock RPCs) is the single source of truth.
> **Seed data:** `sql/seed.sql` v2.1 — inserts into `auth.users` with fixed UUIDs, triggers sync to `public.users`.
> **Goal:** A fully testable end-to-end marketplace before a single external API is touched.

---

## Ground Rules

1. **Schema first, always.** `sql/schema.sql` deploys on `supabase db reset`. Never simplify the schema for the app layer.
2. **Seed data is your test fixture.** `sql/seed.sql` gives you 18 users with fixed UUIDs, 6 loan requests, 10 bids, and reconciled wallet states. Load after every reset.
3. **Triggers and functions are already implemented.** The DB enforces KYC gates, balance checks, tier sync, repayment schedules, and contract activation.
4. **No Edge Functions until Stage 4.** All mutations in Stages 1–3 go through Postgres RPCs defined in `schema.sql`.
5. **Mock everything external in Stages 1–3.** `mock_top_up`, `mock_disburse`, `mock_repayment` RPCs are already in `schema.sql`.
6. **One feature fully working before starting the next.**
7. **Test as you build, not after.**

---

## Reset Workflow

```bash
supabase db reset
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -f sql/schema.sql
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -f sql/seed.sql
```

---

## Schema Quick Reference

| Feature | Primary Tables |
| --- | --- |
| Auth & identity | `users`, `user_profiles`, `refresh_tokens`, `email_verification_tokens`, `password_reset_tokens` |
| KYC | `kyc_verifications` |
| Risk & credit | `risk_assessments` |
| Wallet | `wallet_balances` |
| Loan marketplace | `loan_requests`, `bids` |
| Contracts | `loan_contracts`, `contract_bids` |
| Payments | `disbursements`, `loan_repayments`, `repayment_transactions` |
| Platform | `audit_logs`, `notifications`, `user_notes`, `system_settings` |

Key DB-enforced rules:

- `trg_fn_require_kyc_for_loan` — blocks `loan_requests` INSERT without approved KYC
- `trg_fn_require_active_borrower` — blocks `loan_requests` INSERT if `users.status != 'active'`
- `trg_fn_enforce_lendable_on_bid` — blocks `bids` INSERT if `lendable_balance < bid_amount`
- `trg_fn_lock_funds_on_accept` — on bid → `accepted`: moves `lendable_balance` → `locked_repayment`
- `trg_fn_credit_borrower_on_disbursement` — on disbursement → `completed`: credits `non_lendable_borrowed`
- `trg_fn_check_all_lenders_signed` — auto-activates contract when all `contract_bids.lender_signed = TRUE`
- `fn_score_to_tier` — pure mapping; `trg_sync_reputation_tier` calls it on every `reputation_score` UPDATE
- `handle_new_auth_user` — syncs `auth.users` → `public.users` on every signup (in `schema.sql`)
- `accept_bid(request_id, bid_id, borrower_id)` — atomic RPC in `schema.sql`
- `mock_top_up(user_id, amount)` — Stage 2-3 wallet top-up RPC in `schema.sql`

---

## Testing Strategy

| Layer | Tool | When | What |
| --- | --- | --- | --- |
| Unit | `flutter_test` | Every stage | BLoC states, repository logic, score formulas, validators |
| Widget | `flutter_test` | Every stage | UI renders, buttons fire events, forms validate |
| Integration | Local stack + `integration_test` | Stages 2–4 | Full user flows against real Postgres |
| Sandbox | Provider sandbox APIs | Stage 4 only | MTN MoMo, Africa's Talking, KYC provider |

```bash
# Unit + widget
flutter test

# Integration — single file, Linux desktop only
flutter test integration_test/integration_test.dart -d linux

# Coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## Seed Data Test Accounts ✅

Password for all accounts: `Test1234!`
All accounts inserted into `auth.users` with fixed UUIDs via `sql/seed.sql` v2.1.
Passwords use `crypt('Test1234!', gen_salt('bf'))` — GoTrue-compatible `$2a$` format.

| Email | UUID suffix | Role | Notes |
| --- | --- | --- | --- |
| `david.mukasa@gmail.com` | `...000001` | borrower | KYC approved, credit 750, loan fully funded |
| `sarah.namukasa@yahoo.com` | `...000002` | borrower | KYC approved, loan partially funded |
| `james.okello@outlook.com` | `...000003` | both | KYC approved, loan fully funded, lender |
| `maria.nakato@gmail.com` | `...000004` | borrower | KYC approved, loan active no bids |
| `robert.ssemwanga@gmail.com` | `...000005` | both | KYC approved, lender + draft loan |
| `info@greenleafagro.co.ug` | `...000006` | lender | 1,500,000 lendable, pending bid |
| `contact@kampalatech.ug` | `...000007` | lender | 1,000,000 lendable, pending bid |
| `invest@pearlcapital.ug` | `...000008` | lender | 3,000,000 lendable, 7,000,000 locked |
| `funds@victoriainvest.co.ug` | `...000009` | lender | 3,000,000 lendable, 2,000,000 locked |
| `lending@equatorfinance.ug` | `...000010` | lender | 2,000,000 lendable, 3,000,000 locked |
| `frank.omondi@gmail.com` | `...000011` | borrower | KYC approved, loan active no bids |
| `lucy.nambi@yahoo.com` | `...000012` | both | KYC approved |
| `charles.mwesigwa@gmail.com` | `...000013` | both | KYC approved, 1,200,000 lendable |
| `alice.namuli@gmail.com` | `...000014` | borrower | KYC pending, `pending_verification` |
| `admin1@opencapital.ug` | `...000015` | admin | Full access |
| `admin2@opencapital.ug` | `...000016` | admin | Full access |
| `admin3@opencapital.ug` | `...000017` | admin | Full access |
| `test.user@gmail.com` | `...000018` | borrower | No KYC, no profile — intentionally minimal |

---

## Stage 1 — Foundation ✅ COMPLETE

**Outcome:** App launches, auth works completely, every screen is reachable.

---

### 1.1 — Project Scaffold ✅

- [x] Folder structure: `lib/core/`, `lib/features/`, `lib/shared/`
- [x] `get_it` + `injectable` — `injection.dart`, `injection.config.dart` generated by `build_runner`
- [x] `AppTheme` + `AppColors` — light/dark, brand colour `#1A56DB`, Sora headings + Inter body
- [x] `AppRouter` with GoRouter — all route paths as constants in `Routes` abstract class
- [x] `MainScaffold` with bottom nav (5 tabs: Dashboard, Marketplace, My Loans, Wallet, Profile)
- [x] All platform targets: web, linux, android, iOS, windows, macOS
- [x] `./run_local.sh` (Chrome) and `./run_linux.sh` (Linux desktop) run scripts
- [x] All 5 nav tabs reachable, no errors

---

### 1.2 — Supabase Auth: Register ✅

- [x] `handle_new_auth_user` trigger in `sql/schema.sql` — syncs `auth.users` → `public.users` on every signup, also fires `trg_auto_create_wallet`
- [x] `RegisterPage` — email, password, confirm password, role selector
- [x] `AuthRepository` — `register()`, `signIn()`, `signOut()`, `sendPasswordReset()`, `resendVerification()`, `markEmailVerified()`
- [x] `AuthBloc` — `AuthInitial`, `AuthLoading`, `AuthSuccess`, `AuthError`, `AuthPasswordResetSent`, `AuthVerificationResent`
- [x] `getIt<AuthRepository>()` typed correctly in all auth pages
- [x] On register success → navigates to `VerifyEmailPage`

---

### 1.3 — Auth: Email Verification ✅

- [x] `VerifyEmailPage` — "Check your inbox" UI with Resend button
- [x] Calls `supabase.auth.resend(type: OtpType.signup, email: email)`
- [x] `markEmailVerified()` updates `users.email_verified = TRUE`
- [x] Local dev: seed users pre-confirmed via `email_confirmed_at = NOW()` in `sql/seed.sql`

---

### 1.4 — Auth: Login ✅

- [x] `LoginPage` — email + password, Sign In button, links to Register + Forgot Password
- [x] Checks `emailConfirmedAt` → `VerifyEmailPage` if null, `Dashboard` if confirmed
- [x] Error snackbar on invalid credentials
- [x] Navigates to Dashboard after successful login

---

### 1.5 — Auth: Password Reset ✅

- [x] `ForgotPasswordPage` — email input, Send Reset button
- [x] `AuthRepository.sendPasswordReset()` → `supabase.auth.resetPasswordForEmail(email)`
- [x] `AuthPasswordResetSent` state shown on success

---

### 1.6 — Auth State Persistence + GoRouter Guards ✅

- [x] Router `redirect`: unauthenticated → `/auth/login`, unverified → `/auth/verify-email`, verified → proceed
- [x] `SplashPage` checks `currentSession` → routes correctly after 1s delay
- [x] Session persists across app restarts

---

### 1.7 — Splash + Onboarding ✅

- [x] `SplashPage` — spinner, auth check, redirect
- [x] `OnboardingPage` — 3 slides with animated dot indicators, colour-matched CTAs
- [x] Responsive via `LayoutBuilder` + `.clamp()` — no overflow on any window size
- [x] `withOpacity` → `withValues(alpha:)` migration across all pages

---

### ✅ Stage 1 Completion Status — VERIFIED

- [x] `flutter test test/features/auth/auth_bloc_test.dart` — **7/7 passing**
- [x] `flutter test integration_test/integration_test.dart -d linux` — **15/15 passing**
- [x] `sql/schema.sql` v3.2 deployed — includes all triggers, RPCs, views, mock functions
- [x] `sql/seed.sql` v2.1 deployed — fixed UUIDs, `$2a$` passwords, all seed users sign in with `Test1234!`
- [x] Register → login → Dashboard flow end-to-end
- [x] Wrong password → error snackbar
- [x] Close app → reopen → stays logged in
- [x] All 5 nav tabs reachable
- [x] Chrome and Linux desktop targets working
- [x] Android desugaring fix applied (`build.gradle.kts`)
- [x] Integration test helper fixed: `127.0.0.1`, real keys, `_initialized` guard

---

## Stage 2 — Core Marketplace

**Outcome:** Two test users complete a full loan cycle: post → bid → accept → disburse → repay.
**Time estimate:** 1.5–2 weeks

> **Note:** `accept_bid`, `mock_top_up`, `mock_disburse`, `mock_repayment` RPCs are already
> in `sql/schema.sql`. No migration files needed for these — just call them from Flutter.

---

### 2.1 — User Profile (Onboarding + Edit)

After first login, check if a `user_profiles` row exists. If not, prompt completion.

```dart
class UserRepository {
  Future<void> createProfile(String userId, UserProfileModel data) async {
    await supabase.from('user_profiles').insert({
      'user_id': userId,
      'first_name': data.firstName,
      'last_name': data.lastName,
      'district': data.district,
      'employment_status': data.employmentStatus,
      'monthly_income': data.monthlyIncome,
    });
  }

  Stream<UserProfileModel?> watchProfile(String userId) {
    return supabase
        .from('user_profiles')
        .stream(primaryKey: ['profile_id'])
        .eq('user_id', userId)
        .map((rows) => rows.isEmpty ? null : UserProfileModel.fromJson(rows.first));
  }
}
```

- [ ] `ProfileSetupPage` — shown after first login if no `user_profiles` row exists
- [ ] `ProfilePage` — display + edit, profile completion percentage
- [ ] Compute `profile_completion_percentage` client-side, UPDATE atomically
- [ ] Privacy: never expose `address_line1/2`, `employer_name`, `business_registration_number`, `id_number`. Only `district` is safe for listing context.

```dart
test('profile completion percentage calculated correctly', () {
  final pct = ProfileCompletion.calculate(
    hasName: true, hasAddress: true, hasEmployment: true,
    hasIncome: false, hasBusiness: false,
  );
  expect(pct, 60);
});
```

```dart
// integration_test
testWidgets('creating profile sets profile_completed when all required fields filled', (tester) async {
  await setupSupabaseLocal();
  await signInTestUser('david.mukasa@gmail.com'); // UUID: ...000001
  final uid = supabase.auth.currentUser!.id;
  await supabase.from('user_profiles').insert({
    'user_id': uid, 'first_name': 'Test', 'last_name': 'User',
    'district': 'Central', 'country': 'Uganda',
    'employment_status': 'employed', 'employer_name': 'Test Corp',
    'monthly_income': 3000000, 'profile_completed': true,
    'profile_completion_percentage': 100,
  });
  final row = await supabase.from('user_profiles').select().eq('user_id', uid).single();
  expect(row['profile_completed'], true);
});
```

---

### 2.2 — Wallet Screen

Three segregated pools. Never blend or aggregate these columns.

```dart
class WalletRepository {
  Stream<WalletModel> watchWallet(String userId) {
    return supabase
        .from('wallet_balances')
        .stream(primaryKey: ['wallet_id'])
        .eq('user_id', userId)
        .map((rows) => WalletModel.fromJson(rows.first));
  }
}
```

- [ ] `WalletPage` — three distinct balance cards:
  - 💰 **Lendable Balance** (`lendable_balance`) — "Your deposited funds. Available to lend."
  - 🔒 **Locked for Repayment** (`locked_repayment`) — "Reserved for active loan repayments."
  - 🚫 **Borrowed Funds** (`non_lendable_borrowed`) — "Received from loans. Cannot be lent."
- [ ] ℹ️ tooltip per card
- [ ] Transaction history from `disbursements` + `repayment_transactions`
- [ ] Real-time via `wallet_balances` stream

```dart
testWidgets('WalletPage shows all three balance types', (tester) async {
  final wallet = WalletModel(lendableBalance: 3000000, lockedRepayment: 2000000, nonLendableBorrowed: 0);
  await tester.pumpWidget(WalletPage(wallet: wallet));
  expect(find.text('UGX 3,000,000'), findsOneWidget);
  expect(find.text('UGX 2,000,000'), findsOneWidget);
  expect(find.text('UGX 0'), findsOneWidget);
});
```

---

### 2.3 — Mock Top-Up

> `mock_top_up(p_user_id, p_amount)` RPC already in `sql/schema.sql`. No migration needed.

```dart
Future<void> mockTopUp(String userId, double amount) async {
  await supabase.rpc('mock_top_up', params: {'p_user_id': userId, 'p_amount': amount});
}
```

- [ ] "Add Funds (Test)" button on Wallet screen — clearly labelled MVP mock
- [ ] Bottom sheet: amount input → Confirm
- [ ] On success: `lendable_balance` increases, audit log row written

```dart
testWidgets('mock top-up increments lendable_balance only', (tester) async {
  await setupSupabaseLocal();
  await signInTestUser('lucy.nambi@yahoo.com'); // UUID: ...000012, starts at 0
  final uid = supabase.auth.currentUser!.id;
  final before = await getLendableBalance(uid);
  await supabase.rpc('mock_top_up', params: {'p_user_id': uid, 'p_amount': 500000});
  expect(await getLendableBalance(uid), before + 500000);
  expect(await getLockedRepayment(uid), 0);
  expect(await getNonLendableBorrowed(uid), 0);
});
```

---

### 2.4 — Create Loan Request

DB enforces: KYC gate, active borrower gate, field constraints.

```dart
class LoanRepository {
  Future<String> createLoanRequest(CreateLoanRequestDto dto) async {
    final result = await supabase.from('loan_requests').insert({
      'borrower_id': dto.borrowerId,
      'requested_amount': dto.requestedAmount,
      'purpose': dto.purpose,
      'purpose_description': dto.purposeDescription,
      'duration_months': dto.durationMonths,
      'max_interest_rate': dto.maxInterestRate,
      'status': 'draft',
    }).select('request_id').single();
    return result['request_id'] as String;
  }

  Future<void> publishLoanRequest(String requestId) async {
    final settings = await supabase.from('system_settings')
        .select('setting_value').eq('setting_key', 'listing_duration_days').single();
    final days = int.parse(settings['setting_value'] as String);
    final now = DateTime.now();
    await supabase.from('loan_requests').update({
      'status': 'active',
      'listed_at': now.toIso8601String(),
      'expires_at': now.add(Duration(days: days)).toIso8601String(),
    }).eq('request_id', requestId);
  }
}
```

- [ ] Form: amount, duration, max rate, purpose, description
- [ ] Create as `draft`; separate "Publish" transitions to `active`
- [ ] Client-side validation mirrors DB constraints (from `system_settings`)
- [ ] Show DB trigger error if KYC not approved

```dart
group('LoanRequestValidator', () {
  test('rejects amount below min_loan_amount', () {
    final r = LoanRequestValidator.validate(amount: 50000, settings: {'min_loan_amount': 100000.0});
    expect(r.error, contains('100,000'));
  });
  test('rejects duration above max_loan_duration', () {
    final r = LoanRequestValidator.validate(durationMonths: 40, settings: {'max_loan_duration': 36.0});
    expect(r.error, contains('36'));
  });
});
```

```dart
// integration_test — KYC trigger enforcement
testWidgets('loan creation blocked for user with pending KYC', (tester) async {
  await setupSupabaseLocal();
  await signInTestUser('alice.namuli@gmail.com'); // UUID: ...000014, KYC pending
  expect(
    () async => await supabase.from('loan_requests').insert({
      'borrower_id': supabase.auth.currentUser!.id,
      'requested_amount': 500000, 'purpose': 'Test', 'duration_months': 6, 'status': 'draft',
    }),
    throwsA(predicate((e) => e.toString().contains('KYC approval required'))),
  );
});
```

---

### 2.5 — Loan Marketplace (Anonymised Listing)

> `v_loan_listings` view already in `sql/schema.sql`. No migration needed.

```dart
class LoanRepository {
  Stream<List<LoanListingModel>> watchMarketplace() {
    return supabase
        .from('v_loan_listings')
        .stream(primaryKey: ['request_id'])
        .map((rows) => rows.map((r) => LoanListingModel.fromJson(r)).toList());
  }
}
```

- [ ] `MarketplacePage` — real-time list from `v_loan_listings`
- [ ] Filter bar: purpose, district, amount range, max rate, risk category
- [ ] Shimmer loading, Lottie empty state
- [ ] Confirm `borrower_id` is NEVER present in any response

```dart
// integration_test
testWidgets('v_loan_listings does not expose borrower_id', (tester) async {
  await setupSupabaseLocal();
  await signInTestUser('invest@pearlcapital.ug'); // any authenticated user
  final rows = await supabase.from('v_loan_listings').select();
  for (final row in rows) {
    expect(row.containsKey('borrower_id'), false);
    expect(row.containsKey('credit_score_band'), true);
    expect(row.containsKey('district'), true);
  }
  // Only active/partially_funded loans appear
  for (final row in rows) {
    expect(['active', 'partially_funded'].contains(row['status']), true);
  }
});
```

---

### 2.6 — Loan Detail

- [ ] `LoanDetailPage` — anonymised pre-bid, real-time bid stream
- [ ] Anonymised bids: amount, rate, lender reputation tier — NOT name
- [ ] "Place Bid" button — non-borrower users only
- [ ] "Accept Bid" button — borrower only
- [ ] Funding progress bar, expiry countdown

```dart
testWidgets('Place Bid button hidden from loan owner', (tester) async {
  final loan = LoanDetailModel(requestId: 'r1', borrowerId: 'current-uid');
  await tester.pumpWidget(LoanDetailPage(loan: loan, currentUserId: 'current-uid'));
  expect(find.text('Place Bid'), findsNothing);
});
```

---

### 2.7 — Place Bid

`lendable_balance` only decreases on bid **acceptance**, not placement.

```dart
class BidRepository {
  Future<void> placeBid({
    required String requestId, required String lenderId,
    required double amount, required double interestRate,
  }) async {
    final wallet = await supabase.from('wallet_balances')
        .select('lendable_balance').eq('user_id', lenderId).single();
    if ((wallet['lendable_balance'] as num) < amount) {
      throw InsufficientFundsException(available: (wallet['lendable_balance'] as num).toDouble(), required: amount);
    }
    await supabase.from('bids').insert({
      'request_id': requestId, 'lender_id': lenderId,
      'bid_amount': amount, 'interest_rate': interestRate, 'status': 'pending',
    });
  }
}
```

- [ ] Bottom sheet: amount + rate inputs
- [ ] Client-side: amount ≤ `lendable_balance`, rate ≤ `max_interest_rate`, not own loan
- [ ] User-friendly error from Postgres trigger exception
- [ ] Realtime wallet update on success

```dart
group('BidValidator', () {
  test('rejects bid exceeding lendable balance', () {
    final r = BidValidator.validate(bidAmount: 600000, lendableBalance: 500000, maxRate: 15, bidRate: 12, isBorrowerOwn: false);
    expect(r.isValid, false);
    expect(r.error, contains('Insufficient'));
  });
  test('rejects bid on own loan', () {
    final r = BidValidator.validate(bidAmount: 100000, lendableBalance: 500000, maxRate: 15, bidRate: 12, isBorrowerOwn: true);
    expect(r.isValid, false);
  });
  test('accepts valid bid', () {
    final r = BidValidator.validate(bidAmount: 100000, lendableBalance: 500000, maxRate: 15, bidRate: 12, isBorrowerOwn: false);
    expect(r.isValid, true);
  });
});
```

```dart
// integration_test
testWidgets('placing bid does NOT lock funds — only acceptance does', (tester) async {
  await setupSupabaseLocal();
  await signInTestUser('contact@kampalatech.ug'); // UUID: ...000007, 3M lendable
  final lenderId = supabase.auth.currentUser!.id;
  final lendableBefore = await getLendableBalance(lenderId);

  // Frank's loan — no bids in seed
  final loan = await supabase.from('loan_requests')
      .select('request_id')
      .eq('borrower_id', '10000000-0000-0000-0000-000000000011') // frank
      .eq('status', 'active').single();

  await supabase.from('bids').insert({
    'request_id': loan['request_id'], 'lender_id': lenderId,
    'bid_amount': 500000, 'interest_rate': 12.0, 'status': 'pending',
  });

  // lendable_balance unchanged — funds only lock on acceptance
  expect(await getLendableBalance(lenderId), lendableBefore);
});
```

---

### 2.8 — My Loans

- [ ] Borrower tab: `loan_requests WHERE borrower_id = uid` — grouped by status
- [ ] Lender tab: `bids JOIN loan_requests WHERE bids.lender_id = uid` — grouped by bid status
- [ ] Tap → `LoanDetailPage` or bid detail sheet

---

### 2.9 — Accept Bid + Contract Creation

> `accept_bid(p_request_id, p_bid_id, p_borrower_id)` RPC already in `sql/schema.sql`.

```dart
Future<String> acceptBid({
  required String requestId,
  required String bidId,
  required String borrowerId,
}) async {
  return await supabase.rpc('accept_bid', params: {
    'p_request_id': requestId,
    'p_bid_id': bidId,
    'p_borrower_id': borrowerId,
  }) as String;
}
```

- [ ] "Accept Bid" button on `LoanDetailPage` (borrower only)
- [ ] Confirmation bottom sheet showing bid terms
- [ ] On success: navigate to `ContractPage`

```dart
// integration_test — most important test in Stage 2
// DO NOT proceed to 2.10 until this passes completely
testWidgets('accepting bid creates contract, locks lender funds, transitions loan status', (tester) async {
  await setupSupabaseLocal();
  await signInTestUser('maria.nakato@gmail.com'); // UUID: ...000004

  // Maria's active loan — 1 pending bid from GreenLeaf in seed
  final loan = await supabase.from('loan_requests')
      .select('request_id')
      .eq('borrower_id', '10000000-0000-0000-0000-000000000004')
      .eq('status', 'active').single();
  final bid = await supabase.from('bids')
      .select('bid_id')
      .eq('request_id', loan['request_id'])
      .eq('status', 'pending').single();

  final greenLeafId = '10000000-0000-0000-0000-000000000006';
  final lendableBefore = await getLendableBalance(greenLeafId);
  final lockedBefore   = await getLockedRepayment(greenLeafId);

  final contractId = await supabase.rpc('accept_bid', params: {
    'p_request_id': loan['request_id'],
    'p_bid_id': bid['bid_id'],
    'p_borrower_id': '10000000-0000-0000-0000-000000000004',
  });
  expect(contractId, isNotNull);

  final updatedLoan = await supabase.from('loan_requests').select().eq('request_id', loan['request_id']).single();
  expect(updatedLoan['status'], 'contracted');

  final contract = await supabase.from('loan_contracts').select().eq('contract_id', contractId).single();
  expect(contract['status'], 'draft');
  expect(contract['borrower_id'], '10000000-0000-0000-0000-000000000004');

  final cb = await supabase.from('contract_bids').select().eq('contract_id', contractId);
  expect(cb.length, 1);

  // trg_fn_lock_funds_on_accept fired: lendable ↓, locked ↑
  expect(await getLendableBalance(greenLeafId), lendableBefore - 1500000);
  expect(await getLockedRepayment(greenLeafId), lockedBefore + 1500000);
});
```

---

### 2.10 — Contract View + Signing

```dart
class ContractRepository {
  Future<void> borrowerSign(String contractId, String signerIp) async {
    await supabase.from('loan_contracts').update({
      'borrower_signed': true,
      'borrower_signed_at': DateTime.now().toIso8601String(),
      'borrower_signature_ip': signerIp,
    }).eq('contract_id', contractId);
  }

  Future<void> lenderSign(String contractBidId, String signerIp) async {
    await supabase.from('contract_bids').update({
      'lender_signed': true,
      'lender_signed_at': DateTime.now().toIso8601String(),
      'lender_signature_ip': signerIp,
    }).eq('contract_bid_id', contractBidId);
    // trg_fn_check_all_lenders_signed fires → auto-activates if all signed
  }

  Future<void> generateRepaymentSchedule(String contractId) async {
    await supabase.rpc('sp_calculate_repayment_schedule', params: {'p_contract_id': contractId});
  }
}
```

- [ ] `ContractPage` — terms, party statuses, Sign button
- [ ] After both sign: call `generateRepaymentSchedule`, show "Contract Active"

```dart
testWidgets('after both parties sign contract activates and schedule generates', (tester) async {
  // ... create contract via accept_bid, both sign, schedule generated ...
  final installments = await supabase.from('loan_repayments').select().eq('contract_id', contractId);
  expect(installments.length, greaterThan(0));
});
```

---

### 2.11 — Mock Disbursement

> `mock_disburse(p_contract_id, p_bid_id)` RPC already in `sql/schema.sql`.

```dart
Future<void> mockDisburse(String contractId, String bidId) async {
  await supabase.rpc('mock_disburse', params: {
    'p_contract_id': contractId,
    'p_bid_id': bidId,
  });
}
```

- [ ] "Disburse (Mock)" button on ContractPage after activation
- [ ] `trg_fn_credit_borrower_on_disbursement` fires → borrower `non_lendable_borrowed` ↑

```dart
testWidgets('disbursement credits borrower non_lendable_borrowed only', (tester) async {
  final borrowerId = '10000000-0000-0000-0000-000000000004'; // maria
  final nlbBefore = await getNonLendableBorrowed(borrowerId);
  final lendableBefore = await getLendableBalance(borrowerId);
  await supabase.rpc('mock_disburse', params: {'p_contract_id': contractId, 'p_bid_id': bidId});
  expect(await getNonLendableBorrowed(borrowerId), nlbBefore + 1500000);
  expect(await getLendableBalance(borrowerId), lendableBefore); // unchanged
});
```

---

### 2.12 — Repayment

> `mock_repayment(p_repayment_id, p_amount_paid)` RPC already in `sql/schema.sql`.

```dart
Future<void> mockRepayment(String repaymentId, double amount) async {
  await supabase.rpc('mock_repayment', params: {
    'p_repayment_id': repaymentId,
    'p_amount_paid': amount,
  });
}
```

- [ ] `RepaymentSchedulePage` — list of installments, status indicators
- [ ] "Mark as Paid" per installment (MVP mock)
- [ ] `trg_fn_debit_borrower_on_repayment` fires → borrower balances ↓
- [ ] `trg_fn_update_contract_on_repayment` fires → `outstanding_balance` updated

---

### 2.13 — Reputation Score Recalculation

> `sp_calculate_reputation_score(p_user_id)` already in `sql/schema.sql`.

```dart
class ReputationRepository {
  Future<void> recalculate(String userId) async {
    final newScore = await supabase.rpc(
      'sp_calculate_reputation_score', params: {'p_user_id': userId},
    ) as int;
    await supabase.from('users').update({'reputation_score': newScore}).eq('user_id', userId);
    // trg_sync_reputation_tier auto-updates reputation_tier
  }
}
```

Call after: repayment paid, contract completed, contract defaulted.

---

### ✅ Stage 2 Completion Checklist

- [ ] `flutter test test/` — all unit tests green
- [ ] `flutter test integration_test/integration_test.dart -d linux` — all pass
- [ ] Seed user creates loan → appears anonymised in marketplace
- [ ] Lender places bid → pending, `lendable_balance` unchanged
- [ ] Borrower accepts bid → contract created, funds locked, loan `contracted`
- [ ] Both parties sign → contract activated, repayment schedule generated
- [ ] Mock disburse → borrower `non_lendable_borrowed` increases
- [ ] Mark repayment paid → both wallets update correctly
- [ ] Reputation recalculated after contract event
- [ ] `borrower_id` never appears in marketplace API response

---

## Stage 3 — Polish & Supporting Features

**Outcome:** App feels complete. Notifications, KYC, PDF contracts, analytics, biometrics, offline.
**Time estimate:** 1 week

---

### 3.1 — In-App Notifications

```dart
class NotificationRepository {
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return supabase.from('notifications').stream(primaryKey: ['notification_id'])
        .eq('user_id', userId).order('created_at', ascending: false)
        .map((rows) => rows.map((r) => NotificationModel.fromJson(r)).toList());
  }

  Future<void> writeNotification({required String userId, required String type,
    required String title, required String message, Map<String, dynamic>? data}) async {
    await supabase.from('notifications').insert({
      'user_id': userId, 'type': type, 'title': title, 'message': message, 'data': data,
    });
  }

  Future<void> markRead(String notificationId) async {
    await supabase.from('notifications')
        .update({'read': true, 'read_at': DateTime.now().toIso8601String()})
        .eq('notification_id', notificationId);
  }
}
```

Write notifications when: bid placed (`bid_received`), bid accepted (`bid_accepted`),
contract activated (`contract_active`), repayment due in 3 days (`repayment_due`).

- [ ] `NotificationsPage` — real-time feed, mark read, deep-link via `data` JSONB
- [ ] Unread badge on bottom nav

---

### 3.2 — KYC Document Upload

```dart
class KycRepository {
  static const _columnMap = {
    'id_front': 'id_front_url', 'id_back': 'id_back_url',
    'selfie': 'selfie_url', 'proof_of_address': 'proof_of_address_url',
  };

  Future<void> uploadDocument({required String userId, required File file, required String docType}) async {
    final path = '$userId/$docType-${DateTime.now().millisecondsSinceEpoch}.jpg';
    await supabase.storage.from('kyc-documents').upload(path, file);
    final url = supabase.storage.from('kyc-documents').getPublicUrl(path);
    await supabase.from('kyc_verifications').upsert({
      'user_id': userId, 'status': 'pending',
      _columnMap[docType]!: url, 'submitted_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  }
}
```

- [ ] `KycPage` — upload UI, status chip
- [ ] Realtime on `kyc_verifications` — chip updates within 3s of admin approval
- [ ] Admin: Studio → `kyc_verifications` → set `status = 'approved'`, `verified_at`, `expires_at`

---

### 3.3 — Contract PDF Generation

- [ ] Generate PDF from `loan_contracts` + `contract_bids` + `user_profiles` (post-contract)
- [ ] Upload to Supabase Storage → `loan_contracts.contract_document_url`
- [ ] `flutter_pdfview` for in-app display

---

### 3.4 — Risk Assessment Display

- [ ] `RiskProfilePage` — credit score **band** only (never raw integer), risk category, `valid_until`
- [ ] Band helper matches `v_loan_listings` CASE logic in `sql/schema.sql`

---

### 3.5 — System Settings Read

```dart
class SystemSettingsRepository {
  Future<Map<String, dynamic>> getPublicSettings() async {
    final rows = await supabase.from('system_settings')
        .select('setting_key, setting_value, setting_type').eq('is_public', true);
    return {for (final r in rows) r['setting_key']: _parse(r)};
  }
  dynamic _parse(Map row) => switch (row['setting_type']) {
    'number' => double.parse(row['setting_value'] as String),
    'boolean' => row['setting_value'] == 'true',
    _ => row['setting_value'],
  };
}
```

- [ ] Fetch at app startup, cache in GetIt singleton
- [ ] Use in `LoanRequestValidator` and `BidValidator`

---

### 3.6 — Analytics + Dashboard

Use existing views in `sql/schema.sql`:
`v_loan_performance`, `v_user_portfolio`, `v_lender_investments`

- [ ] `DashboardPage` — pull `v_user_portfolio` for logged-in user (replace placeholder card)
- [ ] `AnalyticsPage` — `fl_chart` charts from views

---

### 3.7 — Audit Log Read (Admin)

- [ ] `AdminDashboardPage` — read-only `audit_logs` surface
- [ ] Write audit rows from client code on every write operation

---

### 3.8 — Biometric Login

- [ ] `local_auth` prompt on splash if biometrics enabled
- [ ] Preference in Hive

---

### 3.9 — Offline Cache (Hive)

- [ ] Cache: marketplace listing, own loans, wallet snapshot
- [ ] "Last updated X ago" banner when offline
- [ ] Block writes while offline

---

### ✅ Stage 3 Completion Checklist

- [ ] Bid placed → notification on borrower device in real time
- [ ] KYC uploaded → `status = 'pending'`; admin approves → chip updates within 3s
- [ ] Contract PDF generated, readable, correct parties/amounts
- [ ] Analytics charts render with live view data
- [ ] `DashboardPage` shows live `v_user_portfolio` data
- [ ] Biometrics prompt on launch
- [ ] Wifi off → "Offline" banner + cached marketplace

---

## Stage 4 — External Integrations + Sandbox APIs

**Only after Stages 1–3 complete and all tests pass.**

### 4.1 — Edge Functions

Move RPCs to Edge Functions one at a time: `accept-bid`, `place-bid`, `process-repayment`, `calculate-risk-score`, `send-notification`, `generate-contract`.

### 4.2 — MTN Mobile Money

Replace `mock_top_up` / `mock_disburse` with MTN MoMo Collection and Disbursement APIs.

| Sandbox test number | Behaviour |
| --- | --- |
| `46733123450` | Always succeeds |
| `46733123451` | Always fails |
| `46733123452` | Timeout |

### 4.3 — Airtel Money Sandbox

### 4.4 — Africa's Talking SMS

### 4.5 — KYC Verification API (Smile Identity)

### 4.6 — Push Notifications (FCM)

### ✅ Stage 4 Completion Checklist

- [ ] All Edge Functions deployed, tested with `supabase functions serve`
- [ ] MTN MoMo sandbox: success, failure, timeout tested
- [ ] All Stage 1–3 integration tests still pass after every switch
- [ ] `kDebugMode` sandbox/production URL switches confirmed before go-live

---

## Summary

| Stage | What you build | External deps | Cost |
| --- | --- | --- | --- |
| 1 ✅ | Auth, routing, scaffold | None | Free |
| 2 | Full marketplace (real schema, mock payments) | None | Free |
| 3 | KYC, PDF, notifications, analytics, biometrics | None | Free |
| 4 | Real payments, Edge Functions, push, KYC API | MTN, Airtel, AT, Smile ID | API costs only |

You can build and fully test a complete lending marketplace through Stage 3 without spending anything, without touching a single external API, and with every flow verified against the production schema.
