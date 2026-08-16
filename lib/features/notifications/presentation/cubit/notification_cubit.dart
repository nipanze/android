// lib/features/notifications/presentation/cubit/notification_cubit.dart
// ignore_for_file: directives_ordering

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/notification_repository.dart';
import '../../domain/models/app_notification.dart';

part 'notification_state.dart';

@injectable
class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit(this._repository) : super(const NotificationInitial());

  final NotificationRepository _repository;
  StreamSubscription<List<AppNotification>>? _sub;

  Future<void> load() async {
    emit(const NotificationLoading());
    try {
      final notifications = await _repository.getNotifications();
      final unread = notifications.where((n) => !n.isRead).length;
      emit(NotificationLoaded(
          notifications: notifications, unreadCount: unread));
      _subscribeRealtime();
    } catch (e) {
      emit(NotificationError(userFacingErrorMessage(e)));
    }
  }

  void _subscribeRealtime() {
    _sub?.cancel();
    _sub = _repository.watchNotifications().listen(
      (notifications) {
        if (!isClosed) {
          final unread = notifications.where((n) => !n.isRead).length;
          emit(NotificationLoaded(
              notifications: notifications, unreadCount: unread));
        }
      },
      onError: (_) {},
    );
  }

  Future<void> markAsRead(String notificationId) async {
    if (state is! NotificationLoaded) return;
    final current = state as NotificationLoaded;

    // Optimistic update
    final updated = current.notifications
        .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
        .toList();
    final unread = updated.where((n) => !n.isRead).length;
    emit(NotificationLoaded(notifications: updated, unreadCount: unread));

    try {
      await _repository.markAsRead(notificationId);
    } catch (_) {
      emit(current); // rollback
    }
  }

  Future<void> markAllAsRead() async {
    if (state is! NotificationLoaded) return;
    final current = state as NotificationLoaded;

    final updated =
        current.notifications.map((n) => n.copyWith(isRead: true)).toList();
    emit(NotificationLoaded(notifications: updated, unreadCount: 0));

    try {
      await _repository.markAllAsRead();
    } catch (_) {
      emit(current);
    }
  }

  Future<void> refresh() => load();

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
