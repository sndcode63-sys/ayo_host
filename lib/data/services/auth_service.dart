import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;

import '../../core/config/api_config.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/push_service.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/services/toast_service.dart';
import '../models/models.dart';
import 'api_client.dart';

class AuthService {
  AuthService._();

  /// Formats phone to standard E.164 (+91XXXXXXXXXX) accepted by MSG91 & AYO Backend
  static String formatPhone(String rawPhone) {
    final clean = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 10) return '+91$clean';
    if (clean.length > 10 && clean.startsWith('91')) return '+$clean';
    if (rawPhone.trim().startsWith('+')) return rawPhone.trim();
    return '+91$clean';
  }

  static String? _lastReqId;

  /// 1. Send 6-digit OTP via MSG91 (POST /api/v1/auth/send-otp)
  static Future<bool> sendOtp({
    required String phone,
    String role = 'HOST',
  }) async {
    try {
      final formattedPhone = formatPhone(phone);
      LoggerService.info('Sending 6-digit OTP to $formattedPhone as $role via MSG91...');

      final response = await ApiClient.instance.post(
        ApiConfig.authSendOtp,
        data: {
          'phone': formattedPhone,
          'role': role,
        },
      );

      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;

      _lastReqId = data['req_id']?.toString() ?? data['request_id']?.toString();

      final success = data['success'] == true;
      final msg = data['message']?.toString() ?? 'OTP sent successfully';
      if (success) {
        ToastService.showSuccess(msg);
      }
      return success;
    } on DioException catch (e) {
      final errData = e.response?.data;
      final err = errData is Map ? (errData['error'] as Map<String, dynamic>?) : null;
      final code = err?['code']?.toString() ?? '';
      final msg = err?['message']?.toString() ?? '';

      if (code == 'RATE_LIMITED') {
        ToastService.showError('Too many OTP requests. Please wait a few minutes before retrying.');
      } else if (code == 'PHONE_REQUIRED') {
        ToastService.showError('Please enter a valid 10-digit mobile number.');
      } else if (code == 'OTP_SEND_FAILED' || msg == 'Invalid request') {
        ToastService.showError('MSG91 Gateway: Invalid request. Use QA bypass 8888888888 (OTP: 123456).');
      } else if (msg.isNotEmpty) {
        ToastService.showError(msg);
      } else {
        ToastService.showError('Failed to send OTP. Please check mobile number.');
      }
      rethrow;
    } catch (e) {
      LoggerService.error('Failed to send OTP via MSG91', error: e);
      rethrow;
    }
  }

  /// 2. Verify 6-digit OTP & Issue Session Token (POST /api/v1/auth/verify-otp)
  static Future<AuthResponse> verifyOtp({
    required String phone,
    required String otp,
    String role = 'HOST',
    String? name,
  }) async {
    try {
      final formattedPhone = formatPhone(phone);
      final fcmToken = await PushService.getOrFetchToken();

      LoggerService.info('Verifying 6-digit OTP for $formattedPhone as $role...');
      final payload = <String, dynamic>{
        'phone': formattedPhone,
        'otp': otp.trim(),
        'role': role,
        'consent_accepted': true,
        if (_lastReqId != null && _lastReqId!.isNotEmpty) 'req_id': _lastReqId,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      };

      final response = await ApiClient.instance.post(
        ApiConfig.authVerifyOtp,
        data: payload,
      );

      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;

      final authResponse = AuthResponse.fromJson(data);

      // BLOCK CUSTOMER ACCOUNTS FROM HOST APP
      if (authResponse.user.role.toUpperCase() == 'CUSTOMER') {
        LoggerService.warning('Blocked customer account login on Host app: ${authResponse.user.id} (${authResponse.user.phone})');
        ToastService.showError(
          'This mobile number is already registered as a Customer. Please use a Host account or register with a different number.',
        );
        throw Exception(
          'This mobile number is already registered as a Customer. Please use a Host account or register with a different number.',
        );
      }

      await SecureStorageService.saveAccessToken(authResponse.accessToken);
      await SecureStorageService.saveUserId(authResponse.user.id);
      await SecureStorageService.saveUserRole(authResponse.user.role);

      LoggerService.info('Host authenticated successfully via OTP: ${authResponse.user.id}');
      ToastService.showSuccess('Host authenticated successfully');

      return authResponse;
    } on DioException catch (e) {
      final errData = e.response?.data;
      final err = errData is Map ? (errData['error'] as Map<String, dynamic>?) : null;
      final code = err?['code']?.toString() ?? '';
      final msg = err?['message']?.toString() ?? '';

      if (code == 'INVALID_OTP') {
        ToastService.showError('Incorrect OTP. Please check the code and try again.');
      } else if (code == 'TOO_MANY_ATTEMPTS') {
        ToastService.showError('Too many incorrect attempts. Please tap Resend OTP to get a new code.');
      } else if (msg.isNotEmpty) {
        ToastService.showError(msg);
      } else {
        ToastService.showError('OTP verification failed. Please try again.');
      }
      rethrow;
    } catch (e) {
      LoggerService.error('Failed to verify OTP', error: e);
      rethrow;
    }
  }

  /// 3. Resend / Retry OTP via SMS ('text') or Voice Call ('voice') (POST /api/v1/auth/retry-otp)
  static Future<bool> retryOtp({
    required String phone,
    bool viaVoice = false,
  }) async {
    try {
      final formattedPhone = formatPhone(phone);
      final channel = viaVoice ? 'voice' : 'text';
      LoggerService.info('Retrying OTP for $formattedPhone via $channel channel...');

      final response = await ApiClient.instance.post(
        ApiConfig.authRetryOtp,
        data: {
          'phone': formattedPhone,
          'retry_channel': channel,
        },
      );

      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;

      final success = data['success'] == true;
      final msg = data['message']?.toString() ??
          (viaVoice
              ? 'Calling you with your 6-digit OTP code...'
              : 'OTP resent successfully');
      ToastService.showSuccess(msg);
      return success;
    } on DioException catch (e) {
      final errData = e.response?.data;
      final err = errData is Map ? (errData['error'] as Map<String, dynamic>?) : null;
      final code = err?['code']?.toString() ?? '';
      final msg = err?['message']?.toString() ?? '';

      if (code == 'RATE_LIMITED') {
        ToastService.showError('Cooldown active. Please wait 30 seconds before retrying.');
      } else if (msg.isNotEmpty) {
        ToastService.showError(msg);
      } else {
        ToastService.showError('Failed to retry OTP.');
      }
      rethrow;
    } catch (e) {
      LoggerService.error('Failed to retry OTP', error: e);
      rethrow;
    }
  }

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

      if (authResponse.user.role.toUpperCase() == 'CUSTOMER') {
        LoggerService.warning('Blocked customer account login on Host app: ${authResponse.user.id}');
        ToastService.showError(
          'This mobile number is already registered as a Customer. Please use a Host account or register with a different number.',
        );
        throw Exception(
          'This mobile number is already registered as a Customer. Please use a Host account or register with a different number.',
        );
      }

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

      if (authResponse.user.role.toUpperCase() == 'CUSTOMER') {
        LoggerService.warning('Blocked customer account login on Host app: ${authResponse.user.id}');
        ToastService.showError(
          'This mobile number is already registered as a Customer. Please use a Host account or register with a different number.',
        );
        throw Exception(
          'This mobile number is already registered as a Customer. Please use a Host account or register with a different number.',
        );
      }

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
      await SecureStorageService.clearAll();
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      LoggerService.info('User logged out & all stored credentials purged successfully');
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
