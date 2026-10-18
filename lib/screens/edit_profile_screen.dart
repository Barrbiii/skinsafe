import 'package:flutter/material.dart';

import '../data/user_repository.dart';
import '../models/user_account.dart';

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

  bool _loading = false;

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

    final updated = UserAccount(
      id: current.id,
      login: current.login,
      password: current.password,
      faceSkinType: _faceSkinType!,
      bodySkinType: _bodySkinType!,
      scalpSkinType: _scalpSkinType!,
      allergens: allergens,
      age: int.parse(_ageController.text.trim()),
      gender: _gender!,
    );

    final error = await UserRepository.instance.updateProfile(updated);

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

    navigator.pop(true); // true = были изменения
  }

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
              const SizedBox(height: 28),

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
                value: _gender,
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
      value: value,
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