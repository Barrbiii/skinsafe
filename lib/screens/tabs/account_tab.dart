import 'package:flutter/material.dart';
import '../../data/user_repository.dart';
import '../edit_profile_screen.dart';
import '../welcome_screen.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    await UserRepository.instance.logout();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
    );
  }

  Future<void> _editProfile() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (changed == true && mounted) {
      setState(() {}); // перерисовка с новыми данными из UserRepository
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = UserRepository.instance.user;
    final primary = Theme.of(context).colorScheme.primary;

    if (user == null) {
      return const Center(child: Text('Нет активного пользователя'));
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: primary.withValues(alpha: 0.15),
                child: Icon(Icons.person, size: 36, color: primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.login,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Возраст: ${user.age} · ${user.gender}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Редактировать профиль'),
              style: TextButton.styleFrom(
                foregroundColor: primary,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 16),

          _InfoBlock(
            title: 'Тип кожи',
            rows: {
              'Лицо': user.faceSkinType,
              'Тело': user.bodySkinType,
              'Кожа головы': user.scalpSkinType,
            },
          ),
          const SizedBox(height: 16),

          _InfoBlock(
            title: 'Аллергены',
            rows: user.allergens.isEmpty
                ? {'': 'Не указаны'}
                : {for (final a in user.allergens) '': a},
          ),
          const SizedBox(height: 32),

          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text(
                'Выйти из аккаунта',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.title, required this.rows});

  final String title;
  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...rows.entries.map(
                (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  if (e.key.isNotEmpty) ...[
                    SizedBox(
                      width: 110,
                      child: Text(
                        e.key,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ],
                  Expanded(
                    child: Text(
                      e.value,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}