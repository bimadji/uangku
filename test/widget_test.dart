// Test T-008: Dashboard + Feed (FR-08, FR-09).

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangku/data/database.dart';
import 'package:uangku/data/transaction_repository.dart';
import 'package:uangku/ui/dashboard_screen.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repo;
  late int catFood;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.seedCategories();
    repo = TransactionRepository(db);
    final cats = await db.select(db.categories).get();
    catFood = cats.firstWhere((c) => c.name == 'Makanan & Minuman').id;
  });

  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: MainScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Dashboard menampilkan CashFlowCard dan empty state',
      (tester) async {
    await pumpApp(tester);

    expect(find.text('Arus Kas'), findsOneWidget);
    expect(find.text('Pemasukan'), findsOneWidget);
    expect(find.text('Pengeluaran'), findsOneWidget);
    expect(find.text('Belum ada transaksi.'), findsOneWidget);
  });

  testWidgets('Dashboard menampilkan data nyata: badge sumber + mode chip',
      (tester) async {
    await repo.insert(TransactionsCompanion.insert(
      amount: 25000,
      type: TxType.expense,
      categoryId: catFood,
      source: TxSource.GOPAY,
      origin: TxOrigin.auto,
      occurredAt: DateTime.now().millisecondsSinceEpoch,
      dedupHash: 'h-gopay',
    ));

    await pumpApp(tester);

    expect(find.text('- Rp 25.000'), findsAtLeast(1));
    expect(find.text('GoPay'), findsOneWidget); // SourceBadge (FR-09)
    expect(find.text('auto'), findsOneWidget); // ModeChip
  });

  testWidgets('Tab Transaksi menampilkan daftar lengkap', (tester) async {
    await repo.insert(TransactionsCompanion.insert(
      amount: 10000,
      type: TxType.income,
      categoryId: catFood,
      source: TxSource.BTN,
      origin: TxOrigin.manual,
      occurredAt: DateTime.now().millisecondsSinceEpoch,
      dedupHash: 'h-btn',
    ));

    await pumpApp(tester);
    await tester.tap(find.text('Transaksi'));
    await tester.pumpAndSettle();

    expect(find.text('+ Rp 10.000'), findsOneWidget);
    expect(find.text('BTN'), findsOneWidget);
    expect(find.text('manual'), findsOneWidget);
  });

  testWidgets('Ganti periode ke Bulan memperbarui cash flow', (tester) async {
    await repo.insert(TransactionsCompanion.insert(
      amount: 30000,
      type: TxType.expense,
      categoryId: catFood,
      source: TxSource.CASH,
      origin: TxOrigin.manual,
      occurredAt: DateTime.now().millisecondsSinceEpoch,
      dedupHash: 'h-cash',
    ));

    await pumpApp(tester);
    await tester.tap(find.text('Bulan'));
    await tester.pumpAndSettle();

    expect(find.text('- Rp 30.000'), findsAtLeast(1));
  });
}
