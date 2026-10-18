import '../analysis_screen.dart';
import 'package:flutter/material.dart';
import '../../data/scan_history_repository.dart';
import '../../data/user_repository.dart';
import '../../models/scan_history.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  late Future<List<ScanHistory>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final userId = UserRepository.instance.user?.id;
    if (userId == null) {
      _historyFuture = Future.value([]);
    } else {
      _historyFuture = ScanHistoryRepository.instance.getForUser(userId);
    }
  }

  Future<void> _refresh() async {
    setState(_loadHistory);
    await _historyFuture;
  }

  Future<void> _deleteItem(int id) async {
    await ScanHistoryRepository.instance.delete(id);
    if (!mounted) return;
    setState(_loadHistory);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Удалено из истории')),
    );
  }

  Future<void> _openScan(ScanHistory scan) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AnalysisScreen(
          composition: scan.composition,
          brand: scan.brand,
          productType: scan.productType,
          initialIsSafe: scan.isSafe,
          scanId: scan.id,
        ),
      ),
    );
    // Если вернулось true, значит запись удалили внутри экрана
    if (deleted == true && mounted) {
      setState(_loadHistory);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<ScanHistory>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return _buildEmpty();
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final scan = items[index];
                return Dismissible(
                  key: ValueKey(scan.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Удалить запись?'),
                        content: const Text('Это действие нельзя отменить.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Отмена'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              'Удалить',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) => _deleteItem(scan.id!),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: ListTile(
                      onTap: () => _openScan(scan),
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: scan.isSafe
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.redAccent.withValues(alpha: 0.15),
                        child: Icon(
                          scan.isSafe ? Icons.check : Icons.warning,
                          color: scan.isSafe ? Colors.green : Colors.redAccent,
                        ),
                      ),
                      title: Text(
                        scan.brand,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(scan.productType, style: TextStyle(color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          Text(
                            '${scan.createdAt.day}.${scan.createdAt.month}.${scan.createdAt.year}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 100),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'История сканирований пуста',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Здесь появятся средства, которые вы добавите',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}