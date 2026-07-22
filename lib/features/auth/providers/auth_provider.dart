import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/dto/register_dto.dart';
import '../../../core/models/entities/user.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/services/auth_service.dart';

// ── State ────────────────────────────────────────────────────────────────────

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final String? error;
  final bool isSessionTimedOut;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.isSessionTimedOut = false,
  });

  const AuthState.initial() : this();

  const AuthState.loading() : this(status: AuthStatus.loading);

  const AuthState.authenticated(User user)
      : this(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated({String? error})
      : this(status: AuthStatus.unauthenticated, error: error);

  const AuthState.error(String error)
      : this(status: AuthStatus.error, error: error);

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
    bool? isSessionTimedOut,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
      isSessionTimedOut: isSessionTimedOut ?? this.isSessionTimedOut,
    );
  }

  @override
  List<Object?> get props => [status, user, error, isSessionTimedOut];
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier({required AuthService authService})
      : _authService = authService,
        super(const AuthState.initial());

  Future<void> login({required String email, required String password}) async {
    state = const AuthState.loading();
    final response = await _authService.login(email, password);
    if (response.success && response.data != null) {
      state = AuthState.authenticated(response.data!.user);
    } else {
      state = AuthState.unauthenticated(
        error: response.message,
      );
    }
  }

  Future<void> register({required RegisterRequest request}) async {
    state = const AuthState.loading();
    final response = await _authService.register(request);
    if (response.success && response.data != null) {
      state = AuthState.authenticated(response.data!.user);
    } else {
      state = AuthState.unauthenticated(
        error: response.message,
      );
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState.unauthenticated();
  }

  Future<void> biometricLogin() async {
    state = const AuthState.loading();
    final response = await _authService.biometricLogin();
    if (response.success) {
      final userResponse = await _authService.getCurrentUser();
      if (userResponse.success && userResponse.data != null) {
        state = AuthState.authenticated(userResponse.data!);
      } else {
        state = const AuthState.unauthenticated(
          error: 'Failed to load user data',
        );
      }
    } else {
      state = AuthState.unauthenticated(
        error: response.message,
      );
    }
  }

  Future<bool> validatePin(String pin) async {
    final response = await _authService.validatePin(pin);
    if (response.success && response.data == true) {
      final userResponse = await _authService.getCurrentUser();
      if (userResponse.success && userResponse.data != null) {
        state = AuthState.authenticated(userResponse.data!);
      }
      return true;
    }
    return false;
  }

  Future<bool> checkSession() async {
    final response = await _authService.checkSession();
    if (response.success && response.data == true) {
      final userResponse = await _authService.getCurrentUser();
      if (userResponse.success && userResponse.data != null) {
        state = AuthState.authenticated(userResponse.data!);
        return true;
      }
    }
    state = const AuthState.unauthenticated();
    return false;
  }

  void handleSessionTimeout() {
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      isSessionTimedOut: true,
    );
  }

  void clearError() {
    state = state.copyWith(error: null, status: AuthStatus.unauthenticated);
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService: authService);
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).status == AuthStatus.authenticated;
});

final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).status == AuthStatus.loading;
});
