import 'package:flutter/material.dart';
import '../data/user_repository.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const int _minAge = 14;
  static const int _maxAge = 100;

  final _formKey = GlobalKey<FormState>();

  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();

  String? _faceSkinType;
  String? _bodySkinType;
  String? _scalpSkinType;
  String? _gender;

  final List<TextEditingController> _allergenControllers = [
    TextEditingController(),
  ];

  bool _obscurePass = true;
  bool _obscureConfirm = true;

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
    // Live-валидация совпадения паролей
    _passwordController.addListener(_onPasswordChanged);
    _confirmPasswordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    // Перезапускаем валидацию формы без её полного сброса
    if (_confirmPasswordController.text.isNotEmpty) {
      _formKey.currentState?.validate();
    }
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _confirmPasswordController.removeListener(_onPasswordChanged);

    _loginController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  // ---------- Валидаторы ----------

  String? _validateLogin(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Введите логин';
    if (value.length < 3) return 'Логин — минимум 3 символа';
    if (value.contains(' ')) return 'Логин не должен содержать пробелы';
    return null;
  }

  String? _validatePassword(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return 'Введите пароль';
    if (value.length < 6) return 'Пароль — минимум 6 символов';
    if (value.contains(' ')) return 'Пароль не должен содержать пробелы';
    if (value == _loginController.text.trim()) {
      return 'Пароль не должен совпадать с логином';
    }
    return null;
  }

  String? _validateConfirm(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return 'Повторите пароль';
    if (value != _passwordController.text) return 'Пароли не совпадают';
    return null;
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

  // ---------- Отправка ----------

  void _submit() {
    // Дополнительно перепроверяем совпадение паролей вне формы
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пароли не совпадают')),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final allergens = _allergenControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final account = UserAccount(
      login: _loginController.text.trim(),
      password: _passwordController.text,
      faceSkinType: _faceSkinType!,
      bodySkinType: _bodySkinType!,
      scalpSkinType: _scalpSkinType!,
      allergens: allergens,
      age: int.parse(_ageController.text.trim()),
      gender: _gender!,
    );

    final error = UserRepository.instance.register(account);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Регистрация успешна! Теперь войдите.'),
        backgroundColor: Colors.green,
      ),
    );

    // Возврат на экран входа/приветствия
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация'),
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
                'Создайте аккаунт',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Заполните данные о себе',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 28),

              _sectionTitle('Учётные данные'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _loginController,
                decoration: const InputDecoration(
                  labelText: 'Логин',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: _validateLogin,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Повторите пароль',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: _validateConfirm,
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
              const SizedBox(height: 4),
              Text(
                'Впишите свои аллергены (можно оставить пустым)',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              ..._buildAllergenFields(),
              const SizedBox(height: 28),

              _sectionTitle('О себе'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                maxLength: 3, // максимум 3 цифры
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
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: primary.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Зарегистрироваться',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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