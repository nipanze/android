// lib/features/marketplace/data/agreement_repository.dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../domain/models/agreement.dart';

@lazySingleton
class AgreementRepository {
  AgreementRepository(this._client);

  final SupabaseClient _client;

  /// Fetch an agreement by ID.
  Future<Agreement> getAgreement(String agreementId) async {
    try {
      final data = await _client
          .from(TableNames.agreements)
          .select()
          .eq('id', agreementId)
          .single();

      return Agreement.fromMap(data);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Fetch agreement by offer ID.
  Future<Agreement?> getAgreementByOfferId(String offerId) async {
    try {
      final data = await _client
          .from(TableNames.agreements)
          .select()
          .eq('offer_id', offerId)
          .maybeSingle();

      return data != null ? Agreement.fromMap(data) : null;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Confirm agreement as current user (borrower or lender).
  /// Returns updated agreement status JSON.
  Future<Map<String, dynamic>> confirmAgreement(String agreementId) async {
    try {
      final result = await _client.rpc(
        RpcNames.confirmAgreement,
        params: {'p_agreement_id': agreementId},
      );
      return result as Map<String, dynamic>;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Borrower unlocks contact details after agreement is locked.
  /// Returns contact reveal data (both parties' contact info).
  Future<ContactRevealData> unlockContact(String agreementId) async {
    try {
      final result = await _client.rpc(
        RpcNames.unlockContact,
        params: {'p_agreement_id': agreementId},
      );
      return ContactRevealData.fromJson(result as Map<String, dynamic>);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Real-time stream for agreement updates.
  Stream<Agreement?> watchAgreement(String agreementId) {
    return _client
        .from(TableNames.agreements)
        .stream(primaryKey: ['id'])
        .eq('id', agreementId)
        .map((rows) {
      if (rows.isEmpty) return null;
      return Agreement.fromMap(rows.first);
    });
  }

  /// Update agreement (edit repayment terms before locking).
  /// Only allowed while status is 'pending'.
  Future<void> updateAgreement({
    required String agreementId,
    required int repaymentAmount,
    required double penaltyPercentage,
  }) async {
    try {
      await _client.from(TableNames.agreements).update({
        'repayment_amount': repaymentAmount,
        'late_payment_penalty_pct': penaltyPercentage,
      }).eq('id', agreementId);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }
}
