import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:logger/logger.dart';

import '../database/enums/database_enums.dart';
import '../models/dto/api_response.dart';
import '../models/dto/login_dto.dart';
import '../models/dto/register_dto.dart';
import '../models/entities/user.dart' as app;
import 'storage_service.dart';

class FirebaseAuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final StorageService _storage;
  final Logger _logger = Logger();

  FirebaseAuthService({required StorageService storage}) : _storage = storage;

  fb.User? get firebaseUser => _auth.currentUser;
  bool get isAuthenticated => firebaseUser != null;
  bool get isEmailVerified => firebaseUser?.emailVerified ?? false;

  Stream<fb.User?> get authStateChanges => _auth.authStateChanges();

  app.User? _mapFirebaseUser(fb.User? fbUser) {
    if (fbUser == null) return null;
    return app.User(
      id: fbUser.uid,
      email: fbUser.email ?? '',
      name: fbUser.displayName ?? fbUser.email?.split('@').first ?? 'User',
      phone: fbUser.phoneNumber,
      photo: fbUser.photoURL,
      role: UserRole.owner,
      createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
      updatedAt: fbUser.metadata.lastSignInTime ?? DateTime.now(),
      lastLogin: fbUser.metadata.lastSignInTime,
      isActive: true,
    );
  }

  Future<ApiResponse<LoginResponse>> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fbUser = credential.user;
      if (fbUser == null) {
        return ApiResponse.error(message: 'Login failed: no user returned');
      }

      final user = _mapFirebaseUser(fbUser)!;
      final token = await fbUser.getIdToken();
      final refreshToken = fbUser.refreshToken ?? '';

      await _storage.setAccessToken(token ?? '');
      await _storage.setRefreshToken(refreshToken);
      await _storage.setUser(user);
      await _storage.setSessionExpiry(
        DateTime.now().add(const Duration(hours: 12)),
      );

      _logger.i('Firebase login successful: ${fbUser.email}');

      return ApiResponse.success(
        data: LoginResponse(
          token: token ?? '',
          refreshToken: refreshToken,
          user: user,
          expiresAt: DateTime.now().add(const Duration(hours: 12)),
        ),
      );
    } on fb.FirebaseAuthException catch (e) {
      _logger.e('Firebase login error: ${e.code}');
      return ApiResponse.error(
        message: _mapAuthError(e.code),
        error: e.message,
        errorCode: e.code,
      );
    } catch (e) {
      _logger.e('Login error: $e');
      return ApiResponse.error(
        message: 'Login failed',
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<LoginResponse>> register(RegisterRequest request) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: request.email,
        password: request.password,
      );

      final fbUser = credential.user;
      if (fbUser == null) {
        return ApiResponse.error(message: 'Registration failed: no user returned');
      }

      await fbUser.updateDisplayName(request.name);

      try {
        await fbUser.sendEmailVerification();
        _logger.i('Verification email sent to: ${fbUser.email}');
      } catch (e) {
        _logger.w('Failed to send verification email: $e');
      }

      final user = app.User(
        id: fbUser.uid,
        email: request.email,
        name: request.name,
        phone: request.phone,
        role: UserRole.owner,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      final token = await fbUser.getIdToken();
      final refreshToken = fbUser.refreshToken ?? '';

      await _storage.setAccessToken(token ?? '');
      await _storage.setRefreshToken(refreshToken);
      await _storage.setUser(user);
      await _storage.setSessionExpiry(
        DateTime.now().add(const Duration(hours: 12)),
      );

      _logger.i('Firebase registration successful: ${fbUser.email}');

      return ApiResponse.success(
        data: LoginResponse(
          token: token ?? '',
          refreshToken: refreshToken,
          user: user,
          expiresAt: DateTime.now().add(const Duration(hours: 12)),
        ),
      );
    } on fb.FirebaseAuthException catch (e) {
      _logger.e('Firebase registration error: ${e.code}');
      return ApiResponse.error(
        message: _mapAuthError(e.code),
        error: e.message,
        errorCode: e.code,
      );
    } catch (e) {
      _logger.e('Registration error: $e');
      return ApiResponse.error(
        message: 'Registration failed',
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<void>> sendEmailVerification() async {
    try {
      final fbUser = _auth.currentUser;
      if (fbUser == null) {
        return ApiResponse.error(message: 'No user logged in');
      }
      if (fbUser.emailVerified) {
        return ApiResponse.success(data: null);
      }
      await fbUser.sendEmailVerification();
      _logger.i('Verification email sent to: ${fbUser.email}');
      return ApiResponse.success(data: null);
    } catch (e) {
      _logger.e('Failed to send verification email: $e');
      return ApiResponse.error(
        message: 'Failed to send verification email',
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<void>> reloadUser() async {
    try {
      final fbUser = _auth.currentUser;
      if (fbUser == null) {
        return ApiResponse.error(message: 'No user logged in');
      }
      await fbUser.reload();
      return ApiResponse.success(data: null);
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to refresh user',
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<void>> logout() async {
    try {
      await _auth.signOut();
      await _storage.clearAll();
      _logger.i('Firebase logout successful');
      return ApiResponse.success(data: null);
    } catch (e) {
      return ApiResponse.error(message: 'Logout failed', error: e.toString());
    }
  }

  Future<ApiResponse<void>> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _logger.i('Password reset email sent to: $email');
      return ApiResponse.success(data: null);
    } on fb.FirebaseAuthException catch (e) {
      return ApiResponse.error(
        message: _mapAuthError(e.code),
        error: e.message,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to send reset email',
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<void>> resetPassword(String oobCode, String newPassword) async {
    try {
      await _auth.confirmPasswordReset(
        code: oobCode,
        newPassword: newPassword,
      );
      return ApiResponse.success(data: null);
    } on fb.FirebaseAuthException catch (e) {
      return ApiResponse.error(
        message: _mapAuthError(e.code),
        error: e.message,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Password reset failed',
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<void>> changePassword(String currentPassword, String newPassword) async {
    try {
      final fbUser = _auth.currentUser;
      if (fbUser == null) {
        return ApiResponse.error(message: 'No user logged in');
      }

      final credential = fb.EmailAuthProvider.credential(
        email: fbUser.email!,
        password: currentPassword,
      );
      await fbUser.reauthenticateWithCredential(credential);
      await fbUser.updatePassword(newPassword);

      return ApiResponse.success(data: null);
    } on fb.FirebaseAuthException catch (e) {
      return ApiResponse.error(
        message: _mapAuthError(e.code),
        error: e.message,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Change password failed',
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<app.User>> updateProfile(Map<String, dynamic> data) async {
    try {
      final fbUser = _auth.currentUser;
      if (fbUser == null) {
        return ApiResponse.error(message: 'No user logged in');
      }

      if (data['name'] != null) {
        await fbUser.updateDisplayName(data['name'] as String);
      }
      if (data['photo'] != null) {
        await fbUser.updatePhotoURL(data['photo'] as String);
      }

      final updatedUser = _mapFirebaseUser(fbUser)!;
      await _storage.setUser(updatedUser);

      return ApiResponse.success(data: updatedUser);
    } catch (e) {
      return ApiResponse.error(
        message: 'Profile update failed',
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<app.User>> getCurrentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) {
      return ApiResponse.error(message: 'No user logged in');
    }

    final user = _mapFirebaseUser(fbUser);
    if (user != null) {
      await _storage.setUser(user);
    }

    return user != null
        ? ApiResponse.success(data: user)
        : ApiResponse.error(message: 'Failed to get user');
  }

  Future<ApiResponse<bool>> checkSession() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return ApiResponse.success(data: false);

    try {
      final token = await fbUser.getIdToken(true);
      await _storage.setAccessToken(token ?? '');
      return ApiResponse.success(data: true);
    } catch (_) {
      return ApiResponse.success(data: false);
    }
  }

  Future<String?> refreshToken() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    final token = await fbUser.getIdToken(true);
    if (token != null) {
      await _storage.setAccessToken(token);
    }
    return token;
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
