// lib/features/positions/data/positions_repository.dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/offline_service.dart';
import '../domain/models/lender_offer.dart';

@lazySingleton
class PositionsRepository {
  PositionsRepository(this._client) {
    OfflineService().registerSessionCache(_clearCache);
  }

  final SupabaseClient _client;
  final Map<String, List<LenderOffer>> _offersCache = {};
  final Map<String, Map<String, dynamic>?> _activityCache = {};
  final Map<String, List<dynamic>> _dealsCache = {};

  String get _uid => _client.auth.currentUser!.id;

  void _clearCache() {
    _offersCache.clear();
    _activityCache.clear();
    _dealsCache.clear();
  }

  /// Fetch all lender offers for the current user from v_lender_offers.
  Future<List<LenderOffer>> getMyOffers() async {
    try {
      final data = await _client
          .from(ViewNames.lenderOffers)
          .select()
          .eq('lender_id', _uid)
          .neq('offer_status', 'withdrawn')
          .order('offered_at', ascending: false);

      final offers = (data as List).map((e) => LenderOffer.fromMap(e)).toList();
      _offersCache[_uid] = offers;
      OfflineService().reportRequestSuccess();
      return offers;
    } catch (e) {
      OfflineService().reportRequestFailure(e);
      final cached = _offersCache[_uid];
      if (cached != null && parseSupabaseError(e) is NetworkException) {
        return cached;
      }
      throw parseSupabaseError(e);
    }
  }

  /// Withdraw a pending offer.
  Future<void> withdrawOffer(String offerId) async {
    try {
      await _client
          .from(TableNames.loanOffers)
          .update({
            'status': 'withdrawn',
            'withdrawn_at': DateTime.now().toIso8601String(),
          })
          .eq('id', offerId)
          .eq('lender_id', _uid)
          .eq('status', 'pending');
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Dashboard summary from v_user_marketplace_activity.
  Future<Map<String, dynamic>?> getMarketplaceActivity() async {
    try {
      final data = await _client
          .from(ViewNames.userMarketplaceActivity)
          .select()
          .eq('user_id', _uid)
          .maybeSingle();
      _activityCache[_uid] = data;
      OfflineService().reportRequestSuccess();
      return data;
    } catch (e) {
      OfflineService().reportRequestFailure(e);
      if (parseSupabaseError(e) is NetworkException &&
          _activityCache.containsKey(_uid)) {
        return _activityCache[_uid];
      }
      return null;
    }
  }

  /// Fetch all active & contracted deals (agreements) for the current user.
  Future<List<dynamic>> getMyDeals() async {
    try {
      final data = await _client
          .from(TableNames.agreements)
          .select()
          .order('created_at', ascending: false);

      final agreements = (data as List);
      final deals = agreements.where((e) {
        final snapshot = e['agreement_snapshot'] as Map<String, dynamic>?;
        final bId = snapshot?['borrower_id'];
        final lId = snapshot?['lender_id'];
        return bId == _uid || lId == _uid;
      }).toList();
      _dealsCache[_uid] = deals;
      OfflineService().reportRequestSuccess();
      return deals;
    } catch (e) {
      OfflineService().reportRequestFailure(e);
      final cached = _dealsCache[_uid];
      if (cached != null && parseSupabaseError(e) is NetworkException) {
        return cached;
      }
      return [];
    }
  }

  /// Realtime stream on loan_offers for the current lender.
  Stream<List<LenderOffer>> watchMyOffers() {
    return _client
        .from(TableNames.loanOffers)
        .stream(primaryKey: ['id'])
        .eq('lender_id', _uid)
        .asyncMap((_) => getMyOffers());
  }
}
