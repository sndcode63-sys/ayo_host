import 'package:flutter/material.dart';

class AppToast {
  AppToast._();

  static GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void show(
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    Color accent;
    IconData icon;
    switch (type) {
      case ToastType.success:
        accent = const Color(0xFF2FD071);
        icon = Icons.check_circle_rounded;
        break;
      case ToastType.error:
        accent = const Color(0xFFFF4D5A);
        icon = Icons.error_rounded;
        break;
      case ToastType.warning:
        accent = const Color(0xFFFFB020);
        icon = Icons.warning_rounded;
        break;
      case ToastType.info:
        accent = const Color(0xFF9DA3FF);
        icon = Icons.info_rounded;
        break;
    }

    final messenger = messengerKey.currentState;
    if (messenger != null) {
      messenger.removeCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF15131A),
          elevation: 8,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: accent.withValues(alpha: 0.35)),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          duration: duration,
        ),
      );
    }
  }

  static void showSuccess(String message) {
    show(message, type: ToastType.success);
  }

  static void showError(String message) {
    show(message, type: ToastType.error, duration: const Duration(seconds: 4));
  }

  static void showInfo(String message) {
    show(message, type: ToastType.info);
  }

  static void showWarning(String message) {
    show(message, type: ToastType.warning);
  }
}

enum ToastType {
  success,
  error,
  info,
  warning,
}
