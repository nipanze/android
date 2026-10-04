import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/offline_service.dart';

class OfflineConnectionListener extends StatefulWidget {
  const OfflineConnectionListener({super.key});

  @override
  State<OfflineConnectionListener> createState() =>
      _OfflineConnectionListenerState();
}

class _OfflineConnectionListenerState extends State<OfflineConnectionListener> {
  late final OfflineService _offlineService;
  late final StreamSubscription<bool> _connectionSubscription;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _offlineService = OfflineService();
    _isOnline = _offlineService.currentIsOnline;
    _connectionSubscription =
        _offlineService.connectionChanges.listen(_handleConnectionChange);
    unawaited(_offlineService.initialize());
  }

  void _handleConnectionChange(bool isOnline) {
    if (!mounted) return;
    setState(() => _isOnline = isOnline);

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    if (!isOnline) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'You’re offline · Check your internet connection.',
            textAlign: TextAlign.center,
          ),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _retryConnection() {
    unawaited(_offlineService.initialize());
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final background = Theme.of(context).scaffoldBackgroundColor;

    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 200),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background.withValues(alpha: 0.96),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 60,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 18),
                Text(
                  'You’re offline',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check your internet connection and try again.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _retryConnection,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      side: BorderSide(
                        color: colorScheme.outline,
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Retry',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
