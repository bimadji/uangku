// Tambahan fixture sampel T-016: Pembelian GoPay dari BTN
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangku/data/database.dart';
import 'package:uangku/services/parser_engine.dart';
import 'package:uangku/services/platform_bridge.dart';

void main() {
  test('Parse BTN Pembelian GoPay Berhasil → expense, merchant GoPay', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final parser = ParserEngine(db);
    await parser.seedInitialRules();

    final result = await parser.parse(const RawNotification(
      packageName: 'id.co.btn.mobilebanking.android',
      title: 'Pembelian GoPay Berhasil',
      text: '',
      postTime: 1793355000000,
    ));

    expect(result, isNotNull);
    expect(result!.appLabel, 'BTN');
    expect(result.txType, TxType.expense);
    await db.close();
  });
}
