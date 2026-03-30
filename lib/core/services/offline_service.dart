import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class OfflineService {
  final Connectivity _connectivity = Connectivity();

  OfflineService();

  /// Returns true if the device currently has network access.
  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    // ignore: unrelated_type_equality_checks
    return result != ConnectivityResult.none;
  }

  /// Returns true if the device is offline.
  Future<bool> get isOffline async => !(await isOnline);

  /// Stream of connectivity changes.
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}