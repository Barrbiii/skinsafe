import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_account.dart';
import 'user_database.dart';

/// Репозиторий пользователя.
/// Работает с SQLite (учётные записи) и SharedPreferences
/// (id активного пользователя между запусками приложения).
class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  static const String _prefsKeyActiveUserId = 'active_user_id';

  UserAccount? _current;

  UserAccount? get user => _current;

  bool get hasUser => _current != null;

  /// Вызывается при старте приложения: подтягивает активного
  /// пользователя из SharedPreferences, если он есть.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_prefsKeyActiveUserId);
    if (id == null) return;
    _current = await UserDatabase.instance.findById(id);
  }

  /// Регистрация. Возвращает null при успехе, иначе — текст ошибки.
  Future<String?> register(UserAccount account) async {
    final existing = await UserDatabase.instance.findByLogin(account.login);
    if (existing != null) {
      return 'Логин уже занят';
    }

    final id = await UserDatabase.instance.insert(account);

    // Сразу логиним пользователя
    _current = UserAccount(
      id: id,
      login: account.login,
      password: account.password,
      faceSkinType: account.faceSkinType,
      bodySkinType: account.bodySkinType,
      scalpSkinType: account.scalpSkinType,
      allergens: account.allergens,
      age: account.age,
      gender: account.gender,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKeyActiveUserId, id);
    return null;
  }

  /// Вход. Возвращает null при успехе, иначе — текст ошибки.
  Future<String?> login(String login, String password) async {
    final u = await UserDatabase.instance.findByLogin(login);
    if (u == null) {
      return 'Пользователь с таким логином не найден';
    }
    if (u.password != password) {
      return 'Неверный пароль';
    }
    _current = u;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKeyActiveUserId, u.id!);
    return null;
  }

  /// Обновление профиля текущего пользователя.
  /// Возвращает null при успехе, иначе — текст ошибки.
  Future<String?> updateProfile(UserAccount updated) async {
    if (_current == null) {
      return 'Нет активного пользователя';
    }
    if (updated.id != _current!.id) {
      return 'Нельзя изменить чужой профиль';
    }
    try {
      final rows = await UserDatabase.instance.update(updated);
      if (rows == 0) {
        return 'Не удалось обновить профиль';
      }
      _current = updated;
      return null;
    } catch (e) {
      return 'Ошибка при обновлении: $e';
    }
  }

  /// Выход: сбрасываем активного пользователя.
  Future<void> logout() async {
    _current = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyActiveUserId);
  }
}