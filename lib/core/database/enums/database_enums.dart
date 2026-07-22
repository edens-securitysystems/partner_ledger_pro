enum UserRole {
  owner(0),
  admin(1),
  manager(2),
  accountant(3),
  viewer(4),
  partner(5);

  const UserRole(this.value);
  final int value;

  static UserRole fromValue(int value) {
    return UserRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserRole.viewer,
    );
  }
}

enum PartnerStatus {
  active(0),
  inactive(1),
  pending(2),
  suspended(3),
  withdrawn(4);

  const PartnerStatus(this.value);
  final int value;

  static PartnerStatus fromValue(int value) {
    return PartnerStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PartnerStatus.active,
    );
  }
}

enum TransactionType {
  investment(0),
  withdrawal(1),
  expense(2),
  income(3),
  transfer(4),
  loan(5),
  loanRepayment(6),
  adjustment(7),
  profitDistribution(8),
  lossAllocation(9);

  const TransactionType(this.value);
  final int value;

  static TransactionType fromValue(int value) {
    return TransactionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TransactionType.adjustment,
    );
  }
}

enum NotificationType {
  system(0),
  transaction(1),
  partner(2),
  ledger(3),
  reminder(4),
  alert(5);

  const NotificationType(this.value);
  final int value;

  static NotificationType fromValue(int value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.system,
    );
  }
}

enum SyncStatus {
  synced(0),
  pendingCreate(1),
  pendingUpdate(2),
  pendingDelete(3),
  conflict(4);

  const SyncStatus(this.value);
  final int value;

  static SyncStatus fromValue(int value) {
    return SyncStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SyncStatus.synced,
    );
  }
}

enum UpdateRequestStatus {
  pending(0),
  approved(1),
  rejected(2),
  expired(3);

  const UpdateRequestStatus(this.value);
  final int value;

  static UpdateRequestStatus fromValue(int value) {
    return UpdateRequestStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UpdateRequestStatus.pending,
    );
  }

  String get display {
    switch (this) {
      case UpdateRequestStatus.pending:
        return 'Pending';
      case UpdateRequestStatus.approved:
        return 'Approved';
      case UpdateRequestStatus.rejected:
        return 'Rejected';
      case UpdateRequestStatus.expired:
        return 'Expired';
    }
  }
}

enum ApprovalDecision {
  pending(0),
  approved(1),
  rejected(2);

  const ApprovalDecision(this.value);
  final int value;

  static ApprovalDecision fromValue(int value) {
    return ApprovalDecision.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ApprovalDecision.pending,
    );
  }

  String get display {
    switch (this) {
      case ApprovalDecision.pending:
        return 'Pending';
      case ApprovalDecision.approved:
        return 'Approved';
      case ApprovalDecision.rejected:
        return 'Rejected';
    }
  }
}

enum InviteStatus {
  active(0),
  accepted(1),
  expired(2),
  revoked(3);

  const InviteStatus(this.value);
  final int value;

  static InviteStatus fromValue(int value) {
    return InviteStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InviteStatus.active,
    );
  }

  String get display {
    switch (this) {
      case InviteStatus.active:
        return 'Active';
      case InviteStatus.accepted:
        return 'Accepted';
      case InviteStatus.expired:
        return 'Expired';
      case InviteStatus.revoked:
        return 'Revoked';
    }
  }
}
