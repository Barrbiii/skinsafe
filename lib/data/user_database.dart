import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user_account.dart';

/// Обёртка над SQLite: открытие БД, создание таблицы, CRUD по пользователям.
class UserDatabase {
  UserDatabase._();
  static final UserDatabase instance = UserDatabase._();

  static const String _dbName = 'skinsafe.db';
  static const int _dbVersion = 3;
  static const String _table = 'users';

  Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $_table ADD COLUMN avatar_path TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE $_scansTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          brand TEXT NOT NULL,
          product_type TEXT NOT NULL,
          composition TEXT NOT NULL,
          is_safe INTEGER NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }
  }

  /// Вставка нового пользователя. Возвращает id.
  Future<int> insert(UserAccount account) async {
    final db = await _open();
    return db.insert(_table, account.toMap()..remove('id'));
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // v1 → v2: добавлена колонка avatar_path
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $_table ADD COLUMN avatar_path TEXT');
    }
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