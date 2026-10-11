import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/note.dart';
import '../data/providers.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    final dirtyCount = ref.watch(dirtyCountProvider);
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: ListTile(
            leading: const Icon(Icons.sync_problem),
            title: const Text('Catatan belum tersinkron'),
            trailing: Chip(
              label: Text('${dirtyCount.value ?? 0}'),
              avatar: const Icon(Icons.cloud_upload_outlined, size: 18),
            ),
          ),
        ),
        Expanded(
          child: notes.when(
            data: (items) => items.isEmpty
                ? const Center(child: Text('Belum ada catatan. Tambahkan satu.'))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) =>
                        _NoteTile(note: items[index]),
                  ),
            error: (error, _) => Center(
              child: Text('Gagal memuat catatan lokal: $error'),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _addNote(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Tambah catatan'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final note = await showDialog<Note>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Catatan baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Judul'),
            ),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: 'Isi (opsional)'),
              minLines: 1,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(
                context,
                Note(
                  title: title,
                  body: bodyController.text.trim(),
                  updatedAt: DateTime.now(),
                  dirty: true,
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    titleController.dispose();
    bodyController.dispose();
    if (note == null) return;
    await ref.read(noteRepositoryProvider).addNote(
          title: note.title,
          body: note.body,
        );
    ref.invalidate(notesProvider);
    ref.invalidate(dirtyCountProvider);
  }
}

class _NoteTile extends ConsumerWidget {
  const _NoteTile({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(
        note.dirty ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
        color: note.dirty ? Colors.orange : Colors.green,
      ),
      title: Text(note.title),
      subtitle: Text(
        note.body.isEmpty ? 'Diperbarui ${_format(note.updatedAt)}' : note.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: note.dirty
          ? const Chip(label: Text('Dirty'))
          : const Chip(label: Text('Tersinkron')),
      onLongPress: () async {
        final id = note.id;
        if (id == null) return;
        await ref.read(noteRepositoryProvider).deleteNote(id);
        ref.invalidate(notesProvider);
        ref.invalidate(dirtyCountProvider);
      },
    );
  }

  String _format(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
