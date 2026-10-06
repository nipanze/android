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
            backgroundColor: Color(0xFF0F172A),
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            content: Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You are offline',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
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
