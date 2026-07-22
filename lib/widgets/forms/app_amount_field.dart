import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppAmountField extends StatefulWidget {
  final String label;
  final String? hint;
  final double? initialValue;
  final TextEditingController? controller;
  final String currencySymbol;
  final int decimalPlaces;
  final void Function(double?)? onChanged;
  final void Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool readOnly;
  final IconData? prefixIcon;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? contentPadding;

  const AppAmountField({
    super.key,
    required this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.currencySymbol = '\u20B9',
    this.decimalPlaces = 2,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
    this.focusNode,
    this.contentPadding,
  });

  @override
  State<AppAmountField> createState() => _AppAmountFieldState();
}

class _AppAmountFieldState extends State<AppAmountField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _hasValue = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        TextEditingController(
          text: widget.initialValue != null
              ? widget.initialValue!.toStringAsFixed(widget.decimalPlaces)
              : '',
        );
    _focusNode = widget.focusNode ?? FocusNode();
    _hasValue = _controller.text.isNotEmpty;
  }

  @override
  void didUpdateWidget(AppAmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) _controller.dispose();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true, signed: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp('^-?\\d*\\.?\\d{0,${widget.decimalPlaces}}'),
        ),
        _AmountFormatter(decimalPlaces: widget.decimalPlaces),
      ],
      validator: (value) {
        if (widget.validator != null) return widget.validator!(value);
        if (value == null || value.isEmpty) return null;
        final amount = double.tryParse(value.replaceAll(',', ''));
        if (amount == null) return 'Invalid amount';
        return null;
      },
      onChanged: (value) {
        setState(() => _hasValue = value.isNotEmpty);
        if (widget.onChanged != null) {
          final amount = double.tryParse(
            value.replaceAll(',', '').replaceAll(widget.currencySymbol, ''),
          );
          widget.onChanged!(amount);
        }
      },
      onFieldSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint ?? '0.00',
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, size: 20)
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  widget.currencySymbol,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
        suffixText: !_hasValue ? null : widget.currencySymbol,
        suffixStyle: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        contentPadding: widget.contentPadding,
      ),
    );
  }
}

class _AmountFormatter extends TextInputFormatter {
  final int decimalPlaces;

  _AmountFormatter({required this.decimalPlaces});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final dotIndex = text.indexOf('.');
    if (dotIndex == -1) return newValue;

    final decimalPart = text.substring(dotIndex + 1);
    if (decimalPart.length > decimalPlaces) {
      return TextEditingValue(
        text: text.substring(0, dotIndex + decimalPlaces + 1),
        selection: TextSelection.collapsed(
          offset: dotIndex + decimalPlaces + 1,
        ),
      );
    }

    return newValue;
  }
}
