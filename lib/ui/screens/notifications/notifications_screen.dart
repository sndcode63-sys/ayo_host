import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/toast_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../state/controllers.dart';
import '../../widgets/shimmer_loading.dart';
import '../documents/vehicle_documents_screen.dart';
import '../onboarding/payout_setup_screen.dart';

/// Dynamic Notification inbox: category filters, swipe-to-delete, action navigation, smooth shimmer.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  static const route = '/notifications';

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _scroll = ScrollController();
  int _selectedFilterIndex = 0;

  static const List<String> _filters = [
    'All',
    'Bookings',
    'Vehicles',
    'Payouts & KYC',
  ];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
        context.read<NotificationController>().loadMore();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationController>().load();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _confirmClearAll(NotificationController c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text(
          'Are you sure you want to permanently delete all notifications from your account?',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await c.clearAll();
              if (ok) {
                ToastService.showSuccess('All notifications cleared successfully');
              } else {
                ToastService.showError('Could not clear notifications');
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _onNotificationTap(AppNotification n) {
    final c = context.read<NotificationController>();
    c.markRead(n);

    final t = '${n.type} ${n.title} ${n.body}'.toLowerCase();
    if (t.contains('kyc') || t.contains('payout') || t.contains('bank') || t.contains('upi')) {
      Navigator.pushNamed(context, PayoutSetupScreen.route);
    } else if (t.contains('vehicle') || t.contains('listing') || t.contains('car') || t.contains('doc')) {
      Navigator.pushNamed(context, VehicleDocumentsScreen.route);
    } else if (n.body.length > 70) {
      _showNotificationDetail(n);
    }
  }

  void _showNotificationDetail(AppNotification n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.fieldBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(n.title, style: AppText.sectionTitle.copyWith(fontSize: 18)),
              const SizedBox(height: 10),
              Text(n.body, style: AppText.body.copyWith(fontSize: 14, height: 1.4)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_filters.length, (idx) {
            final isSelected = _selectedFilterIndex == idx;
            final label = _filters[idx];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: isSelected,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.cardBorder,
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedFilterIndex = idx);
                  }
                },
              ),
            );
          }),
        ),
      ),
    );
  }

  List<AppNotification> _filterNotifications(List<AppNotification> all) {
    if (_selectedFilterIndex == 0) return all;
    return all.where((n) {
      final t = '${n.type} ${n.title} ${n.body}'.toLowerCase();
      if (_selectedFilterIndex == 1) {
        return t.contains('book') || t.contains('trip') || t.contains('handover') || t.contains('ride');
      }
      if (_selectedFilterIndex == 2) {
        return t.contains('vehicle') || t.contains('car') || t.contains('listing') || t.contains('fleet') || t.contains('doc');
      }
      if (_selectedFilterIndex == 3) {
        return t.contains('payout') || t.contains('kyc') || t.contains('bank') || t.contains('upi') || t.contains('earn');
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<NotificationController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: AppText.screenTitle.copyWith(fontSize: 22)),
        actions: [
          if (c.items.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClearAll(c),
              child: const Text(
                'Clear all',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDC2626),
                ),
              ),
            ),
          TextButton(
            onPressed: c.unread > 0 ? c.markAllRead : null,
            child: Text(
              'Mark read',
              style: AppText.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: c.unread > 0 ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: c.load,
        child: _body(c),
      ),
    );
  }

  Widget _body(NotificationController c) {
    if (c.loading && c.items.isEmpty) {
      return const NotificationShimmer();
    }

    if (c.error != null && c.items.isEmpty) {
      return _Message(
        icon: Icons.cloud_off_rounded,
        title: 'Can’t load notifications',
        body: c.error!,
        actionLabel: 'Try again',
        onAction: c.load,
      );
    }

    final filtered = _filterNotifications(c.items);

    if (c.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
        children: [
          _buildFilterChips(),
          const SizedBox(height: 60),
          const _Message(
            icon: Icons.notifications_none_rounded,
            title: 'You’re all caught up',
            body: 'Real-time vehicle booking alerts, KYC status, and payouts will appear here dynamically.',
          ),
        ],
      );
    }

    final totalCount = filtered.length + 1 + (c.loadingMore ? 1 : 0);

    return ListView.builder(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
      itemCount: totalCount,
      itemBuilder: (context, i) {
        if (i == 0) {
          return _buildFilterChips();
        }

        final itemIndex = i - 1;
        if (itemIndex >= filtered.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
          );
        }

        final n = filtered[itemIndex];

        // Swipe / Slide-to-Delete Dismissible
        return Dismissible(
          key: ValueKey('notif_${n.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.only(right: 20),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                SizedBox(width: 6),
                Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          onDismissed: (_) async {
            final ok = await c.delete(n);
            if (ok) {
              ToastService.showSuccess('Notification deleted successfully');
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _NotificationTile(
              n: n,
              onTap: () => _onNotificationTap(n),
            ),
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.n, required this.onTap});

  final AppNotification n;
  final VoidCallback onTap;

  (IconData, Color) get _visual {
    final t = '${n.type} ${n.title}'.toLowerCase();
    if (t.contains('kyc') || t.contains('verif')) return (Icons.verified_user_rounded, AppColors.success);
    if (t.contains('pay') || t.contains('payout') || t.contains('earn')) {
      return (Icons.account_balance_wallet_rounded, AppColors.warning);
    }
    if (t.contains('book') || t.contains('trip') || t.contains('handover')) {
      return (Icons.event_available_rounded, AppColors.primary);
    }
    if (t.contains('vehicle') || t.contains('car') || t.contains('listing')) {
      return (Icons.directions_car_filled_rounded, AppColors.textPrimary);
    }
    return (Icons.notifications_rounded, AppColors.textSecondary);
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _visual;
    final radius = BorderRadius.circular(AppRadius.card);

    return Material(
      color: n.isRead ? AppColors.card : AppColors.primarySoft.withValues(alpha: 0.55),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: n.isRead ? AppColors.cardBorder : AppColors.primaryBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 21, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: AppText.input.copyWith(
                              fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (n.body.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(n.body, style: AppText.body.copyWith(fontSize: 12.5)),
                    ],
                    const SizedBox(height: 6),
                    Text(_ago(n.createdAt), style: AppText.captionCaps),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _ago(DateTime? t) {
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} hr ago';
    if (d.inDays < 7) return '${d.inDays} d ago';
    return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year}';
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.18),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: AppColors.fieldMuted, shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 18),
        Text(title, style: AppText.sectionTitle, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(body, style: AppText.body, textAlign: TextAlign.center),
        if (actionLabel != null) ...[
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                side: const BorderSide(color: AppColors.fieldBorder),
              ),
              child: Text(actionLabel!, style: AppText.input),
            ),
          ),
        ],
      ],
    );
  }
}
