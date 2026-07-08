// lib/features/positions/data/positions_repository.dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../domain/models/lender_offer.dart';

@lazySingleton
class PositionsRepository {
  PositionsRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  /// Fetch all lender offers for the current user from v_lender_offers.
  Future<List<LenderOffer>> getMyOffers() async {
    try {
      final data = await _client
          .from(ViewNames.lenderOffers)
          .select()
          .eq('lender_id', _uid)
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
          .update({'status': 'withdrawn'})
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

  /// Realtime stream on loan_offers for the current lender.
  Stream<List<LenderOffer>> watchMyOffers() {
    return _client
        .from(TableNames.loanOffers)
        .stream(primaryKey: ['id'])
        .eq('lender_id', _uid)
        .asyncMap((_) => getMyOffers());
  }
}
