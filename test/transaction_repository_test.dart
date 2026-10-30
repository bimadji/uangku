// Test T-007: TransactionRepository CRUD + Agregasi (FR-08, FR-09, FR-12)

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangku/data/database.dart';
import 'package:uangku/data/transaction_repository.dart';

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

  TransactionsCompanion makeTx({
    required int amount,
    required TxType type,
    required int categoryId,
    required TxSource source,
    required DateTime occurredAt,
    required String hash,
  }) =>
      TransactionsCompanion.insert(
        amount: amount,
        type: type,
        categoryId: categoryId,
        source: source,
        origin: TxOrigin.auto,
        occurredAt: occurredAt.millisecondsSinceEpoch,
        dedupHash: hash,
      );

  group('CRUD', () {
    test('insert + byId + deleteById', () async {
      final id = await repo.insert(makeTx(
        amount: 15000,
        type: TxType.expense,
        categoryId: catFood,
        source: TxSource.CASH,
        occurredAt: DateTime(2026, 10, 30, 10, 0),
        hash: 'h1',
      ));
      expect(id, isPositive);

      final fetched = await repo.byId(id);
      expect(fetched?.amount, 15000);

      final deleted = await repo.deleteById(id);
      expect(deleted, 1);
      expect(await repo.byId(id), isNull);
    });

    test('feed mengurutkan terbaru dulu (occurred_at DESC)', () async {
      await repo.insert(makeTx(
        amount: 10000,
        type: TxType.expense,
        categoryId: catFood,
        source: TxSource.BTN,
        occurredAt: DateTime(2026, 10, 30, 8, 0),
        hash: 'h-early',
      ));
      await repo.insert(makeTx(
        amount: 20000,
        type: TxType.expense,
        categoryId: catFood,
        source: TxSource.GOPAY,
        occurredAt: DateTime(2026, 10, 30, 12, 0),
        hash: 'h-late',
      ));

      final items = await repo.feed();
      expect(items, hasLength(2));
      expect(items.first.amount, 20000); // 12:00 lebih baru
      expect(items.last.amount, 10000);
    });
  });

  group('Agregasi Arus Kas (FR-08)', () {
    test('cashFlow day hanya menghitung hari bersangkutan', () async {
      final target = DateTime(2026, 10, 30, 14, 0);
      await repo.insert(makeTx(
        amount: 50000,
        type: TxType.income,
        categoryId: catFood,
        source: TxSource.BTN,
        occurredAt: DateTime(2026, 10, 30, 9, 0),
        hash: 'today-in',
      ));
      await repo.insert(makeTx(
        amount: 20000,
        type: TxType.expense,
        categoryId: catFood,
        source: TxSource.GOPAY,
        occurredAt: DateTime(2026, 10, 30, 12, 0),
        hash: 'today-out',
      ));
      await repo.insert(makeTx(
        amount: 100000,
        type: TxType.income,
        categoryId: catFood,
        source: TxSource.BTN,
        occurredAt: DateTime(2026, 10, 29, 23, 0), // kemarin
        hash: 'yesterday-in',
      ));

      final flow = await repo.cashFlow(Period.day, at: target);
      expect(flow.income, 50000);
      expect(flow.expense, 20000);
      expect(flow.net, 30000);
    });

    test('expenseByCategory mengelompokkan dan mengurutkan terbesar dulu',
        () async {
      final now = DateTime(2026, 10, 30, 12, 0);
      await repo.insert(makeTx(
        amount: 10000,
        type: TxType.expense,
        categoryId: catTransport,
        source: TxSource.GOPAY,
        occurredAt: now,
        hash: 't1',
      ));
      await repo.insert(makeTx(
        amount: 50000,
        type: TxType.expense,
        categoryId: catFood,
        source: TxSource.CASH,
        occurredAt: now,
        hash: 'f1',
      ));

      final breakdown = await repo.expenseByCategory(Period.day, at: now);
      expect(breakdown, hasLength(2));
      expect(breakdown[0].categoryName, 'Makanan & Minuman');
      expect(breakdown[0].total, 50000);
      expect(breakdown[1].categoryName, 'Transportasi');
      expect(breakdown[1].total, 10000);
    });
  });
}
