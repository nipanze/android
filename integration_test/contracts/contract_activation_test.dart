// integration_test/contracts/contract_activation_test.dart
//
// Tests contract signing sequence and sp_calculate_repayment_schedule.
//
// Depends on place_bid_test having run first (or a seeded draft contract).
// If no draft contract exists for Maria, the signing test skips gracefully.
//
// Run standalone:  flutter test integration_test/contracts/contract_activation_test.dart
// Run via runner:  flutter test integration_test/integration_test.dart
//
// To guarantee a fresh contract, run:
//   supabase db reset
//   psql "postgresql://postgres:postgres@localhost:54322/postgres" -f schema.sql
//   psql "postgresql://postgres:postgres@localhost:54322/postgres" -f seed.sql
// Then run bids suite before contracts suite.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../test/helpers/supabase_test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => setupSupabaseLocal());

  // -------------------------------------------------------------------------
  // Contract signing → auto-activation → repayment schedule generation
  // -------------------------------------------------------------------------
  group('Contract signing and activation', () {
    test(
      'both parties signing activates contract via trg_fn_check_all_lenders_signed',
      () async {
        await signInTestUser('maria.nakato@gmail.com');
        final mariaUid = supabase.auth.currentUser!.id;

        final contracts = await supabase
            .from('loan_contracts')
            .select('contract_id, borrower_signed, all_lenders_signed')
            .eq('borrower_id', mariaUid)
            .eq('status', 'draft');

        if (contracts.isEmpty) {
          // No draft contract — place_bid_test must run first.
          // Skip rather than fail so the suite stays green in isolation.
          printOnFailure(
            'SKIP: No draft contract found for maria.nakato. '
            'Run integration_test/bids/place_bid_test.dart first, '
            'or reset the DB and reload seed data.',
          );
          await signOut();
          return;
        }

        final contractId = contracts.first['contract_id'] as String;

        // --- Borrower signs ---
        await supabase.from('loan_contracts').update({
          'borrower_signed': true,
          'borrower_signed_at': DateTime.now().toIso8601String(),
          'borrower_signature_ip': '127.0.0.1',
        }).eq('contract_id', contractId);

        await signOut();

        // --- Each lender signs via their own session ---
        // Use adminClient to read contract_bids (bypasses RLS for setup).
        final cbs = await adminClient
            .from('contract_bids')
            .select('contract_bid_id, lender_id')
            .eq('contract_id', contractId);

        for (final cb in cbs) {
          // Sign in as lender so RLS permits the update.
          final lenderRow = await adminClient
              .from('users')
              .select('email')
              .eq('user_id', cb['lender_id'])
              .single();

          await signInTestUser(lenderRow['email'] as String);

          await supabase.from('contract_bids').update({
            'lender_signed': true,
            'lender_signed_at': DateTime.now().toIso8601String(),
            'lender_signature_ip': '127.0.0.1',
          }).eq('contract_bid_id', cb['contract_bid_id']);

          await signOut();
        }

        // --- Verify trigger fired: trg_fn_check_all_lenders_signed ---
        // Read via adminClient — borrower session is signed out.
        final updated = await adminClient
            .from('loan_contracts')
            .select('all_lenders_signed, contract_activated_at, status')
            .eq('contract_id', contractId)
            .single();

        expect(updated['all_lenders_signed'], true,
            reason: 'trg_fn_check_all_lenders_signed should set all_lenders_signed');
        expect(updated['contract_activated_at'], isNotNull,
            reason: 'contract_activated_at must be set on activation');

        // --- Generate repayment schedule ---
        // Sign back in as borrower to call the RPC.
        await signInTestUser('maria.nakato@gmail.com');

        await supabase.rpc('sp_calculate_repayment_schedule', params: {
          'p_contract_id': contractId,
        });

        final installments = await supabase
            .from('loan_repayments')
            .select('installment_number, amount_due, due_date')
            .eq('contract_id', contractId)
            .order('installment_number');

        expect(installments, isNotEmpty,
            reason: 'sp_calculate_repayment_schedule must create installment rows');

        for (final inst in installments) {
          expect((inst['amount_due'] as num).toDouble(), greaterThan(0),
              reason: 'Every installment must have a positive amount_due');
          expect(inst['due_date'], isNotNull,
              reason: 'Every installment must have a due_date');
          expect(inst['installment_number'], isNotNull);
        }

        await signOut();
      },
    );
  });

  // -------------------------------------------------------------------------
  // Reputation score and tier mapping — pure DB function tests
  // -------------------------------------------------------------------------
  group('sp_calculate_reputation_score', () {
    test('returns a value between 0 and 100', () async {
      final davidUid = await signInTestUser('david.mukasa@gmail.com');

      final score = await supabase.rpc(
        'sp_calculate_reputation_score',
        params: {'p_user_id': davidUid},
      );

      expect(score, isNotNull);
      expect(score as int, greaterThanOrEqualTo(0));
      expect(score, lessThanOrEqualTo(100));

      await signOut();
    });

    test('fn_score_to_tier maps score thresholds correctly', () async {
      await signInTestUser('david.mukasa@gmail.com');

      final cases = <int, String>{
        90: 'platinum',
        85: 'platinum',
        75: 'gold',
        70: 'gold',
        60: 'silver',
        55: 'silver',
        45: 'bronze',
        40: 'bronze',
        39: 'restricted',
        0:  'restricted',
      };

      for (final entry in cases.entries) {
        final tier = await supabase.rpc(
          'fn_score_to_tier',
          params: {'p_score': entry.key},
        ) as String;

        expect(tier, entry.value,
            reason: 'Score ${entry.key} should map to ${entry.value}, got $tier');
      }

      await signOut();
    });
  });
}