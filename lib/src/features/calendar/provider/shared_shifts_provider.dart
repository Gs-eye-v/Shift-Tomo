import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../sync/provider/sync_provider.dart';
import '../../sync/provider/sync_settings_provider.dart';
import '../model/shift.dart';

part 'shared_shifts_provider.g.dart';

@riverpod
class SharedShiftsNotifier extends _$SharedShiftsNotifier {
  @override
  AsyncValue<Map<String, dynamic>> build() {
    return const AsyncValue.data({});
  }

  Future<void> refresh() async {
    final settings = ref.read(syncSettingsNotifierProvider);
    if (!settings.isEnabled || settings.roomId.isEmpty || settings.password.isEmpty) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final profilesMap = await ref.read(syncRepositoryProvider).fetchAllProfiles(
        settings.roomId,
        settings.password,
      );
      return profilesMap?['profiles'] as Map<String, dynamic>? ?? {};
    });
  }

  /// 指定したユーザーのシフトデータをDateマップ形式で取得
  Map<DateTime, List<Shift>> getShiftsForUser(String userName) {
    final profiles = state.value ?? {};
    if (!profiles.containsKey(userName)) return {};

    final userData = profiles[userName] as Map<String, dynamic>;
    final shiftsList = userData['shifts'] as List? ?? [];
    
    final Map<DateTime, List<Shift>> shiftsMap = {};
    for (final s in shiftsList) {
      final shift = Shift.fromMap(s as Map<String, dynamic>);
      final dateOnly = DateTime(shift.date.year, shift.date.month, shift.date.day);
      shiftsMap.putIfAbsent(dateOnly, () => []).add(shift);
    }
    return shiftsMap;
  }
}

@riverpod
class SelectedMemberNotifier extends _$SelectedMemberNotifier {
  @override
  String? build() => null;

  void select(String? userName) {
    state = userName;
  }
}
