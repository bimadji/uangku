# Brainstorm: Uangku — Aplikasi Pencatat & Monitor Keuangan Pribadi (Android)

## 1. Ringkasan Ide dan Tujuan

**Uangku** adalah aplikasi Android untuk mencatat dan memonitor keuangan pribadi, dirancang untuk pengguna awal: mahasiswa di Indonesia (pemilik ide sendiri sebagai first user).

**Tujuan utama:**
- Mencatat pemasukan dan pengeluaran dengan ringkasan harian, mingguan, dan bulanan.
- Transaksi digital (m-banking, e-wallet, QRIS) tercatat **otomatis tanpa input manual**.
- Input manual seminimal mungkin; tampilan sederhana dan cepat dipakai.
- Data finansial tetap **100% di perangkat** (privasi maksimal).

## 2. Kebutuhan dan Keputusan yang Disepakati

| # | Keputusan | Detail |
|---|-----------|--------|
| 1 | Sumber data otomatis | **Bale by BTN** (m-banking rekening utama BTN) + **GoPay** (e-wallet) sebagai target MVP |
| 2 | Mekanisme otomatisasi | **`NotificationListenerService`** Android sebagai jalur utama; input manual cepat sebagai fallback |
| 3 | Metode parsing | **Regex deterministik lokal per-aplikasi** (bukan AI/LLM) — instan, offline, hemat baterai |
| 4 | Kategorisasi | Auto-kategori rule-based (keyword/merchant match) + **notifikasi interaktif** (tombol aksi: ubah kategori / abaikan) + halaman koreksi manual di app untuk antisipasi salah kategori |
| 5 | Privasi & arsitektur | **100% local-first**: SQLite/Isar lokal, tanpa server, tanpa login, tanpa analitik cloud |
| 6 | Transaksi tunai | **Input cepat < 5 detik**: widget home screen / quick settings tile, form minimalis (nominal + kategori 1 tap, tanggal default sekarang) |
| 7 | Kalibrasi parser | Menu **"Log Notifikasi Mentah & Uji Regex Lokal"** di pengaturan: riwayat raw text, status parse (sukses/gagal), edit rule tanpa recompile |
| 8 | Dashboard MVP | 3 komponen: kartu arus kas (harian/mingguan/bulanan), donut/bar chart breakdown kategori, feed transaksi kronologis dengan badge sumber (BTN/GoPay/Tunai) & indikator auto vs manual |
| 9 | Tech stack | **Flutter (Dart)**, dengan native Kotlin bridge kecil untuk NotificationListenerService |
| 10 | Kategori default | Pengeluaran: Makanan & Minuman, Transportasi, Kos & Tagihan, Belanja, Hiburan, Kesehatan, Pendidikan, Lainnya. Pemasukan: Uang Saku, Gaji/Part-time, Transfer Masuk, Lainnya |

## 3. Opsi Pencatatan Otomatis dan Pendekatan yang Dipilih

### Perbandingan jujur opsi yang dievaluasi

| Opsi | Kelebihan | Kekurangan | Keputusan |
|------|-----------|------------|-----------|
| **NotificationListenerService** ✅ dipilih | Pasif di background; tidak perlu buka app bank; izin relatif aman dari kebijakan Play Store; 100% offline; tidak butuh izin sensitif seperti SMS | Hanya menangkap transaksi jika aplikasi sumber mengeluarkan notifikasi; notifikasi bisa tertunda/di-suppress Doze; butuh parser per app | **Dipilih sebagai jalur utama** |
| READ_SMS (SMS banking) | Sumber teks terstruktur & andal | Izin `READ_SMS` sangat dibatasi Google Play (hanya app default SMS / whitelist ketat); banyak bank kini kirim notif via app, bukan SMS | **Ditolak** |
| Accessibility Service | Bisa baca layar app bank secara langsung | Sangat invasif; Google Play sangat ketat (penolakan tinggi untuk app non-accessibility); risiko keamanan besar | **Ditolak** |
| Impor e-statement / mutasi (PDF/CSV) | Data lengkap & akurat (backfill historis) | Proses manual per periode; format tiap bank beda; tidak real-time | **Ditunda ke fase lanjutan** (berguna sebagai backfill) |
| Open Banking / API agregator (Snap BI, Brick, Finantier) | Otomatisasi paling lengkap | Hanya realistis untuk entitas legal/B2B berlisensi OJK; tidak layak untuk aplikasi personal tanpa server | **Ditolak** untuk MVP |
| Input manual cepat | Selalu works, fallback universal | Butuh interaksi pengguna | **Dipilih sebagai fallback + jalur tunai** |

### Pendekatan final
1. Notifikasi dari Bale by BTN / GoPay → ditangkap `NotificationListenerService`.
2. Parser regex lokal (template per aplikasi, konfigurasi editable) mengekstrak: tipe transaksi (debit/kredit/QRIS/transfer), nominal, merchant/tujuan.
3. Dedup (notif ganda/terlambat) → simpan transaksi dengan kategori hasil auto-match.
4. Notifikasi interaktif Uangku muncul → pengguna bisa koreksi kategori langsung atau abaikan.
5. Koreksi lanjutan via halaman edit transaksi di app.

## 4. Rekomendasi Stack

- **Framework**: Flutter (Dart). Alasan: Dart mirip OOP modern (cocok untuk background C++/Python), performa compiled, UI declarative cepat, pemula mobile-friendly.
- **Native bridge**: sedikit kode Kotlin (~50–100 baris) untuk `NotificationListenerService` + channel MethodChannel/EventChannel ke Flutter (via plugin seperti `flutter_notification_listener`).
- **Database lokal**: SQLite (drift) atau Isar — keputusan implementasi bisa ditentukan saat development; keduanya 100% lokal.
- **State management**: sesuai kesederhanaan (mis. Riverpod/Provider).
- **Widget/tile input cepat**: `home_widget` + quick settings tile via platform channel.
- **Parser config**: rules regex disimpan sebagai konfigurasi lokal (JSON) yang bisa diedit in-app tanpa recompile.

## 5. Scope MVP dan Fitur Lanjutan

### MVP (v1)
1. Background listener untuk **Bale by BTN** + **GoPay** dengan parser regex lokal + in-app debug log & uji pattern.
2. Auto-kategorisasi rule-based + notifikasi interaktif (ubah kategori / abaikan) + halaman koreksi manual.
3. Input cepat tunai via widget home screen / quick settings tile (nominal + kategori, 1 tap).
4. Dashboard: kartu arus kas (harian/mingguan/bulanan), donut chart kategori, feed transaksi kronologis ber-badge sumber (BTN/GoPay/Tunai) dan indikator auto vs manual.
5. Penyimpanan 100% lokal (SQLite/Isar), tanpa login, tanpa internet, tanpa server.
6. Kategori default sesuai tabel di atas.

### Fase 2 (bukan MVP)
- Budget / batas pengeluaran per kategori.
- Backup/export JSON-CSV (terenkripsi, lokal/Google Drive pribadi).
- Impor e-statement/mutasi (PDF/CSV) untuk backfill historis.
- Perluasan bank/e-wallet lain (Livin' Mandiri, BRImo, BNI, DANA, ShopeePay, OVO, dll.).
- Notifikasi peringatan saldo/pengeluaran, dark mode, multi-akun.

## 6. Risiko dan Pertanyaan Terbuka

### Risiko utama
1. **Format notifikasi Bale by BTN jarang terdokumentasi publik** — kalibrasi regex wajib dilakukan manual dari perangkat sungguhan milik pengguna; bisa berubah tiap update app bank. *Mitigasi: in-app debug log & editor pattern (fitur #7).*
2. **Notifikasi ganda / tertunda / hilang** (Doze mode, notifikasi di-suppress, app force-close). *Mitigasi: dedup berbasis (waktu, nominal, merchant); periode kompromi akurasi.*
3. **Parsing salah / salah kategori otomatis**. *Mitigasi: notifikasi interaktif + halaman koreksi + pembelajaran rule lokal dari koreksi pengguna (fase lanjutan).*
4. **Ketergantungan lifecycle Android**: listener bisa dimatikan OEM (battery optimization, autoclean). *Mitigasi: panduan whitelist battery di onboarding.*
5. **Tidak ada sinkronisasi antar perangkat** — data hilang jika HP rusak sampai fitur backup ada.

### Pertanyaan terbuka
- Apa persisnya format notifikasi Bale by BTN untuk semua tipe transaksi (QRIS, transfer keluar/masuk, biaya admin, tarik tunai)? → perlu sampel dari perangkat asli.
- Apakah GoPay mengirim notifikasi untuk SEMUA jenis transaksi (termasuk pembayaran ke merchant kecil dan top-up)?
- Pilihan database final (drift vs Isar) dan state management — diputuskan saat development.
- Apakah perlu deteksi transaksi dari saldo (perbandingan saldo antar notifikasi) sebagai validasi?

## 7. Langkah Selanjutnya yang Disarankan

1. **Kumpulkan sampel notifikasi asli**: aktifkan semua jenis transaksi di Bale by BTN & GoPay selama beberapa hari, catat teks notifikasi mentahnya (bahan uji regex).
2. Prototype minimal: 1 layar Flutter + listener + parser + penyimpanan lokal, diuji end-to-end di HP pribadi.
3. Bangun in-app parser debugger sejak dini — ini kunci kemudahan kalibrasi.
4. Uji dedup dan skenario notifikasi tertunda/ganda.
5. Rilis MVP untuk pemakaian sendiri 2–4 minggu sebelum mengevaluasi fitur fase 2.
