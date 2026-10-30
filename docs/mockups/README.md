# Perbandingan Mockup Desain UI Uangku

Dokumen ini membandingkan 3 opsi desain visual untuk Uangku yang dirancang berdasarkan referensi Copilot iOS dan Sumeria iOS, serta prinsip-prinsip dari `docs/04-DBD.md`, `docs/03-AFD.md`, dan `docs/01-PRD.md`.

Seluruh mockup dibuat dalam format HTML statis self-contained (lebar mobile 390px) tanpa build step dan dapat dibuka langsung melalui browser di:
- Galeri Bersama: `docs/mockups/index.html`
- Opsi A: `docs/mockups/option-a/index.html`
- Opsi B: `docs/mockups/option-b/index.html`
- Opsi C: `docs/mockups/option-c/index.html`

Tiap opsi mencakup 6 layar lengkap:
1. **Dashboard** (CashFlowCard, breakdown kategori, feed preview, status banner listener)
2. **Transaksi (Feed)** (filter chip BTN/GoPay/Tunai, grouping tanggal, detail badge & mode)
3. **Input Cepat Tunai** (bottom sheet overlay, keypad angka, chip kategori 1-tap, tombol simpan besar)
4. **Detail / Koreksi Transaksi** (edit nominal/kategori/catatan, waktu & sumber read-only, teks notifikasi asli)
5. **Log Parser & Uji Rule** (stat parsed/failed/ignored, editor regex in-app live preview, riwayat 200 notif)
6. **Pengaturan** (diagnostik status listener & battery whitelist, navigasi menu, jaminan privasi 100% lokal)

---

## 1. Opsi A: Clean Card Modern
- **Inspirasi**: Copilot iOS
- **Konsep**: Kartu modular berlapis putih di atas latar abu-abu netral sejuk (`#F4F6F9`), aksen biru kobalt (`#2563EB`), keypad bulat empuk, chart donut ringkas.
- **Kelebihan**:
  - Paling ramah pengguna awam (tampilan aplikasi finansial modern standar industri).
  - Pembagian section sangat tegas berkat kartu modular terpisah.
  - Sangat nyaman digunakan satu tangan di zona jempol.
- **Kekurangan**:
  - Kepadatan informasi sedang (membutuhkan lebih banyak scroll vertikal dibandingkan Opsi C).
- **Kesesuaian Prinsip DBD**:
  - *Input < 5 detik*: Sangat cepat dan natural, keypad bulat mudah dijangkau.
  - *Koreksi ≤ 2 tap*: Tombol aksi dan chip kategori berukuran besar (>48dp).
  - *Status listener*: Banner hijau/kuning kontras tinggi tepat di bawah judul Dashboard.

---

## 2. Opsi B: Editorial Warm Minimal
- **Inspirasi**: Sumeria iOS
- **Konsep**: Tipografi berkarakter (headline serif Georgia/buku kas), garis pemisah halus (hairline border), palet batu hangat (`#FBF9F5` / warm stone), tanpa kartu tebal berlapis.
- **Kelebihan**:
  - Estetika elegan dan personal, memberikan rasa tenang seperti mencatat di buku jurnal pribadi.
  - Memanfaatkan hirarki ukuran teks besar (angka hero hingga 40px) alih-alih kotak kartu.
  - Grafik batang horizontal ringkas hemat ruang vertikal.
- **Kekurangan**:
  - Penggunaan elemen serif memberikan kesan lebih formal dibandingkan aplikasi digital umumnya.
- **Kesesuaian Prinsip DBD**:
  - *Input < 5 detik*: Keypad rapat minimalis langsung fokus pada nominal.
  - *Koreksi ≤ 2 tap*: Layar koreksi bersih dengan garis pemisah jelas.
  - *Status listener*: Terintegrasi rapi sebagai sub-bar status di bagian atas.

---

## 3. Opsi C: Compact High-Density
- **Inspirasi**: Terminal & Ledger Finansial Monospace
- **Konsep**: Font monospace konsisten, border solid tegas 2px, densitas data maksimal, tanpa dekorasi grafis atau warna gradasi lembut.
- **Kelebihan**:
  - Paling efisien dalam menampilkan jumlah transaksi terbanyak per layar tanpa banyak scroll.
  - Sangat cepat dipindai (tabular numbers, format ledger terstruktur).
  - Aksen fungsional hitam-putih kuat dengan penandaan warna terbatas hanya untuk angka debet/kredit.
- **Kekurangan**:
  - Tampilan agak kaku/teknis (developer-centric), kurang dekoratif bagi sebagian pengguna.
- **Kesesuaian Prinsip DBD**:
  - *Input < 5 detik*: Keypad flat tegas ultra-responsif.
  - *Koreksi ≤ 2 tap*: Dialog form padat langsung ke sasaran field.
  - *Status listener*: Indikator teks status hardware selalu tampil di panel sistem.

---

## Ringkasan Matriks Aksesibilitas

Semua opsi memenuhi standar aksesibilitas PRD & DBD:
- Rasio kontras teks terhadap latar belakang minimal 4.5:1 (WCAG AA).
- Tanda `+` dan `-` selalu menyertai nominal selain pembeda warna hijau/merah.
- Seluruh area interaktif (tombol, chip, navigasi, keypad) berukuran minimal 48×48dp.
- Angka selalu menggunakan format tabular (`font-variant-numeric: tabular-nums`).
