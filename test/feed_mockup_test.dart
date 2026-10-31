// Test T-031: Layar Transaksi (Feed) sesuai mockup option-a.

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
  late int catTransport;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = TransactionRepository(db);
    await db.seedCategories();
    final cats = await db.select(db.categories).get();
    catFood = cats.firstWhere((c) => c.name == 'Makanan & Minuman').id;
    catTransport = cats.firstWhere((c) => c.name == 'Transportasi').id;
  });

  tearDown(() => db.close());

  Future<void> pumpFeed(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(theme: buildAppTheme(), home: const MainScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transaksi'));
    await tester.pumpAndSettle();
  }

  group('T-031: Layar Transaksi sesuai mockup', () {
    testWidgets('Judul layar adalah "Riwayat Transaksi"', (tester) async {
      await pumpFeed(tester);
      expect(find.text('Riwayat Transaksi'), findsOneWidget);
    });

    testWidgets('Transaksi dikelompokkan per tanggal dalam kartu (mockup)',
        (tester) async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      await repo.insert(TransactionsCompanion.insert(
        amount: 22000,
        type: TxType.expense,
        categoryId: catFood,
        source: TxSource.BTN,
        origin: TxOrigin.auto,
        occurredAt: now.millisecondsSinceEpoch,
        dedupHash: 'h-today',
      ));
      await repo.insert(TransactionsCompanion.insert(
        amount: 14000,
        type: TxType.expense,
        categoryId: catTransport,
        source: TxSource.GOPAY,
        origin: TxOrigin.auto,
        occurredAt: yesterday.millisecondsSinceEpoch,
        dedupHash: 'h-yesterday',
      ));

      await pumpFeed(tester);

      // Header grouping tanggal huruf kapital (mockup: HARI INI, KEMARIN)
      expect(find.textContaining('HARI INI'), findsOneWidget);
      expect(find.textContaining('KEMARIN'), findsOneWidget);

      // Masing-masing tanggal dibungkus dalam Card terpisah
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('Baris transaksi menampilkan label kategori di bawah nominal',
        (tester) async {
      await repo.insert(TransactionsCompanion.insert(
        amount: 22000,
        type: TxType.expense,
        categoryId: catFood,
        source: TxSource.BTN,
        origin: TxOrigin.auto,
        occurredAt: DateTime.now().millisecondsSinceEpoch,
        dedupHash: 'h1',
      ));

      await pumpFeed(tester);

      expect(find.text('Makanan & Minuman'), findsOneWidget);
      expect(find.text('- Rp 22.000'), findsOneWidget);
    });

    testWidgets('Filter chip sumber berpenampilan pill (mockup option-a)',
        (tester) async {
      await pumpFeed(tester);

      // Filter chips: Semua, BTN, GoPay, Tunai
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('BTN'), findsWidgets);
      expect(find.text('GoPay'), findsWidgets);
      expect(find.text('Tunai'), findsWidgets);
    });
  });
}
