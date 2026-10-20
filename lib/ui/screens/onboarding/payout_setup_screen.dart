import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/controllers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/chrome.dart';
import '../dashboard/main_shell.dart';
import '../../../data/services/host_service.dart';
import '../../../core/services/toast_service.dart';

/// AYO Host Payout & Bank Verification — Host Onboarding (Step 2 of 2).
class PayoutSetupScreen extends StatefulWidget {
  const PayoutSetupScreen({super.key});

  static const route = '/onboarding/payout';

  @override
  State<PayoutSetupScreen> createState() => _PayoutSetupScreenState();
}

class _PayoutSetupScreenState extends State<PayoutSetupScreen> {
  final _upiController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _accountHolderController = TextEditingController();
  bool _upiTab = true;
  bool _isSavingPayout = false;

  @override
  void dispose() {
    _upiController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final ctrl = context.read<OnboardingController>();
    final upi = _upiController.text.trim();
    if (upi.isEmpty) {
      ToastService.showWarning('Please enter a UPI ID (e.g. name@upi)');
      return;
    }
    await ctrl.verifyUpi(upi);
  }

  Future<void> _finishPayoutSetup() async {
    setState(() => _isSavingPayout = true);
    try {
      if (_upiTab) {
        final upi = _upiController.text.trim();
        if (upi.isEmpty) {
          ToastService.showWarning('Please enter your UPI ID');
          setState(() => _isSavingPayout = false);
          return;
        }
        await HostService.savePayoutMethod(
          payoutMethod: 'UPI',
          upiId: upi,
        );
      } else {
        final acc = _accountNumberController.text.trim();
        final ifsc = _ifscController.text.trim();
        final name = _accountHolderController.text.trim();
        if (acc.isEmpty || ifsc.isEmpty || name.isEmpty) {
          ToastService.showWarning('Please enter all bank account details');
          setState(() => _isSavingPayout = false);
          return;
        }
        await HostService.savePayoutMethod(
          payoutMethod: 'BANK',
          accountNumber: acc,
          ifscCode: ifsc,
          accountHolderName: name,
        );
      }

      ToastService.showSuccess('Payout setup complete!');
      if (mounted) {
        Navigator.pushReplacementNamed(context, MainShell.route);
      }
    } catch (e) {
      // Toast shown by error interceptor
    } finally {
      if (mounted) setState(() => _isSavingPayout = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ob = context.watch<OnboardingController>();
    final profile = context.watch<ProfileController>().profile;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            const StepHeader(
              step: 2,
              totalSteps: 2,
              title: 'AYO Host Onboarding',
              subtitle: 'Step 2 of 2 · Payout Setup',
              rightTag: 'Final Step',
            ),
            const SizedBox(height: 20),
            Text('Verify Payout Details', style: AppText.screenTitle),
            const SizedBox(height: 4),
            Text(
              'Choose how you would like to receive your host rental earnings. Payouts are transferred automatically upon trip completion.',
              style: AppText.body.copyWith(fontSize: 11),
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _Tab(
                    label: 'UPI ID',
                    tag: 'Instant',
                    selected: _upiTab,
                    icon: Icons.bolt_rounded,
                    onTap: () => setState(() => _upiTab = true),
                  ),
                  _Tab(
                    label: 'Bank Account',
                    selected: !_upiTab,
                    icon: Icons.account_balance_outlined,
                    onTap: () => setState(() => _upiTab = false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_upiTab) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('UPI ID / VIRTUAL PAYMENT ADDRESS',
                      style: AppText.fieldLabel),
                  Text('Zero processing fee',
                      style: AppText.captionCaps
                          .copyWith(color: AppColors.success, fontSize: 8.5)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _upiController,
                      style: AppText.input.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'yourname@upi',
                        filled: true,
                        fillColor: AppColors.card,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        prefixIcon: const Icon(Icons.alternate_email_rounded,
                            size: 17, color: AppColors.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.primaryBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.primaryBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: ob.verifyingUpi ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: ob.verifyingUpi
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Verify',
                              style: AppText.button.copyWith(fontSize: 12)),
                    ),
                  ),
                ],
              ),
              if (profile != null && profile.fullName.isNotEmpty) ...[
                const SizedBox(height: 12),
                AppCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_outlined,
                          size: 17, color: AppColors.success),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Registered Host Name',
                                style: AppText.captionCaps.copyWith(fontSize: 8.5)),
                            Text(profile.fullName,
                                style: AppText.input
                                    .copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      if (ob.upiVerified)
                        const StatusPill(
                            label: 'Verified', kind: StatusKind.danger),
                    ],
                  ),
                ),
              ],
            ] else ...[
              Text('BANK ACCOUNT NUMBER', style: AppText.fieldLabel),
              const SizedBox(height: 6),
              TextField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'e.g. 50100234567890',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Text('IFSC CODE', style: AppText.fieldLabel),
              const SizedBox(height: 6),
              TextField(
                controller: _ifscController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'e.g. HDFC0001234',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Text('ACCOUNT HOLDER NAME', style: AppText.fieldLabel),
              const SizedBox(height: 6),
              TextField(
                controller: _accountHolderController,
                decoration: const InputDecoration(
                  hintText: 'Full Name on Bank Record',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 18),
            AppCard(
              color: AppColors.warningSoft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.currency_rupee_rounded,
                      size: 17, color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Penny Drop Verification',
                            style: AppText.sectionTitle
                                .copyWith(fontSize: 12.5)),
                        const SizedBox(height: 3),
                        Text(
                          'AYO will send a test credit of ₹1.00 to verify that the account matches your official records before initiating payouts.',
                          style: AppText.body.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Verify & Finish Setup',
              icon: Icons.check_circle_rounded,
              loading: _isSavingPayout,
              onPressed: _finishPayoutSetup,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {
                  ToastService.showInfo('You can configure payout anytime in Settings');
                  Navigator.pushReplacementNamed(context, MainShell.route);
                },
                child: Text('Set up payout later in Settings',
                    style: AppText.body.copyWith(
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                        color: AppColors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
    this.tag,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: selected ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            border: selected
                ? Border.all(color: AppColors.primary, width: 1.1)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15,
                  color: selected ? AppColors.primary : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: AppText.body.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textMuted)),
              if (tag != null && selected) ...[
                const SizedBox(width: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(tag!,
                      style: AppText.captionCaps.copyWith(
                          color: AppColors.primary, fontSize: 7.5)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
