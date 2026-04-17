import 'dart:math';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../model/sync_settings.dart';
import '../../../utils/device_service.dart';

part 'sync_settings_provider.g.dart';

@riverpod
class SyncSettingsNotifier extends _$SyncSettingsNotifier {
  static const String _keyPrefix = 'sync_settings_';

  @override
  SyncSettings build() {
    final deviceId = DeviceService.instance.deviceId;
    
    // 同期読み込みはできないため、SharedPreferencesから値を読み込むための
    // 初期値を返す。実際の値はUI層でProviderを監視するか、初期化時に設定する。
    // ここではDeviceServiceが既に初期化したSharedPreferencesを利用する。
    final prefs = DeviceService.instance.prefs;
    
    return SyncSettings(
      deviceId: deviceId,
      roomId: prefs.getString('${_keyPrefix}roomId') ?? '',
      password: prefs.getString('${_keyPrefix}password') ?? '',
      userName: prefs.getString('${_keyPrefix}userName') ?? '',
      isEnabled: prefs.getBool('${_keyPrefix}isEnabled') ?? false,
    );
  }

  Future<void> _saveString(String key, String value) async {
    await DeviceService.instance.prefs.setString('${_keyPrefix}$key', value);
  }

  Future<void> _saveBool(String key, bool value) async {
    await DeviceService.instance.prefs.setBool('${_keyPrefix}$key', value);
  }

  void updateDeviceId(String id) {
    state = state.copyWith(deviceId: id);
    _saveString('deviceId', id);
  }

  void setEnabled(bool value) {
    state = state.copyWith(isEnabled: value);
    _saveBool('isEnabled', value);
  }

  void updateSettings(SyncSettings settings) {
    state = settings;
    _saveString('roomId', settings.roomId);
    _saveString('password', settings.password);
    _saveString('userName', settings.userName);
    _saveBool('isEnabled', settings.isEnabled);
  }

  void updateRoomId(String id) {
    state = state.copyWith(roomId: id);
    _saveString('roomId', id);
  }

  void updatePassword(String pass) {
    state = state.copyWith(password: pass);
    _saveString('password', pass);
  }

  void updateUserName(String name) {
    state = state.copyWith(userName: name);
    _saveString('userName', name);
  }

  /// パスワードの強さチェック (8文字以上、大文字、小文字、数字必須)
  bool isPasswordValid(String pass) {
    if (pass.length < 8) return false;
    final hasUpper = pass.contains(RegExp(r'[A-Z]'));
    final hasLower = pass.contains(RegExp(r'[a-z]'));
    final hasDigit = pass.contains(RegExp(r'[0-9]'));
    return hasUpper && hasLower && hasDigit;
  }

  /// ルームIDの生成 (ベース8文字以上 + ランダム2桁)
  String generateRoomId(String base) {
    if (base.length < 8) throw Exception('ルームIDのベースは8文字以上必要です');
    final random = Random();
    final suffix = random.nextInt(100).toString().padLeft(2, '0');
    return '$base$suffix';
  }
}
