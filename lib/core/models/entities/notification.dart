import 'package:equatable/equatable.dart';

import '../../database/enums/database_enums.dart';

class AppNotification extends Equatable {
  final String id;
  final String userId;
  final String? businessId;
  final NotificationType type;
  final String title;
  final String message;
  final String? referenceId;
  final String? referenceType;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    required this.userId,
    this.businessId,
    required this.type,
    required this.title,
    required this.message,
    this.referenceId,
    this.referenceType,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  bool get isUnread => !isRead;

  String get typeDisplay {
    switch (type) {
      case NotificationType.system:
        return 'System';
      case NotificationType.transaction:
        return 'Transaction';
      case NotificationType.partner:
        return 'Partner';
      case NotificationType.ledger:
        return 'Ledger';
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.alert:
        return 'Alert';
    }
  }

  bool get hasReference =>
      referenceId != null && referenceId!.isNotEmpty;

  AppNotification copyWith({
    String? id,
    String? userId,
    String? businessId,
    NotificationType? type,
    String? title,
    String? message,
    String? referenceId,
    String? referenceType,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessId: businessId ?? this.businessId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'businessId': businessId,
      'type': type.value,
      'title': title,
      'message': message,
      'referenceId': referenceId,
      'referenceType': referenceType,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      userId: map['userId'] as String,
      businessId: map['businessId'] as String?,
      type: NotificationType.fromValue(map['type'] as int),
      title: map['title'] as String,
      message: map['message'] as String,
      referenceId: map['referenceId'] as String?,
      referenceType: map['referenceType'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      readAt: map['readAt'] != null
          ? DateTime.parse(map['readAt'] as String)
          : null,
    );
  }

  String toJson() => throw UnimplementedError();

  factory AppNotification.fromJson(String source) =>
      throw UnimplementedError();

  Map<String, dynamic> toJsonMap() => toMap();

  factory AppNotification.fromJsonMap(
    Map<String, dynamic> json,
  ) {
    return AppNotification.fromMap(json);
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        businessId,
        type,
        title,
        message,
        referenceId,
        referenceType,
        isRead,
        createdAt,
        readAt,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNotification &&
        other.id == id &&
        other.userId == userId &&
        other.businessId == businessId &&
        other.type == type &&
        other.title == title &&
        other.message == message &&
        other.referenceId == referenceId &&
        other.referenceType == referenceType &&
        other.isRead == isRead &&
        other.createdAt == createdAt &&
        other.readAt == readAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      businessId,
      type,
      title,
      message,
      referenceId,
      referenceType,
      isRead,
      createdAt,
      readAt,
    );
  }

  @override
  String toString() {
    return 'AppNotification(id: $id, type: $typeDisplay, '
        'title: $title, isRead: $isRead)';
  }
}
