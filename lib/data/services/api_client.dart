import 'dart:math';
import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/services/toast_service.dart';

/// Dio-based API client with interceptors for logging, auth, and error handling.
/// All repositories call the backend through this client.
class ApiClient {
  ApiClient._();

  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;

  static void Function()? onUnauthorized;

  late final Dio _dio;

  /// Generates a standard RFC4122 v4 UUID for Idempotency-Key and tracking.
  static String generateUuidV4() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40; // version 4
    values[8] = (values[8] & 0x3f) | 0x80; // variant RFC4122
    final hex = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  static Future<void> initialize() async {
    _instance._dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _instance._dio.interceptors.add(_LoggingInterceptor());
    _instance._dio.interceptors.add(_AuthInterceptor());
    _instance._dio.interceptors.add(_ErrorInterceptor());

    LoggerService.info('ApiClient initialized with base URL: ${ApiConfig.baseUrl}');
  }

  Dio get dio => _dio;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> _handleResponse(Response response) {
    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'data': response.data};
    }
    throw ApiException(
      response.statusCode ?? 0,
      response.data?['error']?['message'] ?? 'Request failed',
      response.data?['error']?['code'],
    );
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    LoggerService.debug('API Request: ${options.method} ${options.uri}');
    if (options.data != null) {
      LoggerService.debug('Request Body: ${options.data}');
    }
    if (options.queryParameters.isNotEmpty) {
      LoggerService.debug('Query Params: ${options.queryParameters}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    LoggerService.info(
      'API Response: ${response.statusCode} ${response.requestOptions.uri}',
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final errCode = err.response?.data?['error']?['code']?.toString() ?? '';
    final path = err.requestOptions.path;
    if (err.response?.statusCode == 402 || errCode == 'LISTING_FEE_REQUIRED') {
      LoggerService.info('API Gate Notice (402): Listing fee required for ${err.requestOptions.uri}');
    } else if (err.response?.statusCode == 404 &&
        (path.contains('/notifications') ||
         path.contains('/host/dashboard') ||
         path.contains('/host/earnings'))) {
      LoggerService.info('API Notice (404): Optional endpoint not present on server (${err.requestOptions.uri})');
    } else {
      LoggerService.error(
        'API Error: ${err.requestOptions.method} ${err.requestOptions.uri} - Response: ${err.response?.data}',
        error: err,
      );
    }
    super.onError(err, handler);
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Auto-attach standard RFC4122 v4 Idempotency-Key on mutating requests
    final method = options.method.toUpperCase();
    if (method == 'POST' || method == 'PUT' || method == 'PATCH') {
      if (!options.headers.containsKey('Idempotency-Key') &&
          !options.headers.containsKey('idempotency-key')) {
        options.headers['Idempotency-Key'] = ApiClient.generateUuidV4();
      }
    }

    super.onRequest(options, handler);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String errorMessage = 'Something went wrong';
    final responseData = err.response?.data;

    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('error')) {
        final error = responseData['error'] as Map<String, dynamic>?;
        errorMessage = error?['message'] ?? errorMessage;
      } else if (responseData.containsKey('message')) {
        errorMessage = responseData['message'] as String;
      }
    } else if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Connection timeout. Please check your internet connection.';
    } else if (err.type == DioExceptionType.connectionError) {
      errorMessage = 'No internet connection. Please check your network.';
    }

    switch (err.type) {
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        if (statusCode == 401) {
          // Keep session persistent — do NOT wipe secure storage or force logout.
          // Only manual logout by user purges credentials.
          LoggerService.warning('401 response for: ${err.requestOptions.uri}');
        } else if (statusCode == 403) {
          if (responseData is Map && responseData['error'] is Map && responseData['error']['code'] == 'INSUFFICIENT_ROLE') {
            errorMessage = 'Access denied: Host account role required. This account is registered as Customer on the backend.';
          } else if (errorMessage == 'Something went wrong') {
            errorMessage = 'Access denied. You don\'t have permission.';
          }
        } else if (errorMessage == 'Something went wrong') {
          if (statusCode == 404) {
            errorMessage = 'Resource not found.';
          } else if (statusCode == 422) {
            errorMessage = 'Invalid data provided.';
          } else if (statusCode != null && statusCode >= 500) {
            errorMessage = 'Server error. Please try again later.';
          }
        }
        break;
      default:
        break;
    }

    final statusCode = err.response?.statusCode;
    final errCode = err.response?.data is Map ? (err.response!.data['error']?['code']?.toString() ?? '') : '';

    // Do not show alarming generic error toast on 402 Payment Required or listing fee requirement;
    // caller UI gracefully opens the payment checkout sheet.
    final isListingFee = statusCode == 402 ||
        errCode == 'LISTING_FEE_REQUIRED' ||
        errorMessage.toLowerCase().contains('listing fee');
    final isUnauthorized = statusCode == 401;

    // Never show alarming toasts for background 401s or 402 listing fees:
    if (!isListingFee && !isUnauthorized) {
      ToastService.showError(errorMessage);
    }

    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        error: errorMessage,
        type: err.type,
        response: err.response,
      ),
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;

  ApiException(this.statusCode, this.message, [this.code]);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
