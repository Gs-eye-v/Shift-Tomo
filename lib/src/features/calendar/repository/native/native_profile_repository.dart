import 'package:shift_tomo/src/features/calendar/model/profile.dart';
import 'package:shift_tomo/src/features/calendar/repository/profile_repository.dart';
import 'package:shift_tomo/src/utils/database_service.dart';

class SqliteProfileRepository implements ProfileRepository {
  final DatabaseService _dbService = DatabaseService();

  @override
  Future<List<Profile>> getProfiles() async {
    final db = await _dbService.database;
    if (db == null) return [];
    final List<Map<String, dynamic>> maps = await db.query('profiles');
    return maps.map((m) => Profile.fromMap(m)).toList();
  }
}
