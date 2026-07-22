import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../../database/enums/database_enums.dart';

class PartnerUpdateRequest extends Equatable {
  final String id;
  final String businessId;
  final String partnerId;
  final String requestedByUserId;
  final String requestedByEmail;
  final String requestedByName;
  final String proposedChanges;
  final String? currentValues;
  final String? reason;
  final UpdateRequestStatus status;
  final int totalApprovers;
  final int approvedCount;
  final int rejectedCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  const PartnerUpdateRequest({
    required this.id,
    required this.businessId,
    required this.partnerId,
    required this.requestedByUserId,
    required this.requestedByEmail,
    required this.requestedByName,
    required this.proposedChanges,
    this.currentValues,
    this.reason,
    this.status = UpdateRequestStatus.pending,
    this.totalApprovers = 0,
    this.approvedCount = 0,
    this.rejectedCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
  });

  bool get isPending => status == UpdateRequestStatus.pending;
  bool get isApproved => status == UpdateRequestStatus.approved;
  bool get isRejected => status == UpdateRequestStatus.rejected;
  bool get isExpired => status == UpdateRequestStatus.expired;

  bool get isFullyApproved =>
      isPending && totalApprovers > 0 && approvedCount >= totalApprovers;

  bool get hasRejection => rejectedCount > 0;

  double get approvalProgress =>
      totalApprovers > 0 ? approvedCount / totalApprovers : 0.0;

  Map<String, dynamic> get proposedChangesMap {
    try {
      return Map<String, dynamic>.from(jsonDecode(proposedChanges) as Map);
    } catch (_) {
      return {};
    }
  }

  Map<String, dynamic>? get currentValuesMap {
    if (currentValues == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(currentValues!) as Map);
    } catch (_) {
      return null;
    }
  }

  List<String> get changedFields => proposedChangesMap.keys.toList();

  PartnerUpdateRequest copyWith({
    String? id,
    String? businessId,
    String? partnerId,
    String? requestedByUserId,
    String? requestedByEmail,
    String? requestedByName,
    String? proposedChanges,
    String? currentValues,
    String? reason,
    UpdateRequestStatus? status,
    int? totalApprovers,
    int? approvedCount,
    int? rejectedCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) {
    return PartnerUpdateRequest(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      partnerId: partnerId ?? this.partnerId,
      requestedByUserId: requestedByUserId ?? this.requestedByUserId,
      requestedByEmail: requestedByEmail ?? this.requestedByEmail,
      requestedByName: requestedByName ?? this.requestedByName,
      proposedChanges: proposedChanges ?? this.proposedChanges,
      currentValues: currentValues ?? this.currentValues,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      totalApprovers: totalApprovers ?? this.totalApprovers,
      approvedCount: approvedCount ?? this.approvedCount,
      rejectedCount: rejectedCount ?? this.rejectedCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'partnerId': partnerId,
      'requestedByUserId': requestedByUserId,
      'requestedByEmail': requestedByEmail,
      'requestedByName': requestedByName,
      'proposedChanges': proposedChanges,
      'currentValues': currentValues,
      'reason': reason,
      'status': status.value,
      'totalApprovers': totalApprovers,
      'approvedCount': approvedCount,
      'rejectedCount': rejectedCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  factory PartnerUpdateRequest.fromMap(Map<String, dynamic> map) {
    return PartnerUpdateRequest(
      id: '${map['id'] ?? ''}',
      businessId: '${map['businessId'] ?? ''}',
      partnerId: '${map['partnerId'] ?? ''}',
      requestedByUserId: '${map['requestedByUserId'] ?? ''}',
      requestedByEmail: '${map['requestedByEmail'] ?? ''}',
      requestedByName: '${map['requestedByName'] ?? ''}',
      proposedChanges: '${map['proposedChanges'] ?? '{}'}',
      currentValues: map['currentValues']?.toString(),
      reason: map['reason']?.toString(),
      status: UpdateRequestStatus.fromValue(
        map['status'] is int ? map['status'] as int : int.tryParse('${map['status']}') ?? 0,
      ),
      totalApprovers: map['totalApprovers'] is int
          ? map['totalApprovers'] as int
          : int.tryParse('${map['totalApprovers']}') ?? 0,
      approvedCount: map['approvedCount'] is int
          ? map['approvedCount'] as int
          : int.tryParse('${map['approvedCount']}') ?? 0,
      rejectedCount: map['rejectedCount'] is int
          ? map['rejectedCount'] as int
          : int.tryParse('${map['rejectedCount']}') ?? 0,
      createdAt: DateTime.tryParse('${map['createdAt']}') ?? DateTime.now(),
      updatedAt: DateTime.tryParse('${map['updatedAt']}') ?? DateTime.now(),
      resolvedAt: map['resolvedAt'] != null
          ? DateTime.tryParse('${map['resolvedAt']}')
          : null,
    );
  }

  Map<String, dynamic> toJsonMap() => toMap();

  @override
  List<Object?> get props => [
        id,
        businessId,
        partnerId,
        requestedByUserId,
        requestedByEmail,
        requestedByName,
        proposedChanges,
        currentValues,
        reason,
        status,
        totalApprovers,
        approvedCount,
        rejectedCount,
        createdAt,
        updatedAt,
        resolvedAt,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PartnerUpdateRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PartnerUpdateRequest(id: $id, partnerId: $partnerId, '
        'status: ${status.display}, approvals: $approvedCount/$totalApprovers)';
  }
}
