import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final Color? iconColor;
  final Color? confirmButtonColor;
  final bool isDestructive;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.icon = Icons.help_outline_rounded,
    this.iconColor,
    this.confirmButtonColor,
    this.isDestructive = false,
    this.onConfirm,
    this.onCancel,
  });

  const ConfirmationDialog.delete({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Delete',
    this.cancelLabel = 'Cancel',
    this.icon = Icons.delete_outline_rounded,
    this.iconColor,
    this.confirmButtonColor,
    this.isDestructive = true,
    this.onConfirm,
    this.onCancel,
  });

  const ConfirmationDialog.logout({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Logout',
    this.cancelLabel = 'Stay',
    this.icon = Icons.logout_rounded,
    this.iconColor,
    this.confirmButtonColor,
    this.isDestructive = false,
    this.onConfirm,
    this.onCancel,
  });

  Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveIconColor = iconColor ??
        (isDestructive ? colorScheme.error : colorScheme.primary);

    return AlertDialog(
      title: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: effectiveIconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(icon, color: effectiveIconColor, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            onCancel?.call();
            Navigator.of(context).pop(false);
          },
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () {
            onConfirm?.call();
            Navigator.of(context).pop(true);
          },
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: confirmButtonColor ?? colorScheme.error,
                  foregroundColor: colorScheme.onError,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
