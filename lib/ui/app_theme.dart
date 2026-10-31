import 'package:flutter/material.dart';

/// Token desain terpusat untuk Uangku — Clean Card Modern (mockup option-a).
///
/// Semua warna, ukuran tipografi, radius, dan spacing berasal dari CSS mockup
/// `docs/mockups/option-a/index.html` dan `docs/04-DBD.md` §3–§4.
/// Widget **tidak boleh** menulis literal warna/ukuran sendiri; semua lewat
/// kelas ini.
class AppColors {
  AppColors._();

  // Surfaces
  static const bg = Color(0xFFF4F6F9);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color(0xFFF8FAFC);

  // Text
  static const fg = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);

  // Lines & accent
  static const border = Color(0xFFE2E8F0);
  static const borderSoft = Color(0xFFF1F5F9);
  static const accent = Color(0xFF2563EB);
  static const accentSubtle = Color(0xFFEFF6FF);

  // Semantic
  static const income = Color(0xFF16A34A);
  static const incomeBg = Color(0xFFDCFCE7);
  static const incomeBorder = Color(0xFF86EFAC);
  static const incomeText = Color(0xFF14532D);
  static const expense = Color(0xFFDC2626);
  static const expenseBg = Color(0xFFFEE2E2);
  static const expenseBorder = Color(0xFFFCA5A5);
  static const expenseText = Color(0xFF7F1D1D);
  static const warn = Color(0xFFD97706);
  static const warnBg = Color(0xFFFEF3C7);
  static const warnBorder = Color(0xFFFCD34D);
  static const warnText = Color(0xFF78350F);

  // Badge sumber (outline monokrom/subtle)
  static const badgeBtnBorder = Color(0xFF94A3B8);
  static const badgeBtnText = Color(0xFF475569);
  static const badgeGopayBorder = Color(0xFF0EA5E9);
  static const badgeGopayText = Color(0xFF0369A1);
  static const badgeCashBorder = Color(0xFF16A34A);
  static const badgeCashText = Color(0xFF15803D);

  // Chip mode
  static const chipAutoBg = Color(0xFFF1F5F9);
  static const chipAutoText = Color(0xFF475569);
  static const chipManualBg = Color(0xFFFEF3C7);
  static const chipManualText = Color(0xFF92400E);

  // Donut chart (mockup legend)
  static const chart = [
    Color(0xFF2563EB),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    Color(0xFF64748B),
  ];
}

/// Skala tipografi (mockup `.screen-title`, `.tx-name`, `.cf-val`, dll).
class AppText {
  AppText._();

  static const screenTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.fg,
  );
  static const greeting = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.muted,
  );
  static const sectionTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.fg,
  );
  static const cardLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.muted,
  );
  static const body = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.fg,
  );
  static const bodyRegular = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.fg,
  );
  static const caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.muted,
  );
  static const badge = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    color: AppColors.badgeBtnText,
  );
  static const chipMode = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.chipAutoText,
  );

  /// Nominal hero di kartu Arus Kas (mockup `.cf-val`).
  static const heroAmount = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.fg,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Nominal di baris transaksi (mockup `.tx-amount`).
  static const txAmount = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Nilai ringkas di bawah hero (mockup: 15px bold).
  static const metricValue = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Label kecil di bawah nilai ringkas (mockup: 11px muted).
  static const metricLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
  );

  /// Label form (mockup `.form-label`).
  static const formLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.muted,
  );
}

/// Radius & spacing (mockup CSS variables).
class AppRadius {
  AppRadius._();

  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const pill = 24.0;
  static const key = 12.0;
}

class AppSpacing {
  AppSpacing._();

  static const screen = 20.0;
  static const card = 16.0;
  static const item = 12.0;
  static const tight = 8.0;
  static const gap = 16.0;
}

/// Tema aplikasi Moneyku — dibangun dari token di atas.
ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accent),
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.expense,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.fg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppText.screenTitle,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderSoft,
      thickness: 1,
      space: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      elevation: 0,
      height: 72,
      indicatorColor: AppColors.accentSubtle,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: selected ? AppColors.accent : AppColors.muted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 22,
          color: selected ? AppColors.accent : AppColors.muted,
        );
      }),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: StadiumBorder(),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.border),
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.fg,
      ),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      labelStyle: AppText.formLabel,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.key),
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.fg,
      contentTextStyle: TextStyle(color: AppColors.surface),
    ),
  );
}
