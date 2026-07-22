import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/enums.dart';
import '../../../widgets/common/confirmation_dialog.dart';
import '../../../widgets/common/app_bar_widget.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsProvider.notifier).loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBarWidget(
        title: 'Settings',
        showBack: false,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _buildAccountSection(theme, colorScheme),
          _buildSectionDivider(),
          _buildPreferencesSection(theme, colorScheme, state),
          _buildSectionDivider(),
          _buildDataSection(theme, colorScheme, state),
          _buildSectionDivider(),
          _buildNotificationsSection(theme, colorScheme, state),
          _buildSectionDivider(),
          _buildAboutSection(theme, colorScheme),
          _buildSectionDivider(),
          _buildLogoutSection(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildSectionDivider() {
    return const SizedBox(height: 8);
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
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
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? colorScheme.primary).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: iconColor ?? colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ??
          Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Switch(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
    );
  }

  Widget _buildAccountSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, colorScheme, 'Account', Icons.person_rounded),
        _buildMenuTile(
          icon: Icons.person_rounded,
          title: 'Profile',
          subtitle: 'Name, email, photo',
          onTap: () => context.push('/settings/profile'),
        ),
        _buildMenuTile(
          icon: Icons.lock_outline_rounded,
          title: 'Change Password',
          onTap: () {},
        ),
        _buildMenuTile(
          icon: Icons.pin_rounded,
          title: 'PIN Lock',
          subtitle: 'Secure app with PIN',
          onTap: () {},
        ),
        _buildMenuTile(
          icon: Icons.fingerprint_rounded,
          title: 'Biometric Login',
          subtitle: 'Use fingerprint or face ID',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(
    ThemeData theme,
    ColorScheme colorScheme,
    SettingsState state,
  ) {
    String themeLabel;
    IconData themeIcon;
    switch (state.themeMode) {
      case ThemeMode.light:
        themeLabel = 'Light';
        themeIcon = Icons.light_mode_rounded;
      case ThemeMode.dark:
        themeLabel = 'Dark';
        themeIcon = Icons.dark_mode_rounded;
      case ThemeMode.system:
        themeLabel = 'System';
        themeIcon = Icons.settings_brightness_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, colorScheme, 'Preferences', Icons.tune_rounded),
        _buildMenuTile(
          icon: themeIcon,
          title: 'Theme',
          subtitle: themeLabel,
          onTap: () => context.push('/settings/theme'),
        ),
        _buildMenuTile(
          icon: Icons.currency_exchange_rounded,
          title: 'Currency',
          subtitle: state.currency.displayName,
          onTap: () => _showCurrencyPicker(colorScheme),
        ),
        _buildMenuTile(
          icon: Icons.language_rounded,
          title: 'Language',
          subtitle: state.language.toUpperCase(),
          onTap: () => _showLanguagePicker(colorScheme),
        ),
      ],
    );
  }

  Widget _buildDataSection(
    ThemeData theme,
    ColorScheme colorScheme,
    SettingsState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, colorScheme, 'Data', Icons.storage_rounded),
        _buildMenuTile(
          icon: Icons.backup_rounded,
          title: 'Backup Data',
          subtitle: state.lastBackupDate != null
              ? 'Last backup: ${state.lastBackupDate}'
              : 'Create a local backup',
          onTap: () => context.push('/settings/backup'),
        ),
        _buildMenuTile(
          icon: Icons.restore_rounded,
          title: 'Restore Data',
          subtitle: 'Restore from a backup file',
          onTap: () => context.push('/settings/backup'),
        ),
        _buildMenuTile(
          icon: Icons.delete_sweep_rounded,
          title: 'Clear Cache',
          subtitle: 'Free up storage space',
          onTap: () => _showClearCacheConfirmation(colorScheme),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection(
    ThemeData theme,
    ColorScheme colorScheme,
    SettingsState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          theme, colorScheme, 'Notifications', Icons.notifications_rounded),
        _buildSwitchTile(
          icon: Icons.notifications_active_rounded,
          title: 'Push Notifications',
          subtitle: 'Receive push notifications',
          value: state.notificationsEnabled,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).updateNotifications(value);
          },
        ),
        _buildSwitchTile(
          icon: Icons.receipt_long_rounded,
          title: 'Transaction Alerts',
          value: true,
          onChanged: (_) {},
        ),
        _buildSwitchTile(
          icon: Icons.people_rounded,
          title: 'Partner Updates',
          value: true,
          onChanged: (_) {},
        ),
        _buildSwitchTile(
          icon: Icons.assessment_rounded,
          title: 'Report Notifications',
          value: false,
          onChanged: (_) {},
        ),
      ],
    );
  }

  Widget _buildAboutSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          theme, colorScheme, 'About', Icons.info_outline_rounded),
        _buildMenuTile(
          icon: Icons.info_rounded,
          title: 'App Version',
          subtitle: '${AppConstants.appVersion} (${AppConstants.appBuildNumber})',
          onTap: () {},
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'v${AppConstants.appVersion}',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.primary),
            ),
          ),
        ),
        _buildMenuTile(
          icon: Icons.description_rounded,
          title: 'Terms of Service',
          onTap: () {},
        ),
        _buildMenuTile(
          icon: Icons.privacy_tip_rounded,
          title: 'Privacy Policy',
          onTap: () {},
        ),
        _buildMenuTile(
          icon: Icons.support_agent_rounded,
          title: 'Contact Support',
          subtitle: AppConstants.supportEmail,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildLogoutSection(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: () => _showLogoutConfirmation(colorScheme),
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: const Text('Logout'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.error,
            side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _showCurrencyPicker(ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text('Select Currency',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
              const Divider(),
              SizedBox(
                height: 320,
                child: ListView.separated(
                  itemCount: Currency.values.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final currency = Currency.values[index];
                    final isSelected = ref.read(currencyProvider) == currency;
                    return ListTile(
                      leading: Text(
                        currency.symbol,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600, color: colorScheme.primary),
                      ),
                      title: Text(currency.displayName),
                      subtitle: Text(currency.code),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
                          : null,
                      onTap: () {
                        ref.read(settingsProvider.notifier).updateCurrency(currency);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguagePicker(ColorScheme colorScheme) {
    final languages = [
      ('en', 'English', 'US'),
      ('hi', 'Hindi', 'IN'),
      ('ml', 'Malayalam', 'IN'),
      ('ta', 'Tamil', 'IN'),
      ('te', 'Telugu', 'IN'),
      ('kn', 'Kannada', 'IN'),
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text('Select Language',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
              const Divider(),
              SizedBox(
                height: 320,
                child: ListView.separated(
                  itemCount: languages.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final lang = languages[index];
                    final isSelected = ref.read(languageProvider) == lang.$1;
                    return ListTile(
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            lang.$2.substring(0, 2).toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 12,
                              color: colorScheme.primary),
                          ),
                        ),
                      ),
                      title: Text(lang.$2),
                      subtitle: Text(lang.$3),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
                          : null,
                      onTap: () {
                        ref.read(settingsProvider.notifier).updateLanguage(lang.$1);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClearCacheConfirmation(ColorScheme colorScheme) {
    ConfirmationDialog(
      title: 'Clear Cache',
      message: 'This will clear all cached data. Your saved data will not be affected.',
      icon: Icons.delete_sweep_rounded,
      iconColor: colorScheme.error,
      confirmLabel: 'Clear',
      isDestructive: true,
      onConfirm: () {},
    ).show(context);
  }

  void _showLogoutConfirmation(ColorScheme colorScheme) {
    ConfirmationDialog.logout(
      title: 'Logout',
      message: 'Are you sure you want to logout from your account?',
      onConfirm: () {},
    ).show(context);
  }
}
