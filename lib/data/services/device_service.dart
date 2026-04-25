import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static final _storage = GetStorage();

  static Future<String> getDeviceId() async {
    String? id = _storage.read('device_id');

    if (id == null) {
      id = const Uuid().v4();
      await _storage.write('device_id', id);
    }

    return id;
  }
}
