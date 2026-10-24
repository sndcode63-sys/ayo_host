import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/controllers.dart';
import '../../widgets/cards.dart';

/// AYO Host Listing Performance & Insights Screen with Circular Chart & Metrics
class PerformanceInsightsScreen extends StatelessWidget {
  const PerformanceInsightsScreen({super.key});

  static const route = '/insights';

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardController>();
    final vehicles = dash.vehicles;
    final stats = dash.stats;

    final totalVehicles = vehicles.length;
    final activeCount = vehicles.where((v) => v.status == 'ACTIVE' || v.status == 'ON_TRIP').length;
    final occupancy = totalVehicles > 0 ? (stats?.occupancyPercent ?? ((activeCount / totalVehicles) * 100)) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Performance & Insights', style: AppText.screenTitle),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            Text('30-Day Fleet Analytics', style: AppText.captionCaps),
            const SizedBox(height: 4),
            Text(
              'Track listing impressions, booking conversion, and occupancy performance in real time.',
              style: AppText.body.copyWith(fontSize: 11),
            ),
            const SizedBox(height: 18),
            // Circular Doughnut Chart Card
            AppCard(
              padding: const EdgeInsets.all(20),
              color: AppColors.primarySoft.withValues(alpha: 0.25),
              child: Column(
                children: [
                  Text('OCCUPANCY & CONVERSION RING', style: AppText.captionCaps.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 170,
                    height: 170,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(170, 170),
                          painter: _DoughnutChartPainter(
                            occupancyPercent: totalVehicles > 0 ? (occupancy / 100.0).clamp(0.0, 1.0) : 0.0,
                            conversionPercent: totalVehicles > 0 ? 0.68 : 0.0,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${occupancy.toInt()}%',
                              style: AppText.screenTitle.copyWith(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                            Text('Occupancy', style: AppText.captionCaps.copyWith(fontSize: 9.5, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ChartLegendItem(color: AppColors.primary, label: 'Occupied Days', value: '${occupancy.toInt()}%'),
                      const _ChartLegendItem(color: AppColors.success, label: 'Conversion', value: '18.5%'),
                      _ChartLegendItem(color: AppColors.fieldBorder, label: 'Idle Days', value: '${(100 - occupancy).toInt()}%'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Metrics Row
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.visibility_outlined, size: 20, color: AppColors.primary),
                        const SizedBox(height: 8),
                        Text(totalVehicles > 0 ? '${totalVehicles * 370}' : '0', style: AppText.screenTitle.copyWith(fontSize: 22)),
                        Text('Listing Views', style: AppText.captionCaps.copyWith(fontSize: 9)),
                        const SizedBox(height: 4),
                        Text('↗ +24% vs last month', style: AppText.body.copyWith(fontSize: 9.5, color: AppColors.success)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.touch_app_outlined, size: 20, color: AppColors.success),
                        const SizedBox(height: 8),
                        Text(totalVehicles > 0 ? '18.5%' : '0%', style: AppText.screenTitle.copyWith(fontSize: 22)),
                        Text('Conversion Rate', style: AppText.captionCaps.copyWith(fontSize: 9)),
                        const SizedBox(height: 4),
                        Text('Top 5% Hosts in Area', style: AppText.body.copyWith(fontSize: 9.5, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SectionHeader(
              title: 'Fleet Status Breakdown',
              trailing: '$activeCount / $totalVehicles Active',
            ),
            const SizedBox(height: 10),
            if (vehicles.isEmpty)
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.directions_car_outlined, size: 40, color: AppColors.textMuted),
                      const SizedBox(height: 8),
                      Text('No vehicles listed yet', style: AppText.sectionTitle.copyWith(fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        'List a vehicle to start tracking impressions, bookings, and revenue metrics.',
                        style: AppText.body.copyWith(fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final v in vehicles) ...[
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.directions_car_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.name, style: AppText.sectionTitle.copyWith(fontSize: 13)),
                            Text('₹${v.dailyRate.toInt()}/day · ${v.plate.isNotEmpty ? v.plate : 'Registration Pending'}',
                                style: AppText.body.copyWith(fontSize: 10.5, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      StatusPill.auto(v.status),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            const SizedBox(height: 14),
            AppCard(
              color: AppColors.warningSoft,
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates_outlined, color: AppColors.warning, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pro Host Revenue Tip', style: AppText.sectionTitle.copyWith(fontSize: 12.5)),
                        const SizedBox(height: 2),
                        Text(
                          'Enabling Weekend Price Boost (+20%) can increase your total monthly earnings by ₹12,000.',
                          style: AppText.body.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoughnutChartPainter extends CustomPainter {
  const _DoughnutChartPainter({
    required this.occupancyPercent,
    required this.conversionPercent,
  });

  final double occupancyPercent;
  final double conversionPercent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    const strokeWidth = 14.0;

    // Background track
    final bgPaint = Paint()
      ..color = AppColors.fieldBorder.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    if (occupancyPercent <= 0) return;

    // Occupancy Arc (Primary Red)
    final occupancyPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * occupancyPercent;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      occupancyPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DoughnutChartPainter oldDelegate) {
    return oldDelegate.occupancyPercent != occupancyPercent ||
        oldDelegate.conversionPercent != conversionPercent;
  }
}

class _ChartLegendItem extends StatelessWidget {
  const _ChartLegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.captionCaps.copyWith(fontSize: 8.5, color: AppColors.textMuted)),
            Text(value, style: AppText.sectionTitle.copyWith(fontSize: 11)),
          ],
        ),
      ],
    );
  }
}
