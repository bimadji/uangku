# 07 — Execution Plan Documentation: Uangku

> Pemecah milestone `docs/06-IPD.md` (M0..M5) menjadi tugas kecil: **satu tugas = satu PR** yang mudah direview.
> Sumber kebenaran: `brainstorm-finance-app.md`, `docs/01-PRD.md` s.d. `docs/06-IPD.md`. Tidak ada keputusan desain baru di dokumen ini.
> File target eksekusi: file ini. Eksekusi tugas TIDAK termasuk dokumen ini — dimulai setelah persetujuan terpisah.

---

## 1. Aturan Kerja

### 1.1 Alur Kerja Git (berlaku untuk SEMUA tugas)
1. **Satu PR = satu tugas.** Setiap tugas dikerjakan di branch sendiri `feat/<id>-<slug>` (lihat tabel tugas).
2. Alur: buat branch dari `main` → kerjakan → push → buka PR ke `main` → **semua test hijau sebelum merge** → merge.
3. Test gagal = **perbaiki akar masalah**. Jangan pernah menghapus atau melemahkan test agar lulus.
4. Merge **tanpa menghapus branch** (branch disimpan sebagai riwayat).
5. Identitas git di repo lokal: `git config user.name bimadji`, `git config user.email` dari akun GitHub `bimadji` (sudah login via `gh` keyring — scopes: `gist, read:org, repo`).
6. Autentikasi hanya via `gh` keyring yang sudah ada. **Tanpa token/kredensial di file, commit, atau log.**
7. **Auth gagal = berhenti dan laporkan.** Tanpa fallback, tanpa workaround kredensial.
8. **Tanpa force-push ke `main`; tanpa rewrite riwayat commit yang sudah ter-merge.**
9. Pengecualian T-001: repo remote `github.com/bimadji/uangku` kosong (terverifikasi), jadi commit pertama (docs + `brainstorm-finance-app.md` apa adanya) langsung ke `main`, bukan via PR. Mulai T-002, semua via PR.

### 1.2 Laporan Setelah Tiap Tugas (T-xxx)
Setelah PR ter-merge (atau saat berhenti karena gagal), tulis ringkasan langsung di terminal sebagai balasan biasa. Jangan membuat file laporan atau changelog. Gunakan bahasa Indonesia yang mudah dipahami dan teks polos yang rapi di terminal (tanpa tabel, tanpa heading markdown, tanpa blok kode panjang).

Format dasar:

T-xxx: judul tugas | PR: <link> | check: <hijau/gagal>

Lalu per file atau komponen yang berubah:
  <path file>
  Apa: ditambah / diubah / dihapus apa (nama kelas atau fungsi).
  Gunanya: fungsi perubahan itu bagi aplikasi, bahasa sederhana.
  Kenapa: alasannya (kaitkan ke FR/NFR, keputusan di docs, atau masalah yang ditemukan).

Aturan laporan:
- Kelompokkan per file/komponen, bukan per commit; perubahan sepele (format, import) cukup satu baris gabungan.
- Sebutkan apa yang sengaja TIDAK diubah jika sekilas tampak perlu.
- Laporkan penyimpangan dari plan (tugas bertambah, berkurang, berubah) beserta alasannya; perubahan di luar scope harus disebut terang-terangan.
- Sebutkan test yang dijalankan dan hasilnya, serta hal yang belum bisa diverifikasi (misal butuh perangkat fisik) sebagai tugas manual untukku.
- Tutup dengan satu baris: tugas berikutnya dan apakah ada yang menungguku.
- Ringkas dan padat; jangan menempel kode panjang kecuali perlu.

### 1.3 Backlog Hal yang Dilewati (`docs/BACKLOG-FUTURE.md`)
Tiap kali menyelesaikan satu tugas T-xxx, catat **SEMUA** hal yang sengaja atau terpaksa dilewati ke `docs/BACKLOG-FUTURE.md` (buat file jika belum ada). Ini berbeda dari laporan terminal: laporan terminal tetap hanya di terminal, sedangkan backlog ini adalah satu-satunya file yang boleh diperbarui sebagai bagian dari laporan tugas.

Yang dicatat: fitur atau detail yang tidak dikerjakan, edge case yang belum ditangani, keputusan yang ditunda, TODO yang ditinggalkan di kode, asumsi yang belum terverifikasi, dan verifikasi manual yang belum dilakukan. Termasuk hal kecil. Kalau tidak ada yang dilewati, tulis "Tidak ada" untuk tugas itu, jangan dilewatkan begitu saja.

Format tiap entri (satu entri per hal yang dilewati):

## T-xxx: judul tugas
- Dilewati: apa yang tidak dikerjakan, spesifik.
- Risiko: dampaknya bila dibiarkan, spesifik dan konkret.
- Terkait: requirement (FR/NFR), file, atau tugas yang terdampak.
- Saran: kapan atau tugas mana yang sebaiknya menanganinya (T-xxx berikutnya, fase 2, atau butuh keputusan pengguna).

Aturan:
1. **Jujur dan lengkap**: jangan menyaring hal yang dianggap sepele atau yang membuat hasil kerja tampak kurang. Risiko ditulis apa adanya, bukan dilunakkan.
2. **Jangan menduplikasi**: kalau satu hal sudah tercatat dari tugas sebelumnya, perbarui entri lama (tambahkan keterangan) alih-alih menulis ulang. Kalau suatu tugas menyelesaikan item lama, tandai item itu "Selesai di T-xxx" dan jangan dihapus.
3. **Perbarui file ini di PR yang sama dengan tugasnya** (alur Git yang berlaku: branch, PR, check hijau, merge, branch tidak dihapus).
4. Di laporan terminal akhir tugas, tambahkan satu bagian **"Dilewati dan risiko"** yang meringkas entri baru, supaya pengguna tahu tanpa membuka file.
5. Jangan memasukkan hal yang sebenarnya bagian dari scope tugas dan belum selesai; itu berarti tugasnya belum selesai, bukan backlog.

## 2. Branch Protection (diaktifkan di T-001 via `gh api`)

Rencana langkah (dijalankan setelah workflow CI ada dan pernah hijau minimal sekali):

- Required status checks: **`flutter-analyze`** dan **`flutter-test`** (nama job dari workflow T-001).
- Blokir force-push ke `main`.
- Branch tidak dihapus saat merge.
- Bila `gh api` ditolak (scope token kurang): berhenti di langkah itu saja, laporkan, lanjut tugas lain tanpa branch protection.

Workflow CI (T-001): GitHub Actions dengan `subosito/flutter-action` + `setup-java` (Temurin 17); tiga job — `flutter pub get` + `flutter analyze`, `flutter test`, `flutter build apk --debug`.

## 3. Legenda Field Tugas

| Field | Arti |
|-------|------|
| **ID** | `T-0xx`, unik, dirujuk di kolom dependensi. |
| **Branch** | `feat/<id>-<slug>` untuk PR. |
| **Dep** | Tugas yang harus selesai (merge) sebelum tugas ini mulai. |
| **Cover** | FR/NFR PRD yang disentuh (sumber `docs/01-PRD.md`). |
| **Perubahan** | Apa yang dikerjakan; eksplisit apa yang TIDAK (eksklusi). |
| **Kriteria sukses** | Terverifikasi: perintah/test/checklist yang bisa dilihat hasilnya. |
| **Ukuran** | S = ≤ 1 hari, < 200 LOC; M = 1–2 hari, < 500 LOC. |
| **MANUAL** | Tugas milik pengguna (bukan kode). |
| **Verifikasi manual** | Butuh perangkat fisik / tindakan pengguna untuk memverifikasi (checklist). |
| **SPIKE** | Eksperimen berbatas waktu 1 hari; hasil = keputusan tercatat, bukan kode produksi. |

## 4. Tabel Ringkas Tugas

| ID | Milestone | Judul | Dep | Ukuran | Jenis |
|----|-----------|-------|-----|--------|-------|
| T-001 | M0 | Setup repo + CI + branch protection | — | S | kode |
| T-002 | M0 | Spike DB: drift vs Isar | T-001 | S | SPIKE |
| T-003 | M0 | Spike state management: Riverpod vs Provider | T-001 | S | SPIKE |
| T-004 | M0 | Spike listener: plugin vs bridge Kotlin custom | T-001 | S | SPIKE |
| T-005 | M0 | Belajar Dart/Flutter dasar + template app di device | T-002, T-003 | S | verifikasi manual |
| T-006 | M1 | Skema DB + seed kategori idempotent | T-002, T-005 | M | kode |
| T-007 | M1 | TransactionRepository: CRUD + agregasi | T-006 | M | kode |
| T-008 | M1 | Dashboard sederhana + layar feed | T-003, T-007 | M | kode |
| T-008B | M1 | **Mockup Desain UI (3 Opsi)** | T-008 | S | desain |
| T-009 | M1 | QuickCashSheet dari FAB | T-008 | M | kode |
| T-010 | M2 | **MANUAL**: kumpulkan sampel notifikasi asli | T-005 | S | MANUAL |
| T-011 | M2 | NotificationListener (Kotlin) + EventChannel | T-004, T-010 | M | kode |
| T-012 | M2 | ParserEngine + parser_rules dari sampel aktual | T-006, T-011 | M | kode |
| T-013 | M2 | DedupService + UNIQUE dedup_hash | T-012 | M | kode |
| T-014 | M2 | Suite unit test parser (fixture sampel M2.1) | T-012 | M | kode |
| T-015 | M2 | Onboarding izin + indikator status | T-011 | M | kode |
| T-016 | M2 | Verifikasi listener pasca-reboot & whitelist baterai | T-015 | S | verifikasi manual |
| T-017 | M3 | CategorizerService (keyword/merchant) | T-012 | M | kode |
| T-018 | M3 | LocalNotifService: notifikasi interaktif | T-013, T-017 | M | kode |
| T-019 | M3 | Layar Detail/Koreksi Transaksi | T-008 | M | kode |
| T-020 | M3 | Log Parser + Uji Rule Parser | T-012, T-019 | M | kode |
| T-021 | M4 | Chart kategori + picker periode | T-008 | M | kode |
| T-022 | M4 | Filter sumber feed + badge konsisten | T-008 | S | kode |
| T-023 | M4 | Widget home screen + Quick Tile | T-009 | M | kode |
| T-024 | M4 | Empty/loading/error states + aksesibilitas | T-008, T-019, T-020, T-021, T-022 | M | kode |
| T-025 | M5 | **MANUAL**: pemakaian nyata harian + catat kegagalan | T-016 | S | MANUAL |
| T-026 | M5 | Kalibrasi pattern dari kasus nyata | T-025 | S | kode |
| T-027 | M5 | Ukur metrik PRD §8 | T-025 | S | kode |
| T-028 | M5 | Perbaikan UX kecil + matikan logging rilis | T-026 | S | kode |

---

## 5. Detail Tugas

### M0 — Setup & Pembelajaran

#### T-001 — Setup repo + CI + branch protection
- **Branch**: commit pertama langsung ke `main` (repo remote kosong — lihat §1 poin 9); workflow di branch `feat/t-001-ci`.
- **Dep**: —
- **Cover**: NFR-06 (dasar maintainability), seluruh tugas berikut (prasyarat proses).
- **Perubahan**:
  1. `git init` lokal; `git config user.name bimadji` + `user.email` dari akun GitHub `bimadji`.
  2. Commit awal: seluruh `docs/*.md` + `brainstorm-finance-app.md` **apa adanya**; push `main`.
  3. Scaffold project Flutter minimal (`flutter create`) — cukup untuk CI bisa jalan.
  4. Workflow GitHub Actions: `subosito/flutter-action` + `setup-java` (Temurin 17); job `flutter-analyze` (`pub get` + `analyze`) dan `flutter-test` (`test`), plus build debug APK.
  5. Branch protection via `gh api`: required checks `flutter-analyze` + `flutter-test`, block force-push, tanpa delete-on-merge (§2).
- **Eksklusi**: tidak ada kode fitur.
- **Kriteria sukses**: `main` berisi docs + project; workflow hijau di GitHub Actions; PR uji (boleh dari branch throwaway) terblokir sebelum check hijau; force-push ke `main` ditolak.
- **Ukuran**: S.
- **Catatan**: bila `gh api` ditolak → stop langkah 5 saja, laporkan, lanjut (A2).

#### T-002 — Spike DB: drift vs Isar (menuntaskan A-04, sisi DB)
- **Branch**: `feat/t-002-spike-db`
- **Dep**: T-001
- **Cover**: A-04; prasyarat T-006.
- **Perubahan**: prototipe kecil skema `transactions` + `categories` (BSD §1) di kedua library; bandingkan: ergonomi migrasi (BSD §7), query agregasi, seed idempotent, dukungan UNIQUE constraint. **Batas waktu 1 hari** — keputusan buruk-terdokumentasi lebih baik daripada spike panjang (risiko IPD §5).
- **Eksklusi**: tidak ada UI; hasil spike tidak langsung merge ke `main` sebagai kode produksi — hanya keputusan.
- **Kriteria sukses**: hasil perbandingan tercatat di §8 (Keputusan Spike) dokumen ini, termasuk alasan; T-006 memakai pemenangnya.
- **Ukuran**: S.

#### T-003 — Spike state management: Riverpod vs Provider
- **Branch**: `feat/t-003-spike-state`
- **Dep**: T-001
- **Cover**: A-04; prasyarat T-008.
- **Perubahan**: layar kecil dengan state async (simulasi feed) di kedua pendekatan; bandingkan boilerplate, testability, documentation. **Batas waktu 1 hari.**
- **Eksklusi**: tidak menyentuh DB/listener.
- **Kriteria sukses**: keputusan tercatat di §8; T-008 memakai pemenangnya.
- **Ukuran**: S.

#### T-004 — Spike listener: plugin `flutter_notification_listener` vs bridge Kotlin custom
- **Branch**: `feat/t-004-spike-listener`
- **Dep**: T-001
- **Cover**: FR-01 (eksplorasi), NFR-04; risiko IPD §5.
- **Perubahan**: uji plugin kandidat di device: apakah event diterima saat app mati (background isolate), apakah bisa filter `packageName`; bandingkan dengan bridge Kotlin minimal (BSD §3 kontrak). **Batas waktu 1 hari.**
- **Eksklusi**: **tanpa pattern parser, tanpa asumsi format notifikasi** (OQ-01/OQ-02 masih terbuka); tidak menulis kontrak final.
- **Kriteria sukses**: keputusan tercatat di §8, termasuk strategi background isolate; T-011 memakai pemenangnya.
- **Ukuran**: S.

#### T-005 — Belajar Dart/Flutter dasar + template app di device (M0.1+M0.2)
- **Branch**: `feat/t-005-learning` (catatan belajar bila ada; umumnya tanpa perubahan kode)
- **Dep**: T-002, T-003 (agar belajar memakai stack yang dipilih)
- **Cover**: prasyarat seluruh tugas koding.
- **Perubahan**: install Flutter SDK + Android Studio/SDK + USB debugging (lokal); pelajari Dart dasar + state management terpilih (target 3–4 hari, latar C++/Python).
- **Eksklusi**: tidak ada fitur.
- **Kriteria sukses**: **verifikasi manual** — checklist:
  - [ ] `flutter doctor` tanpa error di mesin lokal.
  - [ ] Template app ter-install dan jalan di HP pribadi via USB.
- **Ukuran**: S.

### M1 — Fondasi Data + Input Tunai

#### T-006 — Skema DB + seed kategori idempotent (M1.1)
- **Branch**: `feat/t-006-db-schema`
- **Dep**: T-002, T-005
- **Cover**: FR-11, FR-12; BSD §1, §7.
- **Perubahan**: tabel `transactions`, `categories` sesuai BSD §1.1–1.2 (kolom, constraint, index `idx_tx_occurred`, `idx_tx_category`, `UNIQUE(dedup_hash)`); seed FR-11 idempotent (insert-or-ignore by `name`+`kind`); `parser_rules` + `parser_logs` (§1.3–1.4) boleh ikut di sini atau di T-012 — diputuskan di PR.
- **Eksklusi**: tanpa repository/UI; tanpa `parser_rules` pattern (menunggu sampel M2.1).
- **Kriteria sukses**: unit test skema + seed idempotent (jalankan seed 2× → jumlah baris kategori tetap); CI hijau.
- **Ukuran**: M.

#### T-007 — TransactionRepository: CRUD + agregasi (M1.2)
- **Branch**: `feat/t-007-repository`
- **Dep**: T-006
- **Cover**: FR-08, FR-09 (data layer), FR-12.
- **Perubahan**: CRUD transaksi; agregasi arus kas per periode (harian/mingguan/bulanan) dan per kategori; feed kronologis (`idx_tx_occurred`).
- **Eksklusi**: tanpa listener; tanpa UI.
- **Kriteria sukses**: unit test agregasi dengan data uji tetap (kasus: transaksi lintas batas periode, income vs expense); CI hijau.
- **Ukuran**: M.

#### T-008 — Dashboard sederhana + layar feed (M1.3)
- **Branch**: `feat/t-008-dashboard-feed`
- **Dep**: T-003, T-007
- **Cover**: FR-08 (bagian), FR-09 (badge), FR-12.
- **Perubahan**: navigasi 3 tab (AFD §1); CashFlowCard + daftar; layar feed dengan badge `Tunai`/`BTN`/`GoPay` + chip `auto`/`manual` (komponen DBD §5); chart kategori menyusul di T-021.
- **Eksklusi**: tanpa chart (T-021); tanpa filter chip (T-022); tanpa widget/tile (T-023).
- **Kriteria sukses**: widget test: dashboard render agregasi dari repository uji benar; feed menampilkan badge sumber sesuai data; CI hijau.
- **Ukuran**: M.

#### T-009 — QuickCashSheet dari FAB (M1.4)
- **Branch**: `feat/t-009-quick-cash`
- **Dep**: T-008
- **Cover**: FR-07 (FAB saja), NFR-05.
- **Perubahan**: QuickCashSheet (keypad nominal + chip kategori 1 tap, AFD §4) dibuka dari FAB; simpan → `source=CASH`, `origin=manual`, `occurred_at`=sekarang; haptic feedback.
- **Eksklusi**: tanpa widget home screen / quick tile (T-023); tanpa field catatan wajib.
- **Kriteria sukses**: widget test alur input; **verifikasi manual**: input tunai di device < 5 detik (checklist §7).
- **Ukuran**: M.

### M2 — Listener + Parser + Dedup

#### T-010 — **MANUAL**: kumpulkan sampel notifikasi asli (M2.1)
- **Milik**: pengguna (bukan kode). Tidak ada PR.
- **Dep**: T-005 (device siap; app debug dari spike T-004 boleh dipakai untuk mencatat, atau catat manual)
- **Cover**: OQ-01, OQ-02; prasyarat seluruh M2.
- **Instruksi**:
  1. Pakai Bale by BTN & GoPay **normal** selama **5–7 hari**.
  2. Metode pencatatan (urut preferensi):
     a. **Collector app debug** (hasil T-004): listener mencatat setiap notifikasi Bale/GoPay; buka app, copy/share entri → tempel ke file sampel.
     b. **`adb logcat -d`** via USB (grep `packageName` app sumber) — text + postTime tersedia di log.
     c. **Screenshot** hanya backup; text diketik ulang dan entri ditandai `"text_from_screenshot": true`.
     Screenshot/keyboard manual BUKAN sumber utama: `packageName` & `post_time` presisi wajib dari sistem.
  3. Untuk **setiap** notifikasi transaksi, catat: raw text lengkap, `packageName`, dan `postTime`.
  4. Targetkan semua tipe: QRIS, transfer keluar, transfer masuk, top-up, biaya admin, tarik tunai. Tipe yang tidak muncul selama periode → catat "belum ada sampel" (jangan dikarang — mitigasi risiko IPD §5).
- **Format sampel yang dibutuhkan** (satu entri JSON per notifikasi, kumpulkan di file lokal):
  ```json
  {
    "package_name": "<dari perangkat asli>",
    "title": "<judul notifikasi apa adanya>",
    "text": "<isi notifikasi apa adanya, tanpa diedit>",
    "post_time": 1730000000000,
    "post_time_iso": "<ISO-8601 bila mudah, opsional>",
    "expected": {
      "tx_type": "expense | income",
      "amount": 25000,
      "merchant": "<bila terlihat dari text, else null>"
    }
  }
  ```
- **Eksklusi**: TIDAK boleh membuat/menebak pattern regex dari sampel saat pengumpulan — itu tugas T-012.
- **Kriteria sukses**: ≥ 1 sampel per tipe utama (QRIS, transfer keluar, transfer masuk, top-up) per app; `packageName` kedua app tercatat. Tipe tanpa sampel ditandai eksplisit.
- **Ukuran**: S (5–7 hari kalender, effort rendah).

#### T-011 — NotificationListener (Kotlin) + EventChannel (M2.2)
- **Branch**: `feat/t-011-listener`
- **Dep**: T-004, **T-010** (whitelist `package_name` dari sampel nyata)
- **Cover**: FR-01, NFR-03, NFR-04; BSD §3.
- **Perubahan**: `UangkuNotificationListener` extends `NotificationListenerService` (atau plugin terpilih di T-004 + konfigurasi); filter `package_name` dari sampel T-010 di sisi Kotlin; forward payload (`package_name`, `title`, `text`, `post_time`, `key`) via EventChannel `uangku/notif_events`; MethodChannel `uangku/platform` (4 method BSD §3).
- **Eksklusi**: tanpa parser; tanpa dedup; tanpa UI.
- **Kriteria sukses**: unit/instrumented test payload kontrak sesuai BSD §3; **verifikasi manual**: notifikasi uji dari app sumber terlihat di log debug app (checklist §7).
- **Ukuran**: M.

#### T-012 — ParserEngine + parser_rules dari sampel aktual (M2.3)
- **Branch**: `feat/t-012-parser`
- **Dep**: T-006, T-011, **T-010**
- **Cover**: FR-02, NFR-02, NFR-06; BSD §1.3, §5.
- **Perubahan**: `ParserEngine` eksekusi rule regex per-`packageName`; ekstrak `amount` (wajib), `merchant`/`event_time` (opsional, fallback sesuai BSD §5); tabel `parser_rules` + tulis pattern awal **hanya dari sampel aktual T-010**; status sukses/gagal ke `parser_logs`.
- **Eksklusi**: **tanpa pattern rekaan** — regex untuk tipe tanpa sampel tidak dibuat, ditandai "belum didukung" di Log Parser; tanpa dedup (T-013); tanpa kategorisasi (T-017).
- **Kriteria sukses**: unit test seluruh fixture sampel T-010 hijau; parse target < 10 ms (test timing kasar); rule format JSON sesuai BSD §5.
- **Ukuran**: M.

#### T-013 — DedupService + UNIQUE dedup_hash (M2.4)
- **Branch**: `feat/t-013-dedup`
- **Dep**: T-012
- **Cover**: FR-03; BSD §4.
- **Perubahan**: hash kanonikal (`source`,`amount`,`merchant` uppercase/trim, `occurred_at` bucket 60 detik); dua lapis (lookup + UNIQUE constraint, BSD §4 poin 3); entri log status `ignored` untuk duplikat.
- **Eksklusi**: tanpa perubahan parser; tanpa UI.
- **Kriteria sukses**: unit test: duplikat identik terbuang; hampir-identik (beda < 60 s) terbuang; beda > 60 s lolos; urutan terbalik aman; log `ignored` tercatat.
- **Ukuran**: M.

#### T-014 — Suite unit test parser penuh (M2.5)
- **Branch**: `feat/t-014-parser-tests`
- **Dep**: T-012 (bisa paralel dengan T-013 bila kontrak stabil)
- **Cover**: FR-02; strategi testing TRD §7.
- **Perubahan**: seluruh sampel T-010 sebagai fixture `{raw → expected}`; skrip/soal regenerasi fixture mudah; fixture untuk kasus duplikat dedup (payload sama, offset waktu).
- **Eksklusi**: tanpa fixture rekaan.
- **Kriteria sukses**: `flutter test` hijau dengan seluruh fixture; dokumentasi singkat cara menambah fixture baru (dipakai lagi di T-026).
- **Ukuran**: M.

#### T-015 — Onboarding izin + indikator status (M2.6)
- **Branch**: `feat/t-015-onboarding`
- **Dep**: T-011
- **Cover**: FR-01 (grant), FR-12, NFR-01; AFD §2; mitigasi R-04.
- **Perubahan**: onboarding 3 langkah (sambutan/privasi → notification access deep-link → panduan whitelist baterai per-OEM); izin `POST_NOTIFICATIONS` runtime; indikator status listener + whitelist di Pengaturan; banner peringatan di Dashboard bila izin belum lengkap (AFD §8).
- **Eksklusi**: tanpa `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` otomatis (TRD §4); tanpa fitur Pengaturan lain.
- **Kriteria sukses**: widget test alur onboarding; cek status via `NotificationManagerCompat.getEnabledListenerPackages()` benar; **verifikasi manual** di checklist §7.
- **Ukuran**: M.

#### T-016 — Verifikasi listener pasca-reboot & whitelist baterai (M2.7)
- **Branch**: `feat/t-016-device-verify` (laporan hasil di PR, atau perbaikan kecil bila ditemukan bug)
- **Dep**: T-015
- **Cover**: NFR-04; mitigasi R-02, R-04.
- **Jenis**: **verifikasi manual** — emulator tidak memadai (TRD §7). Checklist di §7.
- **Kriteria sukses**: seluruh checklist §7.1 lulus di device pengguna; temuan gagal → bug fix di PR ini.
- **Ukuran**: S.

### M3 — Kategorisasi + Interaktif + Koreksi

#### T-017 — CategorizerService (M3.1)
- **Branch**: `feat/t-017-categorizer`
- **Dep**: T-012
- **Cover**: FR-04; BSD §1.2 (`keywords`).
- **Perubahan**: match keyword/merchant → kategori default (seed FR-11); fallback `Lainnya` (per kind); isi kolom `keywords` seed dari sampel T-010 (merchant nyata).
- **Eksklusi**: tanpa pembelajaran dari koreksi (fase 2); tanpa UI.
- **Kriteria sukses**: unit test keyword/merchant → kategori benar + fallback; CI hijau.
- **Ukuran**: M.

#### T-018 — LocalNotifService: notifikasi interaktif (M3.2)
- **Branch**: `feat/t-018-local-notif`
- **Dep**: T-013, T-017
- **Cover**: FR-05; AFD §3; izin `POST_NOTIFICATIONS` (TRD §4).
- **Perubahan**: `flutter_local_notifications` setelah transaksi tersimpan; tombol **Ubah Kategori** (deep-link Detail/Koreksi) dan **Abaikan** (tutup notifikasi, transaksi tetap).
- **Eksklusi**: tanpa notifikasi untuk parse gagal (AFD §8: diam saat aman).
- **Kriteria sukses**: widget/instrumented test deep-link; **verifikasi manual**: dari notifikasi, koreksi tercapai ≤ 2 tap (checklist §7).
- **Ukuran**: M.

#### T-019 — Layar Detail/Koreksi Transaksi (M3.3)
- **Branch**: `feat/t-019-detail-koreksi`
- **Dep**: T-008
- **Cover**: FR-06; AFD §5; DBD §6.
- **Perubahan**: layar edit kategori/nominal/catatan; sumber + waktu read-only; Simpan/Hapus (hard delete); badge auto/manual tetap tampak.
- **Eksklusi**: koreksi tidak mengubah rule parser otomatis (fase 2).
- **Kriteria sukses**: widget test edit + simpan + hapus; akses dari feed dan deep-link notifikasi.
- **Ukuran**: M.

#### T-020 — Log Parser + Uji Rule Parser (M3.4)
- **Branch**: `feat/t-020-parser-log-ui`
- **Dep**: T-012, T-019
- **Cover**: FR-10, NFR-06; AFD §6; TRD §6 (retensi).
- **Perubahan**: layar Log Parser (ringkasan + daftar ParserLogTile, retensi LRU 200 entri, tombol hapus); layar Uji Rule Parser (raw text prefill, hasil parse live, editor regex JSON, Uji & Simpan).
- **Eksklusi**: tanpa update rule remote (TRD §8.4).
- **Kriteria sukses**: widget test uji rule live; regex invalid → pesan inline merah; **verifikasi manual**: rule diubah in-app tanpa build ulang dan transaksi berikutnya memakai rule baru (checklist §7).
- **Ukuran**: M.

### M4 — Dashboard Penuh + Widget/Tile

#### T-021 — Chart kategori + picker periode (M4.1)
- **Branch**: `feat/t-021-chart-periode`
- **Dep**: T-008
- **Cover**: FR-08; AFD §7; DBD §5.
- **Perubahan**: `fl_chart` donut/bar + legend 2 kolom; tap segmen → filter feed; chip periode Hari Ini/Minggu Ini/Bulan Ini.
- **Eksklusi**: tanpa budget (fase 2).
- **Kriteria sukses**: widget test chart render agregasi benar; periode switch mengubah angka.
- **Ukuran**: M.

#### T-022 — Filter sumber feed + badge konsisten (M4.2)
- **Branch**: `feat/t-022-feed-filter`
- **Dep**: T-008
- **Cover**: FR-09.
- **Perubahan**: filter chip sumber (BTN/GoPay/Tunai) di feed; audit semua badge sumber + mode chip konsisten dengan DBD §5.
- **Eksklusi**: tanpa perubahan data layer.
- **Kriteria sukses**: widget test filter; badge konsisten di semua layar.
- **Ukuran**: S.

#### T-023 — Widget home screen + Quick Tile (M4.3)
- **Branch**: `feat/t-023-widget-tile`
- **Dep**: T-009
- **Cover**: FR-07; DBD §7.
- **Perubahan**: widget 4×1 (`home_widget`): pengeluaran hari ini + tombol "+" → QuickCashSheet; Quick Tile Kotlin `TileService` → Activity transparan berisi sheet; kontrak MethodChannel BSD §3 (`openQuickCashActivity`, event `open_quick_cash`).
- **Eksklusi**: angka widget tidak real-time (diperbarui saat app/tile dipakai — batasan DBD §7, dicatat di layar Tentang bila perlu).
- **Kriteria sukses**: instrumented test channel; **verifikasi manual**: widget & tile membuka sheet, input tersimpan (checklist §7).
- **Ukuran**: M.

#### T-024 — Empty/loading/error states + aksesibilitas (M4.4)
- **Branch**: `feat/t-024-states-a11y`
- **Dep**: T-008, T-019, T-020, T-021, T-022
- **Cover**: NFR-05; DBD §8, §9; AFD §8.
- **Perubahan**: seluruh state kosong/loading/error per DBD §8; aksesibilitas: kontras ≥ 4.5:1, tanda `+`/`−` nominal, target ≥ 48dp, `semanticLabel`, font scale 1.3×.
- **Eksklusi**: tanpa fitur baru.
- **Kriteria sukses**: widget test state kosong; audit manual DBD §9 di checklist §7.
- **Ukuran**: M.

### M5 — Kalibrasi Real-World + Stabilisasi

#### T-025 — **MANUAL**: pemakaian nyata harian + catat kegagalan (M5.1)
- **Milik**: pengguna. Berkelanjutan 2–4 minggu.
- **Dep**: T-016
- **Cover**: metrik PRD §8.
- **Instruksi**: pakai app untuk keuangan nyata; bandingkan mingguan dengan mutasi Bale by BTN & GoPay; catat semua parse gagal/bolong lewat Log Parser (jangan hapus entri gagal sebelum dicatat).
- **Kriteria sukses**: catatan kegagalan tersedia untuk T-026; jumlah duplikat lolos per minggu tercatat (target 0).
- **Ukuran**: S (kalender).

#### T-026 — Kalibrasi pattern dari kasus nyata (M5.2)
- **Branch**: `feat/t-026-kalibrasi`
- **Dep**: T-025
- **Cover**: FR-02, FR-10; R-01.
- **Perubahan**: perbaiki/tambah rule untuk tiap kasus gagal dari T-025; **tambahkan fixture baru sebelum pattern diperbaiki** (regresi, IPD §3 poin 3); tipe tanpa sampel tetap "belum didukung".
- **Eksklusi**: tanpa pattern rekaan.
- **Kriteria sukses**: fixture baru hijau; rasio parse sukses naik terhadap baseline T-025.
- **Ukuran**: S.

#### T-027 — Ukur metrik PRD §8 (M5.3)
- **Branch**: `feat/t-027-metrik`
- **Dep**: T-025
- **Cover**: PRD §8.
- **Perubahan**: hitung rasio parse sukses dari `parser_logs` (`parsed` vs `failed`) per periode; ringkasan metrik (banding mutasi manual, waktu input tunai, duplikat) ditabulasikan ke laporan/lampiran docs.
- **Eksklusi**: tanpa dashboard metrik in-app (bukan FR).
- **Kriteria sukses**: tabel metrik ada, dengan nilai vs target ≥ 90%; sumber angka bisa ditelusuri ke DB.
- **Ukuran**: S.

#### T-028 — Perbaikan UX kecil + matikan logging rilis (M5.4)
- **Branch**: `feat/t-028-polish-rilis`
- **Dep**: T-026
- **Cover**: NFR-05; TRD §6.
- **Perubahan**: perbaikan kecil UX hasil pemakaian (dari catatan T-025, satu PR, scope dibatasi); pastikan tidak ada logging konten transaksi ke Logcat di build rilis.
- **Eksklusi**: tanpa fitur fase 2 (budget, backup, dark mode, dst.).
- **Kriteria sukses**: `flutter build apk --release` tidak mem-log konten transaksi (audit kode + smoke); CI hijau; MVP dinyatakan selesai bila metrik T-027 ≥ 90%.
- **Ukuran**: S.

---

## 6. Keputusan Terbuka → Spike (wajib berbatas waktu)

| Keputusan | Spike | Batas | Output |
|-----------|-------|-------|--------|
| drift vs Isar (A-04) | T-002 | 1 hari | Keputusan tercatat §8; dipakai T-006+ |
| Riverpod vs Provider (A-04) | T-003 | 1 hari | Keputusan tercatat §8; dipakai T-008+ |
| plugin listener vs bridge Kotlin custom | T-004 | 1 hari | Keputusan tercatat §8; dipakai T-011+ |

Tidak ada keputusan diam-diam: jika spike melebihi batas waktu, ambil pilihan yang lebih mudah dan dokumentasikan risikonya (prinsip IPD M0.3).

## 7. Checklist Verifikasi Perangkat Fisik (manual, device pengguna)

### 7.1 — T-016 (listener & baterai)
- [ ] Reboot HP → tanpa membuka app, kirim transaksi uji (Bale by BTN) → transaksi tercatat otomatis.
- [ ] Sama untuk GoPay.
- [ ] Battery optimization aktif (default OEM) → listener tetap hidup ≥ 24 jam pemakaian normal.
- [ ] Notification access dicabut saat app jalan → banner merah muncul di Dashboard/Pengaturan.
- [ ] Notifikasi app lain (bukan Bale/GoPay) → diabaikan total, tidak masuk ParserLog.
- [ ] Notifikasi ganda/tertunda → hanya satu transaksi tersimpan (dedup).

### 7.2 — T-009 / T-018 / T-020 / T-023 (interaksi)
- [ ] Input tunai via FAB < 5 detik (dihitung manual).
- [ ] Dari notifikasi interaktif: koreksi kategori ≤ 2 tap.
- [ ] Ubah rule regex di Uji Rule Parser → transaksi berikutnya pakai rule baru, tanpa build ulang.
- [ ] Widget home screen membuka QuickCashSheet; input tersimpan.
- [ ] Quick Tile membuka sheet; input tersimpan.
- [ ] Aksesibilitas: font scale 1.3× → semua layar utama tidak rusak.

## 8. Keputusan Spike (diisi saat eksekusi)

| ID | Keputusan | Alasan | Tanggal |
|----|-----------|--------|---------|
| T-002 (DB) | **drift 2.35.x** | Isar tidak bisa hidup berdampingan dengan toolchain drift (konflik analyzer/build, rilis resmi mati); drift terbukti end-to-end (3 test hijau). Lengkap: `spikes/db_drift/RESULT.md` | 2026-10-30 |
| T-003 (State) | **Riverpod** | FutureProvider/when tanpa boilerplate async; unit test state tanpa widget tree (terbukti spike); arah StreamProvider cocok feed reaktif M2. Lengkap: `spikes/state/RESULT.md` | 2026-10-30 |
| T-004 (Listener) | **Bridge Kotlin custom** (fallback: plugin) | Filter packageName di Kotlin sebelum bangunkan Dart isolate (kunci NFR-03 baterai); menyatukan listener + 4 MethodChannel + TileService dalam 1 native bridge (~60 baris); 0 third-party dep. Lengkap: `spikes/listener/RESULT.md` | 2026-10-30 |

---

## 9. Catatan Eksplisit

- **Tidak ada pattern/format notifikasi yang dikarang di dokumen ini.** Referensi hanya OQ-01/OQ-02; pattern awal dibuat di T-012 dari sampel aktual T-010.
- Tipe transaksi tanpa sampel diperlakukan "belum didukung", bukan ditebak (mitigasi risiko IPD §5).
- Estimasi ukuran S/M berbasis pengalaman umum Flutter (repo belum ada kode) — dikoreksi saat eksekusi bila meleset.
- Scope MVP = FR-01..FR-12 saja. Fase 2 (PRD §7) tidak masuk tugas mana pun.
- Flutter SDK sudah terpasang di mesin lokal (konfirmasi user, 2026-10-29): T-001 bisa menjalankan `flutter create` lokal dan smoke `flutter analyze`/`test` sebelum push, selain CI GitHub Actions.

---

## 10. Task Penyelarasan UI ke Mockup Option A (T-029 s.d. T-034)

> Sumber acuan visual: `docs/mockups/option-a/index.html` (mockup terpilih, Clean Card Modern) + screenshot aplikasi asli di `docs/realTest/`.
> Batasan keras: **hanya lapisan UI**. Tidak boleh mengubah parser, dedup, kategorisasi, skema DB, atau kontrak Kotlin↔Flutter. Kebutuhan data baru yang tidak tersedia → dicatat di backlog, bukan dikerjakan diam-diam.
> Keputusan pengguna (2026-10-31): ikon transaksi tetap panah ↑/↓ (bukan emoji mockup); kartu Arus Kas mengikuti mockup (hero amount + 2 nilai bawah) dengan label "Arus Kas"; cakupan 6 task.
> Font: mockup memakai font sistem (`-apple-system`/`Segoe UI`/`Roboto`) — **tidak ada font web yang perlu dibundel**, sehingga batasan tanpa unduhan runtime (NFR-01) tetap terpenuhi.

#### T-029 — Tema terpusat + token desain (M6.1)
- **Branch**: `feat/t-029-ui-theme`
- **Dep**: T-028
- **Cover**: `docs/04-DBD.md` §3, §4; mockup option-a token CSS.
- **Perubahan**: satu file `lib/ui/app_theme.dart` berisi token warna (bg `#F4F6F9`, surface `#FFFFFF`, surface-subtle `#F8FAFC`, fg `#0F172A`, muted `#64748B`, border `#E2E8F0`, accent `#2563EB`, income `#16A34A`, expense `#DC2626`, warn `#D97706` + warna badge sumber + chip mode), skala tipografi (screen title 18/700, sub-judul 13/700, body 13/600, caption 10–11/600, hero nominal 26/800), radius (8/16/24), spacing, dan `ThemeData` Material 3 yang memakai token tersebut (seed color `teal` diganti `accent`).
- **Eksklusi**: tanpa perubahan layout layar; tanpa data dummy; tanpa aset/font baru.
- **Kriteria sukses**: widget test memeriksa `Theme.of(context).colorScheme.primary` = `#2563EB` dan token warna tersedia sebagai konstanta; `flutter analyze` bersih; tidak ada literal warna hex baru di luar file token (diversi disetujui).
- **Ukuran**: S.

#### T-030 — Dashboard sesuai mockup (M6.2)
- **Branch**: `feat/t-030-ui-dashboard`
- **Dep**: T-029
- **Cover**: FR-08; DBD §5, §6; mockup dashboard.
- **Perubahan**: judul layar "Ringkasan Uangku" + greeting "Halo, {nama}" di header; badge "OFFLINE 100%" di kanan header; segmented periode **dipisah dari** kartu Arus Kas (menjadi baris penuh di atas kartu, bukan menimpa); kartu Arus Kas dengan hero amount pengeluaran + baris bawah "Pemasukan" dan "Net Arus Kas"; section feed dibungkus kartu putih dengan judul "Transaksi Terbaru" + tautan "Lihat Semua"; baris transaksi memakai `tx-item` (border bawah `#F1F5F9`, min-height 52, avatar 40px) + label kategori di kanan bawah nominal; FAB biru accent 56px radius 28 (bukan teal Material).
- **Eksklusi**: tanpa perubahan data/aggregasi (agregasi net sudah tersedia di `CashFlow`); tanpa widget chart baru (donut dipertahankan, hanya ukurannya diseragamkan ke 84px + % pada legend); greeting "Halo, {nama}" memakai nama placeholder "Bima" (tidak ada sumber nama pengguna di DB → backlog).
- **Kriteria sukses**: widget test memeriksa urutan elemen (status banner → segmented → kartu Arus Kas → chart → kartu feed), hero amount tampil, dan "Lihat Semua" ada; test lama tetap hijau.
- **Ukuran**: M.

#### T-031 — Transaksi (feed) sesuai mockup (M6.3)
- **Branch**: `feat/t-031-ui-feed`
- **Dep**: T-029, T-030
- **Cover**: FR-09; DBD §6; mockup feed.
- **Perubahan**: judul "Riwayat Transaksi"; baris filter chip direstyle (tinggi 36px, pill, memuat badge sumber di dalam chip: `BTN` / `GoPay` / `Tunai` + "Semua" dengan centang); grouping tanggal — transaksi dikelompokkan per tanggal dengan header "Hari Ini · 30 Okt 2026" / "Kemarin" / tanggal lain, tiap kelompok dibungkus kartu putih; baris transaksi memakai komponen `tx-item` yang sama dengan Dashboard (avatar 40px, border bawah, label kategori di kanan).
- **Eksklusi**: tanpa mengubah query feed atau filter di memori (backlog T-022 tetap); tanpa pagination.
- **Kriteria sukses**: widget test memeriksa header tanggal muncul, filter chip memuat badge sumber, dan baris transaksi menampilkan kategori.
- **Ukuran**: M.

#### T-032 — Pengaturan sesuai mockup (M6.4)
- **Branch**: `feat/t-032-ui-settings`
- **Dep**: T-029
- **Cover**: FR-01 (status listener); DBD §6; mockup Pengaturan.
- **Perubahan**: card "Status listener hardware" (radius 16, border `#E2E8F0`, shadow tipis, tanpa divider di antara item) berisi baris Notification Access & Whitelist Baterai dengan trailing badge pill ("AKTIF" hijau / "CEK SETELAN" amber); menu "Log Parser & Uji Rule" dipindah ke dalam card menu yang sama; blok privasi jadi card terpusat dengan ikon kunci + judul "100% Offline & Privat" + penjelasan; label app "Uangku" (bukan "uangku").
- **Eksklusi**: tanpa menambah menu Pengaturan baru; tanpa mengubah alur onboarding.
- **Kriteria sukses**: widget test memeriksa badge status, keberadaan menu Log Parser, dan blok privasi.
- **Ukuran**: S.

#### T-033 — QuickCashSheet sesuai mockup (M6.5)
- **Branch**: `feat/t-033-ui-quicksheet`
- **Dep**: T-029
- **Cover**: FR-07; NFR-05; DBD §5; mockup sheet.
- **Perubahan**: toggle Keluar/Masuk memakai segmented accent (biru, selected putih); **urutan dibalik** — chip kategori lebih dulu, keypad setelahnya (sesuai mockup); keypad tombol 48dp dengan bg `#F8FAFC`, border `#E2E8F0`, radius 12, angka `#0F172A` (bukan teal); chip kategori jadi pill radius 24, selected = biru filled + teks putih; tombol simpan biru accent radius 14 dengan label "Simpan Transaksi (Tunai)" / "Simpan Transaksi (Masuk)" sesuai tipe; display nominal memakai tabular figures.
- **Eksklusi**: tanpa mengubah logika simpan (`_save`), sumber `CASH`, atau validasi tombol.
- **Kriteria sukses**: widget test memeriksa urutan chip sebelum keypad, tombol simpan berlabel sesuai tipe, dan nominal tampil tabular.
- **Ukuran**: M.

#### T-034 — Detail/Koreksi + Log Parser sesuai mockup (M6.6)
- **Branch**: `feat/t-034-ui-detail-logparser`
- **Dep**: T-029, T-030
- **Cover**: FR-06, FR-10; DBD §6; mockup detail & log parser.
- **Perubahan**: layar Detail/Koreksi — app bar dengan "← Batal" & "Hapus", ringkasan sumber dana + waktu, input nominal 18px bold tabular, label form 12/600 muted, chip kategori pill, tombol "Simpan Perubahan" biru accent; Log Parser — stat card Parsed/Failed/Ignored (hijau/merah/abu), panel editor regex dengan hasil live, daftar log dengan badge status pill.
- **Eksklusi**: **tanpa panel "Teks notifikasi asli"** di Detail/Koreksi — data raw text ada di `parser_logs` tetapi belum ada relasi transaksi↔log (butuh kolom `rule_id`/FK baru = perubahan skema, di luar scope UI) → dicatat di backlog.
- **Kriteria sukses**: widget test memeriksa stat card log, badge status, dan label tombol Detail.
- **Ukuran**: M.
