import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangku/data/database.dart';
import 'package:uangku/services/dedup_service.dart';
import 'package:uangku/services/parser_engine.dart';

void main() {
  late AppDatabase db;
  late DedupService dedup;
  late int catFood;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dedup = DedupService(db);
    await db.seedCategories();
    final cats = await db.select(db.categories).get();
    catFood = cats.firstWhere((c) => c.name == 'Makanan & Minuman').id;
  });

  tearDown(() => db.close());

  ParsedCandidate makeCandidate({
    required int amount,
    String? merchant,
    required int occurredAt,
    int ruleId = 1,
  }) =>
      ParsedCandidate(
        packageName: 'id.co.btn.mobilebanking.android',
        appLabel: 'BTN',
        txType: TxType.expense,
        amount: amount,
        merchant: merchant,
        occurredAt: occurredAt,
        ruleId: ruleId,
      );

  group('DedupService Unit Tests (BSD §4 Aturan Dedup)', () {
    test('computeHash menghasilkan hash unik deterministik per bucket 60 detik', () {
      final h1 = DedupService.computeHash(
        source: TxSource.BTN,
        amount: 22000,
        merchant: 'GEPREK MASZEH ITS',
        occurredAt: 1793340260000,
      );
      final h2 = DedupService.computeHash(
        source: TxSource.BTN,
        amount: 22000,
        merchant: 'geprek maszeh its ', // Case & trim insensitive
        occurredAt: 1793340260000,
      );
      final h3 = DedupService.computeHash(
        source: TxSource.BTN,
        amount: 22000,
        merchant: 'GEPREK MASZEH ITS',
        occurredAt: 1793340260000 + 120000, // Beda > 60s
      );

      expect(h1, equals(h2));
      expect(h1, isNot(equals(h3)));
    });

    test('isDuplicate mengidentifikasi transaksi ganda identik via exact hash', () async {
      const now = 1793340260000;
      final hash = DedupService.computeHash(
        source: TxSource.BTN,
        amount: 22000,
        merchant: 'GEPREK MASZEH ITS',
        occurredAt: now,
      );

      // Simpan transaksi pertama ke database
      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              amount: 22000,
              type: TxType.expense,
              categoryId: catFood,
              source: TxSource.BTN,
              origin: TxOrigin.auto,
              merchant: const Value('GEPREK MASZEH ITS'),
              occurredAt: now,
              dedupHash: hash,
            ),
          );

      final candidate = makeCandidate(
        amount: 22000,
        merchant: 'GEPREK MASZEH ITS',
        occurredAt: now,
      );

      final isDup = await dedup.isDuplicate(candidate, TxSource.BTN);
      expect(isDup, isTrue);
    });

    test('isDuplicate menolak notifikasi duplikat dalam window ±60 detik (Lapis 2)', () async {
      const baseTime = 1793340260000;
      final hash = DedupService.computeHash(
        source: TxSource.GOPAY,
        amount: 10000,
        merchant: 'BTN App',
        occurredAt: baseTime,
      );

      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              amount: 10000,
              type: TxType.income,
              categoryId: catFood,
              source: TxSource.GOPAY,
              origin: TxOrigin.auto,
              merchant: const Value('BTN App'),
              occurredAt: baseTime,
              dedupHash: hash,
            ),
          );

      // Tiba 30 detik kemudian (masih dalam window toleransi 60s)
      final delayedCandidate = makeCandidate(
        amount: 10000,
        merchant: 'btn app',
        occurredAt: baseTime + 30000,
      );

      final isDup = await dedup.isDuplicate(delayedCandidate, TxSource.GOPAY);
      expect(isDup, isTrue);
    });

    test('Transaksi berbeda waktu > 60 detik atau beda nominal tidak dianggap duplikat', () async {
      const baseTime = 1793340260000;
      final hash = DedupService.computeHash(
        source: TxSource.BTN,
        amount: 22000,
        merchant: 'GEPREK MASZEH ITS',
        occurredAt: baseTime,
      );

      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              amount: 22000,
              type: TxType.expense,
              categoryId: catFood,
              source: TxSource.BTN,
              origin: TxOrigin.auto,
              merchant: const Value('GEPREK MASZEH ITS'),
              occurredAt: baseTime,
              dedupHash: hash,
            ),
          );

      // Selang 5 menit (transaksi wajar berikutnya)
      final nextCandidate = makeCandidate(
        amount: 22000,
        merchant: 'GEPREK MASZEH ITS',
        occurredAt: baseTime + 300000,
      );
      expect(await dedup.isDuplicate(nextCandidate, TxSource.BTN), isFalse);

      // Nominal berbeda
      final differentAmount = makeCandidate(
        amount: 15000,
        merchant: 'GEPREK MASZEH ITS',
        occurredAt: baseTime + 10000,
      );
      expect(await dedup.isDuplicate(differentAmount, TxSource.BTN), isFalse);
    });

    test('logIgnored mencatat status ignored dan pesan audit ke parser_logs', () async {
      await dedup.logIgnored(
        packageName: 'id.co.btn.mobilebanking.android',
        title: 'Payment duplicate',
        body: 'dup body',
        postedAt: 1793340260000,
        ruleId: 2,
      );

      final logs = await db.select(db.parserLogs).get();
      expect(logs, hasLength(1));
      expect(logs.first.status, ParserLogStatus.ignored);
      expect(logs.first.error, contains('window 60s'));
    });
  });
}
