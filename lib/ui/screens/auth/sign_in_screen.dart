import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/controllers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../dashboard/main_shell.dart';

/// AYO Host Sign Up & Login — phone OTP + Apple/Google.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  static const route = '/sign-in';

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _phoneController = TextEditingController();
  bool _isSignInTab = true;
  String _countryCode = '+1';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final auth = context.read<AuthController>();
    final phone = '$_countryCode ${_phoneController.text.trim()}';
    final ok = await auth.signInWithPhone(phone);
    if (!mounted || !ok) return;
    // Mock OTP flow: any code verifies. Real flow would push an OTP screen.
    final verified = await auth.verifyOtp(phone, '000000');
    if (!mounted) return;
    if (verified) {
      Navigator.pushReplacementNamed(context, MainShell.route);
    }
  }

  Future<void> _social(String provider) async {
    final auth = context.read<AuthController>();
    final ok = await auth.socialSignIn(provider);
    if (mounted && ok) {
      Navigator.pushReplacementNamed(context, MainShell.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthController>().loading;

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
                  const Icon(Icons.arrow_back_rounded, size: 20),
                  const SizedBox(width: 10),
                  Text('HOST',
                      style: AppText.captionCaps
                          .copyWith(color: AppColors.primary)),
                  const SizedBox(width: 6),
                  Text('Sign In', style: AppText.sectionTitle),
                ],
              ),
              const SizedBox(height: 30),
              Text('HOST PORTAL',
                  style:
                      AppText.captionCaps.copyWith(color: AppColors.primary)),
              const SizedBox(height: 6),
              Text('Host on AYO', style: AppText.screenTitle),
              const SizedBox(height: 6),
              Text('Earn with your vehicle on your terms.',
                  style: AppText.body),
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
                          DropdownMenuItem(value: '+1', child: Text('+1')),
                          DropdownMenuItem(value: '+91', child: Text('+91')),
                        ],
                        onChanged: (v) =>
                            setState(() => _countryCode = v ?? '+1'),
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
                          hintText: '(415) 890-2341',
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
                "We'll text you a verification code to sign in or register.",
                style: AppText.body.copyWith(fontSize: 11),
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'Continue',
                icon: Icons.arrow_forward_rounded,
                loading: loading,
                onPressed: _continue,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or',
                        style: AppText.body
                            .copyWith(color: AppColors.textMuted)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  SocialButton(
                    label: 'Apple',
                    icon: Icons.apple_rounded,
                    onPressed: () => _social('apple'),
                  ),
                  const SizedBox(width: 10),
                  SocialButton(
                    label: 'Google',
                    icon: Icons.g_mobiledata_rounded,
                    onPressed: () => _social('google'),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: AppText.body.copyWith(fontSize: 11),
                    children: [
                      const TextSpan(text: 'Renting a vehicle? '),
                      TextSpan(
                        text: 'Switch to Guest →',
                        style: AppText.body.copyWith(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text.rich(
                  TextSpan(
                    style: AppText.body
                        .copyWith(fontSize: 9.5, color: AppColors.textMuted),
                    children: [
                      const TextSpan(
                          text: 'By continuing, you agree to the '),
                      TextSpan(
                        text: 'Host Terms',
                        style: TextStyle(color: AppColors.primary),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Vehicle Standards',
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
