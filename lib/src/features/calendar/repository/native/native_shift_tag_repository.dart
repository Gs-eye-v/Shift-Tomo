import 'package:shift_tomo/src/features/calendar/model/shift_tag.dart';
import 'package:shift_tomo/src/features/calendar/repository/shift_tag_repository.dart';
import 'package:shift_tomo/src/utils/database_service.dart';

class SqliteShiftTagRepository implements ShiftTagRepository {
  final DatabaseService _dbService = DatabaseService();

  @override
  Future<List<ShiftTag>> getTags() async {
    final db = await _dbService.database;
    if (db == null) return [];
    final List<Map<String, dynamic>> maps = await db.query('shift_tags');
    return maps.map((m) => ShiftTag.fromMap(m)).toList();
  }

  @override
  Future<void> addTag(ShiftTag tag) async {
    final db = await _dbService.database;
    if (db == null) return;
    await db.insert('shift_tags', tag.toMap(), conflictAlgorithm: 5); // 5 = replace
  }

  @override
  Future<void> updateTag(ShiftTag tag) async {
    final db = await _dbService.database;
    if (db == null) return;
    await db.update(
      'shift_tags',
      tag.toMap(),
      where: 'id = ?',
      whereArgs: [tag.id],
      conflictAlgorithm: 5,
    );
  }

  @override
  Future<void> deleteTag(String id) async {
    final db = await _dbService.database;
    if (db == null) return;
    await db.delete('shift_tags', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> replaceTags(List<ShiftTag> tags) async {
    final db = await _dbService.database;
    if (db == null) return;

    await db.transaction((txn) async {
      await txn.delete('shift_tags');
      for (final tag in tags) {
        await txn.insert('shift_tags', tag.toMap());
      }
    });
  }
}
