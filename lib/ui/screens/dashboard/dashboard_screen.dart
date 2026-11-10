import '../../widgets/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/services/toast_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/animation_utils.dart';
import '../../../data/models/models.dart';
import '../../../state/controllers.dart';
import '../../widgets/cards.dart';
import '../../widgets/inputs.dart';
import '../earnings/earnings_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../widgets/app_image_view.dart';
import '../account/account_details_screen.dart';
import 'fleet_screen.dart';
import '../documents/vehicle_documents_screen.dart';
import '../onboarding/host_profile_setup_screen.dart';
import '../onboarding/payout_setup_screen.dart';
import '../onboarding/vehicle_details_screen.dart';

/// AYO Host Dashboard — revenue, fleet stats, next handover, My Cars, current geolocation.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static final _money = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

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
                      child: AppImageView(
                        url: vehicle.imageUrl,
                        width: 80,
                        height: 60,
                        fit: BoxFit.cover,
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
              _DetailRow(label: 'Hourly Rate', value: vehicle.hourlyRate > 0 ? '₹${vehicle.hourlyRate.toInt()} / hr' : 'Not Enabled'),
              _DetailRow(label: 'Est. Monthly', value: vehicle.dailyRate > 0 ? '₹${(vehicle.dailyRate * 22).toInt()} / mo (est.)' : '₹0 / mo'),
              _DetailRow(label: 'Pickup Address', value: (vehicle.address?.isNotEmpty == true) ? vehicle.address! : 'Location not specified'),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: ScaleOnPress(
          onTap: () {
            context.read<OnboardingController>().resetVehicleDraft();
            Navigator.pushNamed(context, VehicleDetailsScreen.route);
          },
          child: FloatingActionButton(
            onPressed: () {
              context.read<OnboardingController>().resetVehicleDraft();
              Navigator.pushNamed(context, VehicleDetailsScreen.route);
            },
            backgroundColor: const Color(0xFFFE001A),
            shape: const CircleBorder(),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
      body: dash.loading && dash.stats == null
          ? const DashboardShimmer()
          : RefreshIndicator(
              color: const Color(0xFFFE001A),
              onRefresh: () => context.read<DashboardController>().load(),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Top Red Header Container (Image 3 design — No car image overlay as requested)
                  _RedHeaderContainer(dash: dash),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 90),
                      child: _OnboardingStatusBanner(status: dash.onboardingStatus),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 140),
                      child: _RevenueCard(stats: dash.stats, money: _money),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 190),
                      child: _StatsRow(stats: dash.stats),
                    ),
                    const SizedBox(height: 18),
                    if (dash.activeTrips.isNotEmpty) ...[
                      SectionHeader(
                        title: 'Active Trips',
                        trailing: '${dash.activeTrips.length} Live',
                      ),
                      const SizedBox(height: 10),
                      for (final t in dash.activeTrips) ...[
                        _TripActionCard(trip: t, isActive: true),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 10),
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
                ],
              ),
            ),
    );
  }
}

/// Official Red Header Container matching Image 3 (Strictly NO car image overlay as requested)
/// Fully dynamic: Interactive Date & Time pickers, Dynamic GPS/Profile Location, Dynamic Avatar, Dynamic Name
class _RedHeaderContainer extends StatefulWidget {
  const _RedHeaderContainer({required this.dash});

  final DashboardController dash;

  @override
  State<_RedHeaderContainer> createState() => _RedHeaderContainerState();
}

class _RedHeaderContainerState extends State<_RedHeaderContainer> {
  String? _selectedCity;
  bool _isLocating = false;

  Future<void> _detectGpsLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        ToastService.showWarning('Location permission is needed to detect current city');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality?.isNotEmpty == true
            ? place.locality!
            : (place.subAdministrativeArea?.isNotEmpty == true
                ? place.subAdministrativeArea!
                : (place.administrativeArea ?? 'Location'));

        if (mounted) {
          setState(() {
            _selectedCity = city;
          });
          ToastService.showSuccess('Location detected: $city');
        }
      }
    } catch (e) {
      ToastService.showInfo('Could not detect live GPS city. Showing profile city.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _showLocationPicker(String currentCity) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Select Host Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.my_location_rounded, color: Color(0xFFFE001A)),
                title: const Text('Use Current GPS Location'),
                subtitle: const Text('Detect automatically from device sensor'),
                onTap: () {
                  Navigator.pop(ctx);
                  _detectGpsLocation();
                },
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('Popular Cities', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Delhi NCR',
                  'Mumbai',
                  'Bengaluru',
                  'Hyderabad',
                  'Kolkata',
                  'Pune',
                  'Patna',
                  'Chennai',
                ].map((c) {
                  final isSelected = c.toLowerCase() == currentCity.toLowerCase();
                  return ChoiceChip(
                    label: Text(c),
                    selected: isSelected,
                    selectedColor: const Color(0xFFFE001A),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF1E2022),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedCity = c);
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.edit_location_alt_rounded, color: Color(0xFF1E2022)),
                title: const Text('Edit in Host Profile'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final dashCtrl = context.read<DashboardController>();
                  Navigator.pop(ctx);
                  await Navigator.pushNamed(context, AccountDetailsScreen.route);
                  if (mounted) dashCtrl.load();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final hostProfile = widget.dash.hostProfile;

    // 1. Dynamic Location: selectedCity ?? profile city ?? auth host city ?? 'Select Location'
    final locationText = _selectedCity ??
        (hostProfile?.city.isNotEmpty == true
            ? hostProfile!.city
            : (auth.host?.city.isNotEmpty == true
                ? auth.host!.city
                : 'Select Location'));

    // 2. Dynamic Host Name:
    final firstName = hostProfile?.firstName.trim();
    final authName = auth.user?.name?.trim();
    final statsName = widget.dash.stats?.hostName.trim();
    final hostName = (firstName != null && firstName.isNotEmpty)
        ? firstName
        : (authName != null && authName.isNotEmpty)
            ? authName.split(' ').first
            : (statsName != null && statsName.isNotEmpty)
                ? statsName.split(' ').first
                : 'Host';

    // 3. Dynamic Avatar:
    final avatarUrl = hostProfile?.avatarUrl ?? hostProfile?.photoUrl ?? auth.host?.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    String initials = 'H';
    if (hostProfile?.initials.isNotEmpty == true) {
      initials = hostProfile!.initials;
    } else if (hostName.isNotEmpty) {
      initials = hostName[0].toUpperCase();
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFE001A),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33FE001A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar: Location on left, Notification & Profile on right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Location Dropdown
                  InkWell(
                    onTap: () => _showLocationPicker(locationText),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _isLocating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            locationText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),

                  // Notification Bell & Profile Avatar
                  Row(
                    children: [
                      // Notification Bell in white circle
                      Builder(
                        builder: (ctx) {
                          final unread = ctx.watch<NotificationController>().unread;
                          return InkWell(
                            onTap: () => Navigator.pushNamed(ctx, NotificationsScreen.route),
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(
                                    Icons.notifications_none_rounded,
                                    size: 22,
                                    color: Color(0xFF1E2022),
                                  ),
                                  if (unread > 0)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFE001A),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),

                      // Profile Avatar
                      InkWell(
                        onTap: () async {
                          final dashCtrl = context.read<DashboardController>();
                          await Navigator.pushNamed(context, AccountDetailsScreen.route);
                          if (mounted) {
                            dashCtrl.load();
                          }
                        },
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white,
                            backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                            child: hasAvatar
                                ? null
                                : Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Color(0xFFFE001A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Greeting (Strictly NO car image overlay as requested)
              Text(
                'Hello, $hostName 👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ready to host today? Manage your fleet & earnings',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
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
          : 'Your host KYC verification is in progress. Our team will verify your details within 24 hours.';
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
                  Text('Your host account is active. List vehicles to start earning on AYO.', style: AppText.body.copyWith(fontSize: 10, color: AppColors.textSecondary)),
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
    final change = stats?.revenueChangePercent ?? 0;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, EarningsScreen.route),
      child: Container(
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
              Text(
                'Total host revenue',
                style: AppText.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2FD071).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up_rounded,
                        size: 14, color: Color(0xFF2FD071)),
                    const SizedBox(width: 4),
                    Text(
                      '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                      style: AppText.captionCaps.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2FD071),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            money.format(stats?.totalRevenue ?? 0),
            style: AppText.screenTitle.copyWith(
              fontSize: 38,
              letterSpacing: -1.2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This month',
            style: AppText.captionCaps
                .copyWith(color: Colors.white.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    size: 18, color: Colors.white70),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '₹${(stats?.pendingPayout ?? 0).toInt()} pending payout ${stats?.payoutDate ?? ''}',
                    style: AppText.body.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.white54),
              ],
            ),
          ),
        ],
      ),
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
                    Text('Active fleet', style: AppText.captionCaps),
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
                    Text('Occupancy', style: AppText.captionCaps),
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

class _CarTile extends StatelessWidget {
  const _CarTile({required this.vehicle, required this.onTap});

  final Vehicle vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AutoSlideVehicleImageCarousel(
              photos: vehicle.photos,
              fallbackUrl: vehicle.imageUrl,
              height: 175,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vehicle.name,
                          style: AppText.sectionTitle.copyWith(fontSize: 14)),
                      const SizedBox(height: 3),
                      Text(
                        '${vehicle.displayPrice} · ${vehicle.plate.isNotEmpty ? vehicle.plate : 'Reg Pending'}',
                        style: AppText.body.copyWith(fontSize: 11, color: AppColors.textSecondary),
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
          ),
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


/// Active trip -> "End Trip"; upcoming trip -> "Cancel Trip".
class _TripActionCard extends StatelessWidget {
  const _TripActionCard({required this.trip, required this.isActive});

  final Trip trip;
  final bool isActive;

  Future<void> _confirmEnd(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End this trip?'),
        content: const Text('Confirm the car is returned. The guest\'s security deposit refund will be triggered.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not yet')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('End Trip')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<DashboardController>().endTrip(trip.id);
    }
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final reasonController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this trip?'),
        content: AppTextField(
          label: 'Reason',
          hint: 'Why are you cancelling?',
          controller: reasonController,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep trip')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel Trip')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final reason = reasonController.text.trim();
      await context.read<DashboardController>().cancelTrip(trip.id, reason.isEmpty ? 'Cancelled by host' : reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM dd, hh:mm a');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(trip.vehicle, style: AppText.sectionTitle.copyWith(fontSize: 13.5)),
          const SizedBox(height: 2),
          Text('Guest: ${trip.customer.name}', style: AppText.body.copyWith(fontSize: 11.5)),
          Text('${fmt.format(trip.startTime.toLocal())} → ${fmt.format(trip.endTime.toLocal())}',
              style: AppText.body.copyWith(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: isActive
                ? ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: () => _confirmEnd(context),
                    icon: const Icon(Icons.flag_rounded, size: 16, color: Colors.white),
                    label: const Text('End Trip / Car Returned', style: TextStyle(color: Colors.white)),
                  )
                : OutlinedButton.icon(
                    onPressed: () => _confirmCancel(context),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Cancel Trip'),
                  ),
          ),
        ],
      ),
    );
  }
}
