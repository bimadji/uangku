# 04 — Design Brief Documentation (DBD): Uangku

> Sumber kebenaran: `brainstorm-finance-app.md`, `docs/01-PRD.md`, `docs/03-AFD.md` (nama layar), serta hasil evaluasi mockup Opsi A (`docs/mockups/option-a/index.html`).

## 1. Arah Desain UI/UX: Clean Card Modern (Opsi A)

- **Gaya Visual**: Terinspirasi dari Copilot iOS — kartu-kartu modular putih di atas latar sejuk (`#F4F6F9`) dengan aksen biru kobalt (`#2563EB`).
- **Karakter**: Kontemporer, bersih, ramah pengguna, santai namun terstruktur dengan hierarki jelas.
- **Satu kata kunci: ringan & modular.** Angka hero dan status sistem langsung dipahami dalam sekali pandang tanpa distraksi visual.
- **Zona Jempol**: Semua kontrol utama (FAB input cepat, bottom sheet keypad, segmented period picker, navigation bar) ditempatkan di separuh bawah layar untuk kemudahan navigasi satu tangan.
- **Bukan Template Generik**: Menghindari elemen dekoratif klise (gradient blobs, drop shadow berlebihan, kartu berikon generik, floating pill melayang). Card dipisahkan oleh elevasi halus dan border netral.

## 2. Prinsip Desain

| # | Prinsip | Turunan req |
|---|---------|-------------|
| 1 | **Input tunai < 5 detik**: maksimal 2 langkah interaksi via bottom sheet keypad (nominal → kategori). | FR-07, NFR-05 |
| 2 | **Koreksi ≤ 2 tap** dari notifikasi interaktif maupun feed transaksi. | FR-05, FR-06 |
| 3 | **Keterlihatan status otomatisasi**: pengguna selalu tahu apakah listener background aktif atau terblokir. | R-04 |
| 4 | **Sumber dana selalu terlihat**: setiap transaksi ber-badge teks `BTN` / `GoPay` / `Tunai` + chip mode `auto` / `manual`. | FR-09 |
| 5 | **Diam saat aman**: tidak berisik; notifikasi interaktif hanya untuk konfirmasi kategori; parse gagal dicatat senyap ke log debug. | FR-10 |

## 3. Palet Warna (Token Opsi A)

| Token | Nilai Hex | Peran & Penggunaan |
|-------|-----------|-------------------|
| `--bg` | `#F4F6F9` | Latar kanvas aplikasi (cool neutral grey) |
| `--surface` | `#FFFFFF` | Latar kartu modular dan sheet |
| `--surface-subtle` | `#F8FAFC` | Latar baris netral, display nominal, input |
| `--fg` | `#0F172A` | Teks utama, judul, angka dominan (Slate 900) |
| `--muted` | `#64748B` | Teks sekunder, label, timestamp (Slate 500) |
| `--border` | `#E2E8F0` | Garis pemisah komponen dan outline kartu (Slate 200) |
| `--accent` | `#2563EB` | Aksen brand Uangku, tombol utama, status aktif (Blue 600) |
| `--accent-subtle` | `#EFF6FF` | Latar chip aktif / highlight seleksi |
| `--success` | `#16A34A` | Pemasukan, status listener aktif (Green 600) |
| `--success-bg` | `#DCFCE7` | Latar badge pemasukan / status OK |
| `--error` | `#DC2626` | Pengeluaran, status listener mati, parse gagal (Red 600) |
| `--error-bg` | `#FEE2E2` | Latar nominal pengeluaran / error banner |
| `--warning` | `#D97706` | Peringatan whitelist baterai / izin parsial (Amber 600) |
| `--warning-bg` | `#FEF3C7` | Latar banner warning |

### Ketentuan Badge Sumber Dana
- Badge sumber dana (`BTN`, `GoPay`, `Tunai`) menggunakan outline monokrom/subtle (bukan warna pekat) agar tidak mendominasi hierarki nominal transaksi.
- Badge BTN: border `#94A3B8`, teks `#475569`.
- Badge GoPay: border `#0EA5E9`, teks `#0369A1`.
- Badge Tunai: border `#16A34A`, teks `#15803D`.
- Chip mode: `auto` (abu-abu muda `#F1F5F9`), `manual` (kuning hangat `#FEF3C7`).

## 4. Tipografi

- **Font Family**: Font sans-serif bawaan platform (`-apple-system`, `Roboto`, `Segoe UI`).
- **Angka Finansial**: Wajib `tabular figures` (`font-variant-numeric: tabular-nums`) di semua daftar, tabel, dan kartu rekap agar digit rata dan mudah dipindai.
- **Hierarki Skala Teks**:
  - *Nominal Hero Dashboard*: 26–32sp, font-weight 800/bold.
  - *Nominal Display Keypad*: 32–36sp, font-weight 800/bold.
  - *Judul Halaman (Screen Title)*: 18–20sp, font-weight 700.
  - *Subjudul / Header Card*: 13–14sp, font-weight 700.
  - *Body / Teks Item*: 13–14sp, font-weight 500/600.
  - *Caption / Timestamp / Mode*: 10–11sp, font-weight 600.
- **Bahasa UI**: Bahasa Indonesia santai dan lugas, tanpa istilah perbankan/akuntansi rumit.

## 5. Komponen UI Inti

| Komponen | Spesifikasi & Isi |
|----------|-------------------|
| `CashFlowCard` | Kartu putih modular: header periode segmented (Hari Ini / Minggu Ini / Bulan Ini), angka hero pengeluaran (merah), row perbandingan pemasukan (hijau) & net cashflow. |
| `CategoryDonutChart` | Donut chart SVG 3–4 segmen warna kontras + legend daftar persentase dan nominal kategori (misal Makanan 60%, Transport 30%, Lainnya 10%). |
| `TransactionTile` | Baris transaksi: avatar ikon kategori (background tint lembut), nama merchant/keterangan, badge sumber (`BTN`/`GoPay`/`Tunai`), chip `auto`/`manual`, nominal di kanan dengan tanda `+`/`-`. |
| `QuickCashSheet` | Modal bottom sheet: drag handle, toggle jenis transaksi (Keluar/Masuk), display nominal besar, keypad angka bulat 3x4 (0-9, 00, backspace), grid chip kategori 1-tap, tombol "Simpan" lebar (>=48dp). |
| `SourceBadge` | Chip outline 10sp: label teks `BTN`, `GoPay`, atau `Tunai`. |
| `ModeChip` | Chip kecil 10sp: label teks `auto` atau `manual`. |
| `StatusBanner` | Banner status listener hardware di puncak Dashboard (hijau = aktif, kuning = baterai perlu dicek, merah = akses notifikasi mati). |
| `ParserLogTile` | Baris riwayat parser: waktu, package name, cuplikan raw text, status chip (`parsed`, `failed`, `ignored`). |

## 6. Daftar Layar & Hierarkinya

| Layar | Hierarki Tampilan (Atas ke Bawah) |
|-------|-----------------------------------|
| **Dashboard** | 1) StatusBanner listener · 2) Segmented period selector · 3) CashFlowCard modular · 4) CategoryDonutChart & legend · 5) Preview transaksi terbaru (3–5 item) + tombol "Lihat Semua" · FAB "+" (Input Cepat). |
| **Transaksi (feed)** | 1) Horizontal filter chips (`Semua`, `BTN`, `GoPay`, `Tunai`) · 2) Header grup tanggal (`Hari Ini`, `Kemarin`, `Tanggal lain`) · 3) Daftar `TransactionTile`; tap baris membuka layar Detail/Koreksi · FAB "+". |
| **Input Cepat Tunai** | Modal Bottom Sheet di atas layar aktif: display nominal `Rp 0` → grid tombol keypad angka → chip kategori pilihan 1 tap → tombol "Simpan Transaksi (Tunai)". |
| **Detail/Koreksi Transaksi** | 1) Card ringkasan sumber dana & waktu pencatatan (read-only) · 2) Input nominal besar (editable) · 3) Input merchant/keterangan · 4) Chip picker kategori · 5) Input catatan pribadi · 6) Tombol "Simpan Perubahan" & "Hapus Transaksi" · 7) Card cuplikan raw notification asli untuk audit. |
| **Log Parser** (dari Pengaturan) | 1) Stat cards ringkas (Parsed / Failed / Ignored) · 2) Section "Uji Rule Regex Lokal" (input raw text, regex pattern, hasil live match, tombol "Uji & Simpan") · 3) Daftar `ParserLogTile` (riwayat 200 notifikasi terakhir). |
| **Pengaturan** | 1) Card status otomatisasi OS (Notification Access, Whitelist Baterai) · 2) Menu list (Log Parser & Regex, Kelola Kategori, Panduan Baterai OEM) · 3) Card komitmen privasi 100% offline & lokal (tanpa izin INTERNET). |
| **Onboarding** | 3 langkah pengaktifan awal: Sambutan privasi → Panduan Notification Access → Panduan Whitelist Baterai (AFD §2). |

## 7. Widget Home Screen & Quick Tile

- **Widget (4x1)**: Format kartu Clean Card — logo Uangku + total pengeluaran hari ini + tombol shortcut "+" untuk membuka langsung `QuickCashSheet`. Angka diperbarui setiap app/sheet dibuka (tidak real-time background).
- **Quick Settings Tile**: Ikon "+" Uangku di system tray Android — tap membuka Activity transparan dengan `QuickCashSheet` untuk pencatatan tunai < 5 detik.

## 8. State Kosong / Loading / Error

| Layar / Area | Kosong (Empty) | Loading | Error |
|--------------|----------------|---------|-------|
| **Dashboard** | Card ajakan: "Belum ada transaksi periode ini. Tap + untuk catat pengeluaran tunai." | Shimmer / skeleton halus pada card arus kas & chart. | Snackbar lokal jika pembacaan DB gagal (tidak ada error jaringan). |
| **Feed Transaksi** | Ilustrasi kartu kosong: "Belum ada riwayat transaksi. Transaksi BTN/GoPay akan muncul otomatis di sini." | Skeleton baris transaksi. | Snackbar lokal. |
| **Log Parser** | Teks keterangan: "Belum ada notifikasi yang ditangkap listener. Pastikan Notification Access sudah diizinkan." | — | — |
| **Uji Rule Regex** | Placeholder contoh format bertanda "Contoh uji". | — | Pesan inline merah di bawah input pattern jika syntax regex tidak valid. |

## 9. Panduan Aksesibilitas

- **Kontras Teks**: Rasio kontras teks terhadap latar belakang minimal 4.5:1 (WCAG AA).
- **Indikator Non-Warna**: Setiap nominal pemasukan selalu didahului tanda `+` dan pengeluaran didahului `-` (tidak mengandalkan warna hijau/merah saja).
- **Target Sentuh**: Semua kontrol interaktif (tombol simpan, segmented button, chip kategori, tombol keypad, nav icon) memiliki area sentuh minimal 48×48dp.
- **Format Numerik**: Pemisah ribuan lokal standar Indonesia (`Rp 25.000`).
- **Skalabilitas Teks**: Mendukung sistem font scale Android hingga 1.3× tanpa pemotongan teks atau layout pecah (bottom sheet dan kartu mendukung vertical scroll).
