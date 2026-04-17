import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../sync/provider/sync_provider.dart';
import '../../sync/provider/sync_settings_provider.dart';
import '../model/shift_tag.dart';

part 'holiday_provider.g.dart';

/// ルーム内の全メンバーの予定を比較し、「全員が休み（休日フラグあり）」の日を特定する
@riverpod
Future<List<DateTime>> commonHolidays(CommonHolidaysRef ref, DateTime month) async {
  final syncRepo = ref.watch(syncRepositoryProvider);
  final settings = ref.watch(syncSettingsNotifierProvider);

  if (!settings.isEnabled || settings.roomId.isEmpty || settings.password.isEmpty) {
    return [];
  }

  try {
    final data = await syncRepo.fetchAllProfiles(settings.roomId, settings.password);
    if (data == null) return [];

    final profilesMap = data['profiles'] as Map<String, dynamic>? ?? {};
    if (profilesMap.isEmpty) return [];

    // 各ユーザーごとの「出勤日（isDayOff=falseのタグがある日）」セットを作成
    final List<Set<DateTime>> userWorkDays = [];
    
    profilesMap.forEach((id, userData) {
      final shiftsJson = userData['shifts'] as List? ?? [];
      final tagsJson = userData['tags'] as List? ?? [];
      
      // タグID -> isDayOff のマップ作成
      final Map<String, bool> tagIsDayOff = {};
      for (final t in tagsJson) {
        tagIsDayOff[t['id'] as String] = (t['is_day_off'] as int? ?? 0) == 1;
      }

      final Set<DateTime> workDays = {};
      for (final s in shiftsJson) {
        final date = DateTime.parse(s['date'] as String);
        final dateOnly = DateTime(date.year, date.month, date.day);
        
        final tagIds = (s['tag_ids'] as List?)?.cast<String>() ?? 
                       [s['tag_id'] as String? ?? ''];
        
        // その日のタグが1つでも「休日」出ない場合、それは出勤日とみなす
        bool hasWorkTag = false;
        for (final tid in tagIds) {
          if (tagIsDayOff[tid] == false) {
            hasWorkTag = true;
            break;
          }
        }

        if (hasWorkTag) {
          workDays.add(dateOnly);
        }
      }
      userWorkDays.add(workDays);
    });

    // 対象月の全日について、誰一人として出勤していない日（＝全員休み）を判定
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final List<DateTime> holidays = [];

    for (int day = 1; day <= lastDay; day++) {
      final checkDate = DateTime(month.year, month.month, day);
      
      bool existsSomeoneWorking = false;
      for (final workDaysSet in userWorkDays) {
        if (workDaysSet.contains(checkDate)) {
          existsSomeoneWorking = true;
          break;
        }
      }

      if (!existsSomeoneWorking) {
        holidays.add(checkDate);
      }
    }

    return holidays;
  } catch (e) {
    return [];
  }
}
