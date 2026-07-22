import '../config/sheets_config.dart';
import '../database/enums/database_enums.dart';
import '../models/dto/api_response.dart';
import '../models/entities/notification.dart';
import '../services/google_sheets_service.dart';
import '../services/storage_service.dart';

class NotificationRepository {
  final GoogleSheetsService _sheets;
  final StorageService _storage;

  NotificationRepository({
    required GoogleSheetsService sheets,
    required StorageService storage,
  })  : _sheets = sheets,
        _storage = storage;

  AppNotification _fromRow(Map<String, dynamic> row) {
    return AppNotification(
      id: '${row['id'] ?? ''}',
      userId: '${row['userId'] ?? ''}',
      businessId: row['businessId']?.toString(),
      title: '${row['title'] ?? ''}',
      message: '${row['message'] ?? ''}',
      type: NotificationType.fromValue(_sheets.parseInt(row['type'])),
      isRead: _sheets.parseBool(row['isRead']),
      referenceId: row['referenceId']?.toString(),
      referenceType: row['referenceType']?.toString(),
      createdAt: _sheets.parseDate(row['createdAt']?.toString()),
    );
  }

  Future<ApiResponse<List<AppNotification>>> getAll({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _sheets.getAll(SheetsConfig.sheetNotifications);

    if (response.success && response.data != null) {
      final notifications = response.data!.map(_fromRow).toList();
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _cacheNotifications(notifications);
      return ApiResponse.success(data: notifications);
    }

    return ApiResponse.success(data: await _getCached());
  }

  Future<ApiResponse<AppNotification>> getById(String id) async {
    final response = await _sheets.getById(SheetsConfig.sheetNotifications, id);

    if (response.success && response.data != null) {
      return ApiResponse.success(data: _fromRow(response.data!));
    }

    return ApiResponse.error(message: 'Notification not found');
  }

  Future<ApiResponse<void>> markAsRead(String id) async {
    if (_sheets.isConfigured) {
      final result = await _sheets.update(
        SheetsConfig.sheetNotifications,
        id,
        {'isRead': true},
      );
      if (result.success) return ApiResponse.success(data: null);
      return ApiResponse.error(message: result.message);
    }

    return ApiResponse.success(data: null);
  }

  Future<ApiResponse<void>> markAllAsRead() async {
    final response = await _sheets.getAll(SheetsConfig.sheetNotifications);
    if (response.success && response.data != null) {
      for (final row in response.data!) {
        if (_sheets.parseBool(row['isRead']) == false) {
          await _sheets.update(
            SheetsConfig.sheetNotifications,
            '${row['id'] ?? ''}',
            {'isRead': true},
          );
        }
      }
    }
    return ApiResponse.success(data: null);
  }

  Future<ApiResponse<void>> delete(String id) async {
    if (_sheets.isConfigured) {
      final result = await _sheets.delete(SheetsConfig.sheetNotifications, id);
      if (result.success) return ApiResponse.success(data: null);
      return ApiResponse.error(message: result.message);
    }

    return ApiResponse.success(data: null);
  }

  Future<ApiResponse<void>> deleteAll() async {
    final response = await _sheets.getAll(SheetsConfig.sheetNotifications);
    if (response.success && response.data != null) {
      for (final row in response.data!) {
        await _sheets.delete(
          SheetsConfig.sheetNotifications,
          '${row['id'] ?? ''}',
        );
      }
    }
    return ApiResponse.success(data: null);
  }

  Future<ApiResponse<int>> getUnreadCount() async {
    final cached = await _getCached();
    return ApiResponse.success(
      data: cached.where((n) => n.isUnread).length,
    );
  }

  Future<ApiResponse<void>> create({
    required String userId,
    required String title,
    required String message,
    NotificationType type = NotificationType.system,
    String? referenceId,
    String? referenceType,
    String? businessId,
  }) async {
    final id = _sheets.generateId();
    final now = DateTime.now();

    final notification = AppNotification(
      id: id,
      userId: userId,
      businessId: businessId,
      type: type,
      title: title,
      message: message,
      referenceId: referenceId,
      referenceType: referenceType,
      isRead: false,
      createdAt: now,
    );

    if (_sheets.isConfigured) {
      final result = await _sheets.create(
        SheetsConfig.sheetNotifications,
        notification.toMap(),
      );
      if (result.success) {
        // Update local cache
        final cached = await _getCached();
        cached.insert(0, notification);
        await _cacheNotifications(cached);
        return ApiResponse.success(data: null);
      }
      return ApiResponse.error(message: result.message);
    }

    // Cache locally if no sheets
    final cached = await _getCached();
    cached.insert(0, notification);
    await _cacheNotifications(cached);
    return ApiResponse.success(data: null);
  }

  Future<void> _cacheNotifications(List<AppNotification> notifications) async {
    final json = notifications.map((n) => n.toMap()).toList();
    await _storage.setPref('cached_notifications', json.toString());
  }

  Future<List<AppNotification>> _getCached() async {
    final cached = await _storage.getPref('cached_notifications');
    if (cached == null) return [];
    try {
      final list = (cached as List<dynamic>);
      return list
          .map((e) => AppNotification.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
