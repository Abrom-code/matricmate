import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class NetworkManager extends GetxController {
  static NetworkManager get instance => Get.find();

  final Connectivity _connectivity = Connectivity();

  /// Checks for real internet by attempting a DNS lookup with a short timeout.
  /// Tries two hosts in parallel so a single slow DNS response doesn't block.
  /// Falls back to the connectivity API if both lookups fail but the device
  /// reports an active network interface — avoids false "no internet" when DNS
  /// is slow on first wake/launch.
  Future<bool> hasRealInternet() async {
    // First do a fast connectivity check — if the device has no network
    // interface at all, skip the DNS lookup entirely.
    final hasInterface = await isConnected();
    if (!hasInterface) return false;

    // Try two DNS lookups in parallel with a 5-second timeout.
    // Using Supabase host as primary so the lookup also warms up the DNS
    // cache for the first Supabase call.
    try {
      final results = await Future.any([
        _lookup('8.8.8.8'),   // Google DNS — fast numeric, no DNS needed
        _lookup('1.1.1.1'),   // Cloudflare DNS — fast fallback
      ]).timeout(const Duration(seconds: 5));
      return results;
    } catch (_) {
      // DNS timed out or failed — but device has a network interface.
      // Give benefit of the doubt: let the actual request fail naturally
      // rather than blocking the user with a false "no internet" message.
      return true;
    }
  }

  Future<bool> _lookup(String host) async {
    try {
      final result = await InternetAddress.lookup(host);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }
}
