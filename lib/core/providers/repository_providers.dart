import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/auth_repository.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/invite_repository.dart';
import '../repositories/ledger_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/partner_repository.dart';
import '../repositories/report_repository.dart';
import '../repositories/transaction_repository.dart';
import 'service_providers.dart';

// ── Auth Repository ─────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    sheets: ref.watch(googleSheetsServiceProvider),
    storage: ref.watch(storageServiceProvider),
  );
});

// ── Partner Repository ──────────────────────────────────────────────────────

final partnerRepositoryProvider = Provider<PartnerRepository>((ref) {
  return PartnerRepository(
    sheets: ref.watch(googleSheetsServiceProvider),
    storage: ref.watch(storageServiceProvider),
  );
});

// ── Transaction Repository ──────────────────────────────────────────────────

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(
    sheets: ref.watch(googleSheetsServiceProvider),
    storage: ref.watch(storageServiceProvider),
  );
});

// ── Ledger Repository ───────────────────────────────────────────────────────

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  return LedgerRepository(
    sheets: ref.watch(googleSheetsServiceProvider),
    storage: ref.watch(storageServiceProvider),
  );
});

// ── Dashboard Repository ────────────────────────────────────────────────────

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(
    sheets: ref.watch(googleSheetsServiceProvider),
    storage: ref.watch(storageServiceProvider),
  );
});

// ── Notification Repository ─────────────────────────────────────────────────

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(
    sheets: ref.watch(googleSheetsServiceProvider),
    storage: ref.watch(storageServiceProvider),
  );
});

// ── Report Repository ───────────────────────────────────────────────────────

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(
    sheets: ref.watch(googleSheetsServiceProvider),
    storage: ref.watch(storageServiceProvider),
  );
});

// ── Invite Repository ────────────────────────────────────────────────────────

final inviteRepositoryProvider = Provider<InviteRepository>((ref) {
  return InviteRepository(
    sheets: ref.watch(googleSheetsServiceProvider),
    storage: ref.watch(storageServiceProvider),
  );
});
