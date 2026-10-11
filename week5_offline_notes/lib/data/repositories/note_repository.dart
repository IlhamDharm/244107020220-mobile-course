import 'package:sqflite/sqflite.dart';
import '../local/db.dart';
import '../local/note.dart';

class NoteRepository {
  NoteRepository({Future<Database> Function()? openDb})
      : _openDb = openDb ?? openNotesDb;

  final Future<Database> Function() _openDb;

  Future<List<Note>> fetchNotes() async {
    final db = await _openDb();
    final rows = await db.query('notes', orderBy: 'updated_at DESC');
    return rows.map(Note.fromMap).toList();
  }

  Future<Note> addNote({required String title, String body = ''}) async {
    final db = await _openDb();
    final note = Note(
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    final id = await db.insert('notes', note.toMap());
    return Note(
      id: id,
      title: note.title,
      body: note.body,
      updatedAt: note.updatedAt,
      dirty: true,
    );
  }

  Future<List<Note>> fetchDirty() async {
    final db = await _openDb();
    final rows = await db.query(
      'notes',
      where: 'dirty = 1',
      orderBy: 'updated_at ASC',
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<void> deleteNote(int id) async {
    final db = await _openDb();
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> markSynced(List<Note> uploadedNotes) async {
    final db = await _openDb();
    var syncedCount = 0;
    await db.transaction((txn) async {
      for (final note in uploadedNotes) {
        final id = note.id;
        if (id == null) continue;
        syncedCount += await txn.update(
          'notes',
          {'dirty': 0},
          where: 'id = ? AND dirty = 1 AND updated_at = ?',
          whereArgs: [id, note.updatedAt.toIso8601String()],
        );
      }
    });
    return syncedCount;
  }

  Future<int> countDirty() async {
    final db = await _openDb();
    final rows = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM notes WHERE dirty = 1');
    return ((rows.first['c'] as num?)?.toInt() ?? 0);
  }

}