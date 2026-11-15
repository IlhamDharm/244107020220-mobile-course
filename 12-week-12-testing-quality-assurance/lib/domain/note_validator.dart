/// Fungsi validasi judul catatan / tugas sesuai pedoman Pengujian Modul 12.
/// Menguji kasus batas (edge cases): teks kosong, spasi berlebih, dan panjang minimum.
bool isValidNoteTitle(String value) {
  return value.trim().isNotEmpty;
}

/// Validator formal untuk form input dengan pesan kesalahan spesifik.
String? validateNoteTitle(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Judul catatan tidak boleh kosong';
  }
  if (value.trim().length < 3) {
    return 'Judul catatan minimal 3 karakter';
  }
  if (value.trim().length > 100) {
    return 'Judul catatan maksimal 100 karakter';
  }
  return null;
}
