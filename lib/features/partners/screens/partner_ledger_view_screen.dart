import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/entities/ledger_entry.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../theme/app_colors.dart';

class PartnerLedgerViewScreen extends ConsumerStatefulWidget {
  const PartnerLedgerViewScreen({super.key});

  @override
  ConsumerState<PartnerLedgerViewScreen> createState() => _PartnerLedgerViewScreenState();
}

class _PartnerLedgerViewScreenState extends ConsumerState<PartnerLedgerViewScreen> {
  List<LedgerEntry> _entries = [];
  double _totalCredits = 0;
  double _totalDebits = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLedger();
  }

  Future<void> _loadLedger() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final partnerRepo = ref.read(partnerRepositoryProvider);
      final partnerResponse = await partnerRepo.getByUserId(user.id);

      if (partnerResponse.success && partnerResponse.data != null) {
        final partner = partnerResponse.data!;
        final ledgerRepo = ref.read(ledgerRepositoryProvider);
        final ledgerResponse = await ledgerRepo.getPartnerLedger(partner.id);

        if (mounted) {
          setState(() {
            if (ledgerResponse.success && ledgerResponse.data != null) {
              _entries = ledgerResponse.data!;
              _totalCredits = _entries
                  .where((e) => e.isCredit)
                  .fold(0.0, (sum, e) => sum + e.amount);
              _totalDebits = _entries
                  .where((e) => !e.isCredit)
                  .fold(0.0, (sum, e) => sum + e.amount);
            }
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Ledger'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLedger,
              child: Column(
                children: [
                  _buildSummaryHeader(theme, colorScheme),
                  Expanded(
                    child: _entries.isEmpty
                        ? _buildEmpty(theme, colorScheme)
                        : _buildEntryList(theme, colorScheme),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          _summaryItem(theme, 'Credits', _totalCredits, AppColors.profit),
          const SizedBox(width: 16),
          _summaryItem(theme, 'Debits', _totalDebits, AppColors.loss),
          const SizedBox(width: 16),
          _summaryItem(
            theme,
            'Entries',
            _entries.length.toDouble(),
            colorScheme.primary,
            isCount: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(ThemeData theme, String label, double value, Color color, {bool isCount = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              isCount ? '${value.toInt()}' : '₹${value.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: isCount ? 18 : 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryList(ThemeData theme, ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return _buildEntryCard(theme, colorScheme, entry);
      },
    );
  }

  Widget _buildEntryCard(ThemeData theme, ColorScheme colorScheme, LedgerEntry entry) {
    final isCredit = entry.isCredit;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (isCredit ? AppColors.profit : AppColors.loss).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: isCredit ? AppColors.profit : AppColors.loss,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.description ?? (isCredit ? 'Credit' : 'Debit'),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(entry.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : '-'}₹${entry.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isCredit ? AppColors.profit : AppColors.loss,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bal: ₹${entry.balance.toStringAsFixed(2)}',
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

  Widget _buildEmpty(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_rounded, size: 56, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('No ledger entries yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Your transaction history will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
