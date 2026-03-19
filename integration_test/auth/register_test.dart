// integration_test/auth/register_test.dart
//
// Requires local Supabase stack: supabase start
// Run: flutter test integration_test/auth/register_test.dart

// ignore_for_file: unnecessary_await_in_return

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../test/helpers/supabase_test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => await setupSupabaseLocal());

  group('Registration — DB side-effects', () {
    test('register creates users row with correct defaults', () async {
      // Use the seed user david.mukasa — already exists and is KYC approved
      final uid = await signInTestUser('david.mukasa@gmail.com');

      final userRow = await supabase
          .from('users')
          .select()
          .eq('user_id', uid)
          .single();

      expect(userRow['email'], 'david.mukasa@gmail.com');
      expect(userRow['reputation_score'], greaterThanOrEqualTo(0));
      expect(userRow['reputation_score'], lessThanOrEqualTo(100));
      expect(userRow['reputation_tier'], isNotNull);
      expect(['bronze', 'silver', 'gold', 'platinum', 'restricted'],
          contains(userRow['reputation_tier']));

      await signOut();
    });

    test('register creates wallet_balances row via trg_auto_create_wallet', () async {
      final uid = await signInTestUser('david.mukasa@gmail.com');

      final walletRow = await supabase
          .from('wallet_balances')
          .select()
          .eq('user_id', uid)
          .single();

      expect(walletRow['wallet_id'], isNotNull);
      expect(walletRow['lendable_balance'], isNotNull);
      expect(walletRow['locked_repayment'], isNotNull);
      expect(walletRow['non_lendable_borrowed'], isNotNull);

      await signOut();
    });

    test('alice.namuli has pending_verification status (seed)', () async {
      final uid = await signInTestUser('alice.namuli@gmail.com');

      final userRow = await supabase
          .from('users')
          .select('status')
          .eq('user_id', uid)
          .single();

      expect(userRow['status'], 'pending_verification');

      await signOut();
    });
  });
}
