import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/services/push_service.dart';
import '../../../core/services/toast_service.dart';
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
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
        context.read<NotificationController>().loadMore();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<NotificationController>().load();
      final token = await PushService.getOrFetchToken();
      if (mounted) setState(() => _fcmToken = token);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _copyFcmToken() {
    final token = _fcmToken ?? PushService.currentToken;
    if (token != null && token.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: token));
      PushService.playAlertSound();
      ToastService.showSuccess('FCM Device Token copied to clipboard!');
    } else {
      ToastService.showInfo('Fetching FCM token... Please try again in a moment');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<NotificationController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: AppText.screenTitle.copyWith(fontSize: 22)),
        actions: [
          IconButton(
            tooltip: 'Trigger Test Push Alert with Sound',
            icon: const Icon(Icons.notifications_active_rounded, color: AppColors.primary),
            onPressed: () => c.triggerDemoAlert(),
          ),
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

  Widget _buildFcmDemoCard(NotificationController c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'FCM PUSH NOTIFICATIONS: ACTIVE',
                style: AppText.captionCaps.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              const Icon(Icons.volume_up_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'Sound Alert ON',
                style: AppText.captionCaps.copyWith(
                  color: AppColors.primary,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Host notifications for vehicle bookings, returns, and payout credits with audio alerts.',
            style: AppText.body.copyWith(fontSize: 11.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.notifications_active_rounded, size: 16, color: Colors.white),
                  label: const Text(
                    'Test Sound Alert',
                    style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => c.triggerDemoAlert(),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.cardBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.copy_rounded, size: 14, color: AppColors.textPrimary),
                label: const Text(
                  'Copy FCM Token',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
                onPressed: _copyFcmToken,
              ),
            ],
          ),
        ],
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
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        children: [
          _buildFcmDemoCard(c),
          const SizedBox(height: 40),
          const _Message(
            icon: Icons.notifications_none_rounded,
            title: 'You’re all caught up',
            body: 'Booking updates, KYC results and payouts will show up here.',
          ),
        ],
      );
    }

    final totalCount = c.items.length + 1 + (c.loadingMore ? 1 : 0);

    return ListView.builder(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
      itemCount: totalCount,
      itemBuilder: (context, i) {
        if (i == 0) {
          return _buildFcmDemoCard(c);
        }
        final itemIndex = i - 1;
        if (itemIndex >= c.items.length) {
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
        final n = c.items[itemIndex];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _NotificationTile(n: n, onTap: () => c.markRead(n)),
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
