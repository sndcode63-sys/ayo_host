import 'dart:async';
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

/// AYO Host Sign Up & Login — India Only (+91) Phone Auth + OTP BottomSheet.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  static const route = '/sign-in';

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _phoneController = TextEditingController();
  bool _isSignInTab = true;
  static const String _countryCode = '+91';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _routeAfterAuth() {
    final auth = context.read<AuthController>();
    final status = auth.onboardingStatus;

    final hasProfile = (status?.profileCompleted == true) ||
        (status?.profile != null && status!.profile!.firstName.isNotEmpty) ||
        (auth.host != null && auth.host!.firstName.isNotEmpty) ||
        (auth.user?.name != null && auth.user!.name!.isNotEmpty);

    if (!hasProfile) {
      ToastService.showSuccess('Welcome! Please complete your host profile.');
      Navigator.pushReplacementNamed(context, HostProfileSetupScreen.route);
    } else {
      ToastService.showSuccess('Welcome back!');
      Navigator.pushReplacementNamed(context, MainShell.route);
    }
  }

  Future<void> _sendOtp() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(rawPhone)) {
      ToastService.showWarning('Please enter a valid 10-digit Indian mobile number (e.g. 9876543210)');
      return;
    }

    final formattedPhone = '$_countryCode$rawPhone';
    final auth = context.read<AuthController>();
    final sent = await auth.sendPhoneOtp(formattedPhone);

    if (mounted && sent) {
      _openOtpBottomSheet(formattedPhone);
    }
  }

  void _openOtpBottomSheet(String fullPhone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _OtpBottomSheetContent(
          fullPhone: fullPhone,
          onSuccess: () {
            Navigator.pop(ctx);
            _routeAfterAuth();
          },
          onResend: () async {
            final auth = context.read<AuthController>();
            await auth.sendPhoneOtp(fullPhone);
          },
        ),
      ),
    );
  }

  Future<void> _quickHostLogin() async {
    final auth = context.read<AuthController>();
    ToastService.showInfo('Logging in with Host Session...');

    final success = await auth.quickLoginHost();
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
                  style: AppText.captionCaps.copyWith(color: AppColors.primary)),
              const SizedBox(height: 6),
              Text(
                _isSignInTab ? 'Welcome to AYO Host' : 'Become an AYO Host',
                style: AppText.screenTitle,
              ),
              const SizedBox(height: 6),
              Text(
                'Earn with your vehicle on your terms. Instant payouts.',
                style: AppText.body,
              ),
              const SizedBox(height: 24),
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
              Text('MOBILE NUMBER', style: AppText.fieldLabel),
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
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🇮🇳 ', style: TextStyle(fontSize: 16)),
                        Text('+91 (IN)',
                            style: AppText.input.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        style: AppText.input,
                        decoration: InputDecoration(
                          counterText: '',
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
                    ? "We'll send you a 6-digit OTP on WhatsApp / SMS to verify."
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
                onPressed: loading ? null : _quickHostLogin,
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
                      'Direct Host Quick Login (Bypass OTP)',
                      style: AppText.body.copyWith(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
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

class _OtpBottomSheetContent extends StatefulWidget {
  const _OtpBottomSheetContent({
    required this.fullPhone,
    required this.onSuccess,
    required this.onResend,
  });

  final String fullPhone;
  final VoidCallback onSuccess;
  final VoidCallback onResend;

  @override
  State<_OtpBottomSheetContent> createState() => _OtpBottomSheetContentState();
}

class _OtpBottomSheetContentState extends State<_OtpBottomSheetContent> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _secondsRemaining = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _secondsRemaining = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final fn in _focusNodes) {
      fn.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    final code = _otpCode.trim();
    if (code.length < 6) {
      ToastService.showWarning('Please enter full 6-digit OTP code');
      return;
    }

    final auth = context.read<AuthController>();
    final verified = await auth.verifyOtpCode(code);

    if (mounted && verified) {
      widget.onSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthController>().loading;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.fieldBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.mark_chat_read_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text('OTP Verification', style: AppText.screenTitle.copyWith(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Enter 6-digit code sent to ${widget.fullPhone}',
            style: AppText.body.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 20),
          // 6 PIN Input Boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 44,
                height: 52,
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: AppText.screenTitle.copyWith(fontSize: 20, color: AppColors.primary),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.fieldFill,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.fieldBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.fieldBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty && index < 5) {
                      _focusNodes[index + 1].requestFocus();
                    } else if (val.isEmpty && index > 0) {
                      _focusNodes[index - 1].requestFocus();
                    }
                    if (_otpCode.length == 6) {
                      _verifyOtp();
                    }
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Change Number', style: AppText.body.copyWith(fontSize: 11, color: AppColors.textMuted)),
              ),
              TextButton(
                onPressed: _secondsRemaining > 0
                    ? null
                    : () {
                        widget.onResend();
                        _startCountdown();
                      },
                child: Text(
                  _secondsRemaining > 0
                      ? 'Resend in ${_secondsRemaining}s'
                      : 'Resend OTP',
                  style: AppText.body.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _secondsRemaining > 0 ? AppColors.textMuted : AppColors.primary,
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
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppText.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
