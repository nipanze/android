// lib/core/services/offline_service.dart
// ignore_for_file: depend_on_referenced_packages

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class OfflineService {
  final Connectivity _connectivity = Connectivity();

  OfflineService();

  /// Returns true if the device currently has network access.
  Future<bool> get isOnline async {
   final results = await _connectivity.checkConnectivity();
   return !results.contains(ConnectivityResult.none) && results.isNotEmpty;
 }

  /// Returns true if the device is offline.
  Future<bool> get isOffline async => !(await isOnline);

  /// Stream of connectivity changes.
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}