import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../entities/user.dart';

class LoginRequest extends Equatable {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  LoginRequest copyWith({
    String? email,
    String? password,
  }) {
    return LoginRequest(
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'password': password,
    };
  }

  factory LoginRequest.fromMap(Map<String, dynamic> map) {
    return LoginRequest(
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory LoginRequest.fromJson(String source) {
    return LoginRequest.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }

  @override
  List<Object?> get props => [email, password];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginRequest &&
        other.email == email &&
        other.password == password;
  }

  @override
  int get hashCode => Object.hash(email, password);

  @override
  String toString() => 'LoginRequest(email: $email)';
}

class LoginResponse extends Equatable {
  final String token;
  final String refreshToken;
  final User user;
  final DateTime expiresAt;

  const LoginResponse({
    required this.token,
    required this.refreshToken,
    required this.user,
    required this.expiresAt,
  });

  LoginResponse copyWith({
    String? token,
    String? refreshToken,
    User? user,
    DateTime? expiresAt,
  }) {
    return LoginResponse(
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      user: user ?? this.user,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'token': token,
      'refreshToken': refreshToken,
      'user': user.toJsonMap(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory LoginResponse.fromMap(Map<String, dynamic> map) {
    return LoginResponse(
      token: map['token'] as String,
      refreshToken: map['refreshToken'] as String,
      user: User.fromJsonMap(map['user'] as Map<String, dynamic>),
      expiresAt: DateTime.parse(map['expiresAt'] as String),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory LoginResponse.fromJson(String source) {
    return LoginResponse.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  @override
  List<Object?> get props => [token, refreshToken, user, expiresAt];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginResponse &&
        other.token == token &&
        other.refreshToken == refreshToken &&
        other.user == user &&
        other.expiresAt == expiresAt;
  }

  @override
  int get hashCode => Object.hash(token, refreshToken, user, expiresAt);

  @override
  String toString() {
    return 'LoginResponse(user: ${user.name}, expiresAt: $expiresAt)';
  }
}
