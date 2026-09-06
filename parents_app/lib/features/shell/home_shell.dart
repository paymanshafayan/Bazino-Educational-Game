import 'package:flutter/material.dart';

import '../dashboard/dashboard_screen.dart';
import '../reality/reality_screen.dart';
import '../tips/tips_screen.dart';
import '../wallet/wallet_screen.dart';
import '../../core/session.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final childId = Session.I.childIds.first;
    final pages = [
      DashboardScreen(childId: childId),
      TipsScreen(childId: childId),
      RealityScreen(childId: childId),
      const WalletScreen(),
    ];
    return Scaffold(
      body: pages[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.insights), label: 'پیشرفت'),
          NavigationDestination(icon: Icon(Icons.home_work), label: 'یاری خانگی'),
          NavigationDestination(icon: Icon(Icons.school), label: 'پل واقعیت'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'کیف پول'),
        ],
      ),
    );
  }
}
