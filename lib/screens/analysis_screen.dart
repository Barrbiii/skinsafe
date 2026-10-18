import 'package:flutter/material.dart';
import '../data/user_repository.dart';
import '../data/scan_history_repository.dart';
import '../models/scan_history.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({
    super.key,
    required this.composition,
    this.brand,
    this.productType,
  });

  final String composition;
  final String? brand;
  final String? productType;

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  bool _isAnalyzing = true;
  List<String> _foundAllergens = [];
  bool _isSafe = true;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    // Имитация работы нейросети
    await Future.delayed(const Duration(seconds: 2));

    final user = UserRepository.instance.user;
    final userAllergens = user?.allergens ?? [];
    final compositionLower = widget.composition.toLowerCase();

    final found = <String>[];
    for (final allergen in userAllergens) {
      if (compositionLower.contains(allergen.toLowerCase())) {
        found.add(allergen);
      }
    }

    if (!mounted) return;
    setState(() {
      _isAnalyzing = false;
      _foundAllergens = found;
      _isSafe = found.isEmpty;
    });
  }

  Future<void> _saveToHistory() async {
    final user = UserRepository.instance.user;
    if (user?.id == null) return;

    final brand = widget.brand ?? 'Без бренда';
    final productType = widget.productType ?? 'Не указано';

    final exists = await ScanHistoryRepository.instance.exists(
      userId: user!.id!,
      brand: brand,
      productType: productType,
      composition: widget.composition,
    );

    if (exists) {
      if (!mounted) return;
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Этот состав уже есть в истории'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final scan = ScanHistory(
      userId: user.id!,
      brand: brand,
      productType: productType,
      composition: widget.composition,
      isSafe: _isSafe,
      createdAt: DateTime.now(),
    );

    await ScanHistoryRepository.instance.insert(scan);
    if (!mounted) return;
    setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Анализ состава'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: !_isAnalyzing, // Не даем уйти во время анализа
      ),
      body: SafeArea(
        child: _isAnalyzing ? _buildLoading(primary) : _buildResult(primary),
      ),
    );
  }

  Widget _buildLoading(Color primary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: primary),
          const SizedBox(height: 24),
          const Text(
            'Нейросеть анализирует состав...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Это займет пару секунд',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(Color primary) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (widget.brand != null || widget.productType != null) ...[
          Text(
            [widget.brand, widget.productType].where((e) => e != null).join(' · '),
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],

        // Плашка результата
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _isSafe ? Colors.green.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isSafe ? Colors.green : Colors.redAccent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                _isSafe ? Icons.verified_user : Icons.warning_amber_rounded,
                size: 64,
                color: _isSafe ? Colors.green : Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                _isSafe ? 'Состав безопасен' : 'Внимание!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _isSafe ? Colors.green[800] : Colors.redAccent[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isSafe
                    ? 'В составе не найдено ваших аллергенов.'
                    : 'В составе найдены вещества, на которые у вас аллергия:',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),

        if (!_isSafe) ...[
          const SizedBox(height: 24),
          const Text(
            'Найденные аллергены:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ..._foundAllergens.map(
                (a) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 12),
                  Text(a, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 32),
        const Text(
          'Состав:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Text(
            widget.composition,
            style: TextStyle(color: Colors.grey[800], height: 1.5),
          ),
        ),

        const SizedBox(height: 32),

        if (!_saved)
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _saveToHistory,
              icon: const Icon(Icons.save_alt),
              label: const Text(
                'Сохранить в историю',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        if (_saved)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Сохранено в историю',
                  style: TextStyle(color: Colors.green, fontSize: 16),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),
        SizedBox(
          height: 54,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: BorderSide(color: primary, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Готово', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}