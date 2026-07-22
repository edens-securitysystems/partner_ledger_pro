import 'package:equatable/equatable.dart';

import '../../database/enums/database_enums.dart';

class Partner extends Equatable {
  final String id;
  final String businessId;
  final String name;
  final String? email;
  final String? phone;
  final String? photo;
  final double capital;
  final double ownershipPercentage;
  final DateTime joiningDate;
  final PartnerStatus status;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? userId;

  const Partner({
    required this.id,
    required this.businessId,
    required this.name,
    this.email,
    this.phone,
    this.photo,
    this.capital = 0.0,
    this.ownershipPercentage = 0.0,
    required this.joiningDate,
    this.status = PartnerStatus.active,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.userId,
  });

  bool get isStatusActive => status == PartnerStatus.active;
  bool get isStatusInactive => status == PartnerStatus.inactive;
  bool get isStatusPending => status == PartnerStatus.pending;
  bool get isStatusSuspended => status == PartnerStatus.suspended;
  bool get isStatusWithdrawn => status == PartnerStatus.withdrawn;

  bool get canTransact => isStatusActive && isActive;
  bool get canReceiveProfit => isStatusActive && isActive;

  String get statusDisplay {
    switch (status) {
      case PartnerStatus.active:
        return 'Active';
      case PartnerStatus.inactive:
        return 'Inactive';
      case PartnerStatus.pending:
        return 'Pending';
      case PartnerStatus.suspended:
        return 'Suspended';
      case PartnerStatus.withdrawn:
        return 'Withdrawn';
    }
  }

  double totalInvestment(double totalBusinessProfit) {
    if (ownershipPercentage <= 0) return 0.0;
    return totalBusinessProfit * (ownershipPercentage / 100);
  }

  Partner copyWith({
    String? id,
    String? businessId,
    String? name,
    String? email,
    String? phone,
    String? photo,
    double? capital,
    double? ownershipPercentage,
    DateTime? joiningDate,
    PartnerStatus? status,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? userId,
  }) {
    return Partner(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'name': name,
      'email': email,
      'phone': phone,
      'photo': photo,
      'capital': capital,
      'ownershipPercentage': ownershipPercentage,
      'joiningDate': joiningDate.toIso8601String(),
      'status': status.value,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'userId': userId,
    };
  }

  factory Partner.fromMap(Map<String, dynamic> map) {
    return Partner(
      id: map['id'] as String,
      businessId: map['businessId'] as String,
      name: map['name'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      photo: map['photo'] as String?,
      capital: (map['capital'] as num?)?.toDouble() ?? 0.0,
      ownershipPercentage:
          (map['ownershipPercentage'] as num?)?.toDouble() ?? 0.0,
      joiningDate: DateTime.parse(map['joiningDate'] as String),
      status: PartnerStatus.fromValue(map['status'] as int),
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isActive: map['isActive'] as bool? ?? true,
      userId: map['userId'] as String?,
    );
  }

  String toJson() => throw UnimplementedError();

  factory Partner.fromJson(String source) =>
      throw UnimplementedError();

  Map<String, dynamic> toJsonMap() => toMap();

  factory Partner.fromJsonMap(Map<String, dynamic> json) =>
      Partner.fromMap(json);

  @override
  List<Object?> get props => [
        id,
        businessId,
        name,
        email,
        phone,
        photo,
        capital,
        ownershipPercentage,
        joiningDate,
        status,
        description,
        createdAt,
        updatedAt,
        isActive,
        userId,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Partner &&
        other.id == id &&
        other.businessId == businessId &&
        other.name == name &&
        other.email == email &&
        other.phone == phone &&
        other.photo == photo &&
        other.capital == capital &&
        other.ownershipPercentage == ownershipPercentage &&
        other.joiningDate == joiningDate &&
        other.status == status &&
        other.description == description &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isActive == isActive &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      businessId,
      name,
      email,
      phone,
      photo,
      capital,
      ownershipPercentage,
      joiningDate,
      status,
      description,
      createdAt,
      updatedAt,
      isActive,
      userId,
    );
  }

  @override
  String toString() {
    return 'Partner(id: $id, name: $name, businessId: $businessId, '
        'capital: $capital, ownershipPercentage: $ownershipPercentage%, '
        'status: $status)';
  }
}
