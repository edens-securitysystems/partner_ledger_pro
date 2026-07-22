import 'package:flutter/material.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;
  final Widget? leading;
  final VoidCallback? onBack;
  final bool useGradient;
  final bool showSearchToggle;
  final bool isSearchActive;
  final VoidCallback? onSearchToggle;
  final double height;

  const AppBarWidget({
    super.key,
    required this.title,
    this.showBack = true,
    this.actions,
    this.leading,
    this.onBack,
    this.useGradient = false,
    this.showSearchToggle = false,
    this.isSearchActive = false,
    this.onSearchToggle,
    this.height = kToolbarHeight,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final appBar = AppBar(
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: onBack ?? () => Navigator.of(context).pop(),
            )
          : leading,
      title: Text(title),
      actions: [
        if (showSearchToggle)
          IconButton(
            icon: Icon(
              isSearchActive ? Icons.search_off_rounded : Icons.search_rounded,
            ),
            onPressed: onSearchToggle,
          ),
        if (actions != null) ...actions!,
      ],
    );

    if (!useGradient) return appBar;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: appBar,
    );
  }
}
