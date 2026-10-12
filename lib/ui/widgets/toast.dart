import 'package:flutter/material.dart';

class AppToast {
  AppToast._();

  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  static void show(
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (_isShowing) {
      _overlayEntry?.remove();
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        onDismiss: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
          _isShowing = false;
        },
      ),
    );

    _isShowing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Overlay.of(WidgetsBinding.instance.rootElement!).insert(_overlayEntry!);
    });

    Future.delayed(duration, () {
      if (_isShowing) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        _isShowing = false;
      }
    });
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

class _ToastWidget extends StatelessWidget {
  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  final String message;
  final ToastType type;
  final VoidCallback onDismiss;

  Color get _backgroundColor {
    switch (type) {
      case ToastType.success:
        return Colors.green;
      case ToastType.error:
        return Colors.red;
      case ToastType.info:
        return Colors.blue;
      case ToastType.warning:
        return Colors.orange;
    }
  }

  IconData get _icon {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle;
      case ToastType.error:
        return Icons.error;
      case ToastType.info:
        return Icons.info;
      case ToastType.warning:
        return Icons.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 50,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(_icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
