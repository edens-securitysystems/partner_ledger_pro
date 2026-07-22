import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/enums/database_enums.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/forms/app_amount_field.dart';
import '../../../widgets/forms/app_dropdown.dart';
import '../../../widgets/forms/app_text_field.dart';

class LedgerEntryForm extends ConsumerStatefulWidget {
  final String partnerId;
  final VoidCallback? onSaved;

  const LedgerEntryForm({
    super.key,
    required this.partnerId,
    this.onSaved,
  });

  @override
  ConsumerState<LedgerEntryForm> createState() => _LedgerEntryFormState();
}

class _LedgerEntryFormState extends ConsumerState<LedgerEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  TransactionType _transactionType = TransactionType.adjustment;
  DateTime _entryDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _isCreditType(TransactionType type) {
    return type == TransactionType.income ||
        type == TransactionType.investment ||
        type == TransactionType.loanRepayment ||
        type == TransactionType.profitDistribution;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      widget.onSaved?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ledger entry added successfully'),
            backgroundColor: AppColors.profit,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd MMM yyyy');
    final isCredit = _isCreditType(_transactionType);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'New Ledger Entry',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AppDropdown<TransactionType>(
                label: 'Transaction Type',
                value: _transactionType,
                prefixIcon: Icons.category_rounded,
                items: TransactionType.values.map((type) {
                  final isCredit = _isCreditType(type);
                  return AppDropdownItem<TransactionType>(
                    value: type,
                    label: _typeLabel(type),
                    iconColor: isCredit ? AppColors.profit : AppColors.loss,
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _transactionType = value);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCredit
                          ? AppColors.profitLight
                          : AppColors.lossLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCredit
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          size: 14,
                          color: isCredit ? AppColors.profit : AppColors.loss,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isCredit ? 'Credit' : 'Debit',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                isCredit ? AppColors.profit : AppColors.loss,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppAmountField(
                label: 'Amount',
                hint: '0.00',
                controller: _amountController,
                prefixIcon: Icons.currency_rupee_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Amount is required';
                  }
                  final amount = double.tryParse(value.replaceAll(',', ''));
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _entryDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _entryDate = picked);
                },
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Entry Date',
                    prefixIcon:
                        const Icon(Icons.calendar_today_rounded, size: 20),
                    suffixIcon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  child: Text(
                    dateFormat.format(_entryDate),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Description',
                hint: 'Enter description for this entry',
                controller: _descriptionController,
                prefixIcon: Icons.description_outlined,
                maxLines: 2,
                minLines: 1,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Add Entry',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.investment:
        return 'Investment';
      case TransactionType.withdrawal:
        return 'Withdrawal';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.income:
        return 'Income';
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
