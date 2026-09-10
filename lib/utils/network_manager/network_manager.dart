import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class NetworkManager extends GetxController {
  static NetworkManager get instance => Get.find();

  final Connectivity _connectivity = Connectivity();

  DateTime? _lastReachableAt;
  static const Duration _cacheTtl = Duration(seconds: 4);

  /// Returns true if device has an active network interface and internet access.
  Future<bool> isConnected() async {
    try {
      // 1. Quick check for network interface availability (< 2ms)
      final connectivityResult = await _connectivity.checkConnectivity();
      final hasNetworkInterface = !connectivityResult.contains(
        ConnectivityResult.none,
      );

      if (!hasNetworkInterface) {
        _lastReachableAt = null;
        return false;
      }

      // 2. Return cached reachability if validated within the last 4 seconds
      final now = DateTime.now();
      if (_lastReachableAt != null &&
          now.difference(_lastReachableAt!) < _cacheTtl) {
        return true;
      }

      // 3. Verify actual internet reachability (fast DNS lookup first, HTTP fallback)
      final hasInternetAccess = await _checkInternetReachability();

      if (hasInternetAccess) {
        _lastReachableAt = DateTime.now();
      }

      return hasInternetAccess;
    } catch (_) {
      return false;
    }
  }

  /// Performs low-latency internet reachability check.
  /// Uses raw DNS lookup (~20-50ms) first, falling back to HTTP HEAD if needed.
  Future<bool> _checkInternetReachability() async {
    // Fast path: DNS resolution (ultra lightweight, no TLS handshake overhead)
    try {
      final lookup = await InternetAddress.lookup('google.com').timeout(
        const Duration(milliseconds: 1000),
      );
      if (lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    // Fallback path: Lightweight HTTP request
    try {
      final endpoints = [
        'https://www.google.com',
        'https://www.cloudflare.com',
      ];

      final results = await Future.wait(
        endpoints.map((url) async {
          try {
            await http
                .head(Uri.parse(url))
                .timeout(const Duration(milliseconds: 1500));
            return true;
          } catch (_) {
            return false;
          }
        }),
      );

      return results.any((reachable) => reachable);
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
