// lib/features/provider/data/repositories/provider_repository.dart

import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/offline_service.dart';
import '../../domain/entities/provider_capability.dart';
import '../../domain/entities/provider_category_type.dart';
import '../../domain/entities/provider_company_profile.dart';
import '../../domain/entities/provider_opportunity.dart';
import '../../domain/entities/provider_service_role.dart';
import '../../domain/repositories/provider_repository_interface.dart';

@LazySingleton(as: IProviderRepository)
class ProviderRepository implements IProviderRepository {
  ProviderRepository(this._client) {
    OfflineService().registerSessionCache(_clearCache);
  }

  final SupabaseClient _client;
  final Map<String, List<ProviderCapability>> _capabilityCache = {};
  final Map<String, List<ProviderOpportunity>> _opportunityCache = {};
  bool? _capabilityProfilesEnabled;
  Map<String, ProviderCategoryType>? _categoryTypeCache;

  String? get _uid => _client.auth.currentUser?.id;

  void _clearCache() {
    _capabilityCache.clear();
    _opportunityCache.clear();
    _capabilityProfilesEnabled = null;
    _categoryTypeCache = null;
  }

  @override
  Future<Map<String, ProviderCategoryType>> getMyCategoryTypes() async {
    if (_categoryTypeCache != null) return Map.of(_categoryTypeCache!);
    try {
      final rows =
          await _client.rpc(RpcNames.getMyProviderCategoryTypes) as List;
      final result = <String, ProviderCategoryType>{};
      for (final row in rows.cast<Map<String, dynamic>>()) {
        final type = ProviderCategoryType.fromValue(row['provider_type']);
        if (type != null) result[row['category_slug'].toString()] = type;
      }
      _categoryTypeCache = result;
      return Map.of(result);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  @override
  Future<void> setCategoryType(
      String categorySlug, ProviderCategoryType type) async {
    try {
      await _client.rpc(RpcNames.setProviderCategoryType, params: {
        'p_category_slug': categorySlug,
        'p_provider_type': type.name,
      });
      _categoryTypeCache ??= {};
      _categoryTypeCache![categorySlug] = type;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  @override
  Future<ProviderCompanyProfile?> getCompanyProfile(String categorySlug) async {
    try {
      final row = await _client
          .from(TableNames.providerCompanyProfiles)
          .select()
          .eq('category_slug', categorySlug)
          .maybeSingle();
      return row == null ? null : ProviderCompanyProfile.fromMap(row);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCompanyVerificationRequirements({
    required String categorySlug,
    required List<String> serviceSlugs,
  }) async {
    if (serviceSlugs.isEmpty) return const [];
    try {
      final scopeIds = {...serviceSlugs, categorySlug}.toList();
      final rows = await _client
          .from(TableNames.verificationRequirements)
          .select(
              'scope_type, scope_id, evidence_requirements, required_evidence')
          .eq('is_active', true)
          .inFilter('scope_type', ['category', 'capability']).inFilter(
              'scope_id', scopeIds);
      return (rows as List)
          .whereType<Map>()
          .map((row) => row.cast<String, dynamic>())
          .toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCompanyEvidence({
    required String categorySlug,
    required List<String> serviceSlugs,
  }) async {
    final uid = _uid;
    if (uid == null || serviceSlugs.isEmpty) return const [];
    try {
      final rows = await _client
          .from(TableNames.providerCapabilities)
          .select(
              'id, capability_slug, provider_capability_evidence(id, requirement_key, file_url, status, reject_reason, expires_at, created_at)')
          .eq('user_id', uid)
          .inFilter('capability_slug', serviceSlugs);
      return (rows as List)
          .whereType<Map>()
          .map((row) => row.cast<String, dynamic>())
          .toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  @override
  Future<void> saveCompanyCategory({
    required String categorySlug,
    required List<String> serviceSlugs,
    required List<String> roleCapabilitySlugs,
    required Map<String, dynamic> profile,
    required List<Map<String, String>> evidence,
  }) async {
    try {
      await _client.rpc(RpcNames.saveCompanyCategory, params: {
        'p_category_slug': categorySlug,
        'p_services': serviceSlugs,
        'p_roles': roleCapabilitySlugs,
        'p_profile': profile,
        'p_evidence': evidence,
      });
      _clearCache();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  @override
  Future<String> uploadCompanyEvidence({
    required String categorySlug,
    required String requirementKey,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    final uid = _uid;
    if (uid == null) throw const AuthException('Not authenticated');
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      throw const FormatException('Evidence files must be 5 MB or smaller.');
    }
    const allowed = {'image/jpeg', 'image/png', 'application/pdf'};
    if (!allowed.contains(mimeType.toLowerCase())) {
      throw const FormatException('Choose a JPG, PNG, or PDF file.');
    }
    final safeKey = Uri.encodeComponent(requirementKey.trim());
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path =
        'evidence/$uid/$categorySlug/$safeKey/${DateTime.now().microsecondsSinceEpoch}_$safeName';
    try {
      await _client.storage.from('provider-evidence').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: false),
          );
      return path;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  @override
  Future<bool> capabilityProfilesEnabled() async {
    if (_capabilityProfilesEnabled != null) {
      return _capabilityProfilesEnabled!;
    }
    try {
      final data = await _client
          .from(TableNames.systemSettings)
          .select('setting_value')
          .eq('setting_key', 'capability_profiles_enabled')
          .eq('is_public', true)
          .maybeSingle();
      final value = data?['setting_value']?.toString().toLowerCase();
      _capabilityProfilesEnabled = value == 'true' || value == '1';
      return _capabilityProfilesEnabled!;
    } catch (_) {
      _capabilityProfilesEnabled = false;
      return false;
    }
  }

  @override
  Future<bool> workProfilesEnabled() async {
    try {
      final data = await _client
          .from(TableNames.systemSettings)
          .select('setting_value')
          .eq('setting_key', 'work_profiles_enabled')
          .eq('is_public', true)
          .maybeSingle();
      final value = data?['setting_value']?.toString().toLowerCase();
      return value == 'true' || value == '1';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isCategoryWorkProfileEnabled(String categorySlug) async {
    final globalEnabled = await workProfilesEnabled();
    if (!globalEnabled) return false;
    try {
      final data = await _client
          .from(TableNames.systemSettings)
          .select('setting_value')
          .eq('setting_key', 'work_profiles_enabled_$categorySlug')
          .eq('is_public', true)
          .maybeSingle();
      if (data == null) {
        return true; // Default true if global is enabled and no specific override
      }
      final value = data['setting_value']?.toString().toLowerCase();
      return value != 'false' && value != '0';
    } catch (_) {
      return true;
    }
  }

  @override
  Future<List<ProviderCapability>> getProviderCapabilities() async {
    try {
      final uid = _uid;
      if (uid == null) return const [];
      if (await capabilityProfilesEnabled()) {
        try {
          final data = await _client
              .from(ViewNames.myCapabilityStatus)
              .select()
              .eq('user_id', uid)
              .order('created_at');
          final capabilities = (data as List)
              .map((e) => ProviderCapability.fromMap(e as Map<String, dynamic>))
              .toList();
          _capabilityCache[uid] = capabilities;
          OfflineService().reportRequestSuccess();
          return capabilities;
        } catch (_) {
          // Fall back to the stable base-table query when the SQL patch has
          // not landed yet or the view is temporarily unavailable.
        }
      }

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
  Future<void> saveProviderCapabilitiesBulk({
    required List<Map<String, dynamic>> items,
    String? categorySlug,
    List<String> removeSlugs = const [],
  }) async {
    try {
      final uid = _uid;
      if (uid == null) throw const AuthException('Not authenticated');

      try {
        await _client.rpc(
          RpcNames.saveProviderCapabilities,
          params: {
            'p_items': items,
            'p_category_slug': categorySlug,
            'p_remove_slugs': removeSlugs,
          },
        );
      } catch (rpcErr) {
        // Fall back to direct table operations if RPC not present in db yet
        if (removeSlugs.isNotEmpty) {
          await _client
              .from(TableNames.providerCapabilities)
              .delete()
              .eq('user_id', uid)
              .filter('capability_slug', 'in', removeSlugs);
        }
        if (items.isNotEmpty) {
          final rows = items
              .map((it) => {
                    'user_id': uid,
                    'capability_slug': it['capability_slug'],
                    'verification_level': 'self_declared',
                    if (it['metadata'] != null) 'metadata': it['metadata'],
                  })
              .toList();
          await _client
              .from(TableNames.providerCapabilities)
              .upsert(rows, onConflict: 'user_id,capability_slug');
        }
      }
      _clearCache();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  @override
  Future<void> setCapabilityPaused({
    required String capabilitySlug,
    required bool paused,
  }) async {
    try {
      final uid = _uid;
      if (uid == null) throw const AuthException('Not authenticated');

      final existing = await _client
          .from(TableNames.providerCapabilities)
          .select('metadata')
          .eq('user_id', uid)
          .eq('capability_slug', capabilitySlug)
          .maybeSingle();

      final meta =
          Map<String, dynamic>.from(existing?['metadata'] as Map? ?? {});
      meta['is_paused'] = paused;

      await _client
          .from(TableNames.providerCapabilities)
          .update({
            'metadata': meta,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('user_id', uid)
          .eq('capability_slug', capabilitySlug);
      _clearCache();
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
  Future<String> submitCapabilityEvidence({
    required String providerCapabilityId,
    required String requirementKey,
    required String fileUrl,
  }) async {
    try {
      final result = await _client.rpc(
        RpcNames.submitProviderCapabilityEvidence,
        params: {
          'p_provider_capability_id': providerCapabilityId,
          'p_requirement_key': requirementKey,
          'p_file_url': fileUrl,
        },
      );
      _clearCache();
      return result as String;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  @override
  Future<String> submitRoleQualificationEvidence({
    required String providerCapabilityId,
    required String roleSlug,
    required String qualificationSlug,
    required String evidenceObjectPath,
  }) async {
    try {
      final result = await _client.rpc(
        RpcNames.submitProviderRoleQualificationEvidence,
        params: {
          'p_provider_capability_id': providerCapabilityId,
          'p_role_slug': roleSlug,
          'p_qualification_slug': qualificationSlug,
          'p_evidence_object_path': evidenceObjectPath,
        },
      );
      _clearCache();
      return result as String;
    } catch (e) {
      throw parseSupabaseError(e);
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

  @override
  Future<List<ProviderServiceRole>> getServiceRoles({
    String? categorySlug,
    String? capabilitySlug,
  }) async {
    try {
      var query = _client.from(TableNames.capabilityRoles).select(
            'slug, name, kind_question, category_slug, capability_slug, '
            'role_kinds(slug, name, sort_order), '
            'role_qualifications(slug, name, is_evidence, sort_order)',
          );

      if (capabilitySlug != null) {
        query = query.or(
          'capability_slug.eq.$capabilitySlug,category_slug.eq.$categorySlug',
        ) as dynamic;
      } else if (categorySlug != null) {
        query = query.eq('category_slug', categorySlug) as dynamic;
      }

      final data = await (query as PostgrestFilterBuilder)
          .eq('is_active', true)
          .order('name', ascending: true);

      final roles = (data as List)
          .map((row) => ProviderServiceRole.fromMap(
                row as Map<String, dynamic>,
              ))
          .toList();
      if (roles.isNotEmpty) return roles;
    } catch (_) {}

    return ProviderServiceRole.defaultsForCategory(categorySlug);
  }
}
