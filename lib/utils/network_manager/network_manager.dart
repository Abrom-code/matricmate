import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class NetworkManager extends GetxController {
  static NetworkManager get instance => Get.find();

  final Connectivity _connectivity = Connectivity();

  /// Returns true if the device has an active network interface (WiFi or mobile).
  /// This is instant — no DNS lookup, no remote call.
  /// If this returns false, show "No Internet" and stop.
  /// If this returns true but a remote call fails, let the exception handler
  /// show the error — do not do a second check.
  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }
}
