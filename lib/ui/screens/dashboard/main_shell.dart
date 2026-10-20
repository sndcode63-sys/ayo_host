import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/controllers.dart';
import '../../widgets/chrome.dart';
import '../menu/more_menu_screen.dart';
import 'dashboard_screen.dart';
import 'fleet_screen.dart';

/// Hosts the 3 bottom-nav tabs: Dashboard, Fleet, More.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static const route = '/home';

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardController>().load();
      context.read<ProfileController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardScreen(),
      const FleetScreen(),
      const MoreMenuScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: AyoBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
