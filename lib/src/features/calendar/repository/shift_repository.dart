import '../model/shift.dart';

abstract class ShiftRepository {
  Future<List<Shift>> getShiftsForMonth(DateTime month);
  Future<List<Shift>> getAllShifts();
  Future<void> addShift(Shift shift);
  Future<void> replaceShifts(List<Shift> shifts);
}
