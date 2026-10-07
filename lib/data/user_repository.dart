/// Простое in-memory хранилище зарегистрированного пользователя.
/// Синглтон — один экземпляр на всё приложение.
class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  UserAccount? _user;

  bool get hasUser => _user != null;

  UserAccount? get user => _user;

  /// Регистрация. Возвращает null при успехе, иначе — текст ошибки.
  String? register(UserAccount account) {
    if (_user != null) {
      return 'Аккаунт уже зарегистрирован. Выполните вход.';
    }
    _user = account;
    return null;
  }

  /// Проверка логина и пароля. Возвращает null при успехе, иначе — текст ошибки.
  String? authenticate(String login, String password) {
    final u = _user;
    if (u == null) {
      return 'Аккаунт не найден. Сначала зарегистрируйтесь.';
    }
    if (u.login != login) {
      return 'Неверный логин';
    }
    if (u.password != password) {
      return 'Неверный пароль';
    }
    return null;
  }
}

class UserAccount {
  final String login;
  final String password;
  final String faceSkinType;
  final String bodySkinType;
  final String scalpSkinType;
  final List<String> allergens;
  final int age;
  final String gender;

  UserAccount({
    required this.login,
    required this.password,
    required this.faceSkinType,
    required this.bodySkinType,
    required this.scalpSkinType,
    required this.allergens,
    required this.age,
    required this.gender,
  });
}