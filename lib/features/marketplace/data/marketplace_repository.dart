// lib/features/marketplace/data/marketplace_repository.dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/models/forex_listing_model.dart';
import '../domain/models/loan_listing.dart';
import '../domain/models/marketplace_item.dart';

@lazySingleton
class MarketplaceRepository {
  MarketplaceRepository(this._client);

  final SupabaseClient _client;

  String? get currentViewerId => _client.auth.currentUser?.id;

  /// Fetch active listings from the anonymised view.
  /// borrower_id is NEVER present in this view.
  Future<List<MarketplaceItem>> getListings({
    String? district,
    bool closingSoon = false,
    MarketplaceModule? module,
  }) async {
    try {
      final items = <MarketplaceItem>[];

      if (module == null || module == MarketplaceModule.loan) {
        var query = _client.from(ViewNames.loanListings).select();
        if (district != null) {
          query = query.eq('district', district) as dynamic;
        }
        if (closingSoon) {
          query = query.eq('closing_soon_24h', true) as dynamic;
        }
        final data = await (query as PostgrestFilterBuilder)
            .order('listed_at', ascending: false);
        items.addAll((data as List)
            .map((e) => MarketplaceItem.loan(LoanListing.fromMap(e))));
      }

      if (module == null || module == MarketplaceModule.forex) {
        var query = _client.from(ViewNames.forexListings).select();
        if (closingSoon) {
          query = query.eq('closing_soon_24h', true) as dynamic;
        }
        final data = await (query as PostgrestFilterBuilder)
            .order('listed_at', ascending: false);
        items.addAll((data as List)
            .map((e) => MarketplaceItem.forex(ForexListingModel.fromMap(e))));
      }

      items.sort((a, b) => b.listedAt.compareTo(a.listedAt));
      return items;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Get a single listing detail.
  Future<LoanListing> getListingDetail(String requestId) async {
    try {
      final data = await _client
          .from(ViewNames.loanListingDetails)
          .select()
          .eq('request_id', requestId)
          .single();

      return LoanListing.fromMap(data);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Get live offers for a listing.
  ///
  /// Owners need private table rows so they can accept a specific offer.
  /// Everyone else uses the participant-gated anonymized order-book RPC.
  Future<List<LoanOffer>> getOffers(
    String requestId, {
    bool includePrivate = false,
  }) async {
    if (includePrivate) return _getPrivateOffers(requestId);

    try {
      final data = await _client.rpc(RpcNames.getPublicListingOffers, params: {
        'p_request_id': requestId,
      });

      return (data as List).map((e) => LoanOffer.fromMap(e)).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<LoanOffer>> _getPrivateOffers(String requestId) async {
    try {
      final data = await _client
          .from(TableNames.loanOffers)
          .select('''
            *,
            profiles!loan_offers_lender_id_fkey(
              preferred_bank,
              institution_type,
              is_bank_agent,
              show_professional_tag
            )
          ''')
          .eq('request_id', requestId)
          .eq('status', 'pending')
          .order('offered_at', ascending: false);

      return (data as List).map(_loanOfferFromPrivateRow).toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  LoanOffer _loanOfferFromPrivateRow(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    final profile = map['profiles'];
    if (profile is Map && profile['show_professional_tag'] == true) {
      map['preferred_bank'] = profile['preferred_bank'];
      map['institution_type'] = profile['institution_type'];
      map['is_bank_agent'] = profile['is_bank_agent'];
      map['show_professional_tag'] = profile['show_professional_tag'];
    }
    map.remove('profiles');
    return LoanOffer.fromMap(map);
  }

  /// Place an offer on a listing. Requires lender/pro subscription.
  Future<String> makeOffer({
    required String requestId,
    required int amount,
    required double interestRatePct,
    required double lateFeePct,
    required String repaymentFrequency,
    required int installmentAmount,
    String? expectations,
  }) async {
    try {
      final data = await _client
          .from(TableNames.loanOffers)
          .insert({
            'request_id': requestId,
            'offer_amount': amount,
            'interest_rate_pct': interestRatePct,
            'late_fee_pct': lateFeePct,
            'repayment_frequency': repaymentFrequency,
            'installment_amount': installmentAmount,
            'proposed_expectations': expectations,
            'lender_id': _client.auth.currentUser!.id,
          })
          .select('id')
          .single();

      return data['id'] as String;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Accept an offer. Calls the accept_offer RPC atomically.
  /// Returns agreement_id (Stage 4+: no longer returns reveal_id).
  /// The app should navigate to the agreement review page, where both
  /// parties must confirm before contact details can be revealed.
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
      return result as String; // Returns agreement_id
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
  Stream<List<MarketplaceItem>> watchListings({MarketplaceModule? module}) {
    return _client.from(TableNames.loanRequests).stream(
        primaryKey: ['id']).asyncMap((_) => getListings(module: module));
  }

  Stream<List<MarketplaceItem>> watchForexListings(
      {MarketplaceModule? module}) {
    return _client.from(TableNames.forexRequests).stream(
        primaryKey: ['id']).asyncMap((_) => getListings(module: module));
  }

  /// Real-time stream for a single listing's offers.
  Stream<List<LoanOffer>> watchOffers(
    String requestId, {
    bool includePrivate = false,
  }) {
    return _client
        .from(TableNames.loanOffers)
        .stream(primaryKey: ['id'])
        .eq('request_id', requestId)
        .asyncMap((_) => getOffers(requestId, includePrivate: includePrivate));
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

  /// Fetch a lender's recent interest rate history for sparkline display.
  /// Returns rate values ordered chronologically (oldest first).
  /// Falls back to empty list on any error — callers use 2-point fallback.
  Future<List<double>> getLenderInterestHistory(
    String lenderId, {
    int limit = 6,
  }) async {
    try {
      final data = await _client
          .from('v_lender_rate_history')
          .select('interest_rate_pct, offered_at')
          .eq('lender_id', lenderId)
          .order('offered_at', ascending: true)
          .limit(limit);

      return (data as List)
          .map((row) => (row['interest_rate_pct'] as num).toDouble())
          .toList();
    } catch (e) {
      return const [];
    }
  }

  /// Call the Pro-gated RPC to fetch the set of request_ids that match the
  /// supplied filter criteria.
  ///
  /// The RPC delegates gating to [v_marketplace_pro_filters]: non-Pro callers
  /// simply receive an empty list — no error, no plan-leaking exception.
  ///
  /// Pass [null] for any parameter to omit that criterion entirely.
  Future<Set<String>> getProFilteredRequestIds({
    List<String>? employmentTypes,
    List<String>? incomeBrackets,
    bool suggestedTermsOnly = false,
    bool verifiedOnly = false,
  }) async {
    try {
      final data = await _client.rpc(
        RpcNames.getMarketplaceProFiltered,
        params: {
          if (employmentTypes != null) 'p_employment_types': employmentTypes,
          if (incomeBrackets != null) 'p_income_brackets': incomeBrackets,
          'p_suggested_terms_only': suggestedTermsOnly,
          'p_verified_only': verifiedOnly,
        },
      );
      return {
        for (final row in (data as List)) row['request_id'] as String,
      };
    } catch (_) {
      return const {};
    }
  }
}
