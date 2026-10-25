import '../../core/config/api_config.dart';
import '../../core/services/logger_service.dart';
import '../models/models.dart';
import 'api_client.dart';

class NotificationPage {
  final List<AppNotification> items;
  final int total;
  final int page;
  final int limit;
  const NotificationPage(this.items, this.total, this.page, this.limit);

  bool get hasMore => page * limit < total && items.isNotEmpty;
}

/// Notifications + FCM token endpoints with automatic fallback handling.
class NotificationService {
  NotificationService._();

  static Map<String, dynamic> _unwrap(Map<String, dynamic> res) {
    final d = res['data'];
    return d is Map<String, dynamic> ? d : res;
  }

  /// `POST /notifications/fcm-token`
  static Future<void> registerFcmToken(String token, String platform) async {
    final body = {'fcm_token': token, 'device_platform': platform};
    try {
      await ApiClient.instance.post(ApiConfig.fcmToken, data: body);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // Fallback endpoints
        for (final path in ['/host/notifications/fcm-token', '/users/fcm-token']) {
          try {
            await ApiClient.instance.post(path, data: body);
            return;
          } catch (_) {}
        }
      }
      LoggerService.info('FCM token registration status notice (${e.statusCode})');
    } catch (e) {
      LoggerService.info('FCM token registration info: $e');
    }
  }

  /// `GET /notifications?page=&limit=`
  static Future<NotificationPage> list({int page = 1, int limit = 20}) async {
    final query = {'page': page, 'limit': limit};
    Map<String, dynamic>? res;
    
    try {
      res = await ApiClient.instance.get(ApiConfig.notifications, queryParameters: query);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        for (final path in ['/host/notifications', '/users/notifications']) {
          try {
            res = await ApiClient.instance.get(path, queryParameters: query);
            break;
          } catch (_) {}
        }
      }
    } catch (_) {}

    if (res == null) {
      return NotificationPage(const [], 0, page, limit);
    }

    try {
      final body = _unwrap(res);
      final raw = body['items'] ?? body['notifications'] ?? res['data'];
      final list = raw is List ? raw : const [];
      final items = list
          .whereType<Map>()
          .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final total = body['total'] is num ? (body['total'] as num).toInt() : items.length;
      return NotificationPage(items, total, page, limit);
    } catch (_) {
      return NotificationPage(const [], 0, page, limit);
    }
  }

  /// `GET /notifications/unread-count`
  static Future<int> unreadCount() async {
    Map<String, dynamic>? res;
    try {
      res = await ApiClient.instance.get(ApiConfig.notificationsUnread);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        for (final path in ['/host/notifications/unread-count', '/users/notifications/unread-count']) {
          try {
            res = await ApiClient.instance.get(path);
            break;
          } catch (_) {}
        }
      }
    } catch (_) {}

    if (res == null) return 0;

    try {
      final body = _unwrap(res);
      final v = body['unread_count'] ?? body['count'] ?? body['unread'];
      return v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// `PATCH /notifications/:id/read`
  static Future<void> markRead(String id) async {
    try {
      await ApiClient.instance.patch(ApiConfig.notificationRead(id));
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        try {
          await ApiClient.instance.patch('/host/notifications/$id/read');
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// `POST /notifications/read-all`
  static Future<void> markAllRead() async {
    try {
      await ApiClient.instance.post(ApiConfig.notificationsReadAll);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        try {
          await ApiClient.instance.post('/host/notifications/read-all');
        } catch (_) {}
      }
    } catch (_) {}
  }
}
