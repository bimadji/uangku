
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uangku/data/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  test('seed idempotent: 2x run tetap 2 kategori', () async {
    Future<void> seed() async {
      Future<void> upsert(String name, CategoryKind kind) async {
        final existing = await (db.select(db.categories)
              ..where((c) => c.name.equals(name)))
            .getSingleOrNull();
        if (existing == null) {
          await db.into(db.categories).insert(CategoriesCompanion.insert(
              name: name, kind: kind, sortOrder: 0));
        }
      }

      await upsert('Makanan & Minuman', CategoryKind.expense);
      await upsert('Uang Saku', CategoryKind.income);
    }

    await seed();
    await seed();
    expect(await db.select(db.categories).get(), hasLength(2));
  });

  test('UNIQUE dedup_hash menolak duplikat', () async {
    await db.into(db.categories).insert(CategoriesCompanion.insert(
        name: 'Lainnya', kind: CategoryKind.expense, sortOrder: 99));
    Future<TransactionsCompanion> tx(String hash) async =>
        TransactionsCompanion.insert(
            amount: 25000,
            type: TxType.expense,
            categoryId: 1,
            source: TxSource.BTN,
            origin: TxOrigin.auto,
            occurredAt: 1730000000000,
            dedupHash: hash);
    await db.into(db.transactions).insert(await tx('abc'));
    await expectLater(() async => db.into(db.transactions).insert(await tx('abc')),
        throwsA(isA<Exception>()));
  });

  test('agregasi arus kas per periode (SQL sum)', () async {
    final cat = await db.into(db.categories).insertReturning(
        CategoriesCompanion.insert(
            name: 'Transportasi', kind: CategoryKind.expense, sortOrder: 1));
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
        amount: 10000,
        type: TxType.expense,
        categoryId: cat.id,
        source: TxSource.GOPAY,
        origin: TxOrigin.auto,
        occurredAt: 1730000000000,
        dedupHash: 'h1'));
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
        amount: 50000,
        type: TxType.income,
        categoryId: cat.id,
        source: TxSource.BTN,
        origin: TxOrigin.auto,
        occurredAt: 1730000600000,
        dedupHash: 'h2'));
    final sum = await db.customSelect(
        'SELECT type, SUM(amount) s FROM transactions GROUP BY type')
        .get();
    final map = {for (final r in sum) r.data['type'] as String: r.data['s']};
    expect(map['expense'], 10000);
    expect(map['income'], 50000);
  });
}
