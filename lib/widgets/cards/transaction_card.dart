import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../core/database/enums/database_enums.dart';
import '../../core/models/entities/transaction.dart';
import '../../theme/app_colors.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? partnerName;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.partnerName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd MMM yyyy');

    final isCredit = transaction.isCredit;
    final amountColor = isCredit ? AppColors.credit : AppColors.debit;
    final amountPrefix = isCredit ? '+' : '-';

    return Slidable(
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          if (onEdit != null)
            SlidableAction(
              onPressed: (_) => onEdit!(),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              icon: Icons.edit_rounded,
              label: 'Edit',
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
            ),
          if (onDelete != null)
            SlidableAction(
              onPressed: (_) => onDelete!(),
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              icon: Icons.delete_rounded,
              label: 'Delete',
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(12),
              ),
            ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _buildTypeIcon(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.category ?? transaction.typeDisplay,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            dateFormat.format(transaction.date),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (transaction.time != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              transaction.time!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (partnerName != null) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                partnerName!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$amountPrefix${NumberFormat('#,##0.00').format(transaction.amount)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _buildTypeBadge(context),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(BuildContext context) {
    IconData icon;
    Color bgColor;
    Color iconColor;

    switch (transaction.type) {
      case TransactionType.income:
        icon = Icons.trending_up_rounded;
        bgColor = AppColors.incomeLight;
        iconColor = AppColors.income;
        break;
      case TransactionType.expense:
        icon = Icons.trending_down_rounded;
        bgColor = AppColors.expenseLight;
        iconColor = AppColors.expense;
        break;
      case TransactionType.investment:
        icon = Icons.account_balance_rounded;
        bgColor = AppColors.investmentLight;
        iconColor = AppColors.investment;
        break;
      case TransactionType.withdrawal:
        icon = Icons.payments_rounded;
        bgColor = AppColors.withdrawalLight;
        iconColor = AppColors.withdrawal;
        break;
      case TransactionType.transfer:
        icon = Icons.swap_horiz_rounded;
        bgColor = AppColors.transferLight;
        iconColor = AppColors.transfer;
        break;
      case TransactionType.loan:
        icon = Icons.handshake_rounded;
        bgColor = AppColors.loanLight;
        iconColor = AppColors.loan;
        break;
      case TransactionType.loanRepayment:
        icon = Icons.replay_rounded;
        bgColor = AppColors.loanLight;
        iconColor = AppColors.loan;
        break;
      case TransactionType.adjustment:
        icon = Icons.tune_rounded;
        bgColor = AppColors.adjustmentLight;
        iconColor = AppColors.adjustment;
        break;
      case TransactionType.profitDistribution:
        icon = Icons.emoji_events_rounded;
        bgColor = AppColors.profitLight;
        iconColor = AppColors.profit;
        break;
      case TransactionType.lossAllocation:
        icon = Icons.warning_rounded;
        bgColor = AppColors.lossLight;
        iconColor = AppColors.loss;
        break;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22, color: iconColor),
    );
  }

  Widget _buildTypeBadge(BuildContext context) {
    Color bgColor;
    Color textColor;
    String shortName;

    switch (transaction.type) {
      case TransactionType.income:
        shortName = 'INC';
        bgColor = AppColors.incomeLight;
        textColor = AppColors.income;
        break;
      case TransactionType.expense:
        shortName = 'EXP';
        bgColor = AppColors.expenseLight;
        textColor = AppColors.expense;
        break;
      case TransactionType.investment:
        shortName = 'INV';
        bgColor = AppColors.investmentLight;
        textColor = AppColors.investment;
        break;
      case TransactionType.withdrawal:
        shortName = 'WTH';
        bgColor = AppColors.withdrawalLight;
        textColor = AppColors.withdrawal;
        break;
      case TransactionType.transfer:
        shortName = 'TRF';
        bgColor = AppColors.transferLight;
        textColor = AppColors.transfer;
        break;
      case TransactionType.loan:
        shortName = 'LON';
        bgColor = AppColors.loanLight;
        textColor = AppColors.loan;
        break;
      case TransactionType.loanRepayment:
        shortName = 'LRP';
        bgColor = AppColors.loanLight;
        textColor = AppColors.loan;
        break;
      case TransactionType.adjustment:
        shortName = 'ADJ';
        bgColor = AppColors.adjustmentLight;
        textColor = AppColors.adjustment;
        break;
      case TransactionType.profitDistribution:
        shortName = 'PRF';
        bgColor = AppColors.profitLight;
        textColor = AppColors.profit;
        break;
      case TransactionType.lossAllocation:
        shortName = 'LSS';
        bgColor = AppColors.lossLight;
        textColor = AppColors.loss;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        shortName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
