# AI Feature Integration Log — Campus AI Assistant

Dokumen ini mencatat seluruh proses integrasi fitur AI (LLM Gemini API) ke dalam aplikasi Flutter sesuai instruksi modul praktikum *#10 | Integrasi Fitur AI*.

---

## 1. Konsep & Arsitektur Fitur AI

### Fitur yang Diintegrasikan: **Chat Assistant (Multi-Provider: Gemini & 9Router)**
Fitur ini menambahkan asisten pintar interaktif berbasis Large Language Model yang mendukung dua engine:
1. **Google Gemini API:** Pemanggilan langsung ke endpoint Google Generative Language (`gemini-2.5-flash`, `gemini-2.0-flash`).
2. **9Router / OpenAI-Compatible Gateway:** Menghubungkan aplikasi ke AI Gateway lokal 9Router (`http://localhost:20128/v1/chat/completions`) yang dapat merutekan pertanyaan ke berbagai model (DeepSeek, Claude, GPT, dll.) dengan smart fallback dan penanganan token hemat.

### Diagram Arsitektur Integrasi
```text
+-------------------------------------------------------+
|                       Flutter UI                      |
| (lib/features/chat_screen.dart & Quick Prompt Chips)  |
+-------------------------------------------------------+
                 |                           ^
          (user query)                 (AI response)
                 v                           |
+-------------------------------------------------------+
|                    AiService Layer                    |
|           (lib/ai/ai_service.dart)                    |
+-------------------------------------------------------+
        |                  |                 |
 (ambil/simpan key)        |                 |
        v                  v (mode Gemini)   v (mode 9Router)
+-----------------------+  +---------------+ +-----------------------+
| FlutterSecureStorage  |  | Google Gemini | | 9Router / OpenAI      |
| (Keystore / Keychain) |  | Cloud API     | | Local/Remote Gateway  |
+-----------------------+  +---------------+ +-----------------------+
```

---

## 2. Prompt Engineering & Desain Komponen

### A. System Prompt
```text
Kamu adalah asisten catatan kampus yang ramah dan cerdas. 
Jawablah dalam Bahasa Indonesia yang singkat, padat, dan solutif.
Batasi respon maksimal 2-3 paragraf agar nyaman dibaca pada layar perangkat mobile.
Jangan pernah meminta atau menyertakan data pribadi sensitif (seperti NIK, password, nomor telepon).
```

### B. User Prompt Contoh (Quick Action)
```text
User: "Berikan 3 ide catatan terstruktur untuk persiapan ujian pemrograman mobile."
```

### C. Output Awal AI (Generasi Mentah)
```text
Tentu, berikut 3 ide catatan terstruktur untuk persiapan ujian pemrograman mobile:
1. Ringkasan Siklus State Management (Riverpod vs Provider): Catat perbedaan `Notifier`, `FutureProvider`, dan aturan reaktivitas widget.
2. Cheat Sheet SQLite & Clean Architecture: Tulis struktur tabel (id, title, body, dirty), diagram arah dependensi Presentation -> Domain <- Data.
3. Panduan Error Handling & Fallback: Dokumentasikan cara menangani status offline, penanganan timeout HTTP, dan penggunaan secure storage untuk API Key.
```

---

## 3. Keamanan, Privasi, & Manajemen Biaya

| Aspek | Risiko Potensial | Strategi Mitigasi yang Diterapkan |
|:---|:---|:---|
| **Penyimpanan Kunci API** | Kunci API terekspos di kode sumber / repository GitHub publik. | Kunci API disimpan menggunakan `FlutterSecureStorage` (enkripsi KeyStore di Android dan Keychain di iOS). Pengguna memasukkan kunci melalui dialog pengaturan di dalam aplikasi. |
| **Privasi Pengguna** | Data identitas pengguna (NIK, email, token auth) bocor ke server AI pihak ketiga. | Hanya teks pertanyaan dan konteks umum akademik yang dikirim ke API Gemini. Data lokal dan kredensial login tidak pernah dikirimkan ke endpoint AI. |
| **Biaya & Kuota API** | Lonjakan biaya atau habisnya kuota free-tier (*rate limit exceeded*). | Menggunakan model hemat biaya dan respons cepat `gemini-1.5-flash`, membatasi panjang teks prompt, dan menyediakan tombol prompt cepat agar pengguna tidak mengirim query berulang. |
| **Kegagalan Jaringan / Layanan Down** | Aplikasi crash atau freeze saat API Google Gemini tidak dapat dijangkau. | Menerapkan blok `try-catch` dengan dialog fallback ramah pengguna (*"Layanan AI Sibuk. Coba lagi nanti atau gunakan mode offline."*). |

---

## 4. Implementasi Error Handling & Fallback Design

Ketika API key belum diisi atau server mengembalikan error (seperti error 429 atau koneksi terputus), aplikasi tidak crash melainkan menampilkan fallback dialog sesuai spesifikasi modul Langkah 5:

```dart
try {
  final response = await aiService.ask(question);
} catch (e) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Layanan AI Sibuk'),
      content: const Text('Coba lagi nanti atau gunakan mode offline.'),
    ),
  );
}
```

Tersedia opsi langsung pada dialog tersebut untuk membuka pengaturan dan memperbarui API Key.

---

## 5. Bukti Mesin Hijau (Testing & Analisis)

### 1. `flutter analyze`
```text
Analyzing 10-week-10-ai-feature-integration...
No issues found! (ran in 2.6s)
```

### 2. `dart format --set-exit-if-changed .`
```text
Formatted 21 files (0 changed) in 0.06 seconds.
Exit code: 0
```

### 3. `flutter test` (23/23 Lulus)
```text
00:00 +0: test/ai_service_test.dart: ask() melempar exception saat API key belum diatur
00:00 +1: test/ai_service_test.dart: saveApiKey() dan getApiKey() menyimpan dan mengambil key dengan benar
00:00 +2: test/ai_service_test.dart: ask() sukses mengurai respon JSON dari Gemini API
00:00 +3: test/ai_service_test.dart: ask() melempar exception saat server Gemini mengembalikan HTTP error
00:00 +4: test/ai_service_test.dart: ask() sukses mengurai respon dari 9Router (OpenAI-compatible format)
00:00 +5: test/chat_screen_test.dart: menampilkan pesan sambutan awal dari AI Assistant
00:00 +6: test/chat_screen_test.dart: mengirim pesan dan menampilkan respon AI
00:00 +7: test/chat_screen_test.dart: menampilkan dialog fallback saat layanan AI sibuk atau terjadi error
00:01 +15: Semua pengujian catatan & pencarian bawaan (15 test) lulus
00:01 +23: All tests passed!
```

---

## 6. Refleksi

1. **Fitur AI mana yang Anda integrasikan dan mengapa?**
   - Saya mengintegrasikan **Chat Assistant (Campus AI Assistant)** menggunakan Gemini API. Fitur ini sangat kontekstual dengan aplikasi catatan (*offline notes*), memungkinkan mahasiswa merangkum catatan perkuliahan, menanyakan konsep materi secara instan, serta menyusun ide catatan baru dengan bantuan AI langsung dari aplikasi mobile.
2. **Bagaimana Anda melindungi privasi pengguna saat menggunakan AI API?**
   - Kunci API pengguna tidak di-hardcode di kode program melainkan disimpan di hardware-backed secure storage (`FlutterSecureStorage`). Selain itu, data pribadi seperti identitas lokal, token autentikasi, dan database catatan internal tidak dikirim ke cloud AI; hanya teks prompt spesifik yang dikirimkan.
3. **Fallback apa yang Anda sediakan jika layanan AI error?**
   - Aplikasi menyediakan dialog fallback informatif bertajuk *"Layanan AI Sibuk"* yang menyarankan pengguna untuk mencoba lagi nanti atau menggunakan mode offline. Pengguna juga diberikan tombol pintas untuk memeriksa dan mengatur ulang API Key jika terjadi kesalahan konfigurasi.
4. **Satu hal yang Anda pelajari tentang UX fitur AI di mobile?**
   - Responsivitas visual sangat penting pada fitur AI mobile. Pengguna membutuhkan kejelasan status saat AI sedang memproses (*loading indicator*), batasan teks yang pas untuk layar kecil, serta tombol prompt cepat (*Action Chips*) agar pengguna tidak bingung mengetik instruksi dari nol.
