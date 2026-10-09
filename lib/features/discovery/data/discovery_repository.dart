import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/models/discovery_question_template.dart';
import '../domain/models/user_discovery_plan.dart';

@lazySingleton
class DiscoveryRepository {
  DiscoveryRepository(this._client);

  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id;

  Future<DiscoveryQuestionTemplate?> getNextTemplate({
    required String country,
  }) async {
    final uid = _uid;
    if (uid == null) return null;

    try {
      final templateRows = await _client
          .from(TableNames.discoveryQuestionTemplates)
          .select()
          .eq('is_active', true)
          .order('priority', ascending: true)
          .order('created_at', ascending: true)
          .limit(20);
      final templates = (templateRows as List)
          .map((row) => DiscoveryQuestionTemplate.fromMap(
                Map<String, dynamic>.from(row as Map),
              ))
          .where((template) => template.isEligibleForCountry(country))
          .toList();
      if (templates.isEmpty) return null;

      final interactionRows = await _client
          .from(TableNames.userDiscoveryInteractions)
          .select(
              'template_id, action, dismissed_until, muted_until, created_at')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(80);

      final now = DateTime.now().toUtc();
      final unavailable = <String>{};
      for (final row in interactionRows as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final templateId = map['template_id'] as String?;
        if (templateId == null) continue;
        final action = map['action'] as String? ?? '';
        final dismissedUntil = _parseDateTime(map['dismissed_until']);
        final mutedUntil = _parseDateTime(map['muted_until']);
        final createdAt = _parseDateTime(map['created_at']);

        if (action == 'save' || action == 'answer') {
          unavailable.add(templateId);
        } else if (action == 'mute' &&
            (mutedUntil == null || mutedUntil.isAfter(now))) {
          unavailable.add(templateId);
        } else if ((action == 'dismiss' || action == 'skip') &&
            (dismissedUntil == null || dismissedUntil.isAfter(now))) {
          unavailable.add(templateId);
        } else if (action == 'skip' &&
            createdAt != null &&
            now.difference(createdAt).inDays < 7) {
          unavailable.add(templateId);
        }
      }

      for (final template in templates) {
        if (!unavailable.contains(template.id)) return template;
      }
      return null;
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<List<UserDiscoveryPlan>> getPlans() async {
    final uid = _uid;
    if (uid == null) return const [];

    try {
      final rows = await _client
          .from(TableNames.userDiscoveryPlans)
          .select()
          .eq('user_id', uid)
          .order('updated_at', ascending: false);
      return (rows as List)
          .map((row) =>
              UserDiscoveryPlan.fromMap(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<UserDiscoveryPlan> createPlan(DiscoveryPlanDraft draft) async {
    final uid = _uid;
    if (uid == null) throw const AuthException('Not signed in');

    try {
      final row = await _client
          .from(TableNames.userDiscoveryPlans)
          .insert(draft.toInsertMap(uid))
          .select()
          .single();
      if (draft.templateId != null) {
        await recordInteraction(
          templateId: draft.templateId!,
          action: 'save',
          answer: draft.answers,
        );
      }
      return UserDiscoveryPlan.fromMap(Map<String, dynamic>.from(row));
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<void> updatePlan(
    String planId, {
    required String title,
    String? destination,
    String? preferredLocation,
    DateTime? expectedDate,
    String? timeframe,
    String reminderPreference = 'none',
  }) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _client
          .from(TableNames.userDiscoveryPlans)
          .update({
            'title': title.trim(),
            'destination': _blankToNull(destination),
            'preferred_location': _blankToNull(preferredLocation),
            'expected_date': expectedDate?.toIso8601String().split('T').first,
            'timeframe': _blankToNull(timeframe),
            'reminder_preference': reminderPreference,
            'review_at': expectedDate
                ?.subtract(const Duration(days: 7))
                .toIso8601String(),
          })
          .eq('id', planId)
          .eq('user_id', uid);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<void> deletePlan(String planId) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _client
          .from(TableNames.userDiscoveryPlans)
          .delete()
          .eq('id', planId)
          .eq('user_id', uid);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<void> recordInteraction({
    required String templateId,
    required String action,
    Map<String, dynamic> answer = const {},
    Duration? dismissFor,
    Duration? muteFor,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final now = DateTime.now().toUtc();
    try {
      await _client.from(TableNames.userDiscoveryInteractions).insert({
        'user_id': uid,
        'template_id': templateId,
        'action': action,
        'answer': answer,
        'dismissed_until':
            dismissFor == null ? null : now.add(dismissFor).toIso8601String(),
        'muted_until':
            muteFor == null ? null : now.add(muteFor).toIso8601String(),
      });
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  DateTime? _parseDateTime(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toUtc();
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
