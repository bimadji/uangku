# 01 — Product Requirements Document (PRD): Uangku

> Sumber kebenaran: `brainstorm-finance-app.md`. Semua keputusan final.

## 1. Latar Belakang

Mahasiswa Indonesia bertransaksi melalui banyak kanal: m-banking (Bale by BTN), e-wallet (GoPay), QRIS, dan tunai. Tidak ada satu tempat yang merekap semuanya tanpa input manual. Aplikasi pelacak keuangan umum mensyaratkan input manual per transaksi — beban terlalu besar untuk dipakai konsisten.

**Uangku** menghilangkan beban tersebut: transaksi digital tercatat otomatis dari notifikasi aplikasi bank/e-wallet; transaksi tunai dicatat dalam < 5 detik.

## 2. Tujuan

1. Merekap pemasukan dan pengeluaran dengan ringkasan harian, mingguan, bulanan.
2. Transaksi digital (Bale by BTN, GoPay) tercatat otomatis tanpa input manual.
3. Input manual seminimal mungkin; tampilan sederhana.
4. Data finansial 100% di perangkat (privasi maksimal).

## 3. Target Pengguna

- **Pengguna utama (MVP)**: pemilik ide sendiri — mahasiswa di Indonesia, pengguna Bale by BTN (rekening BTN) dan GoPay.
- Aplikasi single-user, tanpa akun, tanpa server.

## 4. User Stories

| ID | Story |
|----|-------|
| US-01 | Sebagai pengguna, aku ingin transaksi QRIS/transfer/debit di Bale by BTN dan GoPay otomatis tercatat, agar aku tidak perlu input manual. |
| US-02 | Sebagai pengguna, aku ingin koreksi kategori langsung dari notifikasi (tombol aksi), agar tidak perlu membuka aplikasi. |
| US-03 | Sebagai pengguna, aku ingin mencatat pengeluaran tunai dalam < 5 detik dari widget/quick tile, agar pencatatan tunai tidak terlewat. |
| US-04 | Sebagai pengguna, aku ingin melihat arus kas harian/mingguan/bulanan dan breakdown kategori, agar tahu ke mana uangku pergi. |
| US-05 | Sebagai pengguna, aku ingin melihat riwayat transaksi berurutan dengan sumber dana (BTN/GoPay/Tunai) dan indikator auto vs manual, agar bisa memverifikasi keakuratan. |
| US-06 | Sebagai pengguna, aku ingin mengedit kategori transaksi yang salah di aplikasi, agar data tetap akurat. |
| US-07 | Sebagai pengguna, aku ingin melihat notifikasi mentah yang gagal di-parse dan menguji/mengubah rule regex di aplikasi, agar parser bisa dikalibrasi tanpa build ulang. |

## 5. Functional Requirements

| ID | Requirement | Terkait |
|----|-------------|---------|
| FR-01 | Menangkap notifikasi dari aplikasi **Bale by BTN** dan **GoPay** via `NotificationListenerService`. | US-01 |
| FR-02 | Parser regex deterministik lokal per-aplikasi mengekstrak: tipe transaksi (debit/kredit), nominal, merchant/tujuan, waktu. | US-01 |
| FR-03 | Dedup transaksi otomatis berbasis kombinasi (waktu, nominal, sumber, merchant). | US-01 |
| FR-04 | Auto-kategorisasi rule-based (keyword/merchant match) terhadap kategori default. | US-02 |
| FR-05 | Notifikasi interaktif Uangku setelah transaksi tersimpan, dengan tombol aksi: **Ubah Kategori** dan **Abaikan**. | US-02 |
| FR-06 | Halaman koreksi: edit kategori, nominal, catatan transaksi mana pun. | US-06 |
| FR-07 | Input cepat tunai: widget home screen dan quick settings tile; form nominal + kategori 1 tap; tanggal default sekarang. | US-03 |
| FR-08 | Dashboard: kartu arus kas (harian/mingguan/bulanan), donut/bar chart breakdown kategori, feed transaksi kronologis. | US-04 |
| FR-09 | Feed transaksi dengan badge sumber (BTN/GoPay/Tunai) dan indikator auto vs manual. | US-05 |
| FR-10 | Menu "Log Notifikasi Mentah & Uji Regex Lokal": riwayat raw text notifikasi, status parse (sukses/gagal), editor rule regex tanpa recompile. | US-07 |
| FR-11 | Kategori default: Pengeluaran — Makanan & Minuman, Transportasi, Kos & Tagihan, Belanja, Hiburan, Kesehatan, Pendidikan, Lainnya. Pemasukan — Uang Saku, Gaji/Part-time, Transfer Masuk, Lainnya. | US-04 |
| FR-12 | Penyimpanan 100% lokal; aplikasi berfungsi penuh offline. | semua |

## 6. Non-Functional Requirements

| ID | Requirement |
|----|-------------|
| NFR-01 | **Privasi**: tidak ada data yang keluar dari perangkat; tanpa server, tanpa login, tanpa analitik cloud pihak ketiga. |
| NFR-02 | **Performa**: parsing notifikasi < 10 ms; buka dashboard < 1 detik pada perangkat kelas menengah bawah. |
| NFR-03 | **Efisiensi baterai**: listener pasif (event-driven), tanpa polling; kontribusi baterai tidak terasa (tanpa wakelock berulang). |
| NFR-04 | **Keandalan**: transaksi tidak hilang meski notifikasi tiba saat aplikasi tidak berjalan (listener tetap aktif sebagai service OS). |
| NFR-05 | **Kemudahan pemakaian**: input tunai < 5 detik; koreksi kategori ≤ 2 tap. |
| NFR-06 | **Maintainability**: rule parser berupa konfigurasi editable (JSON), bukan hardcode. |

## 7. Scope: MVP vs Fase 2

**MVP (v1)** — sesuai FR-01..FR-12.

**Fase 2 (bukan MVP)**:
- Budget / batas pengeluaran per kategori.
- Backup/export JSON-CSV (terenkripsi, lokal / Google Drive pribadi).
- Impor e-statement/mutasi (PDF/CSV) untuk backfill historis.
- Perluasan bank/e-wallet lain (Livin' Mandiri, BRImo, BNI, DANA, ShopeePay, OVO, dll.).
- Notifikasi peringatan saldo/pengeluaran, dark mode, multi-akun.
- Pembelajaran rule kategori dari koreksi pengguna.

## 8. Metrik Keberhasilan

| Metrik | Target MVP (pemakaian sendiri 2–4 minggu) |
|--------|--------------------------------------------|
| Rasio transaksi digital otomatis tercatat vs aktual (uji manual banding mutasi) | ≥ 90% |
| Rasio notifikasi berhasil di-parse tanpa kalibrasi ulang | ≥ 90% |
| Waktu input transaksi tunai | < 5 detik |
| Duplikat transaksi yang lolos dedup | 0 per minggu |
| Frekuensi membuka aplikasi hanya untuk koreksi besar | menurun dari minggu ke minggu |

## 9. Asumsi

| ID | Asumsi |
|----|--------|
| A-01 | Bale by BTN dan GoPay mengeluarkan notifikasi lokal untuk transaksi debit/kredit/QRIS/transfer. *(Format persisnya belum diketahui — open question OQ-01, OQ-02.)* |
| A-02 | Notifikasi GoPay tidak meng-cover semua jenis transaksi (misal merchant kecil); transaksi tanpa notifikasi dicatat manual. |
| A-03 | Pengguna adalah satu-satunya pengguna perangkat; tidak ada skenario multi-user. |
| A-04 | Database final (drift vs Isar) dan state management diputuskan saat development; tidak memengaruhi PRD. |
| A-05 | Aplikasi MVP untuk pemakaian pribadi, tidak dipublikasikan ke Google Play pada fase ini. |

## 10. Risiko

| ID | Risiko | Dampak | Mitigasi |
|----|--------|--------|----------|
| R-01 | Format notifikasi Bale by BTN tidak terdokumentasi publik dan berubah tiap update app. | Parser gagal, data bolong. | In-app debug log + editor rule (FR-10); kalibrasi dari perangkat asli. |
| R-02 | Notifikasi ganda/tertunda/hilang (Doze, app di-suppress). | Data duplikat atau bolong. | Dedup (FR-03); panduan whitelist baterai saat onboarding. |
| R-03 | Auto-kategorisasi salah. | Data kategori tidak akurat. | Notifikasi interaktif (FR-05) + halaman koreksi (FR-06). |
| R-04 | OEM/aksesoris mematikan listener (battery optimization, autoclean). | Otomatisasi berhenti diam-diam. | Indikator status listener di app + panduan whitelist. |
| R-05 | Tidak ada sinkronisasi/backup di MVP; HP rusak = data hilang. | Kehilangan data permanen. | Diterima untuk MVP; backup = fase 2. |

## 11. Pertanyaan Terbuka

| ID | Pertanyaan | Dipakai di |
|----|-----------|------------|
| OQ-01 | Apa persisnya format notifikasi Bale by BTN untuk semua tipe transaksi (QRIS, transfer keluar/masuk, biaya admin, tarik tunai) dan apa nilai `packageName`-nya? | A-01, `02-TRD.md` §7, `05-BSD.md` §5, `06-IPD.md` M2.1 |
| OQ-02 | Apakah GoPay mengirim notifikasi untuk semua jenis transaksi (termasuk merchant kecil dan top-up), dan apa nilai `packageName`-nya? | A-02, `02-TRD.md` §7, `05-BSD.md` §5, `06-IPD.md` M2.1 |
