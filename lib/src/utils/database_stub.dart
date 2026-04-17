// sqflite の型とメソッドをスタブ化
// Webビルド時に compilation error を防ぐためのファイル

Future<String> getDatabasesPath() => throw UnsupportedError('sqflite not supported on web');

Future<dynamic> openDatabase(
  String path, {
  int? version,
  Future<void> Function(dynamic db, int version)? onCreate,
  Future<void> Function(dynamic db, int oldVersion, int newVersion)? onUpgrade,
}) => throw UnsupportedError('sqflite not supported on web');

class Database {
  Future<void> execute(String sql, [List<dynamic>? arguments]) => throw UnimplementedError();
  Future<int> insert(String table, Map<String, dynamic> values, {String? nullColumnHack, dynamic conflictAlgorithm}) => throw UnimplementedError();
  Future<List<Map<String, dynamic>>> query(String table, {bool? distinct, List<String>? columns, String? where, List<dynamic>? whereArgs, String? groupBy, String? having, String? orderBy, int? limit, int? offset}) => throw UnimplementedError();
  Future<int> update(String table, Map<String, dynamic> values, {String? where, List<dynamic>? whereArgs, dynamic conflictAlgorithm}) => throw UnimplementedError();
  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs}) => throw UnimplementedError();
  Future<T> transaction<T>(Future<T> Function(dynamic txn) action, {bool? exclusive}) => throw UnimplementedError();
}
