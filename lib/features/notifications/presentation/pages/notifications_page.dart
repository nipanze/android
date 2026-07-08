// lib/features/notifications/presentation/pages/notifications_page.dart
// ignore_for_file: unused_import, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../domain/models/app_notification.dart';
import '../cubit/notification_cubit.dart';
import '../widgets/notification_tile.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<NotificationCubit>()..load(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notifications'),
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              if (state is! NotificationLoaded || state.unreadCount == 0) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () =>
                    context.read<NotificationCubit>().markAllAsRead(),
                child:
                    const Text('Mark all read', style: TextStyle(fontSize: 12)),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading || state is NotificationInitial) {
            return _LoadingSkeleton();
          }

          if (state is NotificationError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<NotificationCubit>().refresh(),
            );
          }

          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return const EmptyState(
                icon: Icons.notifications_outlined,
                title: 'No notifications yet',
                subtitle: 'You\'ll be notified here when bids arrive, '
                    'rates change, or contracts are ready.',
              );
            }

            // Group by date
            final groups = _groupByDate(state.notifications);

            return RefreshIndicator(
              onRefresh: () => context.read<NotificationCubit>().refresh(),
              child: ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, i) {
                  final group = groups[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                        child: Text(
                          group.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      // Notifications in group
                      ...group.items.map((n) => NotificationTile(
                            notification: n,
                            onTap: () => _onTap(context, n),
                          )),
                    ],
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _onTap(BuildContext context, AppNotification n) {
    context.read<NotificationCubit>().markAsRead(n.id);
    if (n.deepLinkRoute != null) {
      context.push(n.deepLinkRoute!);
    }
  }

  List<_NotifGroup> _groupByDate(List<AppNotification> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayItems = <AppNotification>[];
    final yesterdayItems = <AppNotification>[];
    final olderItems = <AppNotification>[];

    for (final n in items) {
      final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      if (d == today) {
        todayItems.add(n);
      } else if (d == yesterday)
        yesterdayItems.add(n);
      else
        olderItems.add(n);
    }

    return [
      if (todayItems.isNotEmpty) _NotifGroup('TODAY', todayItems),
      if (yesterdayItems.isNotEmpty) _NotifGroup('YESTERDAY', yesterdayItems),
      if (olderItems.isNotEmpty) _NotifGroup('EARLIER', olderItems),
    ];
  }
}

class _NotifGroup {
  const _NotifGroup(this.label, this.items);
  final String label;
  final List<AppNotification> items;
}

// ─── Loading skeleton ─────────────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 6,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Theme.of(context).dividerColor),
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SkeletonBox(width: 36, height: 36, radius: 10),
          SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                SkeletonBox(width: 140, height: 13),
                Spacer(),
                SkeletonBox(width: 30, height: 10),
              ]),
              SizedBox(height: 6),
              SkeletonBox(width: double.infinity, height: 10),
              SizedBox(height: 4),
              SkeletonBox(width: 180, height: 10),
            ]),
          ),
        ]),
      ),
    );
  }
}
