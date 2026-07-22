import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/enums/database_enums.dart';
import '../../../core/models/entities/notification.dart';
import '../../../widgets/common/app_bar_widget.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../widgets/cards/notification_card.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).fetch();
    });
  }

  String _typeName(NotificationType type) {
    switch (type) {
      case NotificationType.system: return 'System';
      case NotificationType.transaction: return 'Transaction';
      case NotificationType.partner: return 'Partner';
      case NotificationType.ledger: return 'Ledger';
      case NotificationType.reminder: return 'Reminder';
      case NotificationType.alert: return 'Alert';
    }
  }

  List<AppNotification> _filterNotifications(
    List<AppNotification> notifications,
  ) {
    if (_selectedFilter == null) return notifications;
    return notifications.where((n) => n.type == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(notificationsProvider);
    final filtered = _filterNotifications(state.notifications);

    return Scaffold(
      appBar: AppBarWidget(
        title: 'Notifications',
        showBack: false,
        actions: [
          if (state.notifications.any((n) => n.isUnread))
            IconButton(
              icon: const Icon(Icons.done_all_rounded),
              tooltip: 'Mark all as read',
              onPressed: () {
                ref.read(notificationsProvider.notifier).markAllRead();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(theme),
          Expanded(
            child: _buildContent(state, filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final types = NotificationType.values;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _FilterChipWidget(
            label: 'All',
            selected: _selectedFilter == null,
            onPressed: () => setState(() => _selectedFilter = null),
          ),
          ...types.map(
            (type) => Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _FilterChipWidget(
                label: _typeName(type),
                selected: _selectedFilter == type,
                onPressed: () => setState(() => _selectedFilter = type),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(NotificationsState state, List<AppNotification> filtered) {
    final colorScheme = Theme.of(context).colorScheme;

    if (state.isLoading && state.notifications.isEmpty) {
      return const LoadingWidget.shimmerList();
    }

    if (state.error != null && state.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('Something went wrong',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(state.error!, textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () {
                  ref.read(notificationsProvider.notifier).clearError();
                  ref.read(notificationsProvider.notifier).fetch();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      if (_selectedFilter != null) {
        return EmptyStateWidget(
          icon: Icons.filter_alt_off_rounded,
          title: 'No ${_typeName(_selectedFilter!)} Notifications',
          subtitle: 'There are no notifications of this type.',
        );
      }
      return const EmptyStateWidget(
        icon: Icons.notifications_off_outlined,
        title: 'No Notifications',
        subtitle: 'You\'re all caught up! No notifications to show.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationsProvider.notifier).fetch(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final notification = filtered[index];
          return Dismissible(
            key: ValueKey(notification.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              color: colorScheme.error,
              child: Icon(Icons.delete_outline_rounded, color: colorScheme.onError, size: 28),
            ),
            onDismissed: (_) {},
            child: NotificationCard(
              notification: notification,
              onTap: () {},
              onMarkRead: notification.isUnread
                  ? () => ref.read(notificationsProvider.notifier).markRead(notification.id)
                  : null,
            ),
          );
        },
      ),
    );
  }
}

class _FilterChipWidget extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _FilterChipWidget({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onPressed(),
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        selectedColor: colorScheme.primaryContainer,
        checkmarkColor: colorScheme.primary,
        side: BorderSide(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.outlineVariant,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}
