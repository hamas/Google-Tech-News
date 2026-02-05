import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> isMobileData() async {
    final result = await _connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.mobile);
  }

  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  Stream<bool> get isMobileStream =>
      _connectivity.onConnectivityChanged.map((results) {
        return results.contains(ConnectivityResult.mobile);
      });
}

final connectivityServiceProvider = Provider((ref) => ConnectivityService());
