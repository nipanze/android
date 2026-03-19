import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_errors.dart';

@lazySingleton
class LoanRepository {
  LoanRepository(this._supabase);
  final SupabaseClient _supabase;

  // ---------------------------------------------------------------------------
  // Create a loan request as 'draft'.
  // DB triggers enforce: trg_fn_require_kyc_for_loan, trg_fn_require_active_borrower
  // ---------------------------------------------------------------------------
  Future<String> createLoanRequest({
    required String borrowerId,
    required double requestedAmount,
    required String purpose,
    String? purposeDescription,
    required int durationMonths,
    double? maxInterestRate,
  }) async {
    try {
      final result = await _supabase
          .from(Tables.loanRequests)
          .insert({
            'borrower_id': borrowerId,
            'requested_amount': requestedAmount,
            'purpose': purpose,
            'purpose_description': purposeDescription,
            'duration_months': durationMonths,
            'max_interest_rate': maxInterestRate,
            'status': 'draft',
          })
          .select('request_id')
          .single();
      return result['request_id'] as String;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  // Publish draft → active. Sets listed_at and expires_at from system_settings.
  Future<void> publishLoanRequest(String requestId) async {
    try {
      final settingRow = await _supabase
          .from(Tables.systemSettings)
          .select('setting_value')
          .eq('setting_key', SettingKeys.listingDurationDays)
          .single();
      final days = int.parse(settingRow['setting_value'] as String);
      final now = DateTime.now();

      await _supabase.from(Tables.loanRequests).update({
        'status': 'active',
        'listed_at': now.toIso8601String(),
        'expires_at': now.add(Duration(days: days)).toIso8601String(),
      }).eq('request_id', requestId);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  // Borrower's own loan requests
  Future<List<Map<String, dynamic>>> getMyLoanRequests(String borrowerId) async {
    return await _supabase
        .from(Tables.loanRequests)
        .select()
        .eq('borrower_id', borrowerId)
        .order('created_at', ascending: false);
  }

  // Contracts where user is borrower
  Future<List<Map<String, dynamic>>> getMyContracts(String userId) async {
    return await _supabase
        .from(Tables.loanContracts)
        .select()
        .eq('borrower_id', userId)
        .order('created_at', ascending: false);
  }

  // Contracts where user is lender (via contract_bids junction)
  Future<List<Map<String, dynamic>>> getMyLenderContracts(String userId) async {
    return await _supabase
        .from(Tables.contractBids)
        .select('*, loan_contracts(*)')
        .eq('lender_id', userId)
        .order('created_at', ascending: false);
  }

  // Repayment schedule for a contract
  Future<List<Map<String, dynamic>>> getRepaymentSchedule(
      String contractId) async {
    return await _supabase
        .from(Tables.loanRepayments)
        .select()
        .eq('contract_id', contractId)
        .order('installment_number');
  }

  // Borrower signs contract
  Future<void> borrowerSign(String contractId, String signerIp) async {
    await _supabase.from(Tables.loanContracts).update({
      'borrower_signed': true,
      'borrower_signed_at': DateTime.now().toIso8601String(),
      'borrower_signature_ip': signerIp,
    }).eq('contract_id', contractId);
  }

  // Lender signs via contract_bids
  // trg_fn_check_all_lenders_signed fires on this UPDATE and may auto-activate
  Future<void> lenderSign(String contractBidId, String signerIp) async {
    await _supabase.from(Tables.contractBids).update({
      'lender_signed': true,
      'lender_signed_at': DateTime.now().toIso8601String(),
      'lender_signature_ip': signerIp,
    }).eq('contract_bid_id', contractBidId);
  }

  // Generate repayment schedule after contract activation
  Future<void> generateRepaymentSchedule(String contractId) async {
    await _supabase.rpc(Rpcs.calculateRepaymentSchedule,
        params: {'p_contract_id': contractId});
  }

  // Mock disbursement — MVP only, replaced by payment rail in Stage 4
  Future<void> mockDisburse(String contractId, String bidId) async {
    try {
      await _supabase.rpc(Rpcs.mockTopUp.replaceFirst('mock_top_up', 'mock_disburse'),
          params: {'p_contract_id': contractId, 'p_bid_id': bidId});
    } catch (e) {
      // Try the correct RPC name
      await _supabase.rpc('mock_disburse',
          params: {'p_contract_id': contractId, 'p_bid_id': bidId});
    }
  }

  // Mark repayment paid — MVP mock
  Future<void> mockRepayment(String repaymentId, double amountPaid) async {
    await _supabase.rpc('mock_repayment', params: {
      'p_repayment_id': repaymentId,
      'p_amount_paid': amountPaid,
    });
  }

  // Recalculate reputation score after contract events
  Future<void> recalculateReputation(String userId) async {
    final newScore = await _supabase.rpc(
      Rpcs.calculateReputationScore,
      params: {'p_user_id': userId},
    ) as int;

    await _supabase.from(Tables.users).update({
      'reputation_score': newScore,
      // reputation_tier auto-synced by trg_sync_reputation_tier
    }).eq('user_id', userId);
  }
}
