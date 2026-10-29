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
    final candidates = [
      ApiConfig.fcmToken,
      '/host/notifications/fcm-token',
      '/users/fcm-token',
    ];

    for (final path in candidates) {
      try {
        await ApiClient.instance.post(path, data: body);
        return;
      } on ApiException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 403) {
          continue;
        }
        LoggerService.info('FCM token status (${e.statusCode}) on $path');
        break;
      } catch (e) {
        LoggerService.info('FCM token registration info: $e');
        break;
      }
    }
  }

  /// `GET /notifications/mine` or fallback `GET /notifications`
  static Future<NotificationPage> list({int page = 1, int limit = 20}) async {
    final query = {'page': page, 'limit': limit};
    Map<String, dynamic>? res;
    
    final candidates = [
      ApiConfig.notificationsMine,
      ApiConfig.notifications,
      '/host/notifications',
      '/users/notifications',
    ];

    for (final path in candidates) {
      try {
        res = await ApiClient.instance.get(path, queryParameters: query);
        break;
      } on ApiException catch (e) {
        // If 403 (e.g. backend policy not bound) or 404, try next candidate
        if (e.statusCode == 404 || e.statusCode == 403) {
          continue;
        }
        break;
      } catch (_) {
        break;
      }
    }

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
    final candidates = [
      ApiConfig.notificationsUnread,
      '/notifications/mine/unread-count',
      '/host/notifications/unread-count',
      '/users/notifications/unread-count',
    ];

    for (final path in candidates) {
      try {
        res = await ApiClient.instance.get(path);
        break;
      } on ApiException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 403) {
          continue;
        }
        break;
      } catch (_) {
        break;
      }
    }

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
    final candidates = [
      ApiConfig.notificationRead(id),
      '/notifications/mine/$id/read',
      '/host/notifications/$id/read',
    ];

    for (final path in candidates) {
      try {
        await ApiClient.instance.patch(path);
        return;
      } on ApiException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 403) {
          continue;
        }
        break;
      } catch (_) {
        break;
      }
    }
  }

  /// `POST /notifications/read-all`
  static Future<void> markAllRead() async {
    final candidates = [
      ApiConfig.notificationsReadAll,
      '/notifications/mine/read-all',
      '/host/notifications/read-all',
    ];

    for (final path in candidates) {
      try {
        await ApiClient.instance.post(path);
        return;
      } on ApiException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 403) {
          continue;
        }
        break;
      } catch (_) {
        break;
      }
    }
  }
}
