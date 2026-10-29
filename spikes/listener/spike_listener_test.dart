// Spike T-004: Listener Notifikasi — kontrak bridge Dart.
// Plugin: flutter_notification_listener 1.4.0 (Kotlin + FlutterEngineCache).
// Custom bridge: alternatif ~60 baris Kotlin (BSD §3 kontrak).
//
// CATATAN EKSKLUSI SPIKE:
// - Tanpa pattern parser regex, tanpa asumsi format notifikasi (OQ-01/OQ-02).
// - Memverifikasi decoding kontrak Dart dari payload event saja.

import 'package:flutter_test/flutter_test.dart';

/// Kontrak payload event sesuai BSD §3:
/// Kotlin -> Dart via EventChannel / callback `Map<String, dynamic>`
class NotificationPayload {
  const NotificationPayload({
    required this.packageName,
    required this.title,
    required this.text,
    required this.postTime,
    this.key,
  });

  factory NotificationPayload.fromMap(Map<dynamic, dynamic> map) {
    return NotificationPayload(
      packageName: map['package_name'] as String? ??
          map['packageName'] as String? ??
          '',
      title: map['title'] as String? ?? '',
      text: map['text'] as String? ?? '',
      postTime: (map['post_time'] ?? map['postTime'] ?? 0) as int,
      key: map['key'] as String?,
    );
  }

  final String packageName;
  final String title;
  final String text;
  final int postTime;
  final String? key;
}

/// Filter whitelist packageName di sisi Dart (bila Kotlin meneruskan semua)
/// atau verifikasi filter Kotlin. Whitelist diisi di M2 setelah T-010.
bool isAllowedPackage(String pkg, Set<String> whitelist) =>
    whitelist.contains(pkg);

void main() {
  group('Kontrak Payload Notification (BSD §3)', () {
    test('decode map dari Kotlin bridge (snake_case)', () {
      final payload = NotificationPayload.fromMap({
        'package_name': 'com.example.bank',
        'title': 'Bank Test',
        'text': 'Transaksi berhasil Rp 25.000',
        'post_time': 1730000000000,
        'key': 'notif-123',
      });
      expect(payload.packageName, 'com.example.bank');
      expect(payload.text, contains('25.000'));
      expect(payload.postTime, 1730000000000);
    });

    test('toleran camelCase dari plugin kandidat', () {
      final payload = NotificationPayload.fromMap({
        'packageName': 'com.example.ewallet',
        'title': 'E-Wallet',
        'text': 'Top up 50000',
        'postTime': 1730000000000,
      });
      expect(payload.packageName, 'com.example.ewallet');
      expect(payload.postTime, 1730000000000);
    });

    test('filter whitelist paket menolak aplikasi lain', () {
      const whitelist = {'com.btn.bale', 'com.gojek.app'};
      expect(isAllowedPackage('com.btn.bale', whitelist), isTrue);
      expect(isAllowedPackage('com.whatsapp', whitelist), isFalse);
    });
  });
}
