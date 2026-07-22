import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/database/enums/database_enums.dart';
import '../../../core/models/entities/partner.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common/stat_card.dart';
import '../../../widgets/common/summary_card.dart';

class PartnerStatsWidget extends StatelessWidget {
  final Partner partner;

  const PartnerStatsWidget({super.key, required this.partner});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat('#,##0.00');

    final estimatedProfit = partner.capital * 0.15;
    final estimatedReturn = partner.capital > 0
        ? ((estimatedProfit / partner.capital) * 100)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Summary',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildMainStats(theme, colorScheme, currencyFormat, estimatedProfit,
            estimatedReturn),
        const SizedBox(height: 12),
        _buildDetailCards(
            theme, colorScheme, currencyFormat, estimatedProfit),
      ],
    );
  }

  Widget _buildMainStats(
    ThemeData theme,
    ColorScheme colorScheme,
    NumberFormat currencyFormat,
    double estimatedProfit,
    double estimatedReturn,
  ) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Capital',
            value: '\u20B9${currencyFormat.format(partner.capital)}',
            icon: Icons.account_balance_rounded,
            iconColor: AppColors.investment,
            useGradient: true,
            backgroundColor: AppColors.investmentDark,
            sparklineData: [
              partner.capital * 0.6,
              partner.capital * 0.7,
              partner.capital * 0.75,
              partner.capital * 0.85,
              partner.capital * 0.9,
              partner.capital,
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatCard(
            title: 'Ownership',
            value: '${partner.ownershipPercentage.toStringAsFixed(1)}%',
            icon: Icons.pie_chart_rounded,
            iconColor: AppColors.transfer,
            useGradient: true,
            backgroundColor: AppColors.transferDark,
            sparklineData: [
              partner.ownershipPercentage * 0.7,
              partner.ownershipPercentage * 0.8,
              partner.ownershipPercentage * 0.85,
              partner.ownershipPercentage * 0.95,
              partner.ownershipPercentage,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCards(
    ThemeData theme,
    ColorScheme colorScheme,
    NumberFormat currencyFormat,
    double estimatedProfit,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                label: 'Est. Profit Share',
                amount:
                    '\u20B9${currencyFormat.format(estimatedProfit)}',
                icon: Icons.trending_up_rounded,
                iconColor: AppColors.profit,
                amountColor: AppColors.profit,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SummaryCard(
                label: 'Joining Date',
                amount: DateFormat('dd MMM yy')
                    .format(partner.joiningDate),
                icon: Icons.calendar_today_rounded,
                iconColor: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                label: 'Account Status',
                amount: partner.statusDisplay,
                icon: Icons.verified_rounded,
                iconColor: partner.status == PartnerStatus.active
                    ? AppColors.statusActive
                    : AppColors.statusSuspended,
                amountColor: partner.status == PartnerStatus.active
                    ? AppColors.statusActive
                    : AppColors.statusSuspended,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SummaryCard(
                label: 'Can Transact',
                amount: partner.canTransact ? 'Yes' : 'No',
                icon: partner.canTransact
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                iconColor: partner.canTransact
                    ? AppColors.profit
                    : AppColors.loss,
                amountColor: partner.canTransact
                    ? AppColors.profit
                    : AppColors.loss,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
