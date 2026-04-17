import 'dart:math';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../model/sync_settings.dart';
import '../../../utils/device_service.dart';

part 'sync_settings_provider.g.dart';

@riverpod
class SyncSettingsNotifier extends _$SyncSettingsNotifier {
  @override
  SyncSettings build() {
    final deviceId = DeviceService.instance.deviceId;
    return SyncSettings(deviceId: deviceId);
  }

  void updateDeviceId(String id) {
    state = state.copyWith(deviceId: id);
  }

  void setEnabled(bool value) {
    state = state.copyWith(isEnabled: value);
  }

  void updateSettings(SyncSettings settings) {
    state = settings;
  }

  void updateRoomId(String id) {
    state = state.copyWith(roomId: id);
  }

  void updatePassword(String pass) {
    state = state.copyWith(password: pass);
  }

  void updateUserName(String name) {
    state = state.copyWith(userName: name);
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
