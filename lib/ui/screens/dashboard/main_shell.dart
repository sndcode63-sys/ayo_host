import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/controllers.dart';
import '../../widgets/chrome.dart';
import '../menu/more_menu_screen.dart';
import 'dashboard_screen.dart';
import 'placeholder_tab.dart';

/// Hosts the 5 bottom-nav tabs: Dashboard, Fleet, Calendar, Messages, More.
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
      const PlaceholderTab(title: 'Fleet'),
      const PlaceholderTab(title: 'Calendar'),
      const PlaceholderTab(title: 'Messages'),
      const MoreMenuScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: AyoBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
