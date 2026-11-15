import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/note.dart';
import '../data/providers.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(searchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(filteredNotesProvider);
    final currentQuery = ref.watch(searchQueryProvider);

    // Keep text controller in sync if query cleared externally
    if (_searchController.text != currentQuery) {
      _searchController.text = currentQuery;
    }

    return Column(
      children: [
        // Granular watch: only rebuilds the banner when dirty count changes
        const _SyncStatusBanner(),
        _SearchBar(
          controller: _searchController,
          onChanged: (val) =>
              ref.read(searchQueryProvider.notifier).setQuery(val),
          onClear: () {
            _searchController.clear();
            ref.read(searchQueryProvider.notifier).clear();
          },
        ),
        Expanded(
          child: notes.when(
            data: (items) => items.isEmpty
                ? _EmptyView(query: currentQuery)
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) =>
                        _NoteTile(note: items[index]),
                  ),
            error: (error, _) =>
                Center(child: Text('Gagal memuat catatan lokal: $error')),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _addNote(context),
              icon: const Icon(Icons.add),
              label: const Text('Tambah catatan'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addNote(BuildContext context) async {
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
    if (note == null || !mounted) return;

    await ref
        .read(noteRepositoryProvider)
        .addNote(title: note.title, body: note.body);
    ref.invalidate(notesProvider);
    ref.invalidate(dirtyCountProvider);
  }
}

/// Extracted banner with Riverpod .select to isolate rebuilds
class _SyncStatusBanner extends ConsumerWidget {
  const _SyncStatusBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      dirtyCountProvider.select((asyncVal) => asyncVal.value ?? 0),
    );

    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: ListTile(
        leading: const Icon(Icons.sync_problem),
        title: const Text('Catatan belum tersinkron'),
        trailing: Chip(
          label: Text('$count'),
          avatar: const Icon(Icons.cloud_upload_outlined, size: 18),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Cari catatan...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                  tooltip: 'Hapus pencarian',
                )
              : null,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(child: Text('Belum ada catatan. Tambahkan satu.'));
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'Tidak ada catatan yang cocok dengan "$query"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extracted note tile with RepaintBoundary for isolated raster painting
class _NoteTile extends ConsumerWidget {
  const _NoteTile({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RepaintBoundary(
      child: ListTile(
        leading: Icon(
          note.dirty ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
          color: note.dirty ? Colors.orange : Colors.green,
        ),
        title: Text(note.title),
        subtitle: Text(
          note.body.isEmpty
              ? 'Diperbarui ${_format(note.updatedAt)}'
              : note.body,
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
      ),
    );
  }

  String _format(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
