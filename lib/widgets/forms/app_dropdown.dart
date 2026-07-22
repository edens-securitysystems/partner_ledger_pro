import 'package:flutter/material.dart';

class AppDropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final Widget? leading;

  const AppDropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
    this.leading,
  });
}

class AppDropdown<T> extends StatelessWidget {
  final String label;
  final String? hint;
  final T? value;
  final List<AppDropdownItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;
  final IconData? prefixIcon;
  final EdgeInsetsGeometry? contentPadding;

  const AppDropdown({
    super.key,
    required this.label,
    this.hint,
    required this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final selectedItem = items.cast<AppDropdownItem<T>?>().firstWhere(
          (item) => item!.value == value,
          orElse: () => null,
        );

    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item.value,
          child: Row(
            children: [
              if (item.leading != null)
                item.leading!
              else if (item.icon != null) ...[
                Icon(
                  item.icon,
                  size: 20,
                  color: item.iconColor ?? colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
              ],
              Text(
                item.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      validator: (val) => validator?.call(val),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        contentPadding: contentPadding,
      ),
      dropdownColor: colorScheme.surface,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: colorScheme.onSurfaceVariant,
      ),
      selectedItemBuilder: (context) {
        return items.map((item) {
          return Row(
            children: [
              if (item.leading != null)
                item.leading!
              else if (item.icon != null) ...[
                Icon(
                  item.icon,
                  size: 20,
                  color: item.iconColor ?? colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
              ],
              Text(
                item.value == value
                    ? (selectedItem?.label ?? item.label)
                    : item.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        }).toList();
      },
    );
  }
}
