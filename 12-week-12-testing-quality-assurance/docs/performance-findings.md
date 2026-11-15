# Temuan Masalah Performa Aplikasi (Performance Findings) — Week 11

**Mata Kuliah:** Pemrograman Mobile  
**Modul:** #11 | Optimasi Performa  
**Mahasiswa:** Ilham Dharma A (NIM: 244107020220)  
**Tanggal:** 15 November 2026  

---

## 1. Metodologi Baseline Profiling

Sebelum menerapkan optimasi, aplikasi dijalankan menggunakan mode profil (`flutter run --profile`) pada perangkat/emulator untuk mengukur performa nyata tanpa beban overhead mode debug:

```bash
flutter run --profile
```

Instrumen yang digunakan:
- **Flutter DevTools Performance Tab:** Menganalisis Frame Chart, Flame Chart (UI Thread vs Raster Thread), dan mendeteksi jank (frame merah > 32ms atau kuning 16–32ms).
- **Flutter DevTools Memory Tab:** Mengamati Heap Size, Dart/Native memory allocation, serta memonitor pertumbuhan objek (Heap Snapshot).
- **Flutter DevTools Network Tab:** Menganalisis jumlah pemanggilan HTTP dan payload response.

---

## 2. Rincian Masalah yang Ditemukan (Bottlenecks)

Berdasarkan hasil baseline profiling pada skenario scrolling daftar, navigasi halaman, dan pembaruan state, diidentifikasi **5 masalah performa utama**:

### Masalah 1: Widget Rebuild Berlebih pada Halaman Utama & ListView (UI Thread Bottleneck)
- **Gejala:**  
  Pada Flame Chart, event `build` memakan waktu 18.4 ms saat ada aksi pengguna (mengetik pencarian atau pergantian banner status).
- **Penyebab:**
  1. `NotesPage` dan `PostsPage` menyimak provider berlevel tinggi secara keseluruhan (`ref.watch(dirtyCountProvider)` dan `ref.watch(postsRefreshMessageProvider)`).
  2. Saat satu pesan refresh atau satu catatan kotor (*dirty*) berubah, seluruh widget tree halaman (termasuk input search, text controller, dan list item) ikut dibangun ulang (*rebuilt*) dari akar.
  3. Komponen item list dibuat langsung di dalam closure `itemBuilder` tanpa diekstrak menjadi widget mandiri berkategori `const`.
- **Dampak:**  
  CPU UI Thread bekerja ekstra keras membangun ulang objek widget yang sebenarnya tidak mengalami perubahan data visual.

---

### Masalah 2: Ketiadaan `RepaintBoundary` Menyebabkan Over-Painting (Raster Thread Bottleneck)
- **Gejala:**  
  Pada tab Performance DevTools, Raster Thread menunjukkan lonjakan frame time (kuning-merah) saat melakukan scrolling cepat atau saat ada animasi `CircularProgressIndicator`.
- **Penyebab:**
  1. Seluruh item `ListTile` pada daftar catatan, daftar postingan, dan gelembung obrolan AI (`_ChatBubble`) berada pada satu render layer yang sama.
  2. Ketika satu elemen mengalami perubahan tampilan (misalnya animasi loading berputar atau kursor teks berkedip), Flutter me-repaint seluruh canvas viewport layer tersebut.
- **Dampak:**  
  Raster Thread GPU terbebani menggambar ulang area layar yang statis, menyebabkan frame drop (*jank*) saat scrolling.

---

### Masalah 3: Ketiadaan Pagination & Lazy Loading pada Daftar Panjang (Memory & Network Bottleneck)
- **Gejala:**  
  Request API `/posts` mengunduh seluruh 100 entitas postingan sekaligus dalam satu pemanggilan jaringan. Initial load memakan waktu 450ms+ dan alokasi memori Dart Heap melonjak sebesar +8.4 MB secara tiba-tiba.
- **Penyebab:**
  1. `PostRepository.fetchPosts()` memanggil endpoint tanpa parameter pagination (`_page` dan `_limit`).
  2. Semua data di-deserialize menjadi model objek Dart sekaligus, meskipun layar mobile hanya dapat menampilkan 6–8 item dalam satu viewport layar awal.
- **Dampak:**  
  Konsumsi memori meningkat drastis, boros kuota data seluler pengguna, dan waktu respon awal (*Time to First Contentful Paint*) menjadi lambat.

---

### Masalah 4: Strategi Caching Jaringan Belum Optimal (Stale-While-Revalidate Belum Granular)
- **Gejala:**  
  Saat beralih ke tab Posts, pengguna melihat layar kosong (*blank / spinner*) sementara data jaringan belum selesai diunduh, meskipun data lokal sudah tersedia di SQLite.
- **Penyebab:**
  1. Pembacaan cache belum terintegrasi dengan pagination lokal (selalu membaca seluruh isi tabel cache).
  2. Tidak ada penambahan data cache bertahap (*incremental caching / append*), sehingga data lama sering ditimpa atau dihapus seluruhnya.
- **Dampak:**  
  Aplikasi terasa lambat dan tidak responsif bagi pengguna di kondisi jaringan lambat (*high latency*).

---

### Masalah 5: Potensi Memory Leak pada Controller & Scroll Listener yang Tidak Terkelola
- **Gejala:**  
  Pada DevTools Memory tab, Heap snapshot menunjukkan instance `ScrollController` dan `TextEditingController` tidak segera dibebaskan oleh Garbage Collector (GC) setelah keluar masuk halaman.
- **Penyebab:**
  1. Ketiadaan metode `dispose()` yang ketat atau listener yang tidak dicopot sebelum widget dihapus dari widget tree.
- **Dampak:**  
  Retained size memori meningkat secara kumulatif setiap kali pengguna berpindah tab/halaman secara berulang.

---

## 3. Rencana Tindakan Optimasi

| No | Masalah | Rencana Solusi Optimasi | Target Metrik |
|:---:|:---|:---|:---:|
| 1 | Rebuild berlebih | Ekstrak widget kecil `const` + gunakan `ref.watch(provider.select(...))` | Frame build time < 10 ms |
| 2 | Over-painting raster | Bungkus list tiles dan chat bubbles dengan `RepaintBoundary` | Paint/Raster time < 6 ms |
| 3 | Data besar tanpa pagination | Terapkan Infinite Scroll Lazy Loading (`ScrollController` + threshold 200px) | Initial memory allocation turun ~40% |
| 4 | Network latency blocking | Pola Stale-While-Revalidate + incremental SQLite cache | Initial visual display < 16 ms |
| 5 | Potensi memory leak | Lifecycle cleanup ketat di `dispose()` | 0 leaked controller instance |
