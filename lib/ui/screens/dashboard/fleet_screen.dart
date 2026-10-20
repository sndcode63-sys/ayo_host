import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../state/controllers.dart';
import '../../widgets/cards.dart';
import '../documents/vehicle_documents_screen.dart';
import '../onboarding/vehicle_details_screen.dart';

/// Full Fleet Management Screen for AYO Host with real backend data.
class FleetScreen extends StatelessWidget {
  const FleetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardController>();
    final vehicles = dash.vehicles;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Fleet', style: AppText.screenTitle),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: AppColors.primary, size: 28),
            onPressed: () =>
                Navigator.pushNamed(context, VehicleDetailsScreen.route),
          ),
        ],
      ),
      body: dash.loading && vehicles.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => context.read<DashboardController>().load(),
              child: vehicles.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.directions_car_outlined,
                                size: 64, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            Text('No vehicles listed yet',
                                style: AppText.sectionTitle),
                            const SizedBox(height: 8),
                            Text(
                              'Start earning with your vehicle by listing it on AYO platform.',
                              textAlign: TextAlign.center,
                              style: AppText.body.copyWith(fontSize: 12),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                  context, VehicleDetailsScreen.route),
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
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
                      itemCount: vehicles.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final v = vehicles[index];
                        return _FleetCard(vehicle: v);
                      },
                    ),
            ),
    );
  }
}

class _FleetCard extends StatelessWidget {
  const _FleetCard({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
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
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 80,
                  height: 60,
                  color: AppColors.fieldFill,
                  child: vehicle.imageUrl != null &&
                          vehicle.imageUrl!.isNotEmpty
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
                    Text(vehicle.name, style: AppText.sectionTitle),
                    const SizedBox(height: 4),
                    Text(
                      '${vehicle.year} · ${vehicle.bodyType} · ${vehicle.transmission}',
                      style: AppText.body.copyWith(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicle.plate.isNotEmpty
                          ? vehicle.plate
                          : 'Plate Verification Pending',
                      style: AppText.captionCaps
                          .copyWith(fontSize: 9, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              StatusPill.auto(vehicle.status),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${vehicle.dailyRate.toInt()} / day',
                style: AppText.screenTitle.copyWith(fontSize: 16),
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
    );
  }
}
