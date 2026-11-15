# AI-Assisted Development & Vibe Coding

Folder ini berisi implementasi praktikum **AI-Assisted Development / Vibe Coding** (Minggu 9 / Folder Tugas `09-week-8-ai-assisted-development`). Proyek ini mengintegrasikan fitur pencarian catatan (*search notes*) beserta *empty state* pada aplikasi offline notes menggunakan bantuan AI coding assistant dengan penerapan siklus verifikasi ketat: **Prompt $\rightarrow$ Generate $\rightarrow$ Verify $\rightarrow$ Test $\rightarrow$ Refactor $\rightarrow$ Explain**.

---

## 1. Deskripsi Fitur Baru

- **Pencarian Catatan (*Search Query*):** Pengguna dapat mencari catatan berdasarkan judul maupun isi catatan secara *real-time*.
- **Toleran Huruf Besar/Kecil (*Case-Insensitive*):** Kata kunci `"belanja"` dapat menemukan catatan `"Belanja Mingguan"`.
- **Toleran Spasi Ekstra (*Trimmed Query*):** Input dengan spasi berlebih tetap diproses secara akurat.
- **Dua Kondisi Empty State:**
  1. *Empty Search State:* Menampilkan visual ikon pencarian tidak ditemukan (`search_off_rounded`) beserta teks penjelasan `"Tidak ada catatan yang cocok dengan \"<query>\""`.
  2. *Default Empty State:* Menampilkan pesan `"Belum ada catatan. Tambahkan satu."` saat database catatan memang kosong.
- **Pembersihan Cepat (*Clear Button*):** Tombol ikon silang (*clear*) otomatis muncul ketika terdapat input pencarian untuk mengembalikan tampilan ke daftar lengkap.

---

## 2. Tech Stack & Arsitektur

- **Framework:** Flutter (Dart SDK ^3.13.2)
- **State Management:** Flutter Riverpod (`flutter_riverpod: ^3.4.3`)
- **Penyimpanan Lokal:** SQLite (`sqflite: ^2.4.4+1`)
- **Arsitektur:** Clean Architecture dengan pemisahan layer:

```text
Presentation Layer (UI):
  └── lib/pages/notes_page.dart (_SearchBar, _EmptyView, _NoteTile)
            │  menyimak filteredNotesProvider & mengirim setQuery()
            ▼
Application / Notifier Layer:
  └── lib/data/providers.dart (searchQueryProvider, filteredNotesProvider)
            │  mengeksekusi logika use case murni
            ▼
Domain Layer:
  └── lib/domain/search_notes_use_case.dart (SearchNotesUseCase)
            ▲
            │  menyediakan data catatan lokal
Data / Infrastructure Layer:
  └── lib/data/repositories/note_repository.dart & lib/data/local/db.dart
```

---

## 3. Prompt Utama (Formula 5 Slot)

```text
Peran: Senior Flutter Developer
Konteks: Project Flutter offline notes dengan arsitektur feature-first/Clean Architecture, state management Flutter Riverpod, penyimpanan lokal SQLite (sqflite) + REST API (Dio). Model data: Note(id, title, body, updatedAt, dirty).
Tugas: Tambahkan fitur pencarian judul catatan (search query) lengkap dengan visual empty state jika hasil pencarian tidak ditemukan.
Batas: Jangan ubah arsitektur dasar, jangan panggil database langsung dari widget, buat logika filter murni di layer domain agar dapat diuji independen (unit test), fungsi maksimal 40 baris.
Output: Kode Dart untuk domain use case, Riverpod provider, widget UI notes page, 3 unit/widget test case, dan petunjuk pengujian.
```

---

## 4. Tabel Keputusan Review AI (Terima vs Tolak)

| No | Rekomendasi AI | Status | Alasan Teknis & Bukti |
|:---:|:---|:---:|:---|
| 1 | **Debounce Timer pada Input:** Gunakan `async debounce` untuk menunda pencarian saat user mengetik cepat. | **Ditolak** | Operasi pencarian `SearchNotesUseCase` berjalan secara *in-memory* pada data lokal yang sudah dimuat ke memori, bukan query I/O database atau pemanggilan jaringan kontinu. Menambahkan timer debounce justru menambah kompleksitas state yang tidak perlu dan berpotensi menyebabkan kebocoran memori. |
| 2 | **Isolasi Domain Use Case:** Pisahkan filter ke layer domain murni (`SearchNotesUseCase`) tanpa dependensi widget/Flutter. | **Diterima** | Sesuai kaidah *Clean Architecture*. Menjamin bahwa logika bisnis filter dapat diuji dengan *pure Dart unit tests* secara cepat tanpa perlu me-render widget tree. |
| 3 | **Pemisahan Kondisi Empty State:** Pisahkan pesan UI antara list catatan kosong dengan hasil pencarian tidak ditemukan. | **Diterima** | Memberikan kejelasan UX (*feedback*) yang akurat bagi pengguna saat query yang dimasukkan tidak memiliki hasil yang cocok. |

Detail lengkap prompt awal, temuan bug awal (*case-sensitivity* & spasi), serta refleksi dicatat di:
👉 **[docs/ai-log.md](docs/ai-log.md)**

---

## 5. Cara Menjalankan Aplikasi & Pengujian

### Menjalankan Aplikasi
```bash
flutter pub get
flutter run
```

### Menjalankan Analisis Statis
```bash
flutter analyze
```

### Menjalankan Pemeriksaan Format Kode
```bash
dart format --set-exit-if-changed .
```

### Menjalankan Seluruh Pengujian
```bash
flutter test
```

### Menjalankan Pengujian Spesifik Fitur Pencarian
```bash
flutter test test/search_filter_test.dart
```

---

## 6. Bukti Pengujian Mesin (Mesin Hijau)

### Output `flutter analyze`:
```text
Analyzing 09-week-8-ai-assisted-development...
No issues found! (ran in 2.8s)
```

### Output `dart format`:
```text
Formatted 17 files (0 changed) in 0.05 seconds.
Exit code: 0
```

### Output `flutter test` (15 dari 15 Test Lulus):
```text
00:00 +0: loading test/note_test.dart
00:00 +0: test/note_test.dart: fromMap handles missing and null fields safely
00:00 +1: test/note_test.dart: dirty flag survives serialization
00:00 +2: test/note_test.dart: notes provider succeeds with a fake repository
00:00 +3: test/note_test.dart: notes provider forwards repository errors
00:00 +4: test/offline_features_test.dart: Post parses JSONPlaceholder post fields
00:00 +5: test/offline_features_test.dart: syncNotes returns zero without waiting when there are no dirty notes
00:00 +6: test/offline_features_test.dart: syncNotes marks uploaded dirty notes as synced
00:00 +7: test/offline_features_test.dart: syncNotes rejects sync while forceOffline is enabled
00:00 +8: test/search_filter_test.dart: SearchNotesUseCase (Unit Tests) query kosong mengembalikan seluruh catatan tanpa filter
00:00 +9: test/search_filter_test.dart: SearchNotesUseCase (Unit Tests) query hanya spasi mengembalikan seluruh catatan (whitespace-safe)
00:00 +10: test/search_filter_test.dart: SearchNotesUseCase (Unit Tests) filter mengabaikan huruf besar/kecil (case-insensitive) pada judul
00:00 +11: test/search_filter_test.dart: SearchNotesUseCase (Unit Tests) query dengan leading/trailing spasi di-trim dengan benar
00:00 +12: test/search_filter_test.dart: SearchNotesUseCase (Unit Tests) query tidak cocok mengembalikan list kosong
00:00 +13: test/search_filter_test.dart: NotesPage Search & Empty State (Widget Tests) menampilkan empty state pencarian saat query tidak cocok
00:00 +14: test/search_filter_test.dart: NotesPage Search & Empty State (Widget Tests) menampilkan empty state default saat belum ada catatan sama sekali
00:01 +15: All tests passed!
```

---

## 7. Dokumentasi Hasil Uji Visual (Screenshots)

Berikut adalah tangkapan layar pengujian fitur pencarian dan *empty state* pada aplikasi:

| 1. Default Empty State | 2. Query Cocok (Filter) | 3. Query Tidak Cocok (Empty Search) |
|:---:|:---:|:---:|
| <img src="screenshots/Screenshot%202026-11-15%20143259.png" width="260" alt="Default Empty State" /> | <img src="screenshots/Screenshot%202026-11-15%20143424.png" width="260" alt="Query Cocok" /> | <img src="screenshots/Screenshot%202026-11-15%20143437.png" width="260" alt="Empty Search State" /> |
| *Kondisi awal belum ada catatan* | *Pencarian kata kunci `"belanja"`* | *Empty state kata kunci `"beli"`* |

---

## 8. Struktur Folder

```text
09-week-8-ai-assisted-development/
├── docs/
│   ├── ai-log.md                  # Log lengkap proses AI, prompt, temuan bug, & refleksi
│   └── ai-challenge-storage.md     # Dokumen perbandingan storage
├── lib/
│   ├── domain/
│   │   └── search_notes_use_case.dart # Pure domain logic untuk pencarian catatan
│   ├── data/
│   │   ├── local/                 # Database SQLite lokal & Model
│   │   ├── repositories/          # Implementasi Repository
│   │   ├── services/              # Layanan sinkronisasi
│   │   ├── prefs.dart             # SharedPreferences
│   │   └── providers.dart         # Riverpod providers (termasuk filter & search query)
│   ├── pages/
│   │   ├── home_page.dart         # Navigasi tab & scaffold utama
│   │   ├── notes_page.dart        # UI catatan dengan SearchBar & EmptyView
│   │   ├── posts_page.dart        # Cache-first Posts
│   │   └── settings_page.dart     # Pengaturan preferensi & mode offline
│   └── main.dart                  # Entry point aplikasi
├── screenshots/
│   ├── README.md                  # Panduan skenario uji visual
│   ├── Screenshot 2026-11-15 143259.png
│   ├── Screenshot 2026-11-15 143424.png
│   └── Screenshot 2026-11-15 143437.png
├── test/
│   ├── note_test.dart             # Unit test model & provider catatan
│   ├── offline_features_test.dart # Unit test sinkronisasi & cache offline
│   └── search_filter_test.dart    # Unit & Widget test fitur pencarian & empty state
├── analysis_options.yaml
├── pubspec.yaml
└── README.md
```
