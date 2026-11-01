// Test T-035: kesegaran widget & status listener.

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangku/data/database.dart';
import 'package:uangku/services/widget_sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('home_widget');
  late List<MethodCall> calls;
  late AppDatabase db;

  setUp(() async {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    db = AppDatabase(NativeDatabase.memory());
    await db.seedCategories();
  });

  tearDown(() async {
    await db.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<int> insertExpense(int amount, {int? atMs}) async {
    final cat = (await db.select(db.categories).get())
        .firstWhere((c) => c.name == 'Makanan & Minuman');
    return db.into(db.transactions).insert(TransactionsCompanion.insert(
          amount: amount,
          type: TxType.expense,
          categoryId: cat.id,
          source: TxSource.BTN,
          origin: TxOrigin.auto,
          occurredAt: atMs ?? DateTime.now().millisecondsSinceEpoch,
          dedupHash: 'h-$amount-${atMs ?? 0}',
        ));
  }

  group('T-035: syncWidget (DBD §7)', () {
    test('mengirim total pengeluaran hari ini ke widget', () async {
      await insertExpense(20000);
      await insertExpense(7000);

      await syncWidget(db);

      final save = calls.firstWhere((c) => c.method == 'saveWidgetData');
      expect(save.arguments['data'], 'Rp 27.000');
      expect(calls.any((c) => c.method == 'updateWidget'), isTrue);
    });

    test('pengeluaran kemarin tidak ikut dihitung (periode hari)', () async {
      final yesterday = DateTime.now()
          .subtract(const Duration(days: 1))
          .millisecondsSinceEpoch;
      await insertExpense(50000, atMs: yesterday);
      await insertExpense(5000);

      await syncWidget(db);

      final save = calls.firstWhere((c) => c.method == 'saveWidgetData');
      expect(save.arguments['data'], 'Rp 5.000');
    });

    test('tanpa transaksi mengirim Rp 0', () async {
      await syncWidget(db);
      final save = calls.firstWhere((c) => c.method == 'saveWidgetData');
      expect(save.arguments['data'], 'Rp 0');
    });

    test('dipanggil ulang setelah transaksi baru memperbarui angka', () async {
      await insertExpense(10000);
      await syncWidget(db);
      expect(
        calls.lastWhere((c) => c.method == 'saveWidgetData').arguments['data'],
        'Rp 10.000',
      );

      await insertExpense(15000);
      await syncWidget(db);
      expect(
        calls.lastWhere((c) => c.method == 'saveWidgetData').arguments['data'],
        'Rp 25.000',
      );
    });
  });
}