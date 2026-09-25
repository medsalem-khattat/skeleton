import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/app_config.dart';
import 'retry.dart';

/// Scaffold HTTP client for a future custom REST API.
/// Not wired to any real endpoint yet - AppConfig.apiBaseUrl/apiKey
/// are placeholders until that backend exists. Once it does:
///   - requests get the current Firebase ID token as a Bearer header
///     automatically (Firebase Auth manages that token's own refresh)
///   - a 401 response triggers one forced token refresh + retry
///   - transient network failures (timeouts, connection errors) are
///     retried with backoff via withRetry
///
/// Requires the `dio` package: flutter pub add dio
class ApiClient {
  ApiClient() : dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl)) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await FirebaseAuth.instance.currentUser?.getIdToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (AppConfig.apiKey.isNotEmpty) {
            options.headers['x-api-key'] = AppConfig.apiKey;
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            try {
              await FirebaseAuth.instance.currentUser?.getIdToken(true);
              final retried = await dio.fetch(error.requestOptions);
              return handler.resolve(retried);
            } catch (_) {
              // fall through to the original error
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;

  /// GET with retry on transient network errors.
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) {
    return withRetry(
      () => dio.get<T>(path, queryParameters: query),
      shouldRetry: _isTransientDioError,
    );
  }

  /// POST with retry on transient network errors.
  Future<Response<T>> post<T>(String path, {Object? data}) {
    return withRetry(
      () => dio.post<T>(path, data: data),
      shouldRetry: _isTransientDioError,
    );
  }

  bool _isTransientDioError(Object error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError;
    }
    return false;
  }
}
