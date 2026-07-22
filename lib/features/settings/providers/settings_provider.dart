import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';

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
  SettingsNotifier() : super(const SettingsState.initial());

  void updateTheme(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    // _persistSetting('theme_mode', mode.name);
  }

  void updateCurrency(Currency currency) {
    state = state.copyWith(currency: currency);
    // _persistSetting('currency', currency.code);
  }

  void updateLanguage(String language) {
    state = state.copyWith(language: language);
    // _persistSetting('language', language);
  }

  void updateNotifications(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
    // _persistSetting('notifications_enabled', enabled.toString());
  }

  Future<void> backupData() async {
    state = state.copyWith(isBackingUp: true, error: null);
    try {
      // final date = await _settingsService.backupData();
      // state = state.copyWith(isBackingUp: false, lastBackupDate: date);
      await Future.delayed(const Duration(milliseconds: 500));
      state = state.copyWith(isBackingUp: false, lastBackupDate: DateTime.now().toIso8601String());
    } catch (e) {
      state = state.copyWith(isBackingUp: false, error: e.toString());
    }
  }

  Future<void> restoreData() async {
    state = state.copyWith(isRestoring: true, error: null);
    try {
      // await _settingsService.restoreData();
      await Future.delayed(const Duration(milliseconds: 500));
      state = state.copyWith(isRestoring: false);
    } catch (e) {
      state = state.copyWith(isRestoring: false, error: e.toString());
    }
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true);
    try {
      // final theme = await _settingsService.getSetting('theme_mode');
      // final currency = await _settingsService.getSetting('currency');
      // ...
      await Future.delayed(const Duration(milliseconds: 200));
      state = state.copyWith(isLoading: false);
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
  return SettingsNotifier();
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
