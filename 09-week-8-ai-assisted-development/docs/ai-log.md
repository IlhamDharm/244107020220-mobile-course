# AI Development Log — AI-Assisted Development & Vibe Coding

Dokumen ini mencatat seluruh proses implementasi fitur pencarian catatan (*search notes*) menggunakan pendekatan **AI-Assisted Development** sesuai modul praktikum *#09 | AI-Assisted Development / Vibe Coding*.

---

## 1. Praktikum 1: Prompt dan Context Engineering

### Formula 5 Slot
Berikut adalah prompt terstruktur yang digunakan untuk menghasilkan fitur:

```text
Peran: Senior Flutter Developer
Konteks: Project Flutter offline notes dengan arsitektur feature-first/Clean Architecture, state management Flutter Riverpod, penyimpanan lokal SQLite (sqflite) + REST API (Dio). Model data: Note(id, title, body, updatedAt, dirty).
Tugas: Tambahkan fitur pencarian judul catatan (search query) lengkap dengan visual empty state jika hasil pencarian tidak ditemukan.
Batas: Jangan ubah arsitektur dasar, jangan panggil database langsung dari widget, buat logika filter murni di layer domain agar dapat diuji independen (unit test), fungsi maksimal 40 baris.
Output: Kode Dart untuk domain use case, Riverpod provider, widget UI notes page, 3 unit/widget test case, dan petunjuk pengujian.
```

### Konteks Proyek yang Diberikan (Tanpa Secret)
- **Model:** `Note(id, title, body, updatedAt, dirty)`
- **State Management:** `flutter_riverpod: ^3.4.3`
- **Penyimpanan:** `sqflite: ^2.4.4+1`
- **Aturan Keamanan:** Tidak ada token, API key, atau kredensial rahasia yang ditempelkan ke dalam prompt.

---

## 2. Praktikum 2: Generate & Verifikasi Awal

### Output Awal AI (Sebelum Verifikasi & Refactor)
Pada iterasi awal (generasi mentah), AI mengusulkan kode filter sederhana langsung di dalam State widget:

```dart
// Kode usulan awal AI yang belum diverifikasi
List<Note> filterNotes(List<Note> notes, String query) {
  return notes.where((n) => n.title.contains(query)).toList();
}
```

### Verifikasi 6 Langkah

1. **Baca Tiap Baris:** Kode di atas diperiksa alur eksekusinya.
2. **Cek Import & Dependency Rule:** Penempatan filter di dalam file widget mencampurkan tanggung jawab logika bisnis (domain) ke dalam layer UI (*presentation*).
3. **Cek Ketersediaan API:** Method `.contains()` ada di Dart String, namun implementasi ini memiliki cacat logika.
4. **Temuan Bug / Halusinasi Logika:**
   - **Bug 1 (*Case-Sensitive*):** `n.title.contains(query)` bersifat peka huruf besar/kecil. Jika user mencari `"belanja"`, catatan berjudul `"Belanja Mingguan"` tidak akan ditemukan.
   - **Bug 2 (*Unhandled Whitespace*):** Query dengan spasi ekstra di awal/akhir seperti `" belanja "` akan menghasilkan list kosong padahal kata kuncinya ada.
   - **Bug 3 (*Domain Pollution*):** Tidak ada isolasi *use case*, menyulitkan pengujian otomatis tanpa me-render widget.
5. **Bukti Uji (Test Merah Pembukti Bug):**
   ```dart
   // Test gagal (Red) jika memakai logika awal AI
   test('filter harus case-insensitive dan toleran spasi', () {
     final list = [Note(id: 1, title: 'Belanja Mingguan', body: '', updatedAt: DateTime.now())];
     // Logika awal menghasilkan false/empty
     expect(filterNotes(list, '  belanja  '), hasLength(1));
   });
   ```
6. **Uji Manual:** Query pencarian menghasilkan perilaku inkonsisten pada huruf kapital.

---

## 3. Praktikum 3: Debug & Refactor ke Clean Architecture

### Siklus Debugging Berbasis Test
1. **Reproduksi:** Memasukkan query huruf kecil untuk data berhuruf kapital, atau menyertakan spasi di awal/akhir kata kunci.
2. **Isolasi Logika:** Membuat class `SearchNotesUseCase` murni di `lib/domain/search_notes_use_case.dart` yang independen dari package Flutter, SQLite, maupun Dio.
3. **Test Merah:** Menulis unit test di `test/search_filter_test.dart` yang mendefinisikan ekspektasi *case-insensitive* dan *trimmed query*.
4. **Perbaikan Kode:**
   - Menambahkan `.trim().toLowerCase()` pada query dan string target.
   - Mengecek kecocokan pada `title` dan `body`.
   - Mengembalikan daftar asli tanpa filter jika query kosong atau hanya spasi.
5. **Test Hijau & Clean Analyze:** Seluruh test unit & widget berhasil lulus dan `flutter analyze` menghasilkan nol warning.

### Pembagian Layer (Clean Architecture)

```text
lib/pages/notes_page.dart (UI / Presentation)
       |
       v  menyimak filteredNotesProvider & mengupdate searchQueryProvider
lib/data/providers.dart (State / Notifier)
       |
       v  menjalankan aturan pencarian murni
lib/domain/search_notes_use_case.dart (Domain Use Case)
       ^
       |  mengambil data catatan lokal
lib/data/repositories/note_repository.dart (Data / SQLite)
```

- **Fungsi < 40 Baris:** Widget dipecah menjadi komponen modular:
  - `NotesPage`: koordinator utama.
  - `_SearchBar`: kolom input pencarian dengan tombol hapus (*clear*).
  - `_EmptyView`: visual responsif membedakan kondisi list kosong vs tidak ada hasil pencarian.
  - `_NoteTile`: kartu render item catatan.
  - `_SyncStatusBanner`: status sinkronisasi offline.

---

## 4. AI Challenge & Verification Checklist

AI diminta melakukan tinjauan teknis (*code review*) sebagai Senior Developer terhadap implementasi fitur pencarian.

### Hasil Review AI: 3 Temuan & Tindakan

| No | Temuan AI | Level | Keputusan | Alasan Teknis & Bukti |
|:---|:---|:---:|:---:|:---|
| 1 | **Gunakan debounce timer pada TextField** untuk menahan query saat user mengetik cepat. | Saran Performa | **Ditolak** | Operasi pencarian `SearchNotesUseCase` dieksekusi secara *in-memory* pada koleksi catatan lokal (offline list) yang relatif ringan (< 10.000 item), bukan memanggil API jaringan atau query berat ke disk SQLite secara kontinu. Menambahkan debounce timer menambah kompleksitas state dan berpotensi menyebabkan *lag* render UI pada input responsif tanpa manfaat performa yang signifikan untuk kasus ini. |
| 2 | **Pisahkan use case domain murni dari dependensi UI** agar dapat diuji tanpa mocking widget tree. | Blocker Arsitektur | **Diterima** | Sesuai *Clean Architecture* dan *Dependency Rule*. Logika dipindahkan ke `SearchNotesUseCase` tanpa import `package:flutter`. Bukti: Pengujian di `test/search_filter_test.dart` berjalan cepat dan murni sebagai Dart unit test. |
| 3 | **Sediakan dua kondisi empty state yang berbeda** antara list awal kosong vs hasil filter pencarian nihil. | Rekomendasi UX | **Diterima** | User memerlukan feedback yang jelas saat pencarian tidak menghasilkan apapun (`"Tidak ada catatan yang cocok dengan \"$query\""` dilengkapi icon `Icons.search_off_rounded`), berbeda dengan saat database catatan memang masih kosong (`"Belum ada catatan. Tambahkan satu."`). Bukti: Widget test memverifikasi kedua kondisi tersebut secara terpisah. |

### Tabel Keputusan Per File

| File | Tindakan | Justifikasi |
|:---|:---:|:---|
| `lib/domain/search_notes_use_case.dart` | Buat Baru | Domain murni Dart tanpa import Flutter/UI/database, mematuhi Clean Architecture. |
| `lib/data/providers.dart` | Refactor | Menambahkan `searchQueryProvider`, `searchNotesUseCaseProvider`, dan `filteredNotesProvider`. |
| `lib/pages/notes_page.dart` | Refactor | Menambahkan `_SearchBar`, `_EmptyView` adaptif, dan membatasi ukuran fungsi < 40 baris. |
| `test/search_filter_test.dart` | Buat Baru | 5 unit test untuk skenario use case + 2 widget test untuk empty state dan interaksi UI. |

---

## 5. Bukti Mesin Hijau

### 1. `flutter analyze`
```text
Analyzing 09-week-8-ai-assisted-development...
No issues found! (ran in 2.8s)
```

### 2. `dart format --set-exit-if-changed .`
```text
Formatted 17 files (0 changed) in 0.05 seconds.
Exit code: 0
```

### 3. `flutter test`
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

## 6. Refleksi

1. **Satu halusinasi/bug AI apa yang Anda temukan dan bagaimana membuktikannya?**
   - AI mengusulkan fungsi filter sederhana menggunakan `contains(query)` tanpa konversi huruf kecil dan tanpa `.trim()`. Hal ini dibuktikan dengan membuat unit test yang memasukkan kata kunci huruf kecil `"belanja"` terhadap data judul `"Belanja Mingguan"`, yang menghasilkan kegagalan tes (merah) pada implementasi awal.
2. **Prompt mana yang paling membantu dan apa yang Anda ubah?**
   - Prompt formula 5 slot dengan pembatasan eksplisit (*Batas: jangan panggil database dari widget, isolasi use case di domain murni, batasi fungsi maks 40 baris*). Penegasan batasan arsitektur membuat AI tidak mencampurkan logika SQL atau query langsung di dalam komponen `StatefulWidget`.
3. **Satu refactor apa yang Anda lakukan pada kode AI?**
   - Memisahkan logika filter dari widget ke dalam `SearchNotesUseCase` di layer domain, serta menghubungkannya ke Riverpod melalui `filteredNotesProvider` reaktif. Selain itu, memecah widget `NotesPage` menjadi komponen-komponen kecil (`_SearchBar`, `_EmptyView`, `_NoteTile`) agar masing-masing fungsi berada di bawah 40 baris.
4. **Keputusan terima/tolak mana yang paling sulit?**
   - Menolak usulan AI untuk menerapkan debounce timer (`async debounce/Timer`). Secara konseptual debounce terdengar canggih dan sering diusulkan untuk input teks, namun untuk data offline yang sudah ada di memori, debounce justru memperkenalkan *asynchronous latency* dan *memory leak* potensial jika timer tidak di-dispose dengan cermat. Keputusan menolak ini didasarkan pada pertimbangan arsitektur yang pragmatis dan efisien.
