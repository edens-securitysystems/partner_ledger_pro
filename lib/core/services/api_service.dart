import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import '../constants/api_constants.dart';
import '../models/dto/api_response.dart';
import 'storage_service.dart';

class ApiService {
  late final Dio _dio;
  final StorageService _storage;
  final Logger _logger = Logger();

  bool _isRefreshing = false;
  final List<void Function()> _refreshQueue = [];

  ApiService({required StorageService storage}) : _storage = storage {
    _init();
  }

  Dio get dio => _dio;

  void _init() {
    final config = AppConfig.instance;

    _dio = Dio(
      BaseOptions(
        baseUrl: config.fullApiBaseUrl,
        connectTimeout: config.connectionTimeout,
        receiveTimeout: config.receiveTimeout,
        sendTimeout: config.sendTimeout,
        contentType: ApiConstants.contentTypeJson,
        headers: {
          ApiConstants.headerAccept: ApiConstants.contentTypeJson,
          ApiConstants.headerPlatform: 'flutter',
          ApiConstants.headerAppVersion: config.appVersion,
          ApiConstants.headerDeviceId: 'mobile',
        },
      ),
    );

    _dio.interceptors.addAll([
      _authInterceptor(),
      _loggingInterceptor(config.enableLogging),
      _retryInterceptor(config.maxRetries),
    ]);
  }

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getAccessToken();
        if (token != null) {
          options.headers[ApiConstants.headerAuthorization] =
              '${ApiConstants.headerBearer} $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && !_isRefreshing) {
          _isRefreshing = true;
          try {
            final refreshed = await _refreshToken();
            if (refreshed) {
              final token = await _storage.getAccessToken();
              if (token != null && error.requestOptions.headers.containsKey(ApiConstants.headerAuthorization)) {
                error.requestOptions.headers[ApiConstants.headerAuthorization] =
                    '${ApiConstants.headerBearer} $token';
              }
              _processRefreshQueue();
              final retry = await _retryRequest(error.requestOptions);
              handler.resolve(retry);
              return;
            }
          } catch (_) {
          } finally {
            _isRefreshing = false;
          }
        }
        handler.next(error);
      },
    );
  }

  InterceptorsWrapper _loggingInterceptor(bool enabled) {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (enabled) {
          _logger.d('${options.method} ${options.uri}');
          if (options.data != null) {
            _logger.d('Body: ${options.data}');
          }
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (enabled) {
          _logger.d('${response.statusCode} ${response.requestOptions.uri}');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (enabled) {
          _logger.e('${error.response?.statusCode} ${error.requestOptions.uri}: ${error.message}');
        }
        handler.next(error);
      },
    );
  }

  InterceptorsWrapper _retryInterceptor(int maxRetries) {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (_shouldRetry(error) && maxRetries > 0) {
          for (var i = 0; i < maxRetries; i++) {
            await Future.delayed(Duration(seconds: (i + 1) * 2));
            try {
              final retry = await _dio.fetch(error.requestOptions);
              handler.resolve(retry);
              return;
            } catch (_) {}
          }
        }
        handler.next(error);
      },
    );
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError ||
        (error.response != null &&
            error.response!.statusCode != null &&
            error.response!.statusCode! >= 500);
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await Dio(
        BaseOptions(
          baseUrl: AppConfig.instance.fullApiBaseUrl,
          contentType: ApiConstants.contentTypeJson,
        ),
      ).post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      final data = response.data as Map<String, dynamic>;
      final newToken = data['token'] as String?;
      final newRefreshToken = data['refreshToken'] as String?;

      if (newToken != null) {
        await _storage.setAccessToken(newToken);
      }
      if (newRefreshToken != null) {
        await _storage.setRefreshToken(newRefreshToken);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  void _processRefreshQueue() {
    for (final callback in _refreshQueue) {
      callback();
    }
    _refreshQueue.clear();
  }

  Future<Response> _retryRequest(RequestOptions options) async {
    return _dio.fetch(options);
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromData,
    CancelToken? cancelToken,
  }) async {
    return _execute<T>(
      () => _dio.get(path, queryParameters: queryParameters, cancelToken: cancelToken),
      fromData,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromData,
    CancelToken? cancelToken,
  }) async {
    return _execute<T>(
      () => _dio.post(path, data: data, cancelToken: cancelToken),
      fromData,
    );
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromData,
    CancelToken? cancelToken,
  }) async {
    return _execute<T>(
      () => _dio.put(path, data: data, cancelToken: cancelToken),
      fromData,
    );
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromData,
    CancelToken? cancelToken,
  }) async {
    return _execute<T>(
      () => _dio.delete(path, data: data, cancelToken: cancelToken),
      fromData,
    );
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromData,
    CancelToken? cancelToken,
  }) async {
    return _execute<T>(
      () => _dio.patch(path, data: data, cancelToken: cancelToken),
      fromData,
    );
  }

  Future<ApiResponse<T>> _execute<T>(
    Future<Response<dynamic>> Function() request,
    T Function(dynamic)? fromData,
  ) async {
    try {
      final response = await request();
      final body = response.data as Map<String, dynamic>?;
      if (body == null) {
        final statusCode = response.statusCode ?? 200;
        if (statusCode >= 200 && statusCode < 300) {
          return ApiResponse<T>.success(data: null as T, message: 'Success');
        }
        return ApiResponse<T>.error(message: 'Unknown error occurred');
      }

      final data = body['data'] != null && fromData != null
          ? fromData(body['data'])
          : body['data'] as T?;

      return ApiResponse<T>(
        success: body['success'] as bool? ?? true,
        message: body['message'] as String? ?? 'Success',
        data: data,
        error: body['error'] as String?,
        errorCode: body['errorCode'] as String?,
        timestamp: body['timestamp'] != null
            ? DateTime.parse(body['timestamp'] as String)
            : DateTime.now(),
      );
    } on DioException catch (e) {
      final errorBody = e.response?.data as Map<String, dynamic>?;
      return ApiResponse<T>.error(
        message: errorBody?['message'] as String? ?? _mapError(e),
        error: errorBody?['error'] as String? ?? e.message,
        errorCode: errorBody?['errorCode'] as String? ?? _mapErrorCode(e),
      );
    } catch (e) {
      return ApiResponse<T>.error(
        message: 'An unexpected error occurred',
        error: e.toString(),
        errorCode: 'UNKNOWN_ERROR',
      );
    }
  }

  String _mapError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Request timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to server. Check your internet connection.';
      case DioExceptionType.badResponse:
        return _mapStatusCode(e.response?.statusCode);
      case DioExceptionType.cancel:
        return 'Request was cancelled';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  String _mapStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request';
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'Access denied';
      case 404:
        return 'Resource not found';
      case 409:
        return 'Conflict occurred';
      case 422:
        return 'Validation failed';
      case 429:
        return 'Too many requests. Please slow down.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  String _mapErrorCode(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'CONNECTION_TIMEOUT';
      case DioExceptionType.receiveTimeout:
        return 'RECEIVE_TIMEOUT';
      case DioExceptionType.sendTimeout:
        return 'SEND_TIMEOUT';
      case DioExceptionType.connectionError:
        return 'CONNECTION_ERROR';
      case DioExceptionType.badResponse:
        return 'HTTP_${e.response?.statusCode ?? 0}';
      case DioExceptionType.cancel:
        return 'REQUEST_CANCELLED';
      default:
        return 'UNKNOWN';
    }
  }
}
