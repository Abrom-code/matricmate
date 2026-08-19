import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static const _key = 'device_id';
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<String> getDeviceId() async {
    try {
      String? id = await _secureStorage.read(key: _key);
      if (id != null && id.isNotEmpty) return id;

      final prefs = await SharedPreferences.getInstance();
      id = prefs.getString(_key);

      if (id == null || id.isEmpty) {
        id = const Uuid().v4();
      }

      await _secureStorage.write(key: _key, value: id);
      await prefs.setString(_key, id);
      return id;
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      String? id = prefs.getString(_key);
      if (id == null || id.isEmpty) {
        id = const Uuid().v4();
        await prefs.setString(_key, id);
      }
      return id;
    }
  }
}
