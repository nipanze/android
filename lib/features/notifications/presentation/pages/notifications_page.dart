// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const EmptyState(
        icon: Icons.notifications_outlined,
        title: 'No notifications',
        subtitle: 'You\'ll be notified here when bids arrive, rates change, or contracts are ready.',
      ),
    );
  }
}
