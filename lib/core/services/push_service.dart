import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'logger_service.dart';
import 'toast_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('Handling background FCM message: ${message.messageId}');

  try {
    // If message does not have a display notification payload (data-only FCM message),
    // Android will not show it automatically. We must display it via FlutterLocalNotificationsPlugin:
    if (message.notification == null) {
      final title = message.data['title']?.toString() ?? 'AYO Host';
      final body = message.data['body']?.toString() ?? message.data['message']?.toString() ?? '';
      if (title.isNotEmpty || body.isNotEmpty) {
        final localNotifs = FlutterLocalNotificationsPlugin();
        const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
        await localNotifs.initialize(
          settings: const InitializationSettings(android: androidInit),
        );
        const androidDetails = AndroidNotificationDetails(
          'ayo_host_channel',
          'AYO Host Notifications',
          channelDescription: 'Booking alerts, vehicle status, and payout updates',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        );
        await localNotifs.show(
          id: message.messageId.hashCode,
          title: title,
          body: body,
          notificationDetails: const NotificationDetails(android: androidDetails),
          payload: message.data['type']?.toString(),
        );
      }
    }
  } catch (e) {
    debugPrint('Error in background notification display: $e');
  }
}

/// Firebase Cloud Messaging + Local Notifications:
/// Handles device notifications, foreground alerts, and system-level local heads-up notifications.
class PushService {
  PushService._();

  static bool _started = false;
  static String? currentToken;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const String _channelId = 'ayo_host_channel';
  static const String _channelName = 'AYO Host Notifications';
  static const String _channelDesc = 'Booking alerts, vehicle status, and payout updates';

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

  /// Show a system-level Android/iOS notification banner (heads-up)
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    try {
      playAlertSound();
      final notifId = id ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000).toInt();

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id: notifId,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      LoggerService.info('Local notification display note: $e');
    }
  }

  /// Called whenever a push arrives or is opened, so the unread badge can refresh.
  static void Function()? onActivity;

  /// Called when user taps a push notification in the system tray.
  static void Function(String? payload)? onNotificationTapped;

  static Future<void> init() async {
    if (_started) return;
    _started = true;
    try {
      // 1. Initialize local notification plugin for Android & iOS
      try {
        const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
        const iosInit = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
        const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
        await _localNotifications.initialize(
          settings: initSettings,
          onDidReceiveNotificationResponse: (details) {
            onActivity?.call();
            onNotificationTapped?.call(details.payload);
          },
        );

        // Create Android channel & request notification permission (Android 13+)
        final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDesc,
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
            ),
          );
          await androidPlugin.requestNotificationsPermission();
        }
      } catch (e) {
        LoggerService.info('Local notification setup notice: $e');
      }

      // 2. Setup Firebase Cloud Messaging
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      currentToken = await messaging.getToken();
      messaging.onTokenRefresh.listen((t) {
        currentToken = t;
      });

      // 3. Foreground FCM listener -> trigger local heads-up notification!
      FirebaseMessaging.onMessage.listen((msg) {
        final n = msg.notification;
        final title = n?.title ?? msg.data['title']?.toString() ?? 'AYO Host';
        final body = n?.body ?? msg.data['body']?.toString() ?? '';

        showLocalNotification(
          title: title,
          body: body,
          payload: msg.data.toString(),
        );

        final text = [title, body].where((e) => e.trim().isNotEmpty).join(' · ');
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
}
