import 'dart:convert';

import 'package:equatable/equatable.dart';

class ApiResponse<T> extends Equatable {
  final bool success;
  final String message;
  final T? data;
  final String? error;
  final String? errorCode;
  final DateTime timestamp;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
    this.errorCode,
    required this.timestamp,
  });

  bool get hasData => data != null;
  bool get hasError => error != null;

  factory ApiResponse.success({
    required T data,
    String message = 'Success',
  }) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
      timestamp: DateTime.now(),
    );
  }

  factory ApiResponse.error({
    required String message,
    String? error,
    String? errorCode,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      error: error,
      errorCode: errorCode,
      timestamp: DateTime.now(),
    );
  }

  ApiResponse<T> copyWith({
    bool? success,
    String? message,
    T? data,
    String? error,
    String? errorCode,
    DateTime? timestamp,
  }) {
    return ApiResponse<T>(
      success: success ?? this.success,
      message: message ?? this.message,
      data: data ?? this.data,
      error: error ?? this.error,
      errorCode: errorCode ?? this.errorCode,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'error': error,
      'errorCode': errorCode,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ApiResponse.fromMap(
    Map<String, dynamic> map,
    T Function(dynamic)? fromData,
  ) {
    return ApiResponse<T>(
      success: map['success'] as bool? ?? false,
      message: map['message'] as String? ?? '',
      data: map['data'] != null && fromData != null
          ? fromData(map['data'])
          : map['data'] as T?,
      error: map['error'] as String?,
      errorCode: map['errorCode'] as String?,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ApiResponse.fromJson(
    String source,
    T Function(dynamic)? fromData,
  ) {
    return ApiResponse.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
      fromData,
    );
  }

  @override
  List<Object?> get props =>
      [success, message, data, error, errorCode, timestamp];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApiResponse &&
        other.success == success &&
        other.message == message &&
        other.error == error &&
        other.errorCode == errorCode;
  }

  @override
  int get hashCode => Object.hash(success, message, error, errorCode);

  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, '
        'hasData: $hasData, hasError: $hasError)';
  }
}

class PaginatedData<T> extends Equatable {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PaginatedData({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  int get itemCount => items.length;
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  bool get isFirstPage => currentPage == 1;
  bool get isLastPage => currentPage == totalPages;

  PaginatedData<T> copyWith({
    List<T>? items,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    int? itemsPerPage,
    bool? hasNextPage,
    bool? hasPreviousPage,
  }) {
    return PaginatedData<T>(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage:
          hasPreviousPage ?? this.hasPreviousPage,
    );
  }

  factory PaginatedData.empty() {
    return PaginatedData<T>(
      items: const [],
      currentPage: 1,
      totalPages: 1,
      totalItems: 0,
      itemsPerPage: 20,
      hasNextPage: false,
      hasPreviousPage: false,
    );
  }

  factory PaginatedData.fromMap(
    Map<String, dynamic> map,
    List<T> Function(dynamic)? fromItems,
  ) {
    return PaginatedData<T>(
      items: map['items'] != null && fromItems != null
          ? fromItems(map['items'])
          : (map['items'] as List<T>?) ?? [],
      currentPage: map['currentPage'] as int? ?? 1,
      totalPages: map['totalPages'] as int? ?? 1,
      totalItems: map['totalItems'] as int? ?? 0,
      itemsPerPage: map['itemsPerPage'] as int? ?? 20,
      hasNextPage: map['hasNextPage'] as bool? ?? false,
      hasPreviousPage:
          map['hasPreviousPage'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'items': items,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'totalItems': totalItems,
      'itemsPerPage': itemsPerPage,
      'hasNextPage': hasNextPage,
      'hasPreviousPage': hasPreviousPage,
    };
  }

  String toJson() => jsonEncode(toMap());

  @override
  List<Object?> get props => [
        items,
        currentPage,
        totalPages,
        totalItems,
        itemsPerPage,
        hasNextPage,
        hasPreviousPage,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaginatedData &&
        other.currentPage == currentPage &&
        other.totalPages == totalPages &&
        other.totalItems == totalItems &&
        other.itemsPerPage == itemsPerPage;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentPage,
      totalPages,
      totalItems,
      itemsPerPage,
    );
  }

  @override
  String toString() {
    return 'PaginatedData(page: $currentPage/$totalPages, '
        'items: $itemCount/$totalItems)';
  }
}

class PaginatedResponse<T> extends Equatable {
  final ApiResponse<PaginatedData<T>> response;

  const PaginatedResponse({
    required this.response,
  });

  bool get success => response.success;
  String get message => response.message;
  PaginatedData<T>? get data => response.data;
  String? get error => response.error;

  List<T> get items => data?.items ?? [];
  int get currentPage => data?.currentPage ?? 1;
  int get totalPages => data?.totalPages ?? 1;
  int get totalItems => data?.totalItems ?? 0;
  bool get hasNextPage => data?.hasNextPage ?? false;
  bool get hasPreviousPage => data?.hasPreviousPage ?? false;

  factory PaginatedResponse.success({
    required PaginatedData<T> data,
    String message = 'Success',
  }) {
    return PaginatedResponse<T>(
      response: ApiResponse.success(data: data, message: message),
    );
  }

  factory PaginatedResponse.error({
    required String message,
    String? error,
  }) {
    return PaginatedResponse<T>(
      response: ApiResponse.error(message: message, error: error),
    );
  }

  @override
  List<Object?> get props => [response];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaginatedResponse && other.response == response;
  }

  @override
  int get hashCode => response.hashCode;

  @override
  String toString() {
    return 'PaginatedResponse(success: $success, '
        'items: $totalItems)';
  }
}
