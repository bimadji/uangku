# Spike T-003 — Riverpod vs Provider (batas 1 hari)

> Hasil: **Riverpod** dipilih. Prasyarat T-008.
> Bukti kode: `spikes/state/spike_state_test.dart` — 3 test hijau (loading→data, unit test provider, ChangeNotifier path).

## Perbandingan (dari spike)

| Kriteria | Riverpod | Provider |
|---|---|---|
| Boilerplate async state | `FutureProvider` 1 baris; `when(loading/error/data)` eksplisit | `ChangeNotifier` manual + `_load()` + `notifyListeners()` + flag loading/error sendiri |
| Testability | `ProviderContainer` — unit test state **tanpa widget** (terbukti di test 2) | Perlu widget tree atau manual instantiate; state & UI bercampur di ChangeNotifier |
| AutoDispose/refresh | built-in (`ref.refresh`) — cocok untuk feed yang berubah saat listener/parser aktif | manual (`notifyListeners` orchestration sendiri) |
| Konflik import | perlu prefix `rp.` saat co-exist dengan provider di satu file — non-issue di produksi (satu lib saja) | — |
| Dokumentasi & komunitas | docs.riverpod.dev aktif; pattern FutureProvider→StreamProvider searah dengan kebutuhan listener notifikasi (M2) | docs bagus tapi arsitektur InheritedWidget-centric |

## Alasan utama memilih Riverpod
1. **Fitur M2/M3 butuh state reaktif**: feed transaksi berubah otomatis saat notifikasi masuk (M2) dan saat rule parser diubah (T-020). `StreamProvider`/`FutureProvider` + `ref.watch` menyediakan ini tanpa manual `notifyListeners`.
2. Testability tanpa widget tree = suite test lebih cepat dan lebih fokus (terbukti di spike).
3. Boilerplate lebih sedikit untuk tepat use-case utama app (async state → UI).

## Konsekuensi
- `provider` package dikeluarkan dari pubspec saat T-008 (tidak dipakai produksi; hanya dipakai spike untuk perbandingan).
- Tim pribadi (1 orang): biaya belajar Riverpod ditanggung di T-005 (3–4 hari).
