import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../widgets/common/app_bar_widget.dart';
import '../providers/settings_provider.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen>
    with SingleTickerProviderStateMixin {
  bool _autoBackup = false;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBarWidget(title: 'Backup & Restore'),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _buildInfoHeader(theme, colorScheme),
            const SizedBox(height: 24),
            _buildBackupSection(theme, colorScheme, state),
            const SizedBox(height: 16),
            _buildRestoreSection(theme, colorScheme, state),
            const SizedBox(height: 24),
            _buildAutoBackupSection(theme, colorScheme),
            const SizedBox(height: 24),
            _buildBackupInfoSection(theme, colorScheme, state),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.shield_rounded, color: colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Data Protection', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Your data is backed up securely. Regular backups prevent data loss.',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupSection(ThemeData theme, ColorScheme colorScheme, SettingsState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.backup_rounded, size: 32, color: colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text('Create Backup', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Backup all your data including partners, transactions, and settings.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 48,
              child: FilledButton.icon(
                onPressed: state.isBackingUp ? null
                    : () => ref.read(settingsProvider.notifier).backupData(),
                icon: state.isBackingUp
                    ? SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary))
                    : const Icon(Icons.backup_rounded, size: 20),
                label: Text(state.isBackingUp ? 'Backing up...' : 'Backup Now'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreSection(ThemeData theme, ColorScheme colorScheme, SettingsState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: colorScheme.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.restore_rounded, size: 32, color: colorScheme.secondary),
            ),
            const SizedBox(height: 16),
            Text('Restore Data', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Restore your data from a previously created backup file.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 48,
              child: OutlinedButton.icon(
                onPressed: state.isRestoring ? null
                    : () => ref.read(settingsProvider.notifier).restoreData(),
                icon: state.isRestoring
                    ? SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary))
                    : const Icon(Icons.restore_rounded, size: 20),
                label: Text(state.isRestoring ? 'Restoring...' : 'Restore from File'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoBackupSection(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: SwitchListTile(
        secondary: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.sync_rounded, size: 20, color: colorScheme.primary),
        ),
        title: const Text('Auto Backup', style: TextStyle(fontWeight: FontWeight.w500)),
        subtitle: const Text('Automatically backup data daily'),
        value: _autoBackup,
        onChanged: (value) => setState(() => _autoBackup = value),
      ),
    );
  }

  Widget _buildBackupInfoSection(ThemeData theme, ColorScheme colorScheme, SettingsState state) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, colorScheme, 'Backup Information', Icons.info_outline_rounded),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(Icons.access_time_rounded, 'Last Backup',
                  state.lastBackupDate != null
                      ? dateFormat.format(DateTime.parse(state.lastBackupDate!))
                      : 'No backup yet',
                  colorScheme),
                const Divider(height: 24),
                _buildInfoRow(Icons.folder_rounded, 'Backup Location', 'Internal Storage / Backups', colorScheme),
                const Divider(height: 24),
                _buildInfoRow(Icons.storage_rounded, 'Backup Size', '~2.5 MB', colorScheme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, ColorScheme colorScheme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600, color: colorScheme.primary)),
      ],
    );
  }
}
