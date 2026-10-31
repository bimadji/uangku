// Test T-034: Detail/Koreksi + Log Parser sesuai mockup option-a.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangku/data/database.dart';
import 'package:uangku/ui/app_theme.dart';
import 'package:uangku/ui/dashboard_screen.dart';
import 'package:uangku/ui/parser_log_screen.dart';

void main() {
  late AppDatabase db;
  late Transaction tx;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.seedCategories();
    final cat = (await db.select(db.categories).get())
        .firstWhere((c) => c.name == 'Makanan & Minuman');
    final id = await db.into(db.transactions).insert(TransactionsCompanion.insert(
          amount: 22000,
          type: TxType.expense,
          categoryId: cat.id,
          source: TxSource.BTN,
          origin: TxOrigin.auto,
          merchant: const Value('GEPREK MASZEH ITS'),
          occurredAt: 1793340262715,
          dedupHash: 'h-detail',
        ));
    tx = (await (db.select(db.transactions)..where((t) => t.id.equals(id)))
        .getSingle());
  });

  tearDown(() => db.close());

  Future<void> pumpDetail(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2700);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: TransactionDetailScreen(tx: tx),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('T-034: Detail/Koreksi sesuai mockup', () {
    testWidgets('App bar memuat tombol Batal dan Hapus berbentuk teks (mockup)',
        (tester) async {
      await pumpDetail(tester);

      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Hapus'), findsOneWidget);
      expect(find.text('Detail Transaksi'), findsOneWidget);
    });

    testWidgets('Ringkasan sumber dana dan waktu tampil read-only', (tester) async {
      await pumpDetail(tester);

      expect(find.text('SUMBER DANA'), findsOneWidget);
      expect(find.text('WAKTU'), findsOneWidget);
      expect(find.text('BTN'), findsWidgets);
    });

    testWidgets('Form memuat label mockup: nominal, merchant, kategori, catatan',
        (tester) async {
      await pumpDetail(tester);

      expect(find.text('NOMINAL (RUPIAH)'), findsOneWidget);
      expect(find.text('MERCHANT / KETERANGAN'), findsOneWidget);
      expect(find.text('KATEGORI (TAP UNTUK UBAH)'), findsOneWidget);
      expect(find.text('CATATAN PRIBADI (OPSIONAL)'), findsOneWidget);
    });

    testWidgets('Chip kategori berbentuk pill dan bisa dipilih', (tester) async {
      await pumpDetail(tester);

      // Chip kategori Transportasi ada dan bisa diketuk
      await tester.scrollUntilVisible(
        find.text('Transportasi'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Transportasi'));
      await tester.pumpAndSettle();
      expect(find.text('Transportasi'), findsOneWidget);
    });

    testWidgets('Tombol Simpan Perubahan tersedia', (tester) async {
      await pumpDetail(tester);
      await tester.scrollUntilVisible(
        find.text('Simpan Perubahan'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Simpan Perubahan'), findsOneWidget);
    });
  });

  group('T-034: Log Parser sesuai mockup', () {
    Future<void> pumpLog(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2700);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const ParserLogScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Stat card memakai label uppercase PARSED/FAILED/IGNORED',
        (tester) async {
      for (final (status, title) in [
        (ParserLogStatus.parsed, 'ok'),
        (ParserLogStatus.failed, 'bad'),
        (ParserLogStatus.ignored, 'dup'),
      ]) {
        await db.into(db.parserLogs).insert(ParserLogsCompanion.insert(
              packageName: 'com.gojek.gopay',
              title: title,
              body: 'body $title',
              status: status,
              postedAt: 1793354000000,
            ));
      }

      await pumpLog(tester);

      expect(find.text('PARSED'), findsOneWidget);
      expect(find.text('FAILED'), findsOneWidget);
      expect(find.text('IGNORED'), findsOneWidget);
    });

    testWidgets('Setiap log menampilkan badge status pill', (tester) async {
      await db.into(db.parserLogs).insert(ParserLogsCompanion.insert(
            packageName: 'com.gojek.gopay',
            title: 'Top up berhasil',
            body: 'Top up Rp10.000 via BTN App udah masuk.',
            status: ParserLogStatus.parsed,
            postedAt: 1793354000000,
          ));

      await pumpLog(tester);

      expect(find.text('parsed'), findsOneWidget);
      expect(find.text('com.gojek.gopay'), findsOneWidget);
    });

    testWidgets('Tap log membuka layar Uji Rule dengan prefill', (tester) async {
      await db.into(db.parserLogs).insert(ParserLogsCompanion.insert(
            packageName: 'com.gojek.gopay',
            title: 'Top up berhasil',
            body: 'Top up Rp10.000 via BTN App udah masuk.',
            status: ParserLogStatus.parsed,
            postedAt: 1793354000000,
          ));

      await pumpLog(tester);
      await tester.tap(find.text('Top up Rp10.000 via BTN App udah masuk.'));
      await tester.pumpAndSettle();

      expect(find.text('Uji Rule Parser'), findsOneWidget);
    });
  });
}