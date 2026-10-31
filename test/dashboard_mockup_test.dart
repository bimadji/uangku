// Test T-030: Dashboard sesuai mockup option-a.

import 'package:drift/drift.dart' show Value;
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
  late TransactionRepository repo;
  late int catFood;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = TransactionRepository(db);
    await db.seedCategories();
    final cats = await db.select(db.categories).get();
    catFood = cats.firstWhere((c) => c.name == 'Makanan & Minuman').id;
  });

  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(theme: buildAppTheme(), home: const MainScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('T-030: Dashboard sesuai mockup', () {
    testWidgets('Header menampilkan greeting + judul "Ringkasan Uangku" + badge OFFLINE',
        (tester) async {
      await pumpApp(tester);

      expect(find.text('Halo, Bima'), findsOneWidget);
      expect(find.text('Ringkasan Uangku'), findsOneWidget);
      expect(find.text('OFFLINE 100%'), findsOneWidget);
    });

    testWidgets('Segmented periode berada di LUAR kartu Arus Kas (mockup)',
        (tester) async {
      await pumpApp(tester);

      // Label periode mockup: Hari Ini / Minggu Ini / Bulan Ini
      expect(find.text('Hari Ini'), findsOneWidget);
      expect(find.text('Minggu Ini'), findsOneWidget);
      expect(find.text('Bulan Ini'), findsOneWidget);

      // Segmented tidak lagi berada di dalam baris judul kartu
      final card = find.ancestor(
        of: find.text('Arus Kas'),
        matching: find.byType(Card),
      );
      expect(
        find.descendant(of: card, matching: find.text('Hari Ini')),
        findsNothing,
      );
    });

    testWidgets('Kartu Arus Kas: label, hero pengeluaran, Pemasukan & Net Arus Kas',
        (tester) async {
      await repo.insert(TransactionsCompanion.insert(
        amount: 47000,
        type: TxType.expense,
        categoryId: catFood,
        source: TxSource.BTN,
        origin: TxOrigin.auto,
        occurredAt: DateTime.now().millisecondsSinceEpoch,
        dedupHash: 'h1',
      ));
      await repo.insert(TransactionsCompanion.insert(
        amount: 150000,
        type: TxType.income,
        categoryId: catFood,
        source: TxSource.BTN,
        origin: TxOrigin.auto,
        occurredAt: DateTime.now().millisecondsSinceEpoch,
        dedupHash: 'h2',
      ));

      await pumpApp(tester);

      expect(find.text('Arus Kas'), findsOneWidget);
      // Hero pengeluaran + baris transaksi memakai nominal yang sama
      expect(find.text('- Rp 47.000'), findsNWidgets(2));
      expect(find.text('+ Rp 150.000'), findsNWidgets(2)); // kartu + baris transaksi
      expect(find.text('+ Rp 103.000'), findsOneWidget); // net arus kas (hanya di kartu)
    });

    testWidgets('Section feed berada dalam kartu dengan judul + tautan "Lihat Semua"',
        (tester) async {
      await pumpApp(tester);

      expect(find.text('Transaksi Terbaru'), findsOneWidget);
      expect(find.text('Lihat Semua'), findsOneWidget);
    });

    testWidgets('Baris transaksi menampilkan label kategori di kanan bawah nominal',
        (tester) async {
      await repo.insert(TransactionsCompanion.insert(
        amount: 22000,
        type: TxType.expense,
        categoryId: catFood,
        source: TxSource.GOPAY,
        origin: TxOrigin.auto,
        merchant: const Value('GEPREK MASZEH ITS'),
        occurredAt: DateTime.now().millisecondsSinceEpoch,
        dedupHash: 'h3',
      ));

      await pumpApp(tester);

      expect(find.text('GEPREK MASZEH ITS'), findsOneWidget);
      expect(find.text('- Rp 22.000'), findsWidgets);
      // Label kategori di bawah nominal
      expect(find.text('Makanan & Minuman'), findsWidgets);
    });

    testWidgets('Tautan "Lihat Semua" memindahkan ke tab Transaksi', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Lihat Semua'));
      await tester.pumpAndSettle();

      expect(find.text('Riwayat Transaksi'), findsOneWidget);
    });

    testWidgets('Baris transaksi bisa diketuk → membuka Detail (regresi fungsi)',
        (tester) async {
      await repo.insert(TransactionsCompanion.insert(
        amount: 22000,
        type: TxType.expense,
        categoryId: catFood,
        source: TxSource.BTN,
        origin: TxOrigin.auto,
        merchant: const Value('GEPREK MASZEH ITS'),
        occurredAt: DateTime.now().millisecondsSinceEpoch,
        dedupHash: 'h4',
      ));

      await pumpApp(tester);
      await tester.ensureVisible(find.text('GEPREK MASZEH ITS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('GEPREK MASZEH ITS'));
      await tester.pumpAndSettle();

      expect(find.text('Detail Transaksi'), findsOneWidget);
    });

    testWidgets('FAB memakai warna accent biru (bukan teal)', (tester) async {
      await pumpApp(tester);

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      // Warna FAB mengikuti theme (FAB ThemeData), bukan hardcode teal.
      final theme = Theme.of(
        tester.element(find.byType(FloatingActionButton)),
      );
      final bg = theme.floatingActionButtonTheme.backgroundColor;
      expect(bg, isNotNull);
      expect(bg, isNot(Colors.teal));
      expect(fab.onPressed, isNotNull);
    });
  });
}
