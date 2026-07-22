import '../models/dto/api_response.dart';
import '../models/dto/login_dto.dart';
import '../models/dto/register_dto.dart';
import '../models/entities/user.dart';
import '../services/firebase_auth_service.dart';
import '../services/google_sheets_service.dart';
import '../services/storage_service.dart';

class AuthRepository {
  final FirebaseAuthService _firebaseAuth;
  final GoogleSheetsService _sheets;
  final StorageService _storage;

  AuthRepository({
    required FirebaseAuthService firebaseAuth,
    required GoogleSheetsService sheets,
    required StorageService storage,
  })  : _firebaseAuth = firebaseAuth,
        _sheets = sheets,
        _storage = storage;

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

  Future<ApiResponse<User>> getCurrentUser({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final local = await _storage.getUser();
      if (local != null) {
        return ApiResponse.success(data: local);
      }
    }

    return _firebaseAuth.getCurrentUser();
  }

  Future<ApiResponse<void>> updateProfile(Map<String, dynamic> data) async {
    return _firebaseAuth.updateProfile(data);
  }

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

  Future<ApiResponse<void>> changePassword(String current, String newPassword) async {
    return _firebaseAuth.changePassword(current, newPassword);
  }

  Future<bool> hasSession() async {
    return _firebaseAuth.isAuthenticated;
  }

  Future<void> clearSession() async {
    await _storage.clearAll();
  }

  Stream<dynamic> get authStateChanges => _firebaseAuth.authStateChanges;
}
