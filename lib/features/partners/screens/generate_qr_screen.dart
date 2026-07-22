import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/deep_link_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/partners/providers/invite_provider.dart';
import '../../../theme/app_colors.dart';

class GenerateQrScreen extends ConsumerStatefulWidget {
  final String businessId;
  final String businessName;

  const GenerateQrScreen({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  ConsumerState<GenerateQrScreen> createState() => _GenerateQrScreenState();
}

class _GenerateQrScreenState extends ConsumerState<GenerateQrScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateInvite();
    });
  }

  void _generateInvite() {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    ref.read(inviteProvider.notifier).createInvite(
          businessId: widget.businessId,
          businessName: widget.businessName,
          createdByUserId: user.id,
          createdByEmail: user.email,
          expiryHours: 48,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inviteState = ref.watch(inviteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Invite QR'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: inviteState.status == InviteProcessStatus.creating ||
                inviteState.status == InviteProcessStatus.loading
            ? const Center(child: CircularProgressIndicator())
            : inviteState.status == InviteProcessStatus.error
                ? _buildError(theme, inviteState.error ?? 'Failed to generate invite')
                : inviteState.currentInvite != null
                    ? _buildQrView(theme, colorScheme, inviteState)
                    : _buildEmpty(theme),
      ),
    );
  }

  Widget _buildQrView(ThemeData theme, ColorScheme colorScheme, InviteState state) {
    final invite = state.currentInvite!;
    final qrData = buildQrPayload(
      businessId: invite.businessId,
      token: invite.token,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
                Text(
                  widget.businessName,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scan this QR to join as partner',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.circle,
                      color: Colors.black87,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.circle,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.investment.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_rounded, size: 16, color: AppColors.investment),
                      const SizedBox(width: 6),
                      Text(
                        'Expires: ${_formatExpiry(invite.expiresAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.investment,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: qrData));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invite link copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy Link'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Share.share(
                      'Join ${widget.businessName} on Partner Ledger Pro\n\n$qrData\n\nUse this invite link to view your ledger, transactions, and profit share.',
                      subject: 'Partner Invitation - ${widget.businessName}',
                    );
                  },
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How it works',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _stepRow(theme, '1', 'Share this QR or link with your partner'),
                _stepRow(theme, '2', 'Partner opens the link or scans the QR'),
                _stepRow(theme, '3', 'Partner logs in and is linked to this business'),
                _stepRow(theme, '4', 'Partner sees their ledger, transactions, and profit share'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepRow(ThemeData theme, String step, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
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
            Icon(Icons.error_outline_rounded, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton(onPressed: _generateInvite, child: const Text('Retry')),
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
            Icon(Icons.qr_code_2_rounded, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No invite generated yet', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton(onPressed: _generateInvite, child: const Text('Generate Invite')),
          ],
        ),
      ),
    );
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
