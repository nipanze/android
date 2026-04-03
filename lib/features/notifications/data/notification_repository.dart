// lib/features/notifications/data/notification_repository.dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../domain/models/app_notification.dart';

@lazySingleton
class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  /// Fetch all notifications for the current user, newest first.
  Future<List<AppNotification>> getNotifications() async {
    try {
      final data = await _client
          .from(TableNames.notifications)
          .select()
          .eq('user_id', _uid)
          .order('created_at', ascending: false)
          .limit(50);

      return (data as List)
          .map((e) => AppNotification.fromMap(e))
          .toList();
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Unread count only — lightweight query for the badge.
  Future<int> getUnreadCount() async {
    try {
      final data = await _client
          .from(TableNames.notifications)
          .select('id')
          .eq('user_id', _uid)
          .eq('is_read', false);

      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from(TableNames.notifications)
          .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId)
          .eq('user_id', _uid);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead() async {
    try {
      await _client
          .from(TableNames.notifications)
          .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
          .eq('user_id', _uid)
          .eq('is_read', false);
    } catch (e) {
      throw parseSupabaseError(e);
    }
  }

  /// Realtime stream — fires on any INSERT to notifications for this user.
  Stream<List<AppNotification>> watchNotifications() {
    return _client
        .from(TableNames.notifications)
        .stream(primaryKey: ['id'])
        .eq('user_id', _uid)
        .asyncMap((_) => getNotifications());
  }
}