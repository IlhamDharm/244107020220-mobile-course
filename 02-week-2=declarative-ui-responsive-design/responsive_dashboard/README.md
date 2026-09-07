# 🎓 Flutter Week 2: Academic Overview Dashboard

Proyek ini dibangun untuk memenuhi tugas **Week 2 Codelab: Declarative UI & Responsive Design** pada matakuliah Pemrograman Mobile. Aplikasi ini menerapkan prinsip tata letak responsif, manajemen tema (Light & Dark Mode), serta penambahan label aksesibilitas untuk *screen reader*.

---

## 👨‍💻 Identitas Mahasiswa

* **Nama:** Ilham Dharma Atmaja
* **NIM:** 244107020
* **Kelas:** TI-3D
* **Proyek:** `responsive_dashboard`

---

## 📱 Fitur Utama & Tampilan Aplikasi

1. **Tata Letak Responsif (Responsive Layout):**
   * Menggunakan `LayoutBuilder` dan `GridView.count` dengan nilai kustom `kWideBreakpoint = 700.0`.
   * Menampilkan **1 kolom** pada layar sempit (< 700px) dan **2 kolom** pada layar lebar (≥ 700px).
2. **Kartu Header & Informasi Reusable:**
   * `ProfileHeaderCard`: Menampilkan foto profil, nama, NIM, dan kelas mahasiswa.
   * `InfoCard`: Widget *reusable* untuk kartu status (*Assignments, Attendance, Portfolio, Current Week*).
3. **Peralihan Tema (Theme Toggle):**
   * Menggunakan `CupertinoSwitch` di AppBar untuk beralih secara dinamis antara **Light Theme** dan **Dark Theme**.
4. **Aksesibilitas (Accessibility):**
   * Setiap elemen penting dibungkus dengan widget `Semantics` agar dapat dibaca dengan jelas oleh *screen reader*.

---

## 🖼️ Tangkapan Layar (Screenshots)

### 1. Mode Terang (Light Mode - Layar Sempit)
<img width="1475" height="1127" alt="Screenshot 2026-09-07 105758" src="https://github.com/user-attachments/assets/4e05bafb-4f13-48c8-8b21-86a861a8b6f0" />

### 2. Mode Gelap (Dark Mode - Layar Sempit)
<img width="1473" height="1117" alt="Screenshot 2026-09-07 105803" src="https://github.com/user-attachments/assets/e96860f6-cb18-4ebd-823d-c54b728b9bfd" />

### 3. Tampilan Academic Overview Final
<img width="1465" height="1117" alt="Screenshot 2026-09-07 110744" src="https://github.com/user-attachments/assets/b96f86e2-d504-40ce-83f4-2d22aae5e4ac" />

---

## 🤖 AI Exploration & Verification Log

### 1. Prompt Desain Layout
* **Prompt:** "Bandingkan dua tata letak dashboard akademik untuk Flutter: versi GridView dan versi LayoutBuilder + Column. Jelaskan trade-off responsif dan aksesibilitasnya."
* **Hasil & Analisis:**
  * `GridView.count`: Sangat baik untuk penataan grid yang simetris dan mudah mengatur rasio elemen via `childAspectRatio`.
  * `LayoutBuilder + Column`: Memberikan kontrol tinggi untuk tata letak linier vertikal, namun butuh penanganan manual untuk pemisahan kolom pada layar lebar.
* **Keputusan Teknis:** Dipilih kombinasi `LayoutBuilder` untuk mendeteksi breakpoint dan `GridView.count` untuk merender grid responsif.

### 2. Prompt Penguatan Konsep (Expanded inside Row)
* **Prompt:** "Jelaskan kapan penggunaan Expanded justru menyebabkan overflow di dalam Row, beri contoh kode yang gagal dan perbaikannya."
* **Hasil & Analisis:** `Expanded` akan menyebabkan error *unbounded width/height* jika diletakkan di dalam kontainer yang lebarnya tidak terbatas (seperti `Row` di dalam scrollview horizontal tanpa batasan). 
* **Solusi:** Memastikan `Row` berada di dalam konteks dengan batas lebar yang jelas sebelum menggunakan `Expanded`.

### 3. Verification Prompt (Self-Audit)
* **Prompt:** "Periksa kembali rekomendasi layout di atas: apakah tetap responsif di bawah 600px, apakah mengurangi aksesibilitas, dan apakah ada widget yang tidak tersedia di Flutter stabil saat ini?"
* **Hasil Auditing:** Seluruh widget (`GridView`, `LayoutBuilder`, `Semantics`, `CupertinoSwitch`) tersedia pada channel Flutter *stable*. Aplikasi terbukti berjalan tanpa *overflow* pada resolusi di bawah 600px.
