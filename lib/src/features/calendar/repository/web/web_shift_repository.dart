import 'package:shift_tomo/src/features/calendar/model/shift.dart';
import 'package:shift_tomo/src/features/calendar/repository/shift_repository.dart';

class InMemoryShiftRepository implements ShiftRepository {
  static final List<Shift> _shifts = [];

  @override
  Future<List<Shift>> getShiftsForMonth(DateTime month) async {
    return _shifts
        .where((s) => s.date.year == month.year && s.date.month == month.month)
        .toList();
  }

  @override
  Future<List<Shift>> getAllShifts() async {
    return List.from(_shifts);
  }

  @override
  Future<void> addShift(Shift shift) async {
    // 同じ日付、同じプロフィールのシフトがあれば上書き、なければ追加
    final index = _shifts.indexWhere((s) => 
      s.profileId == shift.profileId && 
      s.date.year == shift.date.year &&
      s.date.month == shift.date.month &&
      s.date.day == shift.date.day
    );
    
    if (index != -1) {
      _shifts[index] = shift;
    } else {
      _shifts.add(shift);
    }
  }

  @override
  Future<void> replaceShifts(List<Shift> shifts) async {
    _shifts.clear();
    _shifts.addAll(shifts);
  }
}
