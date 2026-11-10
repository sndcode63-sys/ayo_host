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

/// Notifications service: loads inbox items and manages read states.
/// Note: FCM token registration, unread-count, and delete endpoints do not exist on the backend;
/// those operations are handled entirely on the client side without making failing network calls.
class NotificationService {
  NotificationService._();

  static Map<String, dynamic> _unwrap(Map<String, dynamic> res) {
    final d = res['data'];
    return d is Map<String, dynamic> ? d : res;
  }

  /// No-op: backend does not support FCM token registration.
  static Future<void> registerFcmToken(String token, String platform) async {}

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

  /// No-op: unread count is calculated locally from loaded notification items.
  static Future<int> unreadCount() async => 0;

  /// `PATCH /notifications/:id/read`
  static Future<void> markRead(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) return;

    final candidates = [
      ApiConfig.notificationRead(cleanId),
      '/notifications/mine/$cleanId/read',
      '/host/notifications/$cleanId/read',
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

  /// `DELETE /notifications/:id`
  /// Deletes a single notification both from the cloud backend and user tray.
  static Future<bool> delete(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) return false;

    try {
      final res = await ApiClient.instance.delete('/notifications/$cleanId');
      return res['success'] == true || res['deleted'] == true;
    } on ApiException catch (e) {
      LoggerService.warning('Failed to delete notification $cleanId: ${e.message}');
      return false;
    } catch (e) {
      LoggerService.warning('Failed to delete notification $cleanId: $e');
      return false;
    }
  }

  /// `DELETE /notifications/clear-all`
  /// Deletes all notifications for the current host in a single request.
  static Future<int> clearAll() async {
    try {
      final res = await ApiClient.instance.delete('/notifications/clear-all');
      return (res['deleted_count'] as num?)?.toInt() ?? 0;
    } on ApiException catch (e) {
      LoggerService.warning('Failed to clear notifications: ${e.message}');
      return 0;
    } catch (e) {
      LoggerService.warning('Failed to clear notifications: $e');
      return 0;
    }
  }
}
