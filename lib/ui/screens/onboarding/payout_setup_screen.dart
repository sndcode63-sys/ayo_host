import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/controllers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/chrome.dart';
import '../documents/vehicle_documents_screen.dart';

/// AYO Host Payout & Bank Verification — Host Onboarding (Step 2 of 2).
class PayoutSetupScreen extends StatefulWidget {
  const PayoutSetupScreen({super.key});

  static const route = '/onboarding/payout';

  @override
  State<PayoutSetupScreen> createState() => _PayoutSetupScreenState();
}

class _PayoutSetupScreenState extends State<PayoutSetupScreen> {
  final _upiController = TextEditingController(text: 'marcus.vance@okaxis');
  bool _upiTab = true;

  @override
  void dispose() {
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final ctrl = context.read<OnboardingController>();
    final ok = await ctrl.verifyUpi(_upiController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'UPI ID verified · Penny drop successful'
            : 'Could not verify this UPI ID'),
        backgroundColor: ok ? AppColors.success : AppColors.primary,
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
            const StepHeader(
              step: 2,
              totalSteps: 2,
              title: 'AYO  Host Onboarding',
              subtitle: 'Step 2 of 2 · Payout Setup',
              rightTag: 'Final Step',
            ),
            const SizedBox(height: 20),
            Text('Verify Payout Details', style: AppText.screenTitle),
            const SizedBox(height: 4),
            Text(
              'Choose how you would like to receive your host rental earnings. Payouts are transferred automatically within 24 hours of trip completion.',
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
                        Text('Registered Account Name',
                            style: AppText.captionCaps.copyWith(fontSize: 8.5)),
                        Text('Marcus Vance',
                            style: AppText.input
                                .copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  if (ob.upiVerified)
                    const StatusPill(
                        label: 'Active', kind: StatusKind.danger),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('SUPPORTED UPI PROVIDERS', style: AppText.fieldLabel),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _ProviderLogo('GPay', Color(0xFF4285F4)),
                _ProviderLogo('PhonePe', Color(0xFF5F259F)),
                _ProviderLogo('Paytm', Color(0xFF00B9F1)),
                _ProviderLogo('BHIM', Color(0xFFED752E)),
              ],
            ),
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
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 5),
                Text('256-bit SSL\nEncrypted Data',
                    style: AppText.captionCaps.copyWith(fontSize: 8)),
                const SizedBox(width: 18),
                const Icon(Icons.verified_outlined,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 5),
                Text('RBI Compliant\nDirect Transfer',
                    style: AppText.captionCaps.copyWith(fontSize: 8)),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Verify & Finish Setup',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => Navigator.pushNamed(
                  context, VehicleDocumentsScreen.route),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () =>
                    Navigator.popUntil(context, (r) => r.isFirst),
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

class _ProviderLogo extends StatelessWidget {
  const _ProviderLogo(this.name, this.color);

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        name,
        style: AppText.body.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
