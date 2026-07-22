import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../config/sheets_config.dart';
import '../models/dto/api_response.dart';

class GoogleSheetsService {
  late final Dio _dio;
  final Logger _logger = Logger();
  static const _uuid = Uuid();

  GoogleSheetsService() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
    ));
  }

  String get _baseUrl => SheetsConfig.appsScriptUrl;

  bool get isConfigured => SheetsConfig.isConfigured;

  // ── Core HTTP Methods ──────────────────────────────────────────────────────

  Future<ApiResponse<Map<String, dynamic>>> _post({
    required String action,
    required String sheet,
    Map<String, dynamic>? data,
    Map<String, dynamic>? params,
  }) async {
    if (!isConfigured) {
      return ApiResponse.error(
        message: 'Google Sheets not configured. Set Apps Script URL in sheets_config.dart',
        errorCode: 'NOT_CONFIGURED',
      );
    }

    try {
      final body = <String, dynamic>{
        SheetsConfig.keyAction: action,
        SheetsConfig.keySheet: sheet,
      };

      if (data != null) body[SheetsConfig.keyData] = data;
      if (params != null) body.addAll(params);

      final encodedBody = jsonEncode(body);
      _logger.d('Sheets API: $action on $sheet');

      final postOptions = Options(
        contentType: 'text/plain',
        responseType: ResponseType.plain,
        followRedirects: false,
        validateStatus: (status) => status != null && status < 500,
        headers: {
          'Accept': 'application/json',
        },
      );

      var response = await _dio.post<String>(
        _baseUrl,
        data: encodedBody,
        options: postOptions,
      );

      if (response.statusCode == 302 || response.statusCode == 301) {
        final redirectUrl = response.headers.value('location');
        if (redirectUrl != null) {
          response = await _dio.get<String>(
            redirectUrl,
            options: Options(
              responseType: ResponseType.plain,
              headers: {
                'Accept': 'application/json',
              },
            ),
          );
        }
      }

      final result = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;

      if (result[SheetsConfig.keySuccess] == true) {
        return ApiResponse.success(data: result);
      } else {
        return ApiResponse.error(
          message: result[SheetsConfig.keyMessage] as String? ?? 'Unknown error',
        );
      }
    } on DioException catch (e) {
      _logger.e('Sheets API error: ${e.message}');
      return ApiResponse.error(
        message: _mapDioError(e),
        error: e.message,
        errorCode: 'SHEETS_API_ERROR',
      );
    } catch (e) {
      _logger.e('Sheets API unexpected error: $e');
      return ApiResponse.error(
        message: 'Failed to communicate with Google Sheets',
        error: e.toString(),
        errorCode: 'SHEETS_UNEXPECTED_ERROR',
      );
    }
  }

  // ── CRUD Operations ────────────────────────────────────────────────────────

  Future<ApiResponse<List<Map<String, dynamic>>>> getAll(String sheet) async {
    final response = await _post(
      action: SheetsConfig.actionGetAll,
      sheet: sheet,
    );

    if (response.success && response.data != null) {
      final result = response.data![SheetsConfig.keyResult];
      if (result is List) {
        final rows = result
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        return ApiResponse.success(data: rows);
      }
    }

    return ApiResponse<List<Map<String, dynamic>>>.error(
      message: response.message,
      error: response.error,
    );
  }

  Future<ApiResponse<Map<String, dynamic>?>> getById(
    String sheet,
    String id,
  ) async {
    final response = await _post(
      action: SheetsConfig.actionGetById,
      sheet: sheet,
      params: {SheetsConfig.keyId: id},
    );

    if (response.success && response.data != null) {
      final result = response.data![SheetsConfig.keyResult];
      if (result is Map) {
        return ApiResponse.success(
          data: Map<String, dynamic>.from(result),
        );
      }
      if (result is List && result.isNotEmpty) {
        return ApiResponse.success(
          data: Map<String, dynamic>.from(result.first as Map),
        );
      }
    }

    return ApiResponse.error(message: 'Not found');
  }

  Future<ApiResponse<String>> create(
    String sheet,
    Map<String, dynamic> data,
  ) async {
    final id = data['id'] as String? ?? _uuid.v4();
    data['id'] = id;

    final response = await _post(
      action: SheetsConfig.actionCreate,
      sheet: sheet,
      data: data,
    );

    if (response.success) {
      return ApiResponse.success(data: id);
    }

    return ApiResponse<String>.error(
      message: response.message,
      error: response.error,
    );
  }

  Future<ApiResponse<bool>> update(
    String sheet,
    String id,
    Map<String, dynamic> data,
  ) async {
    data[SheetsConfig.keyId] = id;

    final response = await _post(
      action: SheetsConfig.actionUpdate,
      sheet: sheet,
      data: data,
    );

    return response.success
        ? ApiResponse.success(data: true)
        : ApiResponse<bool>.error(
            message: response.message,
            error: response.error,
          );
  }

  Future<ApiResponse<bool>> delete(String sheet, String id) async {
    final response = await _post(
      action: SheetsConfig.actionDelete,
      sheet: sheet,
      params: {SheetsConfig.keyId: id},
    );

    return response.success
        ? ApiResponse.success(data: true)
        : ApiResponse<bool>.error(
            message: response.message,
            error: response.error,
          );
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> search(
    String sheet,
    String query,
  ) async {
    final response = await _post(
      action: SheetsConfig.actionSearch,
      sheet: sheet,
      params: {SheetsConfig.keySearch: query},
    );

    if (response.success && response.data != null) {
      final result = response.data![SheetsConfig.keyResult];
      if (result is List) {
        final rows = result
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        return ApiResponse.success(data: rows);
      }
    }

    return ApiResponse<List<Map<String, dynamic>>>.error(
      message: response.message,
      error: response.error,
    );
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getByField(
    String sheet,
    String field,
    String value,
  ) async {
    final response = await _post(
      action: SheetsConfig.actionGetByField,
      sheet: sheet,
      params: {
        SheetsConfig.keyField: field,
        SheetsConfig.keyValue: value,
      },
    );

    if (response.success && response.data != null) {
      final result = response.data![SheetsConfig.keyResult];
      if (result is List) {
        final rows = result
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        return ApiResponse.success(data: rows);
      }
    }

    return ApiResponse<List<Map<String, dynamic>>>.error(
      message: response.message,
      error: response.error,
    );
  }

  Future<ApiResponse<bool>> ping() async {
    final response = await _post(
      action: SheetsConfig.actionPing,
      sheet: '',
    );
    return response.success
        ? ApiResponse.success(data: true)
        : ApiResponse<bool>.error(
            message: 'Sheets API unreachable',
            error: response.error,
          );
  }

  // ── Batch Operations ───────────────────────────────────────────────────────

  Future<ApiResponse<int>> batchCreate(
    String sheet,
    List<Map<String, dynamic>> items,
  ) async {
    var successCount = 0;

    for (final item in items) {
      final result = await create(sheet, item);
      if (result.success) successCount++;
    }

    return ApiResponse.success(data: successCount);
  }

  Future<ApiResponse<int>> batchUpdate(
    String sheet,
    List<Map<String, dynamic>> items,
  ) async {
    var successCount = 0;

    for (final item in items) {
      final id = item['id'] as String?;
      if (id == null) continue;
      final result = await update(sheet, id, item);
      if (result.success) successCount++;
    }

    return ApiResponse.success(data: successCount);
  }

  Future<ApiResponse<int>> batchDelete(
    String sheet,
    List<String> ids,
  ) async {
    var successCount = 0;

    for (final id in ids) {
      final result = await delete(sheet, id);
      if (result.success) successCount++;
    }

    return ApiResponse.success(data: successCount);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Request timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to Google Sheets. Check your internet.';
      default:
        return 'Sheets API error. Please try again.';
    }
  }

  String generateId() => _uuid.v4();

  DateTime parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    return DateTime.tryParse(dateStr) ?? DateTime.now();
  }

  double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  int parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  bool parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    if (value is num) return value != 0;
    return false;
  }

  String? nullIfEmpty(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  Map<String, dynamic> cleanRow(Map<String, dynamic> row) {
    return Map<String, dynamic>.from(
      row)..removeWhere((key, value) => value == null);
  }
}
