import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/toast_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/controllers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../dashboard/main_shell.dart';
import '../onboarding/host_profile_setup_screen.dart';
import '../onboarding/payout_setup_screen.dart';

/// AYO Host Sign Up & Login — Phone OTP verification + Ayo backend token exchange.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  static const route = '/sign-in';

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isSignInTab = true;
  String _countryCode = '+91';
  bool _otpSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _routeAfterAuth() {
    final auth = context.read<AuthController>();
    final status = auth.onboardingStatus;

    if (status == null || !status.profileCompleted) {
      ToastService.showSuccess('Welcome! Please complete your host profile.');
      Navigator.pushReplacementNamed(context, HostProfileSetupScreen.route);
    } else if (!status.payoutCompleted) {
      ToastService.showInfo('Please configure your payout method.');
      Navigator.pushReplacementNamed(context, PayoutSetupScreen.route);
    } else {
      ToastService.showSuccess('Welcome back!');
      Navigator.pushReplacementNamed(context, MainShell.route);
    }
  }

  Future<void> _sendOtp() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      ToastService.showWarning('Please enter your phone number');
      return;
    }

    final formattedPhone = '$_countryCode$rawPhone';
    final auth = context.read<AuthController>();
    final sent = await auth.sendPhoneOtp(formattedPhone);

    if (mounted && sent) {
      setState(() {
        _otpSent = true;
      });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      ToastService.showWarning('Please enter a valid 6-digit OTP');
      return;
    }

    final auth = context.read<AuthController>();
    final verified = await auth.verifyOtpCode(otp);

    if (mounted && verified) {
      _routeAfterAuth();
    }
  }

  Future<void> _devMockContinue() async {
    final rawPhone = _phoneController.text.trim().isEmpty
        ? '9876543210'
        : _phoneController.text.trim();
    final fullPhone = '$_countryCode$rawPhone';

    final auth = context.read<AuthController>();
    ToastService.showInfo('Using Dev Mock Auth: $fullPhone');

    final success = await auth.devMockLogin(fullPhone);
    if (mounted && success) {
      _routeAfterAuth();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final loading = auth.loading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),
              Row(
                children: [
                  if (_otpSent)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      onPressed: () => setState(() => _otpSent = false),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  else
                    const Icon(Icons.shield_outlined, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('HOST',
                      style: AppText.captionCaps
                          .copyWith(color: AppColors.primary)),
                  const SizedBox(width: 6),
                  Text(_isSignInTab ? 'Sign In' : 'Create Account',
                      style: AppText.sectionTitle),
                ],
              ),
              const SizedBox(height: 28),
              Text('HOST PORTAL',
                  style:
                      AppText.captionCaps.copyWith(color: AppColors.primary)),
              const SizedBox(height: 6),
              Text(
                _otpSent
                    ? 'Enter Verification Code'
                    : (_isSignInTab ? 'Welcome to AYO Host' : 'Become an AYO Host'),
                style: AppText.screenTitle,
              ),
              const SizedBox(height: 6),
              Text(
                _otpSent
                    ? 'We have sent a 6-digit SMS OTP to $_countryCode ${_phoneController.text.trim()}'
                    : 'Earn with your vehicle on your terms. Instant payouts.',
                style: AppText.body,
              ),
              const SizedBox(height: 24),
              if (!_otpSent) ...[
                AppCard(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _TabPill(
                        label: 'Sign In',
                        selected: _isSignInTab,
                        onTap: () => setState(() => _isSignInTab = true),
                      ),
                      _TabPill(
                        label: 'Create Account',
                        selected: !_isSignInTab,
                        onTap: () => setState(() => _isSignInTab = false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text('PHONE NUMBER', style: AppText.fieldLabel),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.fieldBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _countryCode,
                          items: const [
                            DropdownMenuItem(value: '+91', child: Text('+91 (IN)')),
                            DropdownMenuItem(value: '+1', child: Text('+1 (US)')),
                          ],
                          onChanged: (v) =>
                              setState(() => _countryCode = v ?? '+91'),
                          style: AppText.input,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: AppText.input,
                          decoration: InputDecoration(
                            hintText: '9876543210',
                            hintStyle: AppText.input
                                .copyWith(color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.fieldFill,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.fieldBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.fieldBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 1.2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _isSignInTab
                      ? "We'll send you an OTP to verify your host account."
                      : "By creating an account, you get instant access to list vehicles.",
                  style: AppText.body.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: _isSignInTab ? 'Get OTP & Sign In' : 'Get OTP & Create Account',
                  icon: Icons.sms_rounded,
                  loading: loading,
                  onPressed: _sendOtp,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: loading ? null : _devMockContinue,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flash_on_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Dev Fast Login / Sign Up (Mock OTP)',
                        style: AppText.body.copyWith(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // OTP Input Box
                Text('6-DIGIT VERIFICATION CODE', style: AppText.fieldLabel),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: AppText.screenTitle.copyWith(
                      letterSpacing: 10,
                      fontSize: 22,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '------',
                      hintStyle: AppText.screenTitle.copyWith(
                        letterSpacing: 10,
                        color: AppColors.textMuted,
                      ),
                      filled: true,
                      fillColor: AppColors.fieldFill,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.fieldBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.fieldBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _otpSent = false),
                      child: Text(
                        'Change Number',
                        style: AppText.body.copyWith(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: loading ? null : _sendOtp,
                      child: Text(
                        'Resend OTP',
                        style: AppText.body.copyWith(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Verify OTP & Continue',
                  icon: Icons.check_circle_rounded,
                  loading: loading,
                  onPressed: _verifyOtp,
                ),
              ],
              const SizedBox(height: 24),
              Center(
                child: Text.rich(
                  TextSpan(
                    style: AppText.body
                        .copyWith(fontSize: 10, color: AppColors.textMuted),
                    children: const [
                      TextSpan(
                          text: 'By continuing, you agree to DPDP Act consent and '),
                      TextSpan(
                        text: 'AYO Host Terms & Conditions',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppText.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
