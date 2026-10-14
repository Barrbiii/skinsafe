import 'package:flutter/material.dart';
import '../widgets/floating_nav_bar.dart';
import 'tabs/account_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/home_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 1; // Главная посередине

  static const _titles = ['История', 'SkinSafe', 'Аккаунт'];
  static const _tabs = [HistoryTab(), HomeTab(), AccountTab()];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        extendBody: true, // панель "плавает" над содержимым
        appBar: AppBar(
          title: Text(_titles[_index]),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: IndexedStack(
          index: _index,
          children: const [
            HistoryTab(),
            HomeTab(),
            AccountTab(),
          ],
        ),
        bottomNavigationBar: FloatingNavBar(
          index: _index,
          onChanged: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}