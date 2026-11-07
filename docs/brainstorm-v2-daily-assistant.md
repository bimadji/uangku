# Brainstorm v2 — Uangku: dari Pencatat Keuangan menjadi Asisten Harian

> Hasil sesi brainstorm 2026-11-07 (dipandu pertanyaan per giliran, keputusan disepakati bersama pengguna).
> Sumber konteks: `docs/01-PRD.md` … `docs/07-EXECUTION-PLAN.md`, `docs/BACKLOG-FUTURE.md`, `docs/BUG-LOG.md`, `brainstorm-finance-app.md`, dan kondisi kode saat ini.
> Dokumen ini HANYA hasil brainstorm — tidak mengubah PRD/TRD/AFD/DBD/BSD/IPD/plan. Pembaruan dokumen tersebut dicatat di §7 dan dikerjakan nanti bila ide ini dilanjutkan.

## 1. Ringkasan Visi & Tujuan Versi Berikutnya

Uangku tumbuh dari pencatat keuangan otomatis menjadi **asisten harian mahasiswa**. Inti perubahannya: satu layar **"Hari Ini"** yang menjawab pertanyaan "hari ini ada apa aja?" — kelas hari ini, deadline tugas, tagihan dekat, dan angka uang (sisa budget harian) dalam satu pandangan, didukung notifikasi lokal di waktu yang tepat dan widget homescreen yang menampilkan versi ringkasnya.

**Prinsip yang dipegang:**

1. **Keuangan tetap inti dan tidak terganggu.** Semua fitur MVP (input tunai, listener Bale/GoPay, parser, dedup, dashboard, chart, widget, tile) tetap berjalan; CI tetap pengawal.
2. **Non-uang dibatasi "item ringan"** (judul + tanggal/jam + pengulangan). Tanpa proyek, tanpa subtask, tanpa kalender penuh — pagar keras agar tidak menjadi aplikasi to-do kedua.
3. **Tanpa izin INTERNET, tanpa akun, local-first** — tidak berubah di v2.
4. **Tidak ada AI/LLM.** Semua fitur yang dipilih cukup dengan logika deterministik lokal (aturan + agregasi); prasyarat "buktikan deterministik tidak cukup dulu" otomatis terpenuhi karena tidak ada kandidat yang membutuhkan AI.
5. **Setiap fase selesai = bisa dipakai sendiri dan bisa diverifikasi.** Desain fase 1 harus tuntas walau kapasitas turun.

## 2. Hasil Penggalian Kebutuhan

### 2.1 Yang disampaikan pengguna (fakta sesi, bukan asumsi)

| Topik | Fakta |
|---|---|
| Kapasitas membangun | > 12 jam/minggu (hampir tiap hari), TAPI tidak stabil sepanjang semester (UAS, deadline organisasi) → desain fase 1 harus tahan kapasitas turun ke 3–6 jam/minggu. ±25% waktu terpakai pemeliharaan berjalan (watchdog BUG-021, kalibrasi parser M5). |
| Peran utama v2 | Bukan lagi murni keuangan: hibrida terkontrol — "Hari Ini" menggabungkan uang + item non-uang ringan. (Keputusan C, Q2.) |
| Rutinitas non-uang nyata | Hanya **jadwal kuliah tetap** dan **deadline tugas**. Tidak ada rapat organisasi terjadwal, tidak ada hal pribadi mudah lupa yang spesifik. |
| Cara mengingat sekarang | Kepala sendiri. Tidak ada Google Calendar/catatan/kertas. **Baseline nol** — strukturisasi sekecil apa pun sudah mengalahkan keadaan sekarang. |
| Tagihan berulang | Satu-satunya: **kuota, siklus 2-mingguan** (bukan bulanan!). Konsekuensi: fitur tagihan wajib mendukung siklus fleksibel (7/14/30 hari), bukan cuma "tanggal tiap bulan". |
| Patungan | Tidak ada. → fitur patungan ditolak. |
| Tabungan | Menabung ada, tapi tanpa tujuan ("sekadar menabung"). → fitur target/envelope tabungan ditolak; paling jauh kotak tabungan sederhana (A3). |
| Deadline tugas | Datang lewat grup WhatsApp/LMS → **tidak bisa diotomasi** (tanpa INTERNET; listener hanya Bale/GoPay) → input manual, fokus ke penangkapan secepat mungkin. |

### 2.2 Keputusan yang disepakati (Q1–Q9)

| # | Keputusan | Hasil |
|---|---|---|
| Q1 | Kapasitas | > 12 jam/minggu, dengan peringatan desain-fase-1-tahan-turun (lihat 2.1). |
| Q2 | Peran utama v2 | Hibrida terkontrol: layar "Hari Ini" (uang + non-uang ringan). |
| Q3–Q4 | Penggalian fakta | Lihat 2.1. |
| Q5 | Pemilihan fitur | A1, A2, A3, B1, B2, E1 dipilih; C1 ditanyakan ulang lalu disepakati bentuknya. |
| Q6 | C1 & penempatan | "Hari Ini" = satu layar "hari ini ada apa aja"; **tab pertama baru** (Opsi A), Dashboard uang tetap ada di belakangnya; fondasi = **3 tabel per jenis + lapisan bersama** (bukan satu tabel raksasa). |
| Q7 | Internet & backup | Tetap **tanpa INTERNET**; backup = **ekspor/impor file lokal manual** (pengguna memindahkan filenya sendiri ke Drive/laptop via aplikasi lain). |
| Q8 | Peta jalan | Fase 0 (stabilisasi, paralel) → Fase 1 "Hari Ini" → Fase 2 keputusan uang + widget + backup → Fase 3 poles. Absensi ditunda. |
| Q9 | Konfirmasi | Ringkasan disetujui, ditulis ke dokumen ini. |

## 3. Kandidat Fitur per Area — Penilaian & Status

Kriteria penilaian (dari aturan brainstorm): nilai nyata bagi pengguna; usaha untuk developer solo Flutter (S/M/L); pemakaian-ulang infrastruktur yang ada (listener notifikasi, DB drift, widget/tile, LocalNotifService); dampak privasi & baterai; risiko.

### 3.1 Masuk v2 (disepakati)

| ID | Fitur | Area | Nilai | Usaha | Reuse infra | Privasi/baterai | Risiko | Catatan |
|---|---|---|---|---|---|---|---|---|
| C1 | Fondasi "Hari Ini": 3 tabel (`bills`, `class_schedule`, `todos`) + kueri gabungan "Hari Ini" + **satu scheduler notifikasi lokal bersama** + layar/tab | Inti | Tinggi (alasan utama buka app) | M | DB, LocalNotifService, widget | Netral; notifikasi terjadwal hemat | Sedang: desain tabel/recurrence salah = pengerjaan ulang; migrasi drift baru | Tulang punggung; dibangun pertama, sebelum fitur per jenis diisi penuh. Item ad-hoc ("ambil paket") tinggal di `todos`. |
| A1 | Tagihan berulang siklus fleksibel (7/14/30 hari; jangkar tanggal) | Uang | Tinggi (kasus nyata: kuota 2-mingguan) | S | C1 + transaksi ("tandai dibayar" sekalian mencatat transaksi) | Netral | Rendah | Muncul di Hari Ini; notifikasi H-1 & hari-H. |
| A2 | Budget harian + cek sebelum beli ("sisa jajan hari ini"; tampil di atas keypad QuickCashSheet) | Uang | Tinggi (membantu memutuskan di momen bayar) | S–M | Agregasi repository yang sudah ada + QuickCashSheet + widget | Netral | Rendah; jaga agar tidak "menyebel" — desain diam, warna halus | Nilai budget di-set di setelan (default disepakati saat implementasi). |
| A3 | Kotak tabungan sederhana (masuk/keluar, total; tanpa target) | Uang | Kecil–menengah | S | DB + repository | Netral | Rendah | Dipilih pengguna; ditaruh Fase 3 (nilai paling kecil dari yang dipilih). |
| B1 | Jadwal kuliah mingguan (hari, jam mulai–selesai, matkul, ruang) | Kuliah | Tinggi (baseline kepala sendiri) | S | C1 + widget | Netral | Rendah | Input sekali per semester. |
| B2 | Deadline tugas (judul, matkul opsional, tanggal) | Kuliah | Tinggi | S | C1 + FAB penangkapan cepat | Netral | Rendah teknis; **risiko adopsi: disiplin input** (mitigasi: tangkap < 5 detik via FAB/tile; baseline nol jadi tidak ada yang hilang) | Input manual (tidak bisa otomasi — lihat 2.1). |
| E1 | Insight mingguan deterministik ("jajan naik 20% vs minggu lalu", "tagihan kuota 3 hari lagi") | Uang | Menengah | S (setelah A1+A2) | Agregasi + notifikasi | Netral | Rendah; jangan dikerjakan sebelum A1/A2 ada | Murni aturan, tanpa AI. |
| — | Ekspor/impor backup file (JSON via file picker; pemulihan utuh) | Keselamatan | Tinggi (R-05 PRD masih terbuka; jadwal & tagihan lebih sulit dibuat ulang daripada transaksi) | S | Repository + file picker | Data tetap lokal, pengguna yang memindahkan | Rendah | Masuk Fase 2. |
| — | Widget homescreen diperbarui menjadi ringkasan "Hari Ini" | Permukaan | Menengah | M | Infra widget Kotlin yang sudah ada | Netral | Rendah | Permukaan, bukan fitur baru; masuk Fase 2 (Fase 1 sengaja tetap widget lama agar fase kecil). |

### 3.2 Opsional (tidak dipilih, tidak ditolak — bisa dibuka lagi)

| ID | Fitur | Alasan tidak masuk v2 |
|---|---|---|
| C2 | Quick tile "tangkap deadline" | Menurunkan gesekan input B2, tapi tile kedua menambah keputusan UI; ikut saja kalau B2 terbukti kurang praktis lewat FAB. |
| B3 | Absensi/kehadiran per matkul ("sisa kuota bolos") | Nilai nyata untuk mahasiswa, menunggangi `class_schedule` (murah kalau nanti diminta), tapi sengaja ditunda supaya Fase 1 kecil. **Ditunda tanpa tanggal.** |

### 3.3 Ditolak (tidak akan dikerjakan, dengan alasan)

| ID | Fitur | Alasan penolakan |
|---|---|---|
| C3 | Baca notifikasi WhatsApp untuk deteksi deadline otomatis | Teknis memungkinkan (listener sama, regex lokal, tanpa INTERNET) TAPI: teks WhatsApp tak terstruktur — parser notifikasi uang saja targetnya ≥90% dengan format semi-standar, teks manusia akan jauh di bawah itu; **salah deteksi deadline lebih berbahaya daripada bolong**; permukaan privasi jauh lebih sensitif (membaca semua notifikasi WA); usaha L untuk nilai yang tidak terjamin. Kalau suatu hari benar-benar dipingin: spike terpisah, bukan v2. |
| D1/D2 | Habit tracker, air/tidur/olahraga | Tidak pernah disebut sebagai sakit kepala nyata; pasar sudah banjir aplikasi habit yang lebih bagus; scope creep klasik. Boleh dibuka lagi di v2.x kalau kebutuhan nyata muncul. |
| B4 | Kalender UTS/UAS + mode ujian | Musiman (2× per semester) → nilai per waktu rendah, usaha M. |
| — | Patungan | Tidak ada kebutuhan nyata (Q4). |
| — | Target tabungan berbasis tujuan | Menabung tanpa tujuan (Q4); konsep baru di skema uang tanpa nilai. |
| — | Sinkronisasi cloud / akun | Bertentangan dengan tanpa-INTERNET & tanpa-akun; backup file manual sudah menutup risiko kehilangan data. |
| — | AI/LLM apa pun (remote atau lokal) | Tidak ada kandidat fitur yang terbukti butuh AI; semua tercapai deterministik. Prasyarat "buktikan dulu deterministik tidak cukup" belum pernah terlampaui. |

## 4. Keputusan Arsitektur & Dampak pada Aplikasi yang Ada

| Keputusan | Isi | Dampak pada yang sudah ada |
|---|---|---|
| **INTERNET tetap tidak diminta** | Tidak ada sinkronisasi cloud, tidak ada AI remote, tidak ada update rule otomatis. Konsekuensi yang diterima: deadline tugas tidak bisa diotomasi; parser hanya berkembang via in-app editor/PR. | Tidak ada perubahan AndroidManifest. |
| **Backup = file lokal manual** | Tombol "Ekspor data" → JSON ke folder pilihan (file picker); "Impor" membaca file yang sama; pengguna yang menyalin filenya ke Drive/laptop lewat aplikasi lain. | Repository baru baca/tulis JSON; tidak menyentuh skema transaksi. |
| **Navigasi: tab baru di depan** | Tab pertama = "Hari Ini" (Opsi A); Dashboard uang tetap utuh, bergeser ke belakang; Feed tetap. | `dashboard_screen.dart` & navigasi AFD §1 ditambah; tidak ada fitur uang yang diubah perilakunya. |
| **Skema: 3 tabel per jenis + lapisan bersama** (bukan 1 tabel raksasa) | `bills` (nominal, siklus_hari, tanggal_jangkar, kategori), `class_schedule` (hari-dalam-minggu, jam mulai/selesai, matkul, ruang), `todos` (judul, jenis tugas/pengingat, matkul opsional, tanggal). Lapisan bersama = kueri "Hari Ini" (gabung 3 sumber) + **satu scheduler notifikasi lokal bersama** untuk semua jenis. | Migrasi drift tambah tabel baru; tabel transaksi/kategori/parser **tidak disentuh**; seed & test lama tetap hijau. |
| **Izin Android: tidak ada yang baru** | Notifikasi lokal, listener, widget, tile sudah terpakai. Scheduler notifikasi pakai mekanisme yang sudah ada (WorkManager sudah ada via watchdog T-037c). | AndroidManifest tidak berubah. |
| **Tanpa AI/LLM** | Semua logika baru = aturan + agregasi deterministik. | Tidak ada dependensi baru berat. |

**Spike yang perlu dicek sebelum Fase 1 selesai** (jangan mengarang kemampuan yang belum terverifikasi): penjadwalan notifikasi lokal yang dapat diandalkan **lintas reboot dan hemat baterai di MIUI** — pola luka yang sama dengan BUG-021. Output spike: pola penjadwalan terpilih (mis. WorkManager periodic vs AlarmManager exact vs hybrid), tercatat di §8-execution-plan versi v2 nanti.

## 5. Peta Jalan Bertahap (v2 dan seterusnya)

**Fase 0 — Stabilisasi berjalan paralel (bukan fitur baru; sudah berjalan)**
- Watchdog BUG-021 (T-037c) → hasil lapangan ditunggu; kalibrasi parser M5 (T-025–T-027).
- Realistisnya memakan ±25% kapasitas. **Jika listener masih sering mati, Fase 1 menunggu** — fondasi "Hari Ini" tidak berguna di atas pencatatan yang bolong.
- Kriteria: BUG-021 terbukti pulih sendiri selama ≥ 2 minggu pemakaian nyata; rasio parse sukses ≥ 90% (PRD §8).

**Fase 1 — "Hari Ini" (inti v2, estimasi 3–4 minggu pada kapasitas penuh; tetap selesai walau kapasitas turun)**
1. Fondasi C1: migrasi 3 tabel + kueri gabungan + scheduler notifikasi bersama (+ spike scheduler MIUI).
2. B1 jadwal kuliah (input per semester).
3. B2 deadline tugas (manual; tangkap cepat lewat FAB).
4. A1 tagihan berulang siklus fleksibel ("tandai dibayar" mencatat transaksi).
- Kriteria selesai: tab "Hari Ini" menampilkan ketiga jenis item + notifikasi terjadwal terbukti jalan di device (lintas reboot); seluruh fitur uang lama tetap hijau (CI + smoke device); widget sengaja masih versi lama.

**Fase 2 — Keputusan uang + keselamatan data (estimasi 2–3 minggu)**
1. A2 budget harian (angka "sisa jajan hari ini" di Hari Ini + cek saat buka QuickCashSheet).
2. Widget homescreen diperbarui jadi ringkasan "Hari Ini".
3. Ekspor/impor backup file.
- Kriteria: angka budget terverifikasi terhadap data uji; file backup bisa diimpor balik utuh di device; widget menampilkan item "Hari Ini" tanpa memengaruhi fungsi lama.

**Fase 3 — Poles (estimasi 2 minggu; boleh terpotong kesibukan)**
1. E1 insight mingguan deterministik.
2. A3 kotak tabungan sederhana.
3. (Opsional) C2 quick tile "tangkap deadline" — bila FAB B2 terbukti kurang praktis.
- Kriteria per item masing-masing S; tiap item terverifikasi sendiri.

**Ditunda tanpa tanggal:** B3 absensi. **Tidak akan dikerjakan:** lihat §3.3.

## 6. Risiko, Asumsi, Pertanyaan Terbuka

### 6.1 Risiko

| ID | Risiko | Dampak | Mitigasi |
|---|---|---|---|
| RV2-01 | Listener tetap mati berkala (BUG-021) walau watchdog terpasang | Seluruh nilai v2 runtuh di atas pencatatan yang bolong | Fase 0 menunggu bukti lapangan ≥ 2 minggu sebelum Fase 1 mulai. |
| RV2-02 | Disiplin input deadline (B2) menurun → fitur mati pelan | B2 tidak memberi nilai | Penangkapan < 5 detik (FAB/tile); baseline nol jadi tidak ada yang hilang; evaluasi setelah 2–4 minggu pakai. |
| RV2-03 | Desain recurrence/scheduler salah → pengerjaan ulang C1 | Fase 1 molor | Spike scheduler MIUI + desain tabel direview sebelum migrasi; keputusan spike tercatat. |
| RV2-04 | Kapasitas turun (UAS/organisasi) | Fase molor | Tiap fase dirancang selesai pada kapasitas 3–6 jam/minggu; fase = unit selesai-sendiri. |
| RV2-05 | Notifikasi terjadwal memakan baterai / dibunuh OEM | Pengingat tidak muncul → kepercayaan hilang | Satu scheduler bersama (bukan per-fitur), hemat alarm; spike MIUI; terinspirasi pola watchdog yang sudah ada. |

### 6.2 Asumsi (belum terbukti; diverifikasi saat implementasi)

- Jam digest/notifikasi pagi bisa diatur pengguna (default ± 07:00) — diputuskan final saat implementasi Fase 1.
- Nilai budget harian di-set pengguna di setelan; default awal disepakati saat implementasi Fase 2.
- Siklus tagihan 7/14/30 hari cukup untuk kasus nyata (kuota 2-mingguan = 14).
- WorkManager (sudah dipakai watchdog T-037c) cukup untuk penjadwalan notifikasi harian — **belum terverifikasi untuk kasus jam spesifik lintas reboot; masuk spike**.

### 6.3 Pertanyaan terbuka

- Apakah watchdog BUG-021 benar-benar pulih di MIUI setelah ≥ 2 minggu? (Fase 0 menunggu jawaban ini.)
- Pola penjadwalan notifikasi apa yang paling andal di MIUI lintas reboot: WorkManager periodic, AlarmManager exact-and-allow-while-idle, atau hybrid? (Spike Fase 1.)
- Setelah Fase 1 terpakai beberapa minggu: apakah absensi (B3) diminta? Kalau ya, dia menunggangi `class_schedule` dan murah.
- Format ekspor: JSON penuh saja, atau perlu subset (mis. tanpa parser_logs)? (Diputuskan saat Fase 2, tidak memengaruhi desain.)

## 7. Dokumen yang Perlu Diperbarui Bila Ide Ini Dilanjutkan

**Tidak ada dokumen berikut yang diubah sekarang.** Daftar ini hanya peta kerja nanti:

| Dokumen | Bagian yang diperbarui |
|---|---|
| `docs/01-PRD.md` | FR baru (Hari Ini, tagihan, budget, jadwal, deadline, insight, backup); metrik §8 untuk fitur baru; asumsi & risiko v2. |
| `docs/02-TRD.md` | Arsitektur: tab "Hari Ini", scheduler notifikasi bersama, backup file; batasan teknis (spike MIUI). |
| `docs/03-AFD.md` | Alur baru: buka app → Hari Ini; tambah deadline via FAB; tandai dibayar tagihan; ekspor/impor. |
| `docs/04-DBD.md` | Desain tab "Hari Ini" (blok, empty state), input jadwal/deadline/tagihan, widget v2. |
| `docs/05-BSD.md` | Skema 3 tabel baru + relasi ke `transactions`/`categories`; kueri gabungan; strategi notifikasi. |
| `docs/06-IPD.md` | Detail implementasi fase, keputusan spike scheduler, migrasi drift. |
| `docs/07-EXECUTION-PLAN.md` | Milestone Fase 1–3 + tabel tugas baru (mengikuti format T-xxx yang ada). |
| `docs/BACKLOG-FUTURE.md` | Catat item §3.2/§3.3 yang sesuai (opsional & ditolak) sebagai backlog resmi. |

Urutan yang disarankan saat nanti dikerjakan: PRD+TRD dulu (satu PR docs), lalu BSD+DBD+AFD, lalu IPD+plan.
