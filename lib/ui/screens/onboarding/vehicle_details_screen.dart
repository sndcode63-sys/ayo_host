import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/controllers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/chrome.dart';
import '../../widgets/inputs.dart';
import 'vehicle_photos_screen.dart';

/// AYO Add Vehicle — List Your Vehicle (Step 1 of 2: Details & Pricing).
class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({super.key});

  static const route = '/onboarding/vehicle';

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  final _rateController = TextEditingController(text: '120');

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ob = context.watch<OnboardingController>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            const StepHeader(
              step: 1,
              totalSteps: 2,
              title: 'List Your Vehicle',
              subtitle: 'Step 1 of 2 · Details & Pricing',
            ),
            const SizedBox(height: 20),
            Text('Vehicle Details', style: AppText.screenTitle),
            const SizedBox(height: 4),
            Text(
              'Specify your vehicle specs and registration for automatic verification.',
              style: AppText.body,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in ['Electric', 'Sedan', 'Sports Car', 'SUV'])
                  SelectChip(
                    label: t,
                    icon: t == 'Electric' ? Icons.bolt_rounded : null,
                    selected: ob.bodyType == t,
                    onTap: () =>
                        context.read<OnboardingController>().setBodyType(t),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: AppDropdownField(
                    label: 'Make',
                    value: ob.make.isEmpty ? null : ob.make,
                    hint: 'Porsche',
                    items: const [
                      'Porsche',
                      'BMW',
                      'Tesla',
                      'Mercedes',
                      'Audi'
                    ],
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
                    hint: 'Automatic',
                    items: const ['Automatic', 'Manual'],
                    onChanged: (v) => ob.transmission = v ?? '',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    label: 'License Plate & State',
                    hint: '7XYZ890',
                    onChanged: (v) => ob.plate = v,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppDropdownField(
                    label: ' ',
                    value: ob.plateState.isEmpty ? null : ob.plateState,
                    hint: 'CA',
                    items: const ['CA', 'NY', 'TX', 'FL'],
                    onChanged: (v) => ob.plateState = v ?? '',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SectionHeader(
              title: 'Photos',
              trailing: '1 / 4 min',
              trailingColor: AppColors.textMuted,
            ),
            const SizedBox(height: 4),
            Text('Add at least 4 clear photos of exterior and interior.',
                style: AppText.body.copyWith(fontSize: 10)),
            const SizedBox(height: 10),
            const _PhotoGrid(),
            const SizedBox(height: 18),
            SectionHeader(
              title: 'Pricing & Earnings',
              trailing: 'Recommended \$110 - \$140',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Daily Rate',
                    hint: '\$ 120',
                    controller: _rateController,
                    keyboardType: TextInputType.number,
                    suffix: Text('/ day',
                        style: AppText.body
                            .copyWith(fontSize: 11, color: AppColors.textMuted)),
                    onChanged: (v) =>
                        ob.dailyRate = double.tryParse(v) ?? 0,
                  ),
                ),
              ],
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
                        Text('\$22/hr · 3 hr minimum',
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
                      Text('EST. MONTHLY EARNINGS',
                          style: AppText.captionCaps
                              .copyWith(color: AppColors.primary)),
                      const SizedBox(height: 3),
                      Text(
                        '~\$${ob.estimatedMonthly.toStringAsFixed(0)} /mo',
                        style: AppText.screenTitle.copyWith(fontSize: 18),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('80% occupancy',
                        style: AppText.captionCaps.copyWith(
                            color: AppColors.textSecondary, fontSize: 8.5)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _FeeCard(fee: OnboardingController.listingFee),
            const SizedBox(height: 18),
            PrimaryButton(
              label:
                  'Continue · \$${OnboardingController.listingFee.toStringAsFixed(2)}',
              icon: Icons.arrow_forward_rounded,
              loading: ob.saving,
              onPressed: () =>
                  Navigator.pushNamed(context, VehiclePhotosScreen.route),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'By proceeding, you agree to AYO\'s Host Terms and Safety Standards',
                style: AppText.body
                    .copyWith(fontSize: 9.5, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: const [
        _PhotoSlot(label: 'Cover', sublabel: 'Exterior 3/4', filled: true),
        _PhotoSlot(label: 'Interior', sublabel: 'Cockpit & seats'),
        _PhotoSlot(label: 'Rear & Trunk', sublabel: 'Charging port'),
        _PhotoSlot(label: 'More Photos', sublabel: 'Up to 8 total', isAdd: true),
      ],
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
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
      child: Stack(
        children: [
          Center(
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
                    style: AppText.body.copyWith(
                        fontSize: 8.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (filled)
            const Positioned(
              top: 6,
              left: 8,
              child: Text('COVER',
                  style: TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.primary)),
            ),
        ],
      ),
    );
  }
}

class _FeeCard extends StatelessWidget {
  const _FeeCard({required this.fee});

  final double fee;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Verification & Telematics Setup',
                    style: AppText.sectionTitle.copyWith(fontSize: 12.5)),
                const SizedBox(height: 3),
                Text('One-time registration and smart key kit',
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
                        'Includes \$1,000,000 host liability protection & 24/7 telematics tracking',
                        style: AppText.body.copyWith(
                            fontSize: 9.5, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text('\$${fee.toStringAsFixed(2)}',
              style: AppText.screenTitle.copyWith(fontSize: 17)),
        ],
      ),
    );
  }
}
