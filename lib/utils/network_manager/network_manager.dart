import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/logging/logging.dart';

class NetworkManager extends GetxController {
  static NetworkManager get instance => Get.find();

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final Rx<ConnectivityResult> _connectionStatus = ConnectivityResult.none.obs;

  @override
  void onInit() {
    super.onInit();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  @override
  void onClose() {
    _connectivitySubscription.cancel();
    super.onClose();
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    if (results.isNotEmpty) {
      _connectionStatus.value = results.first;

      if (results.contains(ConnectivityResult.none)) {
        AppHelperFuntions.showSnackBar('No internet connection');
      }
    }
  }

  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      // ignore: unrelated_type_equality_checks
      return result != ConnectivityResult.none;
    } catch (e) {
      AppLoggerHelper.error("Connectivity check failed", e);
      return false;
    }
  }
}
