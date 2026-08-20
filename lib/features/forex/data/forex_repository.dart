import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/models/currency_model.dart';
import '../../../shared/models/forex_listing_model.dart';
import '../../../shared/models/forex_offer_model.dart';

@lazySingleton
class ForexRepository {
  ForexRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  Future<List<CurrencyModel>> getCurrencies() async {
    try {
      final data = await _client
          .from(TableNames.currencies)
          .select()
          .order('code', ascending: true);
      return (data as List).map((e) => CurrencyModel.fromMap(e)).toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<List<CurrencyModel>> getTradeableCurrencies() async {
    final currencies = await getCurrencies();
    return currencies.where((c) => c.forexTradingEnabled).toList();
  }

  Future<String> createRequest({
    required String currencyHeld,
    required String currencyNeeded,
    required int amount,
    required String settlementPreference,
    double? preferredRate,
    String country = 'UG',
  }) async {
    try {
      final data = await _client
          .from(TableNames.forexRequests)
          .insert({
            'requester_id': _uid,
            'currency_held': currencyHeld,
            'currency_needed': currencyNeeded,
            'amount': amount,
            'settlement_preference': settlementPreference,
            'country': country,
            if (preferredRate != null) 'preferred_rate': preferredRate,
          })
          .select('id')
          .single();
      return data['id'] as String;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<List<ForexListingModel>> getMyForexRequests() async {
    try {
      final data = await _client
          .from(TableNames.forexRequests)
          .select()
          .eq('requester_id', _uid)
          .order('listed_at', ascending: false);
      return (data as List)
          .map((e) => ForexListingModel.fromMap({
                'request_id': e['id'],
                ...Map<String, dynamic>.from(e as Map),
              }))
          .toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Stream<List<ForexListingModel>> watchForexRequests() {
    return _client
        .from(TableNames.forexRequests)
        .stream(primaryKey: ['id'])
        .eq('requester_id', _uid)
        .asyncMap((_) => getMyForexRequests());
  }

  Future<ForexListingModel> getRequestDetail(String requestId) async {
    try {
      final data = await _client
          .from(ViewNames.forexListings)
          .select()
          .eq('request_id', requestId)
          .single();
      return ForexListingModel.fromMap(data);
    } catch (e) {
      try {
        final data = await _client
            .from(TableNames.forexRequests)
            .select()
            .eq('id', requestId)
            .single();
        return ForexListingModel.fromMap({
          'request_id': data['id'],
          ...Map<String, dynamic>.from(data as Map),
        });
      } catch (_) {
        throw parseSupabaseError(e);
      }
    }
  }

  Future<String?> getRequestOwnerId(String requestId) async {
    try {
      final data = await _client
          .from(TableNames.forexRequests)
          .select('requester_id')
          .eq('id', requestId)
          .maybeSingle();
      return data?['requester_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<List<ForexOfferModel>> getOffers(String requestId) async {
    try {
      final data = await _client.rpc(RpcNames.getPublicForexOffers, params: {
        'p_request_id': requestId,
      });
      return (data as List).map((e) => ForexOfferModel.fromMap(e)).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<String> makeOffer({
    required String requestId,
    required double rateOffered,
    required int amountAvailable,
    String? terms,
  }) async {
    try {
      final data = await _client
          .from(TableNames.forexOffers)
          .insert({
            'request_id': requestId,
            'offer_maker_id': _uid,
            'rate_offered': rateOffered,
            'amount_available': amountAvailable,
            'terms': terms,
          })
          .select('id')
          .single();
      return data['id'] as String;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<void> withdrawOffer(String offerId) async {
    try {
      await _client
          .from(TableNames.forexOffers)
          .update({'status': 'withdrawn'})
          .eq('id', offerId)
          .eq('offer_maker_id', _uid)
          .eq('status', 'pending');
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Cancel (take down) a Forex request the current user owns.
  Future<void> cancelRequest(String requestId) async {
    try {
      await _client
          .from(TableNames.forexRequests)
          .update({
            'status': 'cancelled',
            'cancelled_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .eq('requester_id', _uid)
          .eq('status', 'active');
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<String> acceptOffer({
    required String requestId,
    required String offerId,
  }) async {
    try {
      final result = await _client.rpc(RpcNames.acceptForexOffer, params: {
        'p_request_id': requestId,
        'p_offer_id': offerId,
        'p_requester_id': _uid,
      });
      return result as String;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<Map<String, dynamic>> unlockContact(String agreementId) async {
    try {
      final data = await _client.rpc(RpcNames.unlockForexContact, params: {
        'p_agreement_id': agreementId,
      });
      return Map<String, dynamic>.from(data as Map);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<void> submitReview({
    required String agreementId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _client.rpc(RpcNames.submitForexReview, params: {
        'p_agreement_id': agreementId,
        'p_rating': rating,
        'p_comment': comment,
      });
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Stream<List<ForexOfferModel>> watchOffers(String requestId) {
    return _client
        .from(TableNames.forexOffers)
        .stream(primaryKey: ['id'])
        .eq('request_id', requestId)
        .asyncMap((_) => getOffers(requestId));
  }
}
