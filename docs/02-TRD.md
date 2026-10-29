# 02 — Technical Requirements Document (TRD): Uangku

> Sumber kebenaran: `brainstorm-finance-app.md`, `docs/01-PRD.md`.

## 1. Arsitektur

**Flutter (Dart)** sebagai satu-satunya layer aplikasi; satu bridge native **Kotlin** kecil (~50–100 baris) untuk `NotificationListenerService` dan widget/quick tile.

```
┌─────────────────────────────────────────────────────┐
│ Android OS                                          │
│  ┌───────────────────────────┐  ┌────────────────┐  │
│  │ UangkuNotificationListener│  │ QuickTile /    │  │
│  │ (Kotlin, extends          │  │ HomeWidget     │  │
│  │  NotificationListener     │  │ (Kotlin stub)  │  │
│  │  Service)                 │  │                │  │
│  └────────────┬──────────────┘  └───────┬────────┘  │
│               │ EventChannel /           │ Method    │
│               │ broadcast (onNewNotif)   │ Channel   │
│  ┌────────────▼──────────────────────────▼────────┐  │
│  │ Flutter Layer (Dart)                           │  │
│  │  - NotifIngestService (router notifikasi)      │  │
│  │  - ParserEngine (regex, config JSON)           │  │
│  │  - DedupService                                │  │
│  │  - CategorizerService (rule keyword/merchant)  │  │
│  │  - LocalNotifService (notifikasi interaktif)   │  │
│  │  - TransactionRepository (DB lokal)            │  │
│  │  - Dashboard UI (dashboard, feed, koreksi,     │  │
│  │    parser debug, pengaturan)                   │  │
│  └────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

**Alur utama**: OS kirim notifikasi → Kotlin listener terima → kirim payload (`packageName`, `title`, `text`, `postTime`) ke Dart → ParserEngine cocokkan dengan rule per-`packageName` → bila match: DedupService → CategorizerService → simpan ke DB → notifikasi interaktif Uangku; bila tidak match: catat raw text ke ParserLog (status `gagal`).

## 2. Komponen dan Tanggung Jawab

| Komponen | Layer | Tanggung jawab | Req |
|----------|-------|----------------|-----|
| `UangkuNotificationListener` | Kotlin | Extend `NotificationListenerService`; filter `packageName` Bale by BTN & GoPay; forward ke Dart; tetap hidup tanpa UI. | FR-01 |
| `NotifIngestService` | Dart | Router notifikasi masuk; delegasi ke ParserEngine; sumber ParserLog. | FR-02, FR-10 |
| `ParserEngine` | Dart | Eksekusi rule regex per-app dari konfigurasi JSON; ekstrak tipe/nominal/merchant/waktu; status sukses/gagal. | FR-02, FR-06 (NFR-06) |
| `DedupService` | Dart | Cek duplikat berdasarkan hash (waktu ±toleransi, nominal, sumber, merchant). | FR-03 |
| `CategorizerService` | Dart | Match keyword/merchant → kategori default (FR-11). | FR-04 |
| `LocalNotifService` | Dart | Tampilkan notifikasi interaktif (Ubah Kategori / Abaikan); deep-link ke layar koreksi. | FR-05 |
| `TransactionRepository` | Dart | CRUD transaksi, feed, agregasi dashboard; akses DB lokal. | FR-08, FR-09 |
| `QuickCashWidget / QuickTile` | Kotlin + Dart | Widget home screen / quick settings tile → buka Activity input cepat → hasil kirim ke Dart (MethodChannel). | FR-07 |
| `ParserRuleStore` | Dart | Simpan/muat rule regex (JSON editable in-app). | FR-10 |
| Dashboard UI | Dart | Kartu arus kas, chart kategori, feed, koreksi, parser debug, pengaturan. | FR-08, FR-09, FR-06, FR-10 |

## 3. Pilihan Library

| Kebutuhan | Kandidat | Catatan |
|-----------|----------|---------|
| Listener notifikasi | `flutter_notification_listener` **atau** plugin custom + bridge Kotlin | Bridge custom dipilih jika plugin tidak stabil di target Android; keputusan final saat development (A-04). |
| DB lokal | `drift` (SQLite) **atau** Isar | Keduanya 100% lokal; final saat development (A-04). Skema lihat `05-BSD.md`. |
| State management | Riverpod atau Provider | Sederhana, cocok skala MVP. |
| Chart | `fl_chart` | Donut/bar sederhana. |
| Widget home screen | `home_widget` | Untuk input cepat tunai. |
| Quick settings tile | platform channel (Kotlin `TileService`) | Tidak ada plugin matang; stub Kotlin kecil. |
| Notifikasi interaktif | `flutter_local_notifications` | Tombol aksi + payload deep-link. |
| Parsing waktu/idr | regex + `intl` | Format `Rp 25.000` dan tanggal notifikasi. |

## 4. Izin Android

| Izin/Komponen | Tujuan | Cara minta |
|---------------|--------|------------|
| `BIND_NOTIFICATION_LISTENER_SERVICE` (manifest) + grant di Settings "Notification access" | Menangkap notifikasi Bale by BTN & GoPay (FR-01) | Onboarding → dialog penjelasan → deep-link `Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS`; cek status via `NotificationManagerCompat.getEnabledListenerPackages()`. |
| `POST_NOTIFICATIONS` (API 33+) | Menampilkan notifikasi interaktif Uangku (FR-05) | Runtime permission saat onboarding. |
| `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` | **Tidak dipakai.** Tidak ada polling terjadwal. | — |
| `INTERNET` | **Tidak diminta.** Aplikasi 100% offline (NFR-01). | — |
| Battery optimization exemption | Menjaga listener tetap hidup (R-02, R-04) | Panduan manual onboarding (dialog + deep-link setting); permintaan otomatis `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` rawan Play Store — dihindari. |

**Tidak diminta**: `READ_SMS`, `AccessibilityService`, `READ_CONTACTS`, akses penyimpanan luas (A-05: tidak dipublikasikan ke Play Store di fase MVP, tetapi desain izin tetap dijaga minimal).

## 5. Strategi Background / Battery

- Listener adalah **service OS event-driven**: hanya aktif saat ada notifikasi; tanpa polling, tanpa alarm, tanpa wakelock berulang (NFR-03).
- Pemrosesan notifikasi dijalankan cepat (< 10 ms parse, NFR-02); tulis DB sinkron saat event — tidak butuh background task panjang.
- Isolasi OEM (MIUI, ColorOS, dll. yang mematikan service): indikator status listener di Pengaturan + panduan whitelist baterai saat onboarding (R-04).
- Jika notifikasi tiba saat Flutter engine tidak jalan: plugin listener meng-handle via background isolate/Dart entrypoint terpisah; bila plugin kandidat tidak mendukung, fallback broadcast ke engine yang di-restart ringan — keputusan final saat development, tercatat di IPD sebagai task risiko.
- Dedup menahan dampak notifikasi tertunda/ganda (R-02).

## 6. Keamanan dan Privasi

- **Tidak ada jaringan**: tidak diminta izin `INTERNET`; tidak ada SDK analitik/iklan (NFR-01).
- **Data tetap di perangkat**: DB lokal di app-private storage (`/data/data/<pkg>/`), tidak di shared storage.
- **Raw text notifikasi** (ParserLog) berisi potensi info sensitif: disimpan lokal, dibatasi jumlah baris (retensi mis. 200 entri, LRU), bisa dihapus pengguna dari layar debug.
- **Tidak ada logging ke sistem log (Logcat)** untuk konten transaksi di build rilis.
- Tanpa akun/login; tanpa backup otomatis cloud (backup = fase 2, terenkripsi).
- APK tidak di-share; app-private storage mencegah akses app lain tanpa root.

## 7. Strategi Testing

| Level | Cakupan |
|-------|---------|
| Unit test `ParserEngine` | Suite sampel raw notifikasi asli (dari perangkat pengguna) per app: Bale by BTN, GoPay; per tipe: QRIS, transfer keluar/masuk, top-up, biaya admin. Format belum diketahui — sampel dikumpulkan dulu (OQ-01, OQ-02); suite dibangun dari sampel aktual, bukan format rekaan. |
| Unit test `DedupService` | Notifikasi ganda identik, hampir-identik (beda detik), urutan terbalik. |
| Unit test `CategorizerService` | Keyword/merchant → kategori benar; fallback `Lainnya`. |
| Widget test UI | Dashboard render agregasi benar; input cepat tunai; koreksi kategori. |
| Integration test perangkat asli | Listener aktif setelah reboot; notifikasi real Bale by BTN/GoPay tersimpan; whitelist baterai. Emulator tidak cukup (butuh app bank asli). |

## 8. Batasan Teknis

1. **Format notifikasi tidak terdokumentasi** — parser hanya sebaik sampel yang dikumpulkan; wajib ada jalur kalibrasi (FR-10).
2. **Notifikasi bukan sumber kebenaran transaksional** — bisa tertunda, ganda, atau tidak terkirim; aplikasi tidak menjamin rekap 100% (target ≥ 90%, PRD metrik).
3. **Listener bisa dimatikan OS/OEM** tanpa sepengetahuan pengguna — butuh indikator status.
4. **Tanpa INTERNET** berarti tidak ada pembaruan rule remote; update rule hanya via in-app editor (FR-10) atau update APK.
5. **Flutter background isolate** untuk listener bergantung kapabilitas plugin; risiko dikendalikan lewat task khusus di IPD.
6. MVP single-device, tanpa sinkronisasi; DB skema dirancang siap migrasi (lihat `05-BSD.md`).
