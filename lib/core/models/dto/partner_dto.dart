import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../../database/enums/database_enums.dart';

class CreatePartnerRequest extends Equatable {
  final String name;
  final String? email;
  final String? phone;
  final String? photo;
  final double capital;
  final double ownershipPercentage;
  final DateTime joiningDate;
  final PartnerStatus status;
  final String? description;

  const CreatePartnerRequest({
    required this.name,
    this.email,
    this.phone,
    this.photo,
    this.capital = 0.0,
    this.ownershipPercentage = 0.0,
    required this.joiningDate,
    this.status = PartnerStatus.active,
    this.description,
  });

  CreatePartnerRequest copyWith({
    String? name,
    String? email,
    String? phone,
    String? photo,
    double? capital,
    double? ownershipPercentage,
    DateTime? joiningDate,
    PartnerStatus? status,
    String? description,
  }) {
    return CreatePartnerRequest(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photo: photo ?? this.photo,
      capital: capital ?? this.capital,
      ownershipPercentage:
          ownershipPercentage ?? this.ownershipPercentage,
      joiningDate: joiningDate ?? this.joiningDate,
      status: status ?? this.status,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'photo': photo,
      'capital': capital,
      'ownershipPercentage': ownershipPercentage,
      'joiningDate': joiningDate.toIso8601String(),
      'status': status.value,
      'description': description,
    };
  }

  factory CreatePartnerRequest.fromMap(Map<String, dynamic> map) {
    return CreatePartnerRequest(
      name: map['name'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      photo: map['photo'] as String?,
      capital: (map['capital'] as num?)?.toDouble() ?? 0.0,
      ownershipPercentage:
          (map['ownershipPercentage'] as num?)?.toDouble() ?? 0.0,
      joiningDate: DateTime.parse(map['joiningDate'] as String),
      status: PartnerStatus.fromValue(map['status'] as int? ?? 0),
      description: map['description'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory CreatePartnerRequest.fromJson(String source) {
    return CreatePartnerRequest.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  @override
  List<Object?> get props => [
        name,
        email,
        phone,
        photo,
        capital,
        ownershipPercentage,
        joiningDate,
        status,
        description,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreatePartnerRequest &&
        other.name == name &&
        other.email == email &&
        other.phone == phone &&
        other.photo == photo &&
        other.capital == capital &&
        other.ownershipPercentage == ownershipPercentage &&
        other.joiningDate == joiningDate &&
        other.status == status &&
        other.description == description;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      email,
      phone,
      photo,
      capital,
      ownershipPercentage,
      joiningDate,
      status,
      description,
    );
  }

  @override
  String toString() {
    return 'CreatePartnerRequest(name: $name, capital: $capital, '
        'ownershipPercentage: $ownershipPercentage)';
  }
}

class UpdatePartnerRequest extends Equatable {
  final String? name;
  final String? email;
  final String? phone;
  final String? photo;
  final double? capital;
  final double? ownershipPercentage;
  final DateTime? joiningDate;
  final PartnerStatus? status;
  final String? description;
  final bool? isActive;

  const UpdatePartnerRequest({
    this.name,
    this.email,
    this.phone,
    this.photo,
    this.capital,
    this.ownershipPercentage,
    this.joiningDate,
    this.status,
    this.description,
    this.isActive,
  });

  UpdatePartnerRequest copyWith({
    String? name,
    String? email,
    String? phone,
    String? photo,
    double? capital,
    double? ownershipPercentage,
    DateTime? joiningDate,
    PartnerStatus? status,
    String? description,
    bool? isActive,
  }) {
    return UpdatePartnerRequest(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photo: photo ?? this.photo,
      capital: capital ?? this.capital,
      ownershipPercentage:
          ownershipPercentage ?? this.ownershipPercentage,
      joiningDate: joiningDate ?? this.joiningDate,
      status: status ?? this.status,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (photo != null) 'photo': photo,
      if (capital != null) 'capital': capital,
      if (ownershipPercentage != null)
        'ownershipPercentage': ownershipPercentage,
      if (joiningDate != null)
        'joiningDate': joiningDate!.toIso8601String(),
      if (status != null) 'status': status!.value,
      if (description != null) 'description': description,
      if (isActive != null) 'isActive': isActive,
    };
  }

  factory UpdatePartnerRequest.fromMap(Map<String, dynamic> map) {
    return UpdatePartnerRequest(
      name: map['name'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      photo: map['photo'] as String?,
      capital: map['capital'] != null
          ? (map['capital'] as num).toDouble()
          : null,
      ownershipPercentage: map['ownershipPercentage'] != null
          ? (map['ownershipPercentage'] as num).toDouble()
          : null,
      joiningDate: map['joiningDate'] != null
          ? DateTime.parse(map['joiningDate'] as String)
          : null,
      status: map['status'] != null
          ? PartnerStatus.fromValue(map['status'] as int)
          : null,
      description: map['description'] as String?,
      isActive: map['isActive'] as bool?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory UpdatePartnerRequest.fromJson(String source) {
    return UpdatePartnerRequest.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  bool get hasFieldsToUpdate =>
      name != null ||
      email != null ||
      phone != null ||
      photo != null ||
      capital != null ||
      ownershipPercentage != null ||
      joiningDate != null ||
      status != null ||
      description != null ||
      isActive != null;

  @override
  List<Object?> get props => [
        name,
        email,
        phone,
        photo,
        capital,
        ownershipPercentage,
        joiningDate,
        status,
        description,
        isActive,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdatePartnerRequest &&
        other.name == name &&
        other.email == email &&
        other.phone == phone &&
        other.photo == photo &&
        other.capital == capital &&
        other.ownershipPercentage == ownershipPercentage &&
        other.joiningDate == joiningDate &&
        other.status == status &&
        other.description == description &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      email,
      phone,
      photo,
      capital,
      ownershipPercentage,
      joiningDate,
      status,
      description,
      isActive,
    );
  }

  @override
  String toString() {
    return 'UpdatePartnerRequest(name: $name, capital: $capital, '
        'status: $status)';
  }
}
