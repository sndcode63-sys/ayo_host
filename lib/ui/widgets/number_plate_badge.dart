import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Cleanly formats raw Indian registration numbers into readable spaced format.
/// e.g. "KA04MN7821" -> "KA 04 MN 7821", "MH12AB1234" -> "MH 12 AB 1234"
String formatVehiclePlate(String raw) {
  final clean = raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  if (clean.isEmpty) return 'REG PENDING';

  final regExp = RegExp(r'^([A-Z]{2})([0-9]{1,2})([A-Z]{0,3})([0-9]{4})$');
  final match = regExp.firstMatch(clean);
  if (match != null) {
    final state = match.group(1) ?? '';
    final rto = match.group(2) ?? '';
    final series = match.group(3) ?? '';
    final num = match.group(4) ?? '';
    final parts = [state, rto, if (series.isNotEmpty) series, num];
    return parts.join(' ');
  }

  // If already separated or custom
  if (raw.trim().contains(' ')) {
    return raw.trim().toUpperCase();
  }
  return clean;
}

/// Official AYO Branded Number Plate Badge.
/// Displays "AYO" on the brand red background on the left,
/// and the vehicle's registration number on the right.
class AyoNumberPlateBadge extends StatelessWidget {
  const AyoNumberPlateBadge({
    super.key,
    required this.plate,
    this.compact = false,
    this.isOverlay = false,
    this.customAyoText = 'AYO',
  });

  final String plate;
  final bool compact;
  final bool isOverlay;
  final String customAyoText;

  @override
  Widget build(BuildContext context) {
    final formatted = formatVehiclePlate(plate);
    final ayoFontSize = compact ? 9.0 : 11.0;
    final plateFontSize = compact ? 10.0 : 12.5;
    final verticalPad = compact ? 2.5 : 4.0;
    final ayoHorizontalPad = compact ? 6.0 : 8.0;
    final plateHorizontalPad = compact ? 8.0 : 10.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 5 : 7),
        border: Border.all(
          color: const Color(0xFF1E2022),
          width: compact ? 1.0 : 1.3,
        ),
        boxShadow: isOverlay
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.38),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Red "AYO" background container
              Container(
                color: AppColors.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: ayoHorizontalPad,
                  vertical: verticalPad,
                ),
                alignment: Alignment.center,
                child: Text(
                  customAyoText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ayoFontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    height: 1.1,
                  ),
                ),
              ),
              // Vertical divider line
              Container(
                width: compact ? 1.0 : 1.2,
                color: const Color(0xFF1E2022),
              ),
              // Registration Number container
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: plateHorizontalPad,
                  vertical: verticalPad,
                ),
                alignment: Alignment.center,
                child: Text(
                  formatted,
                  style: TextStyle(
                    color: const Color(0xFF15131A),
                    fontSize: plateFontSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
