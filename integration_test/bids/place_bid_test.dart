// integration_test/bids/place_bid_test.dart
//
// Tests the complete accept_bid flow — the most critical transaction in Stage 2.
//
// Verifies:
//   1. trg_fn_enforce_lendable_on_bid blocks bids when balance is zero
//   2. accept_bid RPC creates loan_contracts + contract_bids atomically
//   3. trg_fn_lock_funds_on_accept moves lendable → locked for the lender
//   4. loan_request status transitions to 'contracted'
//   5. Contracted loans do not appear in v_loan_listings
//
// Requires local Supabase stack + accept_bid RPC deployed.
//
// Run standalone:  flutter test integration_test/bids/place_bid_test.dart
// Run via runner:  flutter test integration_test/integration_test.dart

// ignore_for_file: unnecessary_await_in_return, unused_local_variable

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../test/helpers/supabase_test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => setupSupabaseLocal());

  group('trg_fn_enforce_lendable_on_bid', () {
    test('blocks bid when lendable_balance is zero', () async {
      // frank.omondi has no lendable balance in seed data.
      await signInTestUser('frank.omondi@gmail.com');
      final frankUid = supabase.auth.currentUser!.id;

      // Find any active loan that Frank doesn't own.
      final otherLoans = await supabase
          .from('loan_requests')
          .select('request_id, borrower_id')
          .eq('status', 'active')
          .neq('borrower_id', frankUid)
          .limit(1);

      if (otherLoans.isEmpty) {
        // No suitable loan in current seed state — skip gracefully.
        await signOut();
        return;
      }

      await expectLater(
        () async => supabase.from('bids').insert({
          'request_id': otherLoans.first['request_id'],
          'lender_id': frankUid,
          'bid_amount': 100000,
          'interest_rate': 12,
          'status': 'pending',
        }),
        throwsA(predicate(
          (e) =>
              e.toString().toLowerCase().contains('insufficient') ||
              e.toString().toLowerCase().contains('lendable'),
          'DB trigger should block bid with zero lendable balance',
        )),
      );

      await signOut();
    });
  });

  group('accept_bid RPC — full atomic transaction', () {
    test('accept_bid creates contract and locks lender funds', () async {
      // GreenLeaf Agro has a pending bid on Maria's loan in seed data.
      final greenLeafUid = await signInTestUser('info@greenleafagro.co.ug');

      final bids = await supabase
          .from('bids')
          .select('bid_id, request_id, bid_amount')
          .eq('lender_id', greenLeafUid)
          .eq('status', 'pending');

      if (bids.isEmpty) {
        // Seed state already consumed by a previous run — skip gracefully.
        // Reset with: supabase db reset && psql ... -f seed.sql
        await signOut();
        return;
      }

      final bid       = bids.first;
      final requestId = bid['request_id'] as String;
      final bidId     = bid['bid_id'] as String;
      final bidAmount = (bid['bid_amount'] as num).toDouble();

      // Fetch borrower_id while still signed in as GreenLeaf.
      final loanRow = await supabase
          .from('loan_requests')
          .select('borrower_id')
          .eq('request_id', requestId)
          .single();
      final borrowerId = loanRow['borrower_id'] as String;

      // Snapshot lender wallet BEFORE acceptance.
      final lendableBefore = await getLendableBalance(greenLeafUid);
      final lockedBefore   = await getLockedRepayment(greenLeafUid);

      // Switch to borrower to call accept_bid (RLS: only borrower may accept).
      await signOut();
      await signInTestUser('maria.nakato@gmail.com');

      final contractId = await supabase.rpc('accept_bid', params: {
        'p_request_id': requestId,
        'p_bid_id':     bidId,
        'p_borrower_id': borrowerId,
      }) as String;

      expect(contractId, isNotNull);

      // Loan request must be 'contracted'.
      final loan = await supabase
          .from('loan_requests')
          .select('status')
          .eq('request_id', requestId)
          .single();
      expect(loan['status'], 'contracted');

      // Contract row must exist in draft state.
      final contract = await supabase
          .from('loan_contracts')
          .select('status, borrower_id, all_lenders_signed')
          .eq('contract_id', contractId)
          .single();
      expect(contract['status'], 'draft');
      expect(contract['borrower_id'], borrowerId);
      expect(contract['all_lenders_signed'], false);

      // Exactly one contract_bids junction row.
      final cb = await supabase
          .from('contract_bids')
          .select('lender_id')
          .eq('contract_id', contractId);
      expect(cb.length, 1);
      expect(cb.first['lender_id'], greenLeafUid);

      // Verify lender wallet changed correctly.
      await signOut();
      await signInTestUser('info@greenleafagro.co.ug');

      final lendableAfter = await getLendableBalance(greenLeafUid);
      final lockedAfter   = await getLockedRepayment(greenLeafUid);

      expect(lendableAfter, lendableBefore - bidAmount,
          reason: 'lendable_balance must decrease by bid amount');
      expect(lockedAfter, lockedBefore + bidAmount,
          reason: 'locked_repayment must increase by bid amount');

      await signOut();
    });
  });

  group('v_loan_listings — contracted loans hidden from marketplace', () {
    test('contracted and fully_funded loans do not appear in v_loan_listings', () async {
      await signInTestUser('invest@pearlcapital.ug');

      final listings = await supabase.from('v_loan_listings').select('status');
      final statuses  = listings.map((r) => r['status'] as String).toList();

      expect(statuses.contains('contracted'), false,
          reason: 'Contracted loans must not appear in marketplace');
      expect(statuses.contains('fully_funded'), false,
          reason: 'Fully funded loans must not appear in marketplace');

      await signOut();
    });
  });
}