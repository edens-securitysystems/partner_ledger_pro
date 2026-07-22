import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../theme/app_colors.dart';
import '../providers/auth_provider.dart';

class PinScreen extends ConsumerStatefulWidget {
  final bool isChangePin;
  final int pinLength;

  const PinScreen({
    super.key,
    this.isChangePin = false,
    this.pinLength = 6,
  });

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  int _failedAttempts = 0;
  bool _isLocked = false;
  bool _showError = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _pinDotsController;

  static const int _maxFailedAttempts = 5;
  static const Duration _lockDuration = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 4).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _pinDotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _pinDotsController.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_isLocked || _pin.length >= widget.pinLength) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin += digit;
      _showError = false;
    });
    _pinDotsController.forward(from: 0);
    if (_pin.length == widget.pinLength) {
      _verifyPin();
    }
  }

  void _onDeletePressed() {
    if (_pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verifyPin() async {
    if (widget.isChangePin) {
      Navigator.pop(context, _pin);
      return;
    }
    final valid = await ref.read(authProvider.notifier).validatePin(_pin);
    if (!mounted) return;
    if (valid) {
      setState(() => _pin = '');
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _failedAttempts++;
        _showError = true;
        _pin = '';
      });
      _shakeController.forward(from: 0);
      if (_failedAttempts >= _maxFailedAttempts) {
        setState(() => _isLocked = true);
        Future.delayed(_lockDuration, () {
          if (mounted) setState(() => _isLocked = false);
        });
      }
    }
  }

  Future<void> _handleBiometric() async {
    await ref.read(authProvider.notifier).biometricLogin();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            if (widget.isChangePin)
              Padding(
                padding: const EdgeInsets.only(
                  top: 8,
                  left: 8,
                  right: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text(
                      'Change PIN',
                      style: theme.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            const Spacer(flex: 2),
            _buildHeader(theme, colorScheme),
            const Gap(40),
            _buildPinDots(colorScheme),
            const Gap(32),
            if (_showError)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _isLocked
                        ? 'Too many attempts. Try again in 30s.'
                        : _failedAttempts == 1
                            ? 'Invalid PIN'
                            : 'Invalid PIN (${_maxFailedAttempts - _failedAttempts} attempts left)',
                    key: ValueKey('$_isLocked-$_failedAttempts'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.lightError,
                    ),
                  ),
                ),
              ),
            if (_isLocked)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            if (!widget.isChangePin && !_isLocked)
              TextButton.icon(
                onPressed: _handleBiometric,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Use Face ID / Touch ID'),
              ),
            const Spacer(flex: 2),
            _buildNumberPad(theme, colorScheme),
            const Gap(24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.lightPrimary.withValues(alpha: 0.1),
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.lightPrimary,
            size: 32,
          ),
        ),
        const Gap(16),
        Text(
          widget.isChangePin ? 'Enter New PIN' : 'Enter PIN',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Gap(4),
        Text(
          widget.isChangePin
              ? 'Choose a ${widget.pinLength}-digit PIN'
              : 'Use your ${widget.pinLength}-digit PIN to unlock',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPinDots(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.pinLength, (i) {
          final isFilled = i < _pin.length;
          return AnimatedScale(
            scale: isFilled ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 16,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled
                    ? AppColors.lightPrimary
                    : colorScheme.surfaceContainerHighest,
                border: !isFilled
                    ? Border.all(color: colorScheme.outline)
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNumberPad(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          _buildNumberRow(theme, colorScheme, ['1', '2', '3']),
          const Gap(12),
          _buildNumberRow(theme, colorScheme, ['4', '5', '6']),
          const Gap(12),
          _buildNumberRow(theme, colorScheme, ['7', '8', '9']),
          const Gap(12),
          Row(
            children: [
              const Expanded(child: SizedBox()),
              Expanded(
                child: _buildNumberButton(theme, colorScheme, '0'),
              ),
              Expanded(
                child: _buildDeleteButton(theme, colorScheme),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberRow(
    ThemeData theme,
    ColorScheme colorScheme,
    List<String> digits,
  ) {
    return Row(
      children: digits.map((d) {
        return Expanded(child: _buildNumberButton(theme, colorScheme, d));
      }).toList(),
    );
  }

  Widget _buildNumberButton(
    ThemeData theme,
    ColorScheme colorScheme,
    String digit,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLocked ? null : () => _onDigitPressed(digit),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 64,
            alignment: Alignment.center,
            child: Text(
              digit,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLocked ? null : _onDeletePressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 64,
            alignment: Alignment.center,
            child: Icon(
              Icons.backspace_outlined,
              color: colorScheme.onSurfaceVariant,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
