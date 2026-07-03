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
    String? district,
    bool closingSoon = false,
  }) async {
    try {
      var query = _client.from(ViewNames.loanListings).select();

      if (district != null) {
        query = query.eq('district', district) as dynamic;
      }
      if (closingSoon) {
        query = query.eq('closing_soon_24h', true) as dynamic;
      }

      final data = await (query as PostgrestFilterBuilder).order('listed_at', ascending: false);

      return (data as List).map((e) => LoanListing.fromMap(e)).toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Get a single listing detail.
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

  /// Get live offers for a listing.
  Future<List<LoanOffer>> getOffers(String requestId) async {
    try {
      final data = await _client
          .from(TableNames.loanOffers)
          .select()
          .eq('request_id', requestId)
          .eq('status', 'pending')
          .order('offered_at', ascending: false);

      return (data as List).map((e) => LoanOffer.fromMap(e)).toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Place an offer on a listing. Requires lender/pro subscription.
  Future<String> makeOffer({
    required String requestId,
    required int amount,
    String? expectations,
  }) async {
    try {
      final data = await _client.from(TableNames.loanOffers).insert({
        'request_id': requestId,
        'offer_amount': amount,
        'proposed_expectations': expectations,
        'lender_id': _client.auth.currentUser!.id,
      }).select('id').single();

      return data['id'] as String;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Accept an offer. Calls the accept_offer RPC atomically.
  Future<String> acceptOffer({
    required String requestId,
    required String offerId,
  }) async {
    try {
      final result = await _client.rpc(RpcNames.acceptOffer, params: {
        'p_request_id': requestId,
        'p_offer_id': offerId,
        'p_borrower_id': _client.auth.currentUser!.id,
      });
      return result as String; // Returns reveal_id
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Withdraw a pending offer.
  Future<void> withdrawOffer(String offerId) async {
    try {
      await _client
          .from(TableNames.loanOffers)
          .update({'status': 'withdrawn'})
          .eq('id', offerId)
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

  /// Real-time stream for a single listing's offers.
  Stream<List<LoanOffer>> watchOffers(String requestId) {
    return _client
        .from(TableNames.loanOffers)
        .stream(primaryKey: ['id'])
        .eq('request_id', requestId)
        .asyncMap((_) => getOffers(requestId));
  }

  /// Check if the user is the borrower of a given listing.
  Future<bool> isListingOwner({
    required String requestId,
    required String userId,
  }) async {
    try {
      final res = await _client
          .from(TableNames.loanRequests)
          .select('id')
          .eq('id', requestId)
          .eq('borrower_id', userId)
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }
}

