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
  late int catId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = TransactionRepository(db);
    await db.seedCategories();
    catId = (await db.select(db.categories).get()).first.id;
  });

  tearDown(() => db.close());

  Future<void> seed(WidgetTester tester) async {
    Future<void> add(int amount, TxSource source, String hash) => repo.insert(
          TransactionsCompanion.insert(
            amount: amount,
            type: TxType.expense,
            categoryId: catId,
            source: source,
            origin: TxOrigin.auto,
            occurredAt: DateTime.now().millisecondsSinceEpoch,
            dedupHash: hash,
          ),
        );
    await add(10000, TxSource.BTN, 'h-btn');
    await add(20000, TxSource.GOPAY, 'h-gopay');
    await add(30000, TxSource.CASH, 'h-cash');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: MainScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transaksi'));
    await tester.pumpAndSettle();
  }

  group('T-022: Filter sumber feed (FR-09)', () {
    testWidgets('Semua transaksi tampil saat filter = Semua', (tester) async {
      await seed(tester);
      expect(find.text('- Rp 10.000'), findsOneWidget);
      expect(find.text('- Rp 20.000'), findsOneWidget);
      expect(find.text('- Rp 30.000'), findsOneWidget);
    });

    testWidgets('Filter BTN hanya menyisakan transaksi BTN', (tester) async {
      await seed(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, 'BTN'));
      await tester.pumpAndSettle();

      expect(find.text('- Rp 10.000'), findsOneWidget);
      expect(find.text('- Rp 20.000'), findsNothing);
      expect(find.text('- Rp 30.000'), findsNothing);
    });

    testWidgets('Filter GoPay hanya menyisakan transaksi GoPay', (tester) async {
      await seed(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, 'GoPay'));
      await tester.pumpAndSettle();

      expect(find.text('- Rp 20.000'), findsOneWidget);
      expect(find.text('- Rp 10.000'), findsNothing);
      expect(find.text('- Rp 30.000'), findsNothing);
    });

    testWidgets('Filter Tunai hanya menyisakan transaksi tunai', (tester) async {
      await seed(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Tunai'));
      await tester.pumpAndSettle();

      expect(find.text('- Rp 30.000'), findsOneWidget);
      expect(find.text('- Rp 10.000'), findsNothing);
      expect(find.text('- Rp 20.000'), findsNothing);
    });

    testWidgets('Kembali ke Semua memunculkan lagi semua transaksi',
        (tester) async {
      await seed(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, 'BTN'));
      await tester.pumpAndSettle();
      expect(find.text('- Rp 20.000'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Semua'));
      await tester.pumpAndSettle();
      expect(find.text('- Rp 10.000'), findsOneWidget);
      expect(find.text('- Rp 20.000'), findsOneWidget);
      expect(find.text('- Rp 30.000'), findsOneWidget);
    });

    testWidgets('Badge sumber tetap tampil konsisten di baris feed',
        (tester) async {
      await seed(tester);
      expect(find.text('BTN'), findsWidgets);
      expect(find.text('GoPay'), findsWidgets);
      expect(find.text('Tunai'), findsWidgets);
    });
  });
}
