import '../models/scan_history.dart';
import 'user_database.dart';

class ScanHistoryRepository {
  ScanHistoryRepository._();
  static final ScanHistoryRepository instance = ScanHistoryRepository._();

  static const String _table = 'scans';

  Future<int> insert(ScanHistory scan) async {
    final db = await UserDatabase.instance.open();
    return db.insert(_table, scan.toMap()..remove('id'));
  }

  Future<List<ScanHistory>> getForUser(int userId) async {
    final db = await UserDatabase.instance.open();
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
    final db = await UserDatabase.instance.open();
    final rows = await db.query(
      _table,
      where: 'user_id = ? AND brand = ? AND product_type = ? AND composition = ?',
      whereArgs: [userId, brand, productType, composition],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> delete(int id) async {
    final db = await UserDatabase.instance.open();
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}