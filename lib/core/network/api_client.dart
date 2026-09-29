import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'retry.dart';

/// HTTP client scaffold for a future custom REST API.
/// AppConfig.apiBaseUrl/apiKey are placeholders until a backend exists.
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
          final method = error.requestOptions.method.toUpperCase();
          final retryableMethod = const {
            'GET',
            'HEAD',
            'OPTIONS',
          }.contains(method);
          if (retryableMethod &&
              error.response?.statusCode == 401 &&
              error.requestOptions.extra['authRetry'] != true) {
            try {
              await FirebaseAuth.instance.currentUser?.getIdToken(true);
              error.requestOptions.extra['authRetry'] = true;
              final retried = await dio.fetch(error.requestOptions);
              return handler.resolve(retried);
            } catch (refreshError, stackTrace) {
              debugPrint(
                'API request retry after authentication failed: '
                '$refreshError\n$stackTrace',
              );
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

  /// POST without automatic retries because the request may not be idempotent.
  Future<Response<T>> post<T>(String path, {Object? data}) {
    return dio.post<T>(path, data: data);
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
