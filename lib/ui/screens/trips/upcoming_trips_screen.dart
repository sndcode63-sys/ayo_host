import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../data/services/trips_service.dart';
import '../../../state/controllers.dart';
import '../notifications/notifications_screen.dart';
import 'scan_handover_screen.dart';

/// Full Upcoming Trips Screen matching AYO Host Reference UI.
/// Supports tabs for Upcoming and Completed trips, with direct "Scan Customer QR" action.
class UpcomingTripsScreen extends StatefulWidget {
  const UpcomingTripsScreen({super.key});

  static const route = '/upcoming-trips';

  @override
  State<UpcomingTripsScreen> createState() => _UpcomingTripsScreenState();
}

class _UpcomingTripsScreenState extends State<UpcomingTripsScreen> {
  int _selectedTab = 0; // 0: Upcoming, 1: Completed
  bool _isLoading = false;
  List<Trip> _completedTrips = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTrips();
    });
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);
    try {
      await context.read<DashboardController>().load();
      final completed = await TripsService.getCompletedTrips();
      if (mounted) {
        setState(() {
          _completedTrips = completed;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardController>();
    final upcomingTrips = dash.upcomingTrips;
    final activeTrips = dash.activeTrips;

    // Combine active & upcoming for tab 0
    final liveAndUpcoming = [...activeTrips, ...upcomingTrips];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF15131A)),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        centerTitle: true,
        title: Text(
          'AYO',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF15131A), size: 24),
            onPressed: () => Navigator.pushNamed(context, NotificationsScreen.route),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadTrips,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Screen Title
            const Text(
              'Upcoming Trips',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF15131A),
              ),
            ),
            const SizedBox(height: 14),

            // Tab Selector: Upcoming (N) | Completed
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEBEDF0),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      label: 'Upcoming (${liveAndUpcoming.length})',
                      isSelected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      label: 'Completed (${_completedTrips.length})',
                      isSelected: _selectedTab == 1,
                      onTap: () => setState(() => _selectedTab = 1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Trips List
            if (_isLoading) ...[
              const SizedBox(height: 60),
              const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ] else if (_selectedTab == 0) ...[
              if (liveAndUpcoming.isEmpty)
                _buildEmptyState('No upcoming trips scheduled at the moment.')
              else
                ...liveAndUpcoming.map((trip) {
                  final isActive = trip.status.toUpperCase() == 'ACTIVE' || trip.status.toUpperCase() == 'ON_TRIP';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _TripCard(
                      trip: trip,
                      isActive: isActive,
                      onScanTap: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScanHandoverScreen(targetTrip: trip),
                          ),
                        );
                        if (result == true) {
                          _loadTrips();
                        }
                      },
                    ),
                  );
                }),
            ] else ...[
              if (_completedTrips.isEmpty)
                _buildEmptyState('No completed trips found yet.')
              else
                ..._completedTrips.map((trip) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _TripCard(
                      trip: trip,
                      isActive: false,
                      isCompleted: true,
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 14),
          const Text(
            'All Caught Up!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF15131A)),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F52BA) : Colors.transparent, // Deep blue
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF5F6368),
          ),
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    this.isActive = false,
    this.isCompleted = false,
    this.onScanTap,
  });

  final Trip trip;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback? onScanTap;

  @override
  Widget build(BuildContext context) {
    final vehicleTitle = trip.vehicle.isNotEmpty ? trip.vehicle : 'Vehicle Listed';
    final customerName = trip.customer.name.isNotEmpty ? trip.customer.name : 'Customer';
    final customerPhone = trip.customer.phone.isNotEmpty ? trip.customer.phone : '+91 Verified Guest';
    final timeFormatted = DateFormat('hh:mm a • Today').format(trip.startTime);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle Info Row with Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle Icon or Photo
              Container(
                width: 60,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.directions_car_rounded, color: Color(0xFF4B5563), size: 30),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicleTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15131A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFDCFCE7)
                      : isCompleted
                          ? const Color(0xFFF3F4F6)
                          : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive
                      ? 'Active Trip'
                      : isCompleted
                          ? 'Completed'
                          : 'Pickup Ready',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? const Color(0xFF15803D)
                        : isCompleted
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF0369A1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF0F1F3)),
          const SizedBox(height: 14),

          // Details List with Icons
          _DetailRow(icon: Icons.person_outline_rounded, text: customerName),
          const SizedBox(height: 8),
          _DetailRow(icon: Icons.phone_outlined, text: customerPhone),
          const SizedBox(height: 8),
          _DetailRow(icon: Icons.location_on_outlined, text: 'Pickup: Host Location / City Hub'),
          const SizedBox(height: 8),
          _DetailRow(
            icon: Icons.access_time_rounded,
            text: isActive ? 'Started at: $timeFormatted' : 'Time: $timeFormatted',
          ),
          const SizedBox(height: 16),

          // Action Button
          if (isActive)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0F52BA)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  _showTripDetailsSheet(context, trip);
                },
                icon: const Icon(Icons.location_searching_rounded, size: 18, color: Color(0xFF0F52BA)),
                label: const Text(
                  'View Trip Details',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F52BA)),
                ),
              ),
            )
          else if (!isCompleted)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F52BA), // Deep blue matching mockup
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onScanTap,
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 19, color: Colors.white),
                label: const Text(
                  'Scan Customer QR',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showTripDetailsSheet(BuildContext context, Trip trip) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_car_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(trip.vehicle.isNotEmpty ? trip.vehicle : 'Trip Details',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Trip ID: ${trip.id}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            const SizedBox(height: 6),
            Text('Renter: ${trip.customer.name} (${trip.customer.phone})',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Start: ${DateFormat('yyyy-MM-dd HH:mm').format(trip.startTime)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            Text('End: ${DateFormat('yyyy-MM-dd HH:mm').format(trip.endTime)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF374151), fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
