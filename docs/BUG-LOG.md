# Catatan Bug (BUG LOG)

Semua bug yang ditemukan selama pengembangan Uangku. Entri disusun **terbaru di atas**.
ID (BUG-xxx) bersifat tetap dan tidak menandakan urutan waktu — dipakai sebagai rujukan.
Aturan pencatatan ada di `docs/07-EXECUTION-PLAN.md` §1.4.

---

## BUG-001: Chip kategori tampil satu kolom penuh (bukan wrap)
- Status: Diperbaiki di T-036 (PR #35)
- Ditemukan: 2026-11-01, setelah T-034, dari screenshot pengguna di `docs/realTest/after/` (layar Catat Tunai Cepat & Catat Pemasukan).
- Gejala: 8 chip kategori (Makanan, Transportasi, Kos & Tagihan, …) masing-masing memenuhi lebar layar dan bertumpuk vertikal, sehingga sheet jadi sangat panjang dan keypad terdorong keluar layar.
- Penyebab: `Container` diberi `alignment: Alignment.center` tanpa lebar eksplisit. Container dengan `alignment` **mengisi seluruh lebar constraint** yang tersedia, sehingga setiap chip di dalam `Wrap` berukuran selebar induk dan tidak pernah bisa berdampingan. Terverifikasi dari screenshot: lebar chip = lebar kartu.
- Lokasi kode: `lib/ui/dashboard_screen.dart` — `_QuickCashSheetState.build` (chip kategori) dan `_TransactionDetailScreenState._categoryChip`.
- Dampak: Fitur inti "input tunai < 5 detik" (FR-07/NFR-05) rusak — pengguna harus menggulir untuk melihat keypad. Tidak ada data yang salah.
- Perbaikan: `alignment` dihapus, diganti `padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)`. Tanpa `alignment`, Container mengecil mengikuti isi sehingga chip dapat wrap beberapa per baris.
- Pencegahan: `test/quicksheet_mockup_test.dart` — "Chip kategori tersusun beberapa per baris (bukan 1 kolom penuh)" dan "Lebar chip kategori tidak memenuhi seluruh layar".

## BUG-002: FAB menutupi nominal & kategori baris terakhir
- Status: Diperbaiki di T-036 (PR #35)
- Ditemukan: 2026-11-01, dari screenshot pengguna yang sama (`docs/realTest/after/` layar Dashboard) — terlihat "- Rp 13.000" dan "Makanan & Minuman" tertutup tombol "+".
- Gejala: Baris transaksi terbawah di Dashboard/Transaksi tertutup FAB sehingga nominal tidak terbaca.
- Penyebab: Padding bawah `ListView` 84dp lebih kecil dari kebutuhan ruang FAB (56dp + margin 16dp = 72dp) ditambah tinggi baris yang sedang digulir; baris terakhir tidak bisa digulir melewati FAB.
- Lokasi kode: `lib/ui/dashboard_screen.dart` — `_DashboardTab` dan `_FeedTab` (`ListView.padding`).
- Dampak: Informasi keuangan tidak terbaca tanpa menggulir lebih jauh. Tidak ada data salah.
- Perbaikan: Padding bawah dinaikkan 84 → 120dp pada kedua layar.
- Pencegahan: Tidak ada test otomatis (memerlukan pengukuran posisi FAB terhadap item terakhir); diverifikasi visual lewat screenshot pengguna.

## BUG-003: Listener notifikasi mati dan tidak pulih sendiri
- Status: Diperbaiki di T-036 (PR #35)
- Ditemukan: 2026-11-01, laporan pengguna: bayar via GoPay tetapi tidak tercatat di Uangku maupun di Log Parser, sementara notifikasinya masih ada di taskbar.
- Gejala: Transaksi digital tidak masuk sama sekali. `adb shell dumpsys notification --noredact` menunjukkan `Live notification listeners` **kosong** meski `enabled_notification_listeners` masih memuat komponen Uangku dan proses app berjalan (`pidof` mengembalikan PID). Uptime perangkat 11 hari, jadi bukan efek restart.
- Penyebab: MIUI/HyperOS melepas binding `NotificationListenerService` saat app lama tidak dipakai (manajemen baterai OEM). Perbaikan sebelumnya (T-016) hanya memanggil `NotificationListenerService.requestRebind()` sekali di `configureFlutterEngine`, sehingga setelah OS melepas service tidak ada yang meminta rebind lagi. Terverifikasi: memanggil rebind tidak memulihkan, sedangkan toggle izin lewat `cmd notification disallow_listener` + `allow_listener` langsung membuat listener LIVE.
- Lokasi kode: `android/app/src/main/kotlin/com/bimadji/uangku/MainActivity.kt` — `MainActivity.requestListenerRebind()`, `UangkuNotificationListener.onListenerConnected()`.
- Dampak: **Kehilangan data transaksi** (severity tinggi). Transaksi yang terjadi selama listener mati tidak pernah tersimpan; notifikasi yang sudah di-swipe hilang permanen. Data yang terlanjur hilang tidak bisa dipulihkan otomatis.
- Perbaikan: (a) `onResume()` memanggil `requestListenerRebind()` sehingga setiap app dibuka service dipaksa tersambung lagi; (b) `onListenerConnected()` melakukan catch-up dengan mengiterasi `activeNotifications` dan mengirimkannya lewat jalur yang sama, sehingga notifikasi yang masih di tray saat service pulih ikut diproses (dedup mencegah pencatatan ganda).
- Pencegahan: Tidak bisa diuji otomatis di CI (butuh perangkat + manajemen baterai OEM). Verifikasi manual: `adb shell dumpsys notification | grep "Live notification listeners"`.

## BUG-004: Widget home screen & status listener menampilkan data basi
- Status: Diperbaiki di T-035 (PR #34)
- Ditemukan: 2026-10-31, saat mengerjakan T-035 (review kode sendiri setelah membaca backlog T-023 dan T-032).
- Gejala: (a) Setelah mencatat transaksi, angka di widget home screen tetap angka lama sampai app dibuka ulang. (b) Setelah pengguna mengubah izin Notification Access di Setelan Android lalu kembali ke app, indikator status masih menampilkan nilai lama.
- Penyebab: (a) `WidgetBridge.updateExpenseToday()` hanya dipanggil dari `initState` `UangkuApp`, tidak ada pemanggilan setelah mutasi transaksi. (b) Tidak ada `WidgetsBindingObserver`; status hanya dibaca sekali saat widget dibangun.
- Lokasi kode: `lib/main.dart` (`_UangkuAppState`), `lib/services/widget_sync.dart` (baru), `lib/ui/dashboard_screen.dart`, `lib/services/notif_ingest_service.dart`.
- Dampak: Informasi menyesatkan (widget menampilkan total lama; status izin tampak aktif padahal dicabut). Tidak merusak data.
- Perbaikan: Helper `syncWidget(db)` dipanggil di setiap titik mutasi (simpan QuickCashSheet, simpan/hapus Detail, transaksi otomatis listener); `WidgetsBindingObserver` menangani `resumed` untuk menyegarkan status listener, whitelist baterai, dan widget; `initiallyLaunchedFromHomeWidget()` ditangani agar cold start dari widget membuka QuickCashSheet.
- Pencegahan: `test/widget_sync_test.dart` — 4 test (`syncWidget` mengirim total hari ini, mengabaikan transaksi kemarin, `Rp 0` saat kosong, dan memperbarui angka setelah transaksi baru).

## BUG-005: Tap baris transaksi tidak membuka layar Detail (regresi)
- Status: Diperbaiki di T-030 (PR #29)
- Ditemukan: 2026-10-31, saat T-030; test `test/widget_test.dart` → "TransactionDetailScreen: buka detail, edit merchant/nominal, simpan" gagal.
- Gejala: Mengetuk baris transaksi di Dashboard tidak membuka apa pun. Test gagal karena teks merchant tidak bisa diketuk (`Warning: A call to tap() … derailed`).
- Penyebab: Saat mengganti `TransactionTile` (ListTile dengan `onTap`) menjadi `TransactionRow` baru untuk mengikuti mockup, properti `onTap` tidak ikut dipindahkan. Regresi fungsional murni akibat penggantian komponen.
- Lokasi kode: `lib/ui/dashboard_screen.dart` — `TransactionRow` (constructor & `build`).
- Dampak: Fitur koreksi transaksi (FR-06) tidak bisa diakses dari Dashboard. Severity tinggi untuk kegunaan, tanpa kerusakan data.
- Perbaikan: `TransactionRow` menerima `onTap` opsional dan membungkus isinya dengan `InkWell`; Dashboard meneruskan navigasi ke `TransactionDetailScreen`.
- Pencegahan: Test regresi di `test/dashboard_mockup_test.dart` — "Baris transaksi bisa diketuk → membuka Detail (regresi fungsi)".

## BUG-006: Bottom sheet meluber 21px setelah urutan chip→keypad
- Status: Diperbaiki di T-033 (PR #32)
- Ditemukan: 2026-10-31, saat T-033; test `test/states_a11y_test.dart` gagal dengan `A RenderFlex overflowed by 21 pixels on the bottom`.
- Gejala: Isi QuickCashSheet melebihi tinggi bottom sheet; muncul garis kuning-hitam "overflow" di mode debug dan tombol Simpan terpotong.
- Penyebab: Mengikuti mockup, urutan diubah (chip kategori sebelum keypad) dan header ditambah, sehingga total tinggi isi melebihi tinggi sheet pada layar uji. Isi sheet sebelumnya hanya `Column` tanpa kemampuan menggulir.
- Lokasi kode: `lib/ui/dashboard_screen.dart` — `_QuickCashSheetState.build`.
- Dampak: Tombol Simpan tidak dapat dijangkau pada layar pendek → input tunai gagal (FR-07).
- Perbaikan: Isi sheet dibungkus `SingleChildScrollView` agar dapat digulir bila melebihi tinggi layar.
- Pencegahan: Tertangkap otomatis oleh test widget yang sudah ada (`test/states_a11y_test.dart`, `test/widget_test.dart` alur input tunai) — overflow melempar error di test.

## BUG-007: Label semantik tombol keypad tidak terbaca pembaca layar
- Status: Diperbaiki di T-033 (PR #32)
- Ditemukan: 2026-10-31, saat T-033; test `test/states_a11y_test.dart` → "Tombol keypad punya label semantik…" gagal (`find.bySemanticsLabel('Angka 5')` tidak menemukan apa pun).
- Gejala: Pembaca layar tidak mengumumkan "Angka 5" / "Hapus digit terakhir"; yang terbaca hanya karakter mentah.
- Penyebab: `Semantics(label: …)` membungkus `GestureDetector` yang berisi `Text`. Semantik anak (`Text`) tetap digabungkan dan menimpa label induk, sehingga label kustom hilang.
- Lokasi kode: `lib/ui/dashboard_screen.dart` — `_QuickCashSheetState._keypad` dan `_typeToggle`.
- Dampak: Pengguna tunanetra tidak dapat mengoperasikan keypad dengan benar (NFR-05/DBD §9).
- Perbaikan: `excludeSemantics: true` ditambahkan pada `Semantics` sehingga label kustom dipakai dan semantik anak diabaikan.
- Pencegahan: `test/states_a11y_test.dart` — "Tombol keypad punya label semantik yang bisa dibaca screen reader" dan "Tombol backspace keypad punya label semantik".

## BUG-008: Label kartu Arus Kas menyimpang dari keputusan pengguna
- Status: Diperbaiki di T-030 (PR #29)
- Ditemukan: 2026-10-31, saat T-030; test `test/widget_test.dart` → "Dashboard menampilkan CashFlowCard dan empty state" gagal (`Expected: exactly one matching candidate, Actual: _TextWidgetFinder…` untuk teks "Arus Kas").
- Gejala: Kartu menampilkan judul "Total Pengeluaran", padahal pengguna memutuskan label tetap "Arus Kas" saat menjawab pertanyaan gap analysis.
- Penyebab: Salah paham keputusan: mockup memakai "Total Pengeluaran (Hari Ini)", dan keputusan pengguna adalah **struktur** mockup (hero + dua nilai bawah) dengan **label tetap** "Arus Kas". Saya menyalin label mockup sekaligus.
- Lokasi kode: `lib/ui/dashboard_screen.dart` — `CashFlowCard.build` (baris `Text('Arus Kas', style: AppText.cardLabel)`).
- Dampak: Tidak ada kerusakan data; teks menyimpang dari kesepakatan sehingga tampilan tidak sesuai keputusan.
- Perbaikan: Label dikembalikan ke "Arus Kas"; struktur hero + "Pemasukan"/"Net Arus Kas" dipertahankan.
- Pencegahan: `test/dashboard_mockup_test.dart` — "Kartu Arus Kas: label, hero pengeluaran, Pemasukan & Net Arus Kas" menegaskan label & struktur sekaligus.

## BUG-009: Hasil uji regex tidak diperbarui saat teks mentah diubah
- Status: Diperbaiki di T-020 (PR #21)
- Ditemukan: 2026-10-31, saat T-020; test `test/parser_log_screen_test.dart` → "Uji Rule menampilkan hasil cocok dan tombol Simpan aktif" gagal.
- Gejala: Mengubah teks notifikasi mentah tidak mengubah hasil uji; hasil "Cocok" tetap dari teks sebelumnya.
- Penyebab: `_runTest()` hanya dipanggil dari `onChanged` field pattern dan dropdown rule; field teks mentah tidak punya `onChanged`.
- Lokasi kode: `lib/ui/parser_log_screen.dart` — `_RuleTestScreenState.build` (TextField teks mentah).
- Dampak: Pengguna bisa menyimpan rule yang tampak cocok padahal diuji pada teks lama → pattern salah tersimpan (FR-10).
- Perbaikan: `onChanged` pada field teks mentah memicu `_runTest(_patternCtrl.text)` bila pattern sudah diisi.
- Pencegahan: Test yang sama di `test/parser_log_screen_test.dart` (uji live) kini mencakup jalur ini.

## BUG-010: `namedGroup()` melempar exception bila grup tidak ada di pattern
- Status: Diperbaiki di T-020 (PR #21)
- Ditemukan: 2026-10-31, saat T-020; test `test/parser_log_screen_test.dart` → "testPattern tanpa named group amount mengembalikan amount null" gagal dengan `FormatException`/exception dari `RegExpMatch.namedGroup`.
- Gejala: Menguji pattern yang tidak punya grup `amount` (mis. hanya `merchant`) membuat layar Uji Rule error, bukan menampilkan hasil.
- Penyebab: `RegExpMatch.namedGroup(name)` melempar bila nama grup tidak terdaftar di pattern — bukan mengembalikan `null`. Kode mengasumsikan null-safe.
- Lokasi kode: `lib/services/parser_engine.dart` — `ParserRuleTesting.testPattern`.
- Dampak: Rule tanpa grup opsional tidak bisa diuji dari UI; pengguna tidak bisa menyimpan rule valid yang tidak mengekstrak nominal.
- Perbaikan: Helper `group(name)` membungkus `namedGroup` dengan try/catch dan mengembalikan `null` bila grup tidak ada.
- Pencegahan: `test/parser_log_screen_test.dart` — "testPattern tanpa named group amount mengembalikan amount null".

## BUG-011: Build APK gagal setelah menambah `flutter_local_notifications`
- Status: Diperbaiki di T-018 (PR #20)
- Ditemukan: 2026-10-31, saat T-018, dari `flutter build apk --debug` (lokal) dan job `build-apk-debug` di CI.
- Gejala: Build berhenti dengan `checkDebugAarMetadata` / `Dependency ':flutter_local_notifications' requires core library desugaring to be enabled`.
- Penyebab: Plugin `flutter_local_notifications` v22 mewajibkan core library desugaring — terverifikasi dari README paket yang terpasang (v22.3.3, baris 217: "Version 10+ … relies on desugaring … Developers will need to update their application's Gradle file to enable desugaring even if they don't use scheduled notifications"). Proyek belum mengaktifkannya, sehingga `checkDebugAarMetadata` gagal.
- Lokasi kode: `android/app/build.gradle.kts` — `compileOptions` & `dependencies`.
- Dampak: Fitur notifikasi interaktif (FR-05) tidak bisa dikirim ke perangkat sama sekali.
- Perbaikan: `isCoreLibraryDesugaringEnabled = true` dan `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`.
- Pencegahan: Job `build-apk-debug` di CI (`.github/workflows/ci.yml`) gagal bila regresi ini kembali.

## BUG-012: Seed kategori gagal karena `UNIQUE(name)` menolak "Lainnya" ganda
- Status: Diperbaiki di T-006 (PR #5); dokumen `docs/05-BSD.md` §1.2 dikoreksi 2026-11-01 (PR #37).
- Ditemukan: 2026-10-30, saat T-006; test `test/database_test.dart` → "seed awal menghasilkan 12 kategori persis" gagal (`SqliteException: UNIQUE constraint failed: categories.name`).
- Gejala: Hanya 11 dari 12 kategori yang tersimpan; seed kedua tidak menambah "Lainnya" untuk jenis pemasukan.
- Penyebab: Skema memakai `UNIQUE(name)` (mengikuti `docs/05-BSD.md` §1.2 yang menulis `name TEXT NOT NULL UNIQUE`), sementara daftar FR-11 memuat "Lainnya" untuk **kedua** jenis transaksi (pengeluaran dan pemasukan). Constraint yang benar adalah pasangan `(name, kind)`.
- Lokasi kode: `lib/data/database.dart` — `Categories.uniqueKeys`, `AppDatabase.seedCategories`.
- Dampak: Kategori "Lainnya" untuk pemasukan tidak ada → kategorisasi pemasukan jatuh ke fallback yang salah. Data lama: tidak ada (DB baru).
- Perbaikan: Constraint diubah menjadi `uniqueKeys => [{name, kind}]`; lookup seed memakai `name` **dan** `kind`.
- Pencegahan: `test/database_test.dart` — "seed awal menghasilkan 12 kategori persis" + "idempotent: 2x seed tetap 12 baris".
- Catatan dokumen: `docs/05-BSD.md` §1.2 semula menulis `UNIQUE` pada `name` saja. **Dikoreksi 2026-11-01 setelah disetujui pengguna**: kolom `name` kini `NOT NULL` tanpa UNIQUE, dan ditambahkan catatan eksplisit `UNIQUE(name, kind)` beserta alasannya.

## BUG-013: Build gagal karena signature `EventChannel.StreamHandler` salah
- Status: Diperbaiki di T-011 (PR #12, commit `a45057f`)
- Ditemukan: 2026-10-31, saat T-011, dari job CI `build-apk-debug` (Kotlin compile error).
- Gejala: Kompilasi Kotlin gagal: `'cancel' overrides nothing` pada implementasi `EventChannel.StreamHandler`.
- Penyebab: API Flutter memakai `onCancel(arguments: Any?)`, bukan `cancel(arguments: Any?)`. Nama method ditebak tanpa memeriksa superclass.
- Lokasi kode: `android/app/src/main/kotlin/com/bimadji/uangku/MainActivity.kt` — `EventChannel.StreamHandler`.
- Dampak: Seluruh bridge notifikasi (FR-01) tidak bisa dibangun.
- Perbaikan: `cancel` → `onCancel`.
- Pencegahan: Job `build-apk-debug` di CI menangkap kesalahan kompilasi Kotlin; `flutter analyze` tidak memeriksa kode Kotlin.

## BUG-014: Build APK rilis gagal karena Gradle kehabisan memori
- Status: Diperbaiki di T-028 (PR #27)
- Ditemukan: 2026-10-31, saat T-028, dari `flutter build apk --release`.
- Gejala: Gradle daemon mati (`Gradle build daemon disappeared unexpectedly`), build berhenti tanpa pesan kode.
- Penyebab: `android/gradle.properties` meminta `-Xmx8G` sementara RAM bebas mesin ±1,6 GB (terukur lewat `Win32_OperatingSystem.FreePhysicalMemory`). Konfigurasi bawaan template tidak sesuai mesin pengembangan.
- Lokasi kode: `android/gradle.properties`.
- Dampak: APK rilis tidak bisa dibuat — menghambat seluruh verifikasi rilis (T-028).
- Perbaikan: `-Xmx2G`, `MaxMetaspaceSize=1G`, `org.gradle.daemon=false`, `org.gradle.workers.max=2`.
- Pencegahan: Tidak ada test otomatis; nilainya bersifat lingkungan. Dicatat agar tidak dikembalikan ke 8G di mesin ini.

## BUG-015: Asumsi "notifikasi Bale by BTN memuat nominal" ternyata salah
- Status: Ditunda (lihat `docs/BACKLOG-FUTURE.md` entri T-012)
- Ditemukan: 2026-10-30, saat pengumpulan sampel T-010 dan verifikasi T-016, lewat `adb shell dumpsys notification --noredact`.
- Gejala: Notifikasi Bale by BTN hanya memuat judul seperti `Payment GEPREK MASZEH ITS Successful` atau `Transfer Masuk`; field `android.text`/`android.bigText` kosong. Hasil parse menghasilkan `amount = 0`.
- Penyebab: Asumsi dokumen (OQ-01/OQ-02 di `docs/01-PRD.md`) bahwa nominal tersedia di payload notifikasi keliru untuk BTN. Terbukti dari dump notifikasi nyata: nominal tidak dikirim bank.
- Lokasi kode: `lib/services/parser_engine.dart` — `seedInitialRules` (rule BTN tanpa grup `amount`).
- Dampak: Transaksi BTN otomatis tersimpan dengan nominal 0 dan memerlukan koreksi manual — melemahkan target "input < 5 detik" untuk transaksi BTN. Data nominal 0 yang sudah tersimpan perlu dikoreksi pengguna.
- Perbaikan: Belum ada di sisi parser (tidak mungkin mengekstrak data yang tidak ada). Mitigasi sementara: layar Detail/Koreksi (T-019) memungkinkan pengisian nominal manual.
- Pencegahan: `test/parser_fixtures_test.dart` menetapkan `expectedAmount: 0` untuk fixture BTN sehingga perilaku ini terkunci dan tidak dianggap sukses palsu.

## BUG-016: Filter sumber feed menyembunyikan transaksi lama
- Status: Ditunda (lihat `docs/BACKLOG-FUTURE.md` entri T-022)
- Ditemukan: 2026-10-31, saat T-022, dari pembacaan kode sendiri (`filteredFeedProvider`).
- Gejala: Memilih filter "BTN" tidak menampilkan transaksi BTN yang lebih lama bila total transaksi melebihi 100.
- Penyebab: `filteredFeedProvider` memanggil `repo.feed()` (yang memakai `LIMIT 100`) lalu menyaring hasilnya di memori, bukan menyaring lewat klausa SQL `WHERE source = ?`.
- Lokasi kode: `lib/ui/dashboard_screen.dart` — `filteredFeedProvider`.
- Dampak: Pengguna mengira tidak punya transaksi BTN padahal ada. Tidak merusak data, tetapi menyesatkan.
- Perbaikan: Belum. Dicatat sebagai backlog T-022 dengan saran memindahkan filter ke `TransactionRepository.feed(source:)`.
- Pencegahan: Belum ada test; akan ditambahkan bersama perbaikannya (uji dengan >100 transaksi).

## BUG-017: Kode generator drift tidak cocok dengan versi runtime
- Status: Diperbaiki di T-002 (PR #2)
- Ditemukan: 2026-10-30, saat spike T-002, ketika mencoba memakai drift + Isar dalam satu proyek.
- Gejala: Test spike gagal memuat dengan error method tidak ditemukan (`$_getPrefetchedDataByColumns` tidak ada pada `drift` 2.28.0) — file `*.g.dart` dihasilkan oleh `drift_dev` versi lain.
- Penyebab: Untuk mengakomodasi `isar_community_generator`, `drift_dev` diturunkan ke 2.28.0 sementara artefak codegen berasal dari `drift_dev` 2.35.x. Versi generator dan runtime drift harus sepasang.
- Lokasi kode: `pubspec.yaml` (drift/drift_dev/build_runner), `spikes/db_drift/`.
- Dampak: Spike tidak bisa dijalankan sampai versi diselaraskan; bukan bug produk (belum ada kode produksi).
- Perbaikan: Kembali ke pasangan `drift ^2.35.3` + `drift_dev ^2.35.2` + `build_runner ^2.17.1`; Isar dibuang dari ketergantungan. Keputusan tercatat di `spikes/db_drift/RESULT.md`.
- Pencegahan: `test/database_test.dart` dan test service lain akan gagal kompilasi bila codegen tidak cocok.

## BUG-018: Cache incremental Kotlin korup membuat build gagal berulang
- Status: Ditunda (bukan bug kode aplikasi — kegagalan tooling)
- Ditemukan: 2026-10-31, saat T-023, dari `flutter build apk --debug`.
- Gejala: `e: Daemon compilation failed` + `Could not close incremental caches in …/kotlin: class-fq-name-to-source.tab, source-to-classes.tab, internal-name-to-source.tab`.
- Penyebab: Cache incremental compiler Kotlin di `build/home_widget/kotlin/...` tertinggal dalam keadaan tidak konsisten. **Dugaan**: proses Gradle/Kotlin daemon terhenti paksa (RAM habis, lihat BUG-014) saat menulis cache. Cara membuktikan: hapus direktori cache lalu build ulang — berhasil (`BUILD SUCCESSFUL`), yang menunjukkan cache, bukan kode, sebagai penyebab.
- Lokasi kode: direktori build (`build/home_widget`), bukan source.
- Dampak: Build lokal gagal sampai cache dibersihkan; tidak memengaruhi aplikasi atau CI.
- Perbaikan: Hapus `build/home_widget` dan jalankan `gradlew assembleRelease -Pkotlin.incremental=false`. Belum ada perbaikan permanen.
- Pencegahan: Tidak ada; bila berulang, pertimbangkan `kotlin.incremental=false` permanen di `gradle.properties`.