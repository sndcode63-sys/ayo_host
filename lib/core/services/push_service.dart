import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../data/services/notification_service.dart';
import 'logger_service.dart';
import 'toast_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('Handling background FCM message: ${message.messageId}');
}

/// Firebase Cloud Messaging: asks permission, registers the device token with the
/// backend on every launch / token refresh, and surfaces foreground pushes.
class PushService {
  PushService._();

  static bool _started = false;
  static String? currentToken;

  /// Trigger sound + haptic feedback alert for notification
  static void playAlertSound() {
    try {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Get cached FCM token or fetch fresh
  static Future<String?> getOrFetchToken() async {
    if (currentToken != null && currentToken!.isNotEmpty) return currentToken;
    try {
      currentToken = await FirebaseMessaging.instance.getToken();
      return currentToken;
    } catch (e) {
      LoggerService.info('Could not fetch FCM token: $e');
      return null;
    }
  }

  /// Called whenever a push arrives or is opened, so the unread badge can refresh.
  static void Function()? onActivity;

  static Future<void> init() async {
    if (_started) return;
    _started = true;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      currentToken = await messaging.getToken();
      await _register(currentToken);
      messaging.onTokenRefresh.listen((t) {
        currentToken = t;
        _register(t);
      });

      FirebaseMessaging.onMessage.listen((msg) {
        playAlertSound();
        final n = msg.notification;
        final title = n?.title ?? msg.data['title']?.toString();
        final body = n?.body ?? msg.data['body']?.toString();
        final text = [title, body].whereType<String>().where((e) => e.trim().isNotEmpty).join(' · ');
        if (text.isNotEmpty) {
          ToastService.showInfo(text);
        }
        onActivity?.call();
      });

      FirebaseMessaging.onMessageOpenedApp.listen((_) => onActivity?.call());
    } catch (e) {
      _started = false;
      LoggerService.error('Push init failed', error: e);
    }
  }

  static Future<void> _register(String? token) async {
    if (token == null || token.trim().isEmpty) return;
    try {
      await NotificationService.registerFcmToken(token, Platform.isIOS ? 'ios' : 'android');
      LoggerService.info('FCM token registered: $token');
    } catch (e) {
      LoggerService.error('FCM token registration failed', error: e);
    }
  }
}
