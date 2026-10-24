import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/services/toast_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/host_service.dart';
import '../../../state/controllers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chrome.dart';
import '../../widgets/inputs.dart';
import '../../widgets/app_image_view.dart';
import '../dashboard/main_shell.dart';
import 'payout_setup_screen.dart';

/// AYO Create Profile — Host Profile Setup (Step 1 of 2).
class HostProfileSetupScreen extends StatefulWidget {
  const HostProfileSetupScreen({super.key});

  static const route = '/onboarding/profile';

  @override
  State<HostProfileSetupScreen> createState() => _HostProfileSetupScreenState();
}

class _HostProfileSetupScreenState extends State<HostProfileSetupScreen> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _dob;
  late final TextEditingController _city;
  late final TextEditingController _phone;
  late final TextEditingController _bio;
  late final TextEditingController _dlNumber;
  String _avatarUrl = '';
  String? _avatarLocalPath;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileController>().profile;
    final user = context.read<AuthController>().user;

    _firstName = TextEditingController(text: profile?.firstName ?? '');
    _lastName = TextEditingController(text: profile?.lastName ?? '');
    _email = TextEditingController(text: profile?.email ?? user?.email ?? '');
    _dob = TextEditingController(text: profile?.dob ?? '');
    _city = TextEditingController(text: profile?.city ?? '');
    _phone = TextEditingController(text: profile?.phone ?? user?.phone ?? '');
    _bio = TextEditingController(text: profile?.bio ?? '');
    _dlNumber = TextEditingController(text: profile?.drivingLicenceNumber ?? '');
    _avatarUrl = profile?.avatarUrl ?? '';
  }

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _email,
      _dob,
      _city,
      _phone,
      _bio,
      _dlNumber,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    // Immediately show the selected photo locally on the UI with 0ms delay
    setState(() {
      _avatarLocalPath = picked.path;
      _uploadingAvatar = true;
    });

    try {
      final url = await HostService.uploadAvatarToGcs(File(picked.path));
      AppImageCache.register(url, picked.path);
      if (mounted) {
        setState(() => _avatarUrl = url);
      }
      ToastService.showSuccess('Profile photo uploaded to Google Cloud Storage!');
    } catch (e) {
      ToastService.showError('Photo upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 21)),
    );
    if (picked != null) {
      final month = picked.month.toString().padLeft(2, '0');
      final day = picked.day.toString().padLeft(2, '0');
      setState(() {
        _dob.text = '${picked.year}-$month-$day';
      });
    }
  }

  Future<void> _continue() async {
    final first = _firstName.text.trim();
    final last = _lastName.text.trim();
    final dobText = _dob.text.trim();
    final cityText = _city.text.trim();

    if (first.length < 2) {
      ToastService.showWarning('Please enter a valid first name (at least 2 letters)');
      return;
    }
    if (last.isEmpty) {
      ToastService.showWarning('Please enter your last name');
      return;
    }
    if (dobText.isEmpty) {
      ToastService.showWarning('Please select your Date of Birth');
      return;
    }

    try {
      final parsedDob = DateTime.parse(dobText);
      final ageYears = DateTime.now().difference(parsedDob).inDays ~/ 365;
      if (ageYears < 18) {
        ToastService.showWarning('Host must be at least 18 years old to list vehicles');
        return;
      }
    } catch (_) {}

    if (cityText.isEmpty) {
      ToastService.showWarning('Please enter your city (e.g. Bengaluru, Mumbai)');
      return;
    }

    final dlText = _dlNumber.text.trim();
    if (dlText.isEmpty || dlText.length < 5) {
      ToastService.showWarning('Please enter a valid Driving License (DL) number');
      return;
    }

    final ok = await context.read<ProfileController>().save({
      'first_name': first,
      'last_name': last,
      'dob': dobText,
      'city': cityText,
      'bio': _bio.text.trim().isNotEmpty ? _bio.text.trim() : 'Experienced car host on Ayo platform',
      'avatar_url': _avatarUrl,
      'driving_licence_number': dlText,
      'driving_licence': dlText,
      'dl_number': dlText,
    });
    if (mounted && ok) {
      ToastService.showSuccess('Host profile saved! Moving to Payout Setup.');
      Navigator.pushReplacementNamed(context, PayoutSetupScreen.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<ProfileController>().loading;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            StepHeader(
              step: 1,
              totalSteps: 3,
              title: 'AYO Host Onboarding',
              subtitle: 'Step 1 of 3 · Profile Setup',
              rightTag: 'Step 1 of 3',
              onClose: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, MainShell.route);
                }
              },
            ),
            const SizedBox(height: 20),
            Text('Set up your Host profile', style: AppText.screenTitle),
            const SizedBox(height: 4),
            Text(
              'Enter your host details to list vehicles and start earning with AYO.',
              style: AppText.body,
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.fieldFill,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primaryBorder, width: 1.5),
                          ),
                          child: _uploadingAvatar
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                              : (_avatarUrl.isNotEmpty || (_avatarLocalPath != null && _avatarLocalPath!.isNotEmpty))
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(40),
                                      child: AppImageView(
                                        url: _avatarUrl,
                                        localPath: _avatarLocalPath,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        isAvatar: true,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person_outline_rounded,
                                      size: 34,
                                      color: AppColors.textMuted,
                                    ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _avatarUrl.isNotEmpty ? 'Change Photo' : 'Upload Profile Photo',
                      style: AppText.body.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'First Name',
                    hint: 'First name',
                    controller: _firstName,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    label: 'Last Name',
                    hint: 'Last name',
                    controller: _lastName,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Email Address',
              hint: 'your.email@example.com',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              prefix: const Icon(Icons.mail_outline_rounded,
                  size: 17, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Date of Birth',
              hint: 'YYYY-MM-DD',
              controller: _dob,
              readOnly: true,
              onTap: () => _selectDate(context),
              prefix: const Icon(Icons.calendar_today_outlined,
                  size: 16, color: AppColors.textMuted),
              suffix: Text('21+ required',
                  style: AppText.captionCaps.copyWith(fontSize: 8)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 2),
              child: Text(
                'Must be 21+ to rent or host on AYO platform.',
                style:
                    AppText.body.copyWith(fontSize: 10, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'City & Region',
              hint: 'Bengaluru, Mumbai, Delhi...',
              controller: _city,
              prefix: const Icon(Icons.location_on_outlined,
                  size: 17, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Host Driving License (DL) Number',
              hint: 'e.g. DL1420110012345',
              controller: _dlNumber,
              prefix: const Icon(Icons.badge_outlined,
                  size: 17, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Phone Number',
              hint: '+91 9876543210',
              controller: _phone,
              keyboardType: TextInputType.phone,
              prefix: const Icon(Icons.call_outlined,
                  size: 17, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Host Bio & Fleet Overview',
              hint:
                  'Tell guests about your hospitality, vehicle care, or airport delivery options...',
              controller: _bio,
              maxLines: 4,
            ),
            const SizedBox(height: 18),
            Center(
              child: Text.rich(
                TextSpan(
                  style: AppText.body
                      .copyWith(fontSize: 9.5, color: AppColors.textMuted),
                  children: [
                    const TextSpan(
                        text: 'By continuing, you agree to AYO\'s '),
                    TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(color: AppColors.primary)),
                    const TextSpan(text: ' and '),
                    TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(color: AppColors.primary)),
                    const TextSpan(
                        text:
                            '. We verify identity to keep our community safe.'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Continue to Payout Setup',
              icon: Icons.arrow_forward_rounded,
              loading: saving,
              onPressed: _continue,
            ),
          ],
        ),
      ),
    );
  }
}
