import 'package:equatable/equatable.dart';

import '../../database/enums/database_enums.dart';

class PartnerApproval extends Equatable {
  final String id;
  final String updateRequestId;
  final String partnerId;
  final String partnerName;
  final String partnerEmail;
  final ApprovalDecision decision;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? decidedAt;

  const PartnerApproval({
    required this.id,
    required this.updateRequestId,
    required this.partnerId,
    required this.partnerName,
    required this.partnerEmail,
    this.decision = ApprovalDecision.pending,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.decidedAt,
  });

  bool get isPending => decision == ApprovalDecision.pending;
  bool get isApproved => decision == ApprovalDecision.approved;
  bool get isRejected => decision == ApprovalDecision.rejected;

  PartnerApproval copyWith({
    String? id,
    String? updateRequestId,
    String? partnerId,
    String? partnerName,
    String? partnerEmail,
    ApprovalDecision? decision,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? decidedAt,
  }) {
    return PartnerApproval(
      id: id ?? this.id,
      updateRequestId: updateRequestId ?? this.updateRequestId,
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      partnerEmail: partnerEmail ?? this.partnerEmail,
      decision: decision ?? this.decision,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      decidedAt: decidedAt ?? this.decidedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'updateRequestId': updateRequestId,
      'partnerId': partnerId,
      'partnerName': partnerName,
      'partnerEmail': partnerEmail,
      'decision': decision.value,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'decidedAt': decidedAt?.toIso8601String(),
    };
  }

  factory PartnerApproval.fromMap(Map<String, dynamic> map) {
    return PartnerApproval(
      id: '${map['id'] ?? ''}',
      updateRequestId: '${map['updateRequestId'] ?? ''}',
      partnerId: '${map['partnerId'] ?? ''}',
      partnerName: '${map['partnerName'] ?? ''}',
      partnerEmail: '${map['partnerEmail'] ?? ''}',
      decision: ApprovalDecision.fromValue(
        map['decision'] is int ? map['decision'] as int : int.tryParse('${map['decision']}') ?? 0,
      ),
      comment: map['comment']?.toString(),
      createdAt: DateTime.tryParse('${map['createdAt']}') ?? DateTime.now(),
      updatedAt: DateTime.tryParse('${map['updatedAt']}') ?? DateTime.now(),
      decidedAt: map['decidedAt'] != null
          ? DateTime.tryParse('${map['decidedAt']}')
          : null,
    );
  }

  Map<String, dynamic> toJsonMap() => toMap();

  @override
  List<Object?> get props => [
        id,
        updateRequestId,
        partnerId,
        partnerName,
        partnerEmail,
        decision,
        comment,
        createdAt,
        updatedAt,
        decidedAt,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PartnerApproval && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PartnerApproval(id: $id, partnerId: $partnerId, '
        'decision: ${decision.display})';
  }
}
