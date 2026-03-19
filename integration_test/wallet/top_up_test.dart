// integration_test/wallet/top_up_test.dart
//
// Requires local Supabase stack: supabase start
// Requires mock_top_up RPC to be deployed (see BUILD_PLAN.md Stage 2.3).
// Run: flutter test integration_test/wallet/top_up_test.dart

// ignore_for_file: unnecessary_await_in_return

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../test/helpers/supabase_test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => await setupSupabaseLocal());

  group('mock_top_up RPC', () {
    test('increments lendable_balance only — locked and borrowed unchanged', () async {
      final uid = await signInTestUser('invest@pearlcapital.ug');

      final before = await supabase
          .from('wallet_balances')
          .select()
          .eq('user_id', uid)
          .single();

      final beforeLendable = (before['lendable_balance'] as num).toDouble();
      final beforeLocked = (before['locked_repayment'] as num).toDouble();
      final beforeBorrowed = (before['non_lendable_borrowed'] as num).toDouble();

      await supabase.rpc('mock_top_up', params: {
        'p_user_id': uid,
        'p_amount': 100000,
      });

      final after = await supabase
          .from('wallet_balances')
          .select()
          .eq('user_id', uid)
          .single();

      expect(
          (after['lendable_balance'] as num).toDouble(), beforeLendable + 100000);
      expect((after['locked_repayment'] as num).toDouble(), beforeLocked);
      expect(
          (after['non_lendable_borrowed'] as num).toDouble(), beforeBorrowed);

      // Restore
      await supabase.rpc('mock_top_up', params: {
        'p_user_id': uid,
        'p_amount': -100000,
      }).catchError((_) async {
        // If RPC doesn't support negative, update directly via admin
        await adminClient.from('wallet_balances').update({
          'lendable_balance': beforeLendable,
        }).eq('user_id', uid);
      });

      await signOut();
    });

    test('rejects non-positive amount', () async {
      final uid = await signInTestUser('invest@pearlcapital.ug');

      expect(
        () async => await supabase.rpc('mock_top_up', params: {
          'p_user_id': uid,
          'p_amount': 0,
        }),
        throwsA(anything),
      );

      await signOut();
    });
  });
}
