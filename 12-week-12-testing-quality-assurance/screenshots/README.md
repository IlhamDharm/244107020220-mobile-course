# Dokumentasi Bukti Visual Pengujian (Week 12 Screenshots)

Folder ini berisi rekaman visual eksekusi pengujian otomatis, analisis statis, dan laporan cakupan kode (*code coverage*) untuk modul **#12 | Pengujian dan Jaminan Kualitas**.

---

## Daftar Tangkapan Layar & Bukti Eksekusi

| File Bukti | Deskripsi Pengujian | Status Mesin |
| :--- | :--- | :---: |
| [`01_unit_tests.png`](01_unit_tests.png) | Eksekusi Unit Test logika bisnis, validator judul form, kasus tepi spasi/null, serta Fake Repository async. | `12/12 PASS (100%)` |
| [`02_widget_tests.png`](02_widget_tests.png) | Eksekusi Widget Test interaksi UI `NotesPage`: dialog popup, input form `Key`, submit catatan, dan tombol batal. | `4/4 PASS (100%)` |
| [`03_all_tests_green.png`](03_all_tests_green.png) / [`test-results.png`](test-results.png) | Seluruh test suite (Unit, Widget, Riverpod, AI Service, Offline sync, Pagination, Model serialization). | `44/44 PASS (100%)` |
| [`04_coverage_report.png`](04_coverage_report.png) / [`coverage-report.png`](coverage-report.png) | Laporan metrik cakupan baris (*Line Coverage*) dari `coverage/lcov.info` (Domain 100%, NotesPage 91%). | `64.93% Overall` |
| [`05_static_analysis.png`](05_static_analysis.png) | Hasil verifikasi *Quality Gate* (`flutter analyze` 0 issues, `dart format` clean). | `0 Issues Found` |

---

## Penjelasan Detail Screenshot

### 1. Unit & Edge Case Tests (`01_unit_tests.png`)
Menampilkan hasil uji logika fungsi `isValidNoteTitle` dan `validateNoteTitle` menggunakan pola **Arrange-Act-Assert**:
- Validasi teks normal dan pemangkasan spasi (*trimming*).
- Kasus tepi string kosong (`""`) dan spasi bertingkat (`" \t \n "`).
- Nilai batas bawah (< 3 karakter) dan batas atas (> 100 karakter).
- Pengujian dependensi asinkron `TaskService` bersama `FakeTaskRepository` untuk skenario *Happy Path* dan *Error Path* (handling exception jaringan/database).

### 2. Widget Tests (`02_widget_tests.png`)
Menampilkan interaksi langsung pada widget pohon Flutter (`flutter_test`):
- Pengecekan keberadaan komponen awal (`Key('add-note-button')`, pencarian).
- Simulasi ketukan tombol tambah (`tester.tap`) dan verifikasi dialog popup terbuka.
- Simulasi pengisian form input judul dan isi catatan (`tester.enterText`).
- Verifikasi penyimpanan state dan dismissal dialog (`tester.pumpAndSettle`).
- Verifikasi tombol pembatalan menutup dialog tanpa menduplikasi data.

### 3. Seluruh Test Suite Hijau (`03_all_tests_green.png`)
Menampilkan terminal eksekusi `flutter test` yang mengeksekusi 44 test secara menyeluruh tanpa ada yang *flaky* atau gagal:
```text
00:03 +44: All tests passed!
```

### 4. Code Coverage Report (`04_coverage_report.png`)
Menampilkan ringkasan metrik dari `flutter test --coverage`:
- `lib/domain/note_validator.dart`: **100.0%** (6/6 lines)
- `lib/domain/task_contract.dart`: **100.0%** (8/8 lines)
- `lib/domain/search_notes_use_case.dart`: **100.0%** (9/9 lines)
- `lib/data/local/note.dart`: **100.0%** (15/15 lines)
- `lib/data/local/post.dart`: **100.0%** (12/12 lines)
- `lib/data/services/note_sync.dart`: **100.0%** (6/6 lines)
- `lib/pages/notes_page.dart`: **91.0%** (121/133 lines)
- **Total Project Line Coverage:** **64.93%** (448 dari 690 baris aktif ter-cover)

### 5. Static Analysis & Quality Gate (`05_static_analysis.png`)
Menampilkan bukti bahwa kode bebas dari *warning*, *lint errors*, dan penulisan format kode konsisten mengikuti standar Flutter/Dart.
