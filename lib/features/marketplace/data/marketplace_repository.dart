// lib/features/marketplace/data/marketplace_repository.dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../domain/models/loan_listing.dart';

@lazySingleton
class MarketplaceRepository {
  MarketplaceRepository(this._client);

  final SupabaseClient _client;

  /// Fetch active listings from the anonymised view.
  /// borrower_id is NEVER present in this view.
  Future<List<LoanListing>> getListings({
    String? riskFilter,
    bool closingSoon = false,
    bool highYield = false,
  }) async {
    try {
      var query = _client.from(ViewNames.loanListings).select();

      if (riskFilter != null) {
        query = query.eq('risk_category', riskFilter) as dynamic;
      }
      if (closingSoon) {
        query = query.eq('closing_soon_24h', true) as dynamic;
      }

      final data = await (query as PostgrestFilterBuilder).order('listed_at', ascending: false);

      final listings = (data as List).map((e) => LoanListing.fromMap(e)).toList();

      if (highYield) {
        listings.sort((a, b) => (b.maxInterestRate).compareTo(a.maxInterestRate));
      }

      return listings;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Get a single listing detail with live bids (anonymised).
  Future<LoanListing> getListingDetail(String requestId) async {
    try {
      final data = await _client
          .from(ViewNames.loanListings)
          .select()
          .eq('request_id', requestId)
          .single();

      return LoanListing.fromMap(data);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Get live order book for a listing — lender_id replaced with lender_token.
  Future<List<LoanBid>> getOrderBook(String requestId) async {
    try {
      // Join loan_bids with profiles to get lender_token (anonymised identifier)
      final data = await _client
          .from(TableNames.loanBids)
          .select('id, request_id, amount, interest_rate, status, placed_at, profiles!inner(lender_token)')
          .eq('request_id', requestId)
          .eq('status', 'pending')
          .order('interest_rate', ascending: true);

      return (data as List).map((e) {
        final profile = e['profiles'] as Map<String, dynamic>?;
        return LoanBid.fromMap({
          ...e,
          'lender_token': profile?['lender_token'],
        });
      }).toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Place a bid on a listing. Requires lender/pro subscription.
  Future<String> placeBid({
    required String requestId,
    required int amount,
    required double interestRate,
  }) async {
    try {
      final data = await _client.from(TableNames.loanBids).insert({
        'request_id': requestId,
        'amount': amount,
        'interest_rate': interestRate,
        'lender_id': _client.auth.currentUser!.id,
      }).select('id').single();

      return data['id'] as String;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Accept a bid. Calls the accept_bid RPC atomically.
  Future<String> acceptBid({
    required String requestId,
    required String bidId,
  }) async {
    try {
      final result = await _client.rpc(RpcNames.acceptBid, params: {
        'p_request_id': requestId,
        'p_bid_id': bidId,
        'p_borrower_id': _client.auth.currentUser!.id,
      });
      return result as String;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Withdraw a pending bid.
  Future<void> withdrawBid(String bidId) async {
    try {
      await _client
          .from(TableNames.loanBids)
          .update({'status': 'withdrawn'})
          .eq('id', bidId)
          .eq('lender_id', _client.auth.currentUser!.id)
          .eq('status', 'pending');
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Real-time stream of the marketplace feed.
  Stream<List<LoanListing>> watchListings() {
    return _client
        .from(TableNames.loanRequests)
        .stream(primaryKey: ['id'])
        .asyncMap((_) => getListings());
  }

  /// Real-time stream for a single listing's order book.
  Stream<List<LoanBid>> watchOrderBook(String requestId) {
    return _client
        .from(TableNames.loanBids)
        .stream(primaryKey: ['id'])
        .eq('request_id', requestId)
        .asyncMap((_) => getOrderBook(requestId));
  }
}
