import '../repositories/note_repository.dart';

Future<int> syncNotes(
  NoteRepository repo, {
  required bool forceOffline,
  Duration delay = const Duration(seconds: 1),
}) async {
  if (forceOffline) {
    throw StateError('Sinkronisasi tidak tersedia saat mode offline aktif.');
  }

  final dirtyNotes = await repo.fetchDirty();
  if (dirtyNotes.isEmpty) return 0;

  await Future<void>.delayed(delay);
  return repo.markSynced(dirtyNotes);
}
