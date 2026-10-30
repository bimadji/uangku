# Catatan Hal yang Dilewati & Backlog Pengembangan Masa Depan (Post-MVP)

Dokumen ini mencatat secara transparan seluruh hal teknis, edge case, atau fitur yang sengaja dilewati selama fase eksekusi MVP (T-001 s.d. selesai) beserta risiko dan rencananya ke depan.

---

## 1. Arsitektur Data & Penyimpanan
- **Migrasi Skema Dinamis (T-006)**
  - *Dilewati*: Belum ada pengujian migrasi bertahap antar-versi skema DB (drift schema migration v1 -> v2).
  - *Risiko*: Upgrade tabel di masa depan bisa memicu error jika skema diubah tanpa migrator.
  - *Rencana*: Implementasi script migrasi `schemaVersion` saat ada penambahan kolom/tabel baru.
- **Dependency Triplet `drift_dev` (T-006)**
  - *Dilewati*: Pinning versi `analyzer` dan `build_runner` dilakukan ketat demi menghindari konflik generator.
  - *Rencana*: Re-evaluasi kompatibilitas paket saat upgrade Flutter SDK versi mayor.

## 2. Fitur Transaksi & Feed
- **Pagination Feed Berbasis Cursor (T-007)**
  - *Dilewati*: Feed baru memakai limit/offset sederhana, bukan cursor-based streaming.
  - *Rencana*: Upgrade ke cursor jika transaksi melebihi 5.000 entri.
- **Preferensi Hari Pertama Mingguan (T-007)**
  - *Dilewati*: Perhitungan mingguan mengasumsikan Senin sebagai awal minggu (ISO-8601).
  - *Rencana*: Opsi kustomisasi hari awal minggu (Minggu vs Senin) di Pengaturan.
- **Validasi Format Input Angka Regex (T-019)**
  - *Dilewati*: Form koreksi memakai `int.tryParse` sederhana tanpa pesan error inline jika ada karakter non-digit.
  - *Rencana*: Input formatter otomatis ribuan (`10.000`) dan error text helper.

## 3. Parser & Deduplikasi
- **Pola Notifikasi Belanja GoPay & Transfer Keluar Bale (T-012)**
  - *Dilewati*: Pattern regex belum dibuat karena sampel asli transaksi tersebut belum muncul di perangkat fisik.
  - *Risiko*: Notifikasi belanja GoPay / transfer keluar akan berstatus `failed` di log sampai pattern didaftarkan.
  - *Rencana*: Kalibrasi pattern di T-026 saat sampel nyata terkumpul.
- **Dua Transaksi Sah Nominal & Merchant Sama < 60 Detik (T-013)**
  - *Dilewati*: Jendela toleransi dedup 60 detik statis; transaksi kedua akan tertahan dengan status `ignored`.
  - *Mitigasi*: Pengguna bisa memulihkan transaksi lewat menu Log Parser jika memang sengaja membayar 2x.
  - *Rencana*: Dialog konfirmasi cerdas jika ada 2 notifikasi identik tiba sangat cepat.
- **Variasi Bahasa Sistem Android Non-ID/EN (T-014)**
  - *Dilewati*: Suite fixture baru mencakup Bahasa Indonesia dan istilah perbankan standar.
  - *Rencana*: Dukungan lokalisasi bahasa daerah atau format sistem non-standar.
