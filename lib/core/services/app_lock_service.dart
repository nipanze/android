import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockService {
  AppLockService._();

  static final AppLockService instance = AppLockService._();
  static const _enabledKey = 'app_lock_enabled';
  static const _backgroundThreshold = Duration(seconds: 30);

  final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> locked = ValueNotifier<bool>(false);
  final LocalAuthentication _auth = LocalAuthentication();

  DateTime? _backgroundedAt;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    enabled.value = prefs.getBool(_enabledKey) ?? false;
    locked.value = enabled.value;
  }

  Future<bool> canUseDeviceLock() async {
    try {
      return _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> setEnabled(bool value) async {
    if (value && !await canUseDeviceLock()) return false;

    if (value) {
      final authenticated = await authenticate();
      if (!authenticated) return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    enabled.value = value;
    locked.value = false;
    return true;
  }

  Future<bool> authenticate() async {
    try {
      return _auth.authenticate(
        localizedReason: 'Unlock Nipanze',
        biometricOnly: false,
        sensitiveTransaction: false,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> unlock() async {
    if (!enabled.value) {
      locked.value = false;
      return;
    }
    final ok = await authenticate();
    if (ok) locked.value = false;
  }

  void handlePaused() {
    if (!enabled.value) return;
    _backgroundedAt = DateTime.now();
  }

  void handleResumed() {
    if (!enabled.value) return;
    final since = _backgroundedAt;
    if (since == null ||
        DateTime.now().difference(since) >= _backgroundThreshold) {
      locked.value = true;
    }
  }
}
