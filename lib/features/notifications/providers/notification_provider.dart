import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/entities/notification.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/repositories/notification_repository.dart';

// ── State ────────────────────────────────────────────────────────────────────

class NotificationsState extends Equatable {
  final bool isLoading;
  final String? error;
  final List<AppNotification> notifications;
  final int unreadCount;

  const NotificationsState({
    this.isLoading = false,
    this.error,
    this.notifications = const [],
    this.unreadCount = 0,
  });

  const NotificationsState.initial() : this();

  NotificationsState copyWith({
    bool? isLoading,
    String? error,
    List<AppNotification>? notifications,
    int? unreadCount,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [isLoading, error, notifications, unreadCount];
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationRepository _repository;

  NotificationsNotifier(this._repository) : super(const NotificationsState.initial());

  Future<void> fetch({String? userId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.getAll();
      if (response.success && response.data != null) {
        final countResponse = await _repository.getUnreadCount();
        final unread = countResponse.success && countResponse.data != null
            ? countResponse.data!
            : response.data!.where((n) => n.isUnread).length;
        state = state.copyWith(
          isLoading: false,
          notifications: response.data,
          unreadCount: unread,
        );
      } else {
        state = state.copyWith(isLoading: false, error: response.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markRead(String id) async {
    try {
      final response = await _repository.markAsRead(id);
      if (response.success) {
        state = state.copyWith(
          notifications: state.notifications.map((n) {
            if (n.id == id) {
              return n.copyWith(isRead: true);
            }
            return n;
          }).toList(),
          unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
        );
      } else {
        state = state.copyWith(error: response.message);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAllRead({String? userId}) async {
    try {
      final response = await _repository.markAllAsRead();
      if (response.success) {
        state = state.copyWith(
          notifications: state.notifications.map((n) => n.copyWith(isRead: true)).toList(),
          unreadCount: 0,
        );
      } else {
        state = state.copyWith(error: response.message);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<int> unreadCount({String? userId}) async {
    try {
      final response = await _repository.getUnreadCount();
      if (response.success && response.data != null) {
        final count = response.data ?? 0;
        state = state.copyWith(unreadCount: count);
        return count;
      }
      return 0;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return 0;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationsNotifier(repository);
});

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).unreadCount;
});

final notificationsListProvider = Provider<List<AppNotification>>((ref) {
  return ref.watch(notificationsProvider).notifications;
});
