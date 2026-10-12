import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/controllers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';

/// AYO Account Details — personal info, contact, payout, privacy.
class AccountDetailsScreen extends StatelessWidget {
  const AccountDetailsScreen({super.key});

  static const route = '/account';

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>().profile;

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
                Text('Edit',
                    style: AppText.body.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 18),
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: AppColors.primarySoft,
                        child: Text(
                          profile?.initials ?? 'MV',
                          style: AppText.screenTitle
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                      const Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.check_rounded,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(profile?.fullName ?? 'Marcus Vance',
                      style: AppText.screenTitle.copyWith(fontSize: 19)),
                  Text(
                    'Host · Member since ${profile?.memberSince ?? '2023'}',
                    style: AppText.body
                        .copyWith(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _InfoSection(
              title: 'PERSONAL INFORMATION',
              rows: [
                ('Full Legal Name', 'Marcus Alexander Vance', null),
                ('Date of Birth', 'Oct 14, 1991', null),
                ('Nationality', 'United States', null),
                ("Driver's License", 'CA DL ••••8942', 'Verified'),
              ],
            ),
            const _InfoSection(
              title: 'CONTACT & SECURITY',
              rows: [
                ('Email Address', 'marcus.vance@example.com', 'Primary'),
                ('Phone Number', '+1 (415) 890-0194', null),
                ('Connected Accounts', 'Google, Apple ID', '2 Active'),
              ],
            ),
            const _InfoSection(
              title: 'PAYOUT & BILLING',
              rows: [
                ('Default Payout', 'Chase Bank ••••4192', 'Default'),
                ('', 'Checking · Direct Deposit', null),
                ('Tax Information', 'W-9 on file (••••6789)', '2024'),
                ('Billing Address', '742 Montgomery St, San Francisco, CA', null),
              ],
            ),
            const _InfoSection(
              title: 'PREFERENCES & PRIVACY',
              rows: [
                ('Two-Factor Authentication', 'Authenticator App', 'Enabled'),
                ('Password', 'Updated 3 months ago', 'Change'),
              ],
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Edit Details',
              icon: Icons.edit_outlined,
              onPressed: () {},
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Download Data',
                    style: AppText.body.copyWith(
                        fontSize: 10.5, color: AppColors.textSecondary)),
                const SizedBox(width: 18),
                Text('Deactivate Account',
                    style: AppText.body.copyWith(
                        fontSize: 10.5, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'AYO ID: AYO-US-928104 · 256-bit encrypted',
                style: AppText.body
                    .copyWith(fontSize: 9, color: AppColors.textMuted),
              ),
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
        'Verified' || 'Enabled' => AppColors.success,
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
