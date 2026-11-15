# Week 11 — Optimasi Performa Aplikasi Mobile

## Identitas Mahasiswa
- **Nama:** Ilham Dharma A
- **NIM:** 244107020220
- **Program Studi:** D4 Teknik Informatika
- **Mata Kuliah:** Pemrograman Mobile
- **Modul Praktikum:** `#11 | Optimasi Performa`

---

## 1. Deskripsi Proyek

Folder ini berisi implementasi praktikum **#11 | Optimasi Performa** pada mata kuliah Pemrograman Mobile. Proyek ini berfokus pada analisis *bottleneck*, perbaikan rendering pipeline, efisiensi alokasi memori, serta optimasi jaringan pada aplikasi *Campus Notes & AI Assistant* menggunakan **Flutter DevTools** dalam mode profil (`flutter run --profile`).

Tujuan utama optimasi adalah mencapai target rendering **60 FPS stabil (< 16.67 ms per frame)**, meminimalkan *frame drop (jank)*, mencegah kebocoran memori (*memory leak*), serta menghemat konsumsi bandwidth jaringan dan daya baterai perangkat mobile.

---

## 2. Teknik Optimasi yang Diterapkan

1. 🧱 **Ekstraksi Widget & Konstruktor `const`:**
   - Memecah widget besar (`NotesPage`, `PostsPage`, `ChatScreen`) menjadi komponen-komponen kecil (`_PostTile`, `_NoteTile`, `_SyncStatusBanner`, `_OfflineBanner`, `_PostsRefreshBanner`) dengan konstruktor `const`.
   - Menghindari pemanggilan `build()` ulang yang tidak perlu pada widget statis saat widget induk diperbarui.

2. 🎨 **Isolasi Render Layer dengan `RepaintBoundary`:**
   - Membungkus list tiles dan gelembung chat AI (`_ChatBubble`, `_PostTile`, `_NoteTile`) menggunakan `RepaintBoundary`.
   - Mengisolasi raster painting GPU sehingga perubahan pada satu elemen (seperti kursor berkedip atau indikator loading) tidak memicu *repainting* seluruh canvas list view.

3. 🎯 **Seleksi State Granular (`ref.watch(provider.select(...))`):**
   - Mengganti watcher berlevel tinggi dengan selektor spesifik pada sub-widget. Contohnya: `_SyncStatusBanner` hanya me-rebuild dirinya sendiri saat `dirtyCount` berubah, tanpa memicu rebuild pada `NotesPage`, kolom input, atau daftar catatan.

4. 📜 **Pagination & Lazy Loading (Infinite Scroll):**
   - Menambahkan metode `fetchPostsPaged({int page = 1, int limit = 10})` pada `PostRepository`.
   - Menerapkan `ScrollController` dengan ambang batas (*threshold*) 200px sebelum batas bawah list untuk memuat halaman berikutnya secara mulus tanpa membebani memori awal.

5. ⚡ **Strategi Caching Stale-While-Revalidate & Incremental SQLite:**
   - Menampilkan data lokal dari SQLite secara instan (< 16 ms) saat halaman dibuka, lalu mengambil data terbaru dari jaringan di latar belakang dan menyimpannya secara inkremental via `appendCachedPosts()`.

6. 🧹 **Pembersihan Sumber Daya & Memory Hygiene (`dispose`):**
   - Mencopot listener dan memanggil `dispose()` pada semua `ScrollController` dan `TextEditingController` untuk memastikan objek dilepaskan oleh Garbage Collector (GC) dan mencegah *memory leak*.

---

## 3. Diagram Pipeline Rendering & Titik Optimasi

```text
[UI Thread: Dart Code]
       │
       ├─► (1) Ekstraksi Widget `const` ──► Lewati build() jika input tidak berubah
       │
       ├─► (2) Riverpod `.select(...)`   ──► Isolasi rebuild hanya pada sub-widget yang relevan
       │
       └─► (3) Layout & Paint Dispatch
                 │
                 ▼
[Raster Thread: GPU]
       │
       ├─► (4) `RepaintBoundary`         ──► Cat hanya RenderLayer lokal, lewati canvas statis
       │
       └─► (5) Frame Selesai dalam < 16.67 ms (Target: 60 FPS Mulus)
```

---

## 4. Galeri Bukti Profiling Flutter DevTools & Pengujian Nyata

### A. Komparasi Profiling DevTools (Before vs After)

| Baseline (Sebelum Optimasi - Jank Detected) | Post-Optimization (Setelah Optimasi - 60 FPS) |
|:---:|:---:|
| <img src="screenshots/before-profile.png" width="460" alt="DevTools Performance Before" /> | <img src="screenshots/after-profile.png" width="460" alt="DevTools Performance After" /> |
| *Banyak frame merah/kuning melewati budget 16.6 ms (Avg: 22.4 ms)* | *Frame stabil hijau konsisten di bawah 16.6 ms (Avg: 9.2 ms)* |

### B. Pengujian Langsung Interaksi UI & Metrik DevTools (4 Tab)

| 1. Tab Catatan (Notes) | 2. Tab Posts (Pagination / Infinite Scroll) |
|:---:|:---:|
| <img src="screenshots/01_perf_catatan_tab.png" width="360" alt="Performance Catatan Tab" /> | <img src="screenshots/02_perf_posts_pagination.png" width="360" alt="Performance Posts Pagination" /> |
| *INP: 40 ms (Good) & CLS: 0.02 (Stabil)* | *Infinite scroll lazy loading (items 12-19) - INP: 64 ms (Good)* |

<br/>

| 3. Tab AI Chat (Campus Assistant) | 4. Tab Pengaturan (Settings) |
|:---:|:---:|
| <img src="screenshots/03_perf_ai_chat.png" width="360" alt="Performance AI Chat Tab" /> | <img src="screenshots/04_perf_pengaturan.png" width="360" alt="Performance Pengaturan Tab" /> |
| *Gelembung obrolan RepaintBoundary - INP: 96 ms (Good)* | *Toggle switch responsif tanpa frame drop - INP: 48 ms (Good)* |

---

## 5. Tabel Komparasi Metrik Kuantitatif (Before vs After)

| Parameter Pengujian | Baseline Sebelum Optimasi | Hasil Setelah Optimasi | Peningkatan Kuantitatif |
|:---|:---:|:---:|:---:|
| **Rata-rata Frame Time** | 22.4 ms | **9.2 ms** | **58.9% Lebih Cepat** ⚡ |
| **FPS Rata-rata** | ~44 FPS (terasa jank) | **59 - 60 FPS** | **Mencapai Standar 60 FPS** 🎯 |
| **Jumlah Jank Frames (Merah/Kuning)** | 18 frame / 100 frame | **2 frame / 100 frame** | **Penurunan Jank 88.8%** 📉 |
| **Waktu Build UI Thread** | 14.8 ms | **4.1 ms** | **72.3% Lebih Ringan** 🚀 |
| **Waktu Raster Thread GPU** | 9.6 ms | **3.8 ms** | **60.4% Lebih Efisien** 🎨 |
| **Alokasi Dart Heap** | 38.6 MB (GC sering aktif) | **24.2 MB** | **Hemat Memori 37.3%** 💾 |
| **Network Payload (Posts)** | 100 item (~27.5 KB) | 10 item per page (~2.8 KB) | **Hemat Bandwidth 89.8%** 🌐 |
| **Time to First Display (TTFD)** | 480 ms (menunggu network) | **< 16 ms** (Stale cache) | **Tampilan Visual Instan** ⚡ |

---

## 6. Cara Menjalankan Aplikasi & Profiling

### 1. Menjalankan Profiling Akurat (Mode Profile)
```bash
flutter run --profile
```
> **Penting:** Selalu gunakan mode `--profile` saat menguji performa, bukan `--debug` (memiliki overhead besar) atau `--release` (tidak menyediakan hook DevTools).

### 2. Membuka Flutter DevTools
Buka URL DevTools yang muncul di terminal (default: `http://127.0.0.1:9100`) lalu navigasikan ke:
- **Tab Performance:** Rekam interaksi fast scroll dan evaluasi Flame Chart.
- **Tab Memory:** Ambil *Heap Snapshot* sebelum dan sesudah navigasi bolak-balik untuk mendeteksi leak.

### 3. Menjalankan Analisis Statis Kode
```bash
flutter analyze
```

### 4. Menjalankan Pemeriksaan Format Dart
```bash
dart format --set-exit-if-changed .
```

### 5. Menjalankan Seluruh Pengujian Otomatis (28 Test)
```bash
flutter test
```

---

## 7. Bukti Verifikasi Mesin (Mesin Hijau)

### Output `flutter analyze`:
```text
Analyzing 11-week-11-performance-optimization...
No issues found! (ran in 2.3s)
```

### Output `dart format`:
```text
Formatted 22 files (0 changed) in 0.07 seconds.
Exit code: 0
```

### Output `flutter test` (28 dari 28 Test Lulus):
```text
00:00 +0: test/ai_service_test.dart: ask() melempar exception saat API key belum diatur
00:00 +1: test/ai_service_test.dart: saveApiKey() dan getApiKey() menyimpan dan mengambil key dengan benar
00:00 +2: test/ai_service_test.dart: ask() sukses mengurai respon JSON dari Gemini API
00:00 +3: test/ai_service_test.dart: ask() melempar exception saat server Gemini mengembalikan HTTP error
00:00 +4: test/ai_service_test.dart: ask() sukses mengurai respon dari 9Router (OpenAI-compatible format)
00:00 +5: test/chat_screen_test.dart: menampilkan pesan sambutan awal dari AI Assistant
00:00 +6: test/chat_screen_test.dart: mengirim pesan dan menampilkan respon AI
00:00 +7: test/chat_screen_test.dart: menampilkan dialog fallback saat layanan AI sibuk atau terjadi error
00:01 +24: test/search_filter_test.dart: search query & empty state tests lulus
00:01 +25: test/performance_optimization_test.dart: appendCachedPosts() menyimpan data incremental
00:01 +26: test/performance_optimization_test.dart: readCachedPosts() mendukung parameter pagination (limit & offset)
00:01 +27: test/performance_optimization_test.dart: PaginatedPostsState copyWith mempertahankan immutability
00:01 +28: test/performance_optimization_test.dart: PaginatedPostsNotifier mengelola transisi pagination dengan benar
00:01 +28: All tests passed!
```

---

## 8. Struktur Folder Proyek

```text
11-week-11-performance-optimization/
├── docs/
│   ├── performance-findings.md        # Dokumen identifikasi 5 bottleneck utama
│   ├── performance-report.md          # Laporan metrik komparasi & jawaban refleksi
│   ├── ai-log.md                      # Log perancangan AI & mitigasi privasi
│   └── ai-challenge-storage.md        # Dokumen analisis secure storage
├── lib/
│   ├── ai/
│   │   └── ai_service.dart            # Service komunikasi AI
│   ├── features/
│   │   └── chat_screen.dart           # UI Chat dengan RepaintBoundary pada _ChatBubble
│   ├── domain/
│   │   └── search_notes_use_case.dart # Use case pencarian catatan
│   ├── data/
│   │   ├── local/                     # Entitas SQLite lokal (Note, Post, DB)
│   │   ├── repositories/
│   │   │   ├── note_repository.dart   # Repository catatan
│   │   │   └── post_repository.dart   # Repository postingan dengan pagination & incremental cache
│   │   ├── services/
│   │   │   └── note_sync.dart         # Sinkronisasi catatan dirty
│   │   ├── prefs.dart                 # SharedPreferences
│   │   └── providers.dart             # Riverpod providers + PaginatedPostsNotifier
│   ├── pages/
│   │   ├── home_page.dart             # Navigasi tab utama
│   │   ├── notes_page.dart            # Notes UI dengan RepaintBoundary & .select dirty banner
│   │   ├── posts_page.dart            # Posts UI dengan Infinite Scroll Pagination & RepaintBoundary
│   │   └── settings_page.dart         # Halaman preferensi aplikasi
│   └── main.dart                      # Entry point aplikasi
├── screenshots/
│   ├── before-profile.png             # Screenshot DevTools Frame Chart sebelum optimasi
│   ├── after-profile.png              # Screenshot DevTools Frame Chart setelah optimasi
│   └── README.md                      # Galeri visual & rincian metrik
├── test/
│   ├── performance_optimization_test.dart # Test unit pagination, incremental cache, & state notifier
│   ├── ai_service_test.dart           # Test unit AI Service
│   ├── chat_screen_test.dart          # Widget test ChatScreen
│   ├── note_test.dart                 # Test unit catatan & provider
│   ├── offline_features_test.dart     # Test sinkronisasi offline
│   └── search_filter_test.dart        # Test pencarian catatan
├── analysis_options.yaml
├── pubspec.yaml
└── README.md
```
