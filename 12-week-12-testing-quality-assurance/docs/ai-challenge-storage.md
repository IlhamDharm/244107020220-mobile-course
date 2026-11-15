# AI Challenge: Perbandingan Storage Offline Notes

## Prompt yang digunakan

```text
Aplikasi Flutter Offline Notes: CRUD catatan + preferensi tema.
Bandingkan SharedPreferences, Hive, sqflite (SQLite), dan Drift
untuk dua kebutuhan ini. Requirements:
- Kriteria: kompleksitas query, kebutuhan relasi, reaktivitas (stream),
  type-safety, ukuran boilerplate, dan kemudahan testing.
- Beri rekomendasi final: mana untuk preferensi, mana untuk catatan,
  beserta alasannya dalam 1 tabel.
- Tunjukkan skema tabel/kotak untuk 1000+ catatan.
Jelaskan trade-off setiap pilihan.
```

## Output awal AI (sebelum verifikasi)

Untuk aplikasi ini, gunakan **SharedPreferences untuk preferensi tema** dan
pertimbangkan **Drift untuk catatan**. SharedPreferences cocok untuk nilai kecil
dan sederhana seperti boolean tema. Catatan lebih terstruktur dan dapat
bertambah banyak, sehingga tidak cocok disimpan sebagai satu daftar JSON di
SharedPreferences. Drift memberi query SQL yang bertipe, relasi, dan stream
`watch()` untuk memantau perubahan. Untuk kebutuhan CRUD yang lebih sederhana,
sqflite lebih langsung dan memiliki boilerplate lebih sedikit, tetapi query
serta hasilnya perlu dipetakan sendiri.

Contoh skema catatan yang dapat mendukung antrean sinkronisasi:

```text
notes
  id          INTEGER PRIMARY KEY
  title       TEXT NOT NULL
  body        TEXT NOT NULL DEFAULT ''
  updated_at  TEXT NOT NULL
  dirty       INTEGER NOT NULL DEFAULT 0
```

Tambahkan indeks pada kolom yang benar-benar sering dipakai untuk filter atau
pengurutan setelah pola query diketahui. Seribu catatan bukan alasan untuk
memasukkan seluruh daftar ke SharedPreferences; database dapat membaca catatan
secara bertahap dengan `ORDER BY`, `LIMIT`, dan `OFFSET`.

## Tabel perbandingan dan justifikasi

| Kriteria | SharedPreferences | Hive | sqflite (SQLite) | Drift |
|---|---|---|---|---|
| Kompleksitas query | Tidak menyediakan query koleksi; hanya get/set berdasarkan key. | Query dan filter terbatas dibanding SQL; sesuai untuk box/key-value. | SQL penuh: filter, sort, agregasi, transaksi, dan pagination. | SQL penuh dengan API Dart bertipe dan query builder. |
| Relasi | Tidak cocok untuk relasi. | Relasi perlu dimodelkan dan dikelola sendiri. | Relasi SQL/foreign key tersedia; query perlu ditulis dan hasil dipetakan. | Relasi SQL tersedia dan dapat diekspresikan dalam query bertipe. |
| Reaktivitas (stream) | Tidak ada stream perubahan nilai bawaan untuk pola repository ini. | Mendukung notifikasi perubahan box/record; bukan SQL `watch` query. | Tidak menyediakan stream perubahan query bawaan; perlu refresh/invalidation atau solusi tambahan. | Mendukung stream query seperti `watch()` untuk hasil yang berubah. |
| Type-safety | Getter/setter bertipe, tetapi key dan skema nilai dikelola manual. | Nilai dapat bertipe melalui adapter, yang perlu dibuat/dipelihara untuk model. | Batas database memakai kolom/map dinamis; perlu model dan mapping manual. | Skema menghasilkan API Dart bertipe melalui code generation. |
| Ukuran boilerplate | Sangat kecil untuk beberapa preferensi. | Sedang; box, adapter, dan migrasi model perlu dikelola. | Rendah–sedang; SQL, model/map, repository, dan migrasi ditulis manual. | Sedang–tinggi pada awalnya; tabel, generated code, dan migrasi, lalu query lebih terstruktur. |
| Kemudahan testing | Mudah untuk nilai sederhana; gunakan mock/in-memory preferences. | Box sementara/memory memudahkan tes, dengan setup adapter. | Repository dapat diinjeksi dengan database uji; plugin/platform setup menambah pekerjaan. | Database in-memory dan API stream mendukung tes query; perlu menguji generated query dan migrasi. |
| Trade-off utama | Sederhana, tetapi rapuh dan tidak efisien untuk koleksi catatan. | Praktis untuk penyimpanan object/key-value, tetapi query relasional tidak sekuat SQL. | Kontrol SQL langsung dan relatif ringan; lebih banyak mapping manual dan tidak reaktif bawaan. | Aman tipe dan reaktif; ada biaya setup/code generation dan disiplin migrasi. |

## Skema untuk 1000+ catatan

Untuk kebutuhan saat ini, satu tabel catatan cukup. `dirty` dan `updated_at`
mendukung antrean sinkronisasi sederhana; indeks dapat ditambahkan bila pola
query membutuhkannya.

```sql
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL,
  dirty INTEGER NOT NULL DEFAULT 0
);

-- Opsional jika daftar catatan sering difilter berdasarkan status sync:
CREATE INDEX idx_notes_dirty_updated
  ON notes(dirty, updated_at);
```

Contoh pembacaan bertahap:

```sql
SELECT id, title, body, updated_at, dirty
FROM notes
ORDER BY updated_at DESC
LIMIT 50 OFFSET 0;
```

Hindari memuat atau menserialisasi seluruh koleksi ke satu nilai
SharedPreferences. Bila sinkronisasi server kelak membutuhkan retry, penghapusan
offline, atau resolusi konflik lintas perangkat, skema dapat dikembangkan
(misalnya status sync, jumlah percobaan, dan tombstone penghapusan) sesuai
kontrak backend.

## Checklist verifikasi AI

1. **Apakah daftar catatan ditempatkan di SharedPreferences?** Tidak. Itu tidak
   sesuai untuk koleksi yang bertambah dan memerlukan query; SharedPreferences
   digunakan untuk preferensi sederhana.
2. **Apakah skema mendukung antrean sync?** Ya, ada `dirty` dan `updated_at`.
   Repository mengambil catatan dirty dan baru menandainya tersinkron bila
   timestamp tidak berubah selama proses. Backend tulis belum tersedia; skema
   belum mencakup retry counter atau tombstone penghapusan.
3. **Apakah klaim real-time didukung stream?** sqflite tidak menyediakan stream
   query bawaan. Aplikasi menggunakan FutureProvider dan invalidasi setelah
   perubahan, bukan stream database. Drift `watch()` dapat menyediakan stream
   query jika kebutuhan reaktivitas meningkat.
4. **Apakah estimasi boilerplate sudah diverifikasi lewat instalasi dan migrasi?**
   Sebagian. `sqflite` dan `shared_preferences` sudah menjadi dependency proyek,
   jadi instalasi ulang keduanya tidak diukur. Instalasi tambahan
   `sqflite_common_ffi_web` berhasil, dan setup aset Web berhasil. Implementasi
   yang ada membuat skema versi 1 dengan `onCreate`, tetapi belum menjalankan
   migrasi versi skema. Drift/Hive tidak dipasang dan tidak dibandingkan lewat
   implementasi percobaan; estimasi boilerplate dalam tabel adalah perbandingan
   kualitatif, bukan hasil benchmark.
5. **Keputusan akhir pemilik proyek:** SharedPreferences untuk preferensi dan
   SQLite/sqflite untuk catatan. Keputusan ini mengikuti bentuk data: preferensi
   adalah nilai sederhana, sedangkan catatan memerlukan CRUD, query, dan metadata
   sync. sqflite dipilih daripada Drift karena kebutuhan sekarang sederhana dan
   implementasinya telah tersedia; konsekuensinya mapping manual dan refresh
   berbasis invalidasi, bukan stream `watch()`.

## Hasil pengujian proyek

Pengujian berikut dijalankan dari folder proyek `week5_offline_notes` setelah
menambahkan backend SQLite Web:

| Perintah | Hasil |
|---|---|
| `flutter analyze` | Lulus, tidak ditemukan masalah. |
| `flutter test` | Lulus, 4 tes yang ada berhasil. Tes mencakup parsing model post dan logika sinkronisasi; belum mencakup database SQLite sungguhan atau CRUD catatan. |
| `flutter build web` | Lulus. |
| `dart run sqflite_common_ffi_web:setup` | Lulus; membuat `web/sqlite3.wasm` dan `web/sqflite_sw.js`. |

## Batasan dan trade-off yang diterima

- SQLite menyimpan catatan secara lokal, mengurutkan berdasarkan waktu, dan
  mendukung atribut sync tanpa menyerialisasi seluruh daftar sebagai satu nilai.
- Pada Web, SQLite berjalan melalui WASM dan persistensi browser (IndexedDB);
  data terikat pada origin termasuk port. Native tetap menggunakan plugin
  sqflite.
- Aplikasi belum memakai stream database. Bila layar perlu otomatis bereaksi
  pada semua perubahan query, Drift dapat dipertimbangkan sebagai migrasi
  terpisah.
- Tes saat ini memvalidasi analisis, logika sync yang diuji, dan kompilasi Web,
  bukan seluruh perilaku CRUD terhadap database nyata.
