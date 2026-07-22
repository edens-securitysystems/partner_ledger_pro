import 'package:local_auth/local_auth.dart';

import '../models/dto/api_response.dart';
import '../models/dto/login_dto.dart';
import '../models/dto/register_dto.dart';
import '../models/entities/user.dart';
import 'firebase_auth_service.dart';
import 'google_sheets_service.dart';
import 'storage_service.dart';

class AuthService {
  final FirebaseAuthService _firebaseAuth;
  final GoogleSheetsService _sheets;
  final StorageService _storage;
  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthService({
    required FirebaseAuthService firebaseAuth,
    required GoogleSheetsService sheets,
    required StorageService storage,
  })  : _firebaseAuth = firebaseAuth,
        _sheets = sheets,
        _storage = storage;

  bool get isAuthenticated => _firebaseAuth.isAuthenticated;

  Future<ApiResponse<LoginResponse>> login(String email, String password) async {
    return _firebaseAuth.login(email, password);
  }

  Future<ApiResponse<LoginResponse>> register(RegisterRequest request) async {
    final result = await _firebaseAuth.register(request);

    if (result.success && result.data != null && _sheets.isConfigured) {
      final user = result.data!.user;
      await _sheets.create('users', user.toMap());
    }

    return result;
  }

  Future<ApiResponse<void>> logout() async {
    return _firebaseAuth.logout();
  }

  Future<ApiResponse<void>> sendEmailVerification() async {
    return _firebaseAuth.sendEmailVerification();
  }

  Future<ApiResponse<void>> reloadUser() async {
    return _firebaseAuth.reloadUser();
  }

  bool get isEmailVerified => _firebaseAuth.isEmailVerified;

  Future<ApiResponse<String>> refreshToken() async {
    final token = await _firebaseAuth.refreshToken();
    if (token != null) {
      return ApiResponse.success(data: token);
    }
    return ApiResponse.error(message: 'Token refresh failed');
  }

  Future<ApiResponse<void>> forgotPassword(String email) async {
    return _firebaseAuth.forgotPassword(email);
  }

  Future<ApiResponse<void>> resetPassword(String token, String password) async {
    return _firebaseAuth.resetPassword(token, password);
  }

  Future<ApiResponse<void>> changePassword(String currentPassword, String newPassword) async {
    return _firebaseAuth.changePassword(currentPassword, newPassword);
  }

  Future<ApiResponse<User>> updateProfile(Map<String, dynamic> data) async {
    return _firebaseAuth.updateProfile(data);
  }

  Future<ApiResponse<String>> biometricLogin() async {
    try {
      final available = await _localAuth.canCheckBiometrics;
      if (!available) {
        return ApiResponse.error(message: 'Biometrics not available on this device');
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Partner Ledger Pro',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!authenticated) {
        return ApiResponse.error(message: 'Biometric authentication failed');
      }

      final token = await _firebaseAuth.refreshToken();
      if (token == null) {
        return ApiResponse.error(message: 'No session found. Please login.');
      }

      return ApiResponse.success(data: token);
    } catch (e) {
      return ApiResponse.error(message: 'Biometric login failed', error: e.toString());
    }
  }

  Future<ApiResponse<bool>> validatePin(String pin) async {
    try {
      final storedPin = await _storage.getPin();
      if (storedPin == null) {
        return ApiResponse.error(message: 'No PIN configured');
      }
      return ApiResponse.success(data: storedPin == pin);
    } catch (e) {
      return ApiResponse.error(message: 'PIN validation failed');
    }
  }

  Future<ApiResponse<void>> setupPin(String pin) async {
    try {
      await _storage.setPin(pin);
      return ApiResponse.success(data: null);
    } catch (e) {
      return ApiResponse.error(message: 'Failed to set PIN');
    }
  }

  Future<ApiResponse<void>> changePin(String oldPin, String newPin) async {
    try {
      final storedPin = await _storage.getPin();
      if (storedPin == null) {
        return ApiResponse.error(message: 'No PIN configured');
      }
      if (storedPin != oldPin) {
        return ApiResponse.error(message: 'Current PIN is incorrect');
      }
      await _storage.setPin(newPin);
      return ApiResponse.success(data: null);
    } catch (e) {
      return ApiResponse.error(message: 'Failed to change PIN');
    }
  }

  Future<bool> isSessionExpired() async {
    final expiry = await _storage.getSessionExpiry();
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry);
  }

  Future<ApiResponse<bool>> checkSession() async {
    return _firebaseAuth.checkSession();
  }

  Future<ApiResponse<User>> getCurrentUser() async {
    return _firebaseAuth.getCurrentUser();
  }
}
