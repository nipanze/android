// lib/features/kyc/data/verification_service.dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../auth/domain/models/nipanze_user.dart';
import '../domain/models/verification_requirement.dart';

@lazySingleton
class VerificationService {
  VerificationService(this._client);

  final SupabaseClient _client;
  List<VerificationRequirement>? _cachedRequirements;
  DateTime? _lastFetch;

  /// Fetches all active verification requirements from DB (cached for 2 minutes).
  Future<List<VerificationRequirement>> getRequirements({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedRequirements != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < const Duration(minutes: 2)) {
      return _cachedRequirements!;
    }

    try {
      final data = await _client
          .from(TableNames.verificationRequirements)
          .select()
          .eq('is_active', true);

      final list = (data as List)
          .map((row) => VerificationRequirement.fromMap(row as Map<String, dynamic>))
          .toList();

      _cachedRequirements = list;
      _lastFetch = DateTime.now();
      return list;
    } catch (e) {
      if (_cachedRequirements != null) return _cachedRequirements!;
      return const [];
    }
  }

  /// Evaluates whether a user can perform an action based on hierarchical rules
  /// (Capability -> Category -> Activity -> Global).
  Future<VerificationCheckResult> canPerform({
    required String action, // e.g. 'loan_request', 'forex_request', 'need_request', 'loan_offer', 'forex_offer', 'need_offer', 'service_offer'
    String? categorySlug,
    String? capabilitySlug,
    NipanzeUser? user,
  }) async {
    final currentUser = user ?? _getCurrentUser();
    if (currentUser == null) {
      return const VerificationCheckResult(
        allowed: false,
        reason: 'authentication_required',
        missingRequirements: ['authentication'],
      );
    }

    try {
      // 1. First, attempt to call the database security function for authoritative decision
      final response = await _client.rpc(
        RpcNames.canPerformMarketplaceActivity,
        params: {
          'p_activity': action,
          if (categorySlug != null) 'p_category_slug': categorySlug,
          if (capabilitySlug != null) 'p_capability_slug': capabilitySlug,
        },
      );

      if (response != null && response is Map<String, dynamic>) {
        return VerificationCheckResult.fromMap(response);
      }
    } catch (_) {
      // Fall back to client-side rule evaluation if offline or RPC fails
    }

    // Client-side fallback evaluation
    final rules = await getRequirements();
    VerificationRequirement? matchedRule;

    // 1. Most specific: capability
    if (capabilitySlug != null) {
      matchedRule = rules.cast<VerificationRequirement?>().firstWhere(
            (r) => r?.scopeType == 'capability' && r?.scopeId == capabilitySlug,
            orElse: () => null,
          );
    }

    // 2. Next: category
    if (matchedRule == null && categorySlug != null) {
      matchedRule = rules.cast<VerificationRequirement?>().firstWhere(
            (r) => r?.scopeType == 'category' && r?.scopeId == categorySlug,
            orElse: () => null,
          );
    }

    // 3. Next: activity
    matchedRule ??= rules.cast<VerificationRequirement?>().firstWhere(
          (r) => r?.scopeType == 'activity' && r?.scopeId == action,
          orElse: () => null,
        );

    // 4. Global fallback
    matchedRule ??= rules.cast<VerificationRequirement?>().firstWhere(
          (r) => r?.scopeType == 'global',
          orElse: () => const VerificationRequirement(
            id: 'default',
            scopeType: 'global',
            scopeId: 'global',
            identityRequired: true,
          ),
        );

    final missing = <String>[];
    String? reason;

    if (matchedRule!.identityRequired && !currentUser.kycApproved) {
      missing.add('identity_verification_required');
      reason ??= 'identity_verification_required';
    }

    return VerificationCheckResult(
      allowed: missing.isEmpty,
      reason: reason,
      missingRequirements: missing,
      requirement: matchedRule,
    );
  }

  /// Admin: Fetch all requirements (including inactive)
  Future<List<VerificationRequirement>> adminGetRequirements() async {
    try {
      final data = await _client.rpc(RpcNames.adminGetVerificationRequirements);
      return (data as List)
          .map((row) => VerificationRequirement.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback query
      final data = await _client
          .from(TableNames.verificationRequirements)
          .select()
          .order('scope_type');
      return (data as List)
          .map((row) => VerificationRequirement.fromMap(row as Map<String, dynamic>))
          .toList();
    }
  }

  /// Admin: Update requirement
  Future<bool> adminUpdateRequirement({
    required String id,
    required bool identityRequired,
    required bool phoneRequired,
    required bool providerVerificationRequired,
    List<String> evidenceRequirements = const [],
    bool isActive = true,
  }) async {
    try {
      await _client.rpc(
        RpcNames.adminUpdateVerificationRequirement,
        params: {
          'p_id': id,
          'p_identity_required': identityRequired,
          'p_phone_required': phoneRequired,
          'p_provider_verification_required': providerVerificationRequired,
          'p_evidence_requirements': evidenceRequirements,
          'p_is_active': isActive,
        },
      );
      _cachedRequirements = null; // Invalidate cache
      return true;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  NipanzeUser? _getCurrentUser() {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return NipanzeUser(
      id: user.id,
      email: user.email ?? '',
    );
  }
}
