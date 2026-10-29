# 06 — Implementation Plan Documentation (IPD): Uangku

> Sumber kebenaran: `brainstorm-finance-app.md` + `docs/01-PRD.md` s.d. `docs/05-BSD.md`.
> Estimasi kasar untuk 1 developer yang baru belajar Flutter/Dart; belajar pemakaian part-time.

## 1. Ringkasan Fase

| Milestone | Isi | Estimasi | DoD ringkas |
|-----------|-----|----------|-------------|
| M0 | Setup & belajar dasar Flutter | 1 minggu | Project build & jalan di device pribadi. |
| M1 | Fondasi data + input manual/tunai | 2 minggu | Tunai tercatat & muncul di dashboard. |
| M2 | Listener + parser + dedup | 2–3 minggu | Notifikasi asli Bale by BTN/GoPay tersimpan otomatis. |
| M3 | Kategorisasi + notifikasi interaktif + koreksi | 1–2 minggu | Koreksi dari notifikasi ≤ 2 tap. |
| M4 | Dashboard penuh + widget/quick tile | 1–2 minggu | Semua FR MVP terpenuhi. |
| M5 | Kalibrasi real-world + MVP stabil | 2–4 minggu (paralel pemakaian) | Metrik PRD tercapai ≥ 90%. |

Total: ~6–8 minggu efektif.

## 2. Task per Milestone (berurutan sesuai dependensi)

### M0 — Setup & Pembelajaran (1 minggu)
- M0.1 Install Flutter SDK, Android Studio/SDK, device USB debugging; jalankan template app di HP.
- M0.2 Pelajari Dart dasar + Riverpod/Provider (dengan latar C++/Python, target 3–4 hari).
- M0.3 Keputusan DB final (drift vs Isar) — spike kecil 1 hari, pilih yang lebih mudah; catat hasil (menuntaskan A-04).
- **DoD**: app template berjalan di device; keputusan DB & state management tercatat.

### M1 — Fondasi Data + Input Tunai (2 minggu)
- M1.1 Skema DB sesuai `05-BSD.md` §1 (tabel `transactions`, `categories`, seed FR-11 idempotent).
- M1.2 `TransactionRepository`: CRUD + agregasi (arus kas per periode, per kategori).
- M1.3 UI Dashboard sederhana (CashFlowCard + daftar) dan layar feed.
- M1.4 QuickCashSheet (nominal + kategori 1 tap) dari FAB — alur AFD §4.
- **DoD**: input tunai dari FAB tersimpan, muncul di dashboard & feed dengan badge `Tunai`/`manual`; input < 5 detik.

### M2 — Listener + Parser + Dedup (2–3 minggu)
- M2.1 **Kumpulkan sampel notifikasi asli** dari Bale by BTN & GoPay (pemakaian normal 5–7 hari, semua tipe: QRIS, transfer keluar/masuk, top-up, biaya admin). Bahan uji suite. *Prasyarat OQ-01/OQ-02.*
- M2.2 Implementasi `UangkuNotificationListener` (Kotlin) + EventChannel kontrak `05-BSD.md` §3; filter `package_name` dari sampel M2.1.
- M2.3 `ParserEngine` + tabel `parser_rules`; tulis pattern awal **dari sampel aktual** (bukan rekaan).
- M2.4 `DedupService` + UNIQUE `dedup_hash` + aturan toleransi (BSD §4); unit test duplikat.
- M2.5 Unit test parser: seluruh sampel M2.1 sebagai fixture (uji ulang bila ada notifikasi baru).
- M2.6 Onboarding izin: notification access + whitelist baterai (AFD §2); indikator status di Pengaturan.
- M2.7 Verifikasi listener hidup setelah reboot & dengan battery optimization aktif (device asli).
- **DoD**: notifikasi asli kedua app tercatat otomatis; duplikat lolos = 0; unit test parser hijau.

### M3 — Kategorisasi + Interaktif + Koreksi (1–2 minggu)
- M3.1 `CategorizerService` (keyword/merchant per kategori, FR-04); unit test.
- M3.2 `LocalNotifService`: notifikasi interaktif dengan tombol **Ubah Kategori** / **Abaikan** (FR-05); deep-link ke Detail/Koreksi.
- M3.3 Layar Detail/Koreksi Transaksi (AFD §5).
- M3.4 Layar Log Parser + Uji Rule Parser (raw text, status, editor regex JSON, uji live — FR-10).
- **DoD**: transaksi salah kategori bisa dikoreksi ≤ 2 tap dari notifikasi; rule regex bisa diubah in-app tanpa build ulang.

### M4 — Dashboard Penuh + Widget/Tile (1–2 minggu)
- M4.1 Chart kategori (fl_chart) + picker periode harian/mingguan/bulanan (FR-08).
- M4.2 Filter sumber di feed + badge sumber/mode konsisten (FR-09).
- M4.3 Widget home screen (`home_widget`) + Quick Tile (Kotlin TileService) → QuickCashSheet (FR-07).
- M4.4 Empty/loading/error states per `04-DBD.md` §8; aksesibilitas (DBD §9).
- **DoD**: seluruh FR-01..FR-12 terpenuhi; audit manual terhadap PRD.

### M5 — Kalibrasi Real-World + Stabilisasi (2–4 minggu, paralel pemakaian sehari-hari)
- M5.1 Pakai app untuk keuangan nyata; catat semua parse gagal/bolong lewat Log Parser.
- M5.2 Kalibrasi pattern dari kasus nyata; tambahkan fixture baru ke suite.
- M5.3 Ukur metrik PRD §8 (target ≥ 90%).
- M5.4 Perbaikan kecil UX dari pemakaian; hentikan logging sensitif di build rilis (TRD §6).
- **DoD**: metrik tercapai; app stabil dipakai harian 2–4 minggu; MVP selesai.

## 3. Strategi Pengujian dengan Sampel Notifikasi Asli

1. **Pengumpulan (M2.1)**: selama 5–7 hari, semua notifikasi Bale by BTN & GoPay dicatat raw (text + packageName + postTime) — via aplikasi sementara/debug log, karena parser belum ada.
2. **Fixture**: tiap sampel unik jadi test case `{raw → expected(tipe, nominal, merchant, waktu)}` di suite unit `ParserEngine`. Tidak ada fixture rekaan.
3. **Regresi**: notifikasi format baru yang gagal → ditambahkan sebagai fixture sebelum pattern diperbaiki.
4. **Dedup**: replika notifikasi ganda/tertunda dari sampel nyata (kirim ulang payload sama dengan offset waktu) ke unit test `DedupService`.
5. **Integration device asli**: checklist M2.7 (reboot, Doze, whitelist), emulator tidak memadai.
6. **Metrik hidup (M5)**: rasio parse sukses dihitung dari tabel `parser_logs` (status `parsed` vs `failed`).

## 4. Definition of Done per Milestone

| M | Definition of Done |
|---|--------------------|
| M0 | Template app jalan di device fisik; keputusan DB & state management tertulis. |
| M1 | Tunai tersimpan via FAB; tampil di dashboard/feed; agregasi arus kas benar untuk data uji; input < 5 detik. |
| M2 | Notifikasi asli kedua app otomatis tersimpan; unit test parser (semua fixture) & dedup hijau; listener aktif setelah reboot; onboarding izin lengkap. |
| M3 | Koreksi kategori dari notifikasi ≤ 2 tap; Log Parser + Uji Rule berfungsi; rule berubah tanpa recompile. |
| M4 | FR-01..FR-12 terpenuhi; widget & tile berfungsi; state kosong/error ada; audit PRD lulus. |
| M5 | Metrik PRD ≥ 90%; dipakai harian 2–4 minggu tanpa data bolong yang tak terjelaskan; MVP dinyatakan selesai. |

## 5. Risiko Implementasi & Task Mitigasi

| Risiko | Task terkait |
|--------|--------------|
| Plugin listener tidak stabil / background isolate bermasalah | M2.2 — fallback: bridge Kotlin custom dengan broadcast + engine restart ringan (TRD §5). Dialokasikan buffer di estimasi M2. |
| Sampel notifikasi tidak lengkap (tipe transaksi tertentu jarang) | M2.1 diperpanjang; tipe tanpa sampel ditandai "belum didukung" di Log Parser, bukan dikarang. |
| OEM mematikan listener | M2.6/M2.7 — indikator status + panduan whitelist; diuji di device pengguna. |
| DB spike molor | M0.3 dibatasi 1 hari; keputusan buruk-dokumentasi lebih baik daripada spike panjang. |
