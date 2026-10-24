import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/host_service.dart';
import '../../../state/controllers.dart';
import '../dashboard/main_shell.dart';
import '../onboarding/host_profile_setup_screen.dart';
import 'sign_in_screen.dart';

/// Red splash shown at cold start; auto-routes to Sign In or Home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const route = '/splash';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    Future.delayed(const Duration(milliseconds: 1800), () async {
      if (!mounted) return;

      final isAuth = await AuthService.isAuthenticated();

      if (!mounted) return;

      if (!isAuth) {
        Navigator.pushReplacementNamed(context, SignInScreen.route);
        return;
      }

      try {
        await context.read<AuthController>().checkSession();
        if (!mounted) return;

        final status = await HostService.getOnboardingStatus();
        if (!mounted) return;

        final hasProfile = status.profileCompleted ||
            (status.profile != null && status.profile!.firstName.isNotEmpty);

        if (!hasProfile) {
          Navigator.pushReplacementNamed(context, HostProfileSetupScreen.route);
        } else {
          Navigator.pushReplacementNamed(context, MainShell.route);
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, MainShell.route);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Soft brand glow behind the mark.
          Align(
            alignment: const Alignment(0, -0.25),
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.38),
                    AppColors.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1).animate(_scale),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 40,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'AYO',
                        style: GoogleFonts.manrope(
                          fontSize: 29,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'AYO Host',
                      style: GoogleFonts.manrope(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Earn with your vehicle on your terms.',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
