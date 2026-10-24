import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/toast_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../state/controllers.dart';
import '../../widgets/cards.dart';
import '../account/account_details_screen.dart';
import '../auth/sign_in_screen.dart';
import '../dashboard/fleet_screen.dart';
import '../insights/performance_insights_screen.dart';
import '../onboarding/payout_setup_screen.dart';
import '../onboarding/vehicle_details_screen.dart';

/// AYO Host Menu & Settings — "More" tab (Fully Dynamic & Interactive).
class MoreMenuScreen extends StatefulWidget {
  const MoreMenuScreen({super.key});

  static const route = '/menu';

  @override
  State<MoreMenuScreen> createState() => _MoreMenuScreenState();
}

class _MoreMenuScreenState extends State<MoreMenuScreen> {
  bool pushNotifications = true;
  bool bookingAlerts = true;

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: AppText.sectionTitle),
        content: Text(message, style: AppText.body.copyWith(fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(SupportConfig? support) {
    final phone = support?.phone.isNotEmpty == true ? support!.phone : '+91 1800-296-0000';
    final email = support?.email.isNotEmpty == true ? support!.email : 'support@ayo.com';
    final whatsapp = support?.whatsapp.isNotEmpty == true ? support!.whatsapp : '+91 9999900000';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('24/7 Dedicated Host Concierge', style: AppText.sectionTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need urgent help during a trip or handover? Contact our dedicated support team:', style: AppText.body.copyWith(fontSize: 12)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Helpline: $phone', style: AppText.body.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Email: $email', style: AppText.body.copyWith(fontSize: 12)),
              ],
            ),
            if (whatsapp.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text('WhatsApp: $whatsapp', style: AppText.body.copyWith(fontSize: 12)),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPoliciesDialog(PlatformPolicies? policies) {
    final freeHours = policies?.cancellationFreeHours ?? 24;
    final minAge = policies?.minRenterAge ?? 21;
    final coverageText = policies?.coverageText ?? 'Comprehensive insurance with 24/7 roadside assistance.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Host Protection & Platform Policies', style: AppText.sectionTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(coverageText, style: AppText.body.copyWith(fontSize: 12)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Free Cancellation: Up to $freeHours hours before trip start', style: AppText.body.copyWith(fontSize: 11.5)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.verified_user_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Minimum Renter Age: $minAge years with valid driving license', style: AppText.body.copyWith(fontSize: 11.5)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>().profile;
    final user = context.watch<AuthController>().user;
    final dash = context.watch<DashboardController>();
    final vehiclesCount = dash.vehicles.length;

    final nameText = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : user?.name?.isNotEmpty == true
            ? user!.name!
            : 'Host Partner';

    final bioText = profile?.bio.isNotEmpty == true
        ? profile!.bio
        : profile?.city.isNotEmpty == true
            ? 'Host · ${profile!.city}'
            : 'Host Partner';

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
          // Host Profile Card -> Navigates to AccountDetailsScreen
          AppCard(
            onTap: () =>
                Navigator.pushNamed(context, AccountDetailsScreen.route),
            child: Row(
              children: [
                Builder(
                  builder: (context) {
                    final avatarUrl = profile?.avatarUrl;
                    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
                    return Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primarySoft,
                          backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                          child: hasAvatar
                              ? null
                              : Text(
                                  profile?.initials.isNotEmpty == true ? profile!.initials : 'H',
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
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nameText, style: AppText.sectionTitle.copyWith(fontSize: 15)),
                      Text(bioText, style: AppText.body.copyWith(fontSize: 10.5)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 13, color: AppColors.warning),
                          Text(
                            ' ${profile?.rating?.toStringAsFixed(2) ?? '4.98'} (${profile?.reviewCount ?? 0} reviews)',
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
                  onTap: () => Navigator.pushNamed(context, PerformanceInsightsScreen.route),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Host tier',
                          style: AppText.captionCaps
                              .copyWith(color: AppColors.primary)),
                      const SizedBox(height: 3),
                      Text(profile?.tier ?? 'Superhost',
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
                  onTap: () => Navigator.pushNamed(context, PerformanceInsightsScreen.route),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Response rate', style: AppText.captionCaps),
                      const SizedBox(height: 3),
                      Text(
                        '${profile?.responseRate?.toStringAsFixed(0) ?? '99'}% · Instant',
                        style: AppText.sectionTitle.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // FLEET & HOSTING SECTION
          _MenuSection(
            title: 'FLEET & HOSTING',
            items: [
              _MenuItem(
                icon: Icons.directions_car_filled_rounded,
                title: 'My Listings',
                subtitle: '$vehiclesCount Vehicles Listed',
                tag: '$vehiclesCount total',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FleetScreen()),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.add_circle_outline_rounded,
                title: 'Add New Vehicle',
                subtitle: 'Onboard a car, set daily rates & location',
                onTap: () => Navigator.pushNamed(context, VehicleDetailsScreen.route),
              ),
              _MenuItem(
                icon: Icons.insights_rounded,
                title: 'Listing Performance & Insights',
                subtitle: 'Circular chart, views, conversion & earnings boost',
                tag: 'NEW',
                onTap: () => Navigator.pushNamed(context, PerformanceInsightsScreen.route),
              ),
            ],
          ),
          // FINANCIAL & SECURITY SECTION
          _MenuSection(
            title: 'FINANCIAL & SECURITY',
            items: [
              _MenuItem(
                icon: Icons.account_balance_outlined,
                title: 'Payout & Bank Settings',
                subtitle: profile?.payoutMethod ?? 'UPI / Bank Transfer configured',
                onTap: () => Navigator.pushNamed(context, PayoutSetupScreen.route),
              ),
              _MenuItem(
                icon: Icons.receipt_long_outlined,
                title: 'Earnings Statements & Invoices',
                subtitle: 'Monthly PDF exports · GST/Tax ready',
                onTap: () => _showInfoDialog(
                  'Earnings Statements & Invoices',
                  'Your monthly GST invoices and payout receipts are generated automatically at the end of each billing cycle.',
                ),
              ),
              _MenuItem(
                icon: Icons.lock_outline_rounded,
                title: 'Security & Login',
                subtitle: 'Firebase Phone OTP & 256-bit Token Encrypted',
                onTap: () => _showInfoDialog(
                  'Security & Login',
                  'Your host account is secured with Firebase Phone Authentication and JWT Token Encryption.',
                ),
              ),
            ],
          ),
          // PREFERENCES SECTION
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
            ],
          ),
          // EXPERIENCE & SUPPORT SECTION
          _MenuSection(
            title: 'EXPERIENCE & SUPPORT',
            items: [
              _MenuItem(
                icon: Icons.swap_horiz_rounded,
                title: 'Switch to Guest Mode',
                subtitle: 'Browse rentals & book for personal trips',
                onTap: () {
                  ToastService.showInfo('Switching to Ayo Guest Mode...');
                },
              ),
              _MenuItem(
                icon: Icons.support_agent_rounded,
                title: 'Host Support & Concierge',
                subtitle: '24/7 dedicated helpline for Host Partners',
                tag: '24/7 Priority',
                onTap: () => _showSupportDialog(dash.supportConfig),
              ),
              _MenuItem(
                icon: Icons.shield_outlined,
                title: 'Terms & Host Protection Policy',
                subtitle: '₹1,00,00,000 Host Liability Protection Policy',
                onTap: () => _showPoliciesDialog(dash.platformPolicies),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
            child: Text('AYO Host v1.0.0 (Production Ready)',
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
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
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
    return Material(
      color: Colors.transparent,
      child: ListTile(
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
        onTap: item.onTap,
      ),
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
    return Material(
      color: Colors.transparent,
      child: ListTile(
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
      ),
    );
  }
}
