// lib/features/activity/data/activity_repository.dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../domain/models/lender_offer.dart';

@lazySingleton
class ActivityRepository {
  ActivityRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  /// Fetch all lender offers for the current user from v_lender_offers.
  Future<List<LenderOffer>> getMyOffers() async {
    try {
      final data = await _client
          .from(ViewNames.lenderOffers)
          .select()
          .eq('lender_id', _uid)
          .neq('offer_status', 'withdrawn')
          .order('offered_at', ascending: false);

      return (data as List).map((e) => LenderOffer.fromMap(e)).toList();
    } catch (e) {
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
      return data;
    } catch (e) {
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
      return agreements.where((e) {
        final snapshot = e['agreement_snapshot'] as Map<String, dynamic>?;
        final bId = snapshot?['borrower_id'];
        final lId = snapshot?['lender_id'];
        return bId == _uid || lId == _uid;
      }).toList();
    } catch (e) {
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
