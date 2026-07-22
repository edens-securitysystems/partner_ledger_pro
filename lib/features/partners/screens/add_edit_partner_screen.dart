import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/database/enums/database_enums.dart';
import '../../../core/models/dto/partner_dto.dart';
import '../../../core/models/entities/partner.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../widgets/common/app_bar_widget.dart';
import '../../../widgets/forms/app_amount_field.dart';
import '../../../widgets/forms/app_dropdown.dart';
import '../../../widgets/forms/app_text_field.dart';
import '../providers/partner_provider.dart';
import '../providers/partner_approval_provider.dart';

class AddEditPartnerScreen extends ConsumerStatefulWidget {
  final String? partnerId;

  const AddEditPartnerScreen({super.key, this.partnerId});

  @override
  ConsumerState<AddEditPartnerScreen> createState() =>
      _AddEditPartnerScreenState();
}

class _AddEditPartnerScreenState extends ConsumerState<AddEditPartnerScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();

  double? _capitalAmount;
  double _ownershipPercentage = 10.0;
  DateTime _joiningDate = DateTime.now();
  PartnerStatus _status = PartnerStatus.active;
  String? _photoPath;

  bool _isSubmitting = false;
  bool _isInitialized = false;
  bool _autoCalculateOwnership = true;
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  Partner? _existingPartner;
  bool get _isEditing => widget.partnerId != null;

  List<Partner> _allPartners = [];

  double get _totalInvestment {
    double total = 0;
    for (final p in _allPartners) {
      total += p.capital;
    }
    return total;
  }

  double get _calculatedOwnership {
    if (_capitalAmount == null || _capitalAmount! <= 0 || _totalInvestment <= 0) {
      return 0.0;
    }
    final effectiveTotal = _totalInvestment;
    return (_capitalAmount! / effectiveTotal) * 100;
  }

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(partnersProvider.notifier).fetchAll();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _fetchAllPartners();
      if (_isEditing) {
        _initializeExistingPartner();
      }
    }
  }

  void _fetchAllPartners() {
    final state = ref.read(partnersProvider);
    _allPartners = state.partners;
    if (_allPartners.isEmpty) {
      ref.read(partnersProvider.notifier).fetchAll().then((_) {
        if (mounted) {
          final updated = ref.read(partnersProvider);
          setState(() => _allPartners = updated.partners);
          if (_capitalAmount != null && _autoCalculateOwnership) {
            setState(() => _ownershipPercentage = _calculatedOwnership);
          }
        }
      });
    }
  }

  void _initializeExistingPartner() {
    final state = ref.read(partnersProvider);
    try {
      final partner =
          state.partners.firstWhere((p) => p.id == widget.partnerId);
      _existingPartner = partner;
      _nameController.text = partner.name;
      _emailController.text = partner.email ?? '';
      _phoneController.text = partner.phone ?? '';
      _descriptionController.text = partner.description ?? '';
      _capitalAmount = partner.capital;
      _ownershipPercentage = partner.ownershipPercentage;
      _joiningDate = partner.joiningDate;
      _status = partner.status;
      _photoPath = partner.photo;
      _isInitialized = true;
    } catch (_) {
      if (mounted) context.pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
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
                  'Select Photo',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source != null) {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _photoPath = picked.path);
      }
    }
  }

  Future<void> _pickJoiningDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joiningDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select Joining Date',
    );
    if (picked != null) {
      setState(() => _joiningDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      if (_isEditing && _existingPartner != null) {
        // Detect changes for approval workflow
        final changes = <String, dynamic>{};
        final current = _existingPartner!;

        final newName = _nameController.text.trim();
        if (newName != current.name) changes['name'] = newName;

        final newEmail = _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim();
        if (newEmail != current.email) changes['email'] = newEmail;

        final newPhone = _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim();
        if (newPhone != current.phone) changes['phone'] = newPhone;

        final newCapital = _capitalAmount ?? 0.0;
        if (newCapital != current.capital) changes['capital'] = newCapital;

        if (_ownershipPercentage != current.ownershipPercentage) {
          changes['ownershipPercentage'] = _ownershipPercentage;
        }

        if (_joiningDate != current.joiningDate) {
          changes['joiningDate'] = _joiningDate.toIso8601String();
        }

        if (_status != current.status) {
          changes['status'] = _status.value;
        }

        final newDescription = _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim();
        if (newDescription != current.description) {
          changes['description'] = newDescription;
        }

        if (changes.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No changes detected'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        final authState = ref.read(authProvider);
        final user = authState.user;

        final success = await ref
            .read(partnerApprovalProvider.notifier)
            .submitUpdateRequest(
              businessId: current.businessId,
              partnerId: current.id,
              currentPartner: current,
              proposedChanges: changes,
              currentUserId: user?.id ?? '',
              currentUserEmail: user?.email ?? '',
              currentUserName: user?.name ?? 'Unknown',
            );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Update request submitted for partner approval',
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          context.pop();
        } else if (mounted) {
          final error = ref.read(partnerApprovalProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to submit update request'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } else {
        // Adding new partner — direct save (no approval needed)
        final request = CreatePartnerRequest(
          name: _nameController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          photo: _photoPath,
          capital: _capitalAmount ?? 0.0,
          ownershipPercentage: _ownershipPercentage,
          joiningDate: _joiningDate,
          status: _status,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
        await ref
            .read(partnersProvider.notifier)
            .add(request: request, businessId: 'current_business');
        if (mounted) context.pop();
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

    return Scaffold(
      appBar: AppBarWidget(
        title: _isEditing ? 'Edit Partner' : 'Add Partner',
        actions: [
          if (_isEditing && _existingPartner != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _showDeleteConfirmation,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SlideTransition(
          position: _slideAnimation,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _buildPhotoSection(theme, colorScheme),
              const SizedBox(height: 24),
              _buildSectionHeader(theme, colorScheme, 'Basic Information',
                  Icons.person_outline_rounded),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Full Name',
                hint: 'Enter partner name',
                controller: _nameController,
                prefixIcon: Icons.person_rounded,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Email',
                hint: 'partner@example.com',
                controller: _emailController,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final emailRegex = RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                    );
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Enter a valid email address';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Phone',
                hint: '98765 43210',
                controller: _phoneController,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (value.trim().length != 10) {
                      return 'Enter exactly 10 digits';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(theme, colorScheme, 'Investment Details',
                  Icons.account_balance_rounded),
              const SizedBox(height: 12),
              _buildTotalInvestmentCard(theme, colorScheme),
              const SizedBox(height: 12),
              AppAmountField(
                label: 'Investment Amount',
                hint: 'Enter investment amount',
                initialValue: _capitalAmount,
                prefixIcon: Icons.currency_rupee_rounded,
                onChanged: (value) {
                  setState(() => _capitalAmount = value);
                  if (_autoCalculateOwnership) {
                    setState(() => _ownershipPercentage = _calculatedOwnership);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Investment amount is required';
                  }
                  final amount = double.tryParse(value.replaceAll(',', ''));
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildOwnershipSlider(theme, colorScheme),
              if (_autoCalculateOwnership && _capitalAmount != null && _capitalAmount! > 0) ...[
                const SizedBox(height: 8),
                _buildCalculatedOwnershipCard(theme, colorScheme),
              ],
              const SizedBox(height: 24),
              _buildSectionHeader(theme, colorScheme, 'Other Details',
                  Icons.info_outline_rounded),
              const SizedBox(height: 12),
              _buildJoiningDatePicker(theme, colorScheme, dateFormat),
              const SizedBox(height: 16),
              AppDropdown<PartnerStatus>(
                label: 'Status',
                value: _status,
                prefixIcon: Icons.flag_outlined,
                items: PartnerStatus.values
                    .where((s) => s != PartnerStatus.withdrawn)
                    .map((status) {
                  return AppDropdownItem<PartnerStatus>(
                    value: status,
                    label: _statusLabel(status),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Notes',
                hint: 'Optional description or notes...',
                controller: _descriptionController,
                prefixIcon: Icons.notes_rounded,
                maxLines: 3,
                minLines: 2,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),
              _buildSubmitButton(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 3,
                ),
              ),
              child: _photoPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.asset(
                        _photoPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatarPlaceholder(
                            theme, colorScheme),
                      ),
                    )
                  : _avatarPlaceholder(theme, colorScheme),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 16,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarPlaceholder(ThemeData theme, ColorScheme colorScheme) {
    final name = _nameController.text;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Center(
      child: Text(
        initial,
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      ThemeData theme, ColorScheme colorScheme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildOwnershipSlider(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ownership Percentage',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _autoCalculateOwnership,
                  onChanged: (value) {
                    setState(() {
                      _autoCalculateOwnership = value;
                      if (value && _capitalAmount != null) {
                        _ownershipPercentage = _calculatedOwnership;
                      }
                    });
                  },
                  activeThumbColor: colorScheme.primary,
                ),
              ],
            ),
            if (_autoCalculateOwnership) ...[
              const SizedBox(height: 4),
              Text(
                'Auto-calculated from investment amount',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: colorScheme.primary,
                inactiveTrackColor: colorScheme.surfaceContainerHighest,
                thumbColor: colorScheme.primary,
                overlayColor: colorScheme.primary.withValues(alpha: 0.12),
                trackHeight: 4,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: _ownershipPercentage,
                min: 0,
                max: 100,
                divisions: 200,
                onChanged: _autoCalculateOwnership
                    ? null
                    : (value) {
                        setState(() => _ownershipPercentage = value);
                      },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '100%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalInvestmentCard(ThemeData theme, ColorScheme colorScheme) {
    final totalInvestment = _totalInvestment;
    return Card(
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded,
                size: 20, color: colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              'Total Investment:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              _formatCurrency(totalInvestment),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatedOwnershipCard(
      ThemeData theme, ColorScheme colorScheme) {
    final percentage = _calculatedOwnership;
    final partnerInvestment = _capitalAmount ?? 0;
    return Card(
      color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.calculate_rounded,
                    size: 18, color: colorScheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  'Auto-calculated Profit %',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(2)}%',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.tertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${_formatCurrency(partnerInvestment)} / ${_formatCurrency(_totalInvestment)} = ${percentage.toStringAsFixed(2)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} L';
    } else {
      return '₹${amount.toStringAsFixed(0)}';
    }
  }

  Widget _buildJoiningDatePicker(
      ThemeData theme, ColorScheme colorScheme, DateFormat dateFormat) {
    return InkWell(
      onTap: _pickJoiningDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Joining Date',
          prefixIcon:
              const Icon(Icons.calendar_today_rounded, size: 20),
          suffixIcon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        child: Text(
          dateFormat.format(_joiningDate),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: _isSubmitting ? null : _submit,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                _isEditing ? 'Submit for Approval' : 'Add Partner',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  String _statusLabel(PartnerStatus status) {
    switch (status) {
      case PartnerStatus.active:
        return 'Active';
      case PartnerStatus.inactive:
        return 'Inactive';
      case PartnerStatus.pending:
        return 'Pending';
      case PartnerStatus.suspended:
        return 'Suspended';
      case PartnerStatus.withdrawn:
        return 'Withdrawn';
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Partner'),
        content: Text(
          'Are you sure you want to delete ${_existingPartner?.name ?? "this partner"}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_existingPartner != null) {
                await ref
                    .read(partnersProvider.notifier)
                    .delete(_existingPartner!.id);
                if (mounted) context.pop();
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
