// integration_test/marketplace/loan_listing_test.dart
//
// Verifies the v_loan_listings view privacy contract:
//   - borrower_id NEVER present in any row
//   - credit_score_band (range string) present, raw credit_score absent
//   - Only active / partially_funded loans appear
//
// Run standalone:  flutter test integration_test/marketplace/loan_listing_test.dart
// Run via runner:  flutter test integration_test/integration_test.dart

// ignore_for_file: unnecessary_await_in_return

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../test/helpers/supabase_test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => setupSupabaseLocal());

  group('v_loan_listings privacy contract', () {
    test('borrower_id is NEVER present in any row', () async {
      await signInTestUser('invest@pearlcapital.ug');

      final rows = await supabase.from('v_loan_listings').select();

      for (final row in rows) {
        expect(row.containsKey('borrower_id'), false,
            reason: 'borrower_id must never appear in marketplace listing');
        expect(row.containsKey('email'), false,
            reason: 'email must never appear in marketplace listing');
        expect(row.containsKey('phone_number'), false,
            reason: 'phone_number must never appear in marketplace listing');
        expect(row.containsKey('first_name'), false,
            reason: 'first_name must never appear in marketplace listing');
      }

      await signOut();
    });

    test('credit_score_band is a range string, not a raw integer', () async {
      await signInTestUser('invest@pearlcapital.ug');

      final rows = await supabase.from('v_loan_listings').select();

      for (final row in rows) {
        expect(row.containsKey('credit_score'), false,
            reason: 'raw credit_score must never appear publicly');
        if (row['credit_score_band'] != null) {
          final band = row['credit_score_band'] as String;
          expect(band.contains('-'), true,
              reason: 'Band must be a range like "700-749", got: $band');
        }
      }

      await signOut();
    });

    test('only active and partially_funded loans appear', () async {
      await signInTestUser('invest@pearlcapital.ug');

      final rows = await supabase.from('v_loan_listings').select('status');
      final statuses = rows.map((r) => r['status'] as String).toSet();

      for (final status in statuses) {
        expect(
          ['active', 'partially_funded'].contains(status),
          true,
          reason: 'Only open loans should appear in marketplace, got: $status',
        );
      }

      await signOut();
    });

    test('required safe fields are present', () async {
      await signInTestUser('invest@pearlcapital.ug');

      final rows = await supabase.from('v_loan_listings').select();
      expect(rows, isNotEmpty,
          reason: 'Seed data must include at least one active loan');

      final row = rows.first;
      for (final field in [
        'request_id',
        'requested_amount',
        'purpose',
        'duration_months',
        'funding_percentage',
        'number_of_bids',
      ]) {
        expect(row.containsKey(field), true,
            reason: 'Expected field "$field" missing from v_loan_listings');
      }

      await signOut();
    });
  });
}