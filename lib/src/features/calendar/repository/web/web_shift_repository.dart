import 'dart:convert';
import 'package:shift_tomo/src/features/calendar/model/shift.dart';
import 'package:shift_tomo/src/features/calendar/repository/shift_repository.dart';
import 'package:shift_tomo/src/utils/device_service.dart';

class LocalStorageShiftRepository implements ShiftRepository {
  static const String _key = 'local_shifts';
  final List<Shift> _shifts = [];
  bool _isLoaded = false;

  Future<void> _ensureLoaded() async {
    if (_isLoaded) return;
    final prefs = DeviceService.instance.prefs;
    final jsonStr = prefs.getString(_key);
    if (jsonStr != null) {
      final List<dynamic> list = json.decode(jsonStr);
      _shifts.clear();
      _shifts.addAll(list.map((item) => Shift.fromMap(item as Map<String, dynamic>)));
    }
    _isLoaded = true;
  }

  Future<void> _save() async {
    final prefs = DeviceService.instance.prefs;
    final jsonStr = json.encode(_shifts.map((s) => s.toMap()).toList());
    await prefs.setString(_key, jsonStr);
  }

  @override
  Future<List<Shift>> getShiftsForMonth(DateTime month) async {
    await _ensureLoaded();
    return _shifts
        .where((s) => s.date.year == month.year && s.date.month == month.month)
        .toList();
  }

  @override
  Future<List<Shift>> getAllShifts() async {
    await _ensureLoaded();
    return List.from(_shifts);
  }

  @override
  Future<void> addShift(Shift shift) async {
    await _ensureLoaded();
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
    await _save();
  }

  @override
  Future<void> replaceShifts(List<Shift> shifts) async {
    _shifts.clear();
    _shifts.addAll(shifts);
    _isLoaded = true;
    await _save();
  }
}

// 互換性のためのエイリアス
typedef InMemoryShiftRepository = LocalStorageShiftRepository;
