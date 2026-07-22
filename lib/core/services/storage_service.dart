import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/entities/user.dart';

class StorageService {
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUser = 'user_data';
  static const String _keyPin = 'user_pin';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyThemePreference = 'theme_preference';
  static const String _keyCurrency = 'currency';
  static const String _keyLanguage = 'language';
  static const String _keySessionExpiry = 'session_expiry';
  static const String _keyLastSync = 'last_sync';
  static const String _keyOnboardingComplete = 'onboarding_complete';

  late final FlutterSecureStorage _secureStorage;
  late SharedPreferences _prefs;

  static Future<StorageService> init() async {
    final service = StorageService._();
    service._secureStorage = const FlutterSecureStorage();
    service._prefs = await SharedPreferences.getInstance();
    return service;
  }

  StorageService._();

  // ── Token Management ─────────────────────────────────────────────────────

  Future<String?> getAccessToken() => _secureStorage.read(key: _keyAccessToken);
  Future<void> setAccessToken(String token) => _secureStorage.write(key: _keyAccessToken, value: token);
  Future<void> removeAccessToken() => _secureStorage.delete(key: _keyAccessToken);

  Future<String?> getRefreshToken() => _secureStorage.read(key: _keyRefreshToken);
  Future<void> setRefreshToken(String token) => _secureStorage.write(key: _keyRefreshToken, value: token);
  Future<void> removeRefreshToken() => _secureStorage.delete(key: _keyRefreshToken);

  Future<bool> hasTokens() async {
    final access = await getAccessToken();
    final refresh = await getRefreshToken();
    return access != null && refresh != null;
  }

  // ── User Data ────────────────────────────────────────────────────────────

  Future<User?> getUser() async {
    final data = await _secureStorage.read(key: _keyUser);
    if (data == null) return null;
    try {
      return User.fromJsonMap(jsonDecode(data) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> setUser(User user) async {
    await _secureStorage.write(key: _keyUser, value: jsonEncode(user.toJsonMap()));
  }

  Future<void> removeUser() async {
    await _secureStorage.delete(key: _keyUser);
  }

  // ── PIN & Biometrics ─────────────────────────────────────────────────────

  Future<String?> getPin() => _secureStorage.read(key: _keyPin);
  Future<void> setPin(String pin) => _secureStorage.write(key: _keyPin, value: pin);
  Future<void> removePin() => _secureStorage.delete(key: _keyPin);
  Future<bool> hasPin() async => (await getPin()) != null;

  Future<bool> isBiometricEnabled() async => _prefs.getBool(_keyBiometricEnabled) ?? false;
  Future<void> setBiometricEnabled(bool enabled) => _prefs.setBool(_keyBiometricEnabled, enabled);

  // ── App Settings ─────────────────────────────────────────────────────────

  Future<String?> getThemePreference() async => _prefs.getString(_keyThemePreference);
  Future<void> setThemePreference(String theme) => _prefs.setString(_keyThemePreference, theme);

  Future<String> getCurrency() async => _prefs.getString(_keyCurrency) ?? 'INR';
  Future<void> setCurrency(String currency) => _prefs.setString(_keyCurrency, currency);

  Future<String> getLanguage() async => _prefs.getString(_keyLanguage) ?? 'en';
  Future<void> setLanguage(String language) => _prefs.setString(_keyLanguage, language);

  // ── Session ──────────────────────────────────────────────────────────────

  Future<DateTime?> getSessionExpiry() async {
    final value = _prefs.getString(_keySessionExpiry);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<void> setSessionExpiry(DateTime expiry) =>
      _prefs.setString(_keySessionExpiry, expiry.toIso8601String());

  Future<bool> isSessionExpired() async {
    final expiry = await getSessionExpiry();
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry);
  }

  // ── Sync ─────────────────────────────────────────────────────────────────

  Future<DateTime?> getLastSync() async {
    final value = _prefs.getString(_keyLastSync);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<void> setLastSync(DateTime time) =>
      _prefs.setString(_keyLastSync, time.toIso8601String());

  // ── Onboarding ───────────────────────────────────────────────────────────

  Future<bool> isOnboardingComplete() async =>
      _prefs.getBool(_keyOnboardingComplete) ?? false;

  Future<void> setOnboardingComplete(bool complete) =>
      _prefs.setBool(_keyOnboardingComplete, complete);

  // ── Generic Storage ──────────────────────────────────────────────────────

  Future<String?> getValue(String key) => _secureStorage.read(key: key);
  Future<void> setValue(String key, String value) => _secureStorage.write(key: key, value: value);
  Future<void> removeValue(String key) => _secureStorage.delete(key: key);

  Future<String?> getPref(String key) async => _prefs.getString(key);
  Future<void> setPref(String key, String value) => _prefs.setString(key, value);

  // ── Clear All (Logout) ───────────────────────────────────────────────────

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _prefs.remove(_keyBiometricEnabled);
    await _prefs.remove(_keyThemePreference);
    await _prefs.remove(_keyCurrency);
    await _prefs.remove(_keyLanguage);
    await _prefs.remove(_keySessionExpiry);
    await _prefs.remove(_keyLastSync);
    await _prefs.remove(_keyOnboardingComplete);
  }
}
