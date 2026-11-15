import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/providers.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/pages/notes_page.dart';

class FakeNoteRepository extends NoteRepository {
  FakeNoteRepository({List<Note>? initialNotes})
    : _notes = List.of(initialNotes ?? []),
      super(openDb: () => throw UnimplementedError());

  final List<Note> _notes;

  @override
  Future<List<Note>> fetchNotes() async {
    return List.unmodifiable(_notes);
  }

  @override
  Future<Note> addNote({required String title, String body = ''}) async {
    final newId = _notes.length + 1;
    final note = Note(
      id: newId,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    _notes.add(note);
    return note;
  }

  @override
  Future<int> countDirty() async {
    return _notes.where((n) => n.dirty).length;
  }
}

void main() {
  Widget createTestWidget(FakeNoteRepository fakeRepo) {
    return ProviderScope(
      overrides: [noteRepositoryProvider.overrideWithValue(fakeRepo)],
      child: const MaterialApp(home: Scaffold(body: NotesPage())),
    );
  }

  group('NotesPage Widget Tests (UI & Interaksi Pengguna)', () {
    testWidgets(
      'menampilkan tombol tambah catatan dan input pencarian saat awal',
      (tester) async {
        // Arrange
        final fakeRepo = FakeNoteRepository(initialNotes: []);

        // Act
        await tester.pumpWidget(createTestWidget(fakeRepo));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byKey(const Key('add-note-button')), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget); // search field
        expect(find.text('Belum ada catatan. Tambahkan satu.'), findsOneWidget);
      },
    );

    testWidgets('menampilkan dialog tambah catatan saat tombol ditekan', (
      tester,
    ) async {
      // Arrange
      final fakeRepo = FakeNoteRepository(initialNotes: []);
      await tester.pumpWidget(createTestWidget(fakeRepo));
      await tester.pumpAndSettle();

      // Act: Tap tombol tambah catatan
      await tester.tap(find.byKey(const Key('add-note-button')));
      await tester.pumpAndSettle();

      // Assert: Dialog muncul dengan title & field
      expect(find.text('Catatan baru'), findsOneWidget);
      expect(find.byKey(const Key('note-title-field')), findsOneWidget);
      expect(find.byKey(const Key('note-body-field')), findsOneWidget);
      expect(find.byKey(const Key('save-note-button')), findsOneWidget);
      expect(find.byKey(const Key('cancel-note-button')), findsOneWidget);
    });

    testWidgets('berhasil menambah catatan baru melalui dialog input form', (
      tester,
    ) async {
      // Arrange
      final fakeRepo = FakeNoteRepository(initialNotes: []);
      await tester.pumpWidget(createTestWidget(fakeRepo));
      await tester.pumpAndSettle();

      // Act: Buka dialog
      await tester.tap(find.byKey(const Key('add-note-button')));
      await tester.pumpAndSettle();

      // Act: Masukkan teks judul dan isi
      await tester.enterText(
        find.byKey(const Key('note-title-field')),
        'Catatan Kuliah Mobile',
      );
      await tester.enterText(
        find.byKey(const Key('note-body-field')),
        'Pembahasan Widget Testing',
      );

      // Act: Tekan tombol Simpan
      await tester.tap(find.byKey(const Key('save-note-button')));
      await tester.pumpAndSettle();

      // Assert: Dialog tertutup dan catatan baru muncul di list
      expect(find.text('Catatan baru'), findsNothing);
      expect(find.text('Catatan Kuliah Mobile'), findsOneWidget);
      expect(find.text('Pembahasan Widget Testing'), findsOneWidget);
    });

    testWidgets(
      'menutup dialog tanpa menambah data saat tombol Batal ditekan',
      (tester) async {
        // Arrange
        final fakeRepo = FakeNoteRepository(initialNotes: []);
        await tester.pumpWidget(createTestWidget(fakeRepo));
        await tester.pumpAndSettle();

        // Act: Buka dialog
        await tester.tap(find.byKey(const Key('add-note-button')));
        await tester.pumpAndSettle();

        // Act: Tekan Batal
        await tester.tap(find.byKey(const Key('cancel-note-button')));
        await tester.pumpAndSettle();

        // Assert: Dialog tertutup dan tetap empty state
        expect(find.text('Catatan baru'), findsNothing);
        expect(find.text('Belum ada catatan. Tambahkan satu.'), findsOneWidget);
      },
    );
  });
}
