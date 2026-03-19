// ignore_for_file: unnecessary_lambdas

import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_errors.dart';
import '../../../shared/models/notification_model.dart';

@lazySingleton
class NotificationRepository {
  NotificationRepository(this._supabase);
  final SupabaseClient _supabase;

  // Real-time stream for current user's notifications
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _supabase
        .from(Tables.notifications)
        .stream(primaryKey: ['notification_id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map((r) => NotificationModel.fromJson(r)).toList());
  }

  Future<void> markRead(String notificationId) async {
    await _supabase.from(Tables.notifications).update({
      'read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('notification_id', notificationId);
  }

  Future<void> markAllRead(String userId) async {
    await _supabase
        .from(Tables.notifications)
        .update({'read': true, 'read_at': DateTime.now().toIso8601String()})
        .eq('user_id', userId)
        .eq('read', false);
  }

  // Write notification from client code (Stages 1–3).
  // Stage 4: Edge Functions handle this via DB webhooks.
  Future<void> write({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabase.from(Tables.notifications).insert({
        'user_id': userId,
        'type': type,
        'title': title,
        'message': message,
        if (data != null) 'data': data,
      });
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  Future<int> unreadCount(String userId) async {
    final response = await _supabase
        .from(Tables.notifications)
        .select('notification_id')
        .eq('user_id', userId)
        .eq('read', false);
    return response.length;
  }
}
