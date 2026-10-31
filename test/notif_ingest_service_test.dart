import 'package:drift/native.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangku/data/database.dart';
import 'package:uangku/services/categorizer_service.dart';
import 'package:uangku/services/dedup_service.dart';
import 'package:uangku/services/local_notif_service.dart';
import 'package:uangku/services/notif_ingest_service.dart';
import 'package:uangku/services/parser_engine.dart';
import 'package:uangku/services/platform_bridge.dart';

/// Test double: tidak menyentuh plugin platform, hanya merekam pemanggilan.
class _FakeLocalNotif extends LocalNotifService {
  _FakeLocalNotif() : super(FlutterLocalNotificationsPlugin());

  final List<(int, String, int, String)> shown = [];

  @override
  Future<void> showTransaction({
    required int txId,
    required String merchant,
    required int amount,
    required String categoryName,
  }) async {
    shown.add((txId, merchant, amount, categoryName));
  }
}

void main() {
  late AppDatabase db;
  late NotifIngestService ingest;
  late _FakeLocalNotif notif;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final parser = ParserEngine(db);
    await db.seedCategories();
    await parser.seedInitialRules();
    final categorizer = CategorizerService(db);
    await categorizer.seedKeywords();
    notif = _FakeLocalNotif();

    ingest = NotifIngestService(
      db: db,
      parser: parser,
      dedup: DedupService(db),
      categorizer: categorizer,
      localNotif: notif,
    );
  });

  tearDown(() => db.close());

  group('T-018: NotifIngestService (AFD §3 alur otomatis)', () {
    test('GoPay top-up → transaksi tersimpan lengkap + notifikasi tampil',
        () async {
      final txId = await ingest.handle(const RawNotification(
        packageName: 'com.gojek.gopay',
        title: 'Top up berhasil',
        text: 'Top up Rp10.000 via BTN Internet Banking App udah masuk.',
        postTime: 1793354827288,
      ));

      expect(txId, isNotNull);
      final tx = (await db.select(db.transactions).get()).single;
      expect(tx.amount, 10000);
      expect(tx.type, TxType.income);
      expect(tx.source, TxSource.GOPAY);
      expect(tx.origin, TxOrigin.auto);
      expect(tx.occurredAt, 1793354827288);

      final cat = await (db.select(db.categories)
            ..where((c) => c.id.equals(tx.categoryId)))
          .getSingle();
      expect(cat.name, 'Transfer Masuk');

      expect(notif.shown, hasLength(1));
      expect(notif.shown.single.$1, txId);
      expect(notif.shown.single.$3, 10000);
    });

    test('Bale QRIS → transaksi expense, kategori Makanan, nominal 0', () async {
      final txId = await ingest.handle(const RawNotification(
        packageName: 'id.co.btn.mobilebanking.android',
        title: 'Payment GEPREK MASZEH ITS Successful',
        text: '',
        postTime: 1793340262715,
      ));

      expect(txId, isNotNull);
      final tx = (await db.select(db.transactions).get()).single;
      expect(tx.type, TxType.expense);
      expect(tx.source, TxSource.BTN);
      expect(tx.amount, 0);
      expect(tx.merchant, 'GEPREK MASZEH ITS');

      final cat = await (db.select(db.categories)
            ..where((c) => c.id.equals(tx.categoryId)))
          .getSingle();
      expect(cat.name, 'Makanan & Minuman');
    });

    test('notifikasi duplikat → hanya satu transaksi, log ignored', () async {
      const raw = RawNotification(
        packageName: 'com.gojek.gopay',
        title: 'Top up berhasil',
        text: 'Top up Rp10.000 via BTN Internet Banking App udah masuk.',
        postTime: 1793354827288,
      );

      final first = await ingest.handle(raw);
      final second = await ingest.handle(const RawNotification(
        packageName: 'com.gojek.gopay',
        title: 'Top up berhasil',
        text: 'Top up Rp10.000 via BTN Internet Banking App udah masuk.',
        postTime: 1793354827288 + 5000, // 5 detik kemudian
      ));

      expect(first, isNotNull);
      expect(second, isNull);
      expect(await db.select(db.transactions).get(), hasLength(1));
      expect(notif.shown, hasLength(1));

      final logs = await db.select(db.parserLogs).get();
      expect(logs.any((l) => l.status == ParserLogStatus.ignored), isTrue);
    });

    test('package di luar whitelist → diabaikan total', () async {
      final txId = await ingest.handle(const RawNotification(
        packageName: 'com.whatsapp',
        title: 'Pesan',
        text: 'Transfer 10000',
        postTime: 1793355000000,
      ));

      expect(txId, isNull);
      expect(await db.select(db.transactions).get(), isEmpty);
      expect(await db.select(db.parserLogs).get(), isEmpty);
      expect(notif.shown, isEmpty);
    });

    test('notifikasi tidak didukung → tidak ada transaksi, log failed',
        () async {
      final txId = await ingest.handle(const RawNotification(
        packageName: 'id.co.btn.mobilebanking.android',
        title: 'Promo Diskon HUT BTN',
        text: 'Diskon menarik',
        postTime: 1793355000000,
      ));

      expect(txId, isNull);
      expect(await db.select(db.transactions).get(), isEmpty);
      expect(notif.shown, isEmpty);

      final logs = await db.select(db.parserLogs).get();
      expect(logs.single.status, ParserLogStatus.failed);
    });

    test('sourceFor memetakan package resmi, null untuk lainnya', () {
      expect(NotifIngestService.sourceFor('id.co.btn.mobilebanking.android'),
          TxSource.BTN);
      expect(NotifIngestService.sourceFor('com.gojek.gopay'), TxSource.GOPAY);
      expect(NotifIngestService.sourceFor('com.example'), isNull);
    });

    test('dedup_hash transaksi otomatis mengikuti DedupService.computeHash',
        () async {
      await ingest.handle(const RawNotification(
        packageName: 'com.gojek.gopay',
        title: 'Top up berhasil',
        text: 'Top up Rp10.000 via BTN Internet Banking App udah masuk.',
        postTime: 1793354827288,
      ));

      final tx = (await db.select(db.transactions).get()).single;
      final expected = DedupService.computeHash(
        source: TxSource.GOPAY,
        amount: 10000,
        merchant: 'BTN Internet Banking App',
        occurredAt: 1793354827288,
      );
      expect(tx.dedupHash, expected);
    });
  });
}
