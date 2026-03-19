// ignore_for_file: directives_ordering, unnecessary_lambdas

import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_errors.dart';
import '../../../shared/models/loan_listing_model.dart';
import '../../../shared/models/bid_model.dart';

@lazySingleton
class MarketplaceRepository {
  MarketplaceRepository(this._supabase);
  final SupabaseClient _supabase;

  // ---------------------------------------------------------------------------
  // Real-time stream of active loan listings from v_loan_listings.
  // borrower_id is excluded at the view level — NEVER present in results.
  // ---------------------------------------------------------------------------
  Stream<List<LoanListingModel>> watchListings() {
    return _supabase
        .from(Views.loanListings)
        .stream(primaryKey: ['request_id'])
        .order('listed_at', ascending: false)
        .map((rows) => rows.map((r) => LoanListingModel.fromJson(r)).toList());
  }

  // ---------------------------------------------------------------------------
  // Single loan listing by requestId (for detail page — still anonymised)
  // ---------------------------------------------------------------------------
  Future<LoanListingModel?> getListing(String requestId) async {
    final rows = await _supabase
        .from(Views.loanListings)
        .select()
        .eq('request_id', requestId)
        .limit(1);
    if (rows.isEmpty) return null;
    return LoanListingModel.fromJson(rows.first);
  }

  // ---------------------------------------------------------------------------
  // Bids for a loan request (anonymised — lender_id exposed but no PII)
  // ---------------------------------------------------------------------------
  Stream<List<BidModel>> watchBidsForLoan(String requestId) {
    return _supabase
        .from(Tables.bids)
        .stream(primaryKey: ['bid_id'])
        .eq('request_id', requestId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map((r) => BidModel.fromJson(r)).toList());
  }

  // ---------------------------------------------------------------------------
  // Place a bid.
  // Client-side pre-check mirrors DB trigger trg_fn_enforce_lendable_on_bid.
  // DB trigger is authoritative — client check is UX only.
  // ---------------------------------------------------------------------------
  Future<void> placeBid({
    required String requestId,
    required String lenderId,
    required double bidAmount,
    required double interestRate,
  }) async {
    try {
      await _supabase.from(Tables.bids).insert({
        'request_id': requestId,
        'lender_id': lenderId,
        'bid_amount': bidAmount,
        'interest_rate': interestRate,
        'status': 'pending',
      });
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Increment views_count (fire-and-forget)
  // ---------------------------------------------------------------------------
  Future<void> recordView(String requestId) async {
    try {
      await _supabase.rpc('increment_loan_views', params: {'p_request_id': requestId});
    } catch (_) {
      // Non-fatal
    }
  }

  // ---------------------------------------------------------------------------
  // Accept a bid — calls the accept_bid Postgres RPC which atomically:
  //   1. Accepts the winning bid (fires trg_fn_lock_funds_on_accept)
  //   2. Rejects all other pending bids
  //   3. Creates loan_contracts + contract_bids rows
  //   4. Updates loan_request status → 'contracted'
  // Returns the new contract_id.
  // ---------------------------------------------------------------------------
  Future<String> acceptBid({
    required String requestId,
    required String bidId,
    required String borrowerId,
  }) async {
    try {
      final contractId = await _supabase.rpc(Rpcs.acceptBid, params: {
        'p_request_id': requestId,
        'p_bid_id': bidId,
        'p_borrower_id': borrowerId,
      });
      return contractId as String;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }
}
