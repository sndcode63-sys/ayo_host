import 'package:flutter/material.dart';

/// AYO Host design tokens.
///
/// Brand red stays the single accent. Deep ink carries weight (hero surfaces,
/// navigation) so red can be used sparingly for actions and status.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFFE60012);
  static const Color primaryDark = Color(0xFFB5000E);
  static const Color primarySoft = Color(0xFFFDECEE);
  static const Color primaryBorder = Color(0xFFF6C9CE);

  // Ink (premium dark surfaces)
  static const Color ink = Color(0xFF15131A);
  static const Color inkRaised = Color(0xFF1F1C26);
  static const Color inkBorder = Color(0xFF2D2935);

  // Surfaces
  static const Color background = Color(0xFFF5F5F8);
  static const Color card = Colors.white;
  static const Color cardBorder = Color(0xFFE9E8EE);

  // Text
  static const Color textPrimary = Color(0xFF15131A);
  static const Color textSecondary = Color(0xFF5F5B6B);
  static const Color textMuted = Color(0xFF8E8A9A);

  // Fields
  static const Color fieldFill = Color(0xFFFFFFFF);
  static const Color fieldBorder = Color(0xFFDEDCE5);
  static const Color fieldMuted = Color(0xFFF0EFF4);

  // Status
  static const Color success = Color(0xFF14804A);
  static const Color successSoft = Color(0xFFE2F4EA);
  static const Color warning = Color(0xFFB86A00);
  static const Color warningSoft = Color(0xFFFCF0DB);

  static const Color navInactive = Color(0xFF8E8A9A);
  static const Color divider = Color(0xFFEDECF1);
}

/// Radius scale: larger surfaces get larger radii.
class AppRadius {
  AppRadius._();

  static const double chip = 12;
  static const double field = 14;
  static const double button = 16;
  static const double card = 20;
  static const double sheet = 28;
}

/// Shadow recipes. Layered and low-opacity so surfaces float without looking heavy.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => [
        BoxShadow(
          color: const Color(0xFF15131A).withValues(alpha: 0.04),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: const Color(0xFF15131A).withValues(alpha: 0.05),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get floating => [
        BoxShadow(
          color: const Color(0xFF15131A).withValues(alpha: 0.28),
          blurRadius: 32,
          offset: const Offset(0, 14),
        ),
      ];

  static List<BoxShadow> get cta => [
        BoxShadow(
          color: const Color(0xFFE60012).withValues(alpha: 0.32),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}
