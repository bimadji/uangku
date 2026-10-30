import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangku/data/database.dart';
import 'package:uangku/services/dedup_service.dart';
import 'package:uangku/services/parser_engine.dart';
import 'package:uangku/services/platform_bridge.dart';

/// Fixture model untuk pengujian regresi parser (TRD §7, BSD §5)
class ParserFixture {
  const ParserFixture({
    required this.name,
    required this.raw,
    required this.expectedSuccess,
    this.expectedAppLabel,
    this.expectedTxType,
    this.expectedAmount,
    this.expectedMerchant,
  });

  final String name;
  final RawNotification raw;
  final bool expectedSuccess;
  final String? expectedAppLabel;
  final TxType? expectedTxType;
  final int? expectedAmount;
  final String? expectedMerchant;
}

void main() {
  late AppDatabase db;
  late ParserEngine parser;
  late DedupService dedup;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    parser = ParserEngine(db);
    dedup = DedupService(db);
    await parser.seedInitialRules();
    await db.seedCategories();
  });

  tearDown(() => db.close());

  // Seluruh sampel aktual nyata dari perangkat HP (T-010):
  final fixtures = <ParserFixture>[
    // 1. GoPay Top Up Masuk
    const ParserFixture(
      name: 'GoPay: Top-up via BTN Mobile Banking',
      raw: RawNotification(
        packageName: 'com.gojek.gopay',
        title: 'Top up berhasil',
        text: 'Top up Rp10.000 via BTN Internet Banking App udah masuk.',
        postTime: 1793354827288,
      ),
      expectedSuccess: true,
      expectedAppLabel: 'GoPay',
      expectedTxType: TxType.income,
      expectedAmount: 10000,
      expectedMerchant: 'BTN Internet Banking App',
    ),

    // 2. Bale by BTN QRIS Payment (Merchant tertangkap, amount 0 karena tidak ada di notifikasi bank)
    const ParserFixture(
      name: 'Bale BTN: QRIS Payment Geprek Maszeh',
      raw: RawNotification(
        packageName: 'id.co.btn.mobilebanking.android',
        title: 'Payment GEPREK MASZEH ITS Successful',
        text: '',
        postTime: 1793340262715,
      ),
      expectedSuccess: true,
      expectedAppLabel: 'BTN',
      expectedTxType: TxType.expense,
      expectedAmount: 0,
      expectedMerchant: 'GEPREK MASZEH ITS',
    ),

    // 3. Bale by BTN Transfer Masuk
    const ParserFixture(
      name: 'Bale BTN: Transfer Masuk Rekening',
      raw: RawNotification(
        packageName: 'id.co.btn.mobilebanking.android',
        title: 'Transfer Masuk',
        text: '',
        postTime: 1793354110767,
      ),
      expectedSuccess: true,
      expectedAppLabel: 'BTN',
      expectedTxType: TxType.income,
      expectedAmount: 0,
      expectedMerchant: null,
    ),

    // 4. Kasus Notifikasi Belum Didukung (Harus gagal anggun, tercatat di log)
    const ParserFixture(
      name: 'Bale BTN: Notifikasi Info/Promo yang belum didukung',
      raw: RawNotification(
        packageName: 'id.co.btn.mobilebanking.android',
        title: 'Promo Diskon HUT BTN',
        text: 'Dapatkan diskon menarik di merchant pilihan.',
        postTime: 1793355000000,
      ),
      expectedSuccess: false,
    ),

    // 5. Kasus Aplikasi Lain di luar whitelist (Harus diabaikan)
    const ParserFixture(
      name: 'App Lain: Notifikasi WhatsApp',
      raw: RawNotification(
        packageName: 'com.whatsapp',
        title: 'Pesan Baru',
        text: 'Transfer sudah dikirim ya',
        postTime: 1793355100000,
      ),
      expectedSuccess: false,
    ),
  ];

  group('T-014: Suite Pengujian Regresi Fixture Parser Lengkap', () {
    for (final fixture in fixtures) {
      test('Fixture: ${fixture.name}', () async {
        final candidate = await parser.parse(fixture.raw);

        if (fixture.expectedSuccess) {
          expect(candidate, isNotNull,
              reason: 'Notifikasi seharusnya berhasil diparse');
          expect(candidate!.appLabel, equals(fixture.expectedAppLabel));
          expect(candidate.txType, equals(fixture.expectedTxType));
          expect(candidate.amount, equals(fixture.expectedAmount));
          expect(candidate.merchant, equals(fixture.expectedMerchant));
          expect(candidate.occurredAt, equals(fixture.raw.postTime));

          // Verifikasi audit log berhasil disimpan
          final logs = await (db.select(db.parserLogs)
                ..where((l) => l.postedAt.equals(fixture.raw.postTime)))
              .get();
          expect(logs, isNotEmpty);
          expect(logs.first.status, ParserLogStatus.parsed);
        } else {
          expect(candidate, isNull,
              reason: 'Notifikasi tidak didukung seharusnya mengembalikan null');

          // Verifikasi audit log mencatat kegagalan
          final logs = await (db.select(db.parserLogs)
                ..where((l) => l.postedAt.equals(fixture.raw.postTime)))
              .get();
          expect(logs, isNotEmpty);
          expect(logs.first.status, ParserLogStatus.failed);
        }
      });
    }

    test('Integrasi Parser + Dedup: replika notifikasi ganda terdeteksi dan tercatat ignored',
        () async {
      // 1. Notifikasi pertama tiba
      const notif1 = RawNotification(
        packageName: 'com.gojek.gopay',
        title: 'Top up berhasil',
        text: 'Top up Rp10.000 via BTN Internet Banking App udah masuk.',
        postTime: 1793354827288,
      );

      final candidate1 = await parser.parse(notif1);
      expect(candidate1, isNotNull);

      // Simpan transaksi pertama ke database
      final hash1 = DedupService.computeHash(
        source: TxSource.GOPAY,
        amount: candidate1!.amount,
        merchant: candidate1.merchant,
        occurredAt: candidate1.occurredAt,
      );
      final cats = await db.select(db.categories).get();
      final catId = cats.first.id;

      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              amount: candidate1.amount,
              type: candidate1.txType,
              categoryId: catId,
              source: TxSource.GOPAY,
              origin: TxOrigin.auto,
              merchant: Value(candidate1.merchant),
              occurredAt: candidate1.occurredAt,
              dedupHash: hash1,
            ),
          );

      // 2. Notifikasi replika tiba selang 10 detik kemudian
      const notif2 = RawNotification(
        packageName: 'com.gojek.gopay',
        title: 'Top up berhasil',
        text: 'Top up Rp10.000 via BTN Internet Banking App udah masuk.',
        postTime: 1793354827288 + 10000,
      );

      final candidate2 = await parser.parse(notif2);
      expect(candidate2, isNotNull);

      final isDup = await dedup.isDuplicate(candidate2!, TxSource.GOPAY);
      expect(isDup, isTrue,
          reason: 'Notifikasi ganda dalam window 60s wajib terdeteksi duplikat');

      // Catat ke log audit
      await dedup.logIgnored(
        packageName: notif2.packageName,
        title: notif2.title,
        body: notif2.text,
        postedAt: notif2.postTime,
        ruleId: candidate2.ruleId,
      );

      final logs = await (db.select(db.parserLogs)
            ..where((l) => l.postedAt.equals(notif2.postTime)))
          .get();
      expect(logs.any((l) => l.status == ParserLogStatus.ignored), isTrue,
          reason: 'Harus ada entri parser_logs berstatus ignored untuk duplikat');
    });
  });
}
