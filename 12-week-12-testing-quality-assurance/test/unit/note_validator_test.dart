import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/domain/note_validator.dart';

void main() {
  group('isValidNoteTitle (Unit Tests & Kasus Tepi)', () {
    test('menerima judul yang berisi teks normal', () {
      // Arrange & Act & Assert
      expect(isValidNoteTitle('Belajar Pemrograman Mobile'), isTrue);
      expect(isValidNoteTitle('Catatan 123'), isTrue);
    });

    test(
      'menerima judul yang memiliki spasi di awal atau akhir (akan di-trim)',
      () {
        expect(isValidNoteTitle('   Praktikum Flutter   '), isTrue);
        expect(isValidNoteTitle('\n\tTugas Penting\t'), isTrue);
      },
    );

    test('menolak teks kosong (kasus tepi 1)', () {
      expect(isValidNoteTitle(''), isFalse);
    });

    test('menolak teks yang hanya terdiri dari spasi (kasus tepi 2)', () {
      expect(isValidNoteTitle('   '), isFalse);
      expect(isValidNoteTitle(' \t \n '), isFalse);
    });
  });

  group('validateNoteTitle (Form Validator Tests)', () {
    test('mengembalikan null saat judul valid', () {
      expect(validateNoteTitle('Struktur Data'), isNull);
      expect(validateNoteTitle('Praktikum Mobile Development'), isNull);
    });

    test('mengembalikan error saat judul null atau kosong', () {
      expect(validateNoteTitle(null), 'Judul catatan tidak boleh kosong');
      expect(validateNoteTitle(''), 'Judul catatan tidak boleh kosong');
      expect(validateNoteTitle('   '), 'Judul catatan tidak boleh kosong');
    });

    test('mengembalikan error saat judul kurang dari 3 karakter (nilai batas bawah)', () {
      expect(validateNoteTitle('ab'), 'Judul catatan minimal 3 karakter');
      expect(validateNoteTitle(' a '), 'Judul catatan minimal 3 karakter');
    });

    test('mengembalikan error saat judul lebih dari 100 karakter (nilai batas atas)', () {
      final longTitle = 'a' * 101;
      expect(
        validateNoteTitle(longTitle),
        'Judul catatan maksimal 100 karakter',
      );
    });
  });
}
