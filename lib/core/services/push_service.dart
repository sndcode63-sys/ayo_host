import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../data/services/notification_service.dart';
import 'logger_service.dart';
import 'toast_service.dart';

/// Firebase Cloud Messaging: asks permission, registers the device token with the
/// backend on every launch / token refresh, and surfaces foreground pushes.
class PushService {
  PushService._();

  static bool _started = false;

  /// Called whenever a push arrives or is opened, so the unread badge can refresh.
  static void Function()? onActivity;

  static Future<void> init() async {
    if (_started) return;
    _started = true;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await _register(await messaging.getToken());
      messaging.onTokenRefresh.listen(_register);

      FirebaseMessaging.onMessage.listen((msg) {
        final n = msg.notification;
        final text = [n?.title, n?.body].whereType<String>().where((e) => e.isNotEmpty).join(' · ');
        if (text.isNotEmpty) ToastService.showInfo(text);
        onActivity?.call();
      });
      FirebaseMessaging.onMessageOpenedApp.listen((_) => onActivity?.call());
    } catch (e) {
      _started = false;
      LoggerService.error('Push init failed', error: e);
    }
  }

  static Future<void> _register(String? token) async {
    if (token == null || token.isEmpty) return;
    try {
      await NotificationService.registerFcmToken(token, Platform.isIOS ? 'ios' : 'android');
      LoggerService.info('FCM token registered');
    } catch (e) {
      LoggerService.error('FCM token registration failed', error: e);
    }
  }
}
