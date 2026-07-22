import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/database/enums/database_enums.dart';

class TransactionTypeSelector extends StatelessWidget {
  final TransactionType selectedType;
  final ValueChanged<TransactionType> onTypeSelected;
  final bool enabled;
  final List<TransactionType> availableTypes;

  const TransactionTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
    this.enabled = true,
    this.availableTypes = const [],
  });

  List<TransactionType> get _displayTypes =>
      availableTypes.isEmpty
          ? TransactionType.values
          : availableTypes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Type',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const Gap(12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _displayTypes.map((type) {
            return _TypeCard(
              type: type,
              isSelected: selectedType == type,
              enabled: enabled,
              onTap: () => onTypeSelected(type),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  final TransactionType type;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _TypeCard({
    required this.type,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final typeColor = Color.lerp(_colorForType(type), colorScheme.primary, 0.0)!;
    final bgColor = _bgColorForType(type);
    final effectiveBgColor = isSelected
        ? typeColor
        : bgColor;
    final effectiveIconColor = isSelected
        ? colorScheme.onPrimary
        : typeColor;
    final effectiveTextColor = isSelected
        ? colorScheme.onPrimary
        : colorScheme.onSurface;

    return AnimatedScale(
      scale: isSelected ? 1.0 : 0.97,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 105,
        height: 80,
        decoration: BoxDecoration(
          color: effectiveBgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? typeColor
                : colorScheme.outlineVariant,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: typeColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _iconForType(type),
                    size: 26,
                    color: effectiveIconColor,
                  ),
                  const Gap(6),
                  Text(
                    _shortLabel(type),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: effectiveTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _colorForType(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return const Color(0xFF276749);
      case TransactionType.expense:
        return const Color(0xFFC05621);
      case TransactionType.investment:
        return const Color(0xFF2B6CB0);
      case TransactionType.withdrawal:
        return const Color(0xFF9C4221);
      case TransactionType.transfer:
        return const Color(0xFF553C9A);
      case TransactionType.loan:
      case TransactionType.loanRepayment:
        return const Color(0xFF2C7A7B);
      case TransactionType.adjustment:
        return const Color(0xFF718096);
      case TransactionType.profitDistribution:
        return const Color(0xFF276749);
      case TransactionType.lossAllocation:
        return const Color(0xFF9B2C2C);
    }
  }

  static Color _bgColorForType(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return const Color(0xFFC6F6D5);
      case TransactionType.expense:
        return const Color(0xFFFEEBC8);
      case TransactionType.investment:
        return const Color(0xFFBEE3F8);
      case TransactionType.withdrawal:
        return const Color(0xFFFEEBC8);
      case TransactionType.transfer:
        return const Color(0xFFE9D8FD);
      case TransactionType.loan:
      case TransactionType.loanRepayment:
        return const Color(0xFFB2F5EA);
      case TransactionType.adjustment:
        return const Color(0xFFE2E8F0);
      case TransactionType.profitDistribution:
        return const Color(0xFFC6F6D5);
      case TransactionType.lossAllocation:
        return const Color(0xFFFED7D7);
    }
  }

  static IconData _iconForType(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.trending_up_rounded;
      case TransactionType.expense:
        return Icons.trending_down_rounded;
      case TransactionType.investment:
        return Icons.account_balance_rounded;
      case TransactionType.withdrawal:
        return Icons.payments_rounded;
      case TransactionType.transfer:
        return Icons.swap_horiz_rounded;
      case TransactionType.loan:
        return Icons.handshake_rounded;
      case TransactionType.loanRepayment:
        return Icons.replay_rounded;
      case TransactionType.adjustment:
        return Icons.tune_rounded;
      case TransactionType.profitDistribution:
        return Icons.emoji_events_rounded;
      case TransactionType.lossAllocation:
        return Icons.warning_rounded;
    }
  }

  static String _shortLabel(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.investment:
        return 'Invest';
      case TransactionType.withdrawal:
        return 'Withdraw';
      case TransactionType.transfer:
        return 'Transfer';
      case TransactionType.loan:
        return 'Loan';
      case TransactionType.loanRepayment:
        return 'Repay';
      case TransactionType.adjustment:
        return 'Adjust';
      case TransactionType.profitDistribution:
        return 'Profit';
      case TransactionType.lossAllocation:
        return 'Loss';
    }
  }
}
