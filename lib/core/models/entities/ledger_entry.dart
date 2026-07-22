import 'package:equatable/equatable.dart';

import '../../database/enums/database_enums.dart';

class LedgerEntry extends Equatable {
  final String id;
  final String partnerId;
  final String businessId;
  final String transactionId;
  final TransactionType type;
  final double amount;
  final double balance;
  final String? description;
  final DateTime date;
  final DateTime createdAt;

  const LedgerEntry({
    required this.id,
    required this.partnerId,
    required this.businessId,
    required this.transactionId,
    required this.type,
    required this.amount,
    required this.balance,
    this.description,
    required this.date,
    required this.createdAt,
  });

  bool get isCredit =>
      type == TransactionType.income ||
      type == TransactionType.investment ||
      type == TransactionType.loanRepayment ||
      type == TransactionType.profitDistribution;

  bool get isDebit =>
      type == TransactionType.expense ||
      type == TransactionType.withdrawal ||
      type == TransactionType.loan ||
      type == TransactionType.lossAllocation;

  bool get isBalancePositive => balance > 0;
  bool get isBalanceNegative => balance < 0;
  bool get isBalanceZero => balance == 0;

  double get absoluteBalance => balance.abs();

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

  String get balanceDisplay {
    if (isBalanceZero) return '0.00';
    return balance.toStringAsFixed(2);
  }

  LedgerEntry copyWith({
    String? id,
    String? partnerId,
    String? businessId,
    String? transactionId,
    TransactionType? type,
    double? amount,
    double? balance,
    String? description,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      partnerId: partnerId ?? this.partnerId,
      businessId: businessId ?? this.businessId,
      transactionId: transactionId ?? this.transactionId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      balance: balance ?? this.balance,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partnerId': partnerId,
      'businessId': businessId,
      'transactionId': transactionId,
      'type': type.value,
      'amount': amount,
      'balance': balance,
      'description': description,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LedgerEntry.fromMap(Map<String, dynamic> map) {
    return LedgerEntry(
      id: map['id'] as String,
      partnerId: map['partnerId'] as String,
      businessId: map['businessId'] as String,
      transactionId: map['transactionId'] as String,
      type: TransactionType.fromValue(map['type'] as int),
      amount: (map['amount'] as num).toDouble(),
      balance: (map['balance'] as num).toDouble(),
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  String toJson() => throw UnimplementedError();

  factory LedgerEntry.fromJson(String source) =>
      throw UnimplementedError();

  Map<String, dynamic> toJsonMap() => toMap();

  factory LedgerEntry.fromJsonMap(Map<String, dynamic> json) =>
      LedgerEntry.fromMap(json);

  LedgerEntry withRunningBalance(double previousBalance) {
    final newBalance = isCredit
        ? previousBalance + amount
        : previousBalance - amount;
    return copyWith(balance: newBalance);
  }

  @override
  List<Object?> get props => [
        id,
        partnerId,
        businessId,
        transactionId,
        type,
        amount,
        balance,
        description,
        date,
        createdAt,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LedgerEntry &&
        other.id == id &&
        other.partnerId == partnerId &&
        other.businessId == businessId &&
        other.transactionId == transactionId &&
        other.type == type &&
        other.amount == amount &&
        other.balance == balance &&
        other.description == description &&
        other.date == date &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      partnerId,
      businessId,
      transactionId,
      type,
      amount,
      balance,
      description,
      date,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'LedgerEntry(id: $id, type: $typeDisplay, amount: $amount, '
        'balance: $balance, partnerId: $partnerId, date: $date)';
  }
}
