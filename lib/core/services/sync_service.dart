import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'google_sheets_service.dart';
import 'storage_service.dart';

enum SyncStatus {
  idle,
  syncing,
  completed,
  failed,
}

enum SyncOperationType {
  create,
  update,
  delete,
}

class SyncOperation {
  final String id;
  final String entityType;
  final SyncOperationType operation;
  final Map<String, dynamic> data;
  final String sheet;
  final DateTime createdAt;
  int retryCount;

  SyncOperation({
    required this.id,
    required this.entityType,
    required this.operation,
    required this.data,
    required this.sheet,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'entityType': entityType,
        'operation': operation.index,
        'data': data,
        'sheet': sheet,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
      };

  factory SyncOperation.fromMap(Map<String, dynamic> map) => SyncOperation(
        id: map['id'] as String,
        entityType: map['entityType'] as String,
        operation: SyncOperationType.values[map['operation'] as int],
        data: Map<String, dynamic>.from(map['data'] as Map),
        sheet: map['sheet'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        retryCount: map['retryCount'] as int? ?? 0,
      );
}

class SyncProgress {
  final int totalOperations;
  final int completedOperations;
  final int failedOperations;
  final String? currentEntity;

  const SyncProgress({
    this.totalOperations = 0,
    this.completedOperations = 0,
    this.failedOperations = 0,
    this.currentEntity,
  });

  double get percentage =>
      totalOperations > 0 ? completedOperations / totalOperations : 1.0;

  bool get isComplete => completedOperations + failedOperations >= totalOperations;

  SyncProgress copyWith({
    int? totalOperations,
    int? completedOperations,
    int? failedOperations,
    String? currentEntity,
  }) {
    return SyncProgress(
      totalOperations: totalOperations ?? this.totalOperations,
      completedOperations: completedOperations ?? this.completedOperations,
      failedOperations: failedOperations ?? this.failedOperations,
      currentEntity: currentEntity ?? this.currentEntity,
    );
  }
}

typedef SyncProgressCallback = void Function(SyncProgress progress);

class SyncService {
  static const String _queueKey = 'sync_queue';
  static const int _maxRetries = 3;

  final GoogleSheetsService _sheets;
  final StorageService _storage;
  final Connectivity _connectivity = Connectivity();

  SyncStatus _status = SyncStatus.idle;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  SyncProgressCallback? _onProgress;

  SyncService({
    required GoogleSheetsService sheets,
    required StorageService storage,
  })  : _sheets = sheets,
        _storage = storage;

  SyncStatus get status => _status;

  void setProgressCallback(SyncProgressCallback callback) {
    _onProgress = callback;
  }

  Future<void> initialize() async {
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        syncPendingOperations();
      }
    });
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
  }

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<void> enqueueOperation(SyncOperation operation) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await _getQueue(prefs);
    queue.add(operation.toMap());
    await prefs.setString(_queueKey, jsonEncode(queue));
  }

  Future<List<SyncOperation>> getPendingOperations() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await _getQueue(prefs);
    return queue.map((m) => SyncOperation.fromMap(m)).toList();
  }

  Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await _getQueue(prefs);
    return queue.length;
  }

  Future<void> syncPendingOperations() async {
    if (!_sheets.isConfigured) return;
    if (_status == SyncStatus.syncing) return;

    final online = await isOnline();
    if (!online) return;

    _status = SyncStatus.syncing;
    final prefs = await SharedPreferences.getInstance();
    final queue = await _getQueue(prefs);

    if (queue.isEmpty) {
      _status = SyncStatus.idle;
      return;
    }

    final operations = queue.map((m) => SyncOperation.fromMap(m)).toList();
    var completed = 0;
    var failed = 0;

    _onProgress?.call(SyncProgress(
      totalOperations: operations.length,
      completedOperations: 0,
      failedOperations: 0,
    ));

    final remaining = <Map<String, dynamic>>[];

    for (final op in operations) {
      if (op.retryCount >= _maxRetries) {
        failed++;
        continue;
      }

      _onProgress?.call(SyncProgress(
        totalOperations: operations.length,
        completedOperations: completed,
        failedOperations: failed,
        currentEntity: op.entityType,
      ));

      try {
        final success = await _executeOperation(op);
        if (success) {
          completed++;
        } else {
          op.retryCount++;
          remaining.add(op.toMap());
          failed++;
        }
      } catch (_) {
        op.retryCount++;
        remaining.add(op.toMap());
        failed++;
      }
    }

    await prefs.setString(_queueKey, jsonEncode(remaining));
    await _storage.setLastSync(DateTime.now());

    _status = completed > 0 ? SyncStatus.completed : SyncStatus.failed;

    _onProgress?.call(SyncProgress(
      totalOperations: operations.length,
      completedOperations: completed,
      failedOperations: failed,
    ));

    Future.delayed(const Duration(seconds: 2), () {
      _status = SyncStatus.idle;
    });
  }

  Future<bool> _executeOperation(SyncOperation op) async {
    try {
      switch (op.operation) {
        case SyncOperationType.create:
          final result = await _sheets.create(op.sheet, op.data);
          return result.success;
        case SyncOperationType.update:
          final id = op.data['id'] as String? ?? op.id;
          final result = await _sheets.update(op.sheet, id, op.data);
          return result.success;
        case SyncOperationType.delete:
          final result = await _sheets.delete(op.sheet, op.id);
          return result.success;
      }
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> _getQueue(SharedPreferences prefs) async {
    final raw = prefs.getString(_queueKey);
    if (raw == null) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
    } catch (_) {
      return [];
    }
  }

  Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
  }

  Future<void> clearFailedOperations() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await _getQueue(prefs);
    final filtered = queue.where((m) {
      final op = SyncOperation.fromMap(m);
      return op.retryCount < _maxRetries;
    }).toList();
    await prefs.setString(_queueKey, jsonEncode(filtered));
  }
}
