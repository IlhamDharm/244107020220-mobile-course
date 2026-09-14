# 🚀 Week 3 — Navigation & State Management

> Praktikum Flutter yang membahas **declarative navigation** menggunakan `go_router` serta **state management** menggunakan Riverpod melalui aplikasi Navigation dan ToDo.

---

## 📌 Tentang Project

Week 3 terdiri dari **dua aplikasi Flutter** yang dibuat untuk mempraktikkan konsep navigasi dan pengelolaan state:

### 🧭 `week3_navigation`

Demonstrasi **declarative navigation** menggunakan `go_router`, termasuk routing berbasis URI, `ShellRoute`, dan `NavigationBar`.

### ✅ `week3_todo`

Aplikasi ToDo sederhana yang menerapkan **Riverpod** untuk mengelola state lokal dan global, filter data, asynchronous state, serta automated testing.

---

## ✨ Fitur

### Navigation

* 🧭 Declarative routing berbasis URI
* 🛣️ Route `/` dan `/stats`
* 🧱 Persistent `ShellRoute`
* 🧭 Bottom navigation menggunakan `NavigationBar`

### ToDo

* ➕ Menambahkan ToDo melalui modal dialog
* ☑️ Menandai ToDo sebagai selesai
* 🗑️ Menghapus ToDo
* 🔎 Filter berdasarkan status:

  * Semua
  * Aktif
  * Selesai
* 📊 Halaman statistik ToDo
* ⏳ Penanganan `AsyncValue`:

  * Loading
  * Error
  * Success
* 🔄 Retry dan invalidasi state menggunakan `ref.invalidate`
* 🧪 Unit test dan widget test

---

## 🛠️ Tech Stack

| Teknologi        | Versi / Keterangan |
| ---------------- | ------------------ |
| **Flutter**      | 3.x                |
| **Dart**         | Dart SDK           |
| **Riverpod**     | v3.4.3             |
| **go_router**    | v18.0.1            |
| **flutter_test** | Automated testing  |

---

## 📁 Struktur Project

```text
03-week-3-Navigation-State-Management/
│
├── week3_navigation/
│   ├── lib/
│   ├── test/
│   └── pubspec.yaml
│
├── week3_todo/
│   ├── lib/
│   ├── test/
│   └── pubspec.yaml
│
└── README.md
```

---

## ⚙️ Cara Menjalankan

Pastikan Flutter sudah terinstall pada perangkat.

### 🧭 Navigation

```bash
cd week3_navigation
flutter pub get
flutter run
```

### ✅ ToDo

```bash
cd week3_todo
flutter pub get
flutter run
```

---

## 🧪 Pengujian

### Static Analysis

```bash
flutter analyze
```

Hasil:

```text
No issues found!
```

### Automated Tests

```bash
flutter test
```

Hasil:

```text
00:03 +2: All tests passed!
```

---

## 📸 Screenshots

### 🧭 Navigation

| Navigasi Dasar                                                                                          | Statistik                                                                                               |
| ------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| <img src="https://github.com/user-attachments/assets/d51600f6-32d9-4a29-b085-75edb54156dc" width="220"> | <img src="https://github.com/user-attachments/assets/b311615c-fdc0-43b5-9283-673bff578ccc" width="220"> |

### ✅ ToDo

| ToDo Kosong                                                                                             | Filter ToDo                                                                                             |
| ------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| <img src="https://github.com/user-attachments/assets/53d6b2c9-ab41-49fe-a850-112bde97499f" width="220"> | <img src="https://github.com/user-attachments/assets/a9b7df93-1364-4a31-ac66-f6006f72c9fb" width="220"> |

### ⏳ AsyncValue

| AsyncValue Produk                                                                                       |
| ------------------------------------------------------------------------------------------------------- |
| <img width="220" src="https://github.com/user-attachments/assets/a6b6249b-aee1-4a38-8665-df7c7f95fde5" > |

---

## 💡 Refleksi Praktikum

### `setState` vs Riverpod

`setState` cukup digunakan untuk **ephemeral atau local state** yang hanya dibutuhkan oleh satu widget, seperti input form pada modal.

Sementara itu, **Riverpod** lebih sesuai untuk application state yang perlu digunakan oleh beberapa widget atau layar serta dapat diuji secara independen.

### `context.go` vs `context.push`

`context.go` digunakan untuk berpindah ke lokasi atau tab utama berdasarkan URI, sedangkan `context.push` digunakan untuk menambahkan route baru ke dalam navigation stack sehingga tombol **Back** dapat kembali ke halaman sebelumnya.

### Keamanan `AsyncValue`

Penggunaan `AsyncValue` membantu menghindari **impossible states** yang dapat terjadi jika status `loading`, `error`, dan `success` disimpan sebagai beberapa boolean terpisah.

Pattern `.when()` membuat setiap kondisi harus ditangani dengan jelas:

```dart
asyncValue.when(
  loading: () => ...,
  error: (error, stack) => ...,
  data: (data) => ...,
);
```

### Perbaikan Kode AI

Beberapa bagian kode hasil generate AI diperbaiki agar mengikuti API Riverpod terbaru.

Perubahan yang dilakukan antara lain:

* Mengganti `StateProvider` yang sudah deprecated.
* Menggunakan `Notifier` dan `AsyncNotifier`.
* Memindahkan mutasi state ke method seperti `.setFilter()`.
* Menghindari penggunaan langsung `.state` dari luar notifier untuk menghilangkan warning `invalid_use_of_protected_member`.

---

## 🎯 Tujuan Pembelajaran

Melalui praktikum ini, beberapa konsep yang dipelajari adalah:

* Declarative navigation pada Flutter
* Routing menggunakan `go_router`
* Penggunaan `ShellRoute`
* State management menggunakan Riverpod
* Local dan global state
* Asynchronous state dengan `AsyncValue`
* Provider invalidation dan retry
* Unit testing
* Widget testing
* Penggunaan API Riverpod modern

---

## 👤 Author

**Ilham Dharma Atmaja**

* **NIM:** `244107020220`
* **Kelas:** `TI-3D`
* **Repository:** [244107020220-mobile-course](https://github.com/IlhamDharm/244107020220-mobile-course.git)
