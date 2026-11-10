import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/services/toast_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/controllers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/chrome.dart';
import '../../widgets/inputs.dart';
import '../../widgets/listing_fee_banner.dart';
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
  late final TextEditingController _weekendController;
  late final TextEditingController _mileageController;

  @override
  void initState() {
    super.initState();
    final ob = context.read<OnboardingController>();
    if (ob.submitResult != null) {
      ob.resetVehicleDraft();
    }
    _makeController = TextEditingController(text: ob.make);
    _modelController = TextEditingController(text: ob.model);
    _yearController = TextEditingController(text: ob.year);
    _rateController = TextEditingController(text: ob.dailyRate > 0 ? ob.dailyRate.toInt().toString() : '');
    _plateController = TextEditingController(text: ob.plate);
    _addressController = TextEditingController(text: ob.pickupAddress);
    _pincodeController = TextEditingController(text: ob.pincode);
    _weekendController = TextEditingController(text: ob.weekendRate > 0 ? ob.weekendRate.toInt().toString() : '');
    _mileageController = TextEditingController(text: ob.mileage);

    // Auto-fetch pickup location as soon as the screen opens (only if nothing typed yet).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final c = context.read<OnboardingController>();
      if (c.pickupAddress.trim().isEmpty && c.pincode.trim().isEmpty) {
        final ok = await c.autoFetchCurrentLocation(silent: true);
        if (ok && mounted) _syncLocationFields();
      }
    });
  }

  void _syncLocationFields() {
    final c = context.read<OnboardingController>();
    _addressController.text = c.pickupAddress;
    _pincodeController.text = c.pincode;
  }

  Future<void> _fetchFromPincode(String pin) async {
    final c = context.read<OnboardingController>();
    final ok = await c.fetchAddressFromPincode(pin);
    if (ok && mounted) _syncLocationFields();
  }

  Future<void> _useCurrentLocation() async {
    final c = context.read<OnboardingController>();
    final ok = await c.autoFetchCurrentLocation();
    if (ok && mounted) _syncLocationFields();
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
    _weekendController.dispose();
    _mileageController.dispose();
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
            AppTextField(
              hint: 'e.g. Convertible / Vintage',
              controller: customClassController,
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
            const ListingFeeBanner(),
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
                    hint: 'e.g. City, Baleno, Creta, Harrier...',
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
                  child: AppDropdownField(
                    label: 'Seats',
                    value: ob.seatingCapacity.toString(),
                    hint: '5',
                    items: const ['2', '4', '5', '6', '7', '8'],
                    onChanged: (v) => ob.seatingCapacity = int.tryParse(v ?? '') ?? 5,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppDropdownField(
                    label: 'Fuel Type',
                    value: ob.fuelType,
                    hint: 'Petrol',
                    items: const ['Petrol', 'Diesel', 'CNG', 'Electric', 'Hybrid'],
                    onChanged: (v) => ob.fuelType = v ?? 'Petrol',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AppDropdownField(
                    label: 'Drivetrain',
                    value: ob.drivetrain,
                    hint: '2WD',
                    items: const ['2WD', '4WD', 'AWD', 'FWD', 'RWD'],
                    onChanged: (v) => ob.drivetrain = v ?? '2WD',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    label: 'Mileage',
                    hint: 'e.g. 16 kmpl',
                    controller: _mileageController,
                    onChanged: (v) => ob.mileage = v,
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
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (v) => ob.plate = v,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: AppDropdownField(
                    label: 'Registration State',
                    value: ob.plateState.isEmpty ? null : ob.plateState,
                    hint: 'Select State (e.g. DL, MH, KA)',
                    items: OnboardingController.allIndianStates,
                    onChanged: (v) => ob.plateState = v ?? '',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('PICKUP LOCATION', style: AppText.fieldLabel),
                GestureDetector(
                  onTap: ob.locationLoading ? null : _useCurrentLocation,
                  child: Row(
                    children: [
                      if (ob.locationLoading)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const Icon(Icons.my_location_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        ob.locationLoading ? 'Detecting...' : 'Use current location',
                        style: AppText.captionCaps.copyWith(
                          color: AppColors.primary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppTextField(
              label: 'Pincode',
              hint: 'e.g. 560038',
              controller: _pincodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefix: const Icon(Icons.pin_drop_outlined, size: 17, color: AppColors.primary),
              suffix: ob.pincodeLoading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              helper: 'Enter 6 digits — address is fetched automatically',
              onChanged: (v) {
                ob.pincode = v;
                if (v.length == 6) _fetchFromPincode(v);
              },
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Pickup Address',
              hint: 'e.g. Building number, street, locality, city, state',
              controller: _addressController,
              maxLines: 3,
              prefix: const Icon(Icons.location_on_outlined, size: 17, color: AppColors.primary),
              helper: 'Auto-detected from your location · you can edit it manually',
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
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    label: 'Weekend Rate (optional)',
                    hint: 'Auto: +20%',
                    controller: _weekendController,
                    keyboardType: TextInputType.number,
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12, right: 4),
                      child: Text('₹', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    onChanged: (v) => ob.weekendRate = double.tryParse(v) ?? 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppCard(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Allow Hourly Rentals',
                            style: AppText.sectionTitle
                                .copyWith(fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(
                          ob.hourlyRentals
                              ? (ob.effectiveHourlyRate > 0
                                  ? '₹${ob.effectiveHourlyRate.toInt()}/hr · 3 hr minimum'
                                  : (ob.dailyRate > 0
                                      ? '₹${(ob.dailyRate / 10).round()}/hr · 3 hr minimum'
                                      : 'Calculated from daily rate · 3 hr minimum'))
                              : 'Enable hourly bookings alongside daily rentals',
                          style: AppText.body.copyWith(
                            fontSize: 11,
                            color: ob.hourlyRentals ? AppColors.primary : AppColors.textMuted,
                            fontWeight: ob.hourlyRentals ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
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
            if (ob.hourlyRentals) ...[
              const SizedBox(height: 12),
              AppCard(
                color: AppColors.primarySoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hourly rental pricing',
                                style: AppText.captionCaps.copyWith(color: AppColors.primary)),
                            const SizedBox(height: 3),
                            Text(
                              ob.effectiveHourlyRate > 0
                                  ? '₹${ob.effectiveHourlyRate.toInt()} / hr'
                                  : (ob.dailyRate > 0
                                      ? '₹${(ob.dailyRate / 10).round()} / hr'
                                      : 'Set daily rate above'),
                              style: AppText.screenTitle.copyWith(
                                fontSize: ob.effectiveHourlyRate > 0 || ob.dailyRate > 0 ? 20 : 15,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primaryBorder),
                          ),
                          child: Text(
                            '3 hr minimum trip',
                            style: AppText.captionCaps.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (ob.effectiveHourlyRate > 0 || ob.dailyRate > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Minimum trip earnings: ₹${((ob.effectiveHourlyRate > 0 ? ob.effectiveHourlyRate : (ob.dailyRate / 10).roundToDouble()) * 3).toInt()} (calculated in Indian Rupees ₹)',
                        style: AppText.body.copyWith(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ] else if (ob.dailyRate > 0) ...[
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
            ],
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Next: Vehicle Photos & Documents',
              icon: Icons.arrow_forward_rounded,
              loading: ob.saving,
              onPressed: () {
                ob.make = _makeController.text.trim();
                ob.model = _modelController.text.trim();
                ob.year = _yearController.text.trim();
                ob.plate = _plateController.text.trim().toUpperCase();
                ob.pickupAddress = _addressController.text.trim();
                ob.pincode = _pincodeController.text.trim();
                ob.dailyRate = double.tryParse(_rateController.text.trim()) ?? 0;
                ob.weekendRate = double.tryParse(_weekendController.text.trim()) ?? 0;
                ob.mileage = _mileageController.text.trim();

                if (ob.make.isEmpty || ob.model.isEmpty) {
                  ToastService.showWarning('Please enter Make and Model of your vehicle');
                  return;
                }
                final currentYear = DateTime.now().year;
                final parsedYear = int.tryParse(ob.year);
                if (parsedYear == null || parsedYear < 1990 || parsedYear > currentYear + 1) {
                  ToastService.showWarning('Please enter a valid 4-digit manufacturing year (1990 - ${currentYear + 1})');
                  return;
                }
                if (ob.plate.isEmpty) {
                  ToastService.showWarning('Please enter vehicle Registration Plate number (e.g. 05 KL 8821)');
                  return;
                }
                if (ob.plateState.isEmpty) {
                  ToastService.showWarning('Please select your vehicle Registration State');
                  return;
                }
                if (ob.pincode.length != 6) {
                  ToastService.showWarning('Please enter a valid 6-digit pincode');
                  return;
                }
                if (ob.pickupAddress.isEmpty) {
                  ToastService.showWarning('Please enter vehicle pickup address or fetch via Pincode');
                  return;
                }
                if (ob.dailyRate <= 0) {
                  ToastService.showWarning('Please enter a valid daily rental rate in ₹');
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
