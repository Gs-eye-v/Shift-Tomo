import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../model/sync_settings.dart';

part 'sync_settings_provider.g.dart';

@riverpod
class SyncSettingsNotifier extends _$SyncSettingsNotifier {
  @override
  SyncSettings build() {
    return const SyncSettings();
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
}
