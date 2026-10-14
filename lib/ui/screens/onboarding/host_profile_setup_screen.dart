import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/controllers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chrome.dart';
import '../../widgets/inputs.dart';
import 'payout_setup_screen.dart';

/// AYO Create Profile — Host Profile Setup (Step 1 of 2).
class HostProfileSetupScreen extends StatefulWidget {
  const HostProfileSetupScreen({super.key});

  static const route = '/onboarding/profile';

  @override
  State<HostProfileSetupScreen> createState() => _HostProfileSetupScreenState();
}

class _HostProfileSetupScreenState extends State<HostProfileSetupScreen> {
  final _firstName = TextEditingController(text: 'Rohit');
  final _lastName = TextEditingController(text: 'Kumar');
  final _email = TextEditingController();
  final _dob = TextEditingController(text: '1998-05-15');
  final _city = TextEditingController(text: 'Bengaluru');
  final _phone = TextEditingController();
  final _bio = TextEditingController(text: 'Bike & car host on Ayo platform');
  final String _avatarKey = 'avatars/default_host.jpg';

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
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _continue() async {
    if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your first and last name')),
      );
      return;
    }

    final ok = await context.read<ProfileController>().save({
      'first_name': _firstName.text.trim(),
      'last_name': _lastName.text.trim(),
      'dob': _dob.text.trim(),
      'city': _city.text.trim(),
      'bio': _bio.text.trim(),
      'avatar_url': _avatarKey,
    });
    if (mounted && ok) {
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
            const StepHeader(
              step: 1,
              totalSteps: 2,
              title: 'Host Profile Setup',
              rightTag: '50% Completed',
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
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: AppColors.fieldFill,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.fieldBorder),
                        ),
                        child: const Icon(Icons.person_outline_rounded,
                            size: 34, color: AppColors.textMuted),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_rounded,
                              size: 15, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Add Photo',
                      style: AppText.body.copyWith(
                          fontSize: 11, fontWeight: FontWeight.w600)),
                  Text('Optional. Can be updated later',
                      style: AppText.body.copyWith(
                          fontSize: 9.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'First Name',
                    hint: 'Alex',
                    controller: _firstName,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    label: 'Last Name',
                    hint: 'Morgan',
                    controller: _lastName,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Email Address',
              hint: 'alex.morgan@example.com',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              prefix: const Icon(Icons.mail_outline_rounded,
                  size: 17, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Date of Birth',
              hint: 'mm/dd/yyyy',
              controller: _dob,
              keyboardType: TextInputType.datetime,
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
              hint: 'San Francisco, CA',
              controller: _city,
              prefix: const Icon(Icons.location_on_outlined,
                  size: 17, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Phone Number',
              hint: '(415) 000-0000',
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
              label: 'Continue to Vehicle Listing',
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
