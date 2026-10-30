import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangku/services/platform_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlatformBridge Unit Tests (BSD §3 Kontrak)', () {
    const channel = MethodChannel('uangku/platform');

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'isListenerEnabled':
            return true;
          case 'openNotificationAccessSettings':
            return true;
          case 'isBatteryOptimizationIgnored':
            return false;
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('isListenerEnabled memanggil platform channel dan parse boolean',
        () async {
      final enabled = await PlatformBridge.isListenerEnabled();
      expect(enabled, isTrue);
    });

    test('openNotificationAccessSettings memanggil method channel sukses',
        () async {
      final success = await PlatformBridge.openNotificationAccessSettings();
      expect(success, isTrue);
    });

    test('isBatteryOptimizationIgnored mengembalikan status boolean',
        () async {
      final ignored = await PlatformBridge.isBatteryOptimizationIgnored();
      expect(ignored, isFalse);
    });

    test('RawNotification.fromMap memetakan snake_case dan fallback aman', () {
      final raw = RawNotification.fromMap({
        'package_name': 'id.co.btn.mobilebanking.android',
        'title': 'Payment GEPREK MASZEH ITS Successful',
        'text': '',
        'post_time': 1793340262715,
        'key': 'notif-btn-1',
      });

      expect(raw.packageName, 'id.co.btn.mobilebanking.android');
      expect(raw.title, contains('GEPREK'));
      expect(raw.text, isEmpty);
      expect(raw.postTime, 1793340262715);
      expect(raw.key, 'notif-btn-1');
    });

    test('RawNotification.fromMap menangani payload GoPay lengkap', () {
      final raw = RawNotification.fromMap({
        'package_name': 'com.gojek.gopay',
        'title': 'Top up berhasil',
        'text': 'Top up Rp10.000 via BTN Internet Banking App udah masuk.',
        'post_time': 1793354827288,
      });

      expect(raw.packageName, 'com.gojek.gopay');
      expect(raw.text, contains('Rp10.000'));
      expect(raw.key, isNull);
    });
  });
}
