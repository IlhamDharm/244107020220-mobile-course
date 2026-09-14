# 🚀 Week 3: Navigation & State Management

> Praktikum Flutter yang membahas declarative navigation dengan `go_router` serta pengelolaan state lokal dan global menggunakan Riverpod melalui aplikasi ToDo dan halaman statistik.

## 📌 Tentang Project

Project Week 3 terdiri dari dua aplikasi Flutter:

- `week3_navigation`: demonstrasi navigasi deklaratif berbasis URI dengan `go_router`.
- `week3_todo`: aplikasi ToDo dengan state management Riverpod, filter data, penanganan state asynchronous, dan pengujian otomatis.

## ✨ Fitur

- 🧭 Declarative routing berbasis URI untuk route `/` dan `/stats`.
- 🧱 Persistent `ShellRoute` dengan `NavigationBar`.
- ➕ CRUD ToDo: tambah melalui modal dialog, checklist selesai, dan hapus data.
- 🔎 Filter ToDo: Semua, Aktif, dan Selesai menggunakan `SegmentedButton`.
- ⏳ Penanganan siklus `AsyncValue`: Loading, Error, dan Success.
- 🔄 Invalidasi state dan retry menggunakan `ref.invalidate`.
- 🧪 Automated unit test dan widget test.

## 🛠️ Tech Stack

- **Flutter:** 3.x
- **State management:** `flutter_riverpod` v3.4.3
- **Routing:** `go_router` v18.0.1
- **Testing:** `flutter_test`
- **Bahasa:** Dart

## 📁 Struktur Folder

```text
03-week-3=Navigation & State Management/
├── week3_navigation/
│   ├── lib/
│   ├── test/
│   └── pubspec.yaml
├── week3_todo/
│   ├── lib/
│   ├── test/
│   └── pubspec.yaml
├── screenshots/
│   ├── 01_home_navigation.png
│   ├── 02_todo_empty.png
│   ├── 03_async_products.png
│   ├── 04_refactor_todo_filter.png
│   └── 05_stats_page.png
└── README.md
```

## 🚀 Cara Menjalankan

Pastikan Flutter 3.x dan Dart SDK telah terpasang, kemudian jalankan setiap aplikasi dari foldernya masing-masing.

### Aplikasi Navigation

```bash
cd week3_navigation
flutter pub get
flutter run
```

### Aplikasi ToDo

```bash
cd week3_todo
flutter pub get
flutter run
```

## 🧪 Hasil Pengujian

### Static Analysis

```text
$ flutter analyze
No issues found!
```

### Automated Tests

```text
$ flutter test
00:03 +2: All tests passed!
```

## 📸 Tangkapan Layar

| Tampilan 1 | Tampilan 2 | Tampilan 3 |
|---|---|---|
| **Navigasi Dasar**<br>![Navigasi Dasar](screenshots/01_home_navigation.png) | **ToDo Kosong**<br>![ToDo Kosong](screenshots/02_todo_empty.png) |  |
| **AsyncValue Produk**<br>![AsyncValue Produk](screenshots/03_async_products.png) | **Filter ToDo**<br>![Filter ToDo](screenshots/04_refactor_todo_filter.png) | **Statistik**<br>![Statistik](screenshots/05_stats_page.png) |

## 💡 Refleksi Praktikum

- **Kapan `setState` cukup vs Riverpod:** `setState` cukup untuk ephemeral atau local state pada widget, misalnya input form di dalam modal. Riverpod lebih tepat untuk app state global yang dibagikan antar layar dan perlu diuji secara independen.
- **`context.go` vs `context.push`:** `context.go` mengubah URI deklaratif untuk tab navigasi utama, sedangkan `context.push` menumpuk route pada navigation stack untuk alur detail sementara agar tombol back kembali ke layar sebelumnya dengan tepat.
- **Keamanan `AsyncValue`:** Penggunaan `AsyncValue` mencegah impossible states yang dapat terjadi jika `isLoading`, `isError`, dan `isSuccess` disimpan sebagai boolean terpisah. Pattern matching melalui `.when()` memaksa seluruh state ditangani secara aman dan mengurangi risiko null pointer.
- **Perbaikan hasil kode AI:** `StateProvider` yang deprecated diganti dengan class `Notifier` atau `AsyncNotifier` modern. Mutasi state langsung melalui `.state =` juga dipindahkan ke method `.setFilter()` untuk menyelesaikan warning `invalid_use_of_protected_member`.

## 👤 Author

**Ilham Dharma Atmaja**  
NIM: `244107020220`  
Kelas: `TI-3D`  
Repository: [244107020220-mobile-course](https://github.com/IlhamDharm/244107020220-mobile-course.git)
