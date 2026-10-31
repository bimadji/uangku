import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangku/data/database.dart';
import 'package:uangku/ui/dashboard_screen.dart';
import 'package:uangku/ui/states.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: MainScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('T-024: State kosong/loading/error (DBD §8)', () {
    testWidgets('Dashboard empty state memberi petunjuk cara mulai', (tester) async {
      await pumpApp(tester);
      expect(find.byType(EmptyState), findsWidgets);
      expect(find.textContaining('Tap + untuk catat pengeluaran tunai.'), findsOneWidget);
    });

    testWidgets('Feed empty state menyebut pilihan filter', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Transaksi'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Coba pilih filter lain'), findsOneWidget);
    });

    testWidgets('EmptyState menampilkan tombol aksi bila diberikan', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmptyState(
            message: 'Kosong',
            actionLabel: 'Tambah',
            onAction: () => tapped = true,
          ),
        ),
      ));

      expect(find.text('Kosong'), findsOneWidget);
      await tester.tap(find.text('Tambah'));
      expect(tapped, isTrue);
    });

    testWidgets('ErrorState menampilkan tombol coba lagi', (tester) async {
      var retried = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ErrorState(message: 'Gagal baca', onRetry: () => retried = true),
        ),
      ));

      expect(find.text('Gagal baca'), findsOneWidget);
      await tester.tap(find.text('Coba lagi'));
      expect(retried, isTrue);
    });
  });

  group('T-024: Aksesibilitas (DBD §9)', () {
    testWidgets('Nominal memakai tabular figures', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: TabularNumber(text: 'Rp 25.000'),
        ),
      ));

      final text = tester.widget<Text>(find.text('Rp 25.000'));
      expect(text.style?.fontFeatures, isNotNull);
      expect(text.style!.fontFeatures!.first.toString(), contains('tnum'));
    });

    testWidgets('Tanda + dan - selalu menyertai nominal', (tester) async {
      await pumpApp(tester);
      // CashFlowCard menampilkan "+ Rp ..." dan "- Rp ..." (FR-09/DBD §9)
      expect(find.textContaining('+ Rp'), findsWidgets);
      expect(find.textContaining('- Rp'), findsWidgets);
    });

    testWidgets('Tombol keypad punya label semantik yang bisa dibaca screen reader',
        (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Angka 5'), findsOneWidget);
    });

    testWidgets('Tombol backspace keypad punya label semantik', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Hapus digit terakhir'), findsOneWidget);
    });

    testWidgets('Target sentuh keypad minimal 48dp', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Ukur kotak tombol keypad (mockup: Container 48dp di dalam Semantics)
      final keyBox = find.ancestor(
        of: find.text('5'),
        matching: find.byType(Container),
      );
      final size = tester.getSize(keyBox.first);
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });
}
