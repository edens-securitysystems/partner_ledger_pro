import 'dart:convert';

import 'package:equatable/equatable.dart';

class RegisterRequest extends Equatable {
  final String name;
  final String email;
  final String password;
  final String? phone;
  final String? businessName;

  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    this.businessName,
  });

  RegisterRequest copyWith({
    String? name,
    String? email,
    String? password,
    String? phone,
    String? businessName,
  }) {
    return RegisterRequest(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      businessName: businessName ?? this.businessName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'businessName': businessName,
    };
  }

  factory RegisterRequest.fromMap(Map<String, dynamic> map) {
    return RegisterRequest(
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      phone: map['phone'] as String?,
      businessName: map['businessName'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory RegisterRequest.fromJson(String source) {
    return RegisterRequest.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  @override
  List<Object?> get props =>
      [name, email, password, phone, businessName];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RegisterRequest &&
        other.name == name &&
        other.email == email &&
        other.password == password &&
        other.phone == phone &&
        other.businessName == businessName;
  }

  @override
  int get hashCode {
    return Object.hash(name, email, password, phone, businessName);
  }

  @override
  String toString() {
    return 'RegisterRequest(name: $name, email: $email)';
  }
}
