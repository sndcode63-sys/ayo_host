import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/host_service.dart';
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
        final status = await HostService.getOnboardingStatus();
        if (!mounted) return;
        final hasProfile = status.profileCompleted || status.profile != null;
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'AYO',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'AYO HOST',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Earn with your vehicle on your terms.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
