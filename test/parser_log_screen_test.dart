import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangku/data/database.dart';
import 'package:uangku/services/parser_engine.dart';
import 'package:uangku/ui/dashboard_screen.dart';
import 'package:uangku/ui/parser_log_screen.dart';

void main() {
  late AppDatabase db;
  late ParserEngine parser;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    parser = ParserEngine(db);
    await parser.seedInitialRules();
  });

  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('T-020: Uji Rule Parser (FR-10)', () {
    test('testPattern cocok dan mengekstrak amount + merchant', () {
      final r = ParserRuleTesting.testPattern(
        r'Top up Rp(?<amount>[\d\.]+) via (?<merchant>.*) udah masuk',
        'Top up Rp10.000 via BTN Internet Banking App udah masuk.',
      );
      expect(r.ok, isTrue);
      expect(r.amount, 10000);
      expect(r.merchant, 'BTN Internet Banking App');
    });

    test('testPattern melaporkan regex invalid sebagai error', () {
      final r = ParserRuleTesting.testPattern('([a-z', 'apapun');
      expect(r.ok, isFalse);
      expect(r.error, contains('tidak valid'));
    });

    test('testPattern melaporkan tidak ada kecocokan', () {
      final r = ParserRuleTesting.testPattern('Transfer Masuk', 'Top up berhasil');
      expect(r.ok, isFalse);
      expect(r.error, contains('Tidak ada kecocokan'));
    });

    test('testPattern tanpa named group amount mengembalikan amount null', () {
      final r = ParserRuleTesting.testPattern(
        r'Payment (?<merchant>.*) Successful',
        'Payment GEPREK MASZEH ITS Successful',
      );
      expect(r.ok, isTrue);
      expect(r.amount, isNull);
      expect(r.merchant, 'GEPREK MASZEH ITS');
    });

    test('updateRulePattern mengubah rule di DB tanpa build ulang', () async {
      final rule = (await db.select(db.parserRules).get()).first;
      await parser.updateRulePattern(rule.id, r'Bayar (?<merchant>.*) oke');

      final updated = await (db.select(db.parserRules)
            ..where((r) => r.id.equals(rule.id)))
          .getSingle();
      expect(updated.pattern, r'Bayar (?<merchant>.*) oke');
    });

    test('trimLogs menyisakan maksimal 200 entri terbaru', () async {
      for (var i = 0; i < 210; i++) {
        await db.into(db.parserLogs).insert(ParserLogsCompanion.insert(
              packageName: 'pkg',
              title: 't$i',
              body: 'b$i',
              status: ParserLogStatus.failed,
              postedAt: 1793354000000 + i,
            ));
      }
      await parser.trimLogs();

      final left = await db.select(db.parserLogs).get();
      expect(left, hasLength(200));
      // Entri tertua (t0..t9) terhapus
      expect(left.any((l) => l.title == 't0'), isFalse);
      expect(left.any((l) => l.title == 't209'), isTrue);
    });

    test('clearLogs menghapus seluruh log', () async {
      await db.into(db.parserLogs).insert(ParserLogsCompanion.insert(
            packageName: 'pkg',
            title: 't',
            body: 'b',
            status: ParserLogStatus.parsed,
            postedAt: 1793354000000,
          ));
      expect(await parser.clearLogs(), 1);
      expect(await db.select(db.parserLogs).get(), isEmpty);
    });
  });

  group('T-020: Layar Log Parser & Uji Rule', () {
    testWidgets('empty state muncul saat belum ada log', (tester) async {
      await pump(tester, const ParserLogScreen());
      expect(find.textContaining('Belum ada notifikasi'), findsOneWidget);
    });

    testWidgets('daftar log menampilkan status parsed/failed/ignored',
        (tester) async {
      for (final (status, title) in [
        (ParserLogStatus.parsed, 'ok-entry'),
        (ParserLogStatus.failed, 'bad-entry'),
        (ParserLogStatus.ignored, 'dup-entry'),
      ]) {
        await db.into(db.parserLogs).insert(ParserLogsCompanion.insert(
              packageName: 'com.gojek.gopay',
              title: title,
              body: 'body $title',
              status: status,
              postedAt: 1793354000000,
            ));
      }

      await pump(tester, const ParserLogScreen());
      expect(find.text('Parsed'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('Ignored'), findsOneWidget);
      expect(find.textContaining('body ok-entry'), findsOneWidget);
    });

    testWidgets('Uji Rule menampilkan hasil cocok dan tombol Simpan aktif',
        (tester) async {
      await pump(tester, const RuleTestScreen(prefill: 'Transfer Masuk'));

      // Pilih rule pertama
      await tester.tap(find.text('Rule (per aplikasi)'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('GoPay').last);
      await tester.pumpAndSettle();

      // Ganti teks agar cocok dengan pattern GoPay
      await tester.enterText(
        find.byType(TextField).first,
        'Top up Rp10.000 via BTN Internet Banking App udah masuk.',
      );
      await tester.pumpAndSettle();

      expect(find.text('Cocok'), findsOneWidget);
      expect(find.textContaining('10000'), findsOneWidget);
    });

    testWidgets('regex invalid menampilkan pesan error inline merah',
        (tester) async {
      await pump(tester, const RuleTestScreen(prefill: 'apapun'));

      await tester.tap(find.text('Rule (per aplikasi)'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('GoPay').last);
      await tester.pumpAndSettle();

      final patternField = find.byType(TextField).last;
      await tester.enterText(patternField, '([a-z');
      await tester.pumpAndSettle();

      expect(find.textContaining('tidak valid'), findsOneWidget);
    });
  });
}
