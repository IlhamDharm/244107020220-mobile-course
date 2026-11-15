import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/providers.dart';
import 'package:week5_offline_notes/domain/search_notes_use_case.dart';
import 'package:week5_offline_notes/pages/notes_page.dart';

void main() {
  group('SearchNotesUseCase (Unit Tests)', () {
    const useCase = SearchNotesUseCase();
    final sampleNotes = [
      Note(
        id: 1,
        title: 'Belanja Mingguan',
        body: 'Beli sayur, buah, dan susu',
        updatedAt: DateTime(2026, 11, 1),
      ),
      Note(
        id: 2,
        title: 'Ide Proyek Flutter',
        body: 'Fitur search dan Clean Architecture',
        updatedAt: DateTime(2026, 11, 2),
      ),
      Note(
        id: 3,
        title: 'Rapat Kerja',
        body: 'Membahas daftar belanja inventaris kantor',
        updatedAt: DateTime(2026, 11, 3),
      ),
    ];

    test('query kosong mengembalikan seluruh catatan tanpa filter', () {
      final result = useCase.execute(sampleNotes, '');
      expect(result.length, equals(3));
    });

    test(
      'query hanya spasi mengembalikan seluruh catatan (whitespace-safe)',
      () {
        final result = useCase.execute(sampleNotes, '   ');
        expect(result.length, equals(3));
      },
    );

    test(
      'filter mengabaikan huruf besar/kecil (case-insensitive) pada judul',
      () {
        final result = useCase.execute(sampleNotes, 'belanja');
        // Harusnya menemukan id: 1 (title: Belanja Mingguan) dan id: 3 (body: belanja inventaris)
        expect(result.length, equals(2));
        expect(result.any((n) => n.id == 1), isTrue);
        expect(result.any((n) => n.id == 3), isTrue);
      },
    );

    test('query dengan leading/trailing spasi di-trim dengan benar', () {
      final result = useCase.execute(sampleNotes, '  flutter  ');
      expect(result.length, equals(1));
      expect(result.first.id, equals(2));
    });

    test('query tidak cocok mengembalikan list kosong', () {
      final result = useCase.execute(sampleNotes, 'zzz-tidak-ditemukan');
      expect(result, isEmpty);
    });
  });

  group('NotesPage Search & Empty State (Widget Tests)', () {
    testWidgets('menampilkan empty state pencarian saat query tidak cocok', (
      tester,
    ) async {
      final testNotes = [
        Note(
          id: 1,
          title: 'Catatan Kuliah',
          body: 'Materi mobile programming',
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesProvider.overrideWith((ref) => Future.value(testNotes)),
            dirtyCountProvider.overrideWith((ref) => Future.value(0)),
          ],
          child: const MaterialApp(home: Scaffold(body: NotesPage())),
        ),
      );

      // Selesaikan rendering awal
      await tester.pumpAndSettle();

      // Catatan awal tampil
      expect(find.text('Catatan Kuliah'), findsOneWidget);

      // Ketik kata kunci yang tidak ada
      await tester.enterText(find.byType(TextField).first, 'resep makanan');
      await tester.pumpAndSettle();

      // Catatan lama tersembunyi
      expect(find.text('Catatan Kuliah'), findsNothing);

      // Empty state pencarian muncul
      expect(
        find.text('Tidak ada catatan yang cocok dengan "resep makanan"'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);

      // Tekan tombol clear (Icons.clear)
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Catatan kembali tampil
      expect(find.text('Catatan Kuliah'), findsOneWidget);
    });

    testWidgets(
      'menampilkan empty state default saat belum ada catatan sama sekali',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              notesProvider.overrideWith((ref) => Future.value([])),
              dirtyCountProvider.overrideWith((ref) => Future.value(0)),
            ],
            child: const MaterialApp(home: Scaffold(body: NotesPage())),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Belum ada catatan. Tambahkan satu.'), findsOneWidget);
      },
    );
  });
}
