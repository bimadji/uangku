// Test T-036: Navigasi arsip bulanan di Dashboard.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangku/data/database.dart';
import 'package:uangku/data/transaction_repository.dart';
import 'package:uangku/ui/app_theme.dart';
import 'package:uangku/ui/dashboard_screen.dart';

void main() {
  late AppDatabase db;
  late int catFood;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.seedCategories();
    final cats = await db.select(db.categories).get();
    catFood = cats.firstWhere((c) => c.name == 'Makanan & Minuman').id;
  });

  tearDown(() => db.close());

  Future<void> addExpense(int amount, DateTime when, String hash) =>
      TransactionRepository(db).insert(TransactionsCompanion.insert(
        amount: amount,
        type: TxType.expense,
        categoryId: catFood,
        source: TxSource.BTN,
        origin: TxOrigin.auto,
        occurredAt: when.millisecondsSinceEpoch,
        dedupHash: hash,
      ));

  String monthName(DateTime d) => formatMonthYear(d);

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(theme: buildAppTheme(), home: const MainScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('T-036: logika anchor & label bulan', () {
    test('viewedAnchor bulan berjalan = awal bulan ini', () {
      final now = DateTime.now();
      final a = viewedAnchor(Period.month, 0);
      expect(a, DateTime(now.year, now.month, 1));
    });

    test('viewedAnchor offset -1 = bulan lalu', () {
      final now = DateTime.now();
      final a = viewedAnchor(Period.month, -1);
      final expected = DateTime(now.year, now.month - 1, 1);
      expect(a, DateTime(expected.year, expected.month, 1));
    });

    test('non-bulan mengabaikan offset', () {
      final a = viewedAnchor(Period.day, -2);
      expect(a.day, DateTime.now().day);
    });

    test('formatMonthYear memakai nama Indonesia', () {
      expect(formatMonthYear(DateTime(2026, 10, 1)), 'Oktober 2026');
      expect(formatMonthYear(DateTime(2026, 1, 1)), 'Januari 2026');
    });
  });

  group('T-036: navigator bulan di Dashboard', () {
    testWidgets('MonthNavigator hanya tampil di mode Bulan', (tester) async {
      await pumpApp(tester);
      // Default: Hari → tidak ada navigator
      expect(find.textContaining('Bulan sebelumnya'), findsNothing);

      // Pindah ke Bulan (segmen selalu berlabel "Bulan Ini" saat offset 0)
      await tester.tap(find.widgetWithText(GestureDetector, 'Bulan Ini'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Bulan sebelumnya'), findsOneWidget);
      expect(find.text(monthName(DateTime.now())), findsWidgets);
    });

    testWidgets('Panah kanan disabled di bulan berjalan', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Bulan Ini').first);
      await tester.pumpAndSettle();

      // Panah kanan nonaktif: mengetuknya tidak mengubah label bulan.
      final before = formatMonthYear(DateTime.now());
      await tester.tap(find.bySemanticsLabel('Bulan berikutnya'));
      await tester.pumpAndSettle();
      expect(find.text(before), findsWidgets);
    });

    testWidgets('Cash flow mengikuti bulan lalu setelah navigasi', (tester) async {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 15);
      await addExpense(75000, lastMonth, 'h-last');
      await addExpense(5000, now, 'h-now');

      await pumpApp(tester);
      await tester.tap(find.widgetWithText(GestureDetector, 'Bulan Ini'));
      await tester.pumpAndSettle();

      // Masih bulan berjalan
      expect(find.text('- Rp 5.000'), findsWidgets);

      // Geser ke bulan lalu
      await tester.tap(find.bySemanticsLabel('Bulan sebelumnya'));
      await tester.pumpAndSettle();

      expect(find.text('- Rp 75.000'), findsWidgets);
      expect(find.text(monthName(lastMonth)), findsWidgets);
    });

    testWidgets('Kembali ke mode Hari me-reset offset', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.widgetWithText(GestureDetector, 'Bulan Ini'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Bulan sebelumnya'));
      await tester.pumpAndSettle();

      // Segmen kini berlabel nama bulan singkat, bukan "Bulan Ini".
      expect(find.text('Bulan Ini'), findsNothing);

      await tester.tap(find.text('Hari Ini'));
      await tester.pumpAndSettle();

      // Kembali ke Hari: offset direset, segmen Bulan kembali "Bulan Ini",
      // dan navigator arsip hilang dari layar.
      expect(find.text('Bulan Ini'), findsOneWidget);
      expect(find.bySemanticsLabel('Bulan sebelumnya'), findsNothing);
    });
  });
}
