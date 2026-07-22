import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/enums/database_enums.dart';
import '../../../core/models/entities/partner_approval.dart';
import '../../../core/models/entities/partner_update_request.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../widgets/common/app_bar_widget.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../widgets/forms/app_text_field.dart';
import '../providers/partner_approval_provider.dart';
import '../providers/partner_provider.dart';

class PendingApprovalsScreen extends ConsumerStatefulWidget {
  const PendingApprovalsScreen({super.key});

  @override
  ConsumerState<PendingApprovalsScreen> createState() =>
      _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState
    extends ConsumerState<PendingApprovalsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fetchAll() {
    final partnersState = ref.read(partnersProvider);

    // Fetch all pending requests
    for (final partner in partnersState.partners) {
      if (partner.isStatusActive && partner.isActive) {
        ref.read(partnerApprovalProvider.notifier).fetchPendingRequests(
              partner.businessId,
            );
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final approvalState = ref.watch(partnerApprovalProvider);

    return Scaffold(
      appBar: AppBarWidget(
        title: 'Pending Approvals',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchAll,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorColor: colorScheme.primary,
              tabs: const [
                Tab(text: 'My Requests'),
                Tab(text: 'Awaiting My Approval'),
              ],
            ),
          ),
          Expanded(
            child: approvalState.isLoading && approvalState.pendingRequests.isEmpty
                ? const LoadingWidget.shimmerList()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMyRequestsList(approvalState),
                      _buildAwaitingApprovalList(approvalState),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRequestsList(PartnerApprovalState state) {
    if (state.pendingRequests.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.how_to_vote_outlined,
        title: 'No Pending Requests',
        subtitle: 'You have no partner update requests awaiting approval.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _fetchAll(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: state.pendingRequests.length,
        itemBuilder: (context, index) {
          final request = state.pendingRequests[index];
          return _RequestCard(
            request: request,
            onTap: () => _showRequestDetail(request),
          );
        },
      ),
    );
  }

  Widget _buildAwaitingApprovalList(PartnerApprovalState state) {
    // Filter requests where current user needs to approve
    final user = ref.read(currentUserProvider);
    final myApprovals = state.pendingRequests.where((r) {
      return r.requestedByEmail != user?.email;
    }).toList();

    if (myApprovals.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.check_circle_outline_rounded,
        title: 'Nothing to Approve',
        subtitle: 'No partner updates are waiting for your approval.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _fetchAll(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: myApprovals.length,
        itemBuilder: (context, index) {
          final request = myApprovals[index];
          return _RequestCard(
            request: request,
            onTap: () => _showApprovalDetail(request),
            showApproveActions: true,
          );
        },
      ),
    );
  }

  void _showRequestDetail(PartnerUpdateRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RequestDetailSheet(
        request: request,
        showActions: false,
      ),
    );
  }

  void _showApprovalDetail(PartnerUpdateRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RequestDetailSheet(
        request: request,
        showActions: true,
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final PartnerUpdateRequest request;
  final VoidCallback onTap;
  final bool showApproveActions;

  const _RequestCard({
    required this.request,
    required this.onTap,
    this.showApproveActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit_document,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Partner Update Request',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'By ${request.requestedByName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: request.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Changes to: ${request.changedFields.join(', ')}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (request.reason != null && request.reason!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Reason: ${request.reason}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(request.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (request.totalApprovers > 0) ...[
                    Icon(
                      Icons.how_to_vote_outlined,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${request.approvedCount}/${request.totalApprovers}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: request.approvalProgress,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: request.isFullyApproved
                    ? Colors.green
                    : colorScheme.primary,
                minHeight: 3,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final UpdateRequestStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case UpdateRequestStatus.pending:
        bgColor = Colors.orange.withValues(alpha: 0.12);
        textColor = Colors.orange.shade700;
        icon = Icons.schedule_rounded;
      case UpdateRequestStatus.approved:
        bgColor = Colors.green.withValues(alpha: 0.12);
        textColor = Colors.green.shade700;
        icon = Icons.check_circle_rounded;
      case UpdateRequestStatus.rejected:
        bgColor = Colors.red.withValues(alpha: 0.12);
        textColor = Colors.red.shade700;
        icon = Icons.cancel_rounded;
      case UpdateRequestStatus.expired:
        bgColor = Colors.grey.withValues(alpha: 0.12);
        textColor = Colors.grey.shade600;
        icon = Icons.timer_off_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.display,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestDetailSheet extends ConsumerStatefulWidget {
  final PartnerUpdateRequest request;
  final bool showActions;

  const _RequestDetailSheet({
    required this.request,
    required this.showActions,
  });

  @override
  ConsumerState<_RequestDetailSheet> createState() =>
      _RequestDetailSheetState();
}

class _RequestDetailSheetState extends ConsumerState<_RequestDetailSheet> {
  final _commentController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(partnerApprovalProvider.notifier)
          .selectRequest(widget.request.id);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final approvalState = ref.watch(partnerApprovalProvider);
    final request = widget.request;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Update Request Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _StatusBadge(status: request.status),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _DetailSection(
                      title: 'Requested By',
                      child: Text(
                        '${request.requestedByName} (${request.requestedByEmail})',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    _DetailSection(
                      title: 'Date',
                      child: Text(
                        dateFormat.format(request.createdAt),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    if (request.reason != null && request.reason!.isNotEmpty)
                      _DetailSection(
                        title: 'Reason',
                        child: Text(
                          request.reason!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    _DetailSection(
                      title: 'Proposed Changes',
                      child: Column(
                        children: request.proposedChangesMap.entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 140,
                                  child: Text(
                                    _fieldLabel(e.key),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${e.value}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (request.currentValuesMap != null)
                      _DetailSection(
                        title: 'Current Values',
                        child: Column(
                          children: request.currentValuesMap!.entries.map((e) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 140,
                                    child: Text(
                                      _fieldLabel(e.key),
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${e.value}',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    _DetailSection(
                      title: 'Approval Progress',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${request.approvedCount} approved',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${request.rejectedCount} rejected',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${request.totalApprovers - request.approvedCount - request.rejectedCount} pending',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: request.approvalProgress,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            color: request.isFullyApproved
                                ? Colors.green
                                : colorScheme.primary,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      ),
                    ),
                    if (approvalState.currentApprovals.isNotEmpty)
                      _DetailSection(
                        title: 'Partner Decisions',
                        child: Column(
                          children:
                              approvalState.currentApprovals.map((approval) {
                            return _ApprovalTile(approval: approval);
                          }).toList(),
                        ),
                      ),
                    if (widget.showActions &&
                        request.status == UpdateRequestStatus.pending)
                      _buildActionSection(theme, colorScheme, approvalState),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionSection(
    ThemeData theme,
    ColorScheme colorScheme,
    PartnerApprovalState approvalState,
  ) {
    // Find my approval record
    final user = ref.read(currentUserProvider);
    final myApproval = approvalState.currentApprovals.firstWhere(
      (a) => a.partnerEmail == user?.email && a.isPending,
      orElse: () => PartnerApproval(
        id: '',
        updateRequestId: '',
        partnerId: '',
        partnerName: '',
        partnerEmail: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (myApproval.id.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Text(
          'Your Decision',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Comment (optional)',
          hint: 'Add a reason for your decision...',
          controller: _commentController,
          maxLines: 2,
          minLines: 1,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : () => _reject(myApproval),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.close_rounded),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _isProcessing ? null : () => _approve(myApproval),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: const Text('Approve'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _approve(PartnerApproval myApproval) async {
    setState(() => _isProcessing = true);
    final success = await ref
        .read(partnerApprovalProvider.notifier)
        .approveRequest(
          updateRequestId: widget.request.id,
          approvalId: myApproval.id,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
        );
    setState(() => _isProcessing = false);
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request approved'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _reject(PartnerApproval myApproval) async {
    setState(() => _isProcessing = true);
    final success = await ref
        .read(partnerApprovalProvider.notifier)
        .rejectRequest(
          updateRequestId: widget.request.id,
          approvalId: myApproval.id,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
        );
    setState(() => _isProcessing = false);
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request rejected'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String _fieldLabel(String field) {
    switch (field) {
      case 'name':
        return 'Name';
      case 'email':
        return 'Email';
      case 'phone':
        return 'Phone';
      case 'capital':
        return 'Capital';
      case 'ownershipPercentage':
        return 'Ownership %';
      case 'status':
        return 'Status';
      case 'description':
        return 'Description';
      case 'joiningDate':
        return 'Joining Date';
      default:
        return field;
    }
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _ApprovalTile extends StatelessWidget {
  final PartnerApproval approval;

  const _ApprovalTile({required this.approval});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    IconData icon;
    Color color;
    switch (approval.decision) {
      case ApprovalDecision.approved:
        icon = Icons.check_circle_rounded;
        color = Colors.green;
      case ApprovalDecision.rejected:
        icon = Icons.cancel_rounded;
        color = Colors.red;
      case ApprovalDecision.pending:
        icon = Icons.schedule_rounded;
        color = Colors.orange;
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(
        approval.partnerName,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: approval.comment != null && approval.comment!.isNotEmpty
          ? Text(
              approval.comment!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: Text(
        approval.decision.display,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
