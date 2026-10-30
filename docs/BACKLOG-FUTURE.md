# Backlog Hal yang Dilewati (Pengembangan Masa Depan)

Dokumen ini adalah satu-satunya file yang diperbarui sebagai bagian dari laporan setiap tugas T-xxx. Setiap entri mencatat hal yang **sengaja atau terpaksa dilewati** saat mengerjakan tugas tersebut: fitur yang tidak dikerjakan, edge case yang belum ditangani, keputusan yang ditunda, TODO yang ditinggalkan di kode, asumsi yang belum terverifikasi, dan verifikasi manual yang belum dilakukan.

Aturan pemakaiannya ada di `docs/07-EXECUTION-PLAN.md` §1.3.

---

## T-005: Belajar Dart/Flutter dasar + template app di device
- Dilewati: Tugas ini adalah materi belajar pribadi (3–4 hari) dan **belum pernah dijalankan** — belum ada catatan belajar, dan beberapa bagian M0 (dasar Dart, Riverpod, arsitektur Flutter) belum dikuasai secara memadai dan terukur.
- Risiko: Kemungkinan besar ada gap pengetahuan yang akan muncul sebagai bug sulit dipahami di task berikutnya (T-016 s.d. T-020).
- Terkait: Prasyarat T-006 s.d. T-028 di `docs/07-EXECUTION-PLAN.md`.
- Saran: Jalankan saat ada jeda; tidak ada kode yang perlu diubah.

## T-016: Verifikasi listener pasca-reboot & whitelist baterai (M2.7) — BELUM DIJALANKAN
- Dilewati: Checklist §7.1 (reboot listener, whitelist baterai, notifikasi app lain diabaikan, notifikasi ganda tertahan dedup) **belum pernah dijalankan di perangkat fisik**. Emulator tidak dipakai karena tidak memadai (TRD §7).
- Risiko: Belum ada bukti listener bertahan setelah reboot maupun saat battery optimization aktif — ini prasyarat utama DoD M2 dan bisa membatalkan keputusan bridge custom (T-004).
- Terkait: `docs/07-EXECUTION-PLAN.md` §7.1, NFR-04, R-02, R-04.
- Saran: **Tugas manual untuk pengguna** — jalankan checklist di HP Redmi Note 13 Pro, laporkan hasilnya.

## T-019: Layar Detail/Koreksi Transaksi
- Dilewati: Kolom `note` **tidak pernah diisi dari QuickCashSheet** (hanya bisa diisi di layar koreksi), dan `dedup_hash` transaksi tunai tidak mengikuti `DedupService.computeHash`. Layar detail **tidak menampilkan cuplikan notifikasi asli** seperti yang ada di mockup Opsi A (referensi `docs/mockups/option-a/index.html`), dan tidak menampilkan sumber dana sebagai field read-only terpisah. Tidak ada konfirmasi tambahan bila nominal diubah menjadi 0 (tombol Simpan menolak, tapi tanpa pesan). Waktu transaksi ditampilkan sebagai teks biasa, bukan read-only field yang jelas.
- Risiko: Pengguna tidak bisa mengaudit apakah nominal yang diedit cocok dengan notifikasi aslinya (melemahkan tujuan FR-10). Dua sumber kebenaran format `dedup_hash` (otomatis vs tunai manual) akan menyulitkan statistik dedup dan migrasi skema.
- Terkait: `lib/ui/dashboard_screen.dart` (`TransactionDetailScreen`), FR-06, AFD §5, `docs/04-DBD.md` §6, `docs/mockups/option-a/index.html`.
- Saran: Panel "Teks notifikasi asli" masuk T-020 (karena `parser_logs` sudah menyimpan raw text); penyamaan format hash saat kolom `created_at` ditambahkan.

## T-025: Pakai app untuk keuangan nyata & catat kegagalan (M5.1) — BELUM DIMULAI
- Dilewati: Pemakaian nyata 2–4 minggu **belum dimulai**, sehingga metrik PRD §8 (rasio transaksi digital ≥ 90%, duplikat 0/minggu, rasio parse ≥ 90%) belum terukur. Perbandingan mingguan dengan mutasi Bale by BTN & GoPay belum pernah dilakukan.
- Risiko: DoD M5 dan keputusan "MVP selesai" tidak bisa dibuat tanpa data pemakaian nyata. Pattern parser yang sekarang mungkin hanya bekerja untuk 3 notifikasi yang sudah diamati.
- Terkait: `docs/01-PRD.md` §8, `docs/06-IPD.md` M5.
- Saran: **Tugas manual untuk pengguna** — mulai setelah listener terpasang dan otomatis (T-016 lulus).

---

## T-001: Setup repo + CI + branch protection
- Dilewati: Workflow CI hanya menjalankan `flutter pub get`, `flutter analyze`, `flutter test`, dan `flutter build apk --debug` — belum ada job `flutter build apk --release`, integration test, coverage report, maupun upload artifact APK.
- Risiko: Build rilis tidak pernah diverifikasi otomatis, jadi masalah signing/proguard hanya muncul saat rilis manual. Tidak ada artifact APK yang bisa diunduh langsung dari Actions.
- Terkait: `docs/07-EXECUTION-PLAN.md` T-001, `.github/workflows/ci.yml`.
- Saran: T-028 (perbaikan rilis) cocok untuk menambahkan build rilis + upload artifact; integration test masuk fase 2.

## T-002: Spike DB: drift vs Isar
- Dilewati: Perbandingan hanya dilakukan pada level toolchain dan 3 skenario uji, bukan benchmark performa (throughput insert/query) pada data skala nyata (~1.500 baris/tahun). Skema `parser_rules` dan `parser_logs` tidak diuji bersama drift.
- Risiko: Performa SQLite untuk 1.500 baris/tahun diperkirakan aman, tetapi belum terukur. Migration skenario upgrade skema tidak diuji (hanya seed idempotent).
- Terkait: `spikes/db_drift/`, `docs/05-BSD.md` §7 (Strategi Migrasi).
- Saran: Migrasi skema diuji saat pertama kali ada penambahan kolom (butuh keputusan pengguna: apakah tabel `transactions` di-backup sebelum migrasi).

## T-003: Spike state management: Riverpod vs Provider
- Dilewati: Perbandingan hanya pada state async sederhana (1 stream data), belum diuji state yang sangat sering berubah (rebuild UI per notifikasi) maupun state persisten lintas restart aplikasi.
- Risiko: Rebuild widget tree tiap notifikasi masuk belum diukur; kalau notifikasi sering datang bersamaan, performa UI bisa turun.
- Terkait: `spikes/state/`, `docs/02-TRD.md` §3.
- Saran: Diukur saat listener mulai aktif di perangkat nyata (T-016), lewat checklist performa.

## T-004: Spike listener: plugin vs bridge Kotlin custom
- Dilewati: Penilaian stabilitas background isolate dilakukan lewat **analisis kode sumber plugin**, bukan uji langsung di perangkat. Empat method `MethodChannel` BSD §3 belum diimplementasikan saat spike ini.
- Risiko: Kalau ternyata isolate plugin lebih stabil daripada bridge custom, keputusan T-004 salah dan T-011 perlu dikerjakan ulang.
- Terkait: `spikes/listener/RESULT.md`, keputusan spike §8.
- Saran: T-016 (verifikasi perangkat) menjadi pembuktian; jika listener mati setelah reboot, fallback plugin diaktifkan sesuai `spikes/listener/RESULT.md`.

## T-006: Skema DB + seed kategori idempotent
- Dilewati: Kolom `created_at` dan `rule_id` pada tabel `transactions` **belum ada** di skema drift, padahal keduanya tercantum di `docs/05-BSD.md` §1.1. Kolom `sort_order` untuk kategori di-seed dengan nilai `0` semua (belum ada urutan kategori yang bermakna). Kolom `categories.keywords` dibiarkan NULL (diisi di T-017). Retensi LRU 200 baris pada `parser_logs` (BSD §8) belum diimplementasikan.
- Risiko: Tidak bisa mengaudit kapan transaksi dibuat (hanya kapan terjadi), dan tidak bisa menelusuri rule mana yang menghasilkan transaksi — padahal `rule_id` adalah kolom audit yang diatur di BSD §6. `parser_logs` bisa tumbuh tanpa batas sehingga DB membengkak dan data sensitif menumpuk.
- Terkait: `lib/data/database.dart`, `docs/05-BSD.md` §1.1, §1.2, §6, §8.
- Saran: T-012 atau T-013 menambahkan `created_at` + `rule_id` (perlu migrasi skema v1 → v2 — keputusan pengguna: migrasi in-place atau reset data). Retensi LRU masuk T-020 (Log Parser) saat UI log dibangun.

## T-007: TransactionRepository: CRUD + agregasi
- Dilewati: Feed memakai `limit/offset` sederhana, bukan cursor-based pagination. Perhitungan periode minggu mengasumsikan **Senin** sebagai awal minggu (ISO-8601) tanpa opsi kustomisasi. Tidak ada agregasi per sumber (BTN/GoPay/Tunai) maupun per kategori untuk pemasukan — `expenseByCategory` hanya menghitung pengeluaran. Perbandingan hari/minggu/bulan memakai batas hari kalender lokal tanpa klausa zona waktu.
- Risiko: Feed panjang (5.000+ baris) akan lambat saat scroll karena offset besar. Pengguna yang terbiasa dengan minggu dimulai Minggu akan melihat angka minggu yang berbeda dari kebiasaan mereka. Chart pemasukan per kategori tidak tersedia.
- Terkait: `lib/data/transaction_repository.dart`, FR-08, FR-09.
- Saran: Cursor pagination bila data tumbuh; opsi hari awal minggu dan agregasi per sumber masuk fase 2 atau T-021/T-022.

## T-008: Dashboard sederhana + layar feed
- Dilewati: `CategoryDonutChart` **belum ada** di Dashboard (areanya baru berupa penanda, belum ada widget chart), tombol "Lihat Semua" di preview transaksi belum ada (hanya 5 item teratas tanpa navigasi), filter chip sumber di feed belum ada, dan tidak ada empty state/loading skeleton yang proper (loading hanya spinner `CircularProgressIndicator`). Angka nominal belum memakai `fontFeatures: tabularFigures` seperti DBD §4.
- Risiko: Dashboard belum memenuhi FR-08 penuh dan melenceng dari DBD §4 (angka rata). Preview transaksi yang terpotong 5 item tanpa jalan keluar navigasi — user harus pindah tab secara manual.
- Terkait: `lib/ui/dashboard_screen.dart`, FR-08, FR-09, `docs/04-DBD.md` §4, §5.
- Saran: T-021 (chart + periode), T-022 (filter sumber), T-024 (empty/loading/error + aksesibilitas) menutup semua ini.

## T-009: QuickCashSheet dari FAB
- Dilewati: Kolom `note` **tidak pernah diisi** dari sheet (hanya ada di layar koreksi T-019), dan `dedup_hash` untuk transaksi tunai dibuat dari timestamp milidetik (`cash-<millis>`) — bukan hash kanonikal `DedupService.computeHash` seperti transaksi otomatis. Tidak ada haptic pada saat memilih kategori (hanya saat menyimpan). Tidak ada konfirmasi nominal 0 / negatif (hanya disable tombol).
- Risiko: Format `dedup_hash` tunai berbeda dari otomatis, sehingga statistik dedup dan migrasi schema nanti harus menangani dua format. Dua input tunaiManual dalam milidetik yang sama (nyaris mustahil) bisa bentrok UNIQUE.
- Terkait: `lib/ui/dashboard_screen.dart` (`QuickCashSheet._save`), FR-07, NFR-05.
- Saran: Migrasi ke `DedupService.computeHash` saat `created_at` ditambahkan (T-012/T-013).

## T-011: NotificationListener (Kotlin) + EventChannel
- Dilewati: **Belum ada wiring dari `PlatformBridge.notificationStream` ke `ParserEngine`** — stream native sudah ada, tapi belum ada consumer Dart yang memprosesnya (itu pekerjaan T-012 dan seterusnya). Tidak ada background isolate: notifikasi hanya terkirim saat Flutter engine hidup (app berjalan atau service foreground). Tidak ada `onNotificationRemoved` handling, tidak ada `requestRebind`, dan tidak ada guard `sbn.isOngoing`/grup notifikasi. Method `openQuickCashActivity` di MethodChannel hanya mengembalikan `true` (belum membuka Activity — itu T-023).
- Risiko: **Jika app tidak sedang berjalan, notifikasi transaksi TIDAK akan tercatat** — ini pelanggaran utama FR-01/NFR-04 dan berarti DoD M2 belum terpenuhi. Notifikasi ongoing (mis. timer) bisa masuk log dan ikut diparse.
- Terkait: `android/app/src/main/kotlin/com/bimadji/uangku/MainActivity.kt`, `lib/services/platform_bridge.dart`, FR-01, NFR-03, NFR-04, `docs/05-BSD.md` §5 (background isolate).
- Saran: **Prioritas utama** — perlu keputusan pengguna: apakah versi MVP boleh hanya berjalan saat app terbuka, atau harus dipasang background isolate. Checklist T-016 (reboot) akan membuktikan.

## T-012: ParserEngine + parser_rules dari sampel aktual
- Dilewati: Pattern untuk **transaksi pengeluaran GoPay** (bayar/belanja QRIS) dan **transfer keluar Bale by BTN** belum dibuat karena sampel aslinya belum terkumpul. Nominal pada notifikasi Bale **tidak ada sama sekali** (hanya tipe & merchant), sehingga hasil parse untuk Bale bernilai `amount = 0` dan harus diisi manual. Tidak ada `event_time` group (waktu selalu dari `postTime` OS). Pencocokan regex mencoba teks body dulu lalu title (bukan title saja). Prioritas rule hanya diurutkan `desc` tanpa pengurutan stabil. Tidak ada validasi syntax regex saat rule disimpan (regex invalid diam-diam diabaikan saat parse).
- Risiko: Transaksi Bale otomatis akan tersimpan dengan nominal 0 (butuh koreksi manual tiap kali — berbeda dari target < 5 detik FR-07). Notifikasi belanja GoPay berstatus `failed` di log dan data hilang sampai pattern didaftarkan. Rule regex salah ketik tidak memberi umpan balik ke pengguna.
- Terkait: `lib/services/parser_engine.dart`, `parser_rules` di `docs/05-BSD.md` §1.3 & §5, OQ-01, OQ-02, FR-02, NFR-06.
- Saran: Pattern baru ditambahkan di T-020 (editor rule in-app) atau T-026 (kalibrasi) begitu sampel lengkap; pesan error regex invalid masuk T-020.

## T-013: DedupService + UNIQUE dedup_hash
- Dilewati: Toleransi 60 detik **bersifat statis** (tidak bisa diubah pengguna). Hash memakai SHA-256 `crypto` — dependency tambahan, bukan hash bawaan SDK Dart. Pengecekan window ±60 detik hanya membandingkan **merchant** yang persis sama setelah uppercase/trim; dua notifikasi duplikat dengan merchant berbeda (mis. "GEPREK MASZEH ITS" vs "Geprek Maszeh") tidak terdeteksi sebagai duplikat. Tidak ada dialog konfirmasi untuk kasus ambigu (dua transaksi sah dengan nominal & merchant sama < 60 detik) — transaksi kedua langsung tertahan.
- Risiko: Notifikasi duplikat yang berbeda ejaan merchant tetap menghasilkan dua transaksi. Dua pembayaran sah dengan nominal dan merchant identik dalam < 60 detik akan dianggap duplikat dan harus dipulihkan manual lewat Log Parser (yang belum ada — T-020).
- Terkait: `lib/services/dedup_service.dart`, FR-03, `docs/05-BSD.md` §4, R-02.
- Saran: Normalisasi merchant lebih agresif + dialog konfirmasi ambigu di T-020.

## T-014: Suite unit test parser penuh
- Dilewati: Fixture suite hanya berisi **3 sampel nyata** (GoPay Top-up, Bale QRIS, Bale Transfer Masuk) — belum ada fixture untuk (notifikasi duplikat nyata, notifikasi tertunda, notifikasi dalam bahasa lain, notifikasi dengan format merchant berbeda). Tidak ada skrip/tool bantu untuk menambah fixture dari file JSON mentah. Tidak ada uji property-based atau fuzzing regex. Tidak ada pengukuran NFR-02 (parsing < 10 ms) yang akurat — test memakai ambang 50 ms pada cold parse SQLite in-memory.
- Risiko: Regresi pattern baru (T-026) bisa lolos dari suite kalau formatnya berbeda dari 3 fixture yang ada. Claim "parse < 10 ms" belum benar-benar terukur pada kondisi device nyata dengan database berisi data.
- Terkait: `test/parser_fixtures_test.dart`, `docs/02-TRD.md` §7, NFR-02.
- Saran: Fixture baru otomatis ditambahkan tiap sampel T-010/T-025 masuk (T-026); benchmark NFR-02 diukur di perangkat nyata saat T-016.

## T-015: Onboarding izin + indikator status listener
- Dilewati: Onboarding **tidak memakai flag "sudah pernah melewati onboarding"** — penentuannya murni dari status izin listener, sehingga onboarding muncul lagi setiap kali izin dicabut. Tidak ada konfigurasi bahasa/region; mode gelap tidak ada (fase 2 sesuai DBD §3). Panduan whitelist baterai hanya **teks**, tanpa tombol deep-link ke halaman pengaturan OEM (hanya ada deep-link ke Notification Access). Izin `POST_NOTIFICATIONS` diminta tepat saat tombol "Lanjut" ditekan di langkah 1 — tanpa penjelasan sebelum system dialog. Tidak ada status listener yang di-refresh otomatis saat user kembali dari Pengaturan (hanya saat tombol "Perbaiki" ditekan atau saat app dibuka ulang). Banner hijau "Listener otomatis aktif" ditampilkan permanen di Dashboard.
- Risiko: `POST_NOTIFICATIONS` yang ditolak pengguna tidak punya alur permintaan ulang di Pengaturan — notifikasi interaktif FR-05 tidak akan bisa muncul selama izin tidak di-backup. Banner hijau permanen permanen memakan ruang vertikal di Dashboard kecil. Status izin yang berubah di luar app (user mencabut izin lewat Settings) tidak terupdate sampai app dibuka ulang.
- Terkait: `lib/ui/onboarding_screen.dart`, `lib/ui/dashboard_screen.dart`, `lib/main.dart`, FR-01, FR-05, NFR-01, `docs/03-AFD.md` §2, `docs/04-DBD.md` §3.
- Saran: Penambahan tombol permintaan ulang + refresh status saat `resume` masuk T-024 atau T-020 (layar Pengaturan sudah ada). Butuh keputusan pengguna apakah banner hijau permanen acceptable atau hanya muncul saat ada masalah.
