// lib/features/contracts/data/contract_repository.dart
// lib/features/contracts/data/contract_repository.dart
import 'package:injectable/injectable.dart';
import 'package:nipanze/features/marketplace/domain/models/loan_listing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../domain/models/negotiator_info.dart';

@lazySingleton
class ContractRepository {
  ContractRepository(this._client);

  final SupabaseClient _client;
  String get _uid => _client.auth.currentUser!.id;

  Future<ContractSummary> getContract(String contractId) async {
    try {
      final data = await _client
          .from(TableNames.contracts)
          .select()
          .eq('id', contractId)
          .single();
      return ContractSummary.fromMap(data);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<List<RepaymentLine>> getSchedule(String contractId) async {
    try {
      final data = await _client
          .from(TableNames.repaymentSchedules)
          .select()
          .eq('contract_id', contractId)
          .order('instalment_number');
      return (data as List).map((e) => RepaymentLine.fromMap(e)).toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<NegotiatorInfo?> getNegotiator(String contractId) async {
    try {
      final data = await _client
          .from(TableNames.negotiatorAssignments)
          .select('negotiators!inner(id, full_name, credentials, specialisation, deals_completed, avg_rating, phone, email)')
          .eq('contract_id', contractId)
          .maybeSingle();
      if (data == null) return null;
      final n = data['negotiators'] as Map<String, dynamic>;
      return NegotiatorInfo.fromMap(n);
    } catch (e) {
      return null;
    }
  }

  Future<ContactReveal?> getMyReveal(String contractId) async {
    try {
      final data = await _client
          .from(TableNames.contactReveals)
          .select()
          .eq('contract_id', contractId)
          .eq('revealed_by', _uid)
          .maybeSingle();
      return data != null ? ContactReveal.fromMap(data) : null;
    } catch (e) {
      return null;
    }
  }

  Future<ContactReveal> confirmReveal(String contractId) async {
    try {
      final existing = await getMyReveal(contractId);

      if (existing != null && existing.isRevealed) return existing;

      final Map<String, dynamic> payload = {
        'contract_id':        contractId,
        'revealed_by':        _uid,
        'reveals_borrower':   true,
        'reveals_lender':     true,
        'reveals_negotiator': true,
        'status':             'revealed',
        'revealed_at':        DateTime.now().toIso8601String(),
      };

      late Map<String, dynamic> result;
      if (existing == null) {
        result = await _client
            .from(TableNames.contactReveals)
            .insert(payload)
            .select()
            .single();
      } else {
        // existing.id is non-null for a persisted record; assert to satisfy type checker
        result = await _client
            .from(TableNames.contactReveals)
            .update({'status': 'revealed',
                     'revealed_at': DateTime.now().toIso8601String()})
            .eq('id', existing.id)   // ← null-asserted: id always present on fetched row
            .select()
            .single();
      }

      return ContactReveal.fromMap(result);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<void> reportRepayment(String scheduleId, String status) async {
    try {
      await _client
          .from(TableNames.repaymentSchedules)
          .update({
            'reported_status': status,
            'reported_at':     DateTime.now().toIso8601String(),
            'reported_by':     _uid,
          })
          .eq('id', scheduleId);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }
}