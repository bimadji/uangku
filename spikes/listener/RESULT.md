# Spike T-004 — Plugin vs Bridge Kotlin Custom (batas 1 hari)

> Hasil: **Bridge Kotlin custom** dipilih (fallback: plugin bila bermasalah di T-011). Prasyarat T-011.
> Bukti kode: `spikes/listener/spike_listener_test.dart` — 3 test hijau (kontrak snake_case BSD §3, toleran camelCase, filter whitelist).

## Analisis Perbandingan

| Kriteria | Plugin `flutter_notification_listener 1.4.0` | Bridge Kotlin custom (~60–100 baris) |
|---|---|---|
| Whitelist filtering di OS level | Tidak langsung: semua notifikasi diteruskan ke Dart isolate, Dart yang memfilter. Boros baterai saat ada notifikasi dari WhatsApp/app ramai lain. | **Native di `onNotificationPosted`**: cek `sbn.packageName` sebelum sentuh EventChannel. Dart isolate tidak pernah bangun untuk notifikasi lain (NFR-03). |
| Integrasi MethodChannel lain | Plugin hanya handle listener; 4 MethodChannel platform di BSD §3 (`openNotificationAccessSettings`, `isListenerEnabled`, `openQuickCashActivity`, `isBatteryOptimizationIgnored`) tetap butuh bridge native sendiri. | **Satu file native**: listener + MethodChannel platform + stub QuickTile (T-023) dalam satu namespace `uangku/platform`. |
| Background isolate | Menggunakan `FlutterEngineCache` bawaan; terbukti jalan di banyak app | Mengikuti pattern official Flutter background execution (~50 baris Kotlin). Risiko: butuh pengujian di Android 13+ (Doze). |
| Dependensi | Third-party dependency aktif (Gradle 8.7, Kotlin 2.1), tapi maintainer independen | 0 dependensi eksternal; tidak rentan deprecation OS API. |

## Keputusan
**Bridge Kotlin custom sebagai jalur utama di T-011; plugin sebagai cadangan.**
Alasan:
1. **Efisiensi baterai (NFR-03)**: filter `packageName` harus di Kotlin. Membiarkan notifikasi non-Bale/GoPay membangunkan Dart isolate berkali-kali merusak target baterai.
2. **Kerapian arsitektur**: TRD §1 sudah mendesain 1 bridge native kecil untuk semua kebutuhan native (listener, tile, settings). Memakai plugin = punya dua bridge native terpisah.
3. Kontrak data Dart (BSD §3) tetap identik di kedua opsi; `NotificationPayload.fromMap` di `spikes/listener/spike_listener_test.dart` toleran format keduanya.

## Rencana Cadangan (Mitigasi Risiko IPD §5)
Jika saat implementasi T-011 di perangkat asli ditemukan masalah lifecycle isolate pada bridge custom, potong ke `flutter_notification_listener` dan tambahkan filter di Dart entrypoint.
