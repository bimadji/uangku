// Test T-006: Skema DB + seed kategori idempotent (FR-11, FR-12, BSD §1).

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangku/data/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  group('Seed Kategori FR-11', () {
    test('seed awal menghasilkan 12 kategori persis (8 expense, 4 income)',
        () async {
      await db.seedCategories();
      final all = await db.select(db.categories).get();
      expect(all, hasLength(12));

      final expense =
          all.where((c) => c.kind == CategoryKind.expense).map((c) => c.name);
      expect(expense, containsAll([
        'Makanan & Minuman', 'Transportasi', 'Kos & Tagihan', 'Belanja',
        'Hiburan', 'Kesehatan', 'Pendidikan', 'Lainnya',
      ]));

      final income =
          all.where((c) => c.kind == CategoryKind.income).map((c) => c.name);
      expect(income,
          containsAll(['Uang Saku', 'Gaji/Part-time', 'Transfer Masuk', 'Lainnya']));
    });

    test('idempotent: 2x seed tetap 12 baris (tanpa duplikat nama)', () async {
      await db.seedCategories();
      await db.seedCategories();
      final all = await db.select(db.categories).get();
      expect(all, hasLength(12));
    });
  });

  group('Constraint Skema', () {
    test('UNIQUE dedup_hash menolak insert duplikat', () async {
      await db.seedCategories();
      final cat = (await db.select(db.categories).get()).first;

      TransactionsCompanion makeTx(String hash) => TransactionsCompanion.insert(
            amount: 25000,
            type: TxType.expense,
            categoryId: cat.id,
            source: TxSource.BTN,
            origin: TxOrigin.auto,
            occurredAt: 1730000000000,
            dedupHash: hash,
          );

      await db.into(db.transactions).insert(makeTx('hash-abc'));
      await expectLater(
        () async => db.into(db.transactions).insert(makeTx('hash-abc')),
        throwsA(isA<Exception>()),
      );
    });

    test('tabel parser_rules dan parser_logs terbuat dan bisa CRUD', () async {
      final ruleId = await db.into(db.parserRules).insert(
            ParserRulesCompanion.insert(
              packageName: 'com.btn.bale',
              appLabel: 'BTN',
              txType: TxType.expense,
              pattern: r'Rp\s*(?<amount>[\d\.]+)',
            ),
          );
      expect(ruleId, isPositive);

      final logId = await db.into(db.parserLogs).insert(
            ParserLogsCompanion.insert(
              packageName: 'com.btn.bale',
              title: 'Notif',
              body: 'Rp 25.000',
              status: ParserLogStatus.parsed,
              postedAt: 1730000000000,
              ruleId: Value(ruleId),
            ),
          );
      expect(logId, isPositive);

      final logs = await db.select(db.parserLogs).get();
      expect(logs, hasLength(1));
      expect(logs.first.ruleId, ruleId);
    });
  });
}
