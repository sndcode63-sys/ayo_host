import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/host_service.dart';

/// Shows the current admin-set listing fee (`GET /vehicles/listing-fee`).
/// Hidden if the fee can't be loaded, so it never blocks onboarding.
class ListingFeeBanner extends StatefulWidget {
  const ListingFeeBanner({super.key});

  @override
  State<ListingFeeBanner> createState() => _ListingFeeBannerState();
}

class _ListingFeeBannerState extends State<ListingFeeBanner> {
  late final Future<ListingFeeConfig> _future = HostService.getListingFee();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ListingFeeConfig>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) return const SizedBox.shrink();
        final fee = snap.data;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.inkBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'One-time listing fee',
                      style: AppText.body.copyWith(
                          fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fee == null
                          ? 'Checking current fee…'
                          : (fee.bypass
                              ? 'No fee right now. Your listing goes straight to review.'
                              : 'Paid when you submit this vehicle for review.'),
                      style: AppText.body.copyWith(
                          fontSize: 12, color: Colors.white.withValues(alpha: 0.62)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (fee == null)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                )
              else
                Text(
                  fee.display,
                  style: AppText.screenTitle.copyWith(fontSize: 22, color: Colors.white),
                ),
            ],
          ),
        );
      },
    );
  }
}
