import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/sheets_config.dart';
import '../models/dto/api_response.dart';
import 'google_sheets_service.dart';
import 'native_backup_helper_export.dart';

class BackupService {
  final GoogleSheetsService _sheets;

  BackupService(this._sheets);

  static const _sheetsToBackup = [
    SheetsConfig.sheetUsers,
    SheetsConfig.sheetBusinesses,
    SheetsConfig.sheetPartners,
    SheetsConfig.sheetTransactions,
    SheetsConfig.sheetLedgerEntries,
    SheetsConfig.sheetNotifications,
    SheetsConfig.sheetUpdateRequests,
    SheetsConfig.sheetApprovals,
    SheetsConfig.sheetPartnerInvites,
  ];

  Future<ApiResponse<BackupResult>> createBackup() async {
    if (!_sheets.isConfigured) {
      return ApiResponse.error(message: 'Google Sheets not configured');
    }

    try {
      final backupData = <String, dynamic>{
        'version': '1.0',
        'createdAt': DateTime.now().toIso8601String(),
        'sheets': <String, List<Map<String, dynamic>>>{},
      };

      final sheetsData =
          backupData['sheets'] as Map<String, List<Map<String, dynamic>>>;

      for (final sheet in _sheetsToBackup) {
        final response = await _sheets.getAll(sheet);
        if (response.success && response.data != null) {
          sheetsData[sheet] = response.data!;
        } else {
          sheetsData[sheet] = [];
        }
      }

      final jsonStr = const JsonEncoder.withIndent('  ').convert(backupData);
      final bytes = utf8.encode(jsonStr);

      if (kIsWeb) {
        return ApiResponse.success(
          data: BackupResult(
            filePath: null,
            sizeBytes: bytes.length,
            sheetCount: sheetsData.length,
            totalRecords: sheetsData.values.fold(
              0,
              (sum, rows) => sum + rows.length,
            ),
          ),
          message: jsonStr,
        );
      }

      final fileName =
          'partner_ledger_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final filePath = await writeBackupFile(fileName, bytes);

      return ApiResponse.success(
        data: BackupResult(
          filePath: filePath,
          sizeBytes: bytes.length,
          sheetCount: sheetsData.length,
          totalRecords: sheetsData.values.fold(
            0,
            (sum, rows) => sum + rows.length,
          ),
        ),
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Backup failed',
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<RestoreResult>> restoreFromJson(String jsonStr) async {
    if (!_sheets.isConfigured) {
      return ApiResponse.error(message: 'Google Sheets not configured');
    }

    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final sheets = data['sheets'] as Map<String, dynamic>?;

      if (sheets == null) {
        return ApiResponse.error(message: 'Invalid backup file format');
      }

      int totalRestored = 0;
      int sheetsRestored = 0;

      for (final sheet in _sheetsToBackup) {
        final rows = sheets[sheet];
        if (rows is List && rows.isNotEmpty) {
          int sheetCount = 0;
          for (final row in rows) {
            final rowMap = Map<String, dynamic>.from(row as Map);
            final response = await _sheets.create(sheet, rowMap);
            if (response.success) sheetCount++;
          }
          totalRestored += sheetCount;
          sheetsRestored++;
        }
      }

      return ApiResponse.success(
        data: RestoreResult(
          sheetsRestored: sheetsRestored,
          totalRecordsRestored: totalRestored,
        ),
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Restore failed',
        error: e.toString(),
      );
    }
  }
}

class BackupResult {
  final String? filePath;
  final int sizeBytes;
  final int sheetCount;
  final int totalRecords;

  BackupResult({
    required this.filePath,
    required this.sizeBytes,
    required this.sheetCount,
    required this.totalRecords,
  });

  String get sizeDisplay {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class RestoreResult {
  final int sheetsRestored;
  final int totalRecordsRestored;

  RestoreResult({
    required this.sheetsRestored,
    required this.totalRecordsRestored,
  });
}
