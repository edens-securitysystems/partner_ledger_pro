import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/common/app_bar_widget.dart';
import '../providers/settings_provider.dart';

class ThemeScreen extends ConsumerStatefulWidget {
  const ThemeScreen({super.key});

  @override
  ConsumerState<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends ConsumerState<ThemeScreen>
    with SingleTickerProviderStateMixin {
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
    final currentMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBarWidget(title: 'Theme Settings'),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _buildSectionHeader(theme, colorScheme, 'Theme Mode', Icons.brightness_6_rounded),
            const SizedBox(height: 12),
            _buildThemeOptions(currentMode),
            const SizedBox(height: 32),
            _buildSectionHeader(theme, colorScheme, 'Accent Color', Icons.palette_outlined),
            const SizedBox(height: 12),
            _buildAccentColorPicker(colorScheme),
            const SizedBox(height: 32),
            _buildSectionHeader(theme, colorScheme, 'Preview', Icons.visibility_rounded),
            const SizedBox(height: 12),
            _buildPreviewCard(colorScheme, currentMode),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme, ColorScheme colorScheme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600, color: colorScheme.primary)),
      ],
    );
  }

  Widget _buildThemeOptions(ThemeMode currentMode) {
    return Row(
      children: [
        Expanded(child: _ThemeOptionCard(
          icon: Icons.light_mode_rounded, label: 'Light',
          isSelected: currentMode == ThemeMode.light,
          onTap: () => ref.read(settingsProvider.notifier).updateTheme(ThemeMode.light),
        )),
        const SizedBox(width: 12),
        Expanded(child: _ThemeOptionCard(
          icon: Icons.dark_mode_rounded, label: 'Dark',
          isSelected: currentMode == ThemeMode.dark,
          onTap: () => ref.read(settingsProvider.notifier).updateTheme(ThemeMode.dark),
        )),
        const SizedBox(width: 12),
        Expanded(child: _ThemeOptionCard(
          icon: Icons.settings_brightness_rounded, label: 'System',
          isSelected: currentMode == ThemeMode.system,
          onTap: () => ref.read(settingsProvider.notifier).updateTheme(ThemeMode.system),
        )),
      ],
    );
  }

  Widget _buildAccentColorPicker(ColorScheme colorScheme) {
    final colors = [
      const Color(0xFF6750A4), const Color(0xFF1976D2), const Color(0xFF388E3C),
      const Color(0xFFD32F2F), const Color(0xFFF57C00), const Color(0xFF7B1FA2),
      const Color(0xFF0097A7), const Color(0xFFC2185B), const Color(0xFF455A64),
      const Color(0xFF512DA8),
    ];

    return Wrap(
      spacing: 12, runSpacing: 12,
      children: colors.map((color) {
        final isSelected = colorScheme.primary == color;
        return GestureDetector(
          onTap: () {},
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected ? colorScheme.onSurface : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))]
                  : null,
            ),
            child: isSelected
                ? Icon(Icons.check_rounded,
                    color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                    size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreviewCard(ColorScheme colorScheme, ThemeMode currentMode) {
    final isDark = currentMode == ThemeMode.dark ||
        (currentMode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);

    final previewColorScheme = ColorScheme.fromSeed(
      seedColor: colorScheme.primary,
      brightness: isDark ? Brightness.dark : Brightness.light,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [previewColorScheme.primaryContainer, previewColorScheme.surface],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: previewColorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.preview_rounded, color: previewColorScheme.onPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sample Card', style: TextStyle(fontWeight: FontWeight.w600, color: previewColorScheme.onSurface)),
                        Text(isDark ? 'Dark theme preview' : 'Light theme preview',
                          style: TextStyle(fontSize: 12, color: previewColorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: previewColorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('NEW', style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: previewColorScheme.onSecondaryContainer)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: 0.6,
                color: previewColorScheme.primary,
                backgroundColor: previewColorScheme.surfaceContainerHighest,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildPreviewChip(previewColorScheme.primary, previewColorScheme.onPrimary, 'Button'),
                  const SizedBox(width: 8),
                  _buildPreviewChip(previewColorScheme.secondary, previewColorScheme.onSecondary, 'Chip'),
                  const Spacer(),
                  Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: previewColorScheme.onSurfaceVariant, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewChip(Color bg, Color fg, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionCard({
    required this.icon, required this.label,
    required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
