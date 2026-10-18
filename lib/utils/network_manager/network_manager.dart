import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class NetworkManager extends GetxController {
  static NetworkManager get instance => Get.find();

  final Connectivity _connectivity = Connectivity();

  DateTime? _lastReachableAt;
  static const Duration _cacheTtl = Duration(seconds: 8);

  /// Returns true if device has an active network interface and internet access.
  /// Set [force] to true to bypass cache and verify live internet status immediately.
  Future<bool> isConnected({bool force = false}) async {
    try {
      // 1. Quick check for network interface availability (< 2ms)
      final connectivityResult = await _connectivity.checkConnectivity();
      final hasNetworkInterface = connectivityResult
          .any((r) => r != ConnectivityResult.none);

      if (!hasNetworkInterface) {
        _lastReachableAt = null;
        return false;
      }

      // 2. Return cached reachability if validated within the last 8 seconds
      final now = DateTime.now();
      if (!force &&
          _lastReachableAt != null &&
          now.difference(_lastReachableAt!) < _cacheTtl) {
        return true;
      }

      // 3. Parallel IP socket probe (~50-200ms online, max 2500ms offline)
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

  /// Performs internet reachability check using parallel raw IP socket probes.
  /// Probes HTTPS (443) and HTTP (80) ports on major public DNS providers.
  /// Port 53 (DNS) is avoided because many ISPs/carriers block raw TCP to it.
  /// Completes as soon as ANY probe succeeds, or after all fail (~2500ms).
  Future<bool> _checkInternetReachability() async {
    final completer = Completer<bool>();
    int pending = 4;

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

    // Probe HTTPS/HTTP ports on Google & Cloudflare DNS IPs
    _rawProbe('8.8.8.8', 443).then(onProbeDone);
    _rawProbe('1.1.1.1', 443).then(onProbeDone);
    _rawProbe('8.8.4.4', 443).then(onProbeDone);
    _rawProbe('1.0.0.1', 80).then(onProbeDone);

    return completer.future;
  }

  Future<bool> _rawProbe(String host, int port) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(milliseconds: 2500),
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
      return result.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }
}

