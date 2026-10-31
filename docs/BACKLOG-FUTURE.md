# Backlog Hal yang Dilewati (Pengembangan Masa Depan)

Dokumen ini adalah satu-satunya file yang diperbarui sebagai bagian dari laporan setiap tugas T-xxx. Setiap entri mencatat hal yang **sengaja atau terpaksa dilewati** saat mengerjakan tugas tersebut: fitur yang tidak dikerjakan, edge case yang belum ditangani, keputusan yang ditunda, TODO yang ditinggalkan di kode, asumsi yang belum terverifikasi, dan verifikasi manual yang belum dilakukan.

Aturan pemakaiannya ada di `docs/07-EXECUTION-PLAN.md` §1.3.

---

## T-005: Belajar Dart/Flutter dasar + template app di device
- Dilewati: Tugas ini adalah materi belajar pribadi (3–4 hari) dan **belum pernah dijalankan** — belum ada catatan belajar, dan beberapa bagian M0 (dasar Dart, Riverpod, arsitektur Flutter) belum dikuasai secara memadai dan terukur.
- Risiko: Kemungkinan besar ada gap pengetahuan yang akan muncul sebagai bug sulit dipahami di task berikutnya (T-016 s.d. T-020).
- Terkait: Prasyarat T-006 s.d. T-028 di `docs/07-EXECUTION-PLAN.md`.
- Saran: Jalankan saat ada jeda; tidak ada kode yang perlu diubah.

## T-016: Verifikasi listener pasca-reboot & whitelist baterai (M2.7) — TERVERIFIKASI SEBAGIAN
- Dilewati: Uji bertahan setelah **reboot penuh tanpa pernah membuka app** dan uji **ketahanan baterai 24 jam** belum selesai dijalankan. Verifikasi baru membuktikan: (1) listener berhasil menerima notifikasi dan menyimpan transaksi ke SQLite saat app berjalan, (2) notifikasi otomatis GoPay Rp 10.000 memicu notifikasi Uangku dan tercatat di DB, (3) notifikasi BTN "Pembelian GoPay Berhasil" tertangkap di log. Uji saat app benar-benar dimatikan belum dilakukan.
- Risiko: Tanpa background isolate, transaksi yang tiba saat sistem membunuh proses Flutter tetap berisiko hilang. Xiaomi MIUI/HyperOS agresif membersihkan RAM; bila service tidak auto-rebind setelah dibunuh, transaksi digital hilang tanpa pemberitahuan.
- Terkait: `docs/07-EXECUTION-PLAN.md` §7.1, NFR-04, R-02, R-04.
- Saran: Jalankan uji reboot saat pengguna sengaja merestart HP; jika transaksi pasca-reboot gagal, pasang headless background isolate atau beralih ke plugin (spikes/listener/RESULT.md).
- Catatan: Masalah listener tidak auto-bind setelah update ditemukan dan **diperbaiki di T-016** lewat `NotificationListenerService.requestRebind()` di MainActivity. Pattern baru BTN "Pembelian GoPay Berhasil" juga didaftarkan.

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
- Dilewati: Tombol "Lihat Semua" di preview transaksi belum ada (hanya 5 item teratas tanpa navigasi), filter chip sumber di feed belum ada, dan tidak ada empty state/loading skeleton yang proper (loading hanya spinner `CircularProgressIndicator`). Angka nominal belum memakai `fontFeatures: tabularFigures` seperti DBD §4.
- Catatan: `CategoryDonutChart` **Selesai di T-021** (donut chart via fl_chart dan legend persentase).
- Risiko: Dashboard belum melengkapi tombol navigasi langsung ke feed penuh. Angka belum tabular figures.
- Terkait: `lib/ui/dashboard_screen.dart`, FR-08, FR-09, `docs/04-DBD.md` §4, §5.
- Saran: T-022 (filter sumber), T-024 (empty/loading/error + aksesibilitas) menutup sisa kekurangan ini.

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
- Catatan: `seedInitialRules()` awalnya tidak dipanggil dari `main.dart` (rule tidak pernah masuk DB di runtime) — **Selesai di T-017** saat startup dirapikan.

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

## T-017: CategorizerService (M3.1)
- Dilewati: Keyword bersifat **hardcode di Dart**, bukan data yang bisa diedit pengguna (padahal BSD §1.2 menyebut "editable in-app fase lanjutan"). Pencocokan memakai `contains` substring sederhana tanpa batas kata, sehingga "MAKAN" juga cocok pada "MAKANAN LAIN" dan "AYAM" cocok pada "AYAMGOYENG". Tidak ada normalisasi typo, singkatan, atau ejaan alternatif. Tidak ada UI kelola kategori. Kategori hasil kategorisasi belum disambungkan ke alur penyimpanan transaksi (masih dipanggil manual dari test).
- Risiko: Keyword hardcode berarti kalibrasi hanya lewat ubah kode + build ulang, bertentangan dengan semangat NFR-06. Substring tanpa batas kata berisiko salah kategori (mis. "AYAM" pada nama merchant non-makanan).
- Terkait: `lib/services/categorizer_service.dart`, `lib/main.dart`, FR-04, NFR-06, `docs/05-BSD.md` §1.2.
- Saran: Editor keyword in-app masuk T-020 atau fase 2; perbaiki pencocokan jadi batas kata saat kalibrasi T-026.

## T-018: LocalNotifService + wiring listener → parser → simpan (M3.2)
- Dilewati: Notifikasi interaktif **hanya muncul saat app berjalan** — `NotifIngestService.start()` dipasang di `initState` `UangkuApp`, jadi notifikasi yang tiba saat app tertutup tetap tidak tercatat (sama seperti backlog T-011). Tombol **Abaikan** memakai `cancelNotification: true` (hanya menutup notifikasi OS) tanpa menandai transaksi sebagai "diabaikan" di database. Tombol **Ubah Kategori** membuka layar Detail, tetapi **tidak bisa mengubah kategori langsung dari notifikasi** (harus tap chip di layar) — target "koreksi ≤ 2 tap" FR-05/NFR-05 belum terbukti terpenuhi. Tidak ada notifikasi untuk transaksi nominal 0 (kasus Bale by BTN) yang justru paling butuh koreksi nominal. `LocalNotifService.onAction` hanya menangani satu callback global (bukan per-notifikasi). Inisialisasi `FlutterLocalNotificationsPlugin` tidak diuji di perangkat — hanya diuji lewat test double.
- Risiko: **DoD M2 tetap belum terpenuhi** karena transaksi tidak tercatat saat app tertutup. Transaksi Bale (nominal 0) tersimpan diam-diam tanpa notifikasi, padahal itu yang butuh perhatian pengguna. Klaim "koreksi ≤ 2 tap" belum diverifikasi dan kemungkinan butuh 3–4 tap (buka app → notifikasi → layar → chip → simpan).
- Terkait: `lib/services/notif_ingest_service.dart`, `lib/services/local_notif_service.dart`, `lib/main.dart`, FR-05, NFR-05, `docs/03-AFD.md` §3, `docs/04-DBD.md` §5.
- Saran: Background isolate masuk T-016 (uji perangkat) atau tugas terpisah — **butuh keputusan pengguna**. Notifikasi khusus nominal 0 + aksi cepat pilih kategori masuk T-020; verifikasi "≤ 2 tap" di checklist §7.2.

## T-020: Log Parser + Uji Rule Parser (M3.4)
- Dilewati: Layar Uji Rule hanya menguji **satu** pattern yang dipilih dari dropdown; tidak ada tombol tambah rule baru, hapus rule, ubah `priority`, atau `enabled` — padahal `parser_rules` punya kolom itu (BSD §1.3). Tidak ada ekspor/impor JSON rule (`version` di BSD §5 belum dipakai). Retensi LRU 200 dipanggil **setelah** insert lewat `trimLogs()` di `parse()`, tetapi tidak ada pembersihan terjadwal maupun batas ukuran total database. `trimLogs()` memuat **seluruh** baris ke memori lalu menghapus kelebihannya — O(n) per notifikasi, bukan query `DELETE ... LIMIT`. Log mentah tetap tersimpan tanpa enkripsi. Tidak ada indikator "log ini menghasilkan transaksi mana".
- Risiko: Pengguna tidak bisa memperbaiki rule yang salah tanpa mengubah kode (mis. mengubah `priority` agar rule spesifik menang). `trimLogs()` yang memuat semua baris akan melambat saat log mendekati ribuan baris. Karena retensi hanya jalan saat ada notifikasi baru, log bisa melebihi 200 kalau `parse()` tidak pernah dipanggil.
- Terkait: `lib/ui/parser_log_screen.dart`, `lib/services/parser_engine.dart` (`ParserRuleTesting`, `trimLogs`, `updateRulePattern`, `clearLogs`), FR-10, NFR-06, `docs/03-AFD.md` §6, `docs/05-BSD.md` §1.3, §5, §8.
- Saran: CRUD rule penuh + ekspor/impor JSON masuk fase 2; optimasi `trimLogs` jadi `DELETE WHERE id NOT IN (SELECT ... LIMIT 200)` saat T-026; verifikasi manual ubah-rule-tanpa-build masuk checklist §7.2.

## T-021: Chart kategori + picker periode (M4.1)
- Dilewati: Tap segmen donut chart belum memfilter feed transaksi (di DBD §5 tertulis 'tap segmen -> filter feed'), hanya menampilkan visual donut dan legend. Legend dibatasi maksimal 4 kategori teratas (sisanya tidak tampil di list legend kecil dashboard). Belum ada animasi custom atau tooltip nominal saat segmen disentuh.
- Risiko: Interaktivitas antar-komponen dashboard belum 100% seperti konsep interaktif (hanya visual chart statis). Pengeluaran kategori ke-5 dan seterusnya hanya tampak sebagai irisan warna tanpa label teks di card.
- Terkait: `lib/ui/dashboard_screen.dart` (`CategoryDonutChart`), FR-08, DBD §5.
- Saran: Filter feed via tap chart ditambahkan di T-022 saat filter chip feed dibangun; ekspansi legend kategori masuk T-024.

## T-022: Filter sumber feed + badge konsisten (M4.2)
- Dilewati: Filter memakai `ChoiceChip` biasa (bukan `SourceBadge` ber-outline seperti di mockup Opsi A). Filter berjalan **di memori** setelah `repo.feed()` mengambil 100 baris pertama — bukan query SQL `WHERE source = ?`, sehingga transaksi ke-101 dan seterusnya tidak akan muncul walau sumbernya cocok. Filter hilang saat app ditutup (state tidak dipersistenkan). Tidak ada indikator jumlah hasil per filter atau kombinasi filter dengan tanggal.
- Risiko: Dengan lebih dari 100 transaksi, filter "BTN" bisa tampak kosong padahal ada transaksi BTN yang lebih lama. Query tetap mengambil semua baris lalu membuang sebagian di Dart — pemborosan saat data besar.
- Terkait: `lib/ui/dashboard_screen.dart` (`feedSourceFilterProvider`, `filteredFeedProvider`, `_FeedTab`), FR-09, `docs/04-DBD.md` §6.
- Saran: Pindahkan filter ke `TransactionRepository.feed(source:)` sebagai klausa SQL saat cursor pagination ditambahkan (fase 2 / T-024).

## T-023: Widget home screen + Quick Tile (M4.3)
- Dilewati: Angka widget **tidak real-time** — hanya di-update saat app dibuka (`_refreshWidget()` dipanggil di `initState`), sesuai batasan DBD §7 yang mengizinkan ini. Tidak ada `HomeWidget.scheduleWidgetUpdates` untuk refresh terjadwal, dan `updatePeriodMillis` masih 24 jam (nilai bawaan), sehingga widget bisa menampilkan angka basi berhari-hari. Widget hanya menampilkan **total pengeluaran** — tidak ada tombol "+" yang benar-benar membuka sheet dari dalam widget (klik "+" membuka Activity, yang karena `singleTop` + deep-link mungkin tidak langsung memunculkan sheet). Quick Tile tidak punya ikon kustom (memakai launcher icon bawaan). Tidak ada handling `initiallyLaunchedFromHomeWidget` untuk app yang **dibuka lewat widget** (hanya klik saat app sudah jalan yang ditangani). Tidak ada preview widget (`updateWidgetPreview`) untuk layar konfigurasi.
- Risiko: Widget menampilkan angka kemarin tanpa penanda, dan bisa relevan bila用户 mengira itu data hari ini. Deep-link dari tile saat app tidak berjalan mungkin tidak membuka sheet karena logika klik hanya bereaksi pada stream klik.
- Terkait: `android/app/src/main/kotlin/com/bimadji/uangku/UangkuWidgetProvider.kt`, `UangkuTileService.kt`, `lib/services/widget_bridge.dart`, `lib/main.dart`, FR-07, `docs/04-DBD.md` §7.
- Saran: Refresh widget saat transaksi tersimpan (T-024 atau saat wiring listener disempurnakan); tangani `initiallyLaunchedFromHomeWidget` untuk membuka sheet saat app baru dibuka dari widget; ikon tile kustom masuk polish T-028.

## T-024: Empty/loading/error states + aksesibilitas (M4.4)
- Dilewati: Tidak ada **skeleton shimmer** — loading masih `CircularProgressIndicator` polos, meski DBD §8 menyebut skeleton. `semanticLabel` hanya ditambahkan pada tombol keypad dan tombol "Perbaiki"; `TransactionTile`, `CashFlowCard`, `CategoryDonutChart`, dan baris log **belum** punya label semantik eksplisit (pembaca layar hanya membaca teks yang sudah terlihat). Uji **font scale 1.3×** belum dijalankan otomatis — hanya tersedia sebagai item checklist manual §7.2. Kontras 4.5:1 belum diukur otomatis (warna dipilih dari palet DBD §3, tetapi tidak ada pemeriksaan kontras di CI). Widget home screen & Quick Tile belum diuji dengan font scale besar.
- Risiko: Pengguna dengan gangguan penglihatan mendapat基本都是 teks yang terbaca, tetapi belum ada grouping/label yang menjelaskan relasi antar-elemen di baris transaksi dan kartu. Skeleton Loading yang缺失 membuat perpindahan tab terasa lebih "kosong" dibanding mockup.
- Associated: `lib/ui/states.dart` (baru), `lib/ui/dashboard_screen.dart`, `lib/ui/parser_log_screen.dart`, `test/states_a11y_test.dart`, NFR-05, `docs/04-DBD.md` §8, §9, `docs/03-AFD.md` §8.
- Saran: Tambah label semantik pada TransactionTile & CashFlowCard serta uji font scale 1.3× di checklist §7.2 saat pengguna menguji di HP; pemeriksaan kontras otomatis bisa masuk CI bila tooling Contrast Checker ditambahkan.

## T-028: Perbaikan UX kecil + matikan logging rilis (M5.4)
- Dilewati: **Bagian perbaikan UX kecil dari catatan pemakaian T-025 belum dikerjakan** — tugas ini baru menutup bagian audit logging & build rilis. R8/minify dimatikan (`isMinifyEnabled = false`) agar kelas plugin notifikasi & widget tidak ter-strip; konsekuensinya ukuran APK rilis 63 MB (bukan 15–20 MB seperti build shrink). Signing masih memakai **debug key** (catatan di `android/app/build.gradle.kts`) — wajib diganti keystore sendiri sebelum dipakai orang lain. Belum ada `versionName`/versionCode yang naik (masih 1.0.0) dan belum ada versioning per rilis. Checklist §7.2 (koreksi ≤ 2 tap, font scale 1.3×, widget & tile di HP) belum dijalankan pengguna.
- Risiko: APK rilis 63 MB boros ruang penyimpanan dan bisa membengkak di rilis berikutnya. Debug keymeans APK rilis bisaditandatangani ulang siapa pun yang punya key tersebut — tidak aman bila nanti dibagikan. Tidak ada昇 versi, jadi setiap update APK rilis menimpa build sebelumnya tanpa nomor seri.
- Associated: `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle.kts`, `android/gradle.properties`, `android/app/src/main/res/xml/data_extraction_rules.xml`, `test/release_audit_test.dart`, TRD §6, NFR-01, `docs/01-PRD.md` A-05.
- Saran: Ganti ke keystore milik sendiri sebelum rilis final (T-025/T-027 atau saat MVP dinyatakan selesai); naikkan versionCode saat rilis stabil; jalankan checklist §7.2 di HP.
- Catatan: Audit menemukan **tidak ada** logging `print`/`debugPrint`/`android.util.Log` di kode produksi — kriteria "build rilis tidak mem-log konten transaksi" sudah terpenuhi sejak awal dan kini dijaga oleh `test/release_audit_test.dart` (5 test). Yang baru diperbaiki di T-028: **auto-backup Google Cloud dimatikan** (`allowBackup="false"` + `data_extraction_rules.xml` mengecualikan database/sharedpref/file) karena DB berisi transaksi & log notifikasi mentah, serta label aplikasi diubah "uangku" → "Uangku".

## T-029: Tema terpusat + token desain (M6.1)
- Dilewati: Token belum dipindahkan penuh ke semua widget — banyak widget masih menulis literal warna/ukuran sendiri (`Colors.red`, `Colors.grey.shade600`, `fontSize: 16`, dst.). Pemeriksaan "tidak ada literal warna di luar file token" **belum** diotomatisasi. Skala tipografi belum meliputi semua peran yang ada di mockup (mis. teks kategori di bawah nominal, teks label 11px pada legend chart). Mode gelap belum ada (sesuai DBD §3, fase 2).
- Risiko: UI bisa menyimpang dari mockup di task-task berikutnya karena widget masih memakai nilai lama sendiri-sendiri; perubahan token tidak otomatis merambat ke semua tempat.
- Associated: `lib/ui/app_theme.dart`, `lib/main.dart`, `docs/04-DBD.md` §3–§4, `docs/mockups/option-a/index.html`.
- Saran: Migrasikan literal ke token dilakukan bertahap di T-030..T-034 sesuai layar yang dikerjakan; Tambahkan lint check (grep tanpa hex di luar app_theme.dart) bila seluruh layar selesai.

## T-030: Dashboard sesuai mockup option-a (M6.2)
- Dilewati: Greeting "Halo, Bima" memakai **nama hardcode** — tidak ada sumber nama pengguna di DB (tidak ada tabel profil), jadi untuk sementara konstan. "Lihat Semua" hanya berpindah ke tab Transaksi, **tanpa** menyaring periode/sumber yang sedang aktif. Iconografi baris transaksi tetap panah ↑/↓ (keputusan pengguna), bukan emoji mockup. Ikon avatar 40px memakai `Icons.arrow_upward/arrow_downward`, mockup memakai emoji kategori — warna & layout sudah sama. Chart donut dikecilkan ke 84px (mockup) tetapi **legend masih memakai format lama** (persentase + nominal tanpa ■ dan tanpa nama singkat) — penyempurnaan legend masuk T-031. Tidak ada animasi atau transisi apa pun (mockup statis juga).
- Risiko: Nama pengguna di header akan salah bila perangkat dipakai orang lain. Tap "Lihat Semua" bisaetis hopedomi verbally: pengguna mengira filtered periodenya ikut, padahal tidak.
- Associated: `lib/ui/dashboard_screen.dart` (`CashFlowCard`, `PeriodSelector`, `TransactionRow`, `_OfflineBadge`, `_DashboardTab`), `lib/ui/app_theme.dart`, FR-08, FR-09, DBD §5–§6.
- Saran: Nama pengguna → tabel profil baru (butuh migrasi skema, di luar scope UI) atau settings sederhana; perbaiki kalimat "Lihat Semua" agar jelas hanya navigasi tab; samakan legend chart di T-031.

## T-031: Transaksi (feed) sesuai mockup option-a (M6.3)
- Dilewati: Tombol "Export" di header kanan layar (mockup option-a `.screen-header` memuat tautan "Export" biru) **belum diimplementasikan** — ekspor data adalah fitur Fase 2 (PRD §7: backup/export JSON-CSV), bukan cakupan MVP. Grouping tanggal baru membedakan "Hari Ini" dan "Kemarin"; tanggal-tanggal sebelumnya memakai format tanggal standar tanpa perlakuan khusus. Baris transaksi tidak menampilkan jam di samping badge (mockup menampilkan `12:45` di baris subtitle). Tautan filter chip belum mendukung multi-pilih (hanya satu sumber aktif atau semua).
- Risiko: Pengguna melihat header tanpa jalan keluar untuk mengekspor data (sesuai scope MVP). Ketiadaan jam membuat transaksi pada hari yang sama tidak terlihat urutan waktunya di kartu.
- Associated: `lib/ui/dashboard_screen.dart` (`_FeedTab`, `_formatDateGroup`), FR-09, `docs/04-DBD.md` §6, `docs/mockups/option-a/index.html`.
- Saran: Fitur Export masuk Fase 2; jam transaksi ditambahkan ke subtitle baris saat T-034.

## T-032: Pengaturan sesuai mockup option-a (M6.4)
- Dilewati: Menu "Kelola Kategori Default" dan "Panduan Whitelist Baterai (Xiaomi)" dari mockup **tidak ditambahkan** — keduanya tidak punya layar tujuan di aplikasi (kelola kategori butuh CRUD baru = di luar scope UI). Baris "Whitelist Baterai" pada card status **tidak bisa diketuk** untuk membuka setelan baterai OEM (mockup juga tidak menyediakannya; hanya teks). Indikator status listener tidak auto-refresh saat pengguna kembali dari Setelan Android — perlu menekan baris Notification Access lagi.
- Risiko: Pengguna melihat menu yang belum bisa membuka apa pun bila kedua menu itu ditambahkan; belum ditambahkan, jadi tidak menyesatkan. Status listener bisa tampak basi setelah pengguna mengubah izin di luar aplikasi.
- Associated: `lib/ui/dashboard_screen.dart` (`_SettingsTab`, `_statusPill`), FR-01, `docs/04-DBD.md` §6, `docs/mockups/option-a/index.html`.
- Saran: Auto-refresh status saat `AppLifecycleState.resumed` masuk T-034 atau polish; layar Kelola Kategori masuk fase 2.
