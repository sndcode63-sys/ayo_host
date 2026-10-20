import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../state/controllers.dart';
import '../../widgets/cards.dart';
import '../account/account_details_screen.dart';
import '../documents/vehicle_documents_screen.dart';
import '../onboarding/host_profile_setup_screen.dart';
import '../onboarding/payout_setup_screen.dart';
import '../onboarding/vehicle_details_screen.dart';

/// AYO Host Dashboard — revenue, fleet stats, next handover, My Cars, current geolocation.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static final _money = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  void _showHandoverDialog(BuildContext context, Handover handover) {
    final tokenController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Scan / Enter Guest QR Token', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Guest: ${handover.guestName}', style: AppText.sectionTitle.copyWith(fontSize: 13)),
            Text('Vehicle: ${handover.vehicleName}', style: AppText.body.copyWith(fontSize: 11)),
            const SizedBox(height: 14),
            TextField(
              controller: tokenController,
              decoration: const InputDecoration(
                labelText: 'Enter Customer QR Handover Token',
                hintText: 'Paste or type token string...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final token = tokenController.text.trim();
              if (token.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter or scan the QR token')),
                );
                return;
              }
              Navigator.pop(ctx);
              await context.read<DashboardController>().startTripHandover(
                    tripId: handover.tripId,
                    token: token,
                    hostLat: 12.9716,
                    hostLng: 77.5946,
                  );
            },
            child: const Text('Start Handover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showVehicleDetailsSheet(BuildContext context, Vehicle vehicle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 80,
                      height: 60,
                      color: AppColors.fieldFill,
                      child: vehicle.imageUrl != null && vehicle.imageUrl!.isNotEmpty
                          ? Image.network(
                              vehicle.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.directions_car_rounded,
                                size: 32,
                                color: AppColors.textMuted,
                              ),
                            )
                          : const Icon(
                              Icons.directions_car_rounded,
                              size: 32,
                              color: AppColors.textMuted,
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vehicle.name, style: AppText.screenTitle.copyWith(fontSize: 18)),
                        const SizedBox(height: 3),
                        Text(
                          '${vehicle.year} · ${vehicle.bodyType} · ${vehicle.transmission}',
                          style: AppText.body.copyWith(fontSize: 11, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          vehicle.plate.isNotEmpty ? vehicle.plate : 'Reg Pending',
                          style: AppText.captionCaps.copyWith(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  StatusPill.auto(vehicle.status),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _DetailRow(label: 'Daily Rate', value: '₹${vehicle.dailyRate.toInt()} / day'),
              _DetailRow(label: 'Est. Monthly', value: '₹${(vehicle.dailyRate * 22).toInt()} / month'),
              _DetailRow(label: 'Pickup Address', value: vehicle.address ?? 'Indiranagar, Bengaluru'),
              _DetailRow(label: 'Listing Status', value: vehicle.status),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VehicleDocumentsScreen(vehicleId: vehicle.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.description_outlined, size: 16),
                      label: const Text('Documents & Review'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardController>();

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 70),
          child: FloatingActionButton(
            onPressed: () =>
                Navigator.pushNamed(context, VehicleDetailsScreen.route),
            backgroundColor: AppColors.primary,
            shape: const CircleBorder(),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
        body: dash.loading && dash.stats == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => context.read<DashboardController>().load(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
                  children: [
                    _TopBar(hostProfile: dash.hostProfile),
                    const SizedBox(height: 18),
                    _Greeting(stats: dash.stats),
                    const SizedBox(height: 12),
                    _OnboardingStatusBanner(status: dash.onboardingStatus),
                    const SizedBox(height: 16),
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
                      _HandoverCard(
                        handover: dash.stats!.nextHandover!,
                        onStartHandover: () => _showHandoverDialog(
                          context,
                          dash.stats!.nextHandover!,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    SectionHeader(
                      title: 'My Cars',
                      trailing: '${dash.vehicles.length} Vehicles',
                      trailingColor: AppColors.textMuted,
                    ),
                    const SizedBox(height: 10),
                    if (dash.vehicles.isEmpty)
                      AppCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Icon(Icons.directions_car_outlined, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 10),
                            Text('No vehicles listed yet', style: AppText.sectionTitle),
                            const SizedBox(height: 4),
                            Text('Tap + button to list your vehicle on Ayo', style: AppText.body.copyWith(fontSize: 11)),
                          ],
                        ),
                      )
                    else
                      for (final v in dash.vehicles) ...[
                        _CarTile(
                          vehicle: v,
                          onTap: () => _showVehicleDetailsSheet(context, v),
                        ),
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
  const _TopBar({this.hostProfile});

  final HostProfile? hostProfile;

  @override
  Widget build(BuildContext context) {
    final locationText = hostProfile?.city.isNotEmpty == true
        ? hostProfile!.city
        : 'Indiranagar, Bengaluru (Live Location)';

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.fieldFill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('HOST',
                      style: AppText.captionCaps
                          .copyWith(color: AppColors.textSecondary, fontSize: 8.5)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.my_location_rounded, size: 11, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  locationText,
                  style: AppText.captionCaps.copyWith(
                    fontSize: 8.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            Builder(
              builder: (context) {
                final avatarUrl = hostProfile?.avatarUrl;
                final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AccountDetailsScreen.route),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primarySoft,
                    backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                    child: hasAvatar
                        ? null
                        : Text(
                            hostProfile?.initials.isNotEmpty == true ? hostProfile!.initials : 'H',
                            style: AppText.captionCaps.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
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
              Text('Fleet & Revenue Overview',
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

class _OnboardingStatusBanner extends StatelessWidget {
  const _OnboardingStatusBanner({this.status});

  final OnboardingStatus? status;

  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();

    final isProfilePending = !status!.profileCompleted && status!.profile == null;
    final isPayoutPending = status!.profileCompleted && !status!.payoutCompleted && status!.kycStatus == 'NOT_STARTED';
    final isKycReviewing = status!.kycStatus == 'PENDING';
    final isVerified = status!.kycStatus == 'VERIFIED' || status!.onboardingCompleted;

    if (isProfilePending) {
      return AppCard(
        color: AppColors.warningSoft,
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.warning,
              radius: 18,
              child: Icon(Icons.person_outline_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Step 1 Remaining: Profile Setup', style: AppText.sectionTitle.copyWith(fontSize: 13, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('Set up name, DOB, and profile photo to start', style: AppText.body.copyWith(fontSize: 10.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => Navigator.pushNamed(context, HostProfileSetupScreen.route),
              child: const Text('Complete', style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ],
        ),
      );
    }

    if (isPayoutPending) {
      return AppCard(
        color: AppColors.warningSoft,
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.warning,
              radius: 18,
              child: Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Step 2 Remaining: Payout Setup', style: AppText.sectionTitle.copyWith(fontSize: 13, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('Link UPI or Bank Account for automatic payouts', style: AppText.body.copyWith(fontSize: 10.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => Navigator.pushNamed(context, PayoutSetupScreen.route),
              child: const Text('Configure', style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ],
        ),
      );
    }

    if (isKycReviewing) {
      final msg = status!.message.isNotEmpty
          ? status!.message
          : 'Aapka verification 24 hour me kiya jayega. Hamari team aapke details verify kar rahi hai.';
      return AppCard(
        color: AppColors.primarySoft,
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 18,
              child: Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('KYC Verification Pending', style: AppText.sectionTitle.copyWith(fontSize: 13, color: AppColors.primary)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('24h SLA', style: AppText.captionCaps.copyWith(color: Colors.white, fontSize: 8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(msg, style: AppText.body.copyWith(fontSize: 10.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (isVerified) {
      return AppCard(
        color: AppColors.successSoft,
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.success,
              radius: 16,
              child: Icon(Icons.check_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Host Account Verified 🟢', style: AppText.sectionTitle.copyWith(fontSize: 13, color: AppColors.success)),
                  Text('Aapka Host account active hai. Vehicles list karke earning start karein.', style: AppText.body.copyWith(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
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
              Text('TOTAL HOST REVENUE', style: AppText.captionCaps),
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
            '+₹${(stats?.pendingPayout ?? 0).toInt()} pending payout ${stats?.payoutDate ?? ''}',
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
                    Text('ACTIVE FLEET', style: AppText.captionCaps),
                    const Icon(Icons.directions_car_filled_rounded,
                        size: 15, color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${stats?.activeRides ?? 0} / ${stats?.totalVehicles ?? 0}',
                  style: AppText.screenTitle.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 2),
                Text('Active vehicles live',
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
                Text('Top host rating',
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
  const _HandoverCard({required this.handover, required this.onStartHandover});

  final Handover handover;
  final VoidCallback onStartHandover;

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
                    onPressed: onStartHandover,
                    icon: const Icon(Icons.qr_code_scanner_rounded,
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
            ],
          ),
        ],
      ),
    );
  }
}

class _CarTile extends StatelessWidget {
  const _CarTile({required this.vehicle, required this.onTap});

  final Vehicle vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.body.copyWith(fontSize: 11, color: AppColors.textMuted)),
          Flexible(
            child: Text(
              value,
              style: AppText.body.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
