# Campus Notify — Praktikum Week 6

Aplikasi Flutter untuk praktikum autentikasi, keamanan, Firebase Cloud
Messaging (FCM), dan deep link notifikasi.

## Praktikum 1 — Login, secure storage, dan token refresh

- Login memakai mock repository agar dapat diuji tanpa server autentikasi.
- Access token dan refresh token dikelola melalui `TokenStore`; implementasi
  aplikasi menggunakan `flutter_secure_storage`.
- GoRouter mengarahkan pengguna tanpa sesi ke `/login`.
- Dio menyertakan access token pada header `Authorization`, mencoba refresh
  satu kali saat menerima 401, lalu mengulang request.
- Jika refresh token kosong/kedaluwarsa, token dibersihkan dan sesi diarahkan
  kembali ke halaman login.
- Halaman utama memiliki tombol uji untuk refresh berhasil dan refresh
  kedaluwarsa.

**Catatan:** login, refresh, dan endpoint API di praktikum ini adalah simulasi,
bukan layanan autentikasi atau backend kampus sungguhan.

## Praktikum 2 — Permission dan token lifecycle FCM

Implementasi di `lib/notifications/push_service.dart`:

- Meminta izin notifikasi melalui Firebase Messaging.
- Mengambil token FCM setelah izin diberikan dan memantau `onTokenRefresh`.
- Menampilkan hanya 12 karakter awal token pada aplikasi. Tombol salin menyalin
  token lengkap ke clipboard; jangan memasukkan token penuh ke log atau
  screenshot laporan.
- Menyediakan channel notifikasi Android dan inisialisasi notifikasi lokal.

### Menautkan Firebase Android

1. Daftarkan aplikasi Android di Firebase Console dengan package name yang
   sama dengan `applicationId` pada `android/app/build.gradle.kts`.
2. Unduh `google-services.json` ke `android/app/google-services.json`.
3. Jalankan ulang aplikasi secara penuh. Gradle menerapkan Google Services
   plugin jika file konfigurasi itu tersedia.
4. Login, pilih **Izin & ambil token FCM**, lalu izinkan notifikasi pada
   perangkat.

Konfigurasi Firebase tidak disertakan di repository ini. Sampai file tersebut
ditambahkan, aplikasi menampilkan status Firebase yang gagal secara eksplisit;
token FCM dan pengiriman notifikasi nyata belum dapat diuji.

Contoh POST `/devices` pada modul memerlukan backend kampus. Belum ada URL
backend dalam proyek ini, sehingga token lifecycle saat ini diperbarui di
aplikasi dan belum didaftarkan ke server.

## Praktikum 3 — Payload, app state, deep link, dan topic

- Background handler adalah fungsi top-level dengan
  `@pragma('vm:entry-point')`.
- Pesan foreground ditampilkan manual menggunakan `flutter_local_notifications`.
- Klik dari foreground meneruskan payload ke rute; klik pesan background
  menggunakan `onMessageOpenedApp`; startup dari terminated menggunakan
  `getInitialMessage`.
- `routeFromMessage(Map<String, dynamic>)` memetakan payload ke rute tanpa
  dependensi pada Firebase dan diuji sebagai fungsi murni.
- Detail pengumuman tersedia di `/pengumuman/:id`.
- Tombol topik berlangganan/berhenti dari `pengumuman-kampus`. Topik cocok
  untuk broadcast; pesan personal sebaiknya ditujukan ke token perangkat.
- Bentuk payload gabungan yang diharapkan:

```json
{
  "notification": {
    "title": "Jadwal kuliah berubah",
    "body": "Kuliah Pemrograman Mobile dipindah ke Ruang A2."
  },
  "data": {
    "route": "/pengumuman/3",
    "id": "3"
  }
}
```

Kirim payload dari Firebase Console/backend dan uji aplikasi pada foreground,
background, dan terminated untuk membuktikan lifecycle sebenarnya. Simulasi
widget/unit test tidak menggantikan pengujian tersebut. Karena konfigurasi
Firebase belum tersedia di repository ini, uji FCM nyata masih menunggu setup
Firebase.

## Menjalankan dan menguji

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

Unit test mencakup route guard/login mock, penyimpanan token melalui fake store,
refresh/retry Dio, perilaku sesi saat refresh kedaluwarsa, dan parsing payload.
Firebase Messaging tidak dipanggil oleh unit test.
