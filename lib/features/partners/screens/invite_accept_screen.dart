import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/enums/database_enums.dart';
import '../../../core/models/entities/partner_invite.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/partners/providers/invite_provider.dart';
import '../../../theme/app_colors.dart';

class InviteAcceptScreen extends ConsumerStatefulWidget {
  final String token;
  final String businessId;

  const InviteAcceptScreen({
    super.key,
    required this.token,
    required this.businessId,
  });

  @override
  ConsumerState<InviteAcceptScreen> createState() => _InviteAcceptScreenState();
}

class _InviteAcceptScreenState extends ConsumerState<InviteAcceptScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inviteProvider.notifier).validateToken(widget.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inviteState = ref.watch(inviteProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accept Invitation'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: inviteState.status == InviteProcessStatus.loading ||
                inviteState.status == InviteProcessStatus.accepting
            ? const Center(child: CircularProgressIndicator())
            : inviteState.status == InviteProcessStatus.error
                ? _buildError(theme, inviteState.error ?? 'Invalid or expired invite')
                : inviteState.acceptSuccess
                    ? _buildSuccess(theme, colorScheme)
                    : inviteState.currentInvite != null
                        ? _buildInviteDetails(theme, colorScheme, inviteState.currentInvite!, user)
                        : _buildEmpty(theme),
      ),
    );
  }

  Widget _buildInviteDetails(ThemeData theme, ColorScheme colorScheme, PartnerInvite invite, dynamic user) {
    final isExpired = invite.isExpired;
    final canAccept = invite.canBeAccepted && user != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.business_rounded,
                    size: 40,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'You\'re Invited!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'to join as a partner in',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  invite.businessName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                _infoRow(theme, Icons.person_outline_rounded, 'Invited by', invite.createdByEmail),
                const SizedBox(height: 12),
                _infoRow(theme, Icons.access_time_rounded, 'Expires', _formatExpiry(invite.expiresAt)),
                const SizedBox(height: 12),
                _infoRow(
                  theme,
                  invite.status == InviteStatus.active
                      ? Icons.check_circle_outline_rounded
                      : Icons.cancel_outlined,
                  'Status',
                  invite.status.display,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (isExpired)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This invitation has expired. Please request a new one.',
                      style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            )
          else if (user == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.investment.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.investment, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Please log in first to accept this invitation.',
                      style: TextStyle(color: AppColors.investment, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canAccept ? () => _acceptInvite(user) : null,
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: const Text('Accept Invitation'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(ThemeData theme, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(ThemeData theme, ColorScheme colorScheme) {
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
                color: AppColors.profit.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 48,
                color: AppColors.profit,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome aboard!',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'You have successfully joined this business as a partner. You can now view your ledger, transactions, and profit share.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.read(inviteProvider.notifier).clearAcceptSuccess();
                context.go('/partner-dashboard');
              },
              icon: const Icon(Icons.dashboard_rounded, size: 18),
              label: const Text('Go to Dashboard'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme, String message) {
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
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: 48, color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 20),
            Text(
              'Invalid Invitation',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Validating invitation...', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptInvite(dynamic user) async {
    final invite = ref.read(inviteProvider).currentInvite;
    if (invite == null || user == null) return;

    final success = await ref.read(inviteProvider.notifier).acceptInvite(
          inviteId: invite.id,
          userId: user.id,
          userEmail: user.email,
          partnerId: user.partnerId ?? '',
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully joined the business!'),
          backgroundColor: AppColors.profit,
        ),
      );
    }
  }

  String _formatExpiry(DateTime expiresAt) {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inHours > 24) {
      return '${diff.inDays}d ${diff.inHours % 24}h remaining';
    }
    return '${diff.inHours}h ${diff.inMinutes % 60}m remaining';
  }
}
