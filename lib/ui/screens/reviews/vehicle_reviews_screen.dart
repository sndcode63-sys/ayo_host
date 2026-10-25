import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../data/services/host_service.dart';
import '../../widgets/cards.dart';

/// Guest reviews for one vehicle — `GET /vehicles/:id/reviews`.
class VehicleReviewsScreen extends StatefulWidget {
  const VehicleReviewsScreen({super.key, required this.vehicleId, required this.vehicleName});

  final String vehicleId;
  final String vehicleName;

  @override
  State<VehicleReviewsScreen> createState() => _VehicleReviewsScreenState();
}

class _VehicleReviewsScreenState extends State<VehicleReviewsScreen> {
  late Future<VehicleReviewsPage> _future;

  @override
  void initState() {
    super.initState();
    _future = HostService.getVehicleReviews(widget.vehicleId);
  }

  void _reload() => setState(() => _future = HostService.getVehicleReviews(widget.vehicleId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reviews · ${widget.vehicleName}', style: AppText.screenTitle.copyWith(fontSize: 16))),
      body: FutureBuilder<VehicleReviewsPage>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load reviews'),
                  TextButton(onPressed: _reload, child: const Text('Retry')),
                ],
              ),
            );
          }
          final page = snap.data!;
          if (page.items.isEmpty) {
            return const Center(child: Text('No reviews yet'));
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: page.items.length + 1,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return AppCard(
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
                        const SizedBox(width: 8),
                        Text(page.ratingAvg.toStringAsFixed(1), style: AppText.screenTitle),
                        const SizedBox(width: 8),
                        Text('(${page.total} reviews)', style: AppText.body),
                      ],
                    ),
                  );
                }
                final r = page.items[i - 1];
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(r.reviewerName, style: AppText.sectionTitle.copyWith(fontSize: 13))),
                          ...List.generate(
                            5,
                            (s) => Icon(s < r.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                size: 16, color: Colors.amber),
                          ),
                        ],
                      ),
                      if (r.comment.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(r.comment, style: AppText.body.copyWith(fontSize: 12.5)),
                      ],
                      if (r.createdAt != null) ...[
                        const SizedBox(height: 6),
                        Text(DateFormat('MMM dd, yyyy').format(r.createdAt!.toLocal()),
                            style: AppText.body.copyWith(fontSize: 10.5, color: AppColors.textMuted)),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
