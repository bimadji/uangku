# Spike T-002 — drift vs Isar (batas 1 hari)

> Hasil: **drift** dipilih. Prasyarat T-006.

## Bukti

### drift 2.35.3 (+ drift_dev 2.35.2, build_runner 2.17.1)
- Codegen jalan: `dart run build_runner build` — 4 output dalam 50 detik.
- Test hijau 3/3 (`spikes/db_drift/spike_drift_test.dart`):
  1. Seed idempotent (lookup by `name` sebelum insert) — 2× run tetap 2 kategori.
  2. `UNIQUE(dedup_hash)` menolak insert duplikat (SQLite constraint).
  3. Agregasi arus kas via SQL `SUM(amount) GROUP BY type`.
- API cocok kebutuhan BSD §7: `schemaVersion` + migrasi satu arah; query type-safe; SQL raw tersedia untuk agregasi.

### Isar — tidak jalan berdampingan dengan toolchain drift
1. `isar: ^3.1.0+1` (rilis resmi) — `pub add` gagal: dependensi tidak null-safe (`sdk >= 2.8.1`).
2. Fork `isar_community 3.3.0-dev.1` + `isar_community_generator` — konflik versi:
   - Generator butuh `build ^4.0.0`; build_runner modern (dibutuhkan drift_dev 2.35: analyzer 13) butuh `build ^5.0.0`.
   - Downgrade build_runner ke rentang `build ^4.0.0` memaksa downgrade analyzer < 9 → konflik dengan drift_dev (butuh analyzer >= 13).
   - Downgrade drift ke 2.28.0 agar analyzer 7 cocok → part file hasil codegen drift mismatch (method runtime hilang: `$_getPrefetchedDataByColumns` di drift_dev 2.35 vs drift 2.28) → test gagal load.
3. Setelah blokir isar generator, `build_runner` tetap hang tak terbatas (terverifikasi berulang; proses dibunuh). Node: konfigurasi drift-only yang sama sebelumnya stabil.
4. Kesimpulan teknis: **tidak ada satu set versi analyzer/build yang menghidupkan drift (versi baru) dan Isar sekaligus** di Flutter 3.47/Dart saat ini.

## Keputusan
**drift.** Alasan utama:
1. Terbukti jalan end-to-end (codegen + 3 test spike hijau) pada toolchain yang sama dengan sisa stack.
2. SQLite murni → `UNIQUE` constraint, index, dan query agregasi (kebutuhan BSD §1 & §4) native, tanpa lapisan tambahan.
3. Isar: dependensi resmi tidak terawat (null-safety gagal resolve), fork komunitas belum stabil (dev release) dan tidak kompatibel toolchain.

## Risiko yang diterima
- drift memaksa build_runner sebagai dev-dep (codegen step) — diterima, CI sudah menjalankannya.
- Spike melebihi batas 1 hari karena debugging resolusi versi Isar; keputusan tetap diambil pada bukti yang cukup (prinsip: buruk-terdokumentasi lebih baik daripada spike panjang).
