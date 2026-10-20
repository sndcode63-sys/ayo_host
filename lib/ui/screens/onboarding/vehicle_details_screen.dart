import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/controllers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/chrome.dart';
import '../../widgets/inputs.dart';
import '../dashboard/main_shell.dart';
import 'vehicle_photos_screen.dart';

/// AYO Add Vehicle — List Your Vehicle (Step 1 of 2: Details, Custom Class, Pincode & Pricing).
class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({super.key});

  static const route = '/onboarding/vehicle';

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  late final TextEditingController _makeController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _rateController;
  late final TextEditingController _plateController;
  late final TextEditingController _addressController;
  late final TextEditingController _pincodeController;

  @override
  void initState() {
    super.initState();
    final ob = context.read<OnboardingController>();
    _makeController = TextEditingController(text: ob.make);
    _modelController = TextEditingController(text: ob.model);
    _yearController = TextEditingController(text: ob.year);
    _rateController = TextEditingController(text: ob.dailyRate > 0 ? ob.dailyRate.toInt().toString() : '');
    _plateController = TextEditingController(text: ob.plate);
    _addressController = TextEditingController(text: ob.pickupAddress);
    _pincodeController = TextEditingController(text: ob.pincode);
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _rateController.dispose();
    _plateController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _showAddCustomClassDialog(BuildContext context) {
    final customClassController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Vehicle Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter custom vehicle body type or class (e.g. Vintage, Van, Camper):',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: customClassController,
              decoration: const InputDecoration(
                hintText: 'e.g. Convertible / Vintage',
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
            onPressed: () {
              final name = customClassController.text.trim();
              if (name.isNotEmpty) {
                context.read<OnboardingController>().addCustomBodyType(name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add & Select', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ob = context.watch<OnboardingController>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            StepHeader(
              step: 3,
              totalSteps: 3,
              title: 'AYO Host Onboarding',
              subtitle: 'Step 3 of 3 · Vehicle Specs & Rates',
              rightTag: 'Step 3 of 3',
              onClose: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, MainShell.route);
                }
              },
            ),
            const SizedBox(height: 20),
            Text('Vehicle Details', style: AppText.screenTitle),
            const SizedBox(height: 4),
            Text(
              'Specify your vehicle details, registration plate, location, and daily rate to list on Ayo.',
              style: AppText.body,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('VEHICLE CLASS / BODY TYPE', style: AppText.fieldLabel),
                GestureDetector(
                  onTap: () => _showAddCustomClassDialog(context),
                  child: Text(
                    '+ Custom Class',
                    style: AppText.captionCaps.copyWith(
                      color: AppColors.primary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in ob.bodyTypes)
                  SelectChip(
                    label: t,
                    icon: t == 'Electric' ? Icons.bolt_rounded : null,
                    selected: ob.bodyType == t,
                    onTap: () =>
                        context.read<OnboardingController>().setBodyType(t),
                  ),
                SelectChip(
                  label: '+ Custom Class',
                  selected: false,
                  icon: Icons.add_rounded,
                  onTap: () => _showAddCustomClassDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Make / Brand',
                    hint: 'e.g. Hyundai, Tata, Porsche...',
                    controller: _makeController,
                    onChanged: (v) => ob.make = v,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    label: 'Model Name',
                    hint: 'e.g. Creta, Nexon, Taycan...',
                    controller: _modelController,
                    onChanged: (v) => ob.model = v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Manufacturing Year',
                    hint: 'e.g. 2024',
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => ob.year = v,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppDropdownField(
                    label: 'Transmission',
                    value: ob.transmission.isEmpty ? 'Automatic' : ob.transmission,
                    hint: 'Automatic',
                    items: const ['Automatic', 'Manual'],
                    onChanged: (v) => ob.transmission = v ?? 'Automatic',
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
                    label: 'License Registration Plate',
                    hint: 'e.g. KA 01 AB 1234',
                    controller: _plateController,
                    onChanged: (v) => ob.plate = v,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: AppDropdownField(
                    label: 'Registration State',
                    value: ob.plateState.isEmpty ? 'KA - Karnataka' : ob.plateState,
                    hint: 'KA - Karnataka',
                    items: OnboardingController.allIndianStates,
                    onChanged: (v) => ob.plateState = v ?? 'KA - Karnataka',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('PICKUP LOCATION & PINCODE', style: AppText.fieldLabel),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pincodeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 560038',
                      counterText: '',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (v) => ob.pincode = v,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: ob.pincodeLoading
                        ? null
                        : () async {
                            final success = await ob.fetchAddressFromPincode(
                              _pincodeController.text,
                            );
                            if (success) {
                              _addressController.text = ob.pickupAddress;
                            }
                          },
                    icon: ob.pincodeLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.my_location_rounded, size: 16),
                    label: const Text('Fetch Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AppTextField(
              label: 'Pickup Address',
              hint: 'e.g. Flat 101, Indiranagar, Bengaluru, Karnataka',
              controller: _addressController,
              prefix: const Icon(Icons.location_on_outlined,
                  size: 17, color: AppColors.primary),
              onChanged: (v) => ob.pickupAddress = v,
            ),
            const SizedBox(height: 18),
            SectionHeader(
              title: 'Pricing & Earnings',
              trailing: 'Set your daily rental rate in ₹',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Daily Rate (Rupees)',
                    hint: 'e.g. 3500',
                    controller: _rateController,
                    keyboardType: TextInputType.number,
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12, right: 4),
                      child: Text('₹', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
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
                        Text('Hourly rentals enabled for guest trips',
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
            if (ob.dailyRate > 0)
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
                        Text(
                          '~₹${ob.estimatedMonthly.toInt()} /mo',
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
                      child: Text('75% occupancy',
                          style: AppText.captionCaps.copyWith(
                              color: AppColors.textSecondary, fontSize: 8.5)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Next: Vehicle Photos & Documents',
              icon: Icons.arrow_forward_rounded,
              loading: ob.saving,
              onPressed: () {
                if (ob.make.trim().isEmpty || ob.model.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter Make and Model of your vehicle')),
                  );
                  return;
                }
                final currentYear = DateTime.now().year;
                final parsedYear = int.tryParse(ob.year.trim());
                if (parsedYear == null || parsedYear < 1990 || parsedYear > currentYear + 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid 4-digit manufacturing year (1990 - ${currentYear + 1})')),
                  );
                  return;
                }
                if (ob.dailyRate <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a daily rate in ₹')),
                  );
                  return;
                }
                Navigator.pushNamed(context, VehiclePhotosScreen.route);
              },
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'By proceeding, you agree to AYO\'s Host Terms and Vehicle Safety Standards',
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
