# Week 7 — Clean Architecture

Folder ini adalah versi portfolio Week 7 yang dibuat dari refactor project
`campus_notify` Minggu 6. Fokus utamanya adalah pemisahan feature-first Clean
Architecture sambil mempertahankan fitur autentikasi, keamanan, FCM, dan deep
link notifikasi yang sudah ada.

## Week 7 — Clean Architecture

Refactor Week 7 memisahkan fitur utama menjadi `presentation`, `domain`, dan
`data` dengan arah dependensi menuju domain.

```text
presentation (Widget, Provider, Router)
      |
      v
domain (Entity, Repository Interface, Use Case, Failure)
      ^
      |
data (Model, Repository Implementation, plugin/backend detail)
```

Struktur feature-first yang diterapkan:

```text
lib/
├── core/
│   ├── failures.dart
│   └── format.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── announcements/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── push/
│       └── presentation/
├── data/              # compatibility + shared demo API/token store
├── notifications/     # FCM service/platform detail
├── pages/             # compatibility export + home page
└── routes.dart
```

### Audit layer sebelum refactor

| File lama | Layer awal | Masalah/keputusan |
| --- | --- | --- |
| `data/auth_repository.dart` | data + domain tercampur | Dipecah menjadi interface domain dan mock implementation data. |
| `providers/auth_provider.dart` | presentation/DI | Dipindah ke `features/auth/presentation/providers`. |
| `pages/login_page.dart` | presentation | Dipindah ke `features/auth/presentation/pages`. |
| `pages/announcement_page.dart` | presentation dengan data hardcoded | Dipindah ke fitur announcements dan membaca use case/provider. |
| `notifications/route_from_message.dart` | utility/presentation boundary | Parsing route memakai fungsi murni `core/format.dart`. |
| `data/api_client.dart` | data | Tetap data/shared demo API; refresh memakai interface auth domain. |

### Fitur yang sudah clean architecture

- `auth`
  - entity: `AuthSession`
  - repository interface: `AuthRepository`
  - use case: `LoginUser`, `RefreshAccessToken`
  - data implementation: `MockAuthRepository`
  - provider wiring: `auth_provider.dart`
- `announcements`
  - entity: `Announcement`
  - repository interface: `AnnouncementRepository`
  - use case: `GetAnnouncements`, `GetAnnouncementDetail`
  - data implementation: `DemoAnnouncementRepository`
  - provider wiring: `announcement_providers.dart`

### Verifikasi dependency rule

`rg` tidak tersedia di environment ini, jadi pemeriksaan dilakukan dengan regex
ekuivalen melalui tool pencarian konten.

| Pemeriksaan | Hasil |
| --- | --- |
| Presentation bebas `Dio/openDatabase/FlutterSecureStorage/SharedPreferences/jsonDecode` | 0 hasil |
| Domain `auth` bebas Flutter/Dio/SQLite/Firebase | 0 hasil |
| Domain `announcements` bebas Flutter/Dio/SQLite/Firebase | 0 hasil |
| `core` bebas Flutter/Dio/SQLite/Firebase | 0 hasil |

Dokumentasi AI Challenge Week 7 tersedia di:

```text
docs/week7-ai-clean-architecture.md
```


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

## Matriks pengujian manual FCM

Uji ini wajib dilakukan setelah `google-services.json` ditambahkan dan aplikasi
dijalankan di emulator dengan Google Play Services atau perangkat fisik.

| State | Yang diharapkan | Cara uji | Status saat ini |
| --- | --- | --- | --- |
| Foreground | Banner lokal muncul, klik masuk ke `/pengumuman/3` | Aplikasi terbuka, kirim payload `notification + data` | Menunggu konfigurasi Firebase |
| Background | Banner sistem muncul, klik masuk ke route benar | Tekan Home, kirim payload, klik banner | Menunggu konfigurasi Firebase |
| Terminated | Aplikasi terbuka ke route benar via `getInitialMessage()` | Swipe-close aplikasi, kirim payload, klik banner | Menunggu konfigurasi Firebase |

Contoh payload data yang dipakai untuk uji deep link:

```json
{
  "route": "/pengumuman/3",
  "id": "3"
}
```

## AI Challenge dan dokumentasi bukti

- Dokumentasi AI Challenge tersedia di `docs/ai-challenge.md`.
- Daftar screenshot yang perlu dikumpulkan tersedia di `screenshots/README.md`.
- Screenshot nyata belum disertakan karena repository ini belum memiliki file
  konfigurasi Firebase (`android/app/google-services.json`).

## Struktur project

```text
lib/
├── app_router.dart
├── main.dart
├── routes.dart
├── data/
│   ├── api_client.dart
│   ├── api_errors.dart
│   ├── auth_repository.dart
│   └── token_store.dart
├── notifications/
│   ├── push_service.dart
│   └── route_from_message.dart
├── pages/
│   ├── announcement_page.dart
│   ├── home_page.dart
│   └── login_page.dart
└── providers/
    ├── api_provider.dart
    ├── auth_provider.dart
    └── push_provider.dart
```

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

## Checklist verifikasi mandiri

- [x] Token aplikasi disimpan melalui `flutter_secure_storage`, bukan `SharedPreferences`.
- [x] Access token dipasang sebagai `Authorization: Bearer ...`.
- [x] `401` memicu refresh satu kali lalu retry request.
- [x] Refresh token kosong/kedaluwarsa membersihkan sesi dan mengembalikan user ke login.
- [x] Route guard mengarahkan user tanpa sesi ke `/login`.
- [x] `routeFromMessage` diuji tanpa Firebase sungguhan.
- [x] Background handler FCM top-level dan diberi `@pragma('vm:entry-point')`.
- [x] Foreground notification ditampilkan manual via local notification.
- [x] Topic messaging `pengumuman-kampus` tersedia.
- [ ] Screenshot pengujian foreground/background/terminated diambil setelah Firebase dikonfigurasi.
