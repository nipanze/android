import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../provider/domain/entities/provider_service_role.dart';
import '../domain/models/job_profile.dart';

class JobProfileRepository {
  const JobProfileRepository(this._client);

  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id;

  Future<bool> jobProfilesEnabled() async {
    try {
      final data = await _client
          .from(TableNames.systemSettings)
          .select('setting_value')
          .eq('setting_key', 'job_profiles_enabled')
          .eq('is_public', true)
          .maybeSingle();
      final value = data?['setting_value']?.toString().toLowerCase();
      return value == 'true' || value == '1';
    } catch (_) {
      return false;
    }
  }

  Future<List<JobProfile>> getMyProfiles() async {
    try {
      final uid = _uid;
      if (uid == null) return const [];
      final data = await _client
          .from(ViewNames.myJobProfiles)
          .select()
          .eq('user_id', uid)
          .order('updated_at', ascending: false);
      return (data as List)
          .map((row) => JobProfile.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<List<ProviderServiceRole>> getRoles(String categorySlug) async {
    try {
      final data = await _client
          .from(TableNames.capabilityRoles)
          .select(
            'slug, name, kind_question, category_slug, capability_slug, '
            'role_kinds(slug, name, sort_order), '
            'role_qualifications(slug, name, is_evidence, sort_order)',
          )
          .eq('category_slug', categorySlug)
          .eq('is_active', true)
          .order('name', ascending: true);
      final list = (data as List)
          .map((row) => ProviderServiceRole.fromMap(
                row as Map<String, dynamic>,
              ))
          .toList();
      if (list.isNotEmpty) return list;
      return ProviderServiceRole.defaultsForCategory(categorySlug);
    } catch (_) {
      return ProviderServiceRole.defaultsForCategory(categorySlug);
    }
  }

  Future<void> saveProfile(JobProfileDraft draft) async {
    try {
      final uid = _uid;
      if (uid == null) throw const AuthException('Not authenticated');

      final profile = await _client
          .from(TableNames.jobProfiles)
          .upsert(
            {
              'user_id': uid,
              'category_slug': draft.categorySlug,
              'is_active': true,
              'availability': draft.availability,
              'preferred_location': draft.preferredLocation,
              'remote_preference': draft.remotePreference,
              'preferred_currency': draft.preferredCurrency,
              'expected_pay_amount': draft.expectedPayAmount,
              'expected_pay_period': draft.expectedPayPeriod,
              'languages': draft.languages,
              'summary': draft.summary,
            },
            onConflict: 'user_id,category_slug',
          )
          .select('id')
          .single();

      final profileId = profile['id'] as String;

      await _client
          .from(TableNames.jobProfileRoles)
          .delete()
          .eq('job_profile_id', profileId);

      for (final role in draft.roles) {
        final insertedRole = await _client
            .from(TableNames.jobProfileRoles)
            .insert({
              'job_profile_id': profileId,
              'role_slug': role.roleSlug,
              'is_active': true,
              'years_experience': role.yearsExperience,
            })
            .select('id')
            .single();
        final roleAssignmentId = insertedRole['id'] as String;

        if (role.workTypeSlugs.isNotEmpty) {
          await _client.from(TableNames.jobProfileRoleWorkTypes).insert([
            for (final slug in role.workTypeSlugs)
              {
                'job_profile_role_id': roleAssignmentId,
                'role_slug': role.roleSlug,
                'work_type_slug': slug,
              },
          ]);
        }

        if (role.qualificationSlugs.isNotEmpty) {
          await _client.from(TableNames.jobProfileQualificationAnswers).insert([
            for (final slug in role.qualificationSlugs)
              {
                'job_profile_role_id': roleAssignmentId,
                'role_slug': role.roleSlug,
                'qualification_slug': slug,
                'answer': {'declared': true},
              },
          ]);
        }
      }
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<void> deactivateProfile(String profileId) async {
    try {
      await _client
          .from(TableNames.jobProfiles)
          .update({'is_active': false}).eq('id', profileId);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }
}
