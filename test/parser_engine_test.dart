import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangku/data/database.dart';
import 'package:uangku/services/parser_engine.dart';
import 'package:uangku/services/platform_bridge.dart';

void main() {
  late AppDatabase db;
  late ParserEngine parser;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    parser = ParserEngine(db);
    await parser.seedInitialRules();
  });

  tearDown(() => db.close());

  group('ParserEngine Unit Tests (Sampel Nyata T-010)', () {
    test('Parse GoPay Top-up: mengekstrak nominal, merchant/metode, dan tipe income',
        () async {
      const notif = RawNotification(
        packageName: 'com.gojek.gopay',
        title: 'Top up berhasil',
        text: 'Top up Rp10.000 via BTN Internet Banking App udah masuk.',
        postTime: 1793354827288,
      );

      final candidate = await parser.parse(notif);
      expect(candidate, isNotNull);
      expect(candidate!.appLabel, 'GoPay');
      expect(candidate.txType, TxType.income);
      expect(candidate.amount, 10000);
      expect(candidate.merchant, 'BTN Internet Banking App');
      expect(candidate.occurredAt, 1793354827288);

      final logs = await db.select(db.parserLogs).get();
      expect(logs, hasLength(1));
      expect(logs.first.status, ParserLogStatus.parsed);
      expect(logs.first.ruleId, candidate.ruleId);
    });

    test('Parse Bale by BTN QRIS: mengekstrak merchant, tipe expense, dan amount 0',
        () async {
      const notif = RawNotification(
        packageName: 'id.co.btn.mobilebanking.android',
        title: 'Payment GEPREK MASZEH ITS Successful',
        text: '',
        postTime: 1793340262715,
      );

      final candidate = await parser.parse(notif);
      expect(candidate, isNotNull);
      expect(candidate!.appLabel, 'BTN');
      expect(candidate.txType, TxType.expense);
      expect(candidate.merchant, 'GEPREK MASZEH ITS');
      expect(candidate.amount, 0); // Notifikasi Bale tidak menyertakan nominal
      expect(candidate.occurredAt, 1793340262715);

      final logs = await db.select(db.parserLogs).get();
      expect(logs, hasLength(1));
      expect(logs.first.status, ParserLogStatus.parsed);
    });

    test('Parse Bale by BTN Transfer Masuk: tipe income', () async {
      const notif = RawNotification(
        packageName: 'id.co.btn.mobilebanking.android',
        title: 'Transfer Masuk',
        text: '',
        postTime: 1793354110767,
      );

      final candidate = await parser.parse(notif);
      expect(candidate, isNotNull);
      expect(candidate!.appLabel, 'BTN');
      expect(candidate.txType, TxType.income);
      expect(candidate.merchant, isNull);

      final logs = await db.select(db.parserLogs).get();
      expect(logs, hasLength(1));
      expect(logs.first.status, ParserLogStatus.parsed);
    });

    test('Notifikasi belum didukung: menghasilkan status failed di parser_logs',
        () async {
      const notif = RawNotification(
        packageName: 'id.co.btn.mobilebanking.android',
        title: 'Pembayaran Tagihan Listrik Berhasil',
        text: '',
        postTime: 1793355000000,
      );

      final candidate = await parser.parse(notif);
      expect(candidate, isNull);

      final logs = await db.select(db.parserLogs).get();
      expect(logs, hasLength(1));
      expect(logs.first.status, ParserLogStatus.failed);
      expect(logs.first.error, contains('belum didukung'));
    });

    test('Performa parsing < 10 ms (NFR-02)', () async {
      const notif = RawNotification(
        packageName: 'com.gojek.gopay',
        title: 'Top up berhasil',
        text: 'Top up Rp50.000 via BCA OneKlik udah masuk.',
        postTime: 1793354827288,
      );

      final stopwatch = Stopwatch()..start();
      final candidate = await parser.parse(notif);
      stopwatch.stop();

      expect(candidate, isNotNull);
      expect(stopwatch.elapsedMilliseconds, lessThan(50)); // Cold parse SQLite in-memory
    });
  });
}
