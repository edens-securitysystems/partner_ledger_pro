import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/enums/database_enums.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../providers/dashboard_provider.dart';

class RecentActivity extends ConsumerWidget {
  final VoidCallback? onViewAll;

  const RecentActivity({super.key, this.onViewAll});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(dashboardDataProvider);
    final transactions = dashboardData?.recentTransactions ?? [];

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (transactions.isNotEmpty && onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('View All'),
                  ),
              ],
            ),
          ),
          if (transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: EmptyStateWidget(
                icon: Icons.receipt_long_rounded,
                title: 'No Recent Transactions',
                subtitle: 'Transactions will appear here once you start logging them.',
              ),
            )
          else
            ...List.generate(
              transactions.length.clamp(0, 10),
              (index) => _TransactionTile(
                data: transactions[index],
                isLast: index ==
                    (transactions.length.clamp(0, 10) - 1),
              ),
            ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isLast;

  const _TransactionTile({required this.data, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final typeStr = data['type'] as String? ?? 'adjustment';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final dateStr = data['date'] as String? ?? '';
    final partnerName = data['partnerName'] as String? ?? 'Unknown';
    final category = data['category'] as String?;

    TransactionType type;
    try {
      type = TransactionType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => TransactionType.adjustment,
      );
    } catch (_) {
      type = TransactionType.adjustment;
    }

    final isIncome = type == TransactionType.income ||
        type == TransactionType.investment ||
        type == TransactionType.loanRepayment ||
        type == TransactionType.profitDistribution;

    final amountColor = isIncome ? AppColors.credit : AppColors.debit;
    final prefix = isIncome ? '+' : '-';

    DateTime? date;
    if (dateStr.isNotEmpty) {
      try {
        date = DateTime.parse(dateStr);
      } catch (_) {
        date = null;
      }
    }

    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: _TypeIcon(type: type),
          title: Text(
            category ?? _typeDisplayName(type),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Row(
            children: [
              Text(
                partnerName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (date != null) ...[
                const SizedBox(width: 6),
                Text(
                  _formatDate(date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          trailing: Text(
            '$prefix${_formatAmount(amount)}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 72,
            color: colorScheme.outlineVariant,
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat(AppConstants.dateFormatShort).format(date);
  }

  String _formatAmount(double amount) {
    if (amount.abs() >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount.abs() >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return NumberFormat('#,##0.00').format(amount);
  }

  String _typeDisplayName(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.investment:
        return 'Investment';
      case TransactionType.withdrawal:
        return 'Withdrawal';
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
}

class _TypeIcon extends StatelessWidget {
  final TransactionType type;

  const _TypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final config = _iconConfig(type);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: config.$2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(config.$1, size: 20, color: config.$3),
    );
  }

  (IconData, Color, Color) _iconConfig(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return (
          Icons.trending_up_rounded,
          AppColors.incomeLight,
          AppColors.incomeDark,
        );
      case TransactionType.expense:
        return (
          Icons.trending_down_rounded,
          AppColors.expenseLight,
          AppColors.expenseDark,
        );
      case TransactionType.investment:
        return (
          Icons.account_balance_rounded,
          AppColors.investmentLight,
          AppColors.investmentDark,
        );
      case TransactionType.withdrawal:
        return (
          Icons.payments_rounded,
          AppColors.withdrawalLight,
          AppColors.withdrawalDark,
        );
      case TransactionType.transfer:
        return (
          Icons.swap_horiz_rounded,
          AppColors.transferLight,
          AppColors.transferDark,
        );
      case TransactionType.loan:
        return (
          Icons.handshake_rounded,
          AppColors.loanLight,
          AppColors.loanDark,
        );
      case TransactionType.loanRepayment:
        return (
          Icons.replay_rounded,
          AppColors.loanLight,
          AppColors.loanDark,
        );
      case TransactionType.adjustment:
        return (
          Icons.tune_rounded,
          AppColors.adjustmentLight,
          AppColors.adjustmentDark,
        );
      case TransactionType.profitDistribution:
        return (
          Icons.emoji_events_rounded,
          AppColors.profitLight,
          AppColors.profitDark,
        );
      case TransactionType.lossAllocation:
        return (
          Icons.warning_rounded,
          AppColors.lossLight,
          AppColors.lossDark,
        );
    }
  }
}
