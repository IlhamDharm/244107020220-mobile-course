import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/local/post.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/data/services/note_sync.dart';

void main() {
  group('Post', () {
    test('parses JSONPlaceholder post fields', () {
      final post = Post.fromJson({
        'id': 7,
        'userId': 2,
        'title': 'Cached post',
        'body': 'Post body',
      });

      expect(post.id, 7);
      expect(post.userId, 2);
      expect(post.title, 'Cached post');
      expect(Post.fromJson(post.toJson()).body, 'Post body');
    });
  });

  group('syncNotes', () {
    test(
      'returns zero without waiting when there are no dirty notes',
      () async {
        final repo = _FakeNoteRepository([]);
        final stopwatch = Stopwatch()..start();

        final count = await syncNotes(
          repo,
          forceOffline: false,
          delay: const Duration(seconds: 5),
        );

        expect(count, 0);
        expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
        expect(repo.synced, isEmpty);
      },
    );

    test('marks uploaded dirty notes as synced', () async {
      final dirtyNotes = [
        Note(
          id: 1,
          title: 'Offline note',
          updatedAt: DateTime.utc(2026),
          dirty: true,
        ),
      ];
      final repo = _FakeNoteRepository(dirtyNotes);

      final count = await syncNotes(
        repo,
        forceOffline: false,
        delay: Duration.zero,
      );

      expect(count, 1);
      expect(repo.synced, dirtyNotes);
    });

    test('rejects sync while forceOffline is enabled', () async {
      final repo = _FakeNoteRepository([]);

      await expectLater(
        syncNotes(repo, forceOffline: true),
        throwsA(isA<StateError>()),
      );
    });
  });
}

class _FakeNoteRepository implements NoteRepository {
  _FakeNoteRepository(this.dirtyNotes);

  final List<Note> dirtyNotes;
  List<Note> synced = [];

  @override
  Future<int> countDirty() async => dirtyNotes.length;

  @override
  Future<List<Note>> fetchDirty() async => dirtyNotes;

  @override
  Future<List<Note>> fetchNotes() async => dirtyNotes;

  @override
  Future<Note> addNote({required String title, String body = ''}) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteNote(int id) async {}

  @override
  Future<int> markSynced(List<Note> uploadedNotes) async {
    synced = uploadedNotes;
    return synced.length;
  }
}
