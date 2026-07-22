import 'package:equatable/equatable.dart';

import '../../database/enums/database_enums.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? photo;
  final UserRole role;
  final String? businessId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLogin;
  final bool isActive;
  final String? pin;
  final bool biometricEnabled;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.photo,
    this.role = UserRole.viewer,
    this.businessId,
    required this.createdAt,
    required this.updatedAt,
    this.lastLogin,
    this.isActive = true,
    this.pin,
    this.biometricEnabled = false,
  });

  bool get isOwner => role == UserRole.owner;
  bool get isAdmin => role == UserRole.admin || role == UserRole.owner;
  bool get isManager =>
      role == UserRole.manager ||
      role == UserRole.admin ||
      role == UserRole.owner;
  bool get isAccountant =>
      role == UserRole.accountant ||
      role == UserRole.manager ||
      role == UserRole.admin ||
      role == UserRole.owner;

  bool get canManageBusiness =>
      role == UserRole.owner || role == UserRole.admin;
  bool get canManagePartners => role != UserRole.viewer;
  bool get canCreateTransactions =>
      role == UserRole.owner ||
      role == UserRole.admin ||
      role == UserRole.manager ||
      role == UserRole.accountant;
  bool get canDeleteTransactions =>
      role == UserRole.owner || role == UserRole.admin;
  bool get canViewReports =>
      role == UserRole.owner ||
      role == UserRole.admin ||
      role == UserRole.manager ||
      role == UserRole.accountant;
  bool get canManageUsers => role == UserRole.owner;
  bool get canExportData =>
      role == UserRole.owner ||
      role == UserRole.admin ||
      role == UserRole.manager;

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? photo,
    UserRole? role,
    String? businessId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
    bool? isActive,
    String? pin,
    bool? biometricEnabled,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photo: photo ?? this.photo,
      role: role ?? this.role,
      businessId: businessId ?? this.businessId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      pin: pin ?? this.pin,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'photo': photo,
      'role': role.value,
      'businessId': businessId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'isActive': isActive,
      'pin': pin,
      'biometricEnabled': biometricEnabled,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      photo: map['photo'] as String?,
      role: UserRole.fromValue(map['role'] as int),
      businessId: map['businessId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      lastLogin: map['lastLogin'] != null
          ? DateTime.parse(map['lastLogin'] as String)
          : null,
      isActive: map['isActive'] as bool? ?? true,
      pin: map['pin'] as String?,
      biometricEnabled: map['biometricEnabled'] as bool? ?? false,
    );
  }

  String toJson() => throw UnimplementedError();

  factory User.fromJson(String source) =>
      throw UnimplementedError();

  Map<String, dynamic> toJsonMap() => toMap();

  factory User.fromJsonMap(Map<String, dynamic> json) =>
      User.fromMap(json);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.phone == phone &&
        other.photo == photo &&
        other.role == role &&
        other.businessId == businessId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.lastLogin == lastLogin &&
        other.isActive == isActive &&
        other.pin == pin &&
        other.biometricEnabled == biometricEnabled;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      email,
      name,
      phone,
      photo,
      role,
      businessId,
      createdAt,
      updatedAt,
      lastLogin,
      isActive,
      pin,
      biometricEnabled,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, role: $role, '
        'businessId: $businessId, isActive: $isActive)';
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        phone,
        photo,
        role,
        businessId,
        createdAt,
        updatedAt,
        lastLogin,
        isActive,
        pin,
        biometricEnabled,
      ];

  Map<String, dynamic> toSessionMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.value,
      'businessId': businessId,
      'photo': photo,
    };
  }
}
