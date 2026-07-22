import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/enums.dart';
import '../../../core/models/entities/business.dart';
import '../../../widgets/common/app_bar_widget.dart';
import '../../../widgets/forms/app_dropdown.dart';
import '../../../widgets/forms/app_text_field.dart';
import '../providers/business_provider.dart';

class AddEditBusinessScreen extends ConsumerStatefulWidget {
  final String? businessId;

  const AddEditBusinessScreen({super.key, this.businessId});

  @override
  ConsumerState<AddEditBusinessScreen> createState() =>
      _AddEditBusinessScreenState();
}

class _AddEditBusinessScreenState extends ConsumerState<AddEditBusinessScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxIdController = TextEditingController();

  String? _logoPath;
  Currency _currency = Currency.inr;
  bool _isSubmitting = false;
  bool _isInitialized = false;
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  Business? _existingBusiness;
  bool get _isEditing => widget.businessId != null;

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
      if (_isEditing) {
        ref.read(businessesProvider.notifier).fetchAll();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isEditing && !_isInitialized) {
      _initializeExistingBusiness();
    }
  }

  void _initializeExistingBusiness() {
    final state = ref.read(businessesProvider);
    try {
      final business =
          state.businesses.firstWhere((b) => b.id == widget.businessId);
      _existingBusiness = business;
      _nameController.text = business.name;
      _descriptionController.text = business.description ?? '';
      _emailController.text = business.email ?? '';
      _phoneController.text = business.phone ?? '';
      _websiteController.text = business.website ?? '';
      _addressController.text = business.address ?? '';
      _taxIdController.text = business.taxId ?? '';
      _logoPath = business.logo;
      _currency = Currency.values.firstWhere(
        (c) => c.code.toLowerCase() == business.currency.toLowerCase(),
        orElse: () => Currency.inr,
      );
      _isInitialized = true;
    } catch (_) {
      if (mounted) context.pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _taxIdController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
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
                  'Select Logo',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('Remove Logo'),
                  onTap: () => Navigator.pop(ctx, null),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == ImageSource.camera || source == ImageSource.gallery) {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source!,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _logoPath = picked.path);
      }
    } else if (source == null) {
      setState(() => _logoPath = null);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      if (_isEditing && _existingBusiness != null) {
        await ref.read(businessesProvider.notifier).update(
              id: _existingBusiness!.id,
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              currency: _currency.code,
            );
      } else {
        await ref.read(businessesProvider.notifier).add(
              name: _nameController.text.trim(),
              ownerEmail: 'owner@example.com',
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              currency: _currency.code,
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Business updated successfully'
                  : 'Business created successfully',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        context.pop();
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

    return Scaffold(
      appBar: AppBarWidget(
        title: _isEditing ? 'Edit Business' : 'Add Business',
        actions: [
          if (_isEditing && _existingBusiness != null)
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
              _buildLogoSection(theme, colorScheme),
              const SizedBox(height: 24),
              _buildSectionHeader(
                theme,
                colorScheme,
                'Business Information',
                Icons.business_rounded,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Business Name',
                hint: 'Enter business name',
                controller: _nameController,
                prefixIcon: Icons.business_rounded,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Business name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Description',
                hint: 'Brief description of the business',
                controller: _descriptionController,
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(
                theme,
                colorScheme,
                'Contact Information',
                Icons.contact_page_rounded,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Email',
                hint: 'business@example.com',
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
                hint: '+91 98765 43210',
                controller: _phoneController,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final digitsOnly =
                        value.replaceAll(RegExp(r'[^0-9]'), '');
                    if (digitsOnly.length < 10) {
                      return 'Enter a valid phone number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Website',
                hint: 'https://example.com',
                controller: _websiteController,
                prefixIcon: Icons.language_rounded,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(
                theme,
                colorScheme,
                'Additional Details',
                Icons.info_outline_rounded,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Address',
                hint: 'Street, city, state, pincode',
                controller: _addressController,
                prefixIcon: Icons.location_on_outlined,
                maxLines: 2,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              _buildCurrencySelector(colorScheme),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Tax ID',
                hint: 'GSTIN / VAT / Tax ID',
                controller: _taxIdController,
                prefixIcon: Icons.receipt_rounded,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 32),
              _buildSubmitButton(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: GestureDetector(
        onTap: kIsWeb ? null : _pickLogo,
        child: Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 3,
                ),
              ),
              child: _logoPlaceholder(theme, colorScheme),
            ),
            if (!kIsWeb)
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

  Widget _logoPlaceholder(ThemeData theme, ColorScheme colorScheme) {
    final name = _nameController.text;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'B';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.business_rounded, size: 28, color: colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            initial,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    String title,
    IconData icon,
  ) {
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

  Widget _buildCurrencySelector(ColorScheme colorScheme) {
    return AppDropdown<Currency>(
      label: 'Currency',
      prefixIcon: Icons.currency_exchange_rounded,
      value: _currency,
      items: Currency.values.map((c) {
        return AppDropdownItem<Currency>(
          value: c,
          label: '${c.symbol}  ${c.code} - ${c.displayName}',
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                c.symbol,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) setState(() => _currency = value);
      },
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
                _isEditing ? 'Update Business' : 'Create Business',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Business'),
        content: Text(
          'Are you sure you want to delete ${_existingBusiness?.name ?? "this business"}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_existingBusiness != null) {
                await ref
                    .read(businessesProvider.notifier)
                    .delete(_existingBusiness!.id);
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
