import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/services/toast_service.dart';
import '../../../core/utils/animation_utils.dart';
import '../../../state/controllers.dart';
import '../../widgets/buttons.dart';
import '../../widgets/app_image_view.dart';
import '../dashboard/main_shell.dart';
import '../onboarding/host_profile_setup_screen.dart';

/// AYO Host Login — Red Theme matching official AYO design with MSG91 OTP Widget.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  static const route = '/sign-in';

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _phoneController = TextEditingController();
  static const String _countryCode = '+91';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _routeAfterAuth() {
    AppImageCache.clear();
    context.read<DashboardController>().reset();
    context.read<ProfileController>().reset();
    context.read<EarningsController>().reset();
    context.read<NotificationController>().reset();
    context.read<OnboardingController>().resetVehicleDraft();

    final auth = context.read<AuthController>();
    final status = auth.onboardingStatus;

    final hasProfile = (status?.profileCompleted == true) ||
        (status?.profile != null && status!.profile!.firstName.isNotEmpty) ||
        (auth.host != null && auth.host!.firstName.isNotEmpty) ||
        (auth.user?.name != null && auth.user!.name!.isNotEmpty);

    if (!hasProfile) {
      ToastService.showSuccess('Welcome! Please complete your host profile.');
      AnimationUtils.pushAndRemoveUntil(context, const HostProfileSetupScreen());
    } else {
      ToastService.showSuccess('Welcome back!');
      AnimationUtils.pushAndRemoveUntil(context, const MainShell());
    }
  }

  Future<void> _sendOtp() async {
    String rawPhone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (rawPhone.length > 10 && rawPhone.startsWith('91')) {
      rawPhone = rawPhone.substring(rawPhone.length - 10);
    }

    if (rawPhone.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(rawPhone)) {
      ToastService.showWarning('Please enter a valid 10-digit Indian mobile number (e.g. 9876543210)');
      return;
    }

    final formattedPhone = '$_countryCode$rawPhone';
    final auth = context.read<AuthController>();
    final sent = await auth.sendPhoneOtp(formattedPhone);

    if (mounted && sent) {
      _openOtpBottomSheet(formattedPhone, rawPhone);
    }
  }

  void _openOtpBottomSheet(String fullPhone, String rawPhone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _OtpBottomSheetContent(
          fullPhone: fullPhone,
          rawPhone: rawPhone,
          onSuccess: () {
            Navigator.pop(ctx);
            _routeAfterAuth();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final loading = auth.loading;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFFE001A),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: const Color(0xFFFE001A),
        ),
        child: Stack(
          children: [
            // 1. Bottom Graphic (City skyline, white car, red motorcycle & curved red road)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/images/auth_city_cars_cropped.png',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),

            // 2. Foreground Form & Content
            SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: screenHeight - 60),
                  child: Column(
                    children: [
                      const SizedBox(height: 38),

                      // AYO Brand Logo Card
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tagline
                      const Text(
                        'Bike & Car Rental',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Subtitle
                      Text(
                        'Enter your mobile number to continue',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // White Form Card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 26,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Mobile Number Input with Indian Flag
                            Container(
                              height: 54,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F5F7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Text('🇮🇳', style: TextStyle(fontSize: 18)),
                                        SizedBox(width: 6),
                                        Text(
                                          '+91',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E2022),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        SizedBox(
                                          height: 24,
                                          child: VerticalDivider(
                                            color: Color(0xFFDCDFE4),
                                            width: 1,
                                            thickness: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      maxLength: 10,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E2022),
                                      ),
                                      decoration: const InputDecoration(
                                        counterText: '',
                                        hintText: 'Enter mobile number',
                                        hintStyle: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF9EA3AE),
                                          fontWeight: FontWeight.normal,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                                      ),
                                      onSubmitted: (_) {
                                        if (!loading) _sendOtp();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Send OTP Pill Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: loading ? null : _sendOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFE001A),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                ),
                                child: loading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Text(
                                            'Send OTP',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_rounded, size: 20),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Terms and Conditions text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'By continuing, you agree to our Terms & Conditions &\nPrivacy Policy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 11.5,
                            height: 1.45,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),

                      // Spacer ensuring bottom car graphic is never covered by the card
                      const SizedBox(height: 240),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpBottomSheetContent extends StatefulWidget {
  const _OtpBottomSheetContent({
    required this.fullPhone,
    required this.rawPhone,
    required this.onSuccess,
  });

  final String fullPhone;
  final String rawPhone;
  final VoidCallback onSuccess;

  @override
  State<_OtpBottomSheetContent> createState() => _OtpBottomSheetContentState();
}

class _OtpBottomSheetContentState extends State<_OtpBottomSheetContent> {
  final TextEditingController _masterOtpController = TextEditingController();
  final FocusNode _masterFocusNode = FocusNode();
  int _secondsRemaining = 30;
  Timer? _timer;
  String? _detectedClipboardOtp;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _checkClipboardForOtp();

    // Request autofocus after sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _masterFocusNode.requestFocus();
    });
  }

  Future<void> _checkClipboardForOtp() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      final match = RegExp(r'\b\d{6}\b').firstMatch(text);
      if (match != null && mounted) {
        setState(() {
          _detectedClipboardOtp = match.group(0);
        });
      }
    } catch (_) {}
  }

  void _applyOtp(String code) {
    final digits = code.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 6) {
      final valid6 = digits.substring(0, 6);
      _masterOtpController.text = valid6;
      setState(() => _errorMessage = null);
      _verifyOtp();
    }
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
    _masterOtpController.dispose();
    _masterFocusNode.dispose();
    super.dispose();
  }

  String get _otpCode => _masterOtpController.text.trim();

  Future<void> _verifyOtp() async {
    final code = _otpCode;
    if (code.length < 6) {
      setState(() {
        _errorMessage = 'Please enter full 6-digit OTP code';
      });
      ToastService.showWarning('Please enter full 6-digit OTP code');
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    final auth = context.read<AuthController>();
    final verified = await auth.verifyOtpCode(code);

    if (!mounted) return;

    if (verified) {
      try {
        TextInput.finishAutofillContext();
      } catch (_) {}
      widget.onSuccess();
    } else {
      final rawErr = auth.error ?? '';
      String displayMsg = 'Invalid OTP code. Please check and retry.';
      if (rawErr.contains('already registered as a Customer') ||
          rawErr.contains('registered for Customer') ||
          rawErr.contains('CUSTOMER')) {
        displayMsg =
            'This mobile number is already registered for Customer. Please use a Host account or register with a different number.';
      } else if (rawErr.contains('INVALID_OTP')) {
        displayMsg =
            'Incorrect OTP code. Please enter the valid code sent to your phone.';
      } else if (rawErr.contains('TOO_MANY_ATTEMPTS')) {
        displayMsg =
            'Too many attempts. Please tap Resend to receive a fresh code.';
      } else if (rawErr.isNotEmpty) {
        displayMsg = rawErr.replaceFirst('Exception: ', '').trim();
      }

      setState(() {
        _errorMessage = displayMsg;
      });
      ToastService.showError(displayMsg);
    }
  }

  Future<void> _retryVia(bool viaVoice) async {
    final auth = context.read<AuthController>();
    final ok = await auth.retryPhoneOtp(viaVoice: viaVoice);
    if (mounted && ok) {
      _startCountdown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthController>().loading;
    final otpText = _masterOtpController.text;
    final hasError = _errorMessage != null && _errorMessage!.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Cars Illustration at the Bottom of OTP Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: -20,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.22,
                child: Image.asset(
                  'assets/images/auth_city_cars_cropped.png',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Main OTP Content
          AutofillGroup(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCDFE4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: const [
                      Icon(Icons.mark_chat_read_rounded, color: Color(0xFFFE001A), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'OTP Verification',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E2022),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter 6-digit code sent to ${widget.fullPhone}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // 6 PIN Input Boxes with native SMS Autofill & Paste support
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. Visual 6 PIN Boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          final hasChar = index < otpText.length;
                          final isFocused = _masterFocusNode.hasFocus &&
                              (index == otpText.length || (index == 5 && otpText.length == 6));
                          final char = hasChar ? otpText[index] : '';

                          return Container(
                            width: 44,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F5F7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: hasError
                                    ? const Color(0xFFFE001A)
                                    : (isFocused
                                        ? const Color(0xFFFE001A)
                                        : (hasChar
                                            ? const Color(0xFFFE001A).withValues(alpha: 0.5)
                                            : const Color(0xFFE2E4E8))),
                                width: hasError || isFocused ? 2.0 : 1.0,
                              ),
                            ),
                            child: Text(
                              char,
                              style: const TextStyle(
                                fontSize: 22,
                                color: Color(0xFFFE001A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }),
                      ),

                      // 2. Invisible master input field for keyboard, paste, and Android SMS autofill
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.0,
                          child: TextField(
                            controller: _masterOtpController,
                            focusNode: _masterFocusNode,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                            ),
                            onChanged: (val) {
                              if (_errorMessage != null) {
                                setState(() => _errorMessage = null);
                              } else {
                                setState(() {});
                              }
                              if (val.trim().length == 6) {
                                _verifyOtp();
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Prominent inline error container if OTP verification fails
                  if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECEE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFE001A).withValues(alpha: 0.4),
                          width: 1.1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFFE001A),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFFE001A),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Quick Auto-fill button if OTP is detected in clipboard
                  if (_detectedClipboardOtp != null && otpText.length < 6) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: InkWell(
                        onTap: () => _applyOtp(_detectedClipboardOtp!),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFE001A).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFE001A).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFFFE001A)),
                              const SizedBox(width: 6),
                              Text(
                                'Auto-fill OTP from SMS: $_detectedClipboardOtp',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFFE001A),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Change Number',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF757575),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_secondsRemaining > 0)
                        Text(
                          'Resend in ${_secondsRemaining}s',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF757575),
                          ),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              onPressed: () => _retryVia(false),
                              icon: const Icon(Icons.sms_outlined, size: 14, color: Color(0xFFFE001A)),
                              label: const Text(
                                'Resend SMS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFE001A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            TextButton.icon(
                              onPressed: () => _retryVia(true),
                              icon: const Icon(Icons.phone_in_talk_rounded, size: 14, color: Color(0xFFFE001A)),
                              label: const Text(
                                'Get OTP on Call',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFE001A),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  PrimaryButton(
                    label: 'Verify OTP & Continue',
                    icon: Icons.check_circle_rounded,
                    loading: loading,
                    onPressed: _verifyOtp,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
