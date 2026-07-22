import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/dashboard_repository.dart';
import '../repositories/partner_repository.dart';
import '../repositories/partner_approval_repository.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/notification_repository.dart';
import '../services/auth_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/google_sheets_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

// ── Storage ──────────────────────────────────────────────────────

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('Initialize StorageService in main() and override this provider');
});

// ── Google Sheets ────────────────────────────────────────────────

final googleSheetsServiceProvider = Provider<GoogleSheetsService>((ref) {
  return GoogleSheetsService();
});

// ── Firebase Auth ────────────────────────────────────────────────

final firebaseAuthProvider = Provider<FirebaseAuthService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return FirebaseAuthService(storage: storage);
});

// ── Auth Service (facade over Firebase + Sheets + local auth) ────

final authServiceProvider = Provider<AuthService>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final sheets = ref.watch(googleSheetsServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthService(
    firebaseAuth: firebaseAuth,
    sheets: sheets,
    storage: storage,
  );
});

// ── Notifications ────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// ── Repositories ─────────────────────────────────────────────────

final partnerRepositoryProvider = Provider<PartnerRepository>((ref) {
  final sheets = ref.watch(googleSheetsServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  return PartnerRepository(sheets: sheets, storage: storage);
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final sheets = ref.watch(googleSheetsServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  return TransactionRepository(sheets: sheets, storage: storage);
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final sheets = ref.watch(googleSheetsServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  return DashboardRepository(sheets: sheets, storage: storage);
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final sheets = ref.watch(googleSheetsServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  return NotificationRepository(sheets: sheets, storage: storage);
});

final partnerApprovalRepositoryProvider = Provider<PartnerApprovalRepository>((ref) {
  final sheets = ref.watch(googleSheetsServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  return PartnerApprovalRepository(sheets: sheets, storage: storage);
});
