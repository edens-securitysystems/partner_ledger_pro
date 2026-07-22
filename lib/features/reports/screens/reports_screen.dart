import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/dto/report_dto.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common/app_bar_widget.dart';
import '../providers/report_provider.dart';
import '../widgets/report_card.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _endDate = DateTime.now();
  String? _selectedBusinessId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportProvider);

    return Scaffold(
      appBar: AppBarWidget(
        title: 'Reports',
        showBack: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: _handleExport,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Export as PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Export as Excel'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Print Report'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: state.isExporting
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating report...'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {},
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterSection(context),
                    _buildReportGrid(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _DateFilterChip(
                  label: 'From',
                  date: dateFormat.format(_startDate),
                  icon: Icons.calendar_today_rounded,
                  onTap: () => _selectDate(context, isStart: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DateFilterChip(
                  label: 'To',
                  date: dateFormat.format(_endDate),
                  icon: Icons.calendar_today_rounded,
                  onTap: () => _selectDate(context, isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showBusinessFilter(context),
              icon: const Icon(Icons.business_rounded, size: 18),
              label: Text(
                _selectedBusinessId != null
                    ? 'Business: ${_selectedBusinessId!.substring(0, 8)}...'
                    : 'All Businesses',
                style: theme.textTheme.labelLarge,
              ),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportGrid(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width > 800 ? 3 : width > 500 ? 2 : 2;

    final reports = [
      _ReportItem(
        icon: Icons.calendar_month_rounded,
        title: 'Monthly Report',
        description: 'Detailed month-by-month financial overview',
        color: AppColors.chartPalette[0],
        route: '/reports/monthly',
      ),
      _ReportItem(
        icon: Icons.date_range_rounded,
        title: 'Yearly Report',
        description: 'Annual financial summary with comparisons',
        color: AppColors.chartPalette[1],
        route: '/reports/yearly',
      ),
      _ReportItem(
        icon: Icons.people_rounded,
        title: 'Partner-wise Report',
        description: 'Individual partner financial breakdown',
        color: AppColors.chartPalette[4],
        route: '/reports/partner',
      ),
      _ReportItem(
        icon: Icons.business_rounded,
        title: 'Business-wise Report',
        description: 'Segment-wise business performance',
        color: AppColors.chartPalette[5],
        route: '/reports/business',
      ),
      _ReportItem(
        icon: Icons.waterfall_chart_rounded,
        title: 'Cash Flow',
        description: 'Track money inflow and outflow',
        color: AppColors.chartPalette[2],
        route: '/reports/cash-flow',
      ),
      _ReportItem(
        icon: Icons.insights_rounded,
        title: 'Profit & Loss',
        description: 'Comprehensive P&L statement',
        color: AppColors.chartPalette[3],
        route: '/reports/profit-loss',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final item = reports[index];
          return ReportCard(
            icon: item.icon,
            title: item.title,
            description: item.description,
            color: item.color,
            onTap: () => context.push(item.route),
          );
        },
      ),
    );
  }

  Future<void> _selectDate(
      BuildContext context, {required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _showBusinessFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Business',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.all_inclusive_rounded),
                title: const Text('All Businesses'),
                onTap: () {
                  setState(() => _selectedBusinessId = null);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.business_rounded),
                title: const Text('Main Business'),
                onTap: () {
                  setState(() => _selectedBusinessId = 'main_business_001');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _handleExport(String type) {
    final request = ReportRequest(
      startDate: _startDate,
      endDate: _endDate,
      partnerId: _selectedBusinessId,
    );
    switch (type) {
      case 'pdf':
        ref.read(reportProvider.notifier).exportPDF(request: request);
      case 'excel':
        ref.read(reportProvider.notifier).exportExcel(request: request);
      case 'print':
        break;
    }
  }
}

class _ReportItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String route;

  const _ReportItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.route,
  });
}

class _DateFilterChip extends StatelessWidget {
  final String label;
  final String date;
  final IconData icon;
  final VoidCallback onTap;

  const _DateFilterChip({
    required this.label,
    required this.date,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      date,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
