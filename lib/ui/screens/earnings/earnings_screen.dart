import '../../widgets/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../state/controllers.dart';
import '../../widgets/cards.dart';

/// Earnings overview from `GET /host/earnings`.
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  static const route = '/earnings';

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final _money = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EarningsController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<EarningsController>();
    final s = c.stats;

    return Scaffold(
      appBar: AppBar(
        title: Text('Earnings', style: AppText.screenTitle.copyWith(fontSize: 22)),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: c.load,
        child: _content(c, s),
      ),
    );
  }

  Widget _content(EarningsController c, EarningsStats? s) {
    if (c.loading && s == null) return const EarningsShimmer();

    if (c.error != null && s == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          const Icon(Icons.cloud_off_rounded, size: 44, color: AppColors.textMuted),
          const SizedBox(height: 14),
          Text('Can’t load earnings', style: AppText.sectionTitle, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(c.error!, style: AppText.body, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(
              onPressed: c.load,
              child: Text('Try again', style: AppText.input),
            ),
          ),
        ],
      );
    }

    final stats = s ?? const EarningsStats();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 32),
      children: [
        _Hero(stats: stats, money: _money),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _Metric(label: 'Pending payout', value: _money.format(stats.pendingPayout), icon: Icons.schedule_rounded, color: AppColors.warning)),
            const SizedBox(width: 12),
            Expanded(child: _Metric(label: 'Paid out', value: _money.format(stats.paidOut), icon: Icons.check_circle_rounded, color: AppColors.success)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _Metric(label: 'Last month', value: _money.format(stats.lastMonth), icon: Icons.calendar_month_rounded, color: AppColors.textSecondary)),
            const SizedBox(width: 12),
            Expanded(child: _Metric(label: 'Completed trips', value: '${stats.completedTrips}', icon: Icons.directions_car_filled_rounded, color: AppColors.primary)),
          ],
        ),
        if (stats.monthly.length >= 2) ...[
          const SizedBox(height: 22),
          Text('Monthly earnings', style: AppText.sectionTitle),
          const SizedBox(height: 12),
          AppCard(child: _BarChart(points: stats.monthly, money: _money)),
        ],
        const SizedBox(height: 22),
        Text('Recent activity', style: AppText.sectionTitle),
        const SizedBox(height: 12),
        if (stats.recent.isEmpty)
          AppCard(
            child: Column(
              children: [
                const Icon(Icons.receipt_long_outlined, size: 30, color: AppColors.textMuted),
                const SizedBox(height: 10),
                Text(
                  stats.isEmpty
                      ? 'No earnings yet. Once a guest completes a trip, your payout shows here.'
                      : 'No recent transactions.',
                  style: AppText.body,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                for (var i = 0; i < stats.recent.length; i++) ...[
                  _EntryRow(entry: stats.recent[i], money: _money),
                  if (i != stats.recent.length - 1) const Divider(),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.stats, required this.money});

  final EarningsStats stats;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final up = stats.changePercent >= 0;
    final headline = stats.total > 0 ? stats.total : stats.thisMonth;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card + 4),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.inkRaised, AppColors.ink],
        ),
        border: Border.all(color: AppColors.inkBorder),
        boxShadow: AppShadows.floating,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total earnings',
                  style: AppText.body.copyWith(
                      fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.65))),
              if (stats.changePercent != 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (up ? const Color(0xFF2FD071) : const Color(0xFFFF4D5A)).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          size: 14, color: up ? const Color(0xFF2FD071) : const Color(0xFFFF4D5A)),
                      const SizedBox(width: 4),
                      Text('${up ? '+' : ''}${stats.changePercent.toStringAsFixed(1)}%',
                          style: AppText.captionCaps.copyWith(
                              fontWeight: FontWeight.w800,
                              color: up ? const Color(0xFF2FD071) : const Color(0xFFFF4D5A))),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(money.format(headline),
              style: AppText.screenTitle.copyWith(fontSize: 40, letterSpacing: -1.4, color: Colors.white)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.white70),
                const SizedBox(width: 10),
                Text('This month',
                    style: AppText.body.copyWith(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.7))),
                const Spacer(),
                Text(money.format(stats.thisMonth),
                    style: AppText.input.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon, required this.color});

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(value, style: AppText.screenTitle.copyWith(fontSize: 20)),
          const SizedBox(height: 2),
          Text(label, style: AppText.captionCaps),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.points, required this.money});

  final List<EarningsPoint> points;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final shown = points.length > 6 ? points.sublist(points.length - 6) : points;
    final max = shown.map((e) => e.amount).fold<double>(0, (a, b) => a > b ? a : b);
    const chartHeight = 120.0;

    return SizedBox(
      height: chartHeight + 44,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < shown.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    NumberFormat.compact().format(shown[i].amount),
                    style: AppText.captionCaps.copyWith(fontSize: 10.5),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    width: 26,
                    height: max <= 0 ? 4 : (shown[i].amount / max * chartHeight).clamp(4.0, chartHeight),
                    decoration: BoxDecoration(
                      color: i == shown.length - 1 ? AppColors.primary : AppColors.ink.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(shown[i].label, style: AppText.captionCaps, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.money});

  final EarningsEntry entry;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.south_west_rounded, size: 18, color: AppColors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title, style: AppText.input, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (entry.subtitle.isNotEmpty)
                  Text(entry.subtitle, style: AppText.captionCaps, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+${money.format(entry.amount)}',
                  style: AppText.input.copyWith(color: AppColors.success, fontWeight: FontWeight.w800)),
              if (entry.status.isNotEmpty) Text(entry.status, style: AppText.captionCaps),
            ],
          ),
        ],
      ),
    );
  }
}
