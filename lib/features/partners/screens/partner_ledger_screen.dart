import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/enums/database_enums.dart';
import '../../../core/models/entities/partner.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common/app_bar_widget.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../../../widgets/forms/app_date_picker.dart';
import '../providers/partner_provider.dart';
import '../widgets/ledger_entry_form.dart';

class PartnerLedgerScreen extends ConsumerStatefulWidget {
  final String partnerId;

  const PartnerLedgerScreen({super.key, required this.partnerId});

  @override
  ConsumerState<PartnerLedgerScreen> createState() =>
      _PartnerLedgerScreenState();
}

class _PartnerLedgerScreenState extends ConsumerState<PartnerLedgerScreen> {
  DateTimeRange? _dateRange;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(partnersProvider.notifier).fetchAll();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Partner? _findPartner() {
    final state = ref.read(partnersProvider);
    try {
      return state.partners.firstWhere((p) => p.id == widget.partnerId);
    } catch (_) {
      return null;
    }
  }

  List<_LedgerRow> _buildLedgerRows(Partner partner) {
    final rows = <_LedgerRow>[
      _LedgerRow(
        date: partner.joiningDate,
        description: 'Opening Balance - Capital Investment',
        amount: partner.capital,
        isCredit: true,
        runningBalance: partner.capital,
      ),
      _LedgerRow(
        date: partner.joiningDate.add(const Duration(days: 15)),
        description: 'Additional Investment',
        amount: partner.capital * 0.25,
        isCredit: true,
        runningBalance: partner.capital * 1.25,
      ),
      _LedgerRow(
        date: partner.joiningDate.add(const Duration(days: 30)),
        description: 'Monthly Profit Distribution',
        amount: partner.capital * 0.08,
        isCredit: true,
        runningBalance: partner.capital * 1.33,
      ),
      _LedgerRow(
        date: partner.joiningDate.add(const Duration(days: 35)),
        description: 'Office Supplies Expense',
        amount: partner.capital * 0.02,
        isCredit: false,
        runningBalance: partner.capital * 1.31,
      ),
      _LedgerRow(
        date: partner.joiningDate.add(const Duration(days: 45)),
        description: 'Withdrawal',
        amount: partner.capital * 0.10,
        isCredit: false,
        runningBalance: partner.capital * 1.21,
      ),
      _LedgerRow(
        date: partner.joiningDate.add(const Duration(days: 60)),
        description: 'Quarterly Bonus',
        amount: partner.capital * 0.15,
        isCredit: true,
        runningBalance: partner.capital * 1.36,
      ),
      _LedgerRow(
        date: partner.joiningDate.add(const Duration(days: 68)),
        description: 'Maintenance Contribution',
        amount: partner.capital * 0.03,
        isCredit: false,
        runningBalance: partner.capital * 1.33,
      ),
      _LedgerRow(
        date: partner.joiningDate.add(const Duration(days: 90)),
        description: 'Half-Yearly Profit Share',
        amount: partner.capital * 0.20,
        isCredit: true,
        runningBalance: partner.capital * 1.53,
      ),
    ];

    if (_dateRange != null) {
      return rows
          .where((r) =>
              r.date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
              r.date.isBefore(_dateRange!.end.add(const Duration(days: 1))))
          .toList();
    }

    return rows;
  }

  void _showAddEntrySheet(Partner partner) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => LedgerEntryForm(
        partnerId: partner.id,
        onSaved: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final partner = _findPartner();
    final currencyFormat = NumberFormat('#,##0.00');

    if (partner == null) {
      return Scaffold(
        appBar: AppBarWidget(title: 'Partner Ledger'),
        body: const Center(child: Text('Partner not found')),
      );
    }

    final ledgerRows = _buildLedgerRows(partner);
    final totalDebit = ledgerRows
        .where((r) => !r.isCredit)
        .fold(0.0, (sum, r) => sum + r.amount);
    final totalCredit = ledgerRows
        .where((r) => r.isCredit)
        .fold(0.0, (sum, r) => sum + r.amount);
    final closingBalance = totalCredit - totalDebit + partner.capital;

    return Scaffold(
      appBar: AppBarWidget(
        title: '${partner.name} Ledger',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showDateRangePicker,
          ),
          IconButton(
            icon: const Icon(Icons.print_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPartnerHeader(theme, colorScheme, partner, currencyFormat),
          _buildDateRangeBanner(colorScheme),
          Expanded(
            child: ledgerRows.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.receipt_long_rounded,
                    title: 'No Entries Found',
                    subtitle: _dateRange != null
                        ? 'No ledger entries in the selected date range.'
                        : 'No ledger entries yet for this partner.',
                  )
                : _buildLedgerList(
                    theme, colorScheme, ledgerRows, currencyFormat),
          ),
          _buildSummaryFooter(
              theme, colorScheme, totalDebit, totalCredit, closingBalance, currencyFormat),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntrySheet(partner),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Entry'),
      ),
    );
  }

  Widget _buildPartnerHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    Partner partner,
    NumberFormat currencyFormat,
  ) {
    final initial =
        partner.name.isNotEmpty ? partner.name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              initial,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partner.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Opening Balance: \u20B9${currencyFormat.format(partner.capital)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: partner.status == PartnerStatus.active
                  ? AppColors.profitLight
                  : AppColors.lossLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              partner.statusDisplay,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: partner.status == PartnerStatus.active
                    ? AppColors.profit
                    : AppColors.loss,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeBanner(ColorScheme colorScheme) {
    if (_dateRange == null) return const SizedBox.shrink();

    final dateFormat = DateFormat('dd MMM');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Row(
        children: [
          Icon(Icons.date_range_rounded,
              size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            '${dateFormat.format(_dateRange!.start)} - ${dateFormat.format(_dateRange!.end)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _dateRange = null),
            child: Text(
              'Clear',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerList(
    ThemeData theme,
    ColorScheme colorScheme,
    List<_LedgerRow> rows,
    NumberFormat currencyFormat,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        final amountColor =
            row.isCredit ? AppColors.profit : AppColors.loss;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: amountColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            row.isCredit
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 14,
                            color: amountColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              row.description,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            DateFormat('dd MMM yyyy').format(row.date),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Bal: \u20B9${currencyFormat.format(row.runningBalance)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${row.isCredit ? '+' : '-'}\u20B9${currencyFormat.format(row.amount)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      row.isCredit ? 'Credit' : 'Debit',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryFooter(
    ThemeData theme,
    ColorScheme colorScheme,
    double totalDebit,
    double totalCredit,
    double closingBalance,
    NumberFormat currencyFormat,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _summaryItem(
                    theme,
                    'Total Credit',
                    '\u20B9${currencyFormat.format(totalCredit)}',
                    AppColors.profit,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryItem(
                    theme,
                    'Total Debit',
                    '\u20B9${currencyFormat.format(totalDebit)}',
                    AppColors.loss,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Closing Balance: ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    '\u20B9${currencyFormat.format(closingBalance)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(
    ThemeData theme,
    String label,
    String amount,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showDateRangePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        DateTimeRange? tempRange = _dateRange;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Filter by Date Range',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppDateRangePicker(
                      label: 'Date Range',
                      selectedRange: tempRange,
                      onRangeSelected: (range) {
                        setModalState(() => tempRange = range);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() => _dateRange = null);
                              Navigator.pop(context);
                            },
                            child: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              setState(() => _dateRange = tempRange);
                              Navigator.pop(context);
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LedgerRow {
  final DateTime date;
  final String description;
  final double amount;
  final bool isCredit;
  final double runningBalance;

  const _LedgerRow({
    required this.date,
    required this.description,
    required this.amount,
    required this.isCredit,
    required this.runningBalance,
  });
}
