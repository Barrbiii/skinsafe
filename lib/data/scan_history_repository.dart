import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/scan_history.dart';

class ScanHistoryRepository {
  ScanHistoryRepository._();
  static final ScanHistoryRepository instance = ScanHistoryRepository._();

  static const String _dbName = 'skinsafe.db';
  static const int _dbVersion = 3;
  static const String _table = 'scans';

  Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), _dbName);
    // ВАЖНО: onCreate/onUpgrade здесь НЕ передаём — они уже заданы
    // в UserDatabase.instance. sqflite корректно переиспользует
    // открытую БД по тому же пути, если версия совпадает.
    _db = await openDatabase(path, version: _dbVersion);
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

  /// Проверяет, есть ли уже такая запись в истории пользователя.
  Future<bool> exists({
    required int userId,
    required String brand,
    required String productType,
    required String composition,
  }) async {
    final db = await _open();
    final rows = await db.query(
      _table,
      where: 'user_id = ? AND brand = ? AND product_type = ? AND composition = ?',
      whereArgs: [userId, brand, productType, composition],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> delete(int id) async {
    final db = await _open();
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}