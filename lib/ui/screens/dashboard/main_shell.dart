import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/push_service.dart';
import '../../../state/controllers.dart';
import '../../widgets/chrome.dart';
import '../menu/more_menu_screen.dart';
import '../notifications/notifications_screen.dart';
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
  Timer? _notificationPollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardController>().load();
      context.read<ProfileController>().load();

      // Push: register FCM token with backend and keep the unread badge fresh.
      final notifications = context.read<NotificationController>();
      PushService.onActivity = () {
        notifications.refreshUnread();
      };
      PushService.onNotificationTapped = (payload) {
        if (mounted) {
          Navigator.pushNamed(context, NotificationsScreen.route);
        }
      };
      notifications.load();
      PushService.init();

      // Background periodic check: auto-sync new notifications from API every 30 seconds
      _notificationPollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) {
          context.read<NotificationController>().syncLatestNotifications();
        }
      });
    });
  }

  @override
  void dispose() {
    _notificationPollTimer?.cancel();
    super.dispose();
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.fastEaseInToSlowEaseOut,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final scale = Tween<double>(begin: 0.98, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: scale,
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_index),
          child: pages[_index],
        ),
      ),
      bottomNavigationBar: AyoBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
