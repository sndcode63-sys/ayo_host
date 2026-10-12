import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/controllers.dart';
import '../../widgets/cards.dart';
import '../account/account_details_screen.dart';
import '../auth/sign_in_screen.dart';

/// AYO Host Menu & Settings — "More" tab.
class MoreMenuScreen extends StatefulWidget {
  const MoreMenuScreen({super.key});

  static const route = '/menu';

  @override
  State<MoreMenuScreen> createState() => _MoreMenuScreenState();
}

class _MoreMenuScreenState extends State<MoreMenuScreen> {
  bool pushNotifications = true;
  bool bookingAlerts = true;
  bool darkMode = false;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>().profile;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          Row(
            children: [
              Text(
                'AYO',
                style: AppText.sectionTitle.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Text('HOST', style: AppText.captionCaps),
              const Spacer(),
              Text('More Menu', style: AppText.sectionTitle),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            onTap: () =>
                Navigator.pushNamed(context, AccountDetailsScreen.route),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primarySoft,
                      child: Text(
                        profile?.initials ?? 'MV',
                        style: AppText.sectionTitle
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                    const Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.check_rounded,
                            size: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile?.fullName ?? 'Marcus Vance',
                          style: AppText.sectionTitle
                              .copyWith(fontSize: 15)),
                      Text(profile?.bio ?? 'Superhost · San Francisco, CA',
                          style: AppText.body.copyWith(fontSize: 10.5)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 13, color: AppColors.warning),
                          Text(
                            ' ${profile?.rating?.toStringAsFixed(2) ?? '4.98'} (${profile?.reviewCount ?? 86} reviews)',
                            style: AppText.body.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.edit_outlined,
                    size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppCard(
                  color: AppColors.primarySoft,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HOST TIER',
                          style: AppText.captionCaps
                              .copyWith(color: AppColors.primary)),
                      const SizedBox(height: 3),
                      Text(profile?.tier ?? 'Superhost Elite',
                          style: AppText.sectionTitle.copyWith(
                              fontSize: 13, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RESPONSE RATE', style: AppText.captionCaps),
                      const SizedBox(height: 3),
                      Text(
                        '${profile?.responseRate?.toStringAsFixed(0) ?? '99'}% · <5 min',
                        style: AppText.sectionTitle.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MenuSection(
            title: 'FLEET & HOSTING',
            items: [
              _MenuItem(
                icon: Icons.directions_car_filled_rounded,
                title: 'My Listings',
                subtitle: '9 Vehicles · 6 active',
                tag: '9 total',
              ),
              _MenuItem(
                icon: Icons.add_circle_outline_rounded,
                title: 'Add New Vehicle',
                subtitle: 'Onboard a car, set daily rates & sync keys',
              ),
              _MenuItem(
                icon: Icons.insights_rounded,
                title: 'Listing Performance & Insights',
                subtitle: '14-day views, conversion, earnings boost',
              ),
            ],
          ),
          _MenuSection(
            title: 'FINANCIAL & SECURITY',
            items: [
              _MenuItem(
                icon: Icons.account_balance_outlined,
                title: 'Payout & Bank Settings',
                subtitle: 'Chase ••••4192 · Auto-payout enabled',
              ),
              _MenuItem(
                icon: Icons.receipt_long_outlined,
                title: 'Earnings Statements & Tax Invoices',
                subtitle: 'Monthly PDF exports · GST/VAT-ready',
              ),
              _MenuItem(
                icon: Icons.lock_outline_rounded,
                title: 'Security & Login',
                subtitle: 'Passwords, 2FA, linked devices',
              ),
            ],
          ),
          _MenuSection(
            title: 'PREFERENCES',
            custom: [
              _ToggleRow(
                icon: Icons.notifications_outlined,
                title: 'Push Notifications',
                subtitle: 'Trip updates & instant messages',
                value: pushNotifications,
                onChanged: (v) => setState(() => pushNotifications = v),
              ),
              _ToggleRow(
                icon: Icons.flash_on_outlined,
                title: 'Booking Requests & Instant Alerts',
                subtitle: 'Immediate SMS and chime for approvals',
                value: bookingAlerts,
                onChanged: (v) => setState(() => bookingAlerts = v),
              ),
              _ToggleRow(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Sync with system theme',
                value: darkMode,
                onChanged: (v) => setState(() => darkMode = v),
              ),
              const _ValueRow(
                icon: Icons.translate_rounded,
                title: 'App Language',
                subtitle: 'English (US)',
                value: 'EN ›',
              ),
            ],
          ),
          _MenuSection(
            title: 'EXPERIENCE & SUPPORT',
            items: [
              _MenuItem(
                icon: Icons.swap_horiz_rounded,
                title: 'Switch to Guest Mode',
                subtitle: 'Browse rentals & book for personal trips',
              ),
              _MenuItem(
                icon: Icons.support_agent_rounded,
                title: 'Host Support & Concierge',
                subtitle: '24/7 dedicated line for Superhosts',
                tag: '24/7 Priority',
              ),
              _MenuItem(
                icon: Icons.shield_outlined,
                title: 'Terms & Host Protection Policy',
                subtitle: '\$1M liability coverage guidelines',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () {
                context.read<AuthController>().signOut();
                Navigator.pushNamedAndRemoveUntil(
                    context, SignInScreen.route, (r) => false);
              },
              icon: const Icon(Icons.logout_rounded,
                  size: 15, color: AppColors.primary),
              label: Text('Sign Out',
                  style: AppText.body.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text('AYO Host v2.4.0 (Build 6081)',
                style: AppText.body
                    .copyWith(fontSize: 9, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? tag;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.tag,
  });
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, this.items, this.custom});

  final String title;
  final List<_MenuItem>? items;
  final List<Widget>? custom;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(title, style: AppText.captionCaps),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              if (items != null)
                for (var i = 0; i < items!.length; i++) ...[
                  _MenuRow(item: items![i]),
                  if (i < items!.length - 1)
                    const Divider(indent: 14, endIndent: 14),
                ],
              if (custom != null)
                for (var i = 0; i < custom!.length; i++) ...[
                  custom![i],
                  if (i < custom!.length - 1)
                    const Divider(indent: 14, endIndent: 14),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item});

  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(item.icon, size: 16, color: AppColors.primary),
      ),
      title: Text(item.title,
          style: AppText.sectionTitle.copyWith(fontSize: 12.5)),
      subtitle: Text(item.subtitle,
          style:
              AppText.body.copyWith(fontSize: 9.5, color: AppColors.textMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      trailing: item.tag != null
          ? Text(item.tag!,
              style: AppText.captionCaps.copyWith(
                  color: AppColors.primary, fontSize: 8.5))
          : const Icon(Icons.chevron_right_rounded,
              size: 18, color: AppColors.textMuted),
      onTap: () {},
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
      title: Text(title, style: AppText.sectionTitle.copyWith(fontSize: 12.5)),
      subtitle: Text(subtitle,
          style:
              AppText.body.copyWith(fontSize: 9.5, color: AppColors.textMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      trailing: AppToggle(value: value, onChanged: onChanged),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
      title: Text(title, style: AppText.sectionTitle.copyWith(fontSize: 12.5)),
      subtitle: Text(subtitle,
          style:
              AppText.body.copyWith(fontSize: 9.5, color: AppColors.textMuted)),
      trailing: Text(value,
          style: AppText.body.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted)),
    );
  }
}
