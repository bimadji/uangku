// Test T-029: token desain terpusat (mockup option-a).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangku/ui/app_theme.dart';

void main() {
  group('T-029: Token desain terpusat', () {
    test('Warna token sama persis dengan CSS mockup option-a', () {
      expect(AppColors.bg, const Color(0xFFF4F6F9));
      expect(AppColors.surface, const Color(0xFFFFFFFF));
      expect(AppColors.surfaceSubtle, const Color(0xFFF8FAFC));
      expect(AppColors.fg, const Color(0xFF0F172A));
      expect(AppColors.muted, const Color(0xFF64748B));
      expect(AppColors.border, const Color(0xFFE2E8F0));
      expect(AppColors.accent, const Color(0xFF2563EB));
      expect(AppColors.income, const Color(0xFF16A34A));
      expect(AppColors.expense, const Color(0xFFDC2626));
      expect(AppColors.warn, const Color(0xFFD97706));
    });

    test('Theme memakai accent biru (bukan seed teal)', () {
      final theme = buildAppTheme();
      expect(theme.colorScheme.primary, AppColors.accent);
      expect(theme.scaffoldBackgroundColor, AppColors.bg);
    });

    test('Nominal memakai tabular figures (DBD §4)', () {
      expect(AppText.heroAmount.fontFeatures, isNotNull);
      expect(AppText.txAmount.fontFeatures, isNotNull);
      expect(AppText.metricValue.fontFeatures, isNotNull);
    });

    test('Skala tipografi mengikuti mockup', () {
      expect(AppText.screenTitle.fontSize, 18);
      expect(AppText.screenTitle.fontWeight, FontWeight.w700);
      expect(AppText.heroAmount.fontSize, 26);
      expect(AppText.heroAmount.fontWeight, FontWeight.w800);
      expect(AppText.txAmount.fontSize, 14);
      expect(AppText.badge.fontSize, 10);
    });

    test('Card memakai radius 16 + border, tanpa elevation (mockup .card)', () {
      final theme = buildAppTheme();
      final shape = theme.cardTheme.shape! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(AppRadius.md));
      expect(shape.side.color, AppColors.border);
      expect(theme.cardTheme.elevation, 0);
    });

    test('NavigationBar: surface, indicator accent-subtle, icon accent saat aktif', () {
      final theme = buildAppTheme();
      expect(theme.navigationBarTheme.backgroundColor, AppColors.surface);
      expect(theme.navigationBarTheme.indicatorColor, AppColors.accentSubtle);
      expect(theme.navigationBarTheme.height, 72);
    });

    test('FAB biru accent + bentuk stadium (mockup .fab)', () {
      final theme = buildAppTheme();
      expect(theme.floatingActionButtonTheme.backgroundColor, AppColors.accent);
      expect(theme.floatingActionButtonTheme.shape, isA<StadiumBorder>());
    });

    test('Chip berbentuk pill (mockup .cat-chip radius 24)', () {
      final theme = buildAppTheme();
      expect(theme.chipTheme.shape, isA<StadiumBorder>());
      expect(theme.chipTheme.side?.color, AppColors.border);
    });

    test('Input form: radius 10, border netral, label muted (mockup .form-input)', () {
      final theme = buildAppTheme();
      final border = theme.inputDecorationTheme.enabledBorder as OutlineInputBorder;
      expect(border.borderRadius, BorderRadius.circular(10));
      expect(border.borderSide.color, AppColors.border);
      expect(theme.inputDecorationTheme.labelStyle?.color, AppColors.muted);
    });

    test('Tombol utama biru accent, tinggi min 48dp (mockup .btn-save)', () {
      final theme = buildAppTheme();
      final style = theme.filledButtonTheme.style;
      expect(style?.backgroundColor?.resolve({}), AppColors.accent);
      expect(style?.minimumSize?.resolve({}), const Size(0, 48));
    });
  });
}
