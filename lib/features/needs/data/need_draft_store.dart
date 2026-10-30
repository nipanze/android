import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Device-local drafts for Need requests. Drafts are scoped to the signed-in
/// account and never appear in the public marketplace until published.
class NeedDraftStore {
  static const retentionPeriod = Duration(days: 30);

  static String _key(String userId) => 'need_request_drafts_$userId';

  static Future<List<Map<String, dynamic>>> load(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key(userId));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final drafts = decoded
          .whereType<Map>()
          .map(Map<String, dynamic>.from)
          .where(_isWithinRetentionPeriod)
          .toList();
      if (drafts.length != decoded.length) {
        await preferences.setString(_key(userId), jsonEncode(drafts));
      }
      return drafts;
    } catch (_) {
      return const [];
    }
  }

  static bool _isWithinRetentionPeriod(Map<String, dynamic> draft) {
    final savedAt = DateTime.tryParse(draft['saved_at']?.toString() ?? '');
    // Keep legacy drafts whose save date is unknown rather than deleting them
    // without a reliable age.
    return savedAt == null ||
        DateTime.now().difference(savedAt) <= retentionPeriod;
  }

  static Future<Map<String, dynamic>> save(
    String userId,
    Map<String, dynamic> draft, {
    String? id,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final drafts = (await load(userId)).toList();
    final draftId = id ?? DateTime.now().microsecondsSinceEpoch.toString();
    final saved = <String, dynamic>{
      ...draft,
      'draft_id': draftId,
      'saved_at': DateTime.now().toIso8601String(),
    };
    final index = drafts.indexWhere((item) => item['draft_id'] == draftId);
    if (index >= 0) {
      drafts[index] = saved;
    } else {
      drafts.insert(0, saved);
    }
    await preferences.setString(_key(userId), jsonEncode(drafts));
    return saved;
  }

  static Future<Map<String, dynamic>?> find(
    String userId,
    String draftId,
  ) async {
    for (final draft in await load(userId)) {
      if (draft['draft_id'] == draftId) return draft;
    }
    return null;
  }

  static Future<void> delete(String userId, String draftId) async {
    final preferences = await SharedPreferences.getInstance();
    final drafts = (await load(userId)).toList();
    drafts.removeWhere((draft) => draft['draft_id'] == draftId);
    await preferences.setString(_key(userId), jsonEncode(drafts));
  }
}
