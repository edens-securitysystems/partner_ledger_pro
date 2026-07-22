import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback? onAddTransaction;
  final VoidCallback? onAddPartner;
  final VoidCallback? onViewReports;
  final VoidCallback? onExport;

  const QuickActions({
    super.key,
    this.onAddTransaction,
    this.onAddPartner,
    this.onViewReports,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        label: 'Add\nTransaction',
        icon: Icons.add_card_rounded,
        color: const Color(0xFF3182CE),
        onTap: onAddTransaction,
      ),
      _QuickAction(
        label: 'Add\nPartner',
        icon: Icons.person_add_rounded,
        color: const Color(0xFF38A169),
        onTap: onAddPartner,
      ),
      _QuickAction(
        label: 'View\nReports',
        icon: Icons.analytics_rounded,
        color: const Color(0xFF805AD5),
        onTap: onViewReports,
      ),
      _QuickAction(
        label: 'Export\nData',
        icon: Icons.file_download_rounded,
        color: const Color(0xFFDD6B20),
        onTap: onExport,
      ),
    ];

    return Row(
      children: actions
          .map(
            (action) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _QuickActionTile(action: action),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

class _QuickActionTile extends StatefulWidget {
  final _QuickAction action;

  const _QuickActionTile({required this.action});

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.animationDurationFast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.action.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.action.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.action.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      widget.action.icon,
                      size: 24,
                      color: widget.action.color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.action.label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
