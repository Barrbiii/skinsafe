import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/scan_history.dart';

class ScanHistoryRepository {
  ScanHistoryRepository._();
  static final ScanHistoryRepository instance = ScanHistoryRepository._();

  static const String _dbName = 'skinsafe.db';
  static const String _table = 'scans';

  Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), _dbName);
    // Используем ту же БД, что и UserDatabase.
    // Не вызываем openDatabase с onCreate — БД уже создана и мигрирована.
    _db = await openDatabase(path, version: 3);
    return _db!;
  }

  Future<int> insert(ScanHistory scan) async {
    final db = await _open();
    return db.insert(_table, scan.toMap()..remove('id'));
  }

  Future<List<ScanHistory>> getForUser(int userId) async {
    final db = await _open();
    final rows = await db.query(
      _table,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map((e) => ScanHistory.fromMap(e)).toList();
  }

  Future<void> delete(int id) async {
    final db = await _open();
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}