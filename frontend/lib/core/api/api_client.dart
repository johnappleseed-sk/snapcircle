import 'package:dio/dio.dart';

import '../constants/app_config.dart';
import '../storage/token_storage.dart';
import '../utils/result.dart';

class ApiClient {
  final TokenStorage _tokenStorage;
  late final Dio _dio;

  ApiClient({TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? const TokenStorage() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  Future<Result<Response<dynamic>>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _send(() => _dio.get(path, queryParameters: queryParameters));
  }

  Future<Result<Response<dynamic>>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _send(
      () => _dio.post(path, data: data, queryParameters: queryParameters),
    );
  }

  Future<Result<Response<dynamic>>> put(String path, {dynamic data}) {
    return _send(() => _dio.put(path, data: data));
  }

  Future<Result<Response<dynamic>>> delete(String path, {dynamic data}) {
    return _send(() => _dio.delete(path, data: data));
  }

  Future<Result<Response<dynamic>>> _send(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      return Result.success(await request());
    } on DioException catch (error) {
      final message = _messageFromError(error);
      return Result.failure(message);
    } catch (_) {
      return Result.failure('Something went wrong. Please try again.');
    }
  }

  String _messageFromError(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }

    if (data is Map<String, dynamic> && data['errors'] is Map) {
      final errors = data['errors'] as Map;
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
      }
    }

    if (error.response?.statusCode == 401) {
      return 'Session expired. Please log in again.';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Please check your internet connection.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to server.';
      default:
        return 'Request failed. Please try again.';
    }
  }
}
