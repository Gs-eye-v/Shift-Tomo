import 'package:flutter/foundation.dart';
import 'database_stub.dart' if (dart.library.io) 'package:sqflite/sqflite.dart' as sqlite;
import 'package:path/path.dart' as p;

class DatabaseService {
  static dynamic _database;

  Future<dynamic> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  Future<dynamic> _initDatabase() async {
    if (kIsWeb) return null;
    final dbPath = await sqlite.getDatabasesPath();
    final path = p.join(dbPath, 'shift_checker.db');
    return await sqlite.openDatabase(
      path,
      version: 3, // バージョンを3に上げる
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE profiles (id TEXT PRIMARY KEY, name TEXT, is_me INTEGER)');
        // バージョン3相当の初期テーブル作成
        await db.execute('''
          CREATE TABLE shift_tags (
            id TEXT PRIMARY KEY, 
            title TEXT, 
            watermark_char TEXT, 
            emoji TEXT, 
            color_code INTEGER, 
            start_time TEXT, 
            end_time TEXT, 
            break_minutes INTEGER DEFAULT 60, 
            hourly_wage INTEGER, 
            is_day_off INTEGER DEFAULT 0
          )
        ''');
        await db.execute('CREATE TABLE shifts (id TEXT PRIMARY KEY, profile_id TEXT, tag_id TEXT, date TEXT, memo TEXT, sub_tasks TEXT)');
        await db.insert('profiles', {'id': 'my_id', 'name': '自分', 'is_me': 1});
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // V2: 旧フィールド追加
          await db.execute('ALTER TABLE shift_tags ADD COLUMN hourly_rate REAL');
          await db.execute('ALTER TABLE shift_tags ADD COLUMN work_hours REAL');
        }
        if (oldVersion < 3) {
          // V3: 新規フィールド追加
          await db.execute('ALTER TABLE shift_tags ADD COLUMN start_time TEXT');
          await db.execute('ALTER TABLE shift_tags ADD COLUMN end_time TEXT');
          await db.execute('ALTER TABLE shift_tags ADD COLUMN break_minutes INTEGER DEFAULT 60');
          await db.execute('ALTER TABLE shift_tags ADD COLUMN hourly_wage INTEGER');
          await db.execute('ALTER TABLE shift_tags ADD COLUMN is_day_off INTEGER DEFAULT 0');
        }
      },
    );
  }
}
