// lib/features/positions/data/positions_repository.dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../domain/models/lender_bid.dart';

@lazySingleton
class PositionsRepository {
  PositionsRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  /// Fetch all lender bids for the current user from v_lender_bids.
  Future<List<LenderBid>> getMyBids() async {
    try {
      final data = await _client
          .from(ViewNames.lenderBids)
          .select()
          .eq('lender_id', _uid)
          .order('placed_at', ascending: false);

      return (data as List).map((e) => LenderBid.fromMap(e)).toList();
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
          .eq('lender_id', _uid)
          .eq('status', 'pending');
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Fetch contracted positions where user is borrower or lender.
  Future<List<Map<String, dynamic>>> getMyContracts() async {
    try {
      final data = await _client
          .from(TableNames.contracts)
          .select('''
            id, status, amount, interest_rate, duration_months,
            purpose, district, repayment_start_date,
            indicative_monthly_payment_ugx,
            borrower_id, lender_id,
            loan_requests!inner(title)
          ''')
          .or('borrower_id.eq.$_uid,lender_id.eq.$_uid')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Portfolio summary from v_user_portfolio.
  Future<Map<String, dynamic>?> getPortfolioSummary() async {
    try {
      final data = await _client
          .from(ViewNames.userPortfolio)
          .select()
          .eq('user_id', _uid)
          .maybeSingle();
      return data;
    } catch (e) {
      return null;
    }
  }

  /// Realtime stream on loan_bids for the current lender.
  Stream<List<LenderBid>> watchMyBids() {
    return _client
        .from(TableNames.loanBids)
        .stream(primaryKey: ['id'])
        .eq('lender_id', _uid)
        .asyncMap((_) => getMyBids());
  }
}