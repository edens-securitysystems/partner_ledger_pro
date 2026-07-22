import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppDatePicker extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final void Function(DateTime)? onDateSelected;
  final String? Function(DateTime?)? validator;
  final IconData? prefixIcon;
  final bool enabled;
  final bool showClearButton;
  final String? hintText;

  const AppDatePicker({
    super.key,
    required this.label,
    this.selectedDate,
    this.firstDate,
    this.lastDate,
    this.onDateSelected,
    this.validator,
    this.prefixIcon,
    this.enabled = true,
    this.showClearButton = true,
    this.hintText,
  });

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
      helpText: label,
    );
    if (picked != null) onDateSelected?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd MMM yyyy');

    final displayText = selectedDate != null
        ? dateFormat.format(selectedDate!)
        : (hintText ?? 'Select date');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: enabled ? () => pickDate(context) : null,
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, size: 20)
                  : const Icon(Icons.calendar_month_rounded, size: 20),
              suffixIcon: enabled && showClearButton && selectedDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {},
                      visualDensity: VisualDensity.compact,
                    )
                  : null,
              errorText: validator?.call(selectedDate),
            ),
            child: Text(
              displayText,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: selectedDate != null
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AppDateRangePicker extends StatelessWidget {
  final String label;
  final DateTimeRange? selectedRange;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final void Function(DateTimeRange)? onRangeSelected;
  final bool enabled;
  final bool showClearButton;

  const AppDateRangePicker({
    super.key,
    required this.label,
    this.selectedRange,
    this.firstDate,
    this.lastDate,
    this.onRangeSelected,
    this.enabled = true,
    this.showClearButton = true,
  });

  Future<void> pickRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: selectedRange,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
      helpText: label,
    );
    if (picked != null) onRangeSelected?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd MMM');

    final displayText = selectedRange != null
        ? '${dateFormat.format(selectedRange!.start)} - ${dateFormat.format(selectedRange!.end)}'
        : 'Select date range';

    return InkWell(
      onTap: enabled ? () => pickRange(context) : null,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.date_range_rounded, size: 20),
              suffixIcon: enabled && showClearButton && selectedRange != null
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {},
                  visualDensity: VisualDensity.compact,
                )
              : null,
          suffix: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
        ),
        child: Text(
          displayText,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: selectedRange != null
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
