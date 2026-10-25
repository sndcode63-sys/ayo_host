import '../../core/config/api_config.dart';
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

/// Notifications + FCM token endpoints.
class NotificationService {
  NotificationService._();

  static Map<String, dynamic> _unwrap(Map<String, dynamic> res) {
    final d = res['data'];
    return d is Map<String, dynamic> ? d : res;
  }

  /// `POST /notifications/fcm-token`
  static Future<void> registerFcmToken(String token, String platform) async {
    await ApiClient.instance.post(
      ApiConfig.fcmToken,
      data: {'fcm_token': token, 'device_platform': platform},
    );
  }

  /// `GET /notifications?page=&limit=`
  static Future<NotificationPage> list({int page = 1, int limit = 20}) async {
    final res = await ApiClient.instance.get(
      ApiConfig.notifications,
      queryParameters: {'page': page, 'limit': limit},
    );
    final body = _unwrap(res);
    final raw = body['items'] ?? body['notifications'] ?? res['data'];
    final list = raw is List ? raw : const [];
    final items = list
        .whereType<Map>()
        .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final total = body['total'] is num ? (body['total'] as num).toInt() : items.length;
    return NotificationPage(items, total, page, limit);
  }

  /// `GET /notifications/unread-count`
  static Future<int> unreadCount() async {
    final res = await ApiClient.instance.get(ApiConfig.notificationsUnread);
    final body = _unwrap(res);
    final v = body['unread_count'] ?? body['count'] ?? body['unread'];
    return v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;
  }

  /// `PATCH /notifications/:id/read`
  static Future<void> markRead(String id) async {
    await ApiClient.instance.patch(ApiConfig.notificationRead(id));
  }

  /// `POST /notifications/read-all`
  static Future<void> markAllRead() async {
    await ApiClient.instance.post(ApiConfig.notificationsReadAll);
  }
}
