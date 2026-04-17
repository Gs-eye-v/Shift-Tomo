import 'package:shift_tomo/src/features/calendar/model/shift.dart';
import 'package:shift_tomo/src/features/calendar/repository/shift_repository.dart';
import 'package:shift_tomo/src/utils/database_service.dart';

class SqliteShiftRepository implements ShiftRepository {
  final DatabaseService _dbService = DatabaseService();

  @override
  Future<List<Shift>> getShiftsForMonth(DateTime month) async {
    final db = await _dbService.database;
    if (db == null) return [];
    
    // 取得は全件行い、後でフィルタリング（SQLiteのWHERE句でも良いが現状の構造を維持）
    final List<Map<String, dynamic>> maps = await db.query('shifts');
    return maps
        .map((m) => Shift.fromMap(m))
        .where((s) => s.date.year == month.year && s.date.month == month.month)
        .toList();
  }

  @override
  Future<List<Shift>> getAllShifts() async {
    final db = await _dbService.database;
    if (db == null) return [];
    final List<Map<String, dynamic>> maps = await db.query('shifts');
    return maps.map((m) => Shift.fromMap(m)).toList();
  }

  @override
  Future<void> addShift(Shift shift) async {
    final db = await _dbService.database;
    if (db == null) return;

    final dateStr = shift.date.toIso8601String().split('T')[0]; // YYYY-MM-DD

    // 同一日の既存シフトを削除（自分専用モードを想定）
    await db.delete(
      'shifts',
      where: 'profile_id = ? AND substr(date, 1, 10) = ?',
      whereArgs: [shift.profileId, dateStr],
    );

    await db.insert('shifts', shift.toMap());
  }

  @override
  Future<void> replaceShifts(List<Shift> shifts) async {
    final db = await _dbService.database;
    if (db == null) return;

    await db.transaction((txn) async {
      // 全削除
      await txn.delete('shifts');
      // 全挿入
      for (final shift in shifts) {
        await txn.insert('shifts', shift.toMap());
      }
    });
  }
}
