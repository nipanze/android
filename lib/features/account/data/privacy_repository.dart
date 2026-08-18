import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../domain/models/blocked_user.dart';

@lazySingleton
class PrivacyRepository {
  PrivacyRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  Future<List<BlockedUser>> getBlockedUsers() async {
    try {
      final data = await _client
          .from(TableNames.userBlocks)
          .select('id, blocked_id, created_at, profiles!user_blocks_blocked_id_fkey(full_name, avatar_url)')
          .eq('blocker_id', _uid)
          .order('created_at', ascending: false);

      return (data as List)
          .map((row) => BlockedUser.fromMap(Map<String, dynamic>.from(row)))
          .toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<void> blockUser(String blockedId) async {
    try {
      await _client.from(TableNames.userBlocks).upsert(
        {
          'blocker_id': _uid,
          'blocked_id': blockedId,
        },
        onConflict: 'blocker_id,blocked_id',
      );
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<void> unblockUser(String blockedId) async {
    try {
      await _client
          .from(TableNames.userBlocks)
          .delete()
          .eq('blocker_id', _uid)
          .eq('blocked_id', blockedId);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }
}
