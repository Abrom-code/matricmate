import 'dart:io';
import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceInfoModel {
  final String deviceId;
  final String deviceModel;
  final String osVersion;

  const DeviceInfoModel({
    required this.deviceId,
    required this.deviceModel,
    required this.osVersion,
  });
}

class DeviceService {
  static const _key = 'device_id';
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static DeviceInfoModel? _cachedInfo;

  /// Returns full device metadata (persistent ID, brand/model, OS version).
  static Future<DeviceInfoModel> getDeviceInfo() async {
    if (_cachedInfo != null) return _cachedInfo!;

    String? id;
    String model = 'Android Device';
    String os = 'Android';

    try {
      if (Platform.isAndroid) {
        try {
          id = await const AndroidId().getId();
        } catch (_) {}

        try {
          final androidInfo = await DeviceInfoPlugin().androidInfo;
          final brand = androidInfo.brand.trim();
          final m = androidInfo.model.trim();
          model = brand.toLowerCase() == m.toLowerCase()
              ? m
              : (brand.isNotEmpty && m.isNotEmpty ? '$brand $m' : (m.isNotEmpty ? m : brand));
          os = 'Android ${androidInfo.version.release} (API ${androidInfo.version.sdkInt})';
        } catch (_) {}
      } else if (Platform.isIOS) {
        try {
          final iosInfo = await DeviceInfoPlugin().iosInfo;
          id = iosInfo.identifierForVendor;
          model = iosInfo.utsname.machine;
          os = 'iOS ${iosInfo.systemVersion}';
        } catch (_) {}
      }
    } catch (_) {}

    // Fallback if platform hardware ID couldn't be fetched
    if (id == null || id.isEmpty) {
      try {
        id = await _secureStorage.read(key: _key);
      } catch (_) {}

      if (id == null || id.isEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          id = prefs.getString(_key);
        } catch (_) {}
      }

      if (id == null || id.isEmpty) {
        id = const Uuid().v4();
        try {
          await _secureStorage.write(key: _key, value: id);
        } catch (_) {}
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_key, id);
        } catch (_) {}
      }
    }

    _cachedInfo = DeviceInfoModel(
      deviceId: id,
      deviceModel: model.isNotEmpty ? model : 'Android Device',
      osVersion: os.isNotEmpty ? os : 'Android',
    );

    return _cachedInfo!;
  }

  /// Backward-compatible method returning the persistent device ID.
  static Future<String> getDeviceId() async {
    final info = await getDeviceInfo();
    return info.deviceId;
  }
}
