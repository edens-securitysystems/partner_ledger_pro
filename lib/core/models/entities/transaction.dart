import 'package:equatable/equatable.dart';

import '../../database/enums/database_enums.dart';

class Transaction extends Equatable {
  final String id;
  final String businessId;
  final String partnerId;
  final TransactionType type;
  final double amount;
  final String? category;
  final String? description;
  final DateTime date;
  final String? time;
  final String? attachmentPath;
  final String createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final SyncStatus syncStatus;

  const Transaction({
    required this.id,
    required this.businessId,
    required this.partnerId,
    required this.type,
    required this.amount,
    this.category,
    this.description,
    required this.date,
    this.time,
    this.attachmentPath,
    required this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.syncStatus = SyncStatus.synced,
  });

  bool get isIncome =>
      type == TransactionType.income ||
      type == TransactionType.investment ||
      type == TransactionType.loanRepayment ||
      type == TransactionType.profitDistribution;

  bool get isExpense =>
      type == TransactionType.expense ||
      type == TransactionType.withdrawal ||
      type == TransactionType.loan ||
      type == TransactionType.lossAllocation;

  bool get isCredit => isIncome;
  bool get isDebit => isExpense;

  String get typeDisplay {
    switch (type) {
      case TransactionType.investment:
        return 'Investment';
      case TransactionType.withdrawal:
        return 'Withdrawal';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.income:
        return 'Income';
      case TransactionType.transfer:
        return 'Transfer';
      case TransactionType.loan:
        return 'Loan';
      case TransactionType.loanRepayment:
        return 'Loan Repayment';
      case TransactionType.adjustment:
        return 'Adjustment';
      case TransactionType.profitDistribution:
        return 'Profit Distribution';
      case TransactionType.lossAllocation:
        return 'Loss Allocation';
    }
  }

  double get signedAmount {
    return isIncome ? amount : -amount;
  }

  bool get hasAttachment =>
      attachmentPath != null && attachmentPath!.isNotEmpty;

  Transaction copyWith({
    String? id,
    String? businessId,
    String? partnerId,
    TransactionType? type,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    String? time,
    String? attachmentPath,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    SyncStatus? syncStatus,
  }) {
    return Transaction(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      partnerId: partnerId ?? this.partnerId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'partnerId': partnerId,
      'type': type.value,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'time': time,
      'attachmentPath': attachmentPath,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
      'syncStatus': syncStatus.value,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      businessId: map['businessId'] as String,
      partnerId: map['partnerId'] as String,
      type: TransactionType.fromValue(map['type'] as int),
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String?,
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      time: map['time'] as String?,
      attachmentPath: map['attachmentPath'] as String?,
      createdBy: map['createdBy'] as String,
      updatedBy: map['updatedBy'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isSynced: map['isSynced'] as bool? ?? false,
      syncStatus:
          SyncStatus.fromValue(map['syncStatus'] as int? ?? 0),
    );
  }

  String toJson() => throw UnimplementedError();

  factory Transaction.fromJson(String source) =>
      throw UnimplementedError();

  Map<String, dynamic> toJsonMap() => toMap();

  factory Transaction.fromJsonMap(Map<String, dynamic> json) =>
      Transaction.fromMap(json);

  @override
  List<Object?> get props => [
        id,
        businessId,
        partnerId,
        type,
        amount,
        category,
        description,
        date,
        time,
        attachmentPath,
        createdBy,
        updatedBy,
        createdAt,
        updatedAt,
        isSynced,
        syncStatus,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction &&
        other.id == id &&
        other.businessId == businessId &&
        other.partnerId == partnerId &&
        other.type == type &&
        other.amount == amount &&
        other.category == category &&
        other.description == description &&
        other.date == date &&
        other.time == time &&
        other.attachmentPath == attachmentPath &&
        other.createdBy == createdBy &&
        other.updatedBy == updatedBy &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isSynced == isSynced &&
        other.syncStatus == syncStatus;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      businessId,
      partnerId,
      type,
      amount,
      category,
      description,
      date,
      time,
      attachmentPath,
      createdBy,
      updatedBy,
      createdAt,
      updatedAt,
      isSynced,
      syncStatus,
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $id, type: $typeDisplay, amount: $amount, '
        'partnerId: $partnerId, date: $date)';
  }
}
