import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/offline_service.dart';

/// Displays brief connectivity feedback without taking space from the screen.
class OfflineConnectionListener extends StatefulWidget {
  const OfflineConnectionListener({super.key});

  @override
  State<OfflineConnectionListener> createState() =>
      _OfflineConnectionListenerState();
}

class _OfflineConnectionListenerState extends State<OfflineConnectionListener> {
  late final OfflineService _offlineService;
  late final StreamSubscription<bool> _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _offlineService = OfflineService();
    _connectionSubscription =
        _offlineService.connectionChanges.listen(_showConnectionMessage);
    unawaited(_offlineService.initialize());
  }

  void _showConnectionMessage(bool isOnline) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            isOnline
                ? 'Connection restored · Updating…'
                : 'You’re offline · Showing recently loaded data',
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.inverseSurface,
        ),
      );
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
