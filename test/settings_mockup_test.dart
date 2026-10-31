// Test T-032: Pengaturan sesuai mockup option-a.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:uangku/data/database.dart';
import 'package:uangku/ui/app_theme.dart';
import 'package:uangku/ui/dashboard_screen.dart';
import 'package:uangku/ui/parser_log_screen.dart';

void main() {
  Future<void> pumpSettings(WidgetTester tester, {bool listener = true, bool battery = true}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory())),
          listenerStatusProvider.overrideWith((_) async => listener),
          batteryStatusProvider.overrideWith((_) async => battery),
        ],
        child: MaterialApp(theme: buildAppTheme(), home: const MainScreen()),
      ),
    );
    await tester.pumpAndSettle();
    // Pindah ke tab Pengaturan
    await tester.tap(find.text('Pengaturan'));
    await tester.pumpAndSettle();
  }

  group('T-032: Pengaturan sesuai mockup option-a', () {
    testWidgets('Judul section adalah "Status listener hardware" (mockup)',
        (tester) async {
      await pumpSettings(tester);
      expect(find.text('Status listener hardware'), findsOneWidget);
    });

    testWidgets('Menampilkan baris Notification Access & Whitelist Baterai dengan badge pill',
        (tester) async {
      await pumpSettings(tester, listener: true, battery: false);

      expect(find.text('Notification Access'), findsOneWidget);
      expect(find.text('Whitelist Baterai (OEM)'), findsOneWidget);

      // Listener aktif -> AKTIF hijau; Baterai belum -> CEK SETELAN kuning
      expect(find.text('AKTIF'), findsOneWidget);
      expect(find.text('CEK SETELAN'), findsOneWidget);
    });

    testWidgets('Menu Log Notifikasi Mentah & Regex membuka ParserLogScreen',
        (tester) async {
      await pumpSettings(tester);

      expect(find.text('Log Notifikasi Mentah & Regex'), findsOneWidget);
      await tester.tap(find.text('Log Notifikasi Mentah & Regex'));
      await tester.pumpAndSettle();

      expect(find.byType(ParserLogScreen), findsOneWidget);
    });

    testWidgets('Privacy Assurance card tampil dengan pesan 100% Offline',
        (tester) async {
      await pumpSettings(tester);

      expect(find.text('100% Offline & Privat'), findsOneWidget);
      expect(find.textContaining('tidak meminta izin INTERNET'), findsOneWidget);
    });
  });
}
