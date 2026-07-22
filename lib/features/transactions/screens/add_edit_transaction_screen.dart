import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/enums/database_enums.dart';
import '../../../core/models/dto/transaction_dto.dart';
import '../../../core/models/entities/transaction.dart';
import '../../../theme/app_colors.dart';
import '../../partners/providers/partner_provider.dart';
import '../../businesses/providers/business_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_type_selector.dart';
import '../widgets/attachment_picker.dart';

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transaction;

  const AddEditTransactionScreen({super.key, this.transaction});

  @override
  ConsumerState<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState
    extends ConsumerState<AddEditTransactionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  final _amountFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  late TransactionType _selectedType;
  DateTime _selectedDate = DateTime.now();
  String? _selectedPartnerId;
  String? _selectedCategory;
  String? _attachmentPath;

  bool _isSubmitting = false;
  bool get _isEditMode => widget.transaction != null;

  late AnimationController _animationController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  static const _categoriesByType = <TransactionType, List<String>>{
    TransactionType.income: [
      'Sales Revenue',
      'Service Income',
      'Commission',
      'Interest',
      'Rental Income',
      'Other Income',
    ],
    TransactionType.expense: [
      'Salary',
      'Rent',
      'Utilities',
      'Marketing',
      'Supplies',
      'Travel',
      'Insurance',
      'Other Expense',
    ],
    TransactionType.investment: [
      'Capital Investment',
      'Asset Purchase',
      'Technology',
      'Other Investment',
    ],
    TransactionType.withdrawal: [
      'Owner Draw',
      'Bank Withdrawal',
      'Other Withdrawal',
    ],
    TransactionType.transfer: [
      'Bank Transfer',
      'Partner Transfer',
      'Account Transfer',
      'Other Transfer',
    ],
    TransactionType.loan: [
      'Business Loan',
      'Personal Loan',
      'Line of Credit',
      'Other Loan',
    ],
    TransactionType.loanRepayment: [
      'Loan Repayment',
      'Partial Payment',
      'Full Settlement',
    ],
    TransactionType.adjustment: [
      'Correction',
      'Write-off',
      'Revaluation',
      'Other Adjustment',
    ],
    TransactionType.profitDistribution: [
      'Quarterly Profit',
      'Annual Profit',
      'Interim Dividend',
    ],
    TransactionType.lossAllocation: [
      'Operating Loss',
      'Impairment Loss',
      'Other Loss',
    ],
  };

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _selectedType = tx?.type ?? TransactionType.income;
    _selectedDate = tx?.date ?? DateTime.now();
    _selectedPartnerId = tx?.partnerId;
    _selectedCategory = tx?.category;
    _attachmentPath = tx?.attachmentPath;

    _amountController = TextEditingController(
      text: tx != null ? tx.amount.toStringAsFixed(2) : '',
    );
    _descriptionController = TextEditingController(
      text: tx?.description ?? '',
    );

    _animationController = AnimationController(
      vsync: this,
      duration: AppConstants.animationDurationSlow,
    );
    _fadeIn = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _amountFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  List<String> get _availableCategories =>
      _categoriesByType[_selectedType] ?? [];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;
    if (_selectedPartnerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a partner'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_isEditMode) {
        final request = UpdateTransactionRequest(
          type: _selectedType,
          amount: amount,
          category: _selectedCategory,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          date: _selectedDate,
          attachmentPath: _attachmentPath,
        );
        await ref
            .read(transactionsProvider.notifier)
            .update(id: widget.transaction!.id, request: request);
      } else {
        final request = CreateTransactionRequest(
          partnerId: _selectedPartnerId!,
          type: _selectedType,
          amount: amount,
          category: _selectedCategory,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          date: _selectedDate,
          attachmentPath: _attachmentPath,
        );
        final businessId =
            ref.read(currentBusinessIdProvider) ?? '';
        await ref.read(transactionsProvider.notifier).add(
              request: request,
              businessId: businessId,
              userId: '',
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? 'Transaction updated' : 'Transaction created',
            ),
            backgroundColor: AppColors.lightSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.lightError,
            behavior: SnackBarBehavior.floating,
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
    final partners = ref.watch(filteredPartnersProvider);
    final businesses = ref.watch(businessesListProvider);
    final hasMultipleBusinesses = businesses.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Transaction' : 'New Transaction'),
        actions: [
          if (_isEditMode)
            IconButton(
              onPressed: () => _showDeleteConfirmation(context),
              icon: Icon(
                Icons.delete_outline_rounded,
                color: colorScheme.error,
              ),
              tooltip: 'Delete',
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                TransactionTypeSelector(
                  selectedType: _selectedType,
                  onTypeSelected: (type) {
                    setState(() {
                      _selectedType = type;
                      if (!_availableCategories
                          .contains(_selectedCategory)) {
                        _selectedCategory = null;
                      }
                    });
                  },
                ),
                const Gap(24),
                _buildAmountField(theme, colorScheme),
                const Gap(20),
                _buildDatePicker(theme, colorScheme),
                const Gap(20),
                _buildPartnerDropdown(theme, colorScheme, partners),
                if (hasMultipleBusinesses) ...[
                  const Gap(20),
                  _buildBusinessDropdown(theme, colorScheme, businesses),
                ],
                const Gap(20),
                _buildCategoryDropdown(theme, colorScheme),
                const Gap(20),
                _buildDescriptionField(theme, colorScheme),
                const Gap(20),
                AttachmentPicker(
                  currentPath: _attachmentPath,
                  onAttachmentChanged: (path) {
                    setState(() => _attachmentPath = path);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildSubmitBar(theme, colorScheme),
    );
  }

  Widget _buildAmountField(ThemeData theme, ColorScheme colorScheme) {
    return TextFormField(
      controller: _amountController,
      focusNode: _amountFocusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: 'Amount',
        prefixText: '₹ ',
        prefixStyle: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        hintText: '0.00',
      ),
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Amount is required';
        }
        final amount = double.tryParse(value.trim());
        if (amount == null) return 'Enter a valid amount';
        if (amount <= 0) return 'Amount must be greater than zero';
        if (amount > AppConstants.maxAmount) {
          return 'Amount exceeds maximum limit';
        }
        return null;
      },
      onFieldSubmitted: (_) => _descriptionFocusNode.requestFocus(),
    );
  }

  Widget _buildDatePicker(ThemeData theme, ColorScheme colorScheme) {
    final dateFormat = DateFormat(AppConstants.dateFormatFull);
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          suffixIcon: Icon(Icons.calendar_today_rounded),
        ),
        child: Text(
          dateFormat.format(_selectedDate),
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }

  Widget _buildPartnerDropdown(
    ThemeData theme,
    ColorScheme colorScheme,
    List partners,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedPartnerId,
      decoration: const InputDecoration(
        labelText: 'Partner *',
        prefixIcon: Icon(Icons.person_outline_rounded),
      ),
      items: partners.map<DropdownMenuItem<String>>((partner) {
        return DropdownMenuItem<String>(
          value: partner.id as String,
          child: Text(partner.name as String),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedPartnerId = value);
      },
      validator: (value) {
        if (value == null) return 'Please select a partner';
        return null;
      },
    );
  }

  Widget _buildBusinessDropdown(
    ThemeData theme,
    ColorScheme colorScheme,
    List businesses,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: ref.read(currentBusinessIdProvider),
      decoration: const InputDecoration(
        labelText: 'Business',
        prefixIcon: Icon(Icons.business_center_rounded),
      ),
      items: businesses.map<DropdownMenuItem<String>>((business) {
        return DropdownMenuItem<String>(
          value: business.id as String,
          child: Text(business.name as String),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          ref.read(businessesProvider.notifier).selectBusiness(
                businesses.firstWhere((b) => b.id == value),
              );
        }
      },
    );
  }

  Widget _buildCategoryDropdown(ThemeData theme, ColorScheme colorScheme) {
    return DropdownButtonFormField<String>(
      initialValue: _availableCategories.contains(_selectedCategory)
          ? _selectedCategory
          : null,
      decoration: const InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.label_outline_rounded),
      ),
      items: _availableCategories.map<DropdownMenuItem<String>>((cat) {
        return DropdownMenuItem<String>(
          value: cat,
          child: Text(cat),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedCategory = value);
      },
    );
  }

  Widget _buildDescriptionField(ThemeData theme, ColorScheme colorScheme) {
    return TextFormField(
      controller: _descriptionController,
      focusNode: _descriptionFocusNode,
      maxLines: 3,
      maxLength: AppConstants.maxDescriptionLength,
      textInputAction: TextInputAction.done,
      decoration: const InputDecoration(
        labelText: 'Description',
        hintText: 'Add notes or details...',
        alignLabelWithHint: true,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: 48),
          child: Icon(Icons.notes_rounded),
        ),
      ),
      validator: (value) {
        if (value != null && value.length > AppConstants.maxDescriptionLength) {
          return 'Description is too long';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isEditMode ? 'Update Transaction' : 'Create Transaction',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
        title: const Text('Delete Transaction?'),
        content: const Text(
          'This action cannot be undone. The transaction will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(transactionsProvider.notifier)
                  .delete(widget.transaction!.id);
              if (!mounted) return;
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction deleted'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.pop(context, true);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
