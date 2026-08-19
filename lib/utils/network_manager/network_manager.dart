import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class NetworkManager extends GetxController {
  static NetworkManager get instance => Get.find();

  final Connectivity _connectivity = Connectivity();

  /// Returns true if device has an active network interface and internet access.
  Future<bool> isConnected() async {
    try {
      // First, quick check for network interface availability
      final connectivityResult = await _connectivity.checkConnectivity();
      final hasNetworkInterface = !connectivityResult.contains(
        ConnectivityResult.none,
      );

      if (!hasNetworkInterface) {
        return false;
      }

      // Verify actual internet reachability via HTTP request
      final hasInternetAccess = await _checkInternetReachability();

      return hasInternetAccess;
    } catch (_) {
      return false;
    }
  }

  /// Performs internet reachability check via lightweight HTTP request.
  Future<bool> _checkInternetReachability() async {
    try {
      // Try multiple reliable endpoints in case one is down
      final endpoints = [
        'https://www.google.com',
        'https://www.cloudflare.com',
        'https://www.apple.com',
      ];

      for (final endpoint in endpoints) {
        try {
          await http
              .head(Uri.parse(endpoint))
              .timeout(const Duration(seconds: 5));

          // Any response (even 4xx/5xx) means we have internet connectivity
          return true;
        } catch (_) {
          // Try next endpoint
          continue;
        }
      }

      return false;
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
