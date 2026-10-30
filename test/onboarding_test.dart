import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangku/data/database.dart';
import 'package:uangku/ui/dashboard_screen.dart';
import 'package:uangku/ui/onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('uangku/platform');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
      switch (call.method) {
        case 'isListenerEnabled':
          return true;
        case 'isBatteryOptimizationIgnored':
          return true;
        case 'requestPostNotificationsPermission':
          return true;
        case 'openNotificationAccessSettings':
          return true;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
  });

  group('T-015: Onboarding & Indikator Status Listener', () {
    testWidgets('Onboarding langkah 1 menampilkan privacy 100% lokal', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: OnboardingScreen())));
      await tester.pumpAndSettle();

      expect(find.text('100% Offline & Privat'), findsOneWidget);
      expect(find.text('Lewati'), findsOneWidget);
      expect(find.text('Lanjut'), findsOneWidget);
    });

    testWidgets('Onboarding lanjut ke langkah akses notifikasi', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: OnboardingScreen())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();

      expect(find.text('Akses Notifikasi Otomatis'), findsOneWidget);
      expect(find.text('Buka Pengaturan Akses Notifikasi'), findsOneWidget);
    });

    testWidgets('Onboarding langkah 3 menampilkan panduan whitelist baterai',
        (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: OnboardingScreen())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();

      expect(find.text('Optimasi Baterai (OEM)'), findsOneWidget);
      expect(find.text('Mulai Gunakan Uangku'), findsOneWidget);
    });

    testWidgets('StatusBanner hijau ketika listener & baterai aktif', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: MainScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Listener otomatis aktif (BTN & GoPay)'), findsOneWidget);
    });

    testWidgets('Pengaturan menampilkan status AKTIF untuk listener & baterai',
        (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: MainScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pengaturan'));
      await tester.pumpAndSettle();

      expect(find.text('Status Otomatisasi'), findsOneWidget);
      expect(find.text('Notification Access'), findsOneWidget);
      expect(find.text('Whitelist Baterai (OEM)'), findsOneWidget);
      expect(find.text('AKTIF'), findsNWidgets(2));
    });
  });
}
