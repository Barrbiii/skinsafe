class UserAccount {
  final int? id;
  final String login;
  final String password;
  final String faceSkinType;
  final String bodySkinType;
  final String scalpSkinType;
  final List<String> allergens;
  final int age;
  final String gender;

  UserAccount({
    this.id,
    required this.login,
    required this.password,
    required this.faceSkinType,
    required this.bodySkinType,
    required this.scalpSkinType,
    required this.allergens,
    required this.age,
    required this.gender,
  });

  /// Преобразование в Map для записи в SQLite.
  /// Аллергены храним строкой через разделитель '|'.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'login': login,
      'password': password,
      'face_skin_type': faceSkinType,
      'body_skin_type': bodySkinType,
      'scalp_skin_type': scalpSkinType,
      'allergens': allergens.join('|'),
      'age': age,
      'gender': gender,
    };
  }

  /// Восстановление из Map (после чтения из SQLite).
  factory UserAccount.fromMap(Map<String, Object?> map) {
    final rawAllergens = (map['allergens'] as String?) ?? '';
    return UserAccount(
      id: map['id'] as int?,
      login: map['login'] as String,
      password: map['password'] as String,
      faceSkinType: map['face_skin_type'] as String,
      bodySkinType: map['body_skin_type'] as String,
      scalpSkinType: map['scalp_skin_type'] as String,
      allergens: rawAllergens.isEmpty ? [] : rawAllergens.split('|'),
      age: map['age'] as int,
      gender: map['gender'] as String,
    );
  }
}