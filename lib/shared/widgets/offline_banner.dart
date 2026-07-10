// lib/shared/widgets/offline_banner.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';

/// Shows an amber banner when the Supabase connection is lost.
/// Dismisses automatically when connectivity is restored.
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  bool _isOffline = false;
  late final AnimationController _controller;
  late final Animation<double> _height;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _height = Tween<double>(begin: 0, end: 36)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Simple connectivity check via a lightweight auth ping
    _startMonitoring();
  }

  void _startMonitoring() {
    Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!mounted) return;
      try {
        await Supabase.instance.client
            .from('system_settings')
            .select('setting_key')
            .limit(1)
            .timeout(const Duration(seconds: 5));
        if (_isOffline && mounted) {
          setState(() => _isOffline = false);
          await _controller.reverse();
        }
      } catch (_) {
        if (!_isOffline && mounted) {
          setState(() => _isOffline = true);
          await _controller.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _height,
      builder: (context, _) => SizedBox(
        height: _height.value,
        child: _height.value > 0
            ? Container(
                color: AppColors.warning,
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'No connection — some data may be outdated',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
