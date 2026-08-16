import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nipanze/features/notifications/data/notification_repository.dart';
import 'package:nipanze/features/notifications/domain/models/app_notification.dart';
import 'package:nipanze/features/notifications/presentation/cubit/notification_cubit.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

AppNotification _notification(String id, {bool isRead = false}) {
  return AppNotification(
    id: id,
    userId: 'u-1',
    type: NotificationType.bidReceived,
    title: 'New offer',
    body: 'Body',
    isRead: isRead,
    createdAt: DateTime.now(),
  );
}

void main() {
  late MockNotificationRepository mockRepo;

  setUp(() {
    mockRepo = MockNotificationRepository();
    when(() => mockRepo.watchNotifications())
        .thenAnswer((_) => const Stream.empty());
  });

  group('NotificationCubit', () {
    blocTest<NotificationCubit, NotificationState>(
      'load counts unread notifications',
      build: () {
        when(() => mockRepo.getNotifications()).thenAnswer((_) async => [
              _notification('n-1'),
              _notification('n-2', isRead: true),
              _notification('n-3'),
            ]);
        return NotificationCubit(mockRepo);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<NotificationLoading>(),
        isA<NotificationLoaded>()
            .having((s) => s.notifications.length, 'count', 3)
            .having((s) => s.unreadCount, 'unread', 2),
      ],
    );

    blocTest<NotificationCubit, NotificationState>(
      'load emits Error on failure',
      build: () {
        when(() => mockRepo.getNotifications()).thenThrow(Exception('oops'));
        return NotificationCubit(mockRepo);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<NotificationLoading>(),
        isA<NotificationError>(),
      ],
    );

    blocTest<NotificationCubit, NotificationState>(
      'markAsRead updates locally and decrements unread',
      build: () {
        when(() => mockRepo.getNotifications()).thenAnswer((_) async => [
              _notification('n-1'),
              _notification('n-2'),
            ]);
        when(() => mockRepo.markAsRead('n-1')).thenAnswer((_) async {});
        return NotificationCubit(mockRepo);
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.markAsRead('n-1');
      },
      skip: 2,
      expect: () => [
        isA<NotificationLoaded>()
            .having((s) => s.notifications.first.isRead, 'marked read', true)
            .having((s) => s.unreadCount, 'unread count', 1),
      ],
    );

    blocTest<NotificationCubit, NotificationState>(
      'markAllAsRead zeroes the unread count',
      build: () {
        when(() => mockRepo.getNotifications()).thenAnswer((_) async => [
              _notification('n-1'),
              _notification('n-2'),
            ]);
        when(() => mockRepo.markAllAsRead()).thenAnswer((_) async {});
        return NotificationCubit(mockRepo);
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.markAllAsRead();
      },
      skip: 2,
      expect: () => [
        isA<NotificationLoaded>()
            .having((s) => s.unreadCount, 'unread count', 0)
            .having((s) => s.notifications.every((n) => n.isRead),
                'all read', true),
      ],
    );

    test('markAsRead is a no-op before load', () async {
      final cubit = NotificationCubit(mockRepo);
      await cubit.markAsRead('n-1');
      expect(cubit.state, isA<NotificationInitial>());
      await cubit.close();
    });
  });
}
