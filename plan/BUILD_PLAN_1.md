# Nipanze — MVP Build Plan

> **Stack:** Flutter + Supabase (free tier) + Supabase CLI Local Stack
> **Database:** The production `schema.sql` (19 tables) is the single source of truth — no simplified schema, no SQLite.
> **Seed data:** `seed.sql` + `seed_patch.sql` pre-populate the local stack for realistic testing.
> **Goal:** A fully testable end-to-end marketplace before a single external API is touched.

---

## Ground Rules

1. **Schema first, always.** The production `schema.sql` deploys on `supabase db reset`. Never simplify the schema for the app layer — work with what the DB enforces.

2. **Seed data is your test fixture.** `seed.sql` + `seed_patch.sql` give you 18 users, 6 loan requests, 10 bids, and reconciled wallet states. Load them after every `supabase db reset`.

3. **Triggers and functions are already implemented.** The DB enforces KYC gates, balance checks, tier sync, repayment schedules, and contract activation. Your Flutter code calls DB functions and reacts to results — it does not reimplement this logic.

4. **No Edge Functions until Stage 4.** All mutations in Stages 1–3 go through Postgres RPCs (already defined in the schema). Edge Functions wrap those same RPCs for server-side enforcement in production.

5. **Mock everything external in Stages 1–3.** Wallet top-up = a button that calls a Postgres RPC. Repayment = a "mark paid" button. KYC = admin sets `kyc_verifications.status = 'approved'` in Studio. Replace each mock one at a time in Stage 4.

6. **One feature fully working before starting the next.** Don't scaffold everything and wire it up later. Auth must be completely done before touching loans.

7. **Test as you build, not after.** Every task has a test. Don't move to the next task until the current one passes.

---

## Schema Quick Reference

The full schema lives in `sql/schema.sql`. and the seed `sql/schema.sql` in Key tables for each feature:

| Feature | Primary Tables |
|---|---|
| Auth & identity | `users`, `user_profiles`, `refresh_tokens`, `email_verification_tokens`, `password_reset_tokens` |
| KYC | `kyc_verifications` |
| Risk & credit | `risk_assessments` |
| Wallet | `wallet_balances` |
| Loan marketplace | `loan_requests`, `bids` |
| Contracts | `loan_contracts`, `contract_bids` |
| Payments | `disbursements`, `loan_repayments`, `repayment_transactions` |
| Platform | `audit_logs`, `notifications`, `user_notes`, `system_settings` |

Key DB-enforced rules your app must respect:

- `trg_fn_require_kyc_for_loan` — blocks `loan_requests` INSERT if no `kyc_verifications` row with `status='approved'`
- `trg_fn_require_active_borrower` — blocks `loan_requests` INSERT if `users.status != 'active'`
- `trg_fn_enforce_lendable_on_bid` — blocks `bids` INSERT if `wallet_balances.lendable_balance < bid_amount`
- `trg_fn_lock_funds_on_accept` — on bid UPDATE to `accepted`: moves funds from `lendable_balance` to `locked_repayment`
- `trg_fn_credit_borrower_on_disbursement` — on disbursement UPDATE to `completed`: credits `non_lendable_borrowed` only
- `trg_fn_check_all_lenders_signed` — auto-activates contract when all `contract_bids.lender_signed = TRUE`
- `fn_score_to_tier` — pure mapping function; `trg_sync_reputation_tier` calls it on every `users.reputation_score` UPDATE

---

## Testing Strategy Overview

| Layer | Tool | When | What |
|---|---|---|---|
| Unit | `flutter_test` | Every stage | BLoC states, repository logic, score formulas, validators |
| Widget | `flutter_test` | Every stage | UI renders, buttons fire events, forms validate |
| Integration | Local stack + `integration_test` | Stages 2–4 | Full user flows against real Postgres |
| Sandbox | Provider sandbox APIs | Stage 4 only | MTN MoMo, Africa's Talking, KYC provider |

```bash
# Install test packages
flutter pub add --dev flutter_test
flutter pub add --dev integration_test
flutter pub add --dev mocktail
```

```bash
# Unit + widget (no local stack needed)
flutter test

# Single test file
flutter test test/features/auth/auth_bloc_test.dart

# Integration (local stack must be running)
supabase start
flutter test integration_test/

# Coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## Environment Setup (Do This First)

```bash
# 1. Install tools
brew install supabase/tap/supabase   # macOS
# Docker Desktop must be installed and running

# 2. Create Flutter project
flutter create nipanze --platforms android,ios,web,linux
cd nipanze

# 3. Install packages
flutter pub add supabase_flutter
flutter pub add flutter_bloc go_router get_it injectable flutter_secure_storage
flutter pub add reactive_forms animate_do lottie smooth_page_indicator
flutter pub add --dev injectable_generator build_runner mocktail

# 4. Initialise Supabase
supabase init

# 5. Start local stack (keep this terminal open during dev)
supabase start
# Prints: API URL, Anon Key, Studio URL (http://localhost:54323), DB URL

# 6. Apply schema and seed data
psql "postgresql://postgres:postgres@localhost:54322/postgres" -f sql/schema.sql
psql "postgresql://postgres:postgres@localhost:54322/postgres" -f sql/seed.sql

```

**`main.dart` environment switch:**

```dart
const useLocalSupabase = true; // flip to false before deploying

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: useLocalSupabase
        ? 'http://localhost:54321'
        : const String.fromEnvironment('SUPABASE_URL'),
    anonKey: useLocalSupabase
        ? 'your-local-anon-key'
        : const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  runApp(const NipanzeApp());
}

final supabase = Supabase.instance.client;
```

**Shared integration test helper:**

```dart
// test/helpers/supabase_test_helper.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> setupSupabaseLocal() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'http://localhost:54321',
    anonKey: 'your-local-anon-key',
  );
}

// Use the service role key for test teardown only — never in production code
final adminClient = SupabaseClient(
  'http://localhost:54321',
  'your-local-service-role-key',
);

Future<void> clearTestData() async {
  // Wipe only rows created by tests (not seed data)
  // Identify test rows by a flag column or known test email prefix
  await adminClient.from('bids')
      .delete()
      .like('lender_id::text', '%')
      .filter('created_at', 'gte', DateTime.now().subtract(Duration(minutes: 5)).toIso8601String());
}

Future<Map<String, dynamic>> signInTestUser(String email, String password) async {
  final res = await supabase.auth.signInWithPassword(email: email, password: password);
  return {'userId': res.user!.id, 'session': res.session};
}
```

**About migrations:** For this project the full `schema.sql` is applied directly on `supabase db reset`. For incremental changes during development, add files to `supabase/migrations/` and run `supabase db push`.

---

## Seed Data Test Accounts

All test users are pre-created in `seed.sql`. After loading, confirm their emails in Studio (`http://localhost:54323 → Authentication → Users → set email_confirmed_at`).

| Email | Role | Notes |
|---|---|---|
| `david.mukasa@gmail.com` | borrower | KYC approved, credit 750, loan fully funded |
| `sarah.namukasa@yahoo.com` | borrower | KYC approved, loan 60% funded |
| `james.okello@outlook.com` | both | KYC approved, loan fully funded, lender |
| `maria.nakato@gmail.com` | borrower | KYC approved, loan active no bids |
| `robert.ssemwanga@gmail.com` | both | KYC approved, lender + draft loan |
| `invest@pearlcapital.ug` | lender | 3,000,000 lendable, 7,000,000 locked |
| `funds@victoriainvest.co.ug` | lender | 3,000,000 lendable, 2,000,000 locked |
| `lending@equatorfinance.ug` | lender | 2,000,000 lendable, 3,000,000 locked |
| `info@greenleafagro.co.ug` | lender | 1,500,000 lendable, pending bid |
| `contact@kampalatech.ug` | lender | 1,000,000 lendable, pending bid |
| `frank.omondi@gmail.com` | borrower | KYC approved, loan active no bids |
| `lucy.nambi@yahoo.com` | both | KYC approved |
| `charles.mwesigwa@gmail.com` | both | KYC approved, 1,200,000 lendable |
| `alice.namuli@gmail.com` | borrower | KYC pending, `pending_verification` status |
| `admin1@nipanze.ug` | admin | Full access |
| `test.user@gmail.com` | borrower | No KYC, no profile — intentionally minimal |

Password for all seed accounts: `Test1234!`

---

## Stage 1 — Foundation

**Outcome:** App launches, auth works completely, every screen is reachable.
**Time estimate:** 3–5 days

---

### 1.1 — Project Scaffold

- [ ] Folder structure: `lib/core/`, `lib/features/`, `lib/shared/`
- [ ] `get_it` + `injectable` — create `injection.dart`, run `build_runner`
- [ ] `AppTheme` — light/dark, brand colour `#1A56DB`, typography (Sora headings + Inter body)
- [ ] `AppRouter` with GoRouter — define all route paths as constants
- [ ] `MainScaffold` with bottom nav (5 tabs: Dashboard, Marketplace, My Loans, Wallet, Profile)
- [ ] Placeholder `Page` widget per tab (centred text label)
- [ ] Confirm app launches, tabs switch, no errors

**Local stack needed:** no

```dart
// test/core/router/app_router_test.dart
testWidgets('all tab routes render placeholder', (tester) async {
  await tester.pumpWidget(MaterialApp.router(routerConfig: AppRouter.router));
  expect(find.byType(MainScaffold), findsOneWidget);
});
```

---

### 1.2 — Supabase Auth: Register

The schema already has `users`, `user_profiles`, and `wallet_balances` tables. A Supabase auth user must map to a `users` row. Add a trigger on `auth.users`:

```sql
-- supabase/migrations/20240101_auth_user_trigger.sql
-- NOTE: The main schema.sql already defines the users table.
-- This trigger bridges auth.users → public.users on registration.
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.users (
    user_id, email, password_hash, role, status,
    email_verified, reputation_score, reputation_tier
  )
  VALUES (
    NEW.id,
    NEW.email,
    '',           -- password managed by Supabase Auth, not this column
    'borrower',
    'pending_verification',
    FALSE,
    50,
    'bronze'
  )
  ON CONFLICT (user_id) DO NOTHING;
  -- trg_auto_create_wallet fires on users INSERT, creates wallet_balances row automatically
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();
```

- [ ] `RegisterPage` — email, password, confirm password, role selector (Borrower / Lender / Both)
- [ ] `AuthRepository` — wraps `supabase.auth.signUp()`
- [ ] `AuthBloc` — states: `AuthInitial`, `AuthLoading`, `AuthSuccess`, `AuthError`
- [ ] On success → navigate to `VerifyEmailPage`

**After register, Studio check:**

- `Authentication → Users` — new user exists
- `Table Editor → users` — row with `status='pending_verification'`, `reputation_tier='bronze'`
- `Table Editor → wallet_balances` — row with all balances = 0 (created by `trg_auto_create_wallet`)

```dart
// test/features/auth/auth_bloc_test.dart
blocTest<AuthBloc, AuthState>(
  'emits [AuthLoading, AuthSuccess] on successful register',
  build: () {
    when(() => mockRepo.register(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async => MockUser());
    return AuthBloc(authRepository: mockRepo);
  },
  act: (b) => b.add(AuthRegisterRequested(email: 'test@test.com', password: 'Test1234!')),
  expect: () => [AuthLoading(), AuthSuccess()],
);
```

```dart
// integration_test/auth/register_test.dart
testWidgets('register creates users row, user_profiles row absent, wallet row present', (tester) async {
  await setupSupabaseLocal();
  // ... navigate and fill form ...
  final userId = supabase.auth.currentUser!.id;

  final userRow = await supabase.from('users').select().eq('user_id', userId).single();
  expect(userRow['status'], 'pending_verification');
  expect(userRow['reputation_tier'], 'bronze');

  final walletRow = await supabase.from('wallet_balances').select().eq('user_id', userId).single();
  expect(walletRow['lendable_balance'], 0);
  expect(walletRow['locked_repayment'], 0);
  expect(walletRow['non_lendable_borrowed'], 0);

  // No user_profile row yet — that's created in Stage 2 (onboarding)
  final profileRows = await supabase.from('user_profiles').select().eq('user_id', userId);
  expect(profileRows.length, 0);
});
```

---

### 1.3 — Auth: Email Verification

- [ ] `VerifyEmailPage` — "Check your inbox" with Resend button (60s cooldown)
- [ ] Calls `supabase.auth.resend(type: OtpType.signup, email: email)`
- [ ] Poll `supabase.auth.currentUser?.emailConfirmedAt` every 3s → on confirmed, UPDATE `users.email_verified = TRUE`, navigate to Dashboard

```dart
// Studio shortcut (avoid waiting for real email during testing):
// Authentication → Users → click user → set email_confirmed_at → Save
// The 3s poll detects it and redirects automatically
```

```dart
testWidgets('shows 60s cooldown after resend tap', (tester) async {
  await tester.pumpWidget(MaterialApp(home: VerifyEmailPage(email: 'test@test.com')));
  await tester.tap(find.text('Resend Email'));
  await tester.pump();
  expect(find.textContaining('59'), findsOneWidget);
});
```

---

### 1.4 — Auth: Login

- [ ] `LoginPage` — email + password, Login button, links to Register + Forgot Password
- [ ] On success: check `emailConfirmedAt` → if null, send to `VerifyEmailPage`; if set, send to Dashboard
- [ ] Handle: invalid credentials, email not confirmed

| Scenario | Expected result |
|---|---|
| Wrong password | "Invalid credentials" shown |
| Email not confirmed | → VerifyEmailPage |
| Valid login | → Dashboard |

---

### 1.5 — Auth: Password Reset

- [ ] `ForgotPasswordPage` — email input, Send Reset button
- [ ] Calls `supabase.auth.resetPasswordForEmail(email)`
- [ ] Success state shown; no actual email sent in local stack (expected)

---

### 1.6 — Auth State Persistence + GoRouter Guards

- [ ] `supabase.auth.onAuthStateChange` stream drives router redirect
- [ ] Unauthenticated → `/auth/login`
- [ ] Authenticated + unverified → `/auth/verify-email`
- [ ] Authenticated + verified → `/dashboard`
- [ ] Reopen app → stays logged in (session persisted)

```dart
redirect: (context, state) {
  final session = supabase.auth.currentSession;
  if (session == null) return '/auth/login';
  if (session.user.emailConfirmedAt == null) return '/auth/verify-email';
  return null;
},
```

---

### 1.7 — Splash + Onboarding

- [ ] `SplashScreen` — logo, 2s delay, check auth → redirect
- [ ] `OnboardingPage` — 3 slides with `smooth_page_indicator`
- [ ] Show once only — `hasSeenOnboarding` flag in Hive

---

### ✅ Stage 1 Completion Checklist

- [ ] `flutter test test/` — all unit + widget tests green
- [ ] `flutter test integration_test/` — local stack running, all pass
- [ ] Register → confirm email in Studio → login → Dashboard
- [ ] Wrong password → correct error message
- [ ] Close app → reopen → stays logged in
- [ ] All 5 nav tabs reachable
- [ ] Studio: `users` row, `wallet_balances` row, no `user_profiles` row

---

## Stage 2 — Core Marketplace

**Outcome:** Two test users complete a full loan cycle: post → bid → accept → disburse → repay.
**Time estimate:** 1.5–2 weeks

---

### 2.1 — User Profile (Onboarding + Edit)

After first login, prompt user to complete `user_profiles`. This is separate from `users` (auth/identity) — profile holds personal, address, employment data.

```dart
// UserRepository methods
Future<void> createProfile(String userId, UserProfileModel data) async {
  await supabase.from('user_profiles').insert({
    'user_id': userId,
    'first_name': data.firstName,
    'last_name': data.lastName,
    'district': data.district,
    'employment_status': data.employmentStatus,
    'monthly_income': data.monthlyIncome,
    // ... other fields
  });
}

Stream<UserProfileModel?> watchProfile(String userId) {
  return supabase
      .from('user_profiles')
      .stream(primaryKey: ['profile_id'])
      .eq('user_id', userId)
      .map((rows) => rows.isEmpty ? null : UserProfileModel.fromJson(rows.first));
}
```

- [ ] `ProfileSetupPage` — shown after first login if no `user_profiles` row exists
- [ ] `ProfilePage` — display + edit profile details, profile completion percentage
- [ ] On update: compute `profile_completion_percentage` client-side, UPDATE both fields atomically

**Privacy note — never expose in UI:** `address_line1/2`, `employer_name`, `business_registration_number`, `id_number`. Only `district` is safe for any listing context.

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
  final uid = supabase.auth.currentUser!.id;

  await supabase.from('user_profiles').insert({
    'user_id': uid,
    'first_name': 'Test', 'last_name': 'User',
    'district': 'Central', 'country': 'Uganda',
    'employment_status': 'employed',
    'employer_name': 'Test Corp',
    'monthly_income': 3000000,
    'profile_completed': true,
    'profile_completion_percentage': 100,
  });

  final row = await supabase.from('user_profiles').select().eq('user_id', uid).single();
  expect(row['profile_completed'], true);
});
```

---

### 2.2 — Wallet Screen

Three segregated pools from `wallet_balances`. Display exactly as the schema defines them — never blend or aggregate these columns.

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
  - 🔒 **Locked for Repayment** (`locked_repayment`) — "Reserved for active loan repayments. Cannot be moved."
  - 🚫 **Borrowed Funds** (`non_lendable_borrowed`) — "Received from loans. Cannot be lent."
- [ ] Each card has an ℹ️ tooltip explaining the balance type
- [ ] Transaction history from `disbursements` + `repayment_transactions` where `borrower_id` or `lender_id = userId`
- [ ] Real-time: subscribe to `wallet_balances` row for userId

```dart
testWidgets('WalletPage shows all three balance types', (tester) async {
  final wallet = WalletModel(
    lendableBalance: 3000000, lockedRepayment: 2000000, nonLendableBorrowed: 0,
  );
  await tester.pumpWidget(WalletPage(wallet: wallet));
  expect(find.text('UGX 3,000,000'), findsOneWidget);
  expect(find.text('UGX 2,000,000'), findsOneWidget);
  expect(find.text('UGX 0'), findsOneWidget);
});

testWidgets('borrowed funds tooltip says cannot be lent', (tester) async {
  await tester.pumpWidget(WalletPage(wallet: mockWallet));
  await tester.tap(find.byKey(const Key('nonLendableInfo')));
  await tester.pump();
  expect(find.textContaining('cannot be lent'), findsOneWidget);
});
```

---

### 2.3 — Mock Top-Up (Replace in Stage 4 with Mobile Money)

Add a Postgres RPC for atomic top-up. This is the MVP replacement for MTN/Airtel in Stages 1–3.

```sql
-- supabase/migrations/20240102_mock_topup.sql
CREATE OR REPLACE FUNCTION mock_top_up(p_user_id UUID, p_amount DECIMAL)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Amount must be positive';
  END IF;

  UPDATE wallet_balances
  SET lendable_balance = lendable_balance + p_amount
  WHERE user_id = p_user_id;

  INSERT INTO audit_logs (
    user_id, event_type, event_category, entity_type, action, description
  ) VALUES (
    p_user_id, 'mock_top_up', 'payment', 'wallet', 'top_up',
    'MVP mock top-up of ' || p_amount || ' UGX'
  );
END;
$$;
```

```dart
Future<void> mockTopUp(String userId, double amount) async {
  await supabase.rpc('mock_top_up', params: {
    'p_user_id': userId,
    'p_amount': amount,
  });
}
```

- [ ] "Add Funds (Test)" button on Wallet screen — clearly labelled as MVP mock
- [ ] Bottom sheet: amount input → Confirm
- [ ] On success: `wallet_balances.lendable_balance` increases, audit log row written

```dart
// integration_test
testWidgets('mock top-up increments lendable_balance only', (tester) async {
  await setupSupabaseLocal();
  final uid = supabase.auth.currentUser!.id;

  final before = await supabase.from('wallet_balances').select().eq('user_id', uid).single();
  final beforeLendable = before['lendable_balance'] as num;

  await supabase.rpc('mock_top_up', params: {'p_user_id': uid, 'p_amount': 500000});

  final after = await supabase.from('wallet_balances').select().eq('user_id', uid).single();
  expect(after['lendable_balance'], beforeLendable + 500000);
  expect(after['locked_repayment'], before['locked_repayment']);         // unchanged
  expect(after['non_lendable_borrowed'], before['non_lendable_borrowed']); // unchanged
});
```

---

### 2.4 — Create Loan Request

The DB enforces:

- `trg_fn_require_kyc_for_loan`: user must have a `kyc_verifications` row with `status='approved'`
- `trg_fn_require_active_borrower`: `users.status` must be `'active'`
- Field constraints: `requested_amount > 0`, `duration_months > 0`, rate 0–100

```dart
class LoanRepository {
  Future<String> createLoanRequest(CreateLoanRequestDto dto) async {
    final result = await supabase
        .from('loan_requests')
        .insert({
          'borrower_id': dto.borrowerId,
          'requested_amount': dto.requestedAmount,
          'purpose': dto.purpose,
          'purpose_description': dto.purposeDescription,
          'duration_months': dto.durationMonths,
          'max_interest_rate': dto.maxInterestRate,
          'status': 'draft',  // borrower publishes manually → 'active'
        })
        .select('request_id')
        .single();
    return result['request_id'] as String;
  }

  Future<void> publishLoanRequest(String requestId) async {
    final settings = await supabase
        .from('system_settings')
        .select('setting_value')
        .eq('setting_key', 'listing_duration_days')
        .single();
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

- [ ] Form: amount, duration, max rate, purpose, description (district auto-filled from `user_profiles`)
- [ ] Create as `draft` first, then separate "Publish" action transitions to `active`
- [ ] Client-side validation mirrors DB constraints
- [ ] Show error from DB trigger if KYC not approved (error message from `trg_fn_require_kyc_for_loan`)

```dart
group('LoanRequestValidator', () {
  test('rejects amount below min_loan_amount system setting', () {
    final result = LoanRequestValidator.validate(
      amount: 50000, systemSettings: {'min_loan_amount': '100000'},
    );
    expect(result.error, contains('100,000'));
  });

  test('rejects duration above max_loan_duration', () {
    final result = LoanRequestValidator.validate(
      durationMonths: 40, systemSettings: {'max_loan_duration': '36'},
    );
    expect(result.error, contains('36'));
  });
});
```

```dart
// integration_test — trigger enforcement
testWidgets('loan creation blocked for user with pending KYC', (tester) async {
  await setupSupabaseLocal();
  // alice.namuli@gmail.com has kyc status='pending'
  // Log in as alice and attempt loan creation
  await supabase.auth.signInWithPassword(
    email: 'alice.namuli@gmail.com', password: 'Test1234!',
  );

  expect(
    () async => await supabase.from('loan_requests').insert({
      'borrower_id': supabase.auth.currentUser!.id,
      'requested_amount': 500000,
      'purpose': 'Test',
      'duration_months': 6,
      'status': 'draft',
    }),
    throwsA(predicate((e) => e.toString().contains('KYC approval required'))),
  );
});
```

---

### 2.5 — Loan Marketplace (Anonymised Listing)

The schema comment specifies exactly which fields are safe to expose:
`request_id, requested_amount, duration_months, max_interest_rate, purpose, district, risk_category, credit_score_band, funding_percentage, number_of_bids, listed_at`

Create a Postgres view to enforce this:

```sql
-- supabase/migrations/20240103_loan_listings_view.sql
CREATE VIEW public.v_loan_listings AS
SELECT
    lr.request_id,
    lr.requested_amount,
    lr.duration_months,
    lr.max_interest_rate,
    lr.purpose,
    up.district,
    ra.risk_category,
    CASE
        WHEN ra.credit_score IS NULL THEN NULL
        WHEN ra.credit_score < 550  THEN '300-549'
        WHEN ra.credit_score < 600  THEN '550-599'
        WHEN ra.credit_score < 650  THEN '600-649'
        WHEN ra.credit_score < 700  THEN '650-699'
        WHEN ra.credit_score < 750  THEN '700-749'
        WHEN ra.credit_score < 800  THEN '750-799'
        ELSE '800-850'
    END AS credit_score_band,
    lr.funding_percentage,
    lr.number_of_bids,
    lr.listed_at,
    lr.status
    -- borrower_id INTENTIONALLY EXCLUDED
FROM loan_requests lr
JOIN user_profiles   up ON lr.borrower_id = up.user_id
LEFT JOIN risk_assessments ra ON lr.borrower_id = ra.user_id AND ra.is_current = TRUE
WHERE lr.status IN ('active', 'partially_funded');
```

```dart
class LoanRepository {
  Stream<List<LoanListingModel>> watchMarketplace({
    String? purposeFilter,
    String? districtFilter,
    String? riskFilter,
    double? maxRate,
  }) {
    var query = supabase
        .from('v_loan_listings')
        .stream(primaryKey: ['request_id']);

    // Realtime streams don't support chained filters directly
    // Apply client-side after stream for MVP; Edge Function in Stage 4
    return query.map((rows) {
      return rows
          .where((r) => purposeFilter == null || r['purpose'] == purposeFilter)
          .where((r) => districtFilter == null || r['district'] == districtFilter)
          .where((r) => riskFilter == null || r['risk_category'] == riskFilter)
          .where((r) => maxRate == null || (r['max_interest_rate'] as num) <= maxRate)
          .map((r) => LoanListingModel.fromJson(r))
          .toList();
    });
  }
}
```

- [ ] `MarketplacePage` — real-time list from `v_loan_listings`
- [ ] Filter bar: purpose, district, amount range, max rate, risk category
- [ ] Shimmer loading, Lottie empty state
- [ ] Confirm `borrower_id` is NEVER present in any response

```dart
test('v_loan_listings does not expose borrower_id', () async {
  await setupSupabaseLocal();
  final rows = await supabase.from('v_loan_listings').select();
  for (final row in rows) {
    expect(row.containsKey('borrower_id'), false);
    expect(row.containsKey('district'), true);
    expect(row.containsKey('credit_score_band'), true);
  }
});
```

---

### 2.6 — Loan Detail

Post-contract, full details are revealed to parties only (enforced by RLS on `loan_requests`). Pre-contract, the detail page shows only the anonymised fields.

- [ ] `LoanDetailPage` — anonymised view pre-bid, real-time bid stream
- [ ] Real-time bids for this loan (anonymised: bid amount, rate, lender tier — NOT lender name)
- [ ] "Place Bid" button — visible only to authenticated non-borrower users
- [ ] "Accept Bid" button — visible only to the borrower (check `borrower_id` via your auth state)
- [ ] Funding progress bar (`funding_percentage`)
- [ ] Expiry countdown (`expires_at`)

```dart
// Real-time bids subscription
final channel = supabase
    .channel('bids-$requestId')
    .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'bids',
      filter: PostgresChangeFilter(
        type: FilterType.eq, column: 'request_id', value: requestId,
      ),
      callback: (payload) => cubit.handleBidChange(payload),
    )
    .subscribe();
```

```dart
testWidgets('Place Bid button hidden from loan owner', (tester) async {
  final loan = LoanDetailModel(requestId: 'r1', borrowerId: 'current-uid');
  await tester.pumpWidget(LoanDetailPage(loan: loan, currentUserId: 'current-uid'));
  expect(find.text('Place Bid'), findsNothing);
});

testWidgets('Accept button visible only to borrower', (tester) async {
  // Other user: button absent
  await tester.pumpWidget(
    LoanDetailPage(loan: loan, currentUserId: 'other-uid', bids: [mockBid]),
  );
  expect(find.text('Accept'), findsNothing);

  // Borrower: button present
  await tester.pumpWidget(
    LoanDetailPage(loan: loan, currentUserId: 'owner-uid', bids: [mockBid]),
  );
  expect(find.text('Accept'), findsOneWidget);
});
```

---

### 2.7 — Place Bid

The DB trigger `trg_fn_enforce_lendable_on_bid` rejects any INSERT where `lendable_balance < bid_amount`. Your client-side validation should match, but the DB is the authoritative gate.

On acceptance (`trg_fn_lock_funds_on_accept`): `lendable_balance` decreases, `locked_repayment` increases. `trg_fn_update_funding_progress` updates `loan_requests.total_bid_amount`, `number_of_bids`, `funding_percentage`, and `status`.

```dart
class BidRepository {
  Future<void> placeBid({
    required String requestId,
    required String lenderId,
    required double amount,
    required double interestRate,
  }) async {
    // Client-side pre-check (mirrors DB trigger)
    final wallet = await supabase
        .from('wallet_balances')
        .select('lendable_balance')
        .eq('user_id', lenderId)
        .single();

    if ((wallet['lendable_balance'] as num) < amount) {
      throw InsufficientFundsException(
        available: wallet['lendable_balance'] as double,
        required: amount,
      );
    }

    // DB trigger fires on INSERT and enforces the same check
    await supabase.from('bids').insert({
      'request_id': requestId,
      'lender_id': lenderId,
      'bid_amount': amount,
      'interest_rate': interestRate,
      'status': 'pending',
    });
  }
}
```

- [ ] Bottom sheet: amount + rate inputs
- [ ] Validate client-side: amount ≤ `lendable_balance`, rate ≤ `max_interest_rate`, not own loan
- [ ] On DB error from trigger: show user-friendly message parsed from Postgres exception
- [ ] On success: wallet updates via Realtime subscription

```dart
group('BidValidator', () {
  test('rejects bid exceeding lendable balance', () {
    final r = BidValidator.validate(
      bidAmount: 600000, lendableBalance: 500000,
      maxRate: 15, bidRate: 12, isBorrowerOwn: false,
    );
    expect(r.isValid, false);
    expect(r.error, contains('Insufficient'));
  });

  test('rejects bid on own loan', () {
    final r = BidValidator.validate(
      bidAmount: 100000, lendableBalance: 500000,
      maxRate: 15, bidRate: 12, isBorrowerOwn: true,
    );
    expect(r.isValid, false);
  });

  test('accepts valid bid', () {
    final r = BidValidator.validate(
      bidAmount: 100000, lendableBalance: 500000,
      maxRate: 15, bidRate: 12, isBorrowerOwn: false,
    );
    expect(r.isValid, true);
  });
});
```

```dart
// integration_test
testWidgets('placing bid decrements lendable_balance, loan funding_percentage increases', (tester) async {
  await setupSupabaseLocal();
  // Sign in as a lender with lendable_balance > 0 (e.g. invest@pearlcapital.ug)
  // Place bid on Maria's active loan (no bids yet in seed)
  // ...

  final wallet = await supabase
      .from('wallet_balances')
      .select()
      .eq('user_id', lenderUid)
      .single();
  // lendable_balance unchanged (bid is pending, lock only fires on acceptance)

  final loan = await supabase
      .from('loan_requests')
      .select()
      .eq('request_id', mariaLoanId)
      .single();
  // Status still 'active' (no acceptance yet)
  expect(loan['number_of_bids'], 1);
});
```

**Note:** `lendable_balance` only decreases when the bid is **accepted** (`trg_fn_lock_funds_on_accept`), not on placement. The trigger fires AFTER UPDATE to `accepted`. Pending bids do not lock funds.

---

### 2.8 — My Loans

- [ ] Borrower tab: `loan_requests WHERE borrower_id = uid` — grouped by status
- [ ] Lender tab: `bids JOIN loan_requests WHERE bids.lender_id = uid` — grouped by bid status
- [ ] Tap loan → `LoanDetailPage`; tap bid → bid detail sheet

```dart
test('lender tab shows bids across all loans', () async {
  await setupSupabaseLocal();
  // robert.ssemwanga has accepted bids on David's and Sarah's loans, plus a pending bid
  final bids = await supabase
      .from('bids')
      .select('*, loan_requests(*)')
      .eq('lender_id', robertUid);
  expect(bids.length, 3); // 3 bids total in seed for Robert
});
```

---

### 2.9 — Accept Bid + Contract Creation

The most critical mutation. Must be atomic. Create a Postgres RPC:

```sql
-- supabase/migrations/20240104_accept_bid.sql
CREATE OR REPLACE FUNCTION accept_bid(
  p_request_id UUID,
  p_bid_id UUID,
  p_borrower_id UUID
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_bid          RECORD;
  v_contract_id  UUID;
  v_weighted_rate DECIMAL(5,2);
  v_total_amount  DECIMAL(15,2);
BEGIN
  -- Fetch the winning bid
  SELECT * INTO v_bid FROM bids WHERE bid_id = p_bid_id AND request_id = p_request_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Bid % not found on request %', p_bid_id, p_request_id;
  END IF;

  -- Accept the winning bid
  UPDATE bids SET status = 'accepted', accepted_at = NOW() WHERE bid_id = p_bid_id;
  -- trg_fn_lock_funds_on_accept fires here: lendable_balance ↓, locked_repayment ↑

  -- Reject all other pending bids (no fund unlock needed — bids are pending, not locked)
  UPDATE bids
  SET status = 'rejected'
  WHERE request_id = p_request_id
    AND bid_id != p_bid_id
    AND status = 'pending';

  -- Create loan contract
  v_total_amount  := v_bid.bid_amount;
  v_weighted_rate := v_bid.interest_rate;

  INSERT INTO loan_contracts (
    request_id, borrower_id,
    total_amount, weighted_interest_rate, duration_months,
    monthly_payment, total_repayment, total_interest,
    status
  )
  SELECT
    p_request_id, p_borrower_id,
    v_total_amount, v_weighted_rate, lr.duration_months,
    -- annuity payment formula
    ROUND(v_total_amount *
      ((v_weighted_rate/100/12) * POWER(1 + v_weighted_rate/100/12, lr.duration_months)) /
      (POWER(1 + v_weighted_rate/100/12, lr.duration_months) - 1), 2),
    ROUND(v_total_amount *
      ((v_weighted_rate/100/12) * POWER(1 + v_weighted_rate/100/12, lr.duration_months)) /
      (POWER(1 + v_weighted_rate/100/12, lr.duration_months) - 1) * lr.duration_months, 2),
    ROUND((v_total_amount *
      ((v_weighted_rate/100/12) * POWER(1 + v_weighted_rate/100/12, lr.duration_months)) /
      (POWER(1 + v_weighted_rate/100/12, lr.duration_months) - 1) * lr.duration_months)
      - v_total_amount, 2),
    'draft'
  FROM loan_requests lr WHERE lr.request_id = p_request_id
  RETURNING contract_id INTO v_contract_id;

  -- Link bid to contract
  INSERT INTO contract_bids (contract_id, bid_id, lender_id, amount, interest_rate)
  VALUES (v_contract_id, p_bid_id, v_bid.lender_id, v_bid.bid_amount, v_bid.interest_rate);

  -- Update loan request status
  UPDATE loan_requests SET status = 'contracted' WHERE request_id = p_request_id;

  RETURN v_contract_id;
END;
$$;
```

- [ ] "Accept Bid" button on `LoanDetailPage` (borrower only)
- [ ] Confirmation bottom sheet showing bid terms
- [ ] Call `supabase.rpc('accept_bid', params: {...})`
- [ ] On success: navigate to `ContractPage` for the new contract

```dart
// integration_test — most important test in the build plan
testWidgets('accepting bid creates contract, locks lender funds, transitions loan status', (tester) async {
  await setupSupabaseLocal();

  // Use Maria's loan (active, 1 pending bid from GreenLeaf Agro in seed)
  final loanResult = await supabase
      .from('loan_requests')
      .select('request_id')
      .eq('borrower_id', mariaNakatoId)
      .eq('status', 'active')
      .single();
  final requestId = loanResult['request_id'];

  final bidResult = await supabase
      .from('bids')
      .select('bid_id')
      .eq('request_id', requestId)
      .eq('status', 'pending')
      .single();
  final bidId = bidResult['bid_id'];

  final walletBefore = await supabase
      .from('wallet_balances')
      .select()
      .eq('user_id', greenLeafId)
      .single();

  final contractId = await supabase.rpc('accept_bid', params: {
    'p_request_id': requestId,
    'p_bid_id': bidId,
    'p_borrower_id': mariaNakatoId,
  });
  expect(contractId, isNotNull);

  // Loan request transitioned
  final loan = await supabase
      .from('loan_requests').select().eq('request_id', requestId).single();
  expect(loan['status'], 'contracted');

  // Contract created in draft
  final contract = await supabase
      .from('loan_contracts').select().eq('contract_id', contractId).single();
  expect(contract['status'], 'draft');
  expect(contract['borrower_id'], mariaNakatoId);

  // contract_bids junction row created
  final cb = await supabase
      .from('contract_bids').select().eq('contract_id', contractId);
  expect(cb.length, 1);

  // Lender funds locked (trg_fn_lock_funds_on_accept fired)
  final walletAfter = await supabase
      .from('wallet_balances').select().eq('user_id', greenLeafId).single();
  expect(
    (walletAfter['locked_repayment'] as num) - (walletBefore['locked_repayment'] as num),
    1500000,  // GreenLeaf's bid amount from seed
  );
  expect(
    (walletAfter['lendable_balance'] as num) - (walletBefore['lendable_balance'] as num),
    -1500000,
  );
});
```

**Do not proceed to 2.10 until this test passes completely.**

---

### 2.10 — Contract View + Signing

After `accept_bid` creates the contract in `draft` status, both parties must sign before it activates.

Activation sequence (from schema comments):

1. Borrower signs → `loan_contracts.borrower_signed = TRUE`
2. Each lender signs → `contract_bids.lender_signed = TRUE`
3. Last lender sign triggers `trg_fn_check_all_lenders_signed` → sets `all_lenders_signed = TRUE`, `contract_activated_at = NOW()`
4. App calls `sp_calculate_repayment_schedule(contract_id)` to generate installments

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
    // trg_fn_check_all_lenders_signed fires and auto-activates if all signed
  }

  Future<void> generateRepaymentSchedule(String contractId) async {
    await supabase.rpc('sp_calculate_repayment_schedule', params: {
      'p_contract_id': contractId,
    });
  }
}
```

- [ ] `ContractPage` — show contract terms, both party statuses, signing buttons
- [ ] "Sign Contract" button — calls appropriate sign method based on current user role
- [ ] After both sign: call `generateRepaymentSchedule`, show "Contract Active" state
- [ ] Contract document displayed post-activation (PDF generated in Stage 3)

```dart
testWidgets('after both parties sign, contract status is active', (tester) async {
  await setupSupabaseLocal();
  final contractId = await supabase.rpc('accept_bid', params: {/*...*/});

  // Borrower signs
  await supabase.from('loan_contracts').update({
    'borrower_signed': true,
    'borrower_signed_at': DateTime.now().toIso8601String(),
  }).eq('contract_id', contractId);

  // Lender signs via contract_bids
  final cb = await supabase
      .from('contract_bids').select('contract_bid_id').eq('contract_id', contractId).single();
  await supabase.from('contract_bids').update({
    'lender_signed': true,
    'lender_signed_at': DateTime.now().toIso8601String(),
  }).eq('contract_bid_id', cb['contract_bid_id']);

  // trg_fn_check_all_lenders_signed should have fired
  final contract = await supabase
      .from('loan_contracts').select().eq('contract_id', contractId).single();
  expect(contract['all_lenders_signed'], true);
  expect(contract['contract_activated_at'], isNotNull);

  // Generate schedule
  await supabase.rpc('sp_calculate_repayment_schedule', params: {'p_contract_id': contractId});

  final installments = await supabase
      .from('loan_repayments').select().eq('contract_id', contractId);
  expect(installments.length, greaterThan(0));
});
```

---

### 2.11 — Mock Disbursement

In the real system, disbursement is a `disbursements` row that a payment provider processes. In MVP, create the row and immediately mark it `completed`:

```sql
CREATE OR REPLACE FUNCTION mock_disburse(p_contract_id UUID, p_bid_id UUID) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_contract RECORD;
  v_bid      RECORD;
BEGIN
  SELECT * INTO v_contract FROM loan_contracts WHERE contract_id = p_contract_id;
  SELECT * INTO v_bid FROM bids WHERE bid_id = p_bid_id;

  -- Create disbursement row
  INSERT INTO disbursements (
    contract_id, bid_id, lender_id, borrower_id,
    amount, payment_method, payment_provider,
    status, initiated_at
  ) VALUES (
    p_contract_id, p_bid_id, v_bid.lender_id, v_contract.borrower_id,
    v_bid.bid_amount, 'wallet', 'mock',
    'pending', NOW()
  );

  -- Immediately complete it (trg_fn_credit_borrower_on_disbursement fires here)
  UPDATE disbursements
  SET status = 'completed', completed_at = NOW()
  WHERE contract_id = p_contract_id AND bid_id = p_bid_id;

  -- Mark contract as disbursed
  UPDATE loan_contracts
  SET disbursed = TRUE, disbursed_at = NOW(), disbursed_amount = v_bid.bid_amount,
      status = 'active'
  WHERE contract_id = p_contract_id;
END;
$$;
```

When `disbursements.status` transitions to `completed`, `trg_fn_credit_borrower_on_disbursement` fires and credits `non_lendable_borrowed` on the borrower's wallet.

```dart
testWidgets('disbursement credits borrower non_lendable_borrowed', (tester) async {
  await setupSupabaseLocal();
  // ... create and sign contract ...

  final borrowerWalletBefore = await supabase
      .from('wallet_balances').select().eq('user_id', borrowerUid).single();

  await supabase.rpc('mock_disburse', params: {
    'p_contract_id': contractId, 'p_bid_id': bidId,
  });

  final borrowerWalletAfter = await supabase
      .from('wallet_balances').select().eq('user_id', borrowerUid).single();

  // non_lendable_borrowed increased, lendable_balance unchanged
  expect(
    (borrowerWalletAfter['non_lendable_borrowed'] as num) -
    (borrowerWalletBefore['non_lendable_borrowed'] as num),
    bidAmount,
  );
  expect(
    borrowerWalletAfter['lendable_balance'],
    borrowerWalletBefore['lendable_balance'],
  );
});
```

---

### 2.12 — Repayment

`loan_repayments` rows were created by `sp_calculate_repayment_schedule`. Display them and handle payment via a mock RPC:

```sql
CREATE OR REPLACE FUNCTION mock_repayment(
  p_repayment_id UUID,
  p_amount_paid  DECIMAL
) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_rep RECORD;
BEGIN
  SELECT * INTO v_rep FROM loan_repayments WHERE repayment_id = p_repayment_id;

  UPDATE loan_repayments
  SET status = 'paid',
      amount_paid = p_amount_paid,
      principal_paid = v_rep.principal_due,
      interest_paid = v_rep.interest_due,
      paid_at = NOW()
  WHERE repayment_id = p_repayment_id;
  -- trg_fn_debit_borrower_on_repayment fires: draws from non_lendable_borrowed first
  -- trg_fn_update_contract_on_repayment fires: updates outstanding_balance
END;
$$;
```

For the lender side, create a `repayment_transactions` row tied to each payment:

```sql
-- Insert a repayment_transaction after mock_repayment call
-- When status → 'completed', trg_fn_release_lender_funds fires:
-- lendable_balance ↑, locked_repayment ↓
```

- [ ] `RepaymentSchedulePage` — list of `loan_repayments` for a contract, status indicators
- [ ] "Mark as Paid" button per installment (mock, MVP only)
- [ ] After payment: borrower `non_lendable_borrowed` decreases, lender `lendable_balance` increases

```dart
testWidgets('marking repayment paid updates borrower and lender balances', (tester) async {
  // ... full contract + disburse setup ...

  final repayment = (await supabase
      .from('loan_repayments')
      .select()
      .eq('contract_id', contractId)
      .order('installment_number')
      .limit(1)).first;

  await supabase.rpc('mock_repayment', params: {
    'p_repayment_id': repayment['repayment_id'],
    'p_amount_paid': repayment['amount_due'],
  });

  // Borrower balance reduced
  final borrower = await supabase
      .from('wallet_balances').select().eq('user_id', borrowerUid).single();
  expect((borrower['non_lendable_borrowed'] as num) < originalNonLendable, true);

  // Contract outstanding_balance reduced (trg_fn_update_contract_on_repayment)
  final contract = await supabase
      .from('loan_contracts').select().eq('contract_id', contractId).single();
  expect(contract['total_repaid'], greaterThan(0));
});
```

---

### 2.13 — Reputation Score Recalculation

The DB has `sp_calculate_reputation_score(user_id)` and `fn_score_to_tier(score)`. Call them after contract events. `trg_sync_reputation_tier` auto-updates `reputation_tier` when `reputation_score` changes.

```dart
class ReputationRepository {
  Future<void> recalculate(String userId) async {
    final newScore = await supabase.rpc(
      'sp_calculate_reputation_score',
      params: {'p_user_id': userId},
    ) as int;

    await supabase.from('users').update({
      'reputation_score': newScore,
      // reputation_tier updated automatically by trg_sync_reputation_tier
    }).eq('user_id', userId);
  }
}
```

Call `recalculate` after:

- Repayment marked paid
- Contract completed (all installments paid)
- Contract defaulted

```dart
test('sp_calculate_reputation_score returns value in 0-100 range', () async {
  await setupSupabaseLocal();
  // david.mukasa has paid loan history in seed
  final score = await supabase.rpc('sp_calculate_reputation_score', params: {
    'p_user_id': davidMukasaId,
  });
  expect(score, greaterThanOrEqualTo(0));
  expect(score, lessThanOrEqualTo(100));
});

test('fn_score_to_tier maps correctly', () async {
  await setupSupabaseLocal();

  for (final pair in [
    [90, 'platinum'], [75, 'gold'], [60, 'silver'],
    [45, 'bronze'], [30, 'restricted'],
  ]) {
    final tier = await supabase.rpc('fn_score_to_tier', params: {'p_score': pair[0]});
    expect(tier, pair[1]);
  }
});
```

---

### ✅ Stage 2 Completion Checklist

- [ ] `flutter test test/` — all unit tests green
- [ ] `flutter test integration_test/` — all integration tests green (local stack running)
- [ ] Register → KYC blocked → seed user (with KYC) creates loan → appears anonymised in marketplace
- [ ] Lender places bid → pending, lendable_balance unchanged, bid visible in real time
- [ ] Borrower accepts bid → contract created, lender funds locked, loan status `contracted`
- [ ] Both parties sign → contract activated, repayment schedule generated
- [ ] Mock disburse → borrower `non_lendable_borrowed` increases
- [ ] Mark repayment paid → both wallet balances update correctly
- [ ] Reputation recalculated after contract event
- [ ] `borrower_id` never appears in any marketplace API response
- [ ] All DB changes visible in Studio at `http://localhost:54323`

---

## Stage 3 — Polish & Supporting Features

**Outcome:** App feels complete. Notifications, KYC, PDF contracts, analytics, biometrics, offline.
**Time estimate:** 1 week

---

### 3.1 — In-App Notifications

The schema has `notifications` table with Realtime enabled. Write notification rows from client code on key events (Edge Functions handle this in Stage 4).

```dart
class NotificationRepository {
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return supabase
        .from('notifications')
        .stream(primaryKey: ['notification_id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map((r) => NotificationModel.fromJson(r)).toList());
  }

  Future<void> writeNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    await supabase.from('notifications').insert({
      'user_id': userId, 'type': type,
      'title': title, 'message': message,
      'data': data,
    });
  }

  Future<void> markRead(String notificationId) async {
    await supabase.from('notifications').update({
      'read': true, 'read_at': DateTime.now().toIso8601String(),
    }).eq('notification_id', notificationId);
  }
}
```

Write notifications in client code when:

- Bid placed → notify borrower (`type: 'bid_received'`, `data: {bid_id, request_id}`)
- Bid accepted → notify lender (`type: 'bid_accepted'`)
- Contract activated → notify both parties (`type: 'contract_active'`)
- Repayment due in 3 days → notify borrower (`type: 'repayment_due'`)

```dart
testWidgets('placing bid creates notification for borrower', (tester) async {
  await setupSupabaseLocal();
  // After calling place_bid...
  final notifs = await supabase
      .from('notifications')
      .select()
      .eq('user_id', borrowerUid)
      .eq('type', 'bid_received');
  expect(notifs.length, 1);
  expect(notifs.first['read'], false);
  expect(notifs.first['data'], contains('bid_id'));
});
```

---

### 3.2 — KYC Document Upload

```dart
class KycRepository {
  Future<void> uploadDocument({
    required String userId,
    required File file,
    required String docType, // 'id_front' | 'id_back' | 'selfie' | 'proof_of_address'
  }) async {
    final path = '$userId/$docType-${DateTime.now().millisecondsSinceEpoch}.jpg';
    await supabase.storage.from('kyc-documents').upload(path, file);
    final url = supabase.storage.from('kyc-documents').getPublicUrl(path);

    // Update the relevant URL column and set status to pending
    final columnMap = {
      'id_front': 'id_front_url',
      'id_back': 'id_back_url',
      'selfie': 'selfie_url',
      'proof_of_address': 'proof_of_address_url',
    };

    await supabase.from('kyc_verifications').upsert({
      'user_id': userId,
      'status': 'pending',
      columnMap[docType]!: url,
      'submitted_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  }
}
```

**Admin KYC approval (local Studio):**

```
http://localhost:54323 → Table Editor → kyc_verifications
→ find user's row → set status = 'approved', verified_at = now(), expires_at = now() + 1 year
```

The Realtime subscription on `kyc_verifications` in the app updates the KYC chip within seconds.

```dart
testWidgets('KYC upload creates/updates kyc_verifications row with status pending', (tester) async {
  await setupSupabaseLocal();
  final uid = supabase.auth.currentUser!.id;

  await KycRepository().uploadDocument(
    userId: uid, file: File('test/assets/test_id.jpg'), docType: 'id_front',
  );

  final row = await supabase
      .from('kyc_verifications').select().eq('user_id', uid).single();
  expect(row['status'], 'pending');
  expect(row['id_front_url'], isNotNull);
});
```

---

### 3.3 — Contract PDF Generation

```bash
flutter pub add pdf printing flutter_pdfview
```

Generate client-side from `loan_contracts` + `contract_bids` + `user_profiles` (revealed post-contract). Upload to Supabase Storage and store URL in `loan_contracts.contract_document_url`.

```dart
test('generated contract PDF is non-empty', () async {
  final contract = ContractModel(
    contractId: 'c1',
    borrowerName: 'David Mukasa',
    lenderName: 'Pearl Capital',
    totalAmount: 5000000,
    interestRate: 11.0,
    durationMonths: 12,
    repaymentSchedule: List.generate(12, (i) => InstallmentModel(
      installmentNumber: i + 1,
      dueDate: DateTime.now().add(Duration(days: 30 * (i + 1))),
      amountDue: 441000,
    )),
  );
  final bytes = await ContractPdfService.generate(contract);
  expect(bytes.lengthInBytes, greaterThan(1000));
});
```

---

### 3.4 — Risk Assessment Display

`risk_assessments` is populated by admin or scoring engine. Display the current assessment to the user (only the band, not the raw score):

```dart
class RiskRepository {
  Future<RiskAssessmentModel?> getCurrentAssessment(String userId) async {
    final result = await supabase
        .from('risk_assessments')
        .select()
        .eq('user_id', userId)
        .eq('is_current', true)
        .maybeSingle();
    return result == null ? null : RiskAssessmentModel.fromJson(result);
  }

  String creditScoreBand(int? score) {
    if (score == null) return 'Not assessed';
    if (score < 550) return '300–549';
    if (score < 600) return '550–599';
    if (score < 650) return '600–649';
    if (score < 700) return '650–699';
    if (score < 750) return '700–749';
    if (score < 800) return '750–799';
    return '800–850';
  }
}
```

- [ ] `RiskProfilePage` — show credit score band, risk category, component scores, valid_until date
- [ ] Never show raw `credit_score` integer — always the band

---

### 3.5 — System Settings Read

`system_settings` is seeded. Fetch public settings at app startup and cache for validators.

```dart
class SystemSettingsRepository {
  Future<Map<String, dynamic>> getPublicSettings() async {
    final rows = await supabase
        .from('system_settings')
        .select('setting_key, setting_value, setting_type')
        .eq('is_public', true);
    return {for (final r in rows) r['setting_key']: _parse(r)};
  }

  dynamic _parse(Map row) {
    return switch (row['setting_type']) {
      'number' => double.parse(row['setting_value'] as String),
      'boolean' => row['setting_value'] == 'true',
      _ => row['setting_value'],
    };
  }
}
```

Use these in `LoanRequestValidator` and `BidValidator` instead of hardcoded constants.

---

### 3.6 — Analytics Dashboard

```bash
flutter pub add fl_chart
```

Use the existing views for data:

- `v_loan_performance` — monthly platform KPIs
- `v_user_portfolio` — user-level borrower + lender aggregates
- `v_lender_investments` — lender portfolio breakdown

```dart
test('v_user_portfolio returns correct column names', () async {
  await setupSupabaseLocal();
  final rows = await supabase.from('v_user_portfolio').select().limit(1);
  expect(rows.first.containsKey('lendable_balance'), true);
  expect(rows.first.containsKey('total_outstanding_debt'), true);
  expect(rows.first.containsKey('active_loans_as_borrower'), true);
});
```

---

### 3.7 — Audit Log Read (Admin)

`audit_logs` is append-only. Surface it in an admin panel or support view.

```dart
class AuditRepository {
  Future<List<AuditLogModel>> getLogsForUser(String userId, {int limit = 50}) async {
    final rows = await supabase
        .from('audit_logs')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map((r) => AuditLogModel.fromJson(r)).toList();
  }
}
```

Write audit log rows from client code for every write operation (Stage 4: Edge Functions handle this automatically).

---

### 3.8 — Biometric Login

```bash
flutter pub add local_auth
```

```dart
testWidgets('biometric prompt shown when setting enabled', (tester) async {
  final mockAuth = MockLocalAuthentication();
  when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
  when(() => mockAuth.authenticate(localizedReason: any(named: 'localizedReason')))
      .thenAnswer((_) async => true);
  await tester.pumpWidget(SplashScreen(localAuth: mockAuth, biometricsEnabled: true));
  await tester.pumpAndSettle();
  verify(() => mockAuth.authenticate(localizedReason: any(named: 'localizedReason'))).called(1);
});
```

---

### 3.9 — Offline Cache (Hive)

Hive is used **only for UI-layer caching**. Supabase Postgres is always the source of truth.

```bash
flutter pub add hive_flutter
```

Cache: last marketplace listing, user's own loans, wallet balances snapshot. Show stale data with "Last updated X ago" banner when offline. Never allow write operations while offline — show error and require connectivity.

---

### ✅ Stage 3 Completion Checklist

- [ ] `flutter test test/` — all tests green
- [ ] `flutter test integration_test/` — all pass
- [ ] Bid placed → notification row created → appears on borrower device in real time
- [ ] KYC uploaded → `kyc_verifications.status = 'pending'`
- [ ] Admin approves KYC in Studio → chip in app updates within 3 seconds via Realtime
- [ ] Contract PDF generated, readable, contains correct party names and amounts
- [ ] Analytics charts render with data from `v_user_portfolio`
- [ ] Biometrics prompt on app launch (device test)
- [ ] Turn off wifi → "Offline" banner + cached marketplace visible

---

## Stage 4 — External Integrations + Sandbox APIs

**Do these only after Stages 1–3 are complete and all tests pass.**

---

### 4.1 — Deploy Edge Functions

Move business logic from client-side RPCs to Edge Functions for server-side enforcement:

```bash
supabase functions new accept-bid
supabase functions new place-bid
supabase functions new process-repayment
supabase functions new calculate-risk-score
supabase functions new send-notification
supabase functions new generate-contract
```

**Process per function:**

1. Write Edge Function wrapping the existing Postgres RPC
2. Test locally: `supabase functions serve function-name --env-file .env.local`
3. Deploy: `supabase functions deploy function-name`
4. Update Flutter to call Edge Function URL instead of RPC
5. Confirm existing integration tests still pass
6. Remove client-side RPC call

Replace **one at a time** — never all at once.

---

### 4.2 — MTN Mobile Money

**Sandbox:** [momodeveloper.mtn.com](https://momodeveloper.mtn.com)

Replace `mock_top_up` RPC with MTN MoMo Collection API. Replace `mock_disburse` with MTN Disbursement API.

```dart
class MtnMomoService {
  static const _baseUrl = kDebugMode
      ? 'https://sandbox.momodeveloper.mtn.com'
      : 'https://proxy.momoapi.mtn.com';

  Future<String> requestPayment({
    required String phone, required double amount, required String externalId,
  }) async { /* POST /collection/v1_0/requesttopay */ }
}
```

| Test number | Behaviour |
|---|---|
| `46733123450` | Always succeeds |
| `46733123451` | Always fails |
| `46733123452` | Timeout |

---

### 4.3 — Airtel Money Sandbox

**Sandbox:** [developers.airtel.africa](https://developers.airtel.africa)

```dart
static const _baseUrl = kDebugMode
    ? 'https://openapiuat.airtel.africa'
    : 'https://openapi.airtel.africa';
```

---

### 4.4 — Africa's Talking SMS

**Sandbox:** [account.africastalking.com/sandbox](https://account.africastalking.com/sandbox)

Messages appear in the AT sandbox simulator, not a real device.

```dart
final _username = kDebugMode ? 'sandbox' : 'your-live-username';
```

---

### 4.5 — KYC Verification API

**Smile Identity sandbox:** [docs.smileidentity.com](https://docs.smileidentity.com)

Replace admin manual approval with automated verification. On successful verification, call an Edge Function that sets `kyc_verifications.status = 'approved'` and `users.status = 'active'`.

---

### 4.6 — Push Notifications (Background)

Use Firebase Cloud Messaging for push delivery alongside the existing Supabase Realtime in-app notifications.

```dart
testWidgets('push message shows in-app banner when app is foreground', (tester) async {
  final mockMessaging = MockMessagingService();
  final controller = StreamController<PushMessage>();
  when(() => mockMessaging.onMessage).thenAnswer((_) => controller.stream);

  await tester.pumpWidget(NipanzeApp(messaging: mockMessaging));
  controller.add(PushMessage(title: 'New bid on your loan'));
  await tester.pump();
  expect(find.text('New bid on your loan'), findsOneWidget);
});
```

---

### ✅ Stage 4 Completion Checklist

- [ ] All Edge Functions deployed and tested locally with `supabase functions serve`
- [ ] MTN MoMo sandbox: success, failure, and timeout tested
- [ ] Airtel sandbox: top-up flow end-to-end
- [ ] Africa's Talking: OTP in AT simulator
- [ ] KYC sandbox: documents verified automatically
- [ ] Push received on real device when app is closed
- [ ] All `kDebugMode` sandbox/production URL switches confirmed
- [ ] Switch from sandbox to production keys **one service at a time**
- [ ] All Stage 1–3 integration tests still pass after each switch

---

## Summary

| Stage | What you build | External deps | Cost |
|---|---|---|---|
| 1 | Auth, routing, scaffold | None | Free |
| 2 | Full marketplace (real schema, mock payments) | None | Free |
| 3 | KYC upload, PDF, notifications, analytics, biometrics | None | Free |
| 4 | Real payments, Edge Functions, push, KYC API | MTN, Airtel, AT, Smile ID | API costs only |

You can build and fully test a complete lending marketplace through Stage 3 without spending anything, without touching a single external API, and with every flow verified by automated tests against the production schema.
