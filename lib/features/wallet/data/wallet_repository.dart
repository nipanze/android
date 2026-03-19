import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_errors.dart';
import '../../../shared/models/wallet_model.dart';

@lazySingleton
class WalletRepository {
  WalletRepository(this._supabase);
  final SupabaseClient _supabase;

  // ---------------------------------------------------------------------------
  // Real-time stream for a user's wallet
  // ---------------------------------------------------------------------------
  Stream<WalletModel> watchWallet(String userId) {
    return _supabase
        .from(Tables.walletBalances)
        .stream(primaryKey: ['wallet_id'])
        .eq('user_id', userId)
        .map((rows) {
          if (rows.isEmpty) throw ServerException('Wallet not found for user $userId');
          return WalletModel.fromJson(rows.first);
        });
  }

  // ---------------------------------------------------------------------------
  // Single fetch (for validators, not real-time display)
  // ---------------------------------------------------------------------------
  Future<WalletModel> getWallet(String userId) async {
    final row = await _supabase
        .from(Tables.walletBalances)
        .select()
        .eq('user_id', userId)
        .single();
    return WalletModel.fromJson(row);
  }

  // ---------------------------------------------------------------------------
  // Mock top-up — MVP only. Replaced by Mobile Money in Stage 4.
  // Calls the `mock_top_up` Postgres RPC which atomically:
  //   1. Increments wallet_balances.lendable_balance
  //   2. Writes an audit_logs row
  // ---------------------------------------------------------------------------
  Future<void> mockTopUp({required String userId, required double amount}) async {
    if (amount <= 0) throw const ValidationException('Amount must be greater than zero.');

    try {
      await _supabase.rpc(Rpcs.mockTopUp, params: {
        'p_user_id': userId,
        'p_amount': amount,
      });
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Transaction history: disbursements + repayment_transactions for a user
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getTransactionHistory(String userId,
      {int limit = 50}) async {
    // Disbursements received (borrower side)
    final disbursements = await _supabase
        .from(Tables.disbursements)
        .select('disbursement_id, amount, status, completed_at, payment_method')
        .eq('borrower_id', userId)
        .eq('status', 'completed')
        .order('completed_at', ascending: false)
        .limit(limit);

    // Repayment transactions (both sides)
    final repayments = await _supabase
        .from(Tables.repaymentTransactions)
        .select('transaction_id, amount, status, completed_at, payment_method, lender_id, borrower_id')
        .or('borrower_id.eq.$userId,lender_id.eq.$userId')
        .eq('status', 'completed')
        .order('completed_at', ascending: false)
        .limit(limit);

    return [
      ...disbursements.map((d) => {'type': 'disbursement', ...d}),
      ...repayments.map((r) => {'type': 'repayment', ...r}),
    ]..sort((a, b) {
        final aDate = DateTime.parse(a['completed_at'] as String? ?? '2000-01-01');
        final bDate = DateTime.parse(b['completed_at'] as String? ?? '2000-01-01');
        return bDate.compareTo(aDate);
      });
  }
}
