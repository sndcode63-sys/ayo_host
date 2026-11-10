import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();
  
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static const String _accessTokenKey = 'ayo_access_token';
  static const String _jwtTokenKey = 'ayo_jwt_token';
  static const String _userIdKey = 'ayo_user_id';
  static const String _userRoleKey = 'ayo_user_role';

  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
    await _storage.write(key: _jwtTokenKey, value: token);
  }

  static Future<String?> getAccessToken() async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token != null && token.isNotEmpty) return token;
    return await _storage.read(key: _jwtTokenKey);
  }

  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  static Future<void> saveUserRole(String role) async {
    await _storage.write(key: _userRoleKey, value: role);
  }

  static Future<String?> getUserRole() async {
    return await _storage.read(key: _userRoleKey);
  }

  static const String _shownNotificationsKey = 'ayo_shown_notifications';

  static Future<Set<String>> getShownNotificationIds() async {
    try {
      final raw = await _storage.read(key: _shownNotificationsKey);
      if (raw != null && raw.isNotEmpty) {
        return raw.split(',').where((e) => e.trim().isNotEmpty).toSet();
      }
    } catch (_) {}
    return <String>{};
  }

  static Future<void> markNotificationsShown(Iterable<String> ids) async {
    try {
      final existing = await getShownNotificationIds();
      existing.addAll(ids.where((e) => e.trim().isNotEmpty));
      final trimmed = existing.toList().reversed.take(200).toList();
      await _storage.write(key: _shownNotificationsKey, value: trimmed.join(','));
    } catch (_) {}
  }

  static Future<void> clearAuthData() async {
    await clearAll();
  }

  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _userIdKey);
      await _storage.delete(key: _userRoleKey);
    }
  }
}
