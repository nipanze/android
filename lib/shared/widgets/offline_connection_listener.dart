// lib/shared/widgets/offline_connection_listener.dart
// Listens to OfflineService connectivity changes and surfaces brief SnackBars
// for offline/reconnected events WITHOUT ever blocking the screen content.
// The full-screen overlay has been intentionally removed so that previously
// loaded (stale) data remains visible while the connection is down.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/offline_service.dart';

class OfflineConnectionListener extends StatefulWidget {
  const OfflineConnectionListener({super.key});

  @override
  State<OfflineConnectionListener> createState() =>
      _OfflineConnectionListenerState();
}

class _OfflineConnectionListenerState
    extends State<OfflineConnectionListener> {
  late final OfflineService _offlineService;
  late final StreamSubscription<bool> _connectionSubscription;

  /// Whether we have already shown the "offline" SnackBar for the current
  /// disconnection period. Resets to false when connection is restored.
  bool _offlineSnackBarShown = false;

  @override
  void initState() {
    super.initState();
    _offlineService = OfflineService();
    _connectionSubscription =
        _offlineService.connectionChanges.listen(_handleConnectionChange);
    unawaited(_offlineService.initialize());
  }

  void _handleConnectionChange(bool isOnline) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    if (!isOnline) {
      // Only show the offline snackbar once per disconnection period.
      if (_offlineSnackBarShown) return;
      _offlineSnackBarShown = true;

      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'You are offline',
              textAlign: TextAlign.center,
            ),
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } else {
      // Connection restored — reset guard so the next disconnection shows
      // the snackbar again.
      _offlineSnackBarShown = false;

      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Connection restored · Updating…',
              textAlign: TextAlign.center,
            ),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This widget never occupies screen space — all feedback is via SnackBar.
    return const SizedBox.shrink();
  }
}
