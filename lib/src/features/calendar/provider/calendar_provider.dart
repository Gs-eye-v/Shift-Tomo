import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../model/shift.dart';
import 'repository_provider.dart';
import 'tag_provider.dart';
import 'app_settings_provider.dart';
import 'view_state_provider.dart';
import '../../sync/provider/sync_settings_provider.dart';
import '../../sync/provider/sync_provider.dart';
import '../../sync/provider/partner_provider.dart';
import '../../sync/repository/sync_repository.dart';
import '../../../utils/notification_service.dart';

part 'calendar_provider.g.dart';

@riverpod
class FocusedMonth extends _$FocusedMonth {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1);
  }
}

@riverpod
class CalendarNotifier extends _$CalendarNotifier {
  @override
  Future<Map<DateTime, List<Shift>>> build() async {
    final repository = ref.watch(shiftRepositoryProvider);
    final focusedMonth = ref.watch(focusedMonthProvider);
    final viewUser = ref.watch(calendarViewUserNotifierProvider);

    if (viewUser.isMe) {
      return _fetchShifts(repository, focusedMonth);
    } else {
      // パートナーのデータを取得
      return _fetchPartnerShifts(viewUser.partner!);
    }
  }

  Future<Map<DateTime, List<Shift>>> _fetchPartnerShifts(dynamic partner) async {
    final syncRepo = ref.read(syncRepositoryProvider);
    try {
      final profiles = await syncRepo.validateAndFetchProfiles(partner.roomId, partner.password);
      final profileData = (profiles['profiles'] as Map? ?? {})[partner.profileName];
      
      if (profileData == null) return {};

      final shiftsJson = profileData['shifts'] as List? ?? [];
      final shifts = shiftsJson.map((m) => Shift.fromMap(m as Map<String, dynamic>)).toList();

      final Map<DateTime, List<Shift>> map = {};
      for (final shift in shifts) {
        final dateOnly = DateTime(shift.date.year, shift.date.month, shift.date.day);
        map[dateOnly] = (map[dateOnly] ?? [])..add(shift);
      }
      return map;
    } catch (e) {
      return {};
    }
  }

  Future<Map<DateTime, List<Shift>>> _fetchShifts(dynamic repository, DateTime month) async {
    final shifts = await repository.getAllShifts();
    
    final Map<DateTime, List<Shift>> map = {};
    for (final shift in shifts) {
      final dateOnly = DateTime(shift.date.year, shift.date.month, shift.date.day);
      map[dateOnly] = (map[dateOnly] ?? [])..add(shift);
    }
    return map;
  }

  Future<void> addShift(Shift shift) async {
    final repository = ref.read(shiftRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.addShift(shift);
      
      // 通知予約の更新
      await syncNotifications();

      // 自動同期の実行
      final syncSettings = ref.read(syncSettingsNotifierProvider);
      if (syncSettings.isEnabled && syncSettings.roomId.isNotEmpty && syncSettings.password.isNotEmpty) {
        ref.read(syncNotifierProvider.notifier).pushAll(
          syncSettings.roomId, 
          syncSettings.password, 
          syncSettings.userName,
          syncSettings.deviceId,
        ).ignore();
      }

      final focusedMonth = ref.read(focusedMonthProvider);
      return _fetchShifts(repository, focusedMonth);
    });
  }

  Future<void> addMultipleShifts(List<Shift> shifts) async {
    final repository = ref.read(shiftRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      for (final shift in shifts) {
        await repository.addShift(shift);
      }

      // 通知予約の更新
      await _syncNotifications();

      // 自動同期の実行
      final syncSettings = ref.read(syncSettingsNotifierProvider);
      if (syncSettings.isEnabled && syncSettings.roomId.isNotEmpty && syncSettings.password.isNotEmpty) {
        ref.read(syncNotifierProvider.notifier).pushAll(
          syncSettings.roomId, 
          syncSettings.password, 
          syncSettings.userName,
          syncSettings.deviceId,
        ).ignore();
      }

      final focusedMonth = ref.read(focusedMonthProvider);
      return _fetchShifts(repository, focusedMonth);
    });
  }

  Future<void> syncNotifications() async {
    await _syncNotifications();
  }

  Future<void> _syncNotifications() async {
    final repository = ref.read(shiftRepositoryProvider);
    final shiftsMap = _toMap(await repository.getAllShifts());
    final tags = ref.read(tagNotifierProvider).value ?? [];
    
    // パートナーのデータも集約
    final partners = ref.read(partnerNotifierProvider).value ?? [];
    final Map<String, Map<DateTime, List<Shift>>> partnerShiftsMap = {};
    
    for (final partner in partners) {
      final pShifts = await _fetchPartnerShifts(partner);
      if (pShifts.isNotEmpty) {
        partnerShiftsMap[partner.displayName] = pShifts;
      }
    }

    final appSettings = ref.read(appSettingsNotifierProvider);

    NotificationService().syncAllNotifications(
      myShifts: shiftsMap, 
      tags: tags,
      appSettings: appSettings,
      partnerShifts: partnerShiftsMap,
    );
  }

  Map<DateTime, List<Shift>> _toMap(List<Shift> shifts) {
    final Map<DateTime, List<Shift>> map = {};
    for (final shift in shifts) {
      final dateOnly = DateTime(shift.date.year, shift.date.month, shift.date.day);
      map[dateOnly] = (map[dateOnly] ?? [])..add(shift);
    }
    return map;
  }
}
