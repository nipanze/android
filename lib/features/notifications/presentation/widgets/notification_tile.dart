// lib/features/notifications/presentation/widgets/notification_tile.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/app_notification.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconAndColor(notification.type);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.transparent
              : AppColors.accent.withValues(alpha: 0.04),
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeAgo(notification.createdAt),
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 10),
                    ),
                    if (!notification.isRead) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notification.hasDeepLink) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Tap to view →',
                      style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _iconAndColor(NotificationType type) {
    switch (type) {
      case NotificationType.bidReceived:
        return (Icons.how_to_vote_outlined, AppColors.accent);
      case NotificationType.bidAccepted:
        return (Icons.check_circle_outline_rounded, AppColors.success);
      case NotificationType.bidRejected:
      case NotificationType.bidWithdrawn:
        return (Icons.cancel_outlined, AppColors.danger);
      case NotificationType.negotiatorAssigned:
        return (Icons.people_outline_rounded, AppColors.purple);
      case NotificationType.contractDraftAvailable:
        return (Icons.handshake_outlined, AppColors.success);
      case NotificationType.kycApproved:
        return (Icons.verified_rounded, AppColors.success);
      case NotificationType.kycRejected:
        return (Icons.gpp_bad_outlined, AppColors.danger);
      case NotificationType.closingSoon24h:
      case NotificationType.closingSoon6h:
        return (Icons.timer_outlined, AppColors.warning);
      case NotificationType.watchlistNewBid:
        return (Icons.star_rounded, AppColors.warning);
      case NotificationType.watchlistRateChange:
        return (Icons.trending_down_rounded, AppColors.accent);
      case NotificationType.contactRevealed:
        return (Icons.visibility_outlined, AppColors.purple);
      case NotificationType.system:
        return (Icons.info_outline_rounded, AppColors.text2Dark);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours   < 24) return '${diff.inHours}h';
    if (diff.inDays    < 7)  return '${diff.inDays}d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}