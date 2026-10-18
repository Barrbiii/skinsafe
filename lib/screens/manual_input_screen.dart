import 'package:flutter/material.dart';

class ManualInputScreen extends StatefulWidget {
  const ManualInputScreen({super.key});

  @override
  State<ManualInputScreen> createState() => _ManualInputScreenState();
}

class _ManualInputScreenState extends State<ManualInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _compositionController = TextEditingController();

  String? _productType;
  String? _bodyPart;

  final List<String> _productTypes = [
    'Крем',
    'Лосьон',
    'Гель для душа',
    'Шампунь',
    'Сыворотка',
    'Маска',
    'Тоник',
    'Другое',
  ];

  final List<String> _bodyParts = [
    'Лицо',
    'Тело',
    'Волосы / кожа головы',
    'Руки',
    'Ноги',
    'Другое',
  ];

  @override
  void dispose() {
    _brandController.dispose();
    _compositionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Данные сохранены (обработка появится позже)'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ввод вручную'),
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
                'Расскажите о средстве',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Заполните поля ниже',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 28),

              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Бренд',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Введите бренд' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _productType,
                decoration: const InputDecoration(
                  labelText: 'Тип средства',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _productTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _productType = v),
                validator: (v) => v == null ? 'Выберите тип средства' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _bodyPart,
                decoration: const InputDecoration(
                  labelText: 'Для какой части тела',
                  prefixIcon: Icon(Icons.accessibility_new),
                ),
                items: _bodyParts
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _bodyPart = v),
                validator: (v) => v == null ? 'Выберите часть тела' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _compositionController,
                minLines: 6,
                maxLines: 12,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  labelText: 'Состав (INCI)',
                  alignLabelWithHint: true,
                  hintText: 'Aqua, Glycerin, Niacinamide, ...',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Введите состав'
                    : null,
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Сохранить',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
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
}