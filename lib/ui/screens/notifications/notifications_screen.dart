import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../state/controllers.dart';

/// Notification inbox: unread highlight, mark one / mark all read, infinite scroll.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  static const route = '/notifications';

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _scroll = ScrollController();

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

  @override
  Widget build(BuildContext context) {
    final c = context.watch<NotificationController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: AppText.screenTitle.copyWith(fontSize: 22)),
        actions: [
          TextButton(
            onPressed: c.unread > 0 ? c.markAllRead : null,
            child: Text(
              'Mark all read',
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
      return const Center(child: CircularProgressIndicator());
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
    if (c.items.isEmpty) {
      return const _Message(
        icon: Icons.notifications_none_rounded,
        title: 'You’re all caught up',
        body: 'Booking updates, KYC results and payouts will show up here.',
      );
    }

    return ListView.separated(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
      itemCount: c.items.length + (c.loadingMore ? 1 : 0),
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i >= c.items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))),
          );
        }
        final n = c.items[i];
        return _NotificationTile(n: n, onTap: () => c.markRead(n));
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
                                fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800),
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(
                                color: AppColors.primary, shape: BoxShape.circle),
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
    // ListView so pull-to-refresh still works on empty / error states.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
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
