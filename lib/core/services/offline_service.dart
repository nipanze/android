import 'dart:async';

// lib/core/services/offline_service.dart
// ignore_for_file: cancel_subscriptions, depend_on_referenced_packages

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

import '../errors/app_exception.dart';

@lazySingleton
class OfflineService {
  factory OfflineService() => _instance;

  OfflineService._();

  static final OfflineService _instance = OfflineService._();
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionChanges =
      StreamController<bool>.broadcast();
  final StreamController<void> _reconnections =
      StreamController<void>.broadcast();
  final Set<void Function()> _sessionCacheClearers = {};
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;

  Stream<bool> get connectionChanges => _connectionChanges.stream;
  Stream<void> get onReconnected => _reconnections.stream;
  bool get currentIsOnline => _isOnline;

  void registerSessionCache(void Function() clearCache) {
    _sessionCacheClearers.add(clearCache);
  }

  void clearSessionCaches() {
    for (final clearCache in _sessionCacheClearers) {
      clearCache();
    }
  }

  Future<void> initialize() async {
    // This app-wide singleton owns the connectivity subscription for its lifetime.
    _connectivitySubscription ??=
        _connectivity.onConnectivityChanged.listen(_handleConnectivity);
    final results = await _connectivity.checkConnectivity();
    _handleConnectivity(results);
  }

  /// Returns true if the device currently has network access.
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  /// Returns true if the device is offline.
  Future<bool> get isOffline async => !(await isOnline);

  void reportRequestFailure(Object error) {
    if (parseSupabaseError(error) is NetworkException) {
      _setOnline(false);
    }
  }

  void reportRequestSuccess() => _setOnline(true);

  void _handleConnectivity(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    final isOnline = _hasConnection(results);
    _setOnline(isOnline);
    if (!wasOnline && isOnline) _reconnections.add(null);
  }

  bool _hasConnection(List<ConnectivityResult> results) =>
      results.isNotEmpty && !results.contains(ConnectivityResult.none);

  void _setOnline(bool isOnline) {
    if (_isOnline == isOnline) return;
    _isOnline = isOnline;
    _connectionChanges.add(isOnline);
  }
}
