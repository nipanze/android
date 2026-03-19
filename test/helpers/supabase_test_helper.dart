// test/helpers/supabase_test_helper.dart
//
// Shared setup for all integration tests.
// Requires the local Supabase stack to be running: supabase start
//
// Keys sourced from: supabase status --output json
// The sb_publishable_ / sb_secret_ keys shown by `supabase status`
// are NOT accepted by supabase_flutter — the JWT keys below are required.
//
// Service role key is used ONLY in tests for admin teardown — never in prod.
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _localUrl = 'http://127.0.0.1:54321';

// JWT anon key — from `supabase status --output json` → ANON_KEY
const _localAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
    '.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9'
    '.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

// JWT service role key — from `supabase status --output json` → SERVICE_ROLE_KEY
const _serviceRoleKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
    '.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0'
    '.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU';

late SupabaseClient supabase;
late SupabaseClient adminClient;

bool _initialized = false;

Future<void> setupSupabaseLocal() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  if (!_initialized) {
    try {
      await Supabase.initialize(
        url: _localUrl,
        anonKey: _localAnonKey,
      );
    } catch (e) {
      if (!e.toString().contains('already')) rethrow;
    }
    _initialized = true;
  }

  supabase = Supabase.instance.client;

  // Service-role client — bypasses RLS for test setup/teardown only.
  adminClient = SupabaseClient(_localUrl, _serviceRoleKey);

  // Confirm all seed user emails so signInWithPassword works.
  await _confirmSeedEmails();
}

// ---------------------------------------------------------------------------
// Confirm every seed email via the GoTrue admin API.
// Supabase Auth blocks signInWithPassword if email_confirmed_at is null.
// Seed users inserted via seed.sql bypass the normal registration flow
// so their emails are unconfirmed by default.
// ---------------------------------------------------------------------------
Future<void> _confirmSeedEmails() async {
  const seedEmails = [
    'david.mukasa@gmail.com',
    'sarah.namukasa@yahoo.com',
    'james.okello@outlook.com',
    'maria.nakato@gmail.com',
    'robert.ssemwanga@gmail.com',
    'invest@pearlcapital.ug',
    'funds@victoriainvest.co.ug',
    'lending@equatorfinance.ug',
    'info@greenleafagro.co.ug',
    'contact@kampalatech.ug',
    'frank.omondi@gmail.com',
    'lucy.nambi@yahoo.com',
    'charles.mwesigwa@gmail.com',
    'alice.namuli@gmail.com',
    'admin1@opencapital.ug',
    'test.user@gmail.com',
  ];

  try {
    final res = await adminClient.auth.admin.listUsers();
    for (final user in res) {
      if (seedEmails.contains(user.email) && user.emailConfirmedAt == null) {
        await adminClient.auth.admin.updateUserById(
          user.id,
          attributes: AdminUserAttributes(emailConfirm: true),
        );
        print('Confirmed email for ${user.email}');
      }
    }
  } catch (e) {
    print('_confirmSeedEmails warning: $e');
  }
}

// ---------------------------------------------------------------------------
// Auth helpers
// ---------------------------------------------------------------------------

/// Sign in a seed test user and return their userId.
/// All seed accounts use password: Test1234!
Future<String> signInTestUser(
  String email, {
  String password = 'Test1234!',
}) async {
  // Clear any existing session before signing in.
  try {
    await supabase.auth.signOut();
  } catch (_) {}

  final res = await supabase.auth.signInWithPassword(
    email: email,
    password: password,
  );
  if (res.user == null) {
    throw Exception(
      'signInTestUser($email) returned null user. '
      'Check the local stack is running and seed.sql was loaded.',
    );
  }
  return res.user!.id;
}

/// Sign out the current user.
Future<void> signOut() async {
  try {
    await supabase.auth.signOut();
  } catch (_) {}
}

// ---------------------------------------------------------------------------
// Cleanup — removes rows created during a test window.
// Uses created_at filter so permanent seed data is preserved.
// ---------------------------------------------------------------------------
Future<void> cleanupTestRows({
  Duration window = const Duration(minutes: 10),
}) async {
  final cutoff = DateTime.now().subtract(window).toIso8601String();

  for (final table in [
    'repayment_transactions',
    'loan_repayments',
    'disbursements',
    'contract_bids',
    'loan_contracts',
    'bids',
    'loan_requests',
    'kyc_verifications',
    'risk_assessments',
    'user_profiles',
    'wallet_balances',
    'notifications',
    'audit_logs',
  ]) {
    try {
      await adminClient.from(table).delete().gte('created_at', cutoff);
    } catch (e) {
      print('cleanupTestRows($table): $e');
    }
  }
}

// ---------------------------------------------------------------------------
// Wallet balance readers
// ---------------------------------------------------------------------------

Future<double> getLendableBalance(String userId) async {
  final row = await supabase
      .from('wallet_balances')
      .select('lendable_balance')
      .eq('user_id', userId)
      .single();
  return (row['lendable_balance'] as num).toDouble();
}

Future<double> getLockedRepayment(String userId) async {
  final row = await supabase
      .from('wallet_balances')
      .select('locked_repayment')
      .eq('user_id', userId)
      .single();
  return (row['locked_repayment'] as num).toDouble();
}

Future<double> getNonLendableBorrowed(String userId) async {
  final row = await supabase
      .from('wallet_balances')
      .select('non_lendable_borrowed')
      .eq('user_id', userId)
      .single();
  return (row['non_lendable_borrowed'] as num).toDouble();
}