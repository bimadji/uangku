import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notifikasi interaktif setelah transaksi otomatis tersimpan (FR-05, AFD §3).
/// Dua aksi: [Ubah Kategori] (deep-link ke Detail/Koreksi) dan [Abaikan]
/// (tutup notifikasi, transaksi tetap tersimpan).
class LocalNotifService {
  LocalNotifService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const String channelId = 'uangku_transaksi';
  static const String actionEdit = 'edit_category';
  static const String actionIgnore = 'ignore';

  /// Callback saat notifikasi/tombol disentuh: (txId, actionId).
  Future<void> Function(int txId, String? actionId)? onAction;

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      settings: const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (resp) {
        final id = int.tryParse(resp.payload ?? '');
        if (id != null) onAction?.call(id, resp.actionId);
      },
      onDidReceiveBackgroundNotificationResponse: null,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          channelId,
          'Transaksi Tercatat',
          description: 'Konfirmasi transaksi otomatis dari BTN & GoPay',
          importance: Importance.defaultImportance,
        ));

    await _requestPermission();
  }

  Future<void> _requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Tampilkan notifikasi konfirmasi untuk transaksi [txId].
  Future<void> showTransaction({
    required int txId,
    required String merchant,
    required int amount,
    required String categoryName,
  }) async {
    final amountText = amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );

    await _plugin.show(
      id: txId,
      title: '$merchant • Rp $amountText',
      body: 'Tercatat sebagai $categoryName',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Transaksi Tercatat',
          channelDescription: 'Konfirmasi transaksi otomatis dari BTN & GoPay',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          actions: const [
            AndroidNotificationAction(actionEdit, 'Ubah Kategori'),
            AndroidNotificationAction(
              actionIgnore,
              'Abaikan',
              cancelNotification: true,
            ),
          ],
        ),
      ),
      payload: '$txId',
    );
  }
}
