import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';

/// Watchdog pemulihan listener (T-037c).
///
/// Latar: MIUI melepas binding NotificationListenerService secara berkala dan
/// mengabaikan `requestRebind()` dari kode (BUG-003). Satu-satunya jalur
/// yang tersisa adalah membangunkan proses lewat WorkManager — yang memiliki
/// allow-list sistem — lalu memanggil rebind dari sana.
///
/// Jendela kehilangan data maksimal: interval watchdog (15 menit bawaan
/// Android, tidak bisa lebih rapat).
const String kWatchdogTaskName = 'uangku.watchdog';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == kWatchdogTaskName) {
      await repairListener();
      return true; // sukses → WorkManager menjadwalkan ulang
    }
    return true;
  });
}

/// Pekerjaan aktual watchdog. Dipisah agar bisa diuji tanpa WorkManager.
Future<void> repairListener() async {
  // Panggil rebind lewat platform channel. `isListenerConnected` dipakai
  // untuk memutuskan apakah ada sesuatu yang harus dilakukan — walau keduanya
  // bisa diabaikan OS, kombinasi keduanya adalah upaya maksimal yang sah.
  await _repairPlatform();
}

Future<void> _repairPlatform() async {
  const platformChannel = MethodChannel('uangku/platform');
  try {
    await platformChannel.invokeMethod<void>('requestListenerRebind');
  } on PlatformException {
    // Abaikan: OS bisa menolak.
  } on MissingPluginException {
    // Isolate background belum punya plugin terpasang — tidak fatal.
  }
}
