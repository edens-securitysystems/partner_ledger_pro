import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/enums/database_enums.dart';
import '../../../core/models/entities/transaction.dart';
import '../../../theme/app_colors.dart';
import '../../partners/providers/partner_provider.dart';
import '../providers/transaction_provider.dart';
import 'add_edit_transaction_screen.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppConstants.animationDurationSlow,
    );
    _fadeIn = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Transaction? _findTransaction(List<Transaction> transactions) {
    for (final t in transactions) {
      if (t.id == widget.transactionId) return t;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final txState = ref.watch(transactionsProvider);
    final partners = ref.watch(filteredPartnersProvider);
    final tx = _findTransaction(txState.transactions);

    if (tx == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transaction')),
        body: const Center(
          child: Text('Transaction not found'),
        ),
      );
    }

    final partnerName = partners
        .where((p) => p.id == tx.partnerId)
        .map((p) => p.name)
        .firstOrNull;

    final dateFormat = DateFormat(AppConstants.dateFormatFull);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final amountColor = tx.isCredit ? AppColors.profit : AppColors.debit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AddEditTransactionScreen(transaction: tx),
                ),
              );
              if (!mounted) return;
              if (result == true && context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: () => _showDeleteConfirmation(context, tx),
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildAmountHeader(theme, colorScheme, tx, amountColor,
                  currencyFormat, partnerName),
              const Gap(20),
              _buildDetailsCard(theme, colorScheme, tx, dateFormat,
                  partnerName),
              if (tx.hasAttachment) ...[
                const Gap(16),
                _buildAttachmentCard(theme, colorScheme, tx),
              ],
              const Gap(16),
              _buildMetadataCard(theme, colorScheme, tx, dateFormat),
              const Gap(16),
              if (partnerName != null)
                _buildPartnerCard(
                    theme, colorScheme, tx, partnerName),
              const Gap(24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    Transaction tx,
    Color amountColor,
    NumberFormat currencyFormat,
    String? partnerName,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _typeGradientStart(tx.type),
            _typeGradientEnd(tx.type),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _typeGradientEnd(tx.type).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTypeBadgeOnDark(theme, tx.type),
          const Gap(16),
          Text(
            currencyFormat.format(tx.amount),
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const Gap(4),
          Text(
            tx.typeDisplay,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          if (partnerName != null) ...[
            const Gap(8),
            Text(
              partnerName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeBadgeOnDark(ThemeData theme, TransactionType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForType(type), size: 18, color: Colors.white),
          const Gap(6),
          Text(
            type.name[0].toUpperCase() + type.name.substring(1),
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(
    ThemeData theme,
    ColorScheme colorScheme,
    Transaction tx,
    DateFormat dateFormat,
    String? partnerName,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(12),
            _DetailRow(
              label: 'Date',
              value: dateFormat.format(tx.date),
              icon: Icons.calendar_today_rounded,
            ),
            if (tx.time != null)
              _DetailRow(
                label: 'Time',
                value: tx.time!,
                icon: Icons.access_time_rounded,
              ),
            _DetailRow(
              label: 'Type',
              value: tx.typeDisplay,
              icon: _iconForType(tx.type),
            ),
            if (tx.category != null)
              _DetailRow(
                label: 'Category',
                value: tx.category!,
                icon: Icons.label_outline_rounded,
              ),
            if (tx.description != null && tx.description!.isNotEmpty)
              _DetailRow(
                label: 'Description',
                value: tx.description!,
                icon: Icons.notes_rounded,
                isMultiLine: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentCard(
    ThemeData theme,
    ColorScheme colorScheme,
    Transaction tx,
  ) {
    final path = tx.attachmentPath!;
    final isImage = _isImageFile(path);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attachment',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(12),
            if (isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Container(
                    height: 200,
                    color: colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Icon(
                        Icons.image_rounded,
                        size: 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      _documentIcon(path),
                      size: 32,
                      color: colorScheme.primary,
                    ),
                    const Gap(12),
                    Expanded(
                      child: Text(
                        path.split('/').last,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildMetadataCard(
    ThemeData theme,
    ColorScheme colorScheme,
    Transaction tx,
    DateFormat dateFormat,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Information',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(12),
            _DetailRow(
              label: 'Created',
              value: dateFormat.format(tx.createdAt),
              icon: Icons.add_circle_outline_rounded,
            ),
            _DetailRow(
              label: 'Created by',
              value: tx.createdBy,
              icon: Icons.person_outline_rounded,
            ),
            if (tx.updatedBy != null)
              _DetailRow(
                label: 'Last updated by',
                value: tx.updatedBy!,
                icon: Icons.person_outline_rounded,
              ),
            _DetailRow(
              label: 'Last updated',
              value: dateFormat.format(tx.updatedAt),
              icon: Icons.update_rounded,
            ),
            _DetailRow(
              label: 'Sync status',
              value: tx.syncStatus.name[0].toUpperCase() +
                  tx.syncStatus.name.substring(1),
              icon: _syncIcon(tx.syncStatus),
              valueColor: _syncColor(tx.syncStatus),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard(
    ThemeData theme,
    ColorScheme colorScheme,
    Transaction tx,
    String partnerName,
  ) {
    return Card(
      child: InkWell(
        onTap: () {
          // Navigate to partner detail - handled by router in production
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: colorScheme.primary,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partnerName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'View partner details',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
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

  void _showDeleteConfirmation(BuildContext context, Transaction tx) {
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
                  .delete(tx.id);
              if (!mounted) return;
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction deleted'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.pop(context);
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

  static Color _typeGradientStart(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return const Color(0xFF1E5D3F);
      case TransactionType.expense:
        return const Color(0xFF8B3A1A);
      case TransactionType.investment:
        return const Color(0xFF1A4D7A);
      case TransactionType.withdrawal:
        return const Color(0xFF7A3318);
      case TransactionType.transfer:
        return const Color(0xFF3D2B70);
      case TransactionType.loan:
      case TransactionType.loanRepayment:
        return const Color(0xFF1F5E5F);
      case TransactionType.adjustment:
        return const Color(0xFF4A5C6E);
      case TransactionType.profitDistribution:
        return const Color(0xFF1E5D3F);
      case TransactionType.lossAllocation:
        return const Color(0xFF7A1F1F);
    }
  }

  static Color _typeGradientEnd(TransactionType type) {
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

  static bool _isImageFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  static IconData _documentIcon(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'csv':
      case 'xlsx':
      case 'xls':
        return Icons.table_chart_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  static IconData _syncIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return Icons.cloud_done_rounded;
      case SyncStatus.pendingCreate:
      case SyncStatus.pendingUpdate:
      case SyncStatus.pendingDelete:
        return Icons.cloud_queue_rounded;
      case SyncStatus.conflict:
        return Icons.warning_amber_rounded;
    }
  }

  static Color _syncColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return AppColors.statusActive;
      case SyncStatus.pendingCreate:
      case SyncStatus.pendingUpdate:
      case SyncStatus.pendingDelete:
        return AppColors.statusPending;
      case SyncStatus.conflict:
        return AppColors.statusSuspended;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isMultiLine;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isMultiLine = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment:
            isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const Gap(10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
              maxLines: isMultiLine ? 4 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
