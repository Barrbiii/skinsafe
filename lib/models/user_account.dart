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
  final String? avatarPath;

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
    this.avatarPath,
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
      'avatar_path': avatarPath,
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
      avatarPath: map['avatar_path'] as String?,
    );
  }

  /// Удобный метод копирования с изменением отдельных полей.
  UserAccount copyWith({
    int? id,
    String? login,
    String? password,
    String? faceSkinType,
    String? bodySkinType,
    String? scalpSkinType,
    List<String>? allergens,
    int? age,
    String? gender,
    String? avatarPath,
    bool clearAvatar = false,
  }) {
    return UserAccount(
      id: id ?? this.id,
      login: login ?? this.login,
      password: password ?? this.password,
      faceSkinType: faceSkinType ?? this.faceSkinType,
      bodySkinType: bodySkinType ?? this.bodySkinType,
      scalpSkinType: scalpSkinType ?? this.scalpSkinType,
      allergens: allergens ?? this.allergens,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
    );
  }
}