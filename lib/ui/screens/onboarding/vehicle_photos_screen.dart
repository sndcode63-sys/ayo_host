import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/controllers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/chrome.dart';
import '../../widgets/inputs.dart';
import 'payout_setup_screen.dart';

/// AYO Host Vehicle Listing & Details (Step 2 of 2: Photos, Specs, Location).
class VehiclePhotosScreen extends StatelessWidget {
  const VehiclePhotosScreen({super.key});

  static const route = '/onboarding/vehicle/photos';

  @override
  Widget build(BuildContext context) {
    final ob = context.watch<OnboardingController>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            const StepHeader(
              step: 2,
              totalSteps: 2,
              title: 'Vehicle Listing',
              subtitle: 'Step 2 of 2 · Details & Pricing',
              rightTag: 'Draft Saved',
            ),
            const SizedBox(height: 18),
            SectionHeader(
              title: 'Vehicle Photos',
              trailing: '1 / 4 min required',
              trailingColor: AppColors.textMuted,
            ),
            const SizedBox(height: 4),
            Text('High-quality photos increase bookings by up to 40%.',
                style: AppText.body.copyWith(fontSize: 10)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: const [
                _Slot(label: 'Cover', sublabel: 'Front Angle', filled: true),
                _Slot(label: 'Interior / Cockpit', sublabel: 'Dashboard & seats'),
                _Slot(label: 'Rear & Trunk', sublabel: 'Cargo & charging'),
                _Slot(label: 'Add More Angles', sublabel: 'Up to 10 total', isAdd: true),
              ],
            ),
            const SizedBox(height: 18),
            SectionHeader(
              title: 'Body & Class Type',
              trailing: 'Select one',
              trailingColor: AppColors.textMuted,
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.5,
              children: [
                for (final (label, icon) in [
                  ('EV', Icons.bolt_rounded),
                  ('Sedan', Icons.directions_car_rounded),
                  ('SUV', Icons.airport_shuttle_rounded),
                  ('Luxury', Icons.diamond_outlined),
                  ('Hatchback', Icons.directions_car_outlined),
                  ('Convertible', Icons.wb_sunny_outlined),
                ])
                  SelectChip(
                    label: label,
                    icon: icon,
                    selected: ob.bodyType == label || (label == 'EV' && ob.bodyType == 'Electric'),
                    onTap: () =>
                        context.read<OnboardingController>().setBodyType(label),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text('Vehicle Specifications', style: AppText.sectionTitle),
            const SizedBox(height: 4),
            Text('Required for plate validation and registration compliance.',
                style: AppText.body.copyWith(fontSize: 10)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppDropdownField(
                    label: 'Brand / Make',
                    value: ob.make.isEmpty ? null : ob.make,
                    hint: 'Porsche',
                    items: const ['Porsche', 'BMW', 'Tesla', 'Mercedes', 'Audi'],
                    onChanged: (v) => ob.make = v ?? '',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppDropdownField(
                    label: 'Model',
                    value: ob.model.isEmpty ? null : ob.model,
                    hint: 'Taycan 4S',
                    items: const ['Taycan 4S', 'i4 M50', 'Model S Plaid'],
                    onChanged: (v) => ob.model = v ?? '',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AppDropdownField(
                    label: 'Year',
                    value: ob.year.isEmpty ? null : ob.year,
                    hint: '2024',
                    items: const ['2025', '2024', '2023', '2022'],
                    onChanged: (v) => ob.year = v ?? '',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppDropdownField(
                    label: 'Transmission',
                    value: ob.transmission.isEmpty ? null : ob.transmission,
                    hint: 'Automatic (EV)',
                    items: const ['Automatic (EV)', 'Automatic', 'Manual'],
                    onChanged: (v) => ob.transmission = v ?? '',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Registration / License Plate',
              hint: 'DL 01 AB 1234',
              onChanged: (v) => ob.plate = v,
              suffix: Container(
                margin: const EdgeInsets.all(10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('GOVT. VERIFIED',
                    style: AppText.captionCaps
                        .copyWith(color: AppColors.success, fontSize: 7.5)),
              ),
            ),
            const SizedBox(height: 18),
            Text('Pickup & Handover Location', style: AppText.sectionTitle),
            const SizedBox(height: 4),
            Text('Where guests collect and return the vehicle.',
                style: AppText.body.copyWith(fontSize: 10)),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Base Address',
              hint: '124 Market St, Financial District, San Fr…',
              prefix: const Icon(Icons.location_on_outlined,
                  size: 17, color: AppColors.primary),
              suffix: const Icon(Icons.gps_fixed_rounded,
                  size: 16, color: AppColors.textMuted),
              onChanged: (v) => ob.pickupAddress = v,
            ),
            const SizedBox(height: 12),
            AppCard(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Host Delivery Service',
                            style: AppText.sectionTitle
                                .copyWith(fontSize: 12.5)),
                        Text('Deliver the car to the guest location (+\$35)',
                            style: AppText.body.copyWith(fontSize: 10)),
                      ],
                    ),
                  ),
                  AppToggle(
                    value: ob.hostDelivery,
                    onChanged: (v) => context
                        .read<OnboardingController>()
                        .setHostDelivery(v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SectionHeader(
              title: 'Pricing & Earnings',
              trailing: 'Recommended \$110 - \$140',
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Daily Rental Rate',
              hint: '\$ ${ob.dailyRate.toStringAsFixed(0)}',
              keyboardType: TextInputType.number,
              suffix: Text('/ day',
                  style: AppText.body
                      .copyWith(fontSize: 11, color: AppColors.textMuted)),
              onChanged: (v) => ob.dailyRate = double.tryParse(v) ?? ob.dailyRate,
            ),
            const SizedBox(height: 12),
            AppCard(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Allow Hourly Rentals',
                            style: AppText.sectionTitle
                                .copyWith(fontSize: 12.5)),
                        Text('\$22/hr · 3hr minimum',
                            style: AppText.body.copyWith(fontSize: 10)),
                      ],
                    ),
                  ),
                  AppToggle(
                    value: ob.hourlyRentals,
                    onChanged: (v) => context
                        .read<OnboardingController>()
                        .setHourlyRentals(v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              color: AppColors.primarySoft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EST. MONTHLY HOST EARNINGS',
                          style: AppText.captionCaps
                              .copyWith(color: AppColors.primary)),
                      const SizedBox(height: 3),
                      Text('~\$${ob.estimatedMonthly.toStringAsFixed(0)} /mo',
                          style:
                              AppText.screenTitle.copyWith(fontSize: 18)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('80%\noccupancy',
                        textAlign: TextAlign.center,
                        style: AppText.captionCaps.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 8,
                            height: 1.2)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Listing & Telematics Setup',
                                style: AppText.sectionTitle
                                    .copyWith(fontSize: 12.5)),
                            const SizedBox(width: 6),
                            Text('ONE-TIME',
                                style: AppText.captionCaps
                                    .copyWith(fontSize: 7.5)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text('AYO Smart Key Box & Live GPS Hardware Kit',
                            style: AppText.body.copyWith(fontSize: 10)),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Includes \$1,000,000 Host Protection Guarantee and 24/7 emergency roadside recovery.',
                                style: AppText.body.copyWith(
                                    fontSize: 9.5,
                                    color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '\$${OnboardingController.listingFee.toStringAsFixed(2)}',
                    style: AppText.screenTitle.copyWith(fontSize: 17),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label:
                  'Pay & List Vehicle · \$${OnboardingController.listingFee.toStringAsFixed(2)}',
              icon: Icons.arrow_forward_rounded,
              loading: ob.saving,
              onPressed: () async {
                final ctrl = context.read<OnboardingController>();
                final ok = await ctrl.submitListing();
                if (context.mounted && ok) {
                  Navigator.pushNamed(context, PayoutSetupScreen.route);
                }
              },
            ),
            const SizedBox(height: 12),
            Center(
              child: Text.rich(
                TextSpan(
                  style: AppText.body
                      .copyWith(fontSize: 9.5, color: AppColors.textMuted),
                  children: [
                    const TextSpan(
                        text: 'By listing, you agree to AYO\'s '),
                    TextSpan(
                        text: 'Host Agreement',
                        style: TextStyle(color: AppColors.primary)),
                    const TextSpan(text: ' and '),
                    TextSpan(
                        text: 'Safety Standards',
                        style: TextStyle(color: AppColors.primary)),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.label,
    required this.sublabel,
    this.filled = false,
    this.isAdd = false,
  });

  final String label;
  final String sublabel;
  final bool filled;
  final bool isAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: filled ? AppColors.primarySoft : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filled ? AppColors.primaryBorder : AppColors.cardBorder,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAdd
                  ? Icons.add_rounded
                  : filled
                      ? Icons.check_circle_rounded
                      : Icons.add_photo_alternate_outlined,
              size: 22,
              color: filled ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(height: 4),
            Text(label,
                style: AppText.captionCaps.copyWith(
                    color: AppColors.textSecondary, fontSize: 8.5)),
            Text(sublabel,
                style: AppText.body
                    .copyWith(fontSize: 8.5, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
