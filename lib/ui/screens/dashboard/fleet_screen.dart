import '../../widgets/shimmer_loading.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/animation_utils.dart';
import '../../../data/models/models.dart';
import '../../../state/controllers.dart';
import '../../widgets/cards.dart';
import '../../widgets/app_image_view.dart';
import '../documents/vehicle_documents_screen.dart';
import '../onboarding/vehicle_details_screen.dart';
import '../trips/scan_handover_screen.dart';

/// Full Fleet Management Screen for AYO Host with real backend data & filtering.
class FleetScreen extends StatefulWidget {
  const FleetScreen({super.key});

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  String _filter = 'ALL'; // ALL / ACTIVE / PENDING_REVIEW / DRAFT

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardController>();
    final allVehicles = dash.vehicles;

    final filteredVehicles = switch (_filter) {
      'ACTIVE' => allVehicles.where((v) => v.status.toUpperCase() == 'ACTIVE').toList(),
      'PENDING_REVIEW' => allVehicles.where((v) => v.status.toUpperCase().contains('REVIEW') || v.status.toUpperCase().contains('PENDING')).toList(),
      'DRAFT' => allVehicles.where((v) => v.status.toUpperCase() == 'DRAFT').toList(),
      _ => allVehicles,
    };

    final activeCount = allVehicles.where((v) => v.status.toUpperCase() == 'ACTIVE').length;
    final reviewCount = allVehicles.where((v) => v.status.toUpperCase().contains('REVIEW') || v.status.toUpperCase().contains('PENDING')).length;
    final draftCount = allVehicles.where((v) => v.status.toUpperCase() == 'DRAFT').length;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Fleet', style: AppText.screenTitle),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Verify Pickup Handover QR',
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 26),
            onPressed: () => Navigator.pushNamed(context, ScanHandoverScreen.route),
          ),
          IconButton(
            tooltip: 'Add Vehicle',
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: AppColors.primary, size: 28),
            onPressed: () {
              context.read<OnboardingController>().resetVehicleDraft();
              Navigator.pushNamed(context, VehicleDetailsScreen.route);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All (${allVehicles.length})',
                  selected: _filter == 'ALL',
                  onTap: () => setState(() => _filter = 'ALL'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Active ($activeCount)',
                  selected: _filter == 'ACTIVE',
                  onTap: () => setState(() => _filter = 'ACTIVE'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'In Review ($reviewCount)',
                  selected: _filter == 'PENDING_REVIEW',
                  onTap: () => setState(() => _filter = 'PENDING_REVIEW'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Drafts ($draftCount)',
                  selected: _filter == 'DRAFT',
                  onTap: () => setState(() => _filter = 'DRAFT'),
                ),
              ],
            ),
          ),
          Expanded(
            child: dash.loading && allVehicles.isEmpty
                ? const FleetShimmer()
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => context.read<DashboardController>().load(),
                    child: filteredVehicles.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.directions_car_outlined,
                                      size: 64, color: AppColors.textMuted),
                                  const SizedBox(height: 16),
                                  Text(
                                    _filter == 'ALL'
                                        ? 'No vehicles listed yet'
                                        : 'No vehicles in $_filter',
                                    style: AppText.sectionTitle,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Start earning with your vehicle by listing it on AYO platform.',
                                    textAlign: TextAlign.center,
                                    style: AppText.body.copyWith(fontSize: 12),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      context.read<OnboardingController>().resetVehicleDraft();
                                      Navigator.pushNamed(context, VehicleDetailsScreen.route);
                                    },
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Add Vehicle'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
                            itemCount: filteredVehicles.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final v = filteredVehicles[index];
                              return FadeSlideIn(
                                delay: Duration(milliseconds: 40 * index.clamp(0, 8)),
                                child: _FleetCard(vehicle: v),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleOnPress(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class AutoSlideVehicleImageCarousel extends StatefulWidget {
  const AutoSlideVehicleImageCarousel({
    super.key,
    required this.photos,
    this.fallbackUrl,
    this.height = 185,
  });

  final List<String> photos;
  final String? fallbackUrl;
  final double height;

  @override
  State<AutoSlideVehicleImageCarousel> createState() => _AutoSlideVehicleImageCarouselState();
}

class _AutoSlideVehicleImageCarouselState extends State<AutoSlideVehicleImageCarousel> {
  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  List<String> get _displayPhotos {
    final list = <String>[];
    for (final p in widget.photos) {
      final clean = p.trim();
      if (clean.isNotEmpty && !list.contains(clean)) {
        list.add(clean);
      }
    }
    if (widget.fallbackUrl != null && widget.fallbackUrl!.trim().isNotEmpty) {
      final f = widget.fallbackUrl!.trim();
      if (!list.contains(f)) {
        list.insert(0, f);
      }
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlideTimer();
  }

  @override
  void didUpdateWidget(covariant AutoSlideVehicleImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photos.length != widget.photos.length ||
        oldWidget.fallbackUrl != widget.fallbackUrl) {
      _autoSlideTimer?.cancel();
      _startAutoSlideTimer();
    }
  }

  void _startAutoSlideTimer() {
    final photos = _displayPhotos;
    if (photos.length > 1) {
      _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (!mounted || !_pageController.hasClients) return;
        final nextPage = (_currentPage + 1) % photos.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = _displayPhotos;

    if (photos.isEmpty) {
      return Container(
        height: widget.height,
        width: double.infinity,
        color: AppColors.fieldFill,
        child: const Center(
          child: Icon(Icons.directions_car_filled_rounded, size: 48, color: AppColors.textMuted),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: photos.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return AppImageView(
                url: photos[index],
                width: double.infinity,
                height: widget.height,
                fit: BoxFit.cover,
              );
            },
          ),
          if (photos.length > 1) ...[
            // Photo count badge top right
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentPage + 1}/${photos.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Page Indicator Dots bottom center
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  photos.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == index ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? AppColors.primary : Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FleetCard extends StatelessWidget {
  const _FleetCard({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final isBike = vehicle.isBike;

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VehicleDocumentsScreen(vehicleId: vehicle.id),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full width auto-sliding vehicle image carousel
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AutoSlideVehicleImageCarousel(
              photos: vehicle.photos,
              fallbackUrl: vehicle.imageUrl,
              height: 190,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        vehicle.name,
                        style: AppText.sectionTitle.copyWith(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isBike ? '🏍️ Bike' : '🚗 Car',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E2022)),
                          ),
                        ),
                        StatusPill.auto(vehicle.status),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${vehicle.year} · ${vehicle.bodyType} · ${vehicle.transmission}',
                  style: AppText.body.copyWith(
                      fontSize: 11, color: AppColors.textMuted),
                ),
                if (vehicle.plate.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    vehicle.plate,
                    style: AppText.captionCaps
                        .copyWith(fontSize: 9.5, color: AppColors.primary),
                  ),
                ],
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      vehicle.displayPrice,
                      style: AppText.screenTitle.copyWith(fontSize: 15, color: AppColors.primary),
                    ),
                    Row(
                      children: [
                        Text(
                          vehicle.status == 'ACTIVE'
                              ? '🟢 Live on Catalog'
                              : vehicle.status == 'PENDING_REVIEW'
                                  ? '⏳ Under Admin Review'
                                  : '📝 Tap to View Documents',
                          style: AppText.body.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: vehicle.status == 'ACTIVE'
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
