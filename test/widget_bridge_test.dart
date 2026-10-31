import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangku/services/widget_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('home_widget');

  group('T-023: WidgetBridge (FR-07, DBD §7)', () {
    late List<MethodCall> calls;

    setUp(() {
      calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        return true;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('updateExpenseToday mengirim nominal berformat Rp ribuan lalu update widget',
        () async {
      await WidgetBridge.updateExpenseToday(47000);

      final save = calls.firstWhere((c) => c.method == 'saveWidgetData');
      expect(save.arguments['id'], WidgetBridge.keyExpenseToday);
      expect(save.arguments['data'], 'Rp 47.000');

      final update =
          calls.firstWhere((c) => c.method == 'updateWidget');
      expect(update.arguments['android'], 'UangkuWidgetProvider');
    });

    test('format ribuan benar untuk nominal besar', () async {
      await WidgetBridge.updateExpenseToday(1500000);
      final save = calls.firstWhere((c) => c.method == 'saveWidgetData');
      expect(save.arguments['data'], 'Rp 1.500.000');
    });

    test('quickCashUri konsisten dengan yang dipakai widget & tile', () {
      expect(WidgetBridge.quickCashUri, 'uangku://quick-cash');
    });

    test('updateWidget memakai androidName provider yang terdaftar di manifest',
        () async {
      await WidgetBridge.updateExpenseToday(1000);
      final update = calls.firstWhere((c) => c.method == 'updateWidget');
      expect(update.arguments['android'], contains('UangkuWidgetProvider'));
    });
  });
}
