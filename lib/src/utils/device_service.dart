import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static const String _deviceIdKey = 'device_id';
  late final SharedPreferences _prefs;
  String? _deviceId;

  DeviceService._();
  static final DeviceService instance = DeviceService._();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _deviceId = _prefs.getString(_deviceIdKey);
    
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await _prefs.setString(_deviceIdKey, _deviceId!);
    }
  }

  String get deviceId => _deviceId ?? '';
}
