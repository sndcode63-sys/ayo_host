import '../../ui/widgets/toast.dart' as app_toast;

class ToastService {
  ToastService._();

  static void showSuccess(String message) {
    app_toast.AppToast.showSuccess(message);
  }

  static void showError(String message) {
    app_toast.AppToast.showError(message);
  }

  static void showInfo(String message) {
    app_toast.AppToast.showInfo(message);
  }

  static void showWarning(String message) {
    app_toast.AppToast.showWarning(message);
  }

  static void show(
    String message, {
    app_toast.ToastType type = app_toast.ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    app_toast.AppToast.show(message, type: type, duration: duration);
  }
}
