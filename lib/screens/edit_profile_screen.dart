import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/user_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const int _minAge = 14;
  static const int _maxAge = 100;

  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();

  String? _faceSkinType;
  String? _bodySkinType;
  String? _scalpSkinType;
  String? _gender;

  final List<TextEditingController> _allergenControllers = [];

  String? _avatarPath;
  bool _avatarChanged = false;
  bool _loading = false;

  final ImagePicker _picker = ImagePicker();

  final List<String> _skinTypes = [
    'Сухая',
    'Жирная',
    'Нормальная',
    'Комбинированная',
    'Чувствительная',
  ];

  final List<String> _genderOptions = ['Мужской', 'Женский', 'Другой'];

  @override
  void initState() {
    super.initState();
    final user = UserRepository.instance.user;
    if (user == null) return;

    _ageController.text = user.age.toString();
    _faceSkinType = user.faceSkinType;
    _bodySkinType = user.bodySkinType;
    _scalpSkinType = user.scalpSkinType;
    _gender = user.gender;
    _avatarPath = user.avatarPath;

    if (user.allergens.isEmpty) {
      _allergenControllers.add(TextEditingController());
    } else {
      for (final a in user.allergens) {
        _allergenControllers.add(TextEditingController(text: a));
      }
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    for (final c in _allergenControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addAllergenField() {
    setState(() => _allergenControllers.add(TextEditingController()));
  }

  void _removeAllergenField(int index) {
    setState(() {
      _allergenControllers[index].dispose();
      _allergenControllers.removeAt(index);
      if (_allergenControllers.isEmpty) {
        _allergenControllers.add(TextEditingController());
      }
    });
  }

  String? _validateAge(String? v) {
    final raw = v?.trim() ?? '';
    if (raw.isEmpty) return 'Введите возраст';
    if (!RegExp(r'^\d+$').hasMatch(raw)) {
      return 'Возраст должен быть целым числом';
    }
    final age = int.parse(raw);
    if (age < _minAge || age > _maxAge) {
      return 'Возраст должен быть от $_minAge до $_maxAge лет';
    }
    return null;
  }

  // ---------- Аватарка ----------

  Future<void> _pickAvatarSource() async {
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Сделать фото'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Выбрать из галереи'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              if (_avatarPath != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Удалить фото',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _avatarPath = null;
                      _avatarChanged = true;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );

    if (choice == null) return;

    try {
      final picked = await _picker.pickImage(
        source: choice,
        imageQuality: 85,
        maxWidth: 800,
      );
      if (picked == null) return;

      final saved = await _saveAvatarLocally(File(picked.path));
      if (!mounted) return;
      setState(() {
        _avatarPath = saved;
        _avatarChanged = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('Camera not available')
                ? 'Камера недоступна (в симуляторе её нет). Выберите фото из галереи.'
                : 'Не удалось получить изображение: $e',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// Копирует выбранный файл в директорию приложения,
  /// чтобы путь не «умер» вместе с временным кэшем iOS/Android.
  Future<String> _saveAvatarLocally(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}${p.extension(source.path)}';
    final saved = await source.copy(p.join(dir.path, fileName));

    // Удаляем прошлый аватар, если он лежал в той же папке
    final oldPath = _avatarPath;
    if (oldPath != null && oldPath.isNotEmpty) {
      final oldFile = File(oldPath);
      if (oldFile.existsSync() && oldPath != saved.path) {
        try {
          await oldFile.delete();
        } catch (_) {
          // не критично
        }
      }
    }
    return saved.path;
  }

  // ---------- Сохранение ----------

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final current = UserRepository.instance.user;
    if (current == null) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _loading = true);

    final allergens = _allergenControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final updated = current.copyWith(
      faceSkinType: _faceSkinType,
      bodySkinType: _bodySkinType,
      scalpSkinType: _scalpSkinType,
      allergens: allergens,
      age: int.parse(_ageController.text.trim()),
      gender: _gender,
    );

    var error = await UserRepository.instance.updateProfile(updated);

    if (error == null && _avatarChanged) {
      error = await UserRepository.instance.updateAvatar(_avatarPath);
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
      return;
    }

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Профиль обновлён'),
        backgroundColor: Colors.green,
        duration: Duration(milliseconds: 800),
      ),
    );

    navigator.pop(true);
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактирование профиля'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              const Text(
                'Редактируйте данные о себе',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Логин и пароль изменить нельзя',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Блок аватарки
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatarSource,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          _EditableAvatar(
                            avatarPath: _avatarPath,
                            color: primary,
                            size: 96,
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _pickAvatarSource,
                      child: const Text('Сменить фото'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _sectionTitle('Тип кожи'),
              const SizedBox(height: 12),
              _skinDropdown(
                label: 'Кожа лица',
                value: _faceSkinType,
                onChanged: (v) => setState(() => _faceSkinType = v),
              ),
              const SizedBox(height: 16),
              _skinDropdown(
                label: 'Кожа тела',
                value: _bodySkinType,
                onChanged: (v) => setState(() => _bodySkinType = v),
              ),
              const SizedBox(height: 16),
              _skinDropdown(
                label: 'Кожа головы',
                value: _scalpSkinType,
                onChanged: (v) => setState(() => _scalpSkinType = v),
              ),
              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionTitle('Аллергены'),
                  TextButton.icon(
                    onPressed: _addAllergenField,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Добавить'),
                    style: TextButton.styleFrom(foregroundColor: primary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._buildAllergenFields(),
              const SizedBox(height: 28),

              _sectionTitle('О себе'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                maxLength: 3,
                decoration: const InputDecoration(
                  labelText: 'Возраст',
                  helperText: 'От 14 до 100 лет',
                  prefixIcon: Icon(Icons.cake_outlined),
                  counterText: '',
                ),
                validator: _validateAge,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(
                  labelText: 'Пол',
                  prefixIcon: Icon(Icons.wc_outlined),
                ),
                items: _genderOptions
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v),
                validator: (v) => v == null ? 'Выберите пол' : null,
              ),

              const SizedBox(height: 36),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Сохранить',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _skinDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.face_retouching_natural),
      ),
      items: _skinTypes
          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Выберите тип кожи' : null,
    );
  }

  List<Widget> _buildAllergenFields() {
    return List.generate(_allergenControllers.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _allergenControllers[index],
                decoration: InputDecoration(
                  labelText: 'Аллерген ${index + 1}',
                  prefixIcon: const Icon(Icons.warning_amber_outlined),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Удалить',
              onPressed: _allergenControllers.length == 1
                  ? null
                  : () => _removeAllergenField(index),
              icon: Icon(
                Icons.delete_outline,
                color: _allergenControllers.length == 1
                    ? Colors.grey.shade400
                    : Colors.redAccent,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({
    required this.avatarPath,
    required this.color,
    required this.size,
  });

  final String? avatarPath;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasFile = avatarPath != null && avatarPath!.isNotEmpty;
    final fileExists = hasFile && File(avatarPath!).existsSync();

    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: color.withValues(alpha: 0.15),
        child: (hasFile && fileExists)
            ? Image.file(
          File(avatarPath!),
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (_, _, _) => _fallback(size),
        )
            : _fallback(size),
      ),
    );
  }

  Widget _fallback(double size) {
    return Icon(Icons.person, size: size * 0.56, color: color);
  }
}