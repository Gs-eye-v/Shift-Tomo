import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../model/shift.dart';
import 'repository_provider.dart';

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
    return _fetchShifts(repository, focusedMonth);
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
      final focusedMonth = ref.read(focusedMonthProvider);
      return _fetchShifts(repository, focusedMonth);
    });
  }
}
