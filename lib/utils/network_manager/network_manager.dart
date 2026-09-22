import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class NetworkManager extends GetxController {
  static NetworkManager get instance => Get.find();

  final Connectivity _connectivity = Connectivity();

  DateTime? _lastReachableAt;
  static const Duration _cacheTtl = Duration(seconds: 4);

  /// Returns true if device has an active network interface and internet access.
  /// Set [force] to true to bypass cache and verify live internet status immediately.
  Future<bool> isConnected({bool force = false}) async {
    try {
      // 1. Quick check for network interface availability (< 2ms)
      final connectivityResult = await _connectivity.checkConnectivity();
      final hasNetworkInterface = connectivityResult.isNotEmpty &&
          !connectivityResult.contains(ConnectivityResult.none);

      if (!hasNetworkInterface) {
        _lastReachableAt = null;
        return false;
      }

      // 2. Return cached reachability if validated within the last 4 seconds
      final now = DateTime.now();
      if (!force &&
          _lastReachableAt != null &&
          now.difference(_lastReachableAt!) < _cacheTtl) {
        return true;
      }

      // 3. Ultra-fast parallel IP socket probe (30-80ms online, max 600ms offline)
      final hasInternetAccess = await _checkInternetReachability();

      if (hasInternetAccess) {
        _lastReachableAt = DateTime.now();
      } else {
        _lastReachableAt = null;
      }

      return hasInternetAccess;
    } catch (_) {
      _lastReachableAt = null;
      return false;
    }
  }

  /// Performs ultra low-latency internet reachability check.
  /// Uses parallel raw IP socket probes to bypass DNS lookup entirely.
  /// Completes in 30-80ms when online, and at most 600ms when offline.
  Future<bool> _checkInternetReachability() async {
    final completer = Completer<bool>();
    int pending = 3;

    void onProbeDone(bool success) {
      if (success) {
        if (!completer.isCompleted) completer.complete(true);
      } else {
        pending--;
        if (pending == 0 && !completer.isCompleted) {
          completer.complete(false);
        }
      }
    }

    _rawProbe('8.8.8.8', 53).then(onProbeDone);
    _rawProbe('1.1.1.1', 53).then(onProbeDone);
    _rawProbe('1.1.1.1', 443).then(onProbeDone);

    return completer.future;
  }

  Future<bool> _rawProbe(String host, int port) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(milliseconds: 600),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Quick interface-only connectivity check (WiFi / Mobile).
  Future<bool> hasNetworkInterface() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }
}
