import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user_account.dart';

/// Обёртка над SQLite: открытие БД, создание таблицы, CRUD по пользователям.
class UserDatabase {
  UserDatabase._();
  static final UserDatabase instance = UserDatabase._();

  static const String _dbName = 'skinsafe.db';
  static const int _dbVersion = 1;
  static const String _table = 'users';

  Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        login TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        face_skin_type TEXT NOT NULL,
        body_skin_type TEXT NOT NULL,
        scalp_skin_type TEXT NOT NULL,
        allergens TEXT NOT NULL DEFAULT '',
        age INTEGER NOT NULL,
        gender TEXT NOT NULL
      )
    ''');
  }

  /// Вставка нового пользователя. Возвращает id.
  Future<int> insert(UserAccount account) async {
    final db = await _open();
    return db.insert(_table, account.toMap()..remove('id'));
  }

  /// Обновление существующего пользователя по id.
  /// Возвращает количество затронутых строк (0, если не найден).
  Future<int> update(UserAccount account) async {
    if (account.id == null) {
      throw ArgumentError('Нельзя обновить пользователя без id');
    }
    final db = await _open();
    return db.update(
      _table,
      account.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  /// Поиск по логину. Возвращает null, если не найден.
  Future<UserAccount?> findByLogin(String login) async {
    final db = await _open();
    final rows = await db.query(
      _table,
      where: 'login = ?',
      whereArgs: [login],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserAccount.fromMap(rows.first);
  }

  /// Поиск по id.
  Future<UserAccount?> findById(int id) async {
    final db = await _open();
    final rows = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserAccount.fromMap(rows.first);
  }

  /// Очистить таблицу (пригодится при отладке).
  Future<void> clear() async {
    final db = await _open();
    await db.delete(_table);
  }
}