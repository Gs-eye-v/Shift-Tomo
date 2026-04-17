import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'calendar_provider.dart';
import 'tag_provider.dart';

part 'salary_provider.g.dart';

class SalaryStats {
  final int totalSalary;
  final double totalHours;
  final int totalShifts;

  SalaryStats({
    required this.totalSalary,
    required this.totalHours,
    required this.totalShifts,
  });
}

@riverpod
SalaryStats monthlySalary(MonthlySalaryRef ref) {
  final shiftsMapAsync = ref.watch(calendarNotifierProvider);
  final tagsAsync = ref.watch(tagNotifierProvider);

  final shiftsMap = shiftsMapAsync.value ?? {};
  final tags = tagsAsync.value ?? [];

  int totalSalary = 0;
  double totalHours = 0;
  int totalShifts = 0;

  for (final dayShifts in shiftsMap.values) {
    bool hasWorkShift = false;
    for (final shift in dayShifts) {
      for (final tagId in shift.tagIds) {
        final tag = tags.where((t) => t.id == tagId).firstOrNull;
        if (tag != null && !tag.isDayOff) {
          hasWorkShift = true;
          break;
        }
      }
      if (hasWorkShift) break;
    }
    
    if (hasWorkShift) {
      totalShifts++;
    }
    
    for (final shift in dayShifts) {
      for (final tagId in shift.tagIds) {
        final tag = tags.where((t) => t.id == tagId).firstOrNull;
        if (tag != null && tag.hourlyWage != null) {
          final workDuration = _calculateWorkDuration(
            tag.startTime,
            tag.endTime,
            tag.breakMinutes,
          );
          
          final hours = workDuration.inMinutes / 60.0;
          totalSalary += (hours * tag.hourlyWage!).round();
          totalHours += hours;
        }
      }
    }
  }

  return SalaryStats(
    totalSalary: totalSalary,
    totalHours: totalHours,
    totalShifts: totalShifts,
  );
}

/// 始業・終業時間と休憩時間から実労働時間を算出
Duration _calculateWorkDuration(String? startStr, String? endStr, int breakMin) {
  if (startStr == null || endStr == null || startStr.isEmpty || endStr.isEmpty) {
    return Duration.zero;
  }

  try {
    final startParts = startStr.split(':');
    final endParts = endStr.split(':');
    
    int startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    int endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    // 日をまたぐ場合 (例: 22:00 ~ 06:00)
    if (endMinutes < startMinutes) {
      endMinutes += 24 * 60;
    }

    int totalMinutes = endMinutes - startMinutes - breakMin;
    return Duration(minutes: totalMinutes > 0 ? totalMinutes : 0);
  } catch (e) {
    return Duration.zero;
  }
}
