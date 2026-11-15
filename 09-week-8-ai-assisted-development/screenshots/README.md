# Screenshots Panduan Pengujian Manual

Sesuai instruksi modul praktikum Minggu 9:
> Uji manual 3 query + screenshot:
> 1. Query kosong (menampilkan semua catatan)
> 2. Query cocok (menampilkan catatan hasil filter)
> 3. Query tidak cocok (menampilkan empty state "Tidak ada catatan yang cocok...")

## Daftar Skenario Uji Visual:

| File | Skenario | Keterangan |
|---|---|---|
| `01_query_kosong.png` | Input pencarian kosong | Seluruh catatan ditampilkan secara normal |
| `02_query_cocok.png` | Input kata kunci misal `"belanja"` | Hanya catatan yang relevan yang ditampilkan |
| `03_query_tidak_cocok.png` | Input kata kunci tidak ada misal `"xyz"` | Menampilkan ilustrasi/ikon `search_off` dan teks empty state |

*(Catatan: Tangkapan layar dari emulator/perangkat riil dapat disimpan pada folder ini)*
