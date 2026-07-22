import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Light Theme ──────────────────────────────────────────────────────────

  static const Color lightPrimary = Color(0xFF1A3A5C);
  static const Color lightPrimaryLight = Color(0xFF2C5282);
  static const Color lightPrimaryDark = Color(0xFF0F2440);
  static const Color lightSecondary = Color(0xFF3182CE);
  static const Color lightSecondaryLight = Color(0xFF4299E1);
  static const Color lightTertiary = Color(0xFF38A169);

  static const Color lightBackground = Color(0xFFF7FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightSurfaceContainer = Color(0xFFF8FAFC);
  static const Color lightSurfaceContainerHigh = Color(0xFFF1F5F9);
  static const Color lightSurfaceContainerHighest = Color(0xFFE2E8F0);

  static const Color lightError = Color(0xFFE53E3E);
  static const Color lightOnError = Color(0xFFFFFFFF);
  static const Color lightSuccess = Color(0xFF38A169);
  static const Color lightWarning = Color(0xFFDD6B20);
  static const Color lightInfo = Color(0xFF3182CE);

  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightOnBackground = Color(0xFF1A202C);
  static const Color lightOnSurface = Color(0xFF1A202C);
  static const Color lightOnSurfaceVariant = Color(0xFF64748B);
  static const Color lightOutline = Color(0xFFCBD5E1);
  static const Color lightOutlineVariant = Color(0xFFE2E8F0);

  // ── Dark Theme ───────────────────────────────────────────────────────────

  static const Color darkPrimary = Color(0xFF63B3ED);
  static const Color darkPrimaryLight = Color(0xFF90CDF4);
  static const Color darkPrimaryDark = Color(0xFF4299E1);
  static const Color darkSecondary = Color(0xFF4FD1C5);
  static const Color darkSecondaryLight = Color(0xFF81E6D9);
  static const Color darkTertiary = Color(0xFF68D391);
  static const Color darkTertiaryLight = Color(0xFF9AE6B4);

  static const Color darkBackground = Color(0xFF0F1724);
  static const Color darkSurface = Color(0xFF1A2332);
  static const Color darkSurfaceVariant = Color(0xFF1E293B);
  static const Color darkSurfaceContainer = Color(0xFF162032);
  static const Color darkSurfaceContainerHigh = Color(0xFF1E293B);
  static const Color darkSurfaceContainerHighest = Color(0xFF334155);

  static const Color darkError = Color(0xFFF56565);
  static const Color darkOnError = Color(0xFF1A202C);
  static const Color darkSuccess = Color(0xFF68D391);
  static const Color darkWarning = Color(0xFFFBD38D);
  static const Color darkInfo = Color(0xFF63B3ED);

  static const Color darkOnPrimary = Color(0xFF0F2440);
  static const Color darkOnSecondary = Color(0xFF0F2440);
  static const Color darkOnBackground = Color(0xFFE2E8F0);
  static const Color darkOnSurface = Color(0xFFE2E8F0);
  static const Color darkOnSurfaceVariant = Color(0xFF94A3B8);
  static const Color darkOutline = Color(0xFF475569);
  static const Color darkOutlineVariant = Color(0xFF334155);

  // ── Semantic Colors (Light) ──────────────────────────────────────────────

  static const Color profit = Color(0xFF38A169);
  static const Color profitLight = Color(0xFFC6F6D5);
  static const Color profitDark = Color(0xFF276749);

  static const Color loss = Color(0xFFE53E3E);
  static const Color lossLight = Color(0xFFFED7D7);
  static const Color lossDark = Color(0xFF9B2C2C);

  static const Color credit = Color(0xFF2F855A);
  static const Color creditLight = Color(0xFFC6F6D5);
  static const Color creditDark = Color(0xFF22543D);

  static const Color debit = Color(0xFFC53030);
  static const Color debitLight = Color(0xFFFED7D7);
  static const Color debitDark = Color(0xFF742A2A);

  static const Color investment = Color(0xFF2B6CB0);
  static const Color investmentLight = Color(0xFFBEE3F8);
  static const Color investmentDark = Color(0xFF1A365D);

  static const Color expense = Color(0xFFC05621);
  static const Color expenseLight = Color(0xFFFEEBC8);
  static const Color expenseDark = Color(0xFF7B341E);

  static const Color income = Color(0xFF276749);
  static const Color incomeLight = Color(0xFFC6F6D5);
  static const Color incomeDark = Color(0xFF1A4731);

  static const Color withdrawal = Color(0xFF9C4221);
  static const Color withdrawalLight = Color(0xFFFEEBC8);
  static const Color withdrawalDark = Color(0xFF652B19);

  static const Color transfer = Color(0xFF553C9A);
  static const Color transferLight = Color(0xFFE9D8FD);
  static const Color transferDark = Color(0xFF322659);

  static const Color loan = Color(0xFF2C7A7B);
  static const Color loanLight = Color(0xFFB2F5EA);
  static const Color loanDark = Color(0xFF1D4044);

  static const Color adjustment = Color(0xFF718096);
  static const Color adjustmentLight = Color(0xFFE2E8F0);
  static const Color adjustmentDark = Color(0xFF4A5568);

  static const Color neutral = Color(0xFF718096);
  static const Color neutralLight = Color(0xFFEDF2F7);
  static const Color neutralDark = Color(0xFF4A5568);

  // ── Chart Colors ─────────────────────────────────────────────────────────

  static const List<Color> chartPalette = <Color>[
    Color(0xFF3182CE),
    Color(0xFF38A169),
    Color(0xFFDD6B20),
    Color(0xFFE53E3E),
    Color(0xFF805AD5),
    Color(0xFF319795),
    Color(0xFFD69E2E),
    Color(0xFFDD6B20),
    Color(0xFFE53E3E),
    Color(0xFF3182CE),
  ];

  // ── Status Colors ────────────────────────────────────────────────────────

  static const Color statusActive = Color(0xFF38A169);
  static const Color statusInactive = Color(0xFFA0AEC0);
  static const Color statusPending = Color(0xFFDD6B20);
  static const Color statusSuspended = Color(0xFFE53E3E);
  static const Color statusApproved = Color(0xFF38A169);
  static const Color statusRejected = Color(0xFFE53E3E);
  static const Color statusCompleted = Color(0xFF2F855A);
  static const Color statusProcessing = Color(0xFF3182CE);
  static const Color statusCancelled = Color(0xFFA0AEC0);

  // ── Divider & Shadows ────────────────────────────────────────────────────

  static const Color dividerLight = Color(0xFFE2E8F0);
  static const Color dividerDark = Color(0xFF334155);

  static const List<BoxShadow> cardShadowLight = <BoxShadow>[
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x05000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> cardShadowDark = <BoxShadow>[
    BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  // ── Gradient Presets ─────────────────────────────────────────────────────

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1A3A5C), Color(0xFF2C5282)],
  );

  static const LinearGradient profitGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF276749), Color(0xFF38A169)],
  );

  static const LinearGradient lossGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF9B2C2C), Color(0xFFE53E3E)],
  );

  static const LinearGradient darkPrimaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF4299E1), Color(0xFF63B3ED)],
  );
}
