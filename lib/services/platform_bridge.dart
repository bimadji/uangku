import 'dart:async';
import 'package:flutter/services.dart';

/// Kontrak data event notifikasi dari Kotlin (BSD §3)
class RawNotification {
  const RawNotification({
    required this.packageName,
    required this.title,
    required this.text,
    required this.postTime,
    this.key,
  });

  factory RawNotification.fromMap(Map<dynamic, dynamic> map) {
    return RawNotification(
      packageName: map['package_name'] as String? ?? '',
      title: map['title'] as String? ?? '',
      text: map['text'] as String? ?? '',
      postTime: (map['post_time'] ?? 0) as int,
      key: map['key'] as String?,
    );
  }

  final String packageName;
  final String title;
  final String text;
  final int postTime;
  final String? key;
}

class PlatformBridge {
  static const MethodChannel _platformChannel =
      MethodChannel('uangku/platform');
  static const EventChannel _eventChannel =
      EventChannel('uangku/notif_events');

  /// Membuka halaman Pengaturan Notification Access OS (FR-01)
  static Future<bool> openNotificationAccessSettings() async {
    final result = await _platformChannel
        .invokeMethod<bool>('openNotificationAccessSettings');
    return result ?? false;
  }

  /// Mengecek apakah Uangku sudah diizinkan membaca notifikasi
  static Future<bool> isListenerEnabled() async {
    final result =
        await _platformChannel.invokeMethod<bool>('isListenerEnabled');
    return result ?? false;
  }

  /// Mengecek status battery optimization whitelist
  static Future<bool> isBatteryOptimizationIgnored() async {
    final result = await _platformChannel
        .invokeMethod<bool>('isBatteryOptimizationIgnored');
    return result ?? false;
  }

  /// Meminta izin runtime POST_NOTIFICATIONS (Android 13+, FR-05)
  static Future<bool> requestPostNotificationsPermission() async {
    final result = await _platformChannel
        .invokeMethod<bool>('requestPostNotificationsPermission');
    return result ?? false;
  }

  /// Stream notifikasi masuk secara real-time dari OS
  static Stream<RawNotification> get notificationStream {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) => RawNotification.fromMap(event as Map<dynamic, dynamic>));
  }
}
