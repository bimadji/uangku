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

  Future<void> pumpDashboard(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: MainScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('T-021: CategoryDonutChart & Picker Periode (FR-08)', () {
    testWidgets('Donut chart tampil saat ada data pengeluaran', (tester) async {
      await repo.insert(TransactionsCompanion.insert(
        amount: 30000,
        type: TxType.expense,
        categoryId: catFood,
        source: TxSource.BTN,
        origin: TxOrigin.auto,
        occurredAt: DateTime.now().millisecondsSinceEpoch,
        dedupHash: 'h1',
      ));
      await repo.insert(TransactionsCompanion.insert(
        amount: 20000,
        type: TxType.expense,
        categoryId: catTransport,
        source: TxSource.GOPAY,
        origin: TxOrigin.auto,
        occurredAt: DateTime.now().millisecondsSinceEpoch,
        dedupHash: 'h2',
      ));

      await pumpDashboard(tester);

      expect(find.text('Breakdown Kategori'), findsOneWidget);
      expect(find.text('Makanan & Minuman'), findsOneWidget);
      expect(find.text('Transportasi'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget); // 30.000 / 50.000
      expect(find.text('40%'), findsOneWidget); // 20.000 / 50.000
    });

    testWidgets('Empty state breakdown kategori tampil saat belum ada pengeluaran',
        (tester) async {
      await pumpDashboard(tester);

      expect(find.text('Breakdown Kategori'), findsOneWidget);
      expect(find.text('Belum ada pengeluaran di periode ini.'), findsOneWidget);
    });

    testWidgets('Picker periode ganti ke Bulan me-refresh breakdown kategori',
        (tester) async {
      // Transaksi di bulan ini tapi hari kemarin
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      await repo.insert(TransactionsCompanion.insert(
        amount: 25000,
        type: TxType.expense,
        categoryId: catFood,
        source: TxSource.BTN,
        origin: TxOrigin.auto,
        occurredAt: yesterday.millisecondsSinceEpoch,
        dedupHash: 'h-prev',
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: MainScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Di mode Hari (default), transaksi kemarin tidak muncul
      expect(find.text('Belum ada pengeluaran di periode ini.'), findsOneWidget);

      // Ubah ke Bulan
      await tester.tap(find.text('Bulan'));
      await tester.pumpAndSettle();

      // Sekarang muncul
      expect(find.text('Makanan & Minuman'), findsWidgets);
    });
  });
}
