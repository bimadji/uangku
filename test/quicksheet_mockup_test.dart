// Test T-033: QuickCashSheet sesuai mockup option-a.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangku/data/database.dart';
import 'package:uangku/ui/app_theme.dart';
import 'package:uangku/ui/dashboard_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.seedCategories(); // chip kategori butuh seed FR-11
  });
  tearDown(() => db.close());

  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(theme: buildAppTheme(), home: const MainScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
  }

  group('T-033: QuickCashSheet sesuai mockup', () {
    testWidgets('Header sheet menampilkan judul + penanda < 5 Detik', (tester) async {
      await openSheet(tester);
      expect(find.text('Catat Tunai Cepat'), findsOneWidget);
      expect(find.text('< 5 Detik'), findsOneWidget);
    });

    testWidgets('Urutan mockup: chip kategori muncul SEBELUM keypad', (tester) async {
      await openSheet(tester);

      final chipY = tester.getTopLeft(find.text('PILIH KATEGORI (1 TAP)')).dy;
      final keypadY = tester.getTopLeft(find.text('1')).dy;

      expect(chipY, lessThan(keypadY),
          reason: 'Mockup menaruh chip kategori sebelum keypad');
    });

    testWidgets('Label kategori berisi nama default FR-11', (tester) async {
      await openSheet(tester);
      expect(find.text('Makanan & Minuman'), findsOneWidget);
      expect(find.text('Transportasi'), findsOneWidget);
    });

    testWidgets('Toggle Masuk mengganti chip ke kategori pemasukan', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Uang Saku'), findsOneWidget);
      expect(find.text('Makanan & Minuman'), findsNothing);
    });

    testWidgets('Tombol simpan berlabel sesuai tipe transaksi', (tester) async {
      await openSheet(tester);
      expect(find.text('Simpan Transaksi (Tunai)'), findsOneWidget);

      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();
      expect(find.text('Simpan Transaksi (Masuk)'), findsOneWidget);
    });

    testWidgets('Keypad punya tombol 0-9, 00, dan backspace (mockup)', (tester) async {
      await openSheet(tester);

      for (final k in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '00']) {
        expect(find.text(k), findsWidgets, reason: 'Tombol $k harus ada');
      }
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
    });

    testWidgets('Nominal awal Rp 0 dan tombol simpan disabled', (tester) async {
      await openSheet(tester);

      expect(find.text('Rp 0'), findsOneWidget);
      final btn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Simpan Transaksi (Tunai)'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('Mengetik nominal memperbarui display', (tester) async {
      await openSheet(tester);

      for (final k in ['5', '0', '0', '0']) {
        await tester.ensureVisible(find.text(k).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text(k).last);
        await tester.pump();
      }
      expect(find.text('Rp 5000'), findsOneWidget);
    });
  });
}