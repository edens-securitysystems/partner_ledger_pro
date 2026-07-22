import 'package:equatable/equatable.dart';

import '../../database/enums/database_enums.dart';

class PartnerInvite extends Equatable {
  final String id;
  final String businessId;
  final String businessName;
  final String createdByUserId;
  final String createdByEmail;
  final String token;
  final InviteStatus status;
  final String? acceptedByUserId;
  final String? acceptedByEmail;
  final String? acceptedByPartnerId;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PartnerInvite({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.createdByUserId,
    required this.createdByEmail,
    required this.token,
    this.status = InviteStatus.active,
    this.acceptedByUserId,
    this.acceptedByEmail,
    this.acceptedByPartnerId,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == InviteStatus.active;
  bool get isExpired => DateTime.now().isAfter(expiresAt) || status == InviteStatus.expired;
  bool get isAccepted => status == InviteStatus.accepted;
  bool get isRevoked => status == InviteStatus.revoked;
  bool get canBeAccepted => isActive && !isExpired;

  bool get isDeepLink => token.isNotEmpty;

  PartnerInvite copyWith({
    String? id,
    String? businessId,
    String? businessName,
    String? createdByUserId,
    String? createdByEmail,
    String? token,
    InviteStatus? status,
    String? acceptedByUserId,
    String? acceptedByEmail,
    String? acceptedByPartnerId,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PartnerInvite(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      token: token ?? this.token,
      status: status ?? this.status,
      acceptedByUserId: acceptedByUserId ?? this.acceptedByUserId,
      acceptedByEmail: acceptedByEmail ?? this.acceptedByEmail,
      acceptedByPartnerId: acceptedByPartnerId ?? this.acceptedByPartnerId,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'businessName': businessName,
      'createdByUserId': createdByUserId,
      'createdByEmail': createdByEmail,
      'token': token,
      'status': status.value,
      'acceptedByUserId': acceptedByUserId,
      'acceptedByEmail': acceptedByEmail,
      'acceptedByPartnerId': acceptedByPartnerId,
      'expiresAt': expiresAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PartnerInvite.fromMap(Map<String, dynamic> map) {
    return PartnerInvite(
      id: '${map['id'] ?? ''}',
      businessId: '${map['businessId'] ?? ''}',
      businessName: '${map['businessName'] ?? ''}',
      createdByUserId: '${map['createdByUserId'] ?? ''}',
      createdByEmail: '${map['createdByEmail'] ?? ''}',
      token: '${map['token'] ?? ''}',
      status: InviteStatus.fromValue(map['status'] is int ? map['status'] as int : 0),
      acceptedByUserId: map['acceptedByUserId']?.toString(),
      acceptedByEmail: map['acceptedByEmail']?.toString(),
      acceptedByPartnerId: map['acceptedByPartnerId']?.toString(),
      expiresAt: DateTime.parse(map['expiresAt'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJsonMap() => toMap();

  factory PartnerInvite.fromJsonMap(Map<String, dynamic> json) =>
      PartnerInvite.fromMap(json);

  String toJson() => throw UnimplementedError();

  factory PartnerInvite.fromJson(String source) =>
      throw UnimplementedError();

  @override
  List<Object?> get props => [
        id,
        businessId,
        businessName,
        createdByUserId,
        createdByEmail,
        token,
        status,
        acceptedByUserId,
        acceptedByEmail,
        acceptedByPartnerId,
        expiresAt,
        createdAt,
        updatedAt,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PartnerInvite && other.id == id && other.token == token;
  }

  @override
  int get hashCode => Object.hash(id, token, businessId, status);

  @override
  String toString() {
    return 'PartnerInvite(id: $id, businessId: $businessId, '
        'status: $status, expiresAt: $expiresAt)';
  }
}
