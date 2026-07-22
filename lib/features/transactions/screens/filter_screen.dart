import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/enums/database_enums.dart';
import '../../../core/models/dto/transaction_dto.dart';
import '../../../theme/app_colors.dart';
import '../../partners/providers/partner_provider.dart';

class FilterScreen extends ConsumerStatefulWidget {
  final TransactionFilter currentFilter;

  const FilterScreen({super.key, required this.currentFilter});

  @override
  ConsumerState<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends ConsumerState<FilterScreen>
    with SingleTickerProviderStateMixin {
  DateTime? _startDate;
  DateTime? _endDate;
  final Set<TransactionType> _selectedTypes = {};
  final Set<String> _selectedPartnerIds = {};
  final Set<String> _selectedCategories = {};
  double? _minAmount;
  double? _maxAmount;
  late final TextEditingController _minAmountController;
  late final TextEditingController _maxAmountController;

  late AnimationController _animationController;
  late Animation<double> _fadeIn;

  static const _allCategories = <String>[
    'Salary',
    'Rent',
    'Utilities',
    'Marketing',
    'Supplies',
    'Commission',
    'Interest',
    'Sales Revenue',
    'Service Income',
    'Capital Investment',
    'Asset Purchase',
    'Owner Draw',
    'Bank Transfer',
    'Loan Repayment',
    'Correction',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final f = widget.currentFilter;
    _startDate = f.startDate;
    _endDate = f.endDate;
    if (f.type != null) _selectedTypes.add(f.type!);
    if (f.partnerId != null) _selectedPartnerIds.add(f.partnerId!);
    if (f.category != null) _selectedCategories.add(f.category!);
    _minAmount = f.minAmount;
    _maxAmount = f.maxAmount;
    _minAmountController = TextEditingController(
      text: _minAmount?.toStringAsFixed(2) ?? '',
    );
    _maxAmountController = TextEditingController(
      text: _maxAmount?.toStringAsFixed(2) ?? '',
    );

    _animationController = AnimationController(
      vsync: this,
      duration: AppConstants.animationDurationNormal,
    );
    _fadeIn = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _startDate != null ||
      _endDate != null ||
      _selectedTypes.isNotEmpty ||
      _selectedPartnerIds.isNotEmpty ||
      _selectedCategories.isNotEmpty ||
      _minAmount != null ||
      _maxAmount != null;

  int get _activeFilterCount {
    int count = 0;
    if (_startDate != null || _endDate != null) count++;
    if (_selectedTypes.isNotEmpty) count++;
    if (_selectedPartnerIds.isNotEmpty) count++;
    if (_selectedCategories.isNotEmpty) count++;
    if (_minAmount != null || _maxAmount != null) count++;
    return count;
  }

  void _clearAll() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedTypes.clear();
      _selectedPartnerIds.clear();
      _selectedCategories.clear();
      _minAmount = null;
      _maxAmount = null;
      _minAmountController.clear();
      _maxAmountController.clear();
    });
  }

  void _applyFilters() {
    _minAmount = double.tryParse(_minAmountController.text.trim());
    _maxAmount = double.tryParse(_maxAmountController.text.trim());

    final filter = TransactionFilter(
      startDate: _startDate,
      endDate: _endDate,
      type: _selectedTypes.length == 1 ? _selectedTypes.first : null,
      partnerId: _selectedPartnerIds.length == 1
          ? _selectedPartnerIds.first
          : null,
      category:
          _selectedCategories.length == 1 ? _selectedCategories.first : null,
      minAmount: _minAmount,
      maxAmount: _maxAmount,
    );
    Navigator.pop(context, filter);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final partners = ref.watch(filteredPartnersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters'),
        actions: [
          if (_hasActiveFilters)
            TextButton(
              onPressed: _clearAll,
              child: const Text('Clear all'),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader(
              theme,
              colorScheme,
              'Date Range',
              Icons.date_range_rounded,
              trailing: _startDate != null
                  ? TextButton(
                      onPressed: () =>
                          setState(() { _startDate = null; _endDate = null; }),
                      child: const Text('Clear'),
                    )
                  : null,
            ),
            const Gap(12),
            _buildDateRangeTile(theme, colorScheme),
            const Gap(24),
            _buildSectionHeader(
              theme,
              colorScheme,
              'Transaction Type',
              Icons.category_rounded,
              count: _selectedTypes.length,
            ),
            const Gap(12),
            _buildTypeChips(theme, colorScheme),
            const Gap(24),
            _buildSectionHeader(
              theme,
              colorScheme,
              'Partners',
              Icons.people_rounded,
              count: _selectedPartnerIds.length,
            ),
            const Gap(12),
            _buildPartnerChips(theme, colorScheme, partners),
            const Gap(24),
            _buildSectionHeader(
              theme,
              colorScheme,
              'Categories',
              Icons.label_outline_rounded,
              count: _selectedCategories.length,
            ),
            const Gap(12),
            _buildCategoryChips(theme, colorScheme),
            const Gap(24),
            _buildSectionHeader(
              theme,
              colorScheme,
              'Amount Range',
              Icons.attach_money_rounded,
              count: (_minAmount != null || _maxAmount != null) ? 1 : 0,
            ),
            const Gap(12),
            _buildAmountRange(theme, colorScheme),
            const Gap(32),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(theme, colorScheme),
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    String title,
    IconData icon, {
    int count = 0,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const Gap(8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (count > 0) ...[
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const Spacer(),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildDateRangeTile(ThemeData theme, ColorScheme colorScheme) {
    final hasRange = _startDate != null && _endDate != null;
    return Card(
      child: InkWell(
        onTap: _pickDateRange,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: hasRange
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  size: 20,
                  color: hasRange
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const Gap(12),
              Expanded(
                child: hasRange
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Gap(2),
                          Text(
                            '${_endDate!.difference(_startDate!).inDays + 1} days',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Select date range',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChips(ThemeData theme, ColorScheme colorScheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TransactionType.values.map((type) {
        final isSelected = _selectedTypes.contains(type);
        return FilterChip(
          avatar: Icon(
            _iconForType(type),
            size: 18,
            color: isSelected ? colorScheme.primary : _colorForType(type),
          ),
          label: Text(type.name[0].toUpperCase() + type.name.substring(1)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedTypes.add(type);
              } else {
                _selectedTypes.remove(type);
              }
            });
          },
          selectedColor: colorScheme.primaryContainer,
          checkmarkColor: colorScheme.primary,
          side: BorderSide(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPartnerChips(
    ThemeData theme,
    ColorScheme colorScheme,
    List partners,
  ) {
    if (partners.isEmpty) {
      return Text(
        'No partners available',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: partners.map<Widget>((partner) {
        final isSelected = _selectedPartnerIds.contains(partner.id);
        return FilterChip(
          avatar: CircleAvatar(
            radius: 10,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              (partner.name as String)[0].toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
          label: Text(partner.name as String),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedPartnerIds.add(partner.id as String);
              } else {
                _selectedPartnerIds.remove(partner.id as String);
              }
            });
          },
          selectedColor: colorScheme.primaryContainer,
          checkmarkColor: colorScheme.primary,
          side: BorderSide(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryChips(ThemeData theme, ColorScheme colorScheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allCategories.map((cat) {
        final isSelected = _selectedCategories.contains(cat);
        return FilterChip(
          label: Text(cat),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedCategories.add(cat);
              } else {
                _selectedCategories.remove(cat);
              }
            });
          },
          selectedColor: colorScheme.secondaryContainer,
          checkmarkColor: colorScheme.secondary,
          side: BorderSide(
            color:
                isSelected ? colorScheme.secondary : colorScheme.outlineVariant,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmountRange(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _minAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Min amount',
              prefixText: '₹ ',
              prefixStyle: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              isDense: true,
            ),
            onChanged: (v) {
              _minAmount = double.tryParse(v.trim());
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(
            Icons.arrow_forward_rounded,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        Expanded(
          child: TextField(
            controller: _maxAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Max amount',
              prefixText: '₹ ',
              prefixStyle: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              isDense: true,
            ),
            onChanged: (v) {
              _maxAmount = double.tryParse(v.trim());
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _hasActiveFilters ? _clearAll : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Clear All'),
              ),
            ),
            const Gap(12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _applyFilters,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _hasActiveFilters
                    ? Text(
                        'Apply ($_activeFilterCount filter${_activeFilterCount > 1 ? 's' : ''})',
                      )
                    : const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

  static Color _colorForType(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.expense:
        return AppColors.expense;
      case TransactionType.investment:
        return AppColors.investment;
      case TransactionType.withdrawal:
        return AppColors.withdrawal;
      case TransactionType.transfer:
        return AppColors.transfer;
      case TransactionType.loan:
      case TransactionType.loanRepayment:
        return AppColors.loan;
      case TransactionType.adjustment:
        return AppColors.adjustment;
      case TransactionType.profitDistribution:
        return AppColors.profit;
      case TransactionType.lossAllocation:
        return AppColors.loss;
    }
  }
}
