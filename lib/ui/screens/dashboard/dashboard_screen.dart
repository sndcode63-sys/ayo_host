import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../state/controllers.dart';
import '../../widgets/cards.dart';
import '../onboarding/vehicle_details_screen.dart';

/// AYO Host Dashboard — revenue, fleet stats, next handover, My Cars.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static final _money = NumberFormat.currency(symbol: '\$');

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardController>();

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
          onPressed: () =>
              Navigator.pushNamed(context, VehicleDetailsScreen.route),
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
        body: dash.loading && dash.stats == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => context.read<DashboardController>().load(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
                  children: [
                    const _TopBar(),
                    const SizedBox(height: 18),
                    _Greeting(stats: dash.stats),
                    const SizedBox(height: 18),
                    _RevenueCard(stats: dash.stats, money: _money),
                    const SizedBox(height: 12),
                    _StatsRow(stats: dash.stats),
                    const SizedBox(height: 20),
                    if (dash.stats?.nextHandover != null) ...[
                      SectionHeader(
                        title: 'Next Handover',
                        trailing: dash.stats!.nextHandover!.countdown,
                      ),
                      const SizedBox(height: 10),
                      _HandoverCard(handover: dash.stats!.nextHandover!),
                      const SizedBox(height: 20),
                    ],
                    SectionHeader(
                      title: 'My Cars',
                      trailing: '${dash.vehicles.length} Vehicles',
                      trailingColor: AppColors.textMuted,
                    ),
                    const SizedBox(height: 10),
                    for (final v in dash.vehicles) ...[
                      _CarTile(vehicle: v),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'AYO',
          style: AppText.sectionTitle.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.fieldFill,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Text('HOST',
                  style: AppText.captionCaps
                      .copyWith(color: AppColors.textSecondary)),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 14, color: AppColors.textMuted),
            ],
          ),
        ),
        const Spacer(),
        Stack(
          children: [
            const Icon(Icons.notifications_outlined,
                size: 24, color: AppColors.textPrimary),
            Positioned(
              right: 1,
              top: 1,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({this.stats});

  final DashboardStats? stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${stats?.greeting ?? 'Hello,'}\n${stats?.hostName ?? ''}',
                style: AppText.screenTitle.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 4),
              Text('October 2026 Fleet Overview',
                  style: AppText.body
                      .copyWith(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text('Live\nHost',
                  textAlign: TextAlign.center,
                  style: AppText.captionCaps.copyWith(
                      color: AppColors.primary, height: 1.1, fontSize: 9)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.stats, required this.money});

  final DashboardStats? stats;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL REVENUE', style: AppText.captionCaps),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '↗ +${stats?.revenueChangePercent.toStringAsFixed(1) ?? '0'}%',
                  style: AppText.captionCaps
                      .copyWith(color: AppColors.success),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  money.format(stats?.totalRevenue ?? 0),
                  style: AppText.screenTitle.copyWith(fontSize: 30),
                ),
              ),
              Text('This Month',
                  style: AppText.captionCaps
                      .copyWith(color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '+\$${(stats?.pendingPayout ?? 0).toStringAsFixed(0)} pending payout ${stats?.payoutDate ?? ''}',
            style:
                AppText.body.copyWith(fontSize: 11, color: AppColors.success),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final DashboardStats? stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ACTIVE RIDES', style: AppText.captionCaps),
                    const Icon(Icons.directions_car_filled_rounded,
                        size: 15, color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${stats?.activeRides ?? 0} /${stats?.totalVehicles ?? 0}',
                  style: AppText.screenTitle.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 2),
                Text('2 handovers today',
                    style: AppText.body.copyWith(fontSize: 10)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('OCCUPANCY', style: AppText.captionCaps),
                    const Icon(Icons.timelapse_rounded,
                        size: 15, color: AppColors.textMuted),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${stats?.occupancyPercent.toStringAsFixed(0) ?? '0'}%',
                  style: AppText.screenTitle.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 2),
                Text('Top 5% Bay Area',
                    style: AppText.body.copyWith(fontSize: 10)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HandoverCard extends StatelessWidget {
  const _HandoverCard({required this.handover});

  final Handover handover;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.directions_car_rounded,
                    size: 26, color: AppColors.textMuted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(handover.vehicleName,
                        style: AppText.sectionTitle
                            .copyWith(fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text(
                      'Guest: ${handover.guestName} · ${handover.timeLabel}',
                      style: AppText.body.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              StatusPill(label: handover.location, kind: StatusKind.danger),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.play_arrow_rounded,
                        size: 16, color: Colors.white),
                    label: Text('Start Handover',
                        style: AppText.button.copyWith(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_bubble_outline_rounded,
                        size: 14, color: AppColors.textSecondary),
                    label: Text('Contact Guest',
                        style: AppText.body.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.cardBorder),
                      backgroundColor: AppColors.fieldFill,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CarTile extends StatelessWidget {
  const _CarTile({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Container(
              width: 58,
              height: 46,
              color: AppColors.fieldFill,
              child: vehicle.imageUrl != null && vehicle.imageUrl!.isNotEmpty
                  ? Image.network(
                      vehicle.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.directions_car_rounded,
                        size: 24,
                        color: AppColors.textMuted,
                      ),
                    )
                  : const Icon(
                      Icons.directions_car_rounded,
                      size: 24,
                      color: AppColors.textMuted,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vehicle.name,
                    style: AppText.sectionTitle.copyWith(fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  '₹${vehicle.dailyRate.toInt()}/day · ${vehicle.plate.isNotEmpty ? vehicle.plate : 'Reg Pending'}',
                  style: AppText.body.copyWith(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          StatusPill.auto(vehicle.status),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
