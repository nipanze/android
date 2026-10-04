import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shows a temporary snackbar when the Supabase connection is lost.
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  Timer? _monitor;
  bool _isOffline = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    unawaited(_checkConnection());
    _monitor = Timer.periodic(
      const Duration(seconds: 10),
      (_) => unawaited(_checkConnection()),
    );
  }

  Future<void> _checkConnection() async {
    if (!mounted || _isChecking) return;
    _isChecking = true;
    var isOnline = true;
    try {
      await Supabase.instance.client
          .from('system_settings')
          .select('setting_key')
          .limit(1)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      isOnline = false;
    } finally {
      _isChecking = false;
    }

    if (!mounted || isOnline == !_isOffline) return;
    _isOffline = !isOnline;
    if (_isOffline) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('No connection — some data may be outdated'),
            duration: Duration(seconds: 4),
          ),
        );
    }
  }

  @override
  void dispose() {
    _monitor?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
