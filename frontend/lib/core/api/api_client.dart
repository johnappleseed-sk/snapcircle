import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_config.dart';
import '../storage/token_storage.dart';
import '../utils/result.dart';

class ApiClient {
  static final ValueNotifier<int> unauthorizedEvents = ValueNotifier<int>(0);

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
      if (error.response?.statusCode == 401) {
        await _tokenStorage.deleteToken();
        unauthorizedEvents.value++;
      }
      final message = _messageFromError(error);
      if (kDebugMode) {
        debugPrint(
          'SnapCircle API error: ${error.requestOptions.method} '
          '${error.requestOptions.uri} -> ${error.response?.statusCode} '
          '$message',
        );
      }
      return Result.failure(message);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('SnapCircle API unexpected error: $error');
      }
      return Result.failure('Something went wrong. Please try again.');
    }
  }

  String _messageFromError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final parsedData = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};

    if (parsedData['message'] is String &&
        (parsedData['message'] as String).trim().isNotEmpty) {
      return (parsedData['message'] as String).trim();
    }

    final validationMessage = _validationMessage(parsedData['errors']);
    if (validationMessage != null) {
      return validationMessage;
    }

    if (statusCode == 401) {
      return 'Your session expired. Please log in again.';
    }

    if (statusCode == 403) {
      return 'You are not allowed to perform this action.';
    }

    if (statusCode == 413) {
      return 'The uploaded image is too large.';
    }

    if (statusCode == 422) {
      return 'Please check the information and try again.';
    }

    if (statusCode == 429) {
      return 'Too many requests. Please try again later.';
    }

    if (statusCode != null && statusCode >= 500) {
      return 'The server is having trouble. Please try again shortly.';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'The request timed out. Check your connection and try again.';
      case DioExceptionType.connectionError:
        return 'Unable to reach the SnapCircle API. Start the backend and check the Android API URL.';
      case DioExceptionType.cancel:
        return 'The request was cancelled.';
      case DioExceptionType.badCertificate:
        return 'The server certificate could not be verified.';
      case DioExceptionType.badResponse:
        return 'The server returned an unexpected response.';
      case DioExceptionType.unknown:
        if (error.message?.trim().isNotEmpty == true) {
          return 'Network error: ${error.message!.trim()}';
        }
        return 'Network error. Please try again.';
    }
  }

  String? _validationMessage(dynamic errors) {
    if (errors is! Map) {
      return null;
    }

    for (final entry in errors.entries) {
      final value = entry.value;
      if (value is List && value.isNotEmpty) {
        final message = value.first.toString().trim();
        if (message.isNotEmpty) {
          return message;
        }
      }

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }
}
