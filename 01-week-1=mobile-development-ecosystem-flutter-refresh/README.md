# 📱 Week 1: Pengenalan Flutter & Basic Widgets

Dokumentasi tugas praktikum **Week 1** pada mata kuliah Pemrograman Mobile. Praktikum ini mencakup instalasi lingkungan pengembangan Flutter, pemeriksaan dependensi system via `flutter doctor`, serta pembuatan UI Profil Mahasiswa sederhana menggunakan widget dasar Flutter.

---

## 👨‍💻 Identitas Mahasiswa

* **Nama:** ILHAM DHARMA AATMAJA
* **NIM:** 244107020220
* **Kelas:** TI 3D

---

## ⚙️ 1. Pemeriksaan Lingkungan Pengembangan (`flutter doctor`)

Pemeriksaan status instalasi Flutter SDK dan dependensi terkait pada perangkat dilakukan melalui perintah `flutter doctor`.

<img width="1258" height="282" alt="Screenshot 2026-08-31 083653" src="https://github.com/user-attachments/assets/d773b3ce-3df6-4c33-83b4-cc22b82c097d" />

**Hasil Pemeriksaan:**
* **Flutter SDK:** Versi 3.47.2 (Channel stable) terpasang dengan baik pada Microsoft Windows 11.
* **Android Toolchain:** Terkonfigurasi dengan Android SDK version 36.0.0.
* **Chrome:** Siap digunakan sebagai target web development.
* **Visual Studio:** Tanda silang `[X]` dikarenakan belum menginstal beban kerja C++ untuk pengembangan aplikasi desktop Windows (hal ini aman untuk diabaikan karena fokus pengembangan difokuskan pada mobile/web).

---

## 🖼️ 2. Hasil Implementasi UI Profil Mahasiswa

### A. Tampilan Profil Sederhana (Layout Tengah)
Membuat halaman profil mahasiswa sederhana dengan memanfaatkan kombinasi `Column`, `Icon` (topi akademik), `Text` untuk Nama, NIM, dan Status Mahasiswa.

<img width="622" height="1062" alt="Screenshot 2026-08-31 081330" src="https://github.com/user-attachments/assets/ec62f76a-b254-497c-a21a-fcb78546cb30"  />

### B. Tampilan Kartu Identitas (Card Profile)
Mengembangkan layout profil menjadi bentuk kartu (*Card*) yang memuat avatar pengguna (`CircleAvatar`), nama mahasiswa, serta detail NIM dan kelas.

<img width="623" height="1062" alt="Screenshot 2026-08-31 090328" src="https://github.com/user-attachments/assets/02d1208c-18d8-4653-b0be-c95eb1996137" />

---

## 🛠️ Ringkasan Komponen Widget yang Digunakan

* **`Scaffold`:** Struktur utama halaman (menyediakan `AppBar` dan `body`).
* **`Center` & `Column`:** Menata posisi widget secara vertikal agar berada di tengah layar.
* **`Card` & `Container`:** Memberikan dekorasi latar belakang dan sudut membulat (*border radius*) pada UI.
* **`Row` & `Expanded`:** Menata elemen avatar dan teks identitas secara horizontal di dalam kartu.
* **`CircleAvatar` & `Icon`:** Menampilkan simbol visual untuk ikon pengguna dan topi akademik.
