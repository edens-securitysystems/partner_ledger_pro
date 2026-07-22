import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../core/database/enums/database_enums.dart';
import '../../../core/models/entities/partner.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common/app_bar_widget.dart';
import '../../../widgets/common/confirmation_dialog.dart';
import '../../../widgets/common/summary_card.dart';
import '../providers/partner_provider.dart';
import '../widgets/partner_stats_widget.dart';

class PartnerDetailScreen extends ConsumerStatefulWidget {
  final String partnerId;

  const PartnerDetailScreen({super.key, required this.partnerId});

  @override
  ConsumerState<PartnerDetailScreen> createState() =>
      _PartnerDetailScreenState();
}

class _PartnerDetailScreenState extends ConsumerState<PartnerDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(partnersProvider.notifier).fetchAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final partner = _findPartner();

    if (partner == null) {
      return Scaffold(
        appBar: AppBarWidget(title: 'Partner Details'),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_off_rounded,
                  size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Partner not found',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              stretch: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () =>
                      context.push('/partners/${partner.id}/edit'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _showDeleteDialog(partner),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(theme, colorScheme, partner),
              ),
              bottom: TabBar(
                controller: _tabController,
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Ledger'),
                  Tab(text: 'Transactions'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(partner: partner),
            _LedgerTab(partner: partner),
            _TransactionsTab(partner: partner),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme, Partner partner) {
    final currencyFormat = NumberFormat('#,##0.00');

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 48),
            _buildAvatar(theme, colorScheme, partner),
            const SizedBox(height: 12),
            Text(
              partner.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            if (partner.email != null)
              Text(
                partner.email!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _headerStat(
                  theme,
                  '\u20B9${currencyFormat.format(partner.capital)}',
                  'Capital',
                ),
                Container(
                  width: 1,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _headerStat(
                  theme,
                  '${partner.ownershipPercentage.toStringAsFixed(1)}%',
                  'Ownership',
                ),
                Container(
                  width: 1,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _headerStat(
                  theme,
                  partner.statusDisplay,
                  'Status',
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _headerStat(ThemeData theme, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(ThemeData theme, ColorScheme colorScheme, Partner partner) {
    final initial =
        partner.name.isNotEmpty ? partner.name[0].toUpperCase() : '?';

    if (partner.photo != null && partner.photo!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: SizedBox(
          width: 80,
          height: 80,
          child: CachedNetworkImage(
            imageUrl: partner.photo!,
            fit: BoxFit.cover,
            placeholder: (_, __) => _avatarPlaceholder(theme, colorScheme, initial),
            errorWidget: (_, __, ___) =>
                _avatarPlaceholder(theme, colorScheme, initial),
          ),
        ),
      );
    }

    return _avatarPlaceholder(theme, colorScheme, initial);
  }

  Widget _avatarPlaceholder(ThemeData theme, ColorScheme colorScheme, String initial) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Center(
        child: Text(
          initial,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(Partner partner) {
    showDialog(
      context: context,
      builder: (_) => ConfirmationDialog.delete(
        title: 'Delete Partner',
        message:
            'Are you sure you want to delete ${partner.name}? This action cannot be undone.',
        confirmLabel: 'Delete',
        onConfirm: () {
          ref.read(partnersProvider.notifier).delete(partner.id);
          if (context.mounted) context.pop();
        },
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Partner partner;

  const _OverviewTab({required this.partner});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd MMM yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Partner Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _infoCard(theme, colorScheme, partner, dateFormat),
          const SizedBox(height: 20),
          PartnerStatsWidget(partner: partner),
          const SizedBox(height: 20),
          Text(
            'Recent Activity',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _recentActivityChart(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _infoCard(
    ThemeData theme,
    ColorScheme colorScheme,
    Partner partner,
    DateFormat dateFormat,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoRow(theme, colorScheme, Icons.person_outline_rounded, 'Name',
                partner.name),
            if (partner.email != null)
              _infoRow(theme, colorScheme, Icons.email_outlined, 'Email',
                  partner.email!),
            if (partner.phone != null)
              _infoRow(theme, colorScheme, Icons.phone_outlined, 'Phone',
                  partner.phone!),
            _infoRow(
              theme,
              colorScheme,
              Icons.calendar_today_rounded,
              'Joining Date',
              dateFormat.format(partner.joiningDate),
            ),
            _infoRow(
              theme,
              colorScheme,
              Icons.info_outline_rounded,
              'Status',
              partner.statusDisplay,
              valueColor: partner.status == PartnerStatus.active
                  ? AppColors.statusActive
                  : partner.status == PartnerStatus.suspended
                      ? AppColors.statusSuspended
                      : colorScheme.onSurface,
            ),
            if (partner.description != null && partner.description!.isNotEmpty)
              _infoRow(
                theme,
                colorScheme,
                Icons.notes_rounded,
                'Notes',
                partner.description!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    ThemeData theme,
    ColorScheme colorScheme,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
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
                color: valueColor ?? colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentActivityChart(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Summary',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    label: 'Capital',
                    amount: '\u20B9${NumberFormat('#,##0').format(partner.capital)}',
                    icon: Icons.account_balance_rounded,
                    iconColor: AppColors.investment,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SummaryCard(
                    label: 'Ownership',
                    amount: '${partner.ownershipPercentage.toStringAsFixed(1)}%',
                    icon: Icons.pie_chart_rounded,
                    iconColor: AppColors.transfer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerTab extends StatelessWidget {
  final Partner partner;

  const _LedgerTab({required this.partner});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat('#,##0.00');

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Card(
                  color: AppColors.profitLight,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          'Opening Balance',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.profitDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\u20B9${currencyFormat.format(partner.capital)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.profitDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  color: colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          'Closing Balance',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\u20B9${currencyFormat.format(partner.capital * 1.15)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              _ledgerEntryRow(
                theme,
                colorScheme,
                date: partner.joiningDate,
                description: 'Initial Capital Investment',
                amount: partner.capital,
                isCredit: true,
                balance: partner.capital,
                currencyFormat: currencyFormat,
              ),
              _ledgerEntryRow(
                theme,
                colorScheme,
                date: partner.joiningDate.add(const Duration(days: 30)),
                description: 'Monthly Profit Share',
                amount: partner.capital * 0.08,
                isCredit: true,
                balance: partner.capital * 1.08,
                currencyFormat: currencyFormat,
              ),
              _ledgerEntryRow(
                theme,
                colorScheme,
                date: partner.joiningDate.add(const Duration(days: 45)),
                description: 'Office Expense Contribution',
                amount: partner.capital * 0.03,
                isCredit: false,
                balance: partner.capital * 1.05,
                currencyFormat: currencyFormat,
              ),
              _ledgerEntryRow(
                theme,
                colorScheme,
                date: partner.joiningDate.add(const Duration(days: 60)),
                description: 'Quarterly Bonus',
                amount: partner.capital * 0.10,
                isCredit: true,
                balance: partner.capital * 1.15,
                currencyFormat: currencyFormat,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ledgerEntryRow(
    ThemeData theme,
    ColorScheme colorScheme, {
    required DateTime date,
    required String description,
    required double amount,
    required bool isCredit,
    required double balance,
    required NumberFormat currencyFormat,
  }) {
    final amountColor = isCredit ? AppColors.profit : AppColors.loss;
    final dateFormat = DateFormat('dd MMM');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
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
                  Text(
                    description,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        dateFormat.format(date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Balance: \u20B9${currencyFormat.format(balance)}',
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
            Text(
              '${isCredit ? '+' : '-'}\u20B9${currencyFormat.format(amount)}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionsTab extends StatelessWidget {
  final Partner partner;

  const _TransactionsTab({required this.partner});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Transaction History',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transactions for ${partner.name} will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
