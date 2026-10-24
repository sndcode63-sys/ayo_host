import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/controllers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/app_image_view.dart';
import '../onboarding/host_profile_setup_screen.dart';

/// AYO Account Details — personal info, contact, payout, privacy.
class AccountDetailsScreen extends StatelessWidget {
  const AccountDetailsScreen({super.key});

  static const route = '/account';

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>().profile;
    final user = context.watch<AuthController>().user;

    final nameText = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : user?.name?.isNotEmpty == true
            ? user!.name!
            : 'Host Partner';

    final emailText = profile?.email?.isNotEmpty == true
        ? profile!.email!
        : user?.email?.isNotEmpty == true
            ? user!.email!
            : 'Not set';

    final phoneText = profile?.phone?.isNotEmpty == true
        ? profile!.phone!
        : user?.phone.isNotEmpty == true
            ? user!.phone
            : 'Not set';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 16),
                  ),
                ),
                const Spacer(),
                Text('Account Details', style: AppText.sectionTitle),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, HostProfileSetupScreen.route),
                  child: Text('Edit',
                      style: AppText.body.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, HostProfileSetupScreen.route),
                    child: Builder(
                      builder: (context) {
                        final avatarUrl = profile?.avatarUrl;
                        return Stack(
                          children: [
                            ClipOval(
                              child: Container(
                                width: 68,
                                height: 68,
                                color: AppColors.primarySoft,
                                child: AppImageView(
                                  url: avatarUrl,
                                  width: 68,
                                  height: 68,
                                  fit: BoxFit.cover,
                                  isAvatar: true,
                                  fallbackIcon: Center(
                                    child: Text(
                                      profile?.initials.isNotEmpty == true ? profile!.initials : 'H',
                                      style: AppText.screenTitle.copyWith(color: AppColors.primary),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Positioned(
                              right: 0,
                              bottom: 0,
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: AppColors.primary,
                                child: Icon(Icons.edit_rounded,
                                    size: 10, color: Colors.white),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(nameText, style: AppText.screenTitle.copyWith(fontSize: 19)),
                  Text(
                    'Host Partner · Member since ${profile?.memberSince ?? '2024'}',
                    style: AppText.body
                        .copyWith(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _InfoSection(
              title: 'PERSONAL INFORMATION',
              rows: [
                ('Full Name', nameText, null),
                ('Date of Birth', (profile?.dob?.isNotEmpty == true) ? profile!.dob! : 'Not provided', null),
                ('City / Region', (profile?.city.isNotEmpty == true) ? profile!.city : 'Not provided', null),
                ("Host Status", profile?.isCompleted == true ? 'Onboarding Complete' : 'Profile Active', 'Verified'),
              ],
            ),
            _InfoSection(
              title: 'CONTACT & SECURITY',
              rows: [
                ('Email Address', emailText, 'Primary'),
                ('Phone Number', phoneText, 'Verified'),
                ('Bio', (profile?.bio.isNotEmpty == true) ? profile!.bio : 'Host on Ayo platform', null),
              ],
            ),
            _InfoSection(
              title: 'PAYOUT & BILLING',
              rows: [
                ('Payout Method', profile?.payoutMethod ?? 'UPI / Bank Transfer', 'Configured'),
                ('Payout Status', 'Direct Deposit', 'Active'),
              ],
            ),
            const _InfoSection(
              title: 'PREFERENCES & PRIVACY',
              rows: [
                ('Platform Status', 'Active Host', 'Enabled'),
                ('DPDP Compliance', 'Consent Accepted (v1.0)', 'Verified'),
              ],
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Edit Profile Details',
              icon: Icons.edit_outlined,
              onPressed: () => Navigator.pushNamed(context, HostProfileSetupScreen.route),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.rows});

  final String title;
  final List<(String, String, String?)> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(title, style: AppText.captionCaps),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                _InfoRow(
                  label: rows[i].$1,
                  value: rows[i].$2,
                  tag: rows[i].$3,
                ),
                if (i < rows.length - 1) const Divider(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.tag});

  final String label;
  final String value;
  final String? tag;

  Color get _tagColor => switch (tag) {
        'Verified' || 'Enabled' || 'Configured' => AppColors.success,
        'Change' => AppColors.primary,
        _ => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label.isNotEmpty)
                  Text(label,
                      style: AppText.body.copyWith(
                          fontSize: 10, color: AppColors.textMuted)),
                Text(value,
                    style: AppText.input.copyWith(
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (tag != null)
            Text(tag!,
                style: AppText.body.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _tagColor)),
        ],
      ),
    );
  }
}
