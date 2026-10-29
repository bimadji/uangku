# 04 — Design Brief Documentation (DBD): Uangku

> Sumber kebenaran: `brainstorm-finance-app.md`, `docs/01-PRD.md`, `docs/03-AFD.md` (nama layar).

## 1. Arah Desain UI/UX

- **Satu kata kunci: ringan.** Aplikasi keuangan mahasiswa: cepat dibuka, sekali lirik paham, tanpa jargon keuangan.
- Sistem terbuka (hijau/merah) lebih penting dari estetika; angka adalah hero.
- Semua layar bisa dipakai satu tangan; aksi utama di zona jempol (bagian bawah).
- Tidak ada onboarding panjang, tidak ada ajakan upgrade, tidak ada iklan.

## 2. Prinsip Desain

| # | Prinsip | Turunan req |
|---|---------|-------------|
| 1 | **Input tunai < 5 detik**: maksimal 2 langkah interaksi (nominal → kategori). | FR-07, NFR-05 |
| 2 | **Koreksi ≤ 2 tap** dari notifikasi atau feed. | FR-05, FR-06 |
| 3 | **Keterlihatan status otomatisasi**: pengguna selalu tahu listener hidup atau tidak. | R-04 |
| 4 | **Sumber dana selalu terlihat**: setiap transaksi ber-badge BTN / GoPay / Tunai + indikator auto/manual. | FR-09 |
| 5 | **Diam saat aman**: app tidak berisik; notifikasi interaktif hanya untuk konfirmasi kategori; parse gagal diam-diam ke log. | FR-10 |

## 3. Palet Warna

| Token | Peran |
|-------|-------|
| `--surface` | Latar kartu/layar (putih/netral terang; dark mode = fase 2) |
| `--fg` | Teks utama |
| `--muted` | Teks sekunder, timestamp |
| `--accent` | Warna brand Uangku, elemen aktif (usul: teal/biru tua netral-keuangan) |
| `--success` (hijau) | Pemasukan, status listener aktif |
| `--error` (merah) | Pengeluaran, status listener mati, parse gagal |
| `--warning` (kuning) | Banner whitelist baterai / izin belum lengkap |
| `--border` | Pemisah halus |

Badge sumber dana: monokrom outline (bukan warna kuat) agar hierarki angka tidak kalah.

## 4. Tipografi

- **Angka**: tabular figures (font numerik monospaced lebar-konsisten, mis. default font + `fontFeatures: tabularFigures`) agar daftar transaksi rata.
- Nominal besar di dashboard: ukuran hero (~32–40sp), berat semibold.
- Body 14–16sp; label/badge 11–12sp uppercase letter-spacing kecil.
- Bahasa UI: Indonesia santai, tanpa istilah akuntansi.

## 5. Komponen UI Inti

| Komponen | Isi |
|----------|-----|
| `CashFlowCard` | Kartu arus kas: periode (chip Hari Ini/Minggu Ini/Bulan Ini), pemasukan (hijau), pengeluaran (merah). |
| `CategoryDonutChart` | Donut chart kategori + legend 2 kolom, tap segmen → filter feed. |
| `TransactionTile` | Baris feed: ikon kategori, merchant/keterangan, badge sumber (BTN/GoPay/Tunai), chip kecil auto/manual, nominal kanan. |
| `QuickCashSheet` | Bottom sheet input tunai: keypad nominal, grid chip kategori 1 tap, tombol simpan besar. |
| `SourceBadge` | Chip outline kecil: `BTN` / `GoPay` / `Tunai`. |
| `ModeChip` | Chip mini: `auto` / `manual`. |
| `StatusBanner` | Banner status listener/izin (hijau/merah/kuning). |
| `ParserLogTile` | Baris log: waktu, packageName, cuplikan raw text, ikon status sukses/gagal. |

## 6. Daftar Layar

| Layar | Isi & hierarki (atas→bawah) |
|-------|------------------------------|
| **Dashboard** | 1) StatusBanner (hanya jika ada masalah izin) · 2) CashFlowCard + chip periode · 3) CategoryDonutChart · 4) Preview transaksi terbaru (5) + tombol "Lihat semua" · FAB "+" (input cepat). |
| **Transaksi (feed)** | 1) Filter chip: sumber (BTN/GoPay/Tunai) · 2) Grup tanggal · 3) daftar TransactionTile; tap → Detail/Koreksi. |
| **Input Cepat Tunai** | Sheet di atas layar apa pun: keypad nominal → grid kategori → Simpan. Tidak ada field opsional yang menghalangi. |
| **Detail/Koreksi Transaksi** | 1) Nominal besar (editable) · 2) kategori (grid chip) · 3) merchant/keterangan (editable) · 4) sumber + waktu (read-only) · 5) tombol Simpan / Hapus. |
| **Log Parser** (dari Pengaturan) | 1) ringkasan: N notifikasi / N gagal · 2) daftar ParserLogTile; tap entri gagal → Uji Rule Parser. |
| **Uji Rule Parser** | Text field raw text (prefill dari log), daftar rule per app, hasil parse live (tipe/nominal/merchant/waktu), editor regex JSON, tombol Uji & Simpan. |
| **Pengaturan** | 1) Status listener + deep-link Notification access · 2) Status whitelist baterai + panduan OEM · 3) Log Parser · 4) Kelola kategori (lihat urutan) · 5) Tentang (privasi: "data tidak keluar dari perangkat"). |
| **Onboarding** | 3 langkah: sambutan/privasi → izin notification access → whitelist baterai (lihat AFD §2). |

## 7. Widget Home Screen & Quick Tile

- **Widget**: ukuran kecil (4×1) — logo + pengeluaran hari ini + tombol "+" langsung buka QuickCashSheet. Update saat app berjalan; angka tidak real-time (diperbarui saat app/tile dipakai) — catat sebagai batasan.
- **Quick Tile**: ikon "+" Uangku; tap → Activity transparan berisi QuickCashSheet. Satu-satunya fungsi tile (tidak ada toggle).

## 8. State Kosong / Loading / Error

| Layar/area | Kosong | Loading | Error |
|------------|--------|---------|-------|
| Dashboard | Ilustrasi mini + CTA "Catat pengeluaran pertama" + status izin. | Skeleton kartu (jarang terlihat, DB lokal cepat). | Tidak ada error jaringan (offline penuh); DB error → snackbar generik. |
| Feed transaksi | "Belum ada transaksi. Pakai widget tunai atau tunggu notifikasi." | Skeleton baris. | Snackbar. |
| Log Parser | "Belum ada notifikasi masuk. Cek Notification access di Pengaturan." | — | — |
| Uji Rule Parser | Prefill kosong + placeholder contoh format (ditandai "contoh, bukan format asli"). | — | Hasil regex invalid → pesan inline merah di field pattern. |

## 9. Panduan Aksesibilitas

- Kontras teks ≥ 4.5:1 (WCAG AA); hijau/merah tidak jadi satu-satunya pembeda pemasukan/pengeluaran — selalu ada tanda `+`/`−` pada nominal.
- Target sentuh ≥ 48×48dp; chip kategori di QuickCashSheet ≥ 48dp tinggi.
- Semua ikon dengan label `semanticLabel`; urutan fokus layar input: nominal → kategori → simpan.
- Nominal pakai pemisah ribuan lokal (`Rp 25.000`); tidak bergantung warna badge untuk membedakan sumber (teks label tetap ada).
- Mendukung font scale sistem hingga 1.3× tanpa layout rusak (sheet input boleh scroll).
