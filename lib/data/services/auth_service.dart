import '../../core/config/api_config.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/services/toast_service.dart';
import '../models/models.dart';
import 'api_client.dart';

class AuthService {
  AuthService._();

  static Future<AuthResponse> exchangeFirebaseToken({
    required String idToken,
    String? role,
    bool consentAccepted = true,
    String consentVersion = '1.0',
  }) async {
    try {
      LoggerService.info('Exchanging Firebase token for Ayo session');

      final data = <String, dynamic>{
        'id_token': idToken,
        'consent_accepted': consentAccepted,
        'consent_version': consentVersion,
      };
      if (role != null) {
        data['role'] = role;
      }

      final response = await ApiClient.instance.post(
        ApiConfig.authExchange,
        data: data,
      );

      final authResponse = AuthResponse.fromJson(response['data']);

      await SecureStorageService.saveAccessToken(authResponse.accessToken);
      await SecureStorageService.saveUserId(authResponse.user.id);
      await SecureStorageService.saveUserRole(authResponse.user.role);

      LoggerService.info('Successfully exchanged token for user: ${authResponse.user.id}');
      ToastService.showSuccess('Login successful');

      return authResponse;
    } catch (e) {
      LoggerService.error('Failed to exchange Firebase token', error: e);
      rethrow;
    }
  }

  static Future<AuthResponse> quickLogin({String role = 'HOST'}) async {
    try {
      LoggerService.info('Performing quick login as $role');

      final response = await ApiClient.instance.post(
        ApiConfig.authQuickLogin,
        data: {'role': role},
      );

      final authResponse = AuthResponse.fromJson(response['data']);

      await SecureStorageService.saveAccessToken(authResponse.accessToken);
      await SecureStorageService.saveUserId(authResponse.user.id);
      await SecureStorageService.saveUserRole(authResponse.user.role);

      LoggerService.info('Quick login success for host: ${authResponse.user.id}');
      ToastService.showSuccess('Host authenticated successfully');

      return authResponse;
    } catch (e) {
      LoggerService.error('Failed to perform quick login', error: e);
      rethrow;
    }
  }

  static Future<User?> getAuthMe() async {
    try {
      final response = await ApiClient.instance.get(ApiConfig.authMe);
      if (response['data'] != null && response['data'] is Map<String, dynamic>) {
        return User.fromJson(response['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to fetch /auth/me', error: e);
      return null;
    }
  }

  static Future<User?> getUserProfile() async {
    try {
      final response = await ApiClient.instance.get(ApiConfig.usersMe);
      if (response['data'] != null && response['data'] is Map<String, dynamic>) {
        return User.fromJson(response['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to fetch /users/me', error: e);
      return null;
    }
  }

  static Future<User?> updateUserProfile({required String name}) async {
    try {
      final response = await ApiClient.instance.patch(
        ApiConfig.usersProfile,
        data: {'name': name.trim()},
      );
      if (response['data'] != null && response['data'] is Map<String, dynamic>) {
        return User.fromJson(response['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to update /users/profile', error: e);
      rethrow;
    }
  }

  static Future<void> logout() async {
    try {
      await SecureStorageService.clearAuthData();
      LoggerService.info('User logged out successfully');
      ToastService.showInfo('Logged out successfully');
    } catch (e) {
      LoggerService.error('Failed to logout', error: e);
      rethrow;
    }
  }

  static Future<bool> isAuthenticated() async {
    final token = await SecureStorageService.getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
