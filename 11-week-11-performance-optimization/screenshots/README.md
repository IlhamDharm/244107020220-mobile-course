# Screenshots Profiling & Optimasi Performa — Week 11

Dokumentasi visual pengujian performa aplikasi pada mata kuliah Pemrograman Mobile (**#11 | Optimasi Performa**).

---

## 📊 1. Galeri Profiling DevTools (Before vs After)

| Baseline Profiling (Sebelum Optimasi - Jank Detected) | Post-Optimization (Setelah Optimasi - 60 FPS) |
|:---:|:---:|
| <img src="before-profile.png" width="460" alt="DevTools Performance Before" /> | <img src="after-profile.png" width="460" alt="DevTools Performance After" /> |
| *Banyak frame merah/kuning melewati budget 16.6 ms (Avg: 22.4 ms)* | *Frame stabil hijau konsisten di bawah 16.6 ms (Avg: 9.2 ms)* |

---

## 📱 2. Pengujian Interaksi Live Metrics pada 4 Tab Aplikasi

Berikut adalah hasil pengujian langsung interaksi UI dengan pemantauan *Chrome DevTools Performance Metrics (INP & CLS)*:

| 1. Tab Catatan (Notes) | 2. Tab Posts (Pagination / Infinite Scroll) |
|:---:|:---:|
| <img src="01_perf_catatan_tab.png" width="360" alt="Performance Catatan Tab" /> | <img src="02_perf_posts_pagination.png" width="360" alt="Performance Posts Pagination" /> |
| *INP: 40 ms (Good) & CLS: 0.02* | *Infinite scroll lazy loading (items 12-19) - INP: 64 ms (Good)* |

<br/>

| 3. Tab AI Chat (Campus Assistant) | 4. Tab Pengaturan (Settings) |
|:---:|:---:|
| <img src="03_perf_ai_chat.png" width="360" alt="Performance AI Chat Tab" /> | <img src="04_perf_pengaturan.png" width="360" alt="Performance Pengaturan Tab" /> |
| *Gelembung obrolan RepaintBoundary - INP: 96 ms (Good)* | *Toggle switch responsif tanpa frame drop - INP: 48 ms (Good)* |

---

## 📈 Rincian Komparasi Metrik Profiling

| Metrik Evaluasi | Baseline Sebelum Optimasi | Hasil Pengujian Nyata | Keterangan & Standar |
|:---|:---:|:---:|:---:|
| **Interaction to Next Paint (INP)** | > 200 ms (Poor) | **40 ms – 96 ms (Good)** | Memenuhi standar Google Web Vitals (< 200 ms) ⚡ |
| **Cumulative Layout Shift (CLS)** | > 0.1 (Unstable) | **0.02 (Good)** | Layout stabil dan tidak bergeser saat scrolling 🎯 |
| **Rata-rata Frame Time** | 22.4 ms (Jank) | **9.2 ms** | Konsisten di bawah frame budget 16.67 ms (60 FPS) 🚀 |
| **Penghematan Bandwidth List** | 100 item (~27.5 KB) | **10 item / page (~2.8 KB)** | Lazy loading menghemat 89.8% transfer data awal 🌐 |
| **Time to First Display (TTFD)** | 480 ms | **< 16 ms** | Konten lokal SQLite tampil instan (Zero Latency) 💾 |
