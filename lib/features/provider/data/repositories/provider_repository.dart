// lib/features/provider/data/repositories/provider_repository.dart

import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/offline_service.dart';
import '../../domain/entities/provider_capability.dart';
import '../../domain/entities/provider_opportunity.dart';
import '../../domain/repositories/provider_repository_interface.dart';

@LazySingleton(as: IProviderRepository)
class ProviderRepository implements IProviderRepository {
  ProviderRepository(this._client) {
    OfflineService().registerSessionCache(_clearCache);
  }

  final SupabaseClient _client;
  final Map<String, List<ProviderCapability>> _capabilityCache = {};
  final Map<String, List<ProviderOpportunity>> _opportunityCache = {};

  String? get _uid => _client.auth.currentUser?.id;

  void _clearCache() {
    _capabilityCache.clear();
    _opportunityCache.clear();
  }

  @override
  Future<List<ProviderCapability>> getProviderCapabilities() async {
    try {
      final uid = _uid;
      if (uid == null) return const [];
      final data = await _client
          .from(TableNames.providerCapabilities)
          .select(
            'id, user_id, capability_slug, verification_level, evidence_url, '
            'metadata, verified_by, verified_at, created_at, '
            'need_capabilities!capability_slug(name, category_slug, '
            'need_categories!category_slug(name, icon))',
          )
          .eq('user_id', uid)
          .order('created_at');

      final capabilities = (data as List).map((e) {
        final nc = e['need_capabilities'] as Map<String, dynamic>?;
        final cat =
            nc != null ? nc['need_categories'] as Map<String, dynamic>? : null;
        return ProviderCapability.fromMap({
          ...e,
          'capability_name': nc?['name'],
          'category_slug': nc?['category_slug'],
          'category_name': cat?['name'],
          'category_icon': cat?['icon'],
        });
      }).toList();
      _capabilityCache[uid] = capabilities;
      OfflineService().reportRequestSuccess();
      return capabilities;
    } catch (e) {
      OfflineService().reportRequestFailure(e);
      final uid = _uid;
      final cached = uid == null ? null : _capabilityCache[uid];
      if (cached != null && parseSupabaseError(e) is NetworkException) {
        return cached;
      }
      throw parseSupabaseError(e);
    }
  }

  @override
  Future<void> addCapabilities(
    List<String> slugs, {
    Map<String, Map<String, dynamic>> metadataBySlug = const {},
  }) async {
    try {
      final uid = _uid;
      if (uid == null) throw const AuthException('Not authenticated');
      final rows = slugs
          .map((s) => {
                'user_id': uid,
                'capability_slug': s,
                'verification_level': 'self_declared',
                if (metadataBySlug.containsKey(s))
                  'metadata': metadataBySlug[s],
              })
          .toList();
      await _client
          .from(TableNames.providerCapabilities)
          .upsert(rows, onConflict: 'user_id,capability_slug');
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  @override
  Future<void> removeCapability(String capabilitySlug) async {
    try {
      final uid = _uid;
      if (uid == null) throw const AuthException('Not authenticated');
      await _client
          .from(TableNames.providerCapabilities)
          .delete()
          .eq('user_id', uid)
          .eq('capability_slug', capabilitySlug);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  @override
  Future<bool> hasCapability(String capabilitySlug) async {
    try {
      final uid = _uid;
      if (uid == null) return false;
      final data = await _client
          .from(TableNames.providerCapabilities)
          .select('capability_slug')
          .eq('user_id', uid)
          .eq('capability_slug', capabilitySlug)
          .maybeSingle();
      return data != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<ProviderOpportunity>> getProviderOpportunities() async {
    try {
      final uid = _uid;
      if (uid == null) return const [];
      final data = await _client.rpc(
        RpcNames.getProviderOpportunities,
        params: {'p_user_id': uid},
      );
      final opportunities = (data as List)
          .map((e) => ProviderOpportunity.fromMap(e as Map<String, dynamic>))
          .toList();
      _opportunityCache[uid] = opportunities;
      OfflineService().reportRequestSuccess();
      return opportunities;
    } catch (e) {
      OfflineService().reportRequestFailure(e);
      final uid = _uid;
      final cached = uid == null ? null : _opportunityCache[uid];
      if (cached != null && parseSupabaseError(e) is NetworkException) {
        return cached;
      }
      return const [];
    }
  }
}
