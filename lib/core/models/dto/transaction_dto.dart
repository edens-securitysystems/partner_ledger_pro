import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../../database/enums/database_enums.dart';

class CreateTransactionRequest extends Equatable {
  final String partnerId;
  final TransactionType type;
  final double amount;
  final String? category;
  final String? description;
  final DateTime date;
  final String? time;
  final String? attachmentPath;

  const CreateTransactionRequest({
    required this.partnerId,
    required this.type,
    required this.amount,
    this.category,
    this.description,
    required this.date,
    this.time,
    this.attachmentPath,
  });

  CreateTransactionRequest copyWith({
    String? partnerId,
    TransactionType? type,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    String? time,
    String? attachmentPath,
  }) {
    return CreateTransactionRequest(
      partnerId: partnerId ?? this.partnerId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      attachmentPath: attachmentPath ?? this.attachmentPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'partnerId': partnerId,
      'type': type.value,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'time': time,
      'attachmentPath': attachmentPath,
    };
  }

  factory CreateTransactionRequest.fromMap(Map<String, dynamic> map) {
    return CreateTransactionRequest(
      partnerId: map['partnerId'] as String,
      type: TransactionType.fromValue(map['type'] as int),
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String?,
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      time: map['time'] as String?,
      attachmentPath: map['attachmentPath'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory CreateTransactionRequest.fromJson(String source) {
    return CreateTransactionRequest.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  @override
  List<Object?> get props => [
        partnerId,
        type,
        amount,
        category,
        description,
        date,
        time,
        attachmentPath,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateTransactionRequest &&
        other.partnerId == partnerId &&
        other.type == type &&
        other.amount == amount &&
        other.category == category &&
        other.description == description &&
        other.date == date &&
        other.time == time &&
        other.attachmentPath == attachmentPath;
  }

  @override
  int get hashCode {
    return Object.hash(
      partnerId,
      type,
      amount,
      category,
      description,
      date,
      time,
      attachmentPath,
    );
  }

  @override
  String toString() {
    return 'CreateTransactionRequest(type: $type, amount: $amount, '
        'partnerId: $partnerId)';
  }
}

class UpdateTransactionRequest extends Equatable {
  final String? partnerId;
  final TransactionType? type;
  final double? amount;
  final String? category;
  final String? description;
  final DateTime? date;
  final String? time;
  final String? attachmentPath;

  const UpdateTransactionRequest({
    this.partnerId,
    this.type,
    this.amount,
    this.category,
    this.description,
    this.date,
    this.time,
    this.attachmentPath,
  });

  UpdateTransactionRequest copyWith({
    String? partnerId,
    TransactionType? type,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    String? time,
    String? attachmentPath,
  }) {
    return UpdateTransactionRequest(
      partnerId: partnerId ?? this.partnerId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      attachmentPath: attachmentPath ?? this.attachmentPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (partnerId != null) 'partnerId': partnerId,
      if (type != null) 'type': type!.value,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (date != null) 'date': date!.toIso8601String(),
      if (time != null) 'time': time,
      if (attachmentPath != null) 'attachmentPath': attachmentPath,
    };
  }

  factory UpdateTransactionRequest.fromMap(Map<String, dynamic> map) {
    return UpdateTransactionRequest(
      partnerId: map['partnerId'] as String?,
      type: map['type'] != null
          ? TransactionType.fromValue(map['type'] as int)
          : null,
      amount: map['amount'] != null
          ? (map['amount'] as num).toDouble()
          : null,
      category: map['category'] as String?,
      description: map['description'] as String?,
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : null,
      time: map['time'] as String?,
      attachmentPath: map['attachmentPath'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory UpdateTransactionRequest.fromJson(String source) {
    return UpdateTransactionRequest.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  bool get hasFieldsToUpdate =>
      partnerId != null ||
      type != null ||
      amount != null ||
      category != null ||
      description != null ||
      date != null ||
      time != null ||
      attachmentPath != null;

  @override
  List<Object?> get props => [
        partnerId,
        type,
        amount,
        category,
        description,
        date,
        time,
        attachmentPath,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdateTransactionRequest &&
        other.partnerId == partnerId &&
        other.type == type &&
        other.amount == amount &&
        other.category == category &&
        other.description == description &&
        other.date == date &&
        other.time == time &&
        other.attachmentPath == attachmentPath;
  }

  @override
  int get hashCode {
    return Object.hash(
      partnerId,
      type,
      amount,
      category,
      description,
      date,
      time,
      attachmentPath,
    );
  }

  @override
  String toString() {
    return 'UpdateTransactionRequest(partnerId: $partnerId, '
        'type: $type, amount: $amount)';
  }
}

class TransactionFilter extends Equatable {
  final String? partnerId;
  final TransactionType? type;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final String? category;
  final int page;
  final int limit;

  const TransactionFilter({
    this.partnerId,
    this.type,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.category,
    this.page = 1,
    this.limit = 20,
  });

  TransactionFilter copyWith({
    String? partnerId,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    String? category,
    int? page,
    int? limit,
  }) {
    return TransactionFilter(
      partnerId: partnerId ?? this.partnerId,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      category: category ?? this.category,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (partnerId != null) 'partnerId': partnerId,
      if (type != null) 'type': type!.value,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      if (minAmount != null) 'minAmount': minAmount,
      if (maxAmount != null) 'maxAmount': maxAmount,
      if (category != null) 'category': category,
      'page': page,
      'limit': limit,
    };
  }

  factory TransactionFilter.fromMap(Map<String, dynamic> map) {
    return TransactionFilter(
      partnerId: map['partnerId'] as String?,
      type: map['type'] != null
          ? TransactionType.fromValue(map['type'] as int)
          : null,
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'] as String)
          : null,
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : null,
      minAmount: map['minAmount'] != null
          ? (map['minAmount'] as num).toDouble()
          : null,
      maxAmount: map['maxAmount'] != null
          ? (map['maxAmount'] as num).toDouble()
          : null,
      category: map['category'] as String?,
      page: map['page'] as int? ?? 1,
      limit: map['limit'] as int? ?? 20,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory TransactionFilter.fromJson(String source) {
    return TransactionFilter.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  bool get hasFilters =>
      partnerId != null ||
      type != null ||
      startDate != null ||
      endDate != null ||
      minAmount != null ||
      maxAmount != null ||
      category != null;

  TransactionFilter reset() => const TransactionFilter();

  @override
  List<Object?> get props => [
        partnerId,
        type,
        startDate,
        endDate,
        minAmount,
        maxAmount,
        category,
        page,
        limit,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionFilter &&
        other.partnerId == partnerId &&
        other.type == type &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.minAmount == minAmount &&
        other.maxAmount == maxAmount &&
        other.category == category &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    return Object.hash(
      partnerId,
      type,
      startDate,
      endDate,
      minAmount,
      maxAmount,
      category,
      page,
      limit,
    );
  }

  @override
  String toString() {
    return 'TransactionFilter(partnerId: $partnerId, type: $type, '
        'startDate: $startDate, endDate: $endDate, page: $page)';
  }
}
