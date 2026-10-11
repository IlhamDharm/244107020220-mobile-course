import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/providers.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';

class FakeNoteRepository extends NoteRepository {
  FakeNoteRepository({this.items = const [], this.throwError = false})
    : super(openDb: () => throw UnimplementedError());

  final List<Note> items;
  final bool throwError;

  @override
  Future<List<Note>> fetchNotes() async {
    if (throwError) throw Exception('db locked (simulasi)');
    return items;
  }

  @override
  Future<int> countDirty() =>
      Future.value(items.where((note) => note.dirty).length);
}

void main() {
  test('fromMap handles missing and null fields safely', () {
    final note = Note.fromMap({
      'title': 'Belanja',
      'body': null,
      'dirty': null,
    });

    expect(note.title, 'Belanja');
    expect(note.body, '');
    expect(note.dirty, isFalse);
    expect(note.updatedAt, DateTime.fromMillisecondsSinceEpoch(0));
  });

  test('dirty flag survives serialization', () {
    final note = Note(
      title: 'a',
      updatedAt: DateTime(2026, 9, 18),
      dirty: true,
    );

    final restored = Note.fromMap(note.toMap());

    expect(restored.dirty, isTrue);
  });

  test('notes provider succeeds with a fake repository', () async {
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(
            items: [Note(title: 'Tes', updatedAt: DateTime.now())],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notes = await container.read(notesProvider.future);

    expect(notes, hasLength(1));
    expect(notes.first.title, 'Tes');
  });

  test('notes provider forwards repository errors', () async {
    final providerError = Completer<Object>();
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(throwError: true),
        ),
      ],
    );
    final subscription = container.listen(notesProvider, (_, state) {
      if (state.hasError && !providerError.isCompleted) {
        providerError.complete(state.error!);
      }
    });
    addTearDown(() {
      subscription.close();
      container.dispose();
    });

    expect(await providerError.future, isA<Exception>());
  });
}
