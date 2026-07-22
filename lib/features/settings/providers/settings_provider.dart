import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/services/storage_service.dart';

// ── State ────────────────────────────────────────────────────────────────────

class SettingsState extends Equatable {
  final bool isLoading;
  final String? error;
  final ThemeMode themeMode;
  final Currency currency;
  final String language;
  final bool notificationsEnabled;
  final bool isBackingUp;
  final bool isRestoring;
  final String? lastBackupDate;

  const SettingsState({
    this.isLoading = false,
    this.error,
    this.themeMode = ThemeMode.system,
    this.currency = Currency.inr,
    this.language = 'en',
    this.notificationsEnabled = true,
    this.isBackingUp = false,
    this.isRestoring = false,
    this.lastBackupDate,
  });

  const SettingsState.initial() : this();

  SettingsState copyWith({
    bool? isLoading,
    String? error,
    ThemeMode? themeMode,
    Currency? currency,
    String? language,
    bool? notificationsEnabled,
    bool? isBackingUp,
    bool? isRestoring,
    String? lastBackupDate,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      themeMode: themeMode ?? this.themeMode,
      currency: currency ?? this.currency,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isBackingUp: isBackingUp ?? this.isBackingUp,
      isRestoring: isRestoring ?? this.isRestoring,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        error,
        themeMode,
        currency,
        language,
        notificationsEnabled,
        isBackingUp,
        isRestoring,
        lastBackupDate,
      ];
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class SettingsNotifier extends StateNotifier<SettingsState> {
  final StorageService _storage;

  SettingsNotifier(this._storage) : super(const SettingsState.initial());

  void updateTheme(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _storage.setThemePreference(mode.name);
  }

  void updateCurrency(Currency currency) {
    state = state.copyWith(currency: currency);
    _storage.setCurrency(currency.code);
  }

  void updateLanguage(String language) {
    state = state.copyWith(language: language);
    _storage.setLanguage(language);
  }

  void updateNotifications(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
  }

  Future<void> backupData() async {
    state = state.copyWith(isBackingUp: true, error: null);
    try {
      await _storage.setLastSync(DateTime.now());
      state = state.copyWith(
        isBackingUp: false,
        lastBackupDate: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      state = state.copyWith(isBackingUp: false, error: e.toString());
    }
  }

  Future<void> restoreData() async {
    state = state.copyWith(isRestoring: true, error: null);
    try {
      await loadSettings();
      state = state.copyWith(isRestoring: false);
    } catch (e) {
      state = state.copyWith(isRestoring: false, error: e.toString());
    }
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true);
    try {
      final themeName = await _storage.getThemePreference();
      final currencyCode = await _storage.getCurrency();
      final language = await _storage.getLanguage();
      final lastSync = await _storage.getLastSync();

      ThemeMode themeMode = ThemeMode.system;
      if (themeName != null) {
        themeMode = ThemeMode.values.firstWhere(
          (t) => t.name == themeName,
          orElse: () => ThemeMode.system,
        );
      }

      Currency currency = Currency.inr;
      try {
        currency = Currency.values.firstWhere(
          (c) => c.name.toUpperCase() == currencyCode.toUpperCase(),
        );
      } catch (_) {
        currency = Currency.inr;
      }

      state = state.copyWith(
        isLoading: false,
        themeMode: themeMode,
        currency: currency,
        language: language,
        lastBackupDate: lastSync?.toIso8601String(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SettingsNotifier(storage);
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});

final currencyProvider = Provider<Currency>((ref) {
  return ref.watch(settingsProvider).currency;
});

final languageProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).language;
});

final notificationsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).notificationsEnabled;
});
