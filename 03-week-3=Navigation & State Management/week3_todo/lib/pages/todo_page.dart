import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_tile.dart';

class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(filteredTodoListProvider);
    final activeFilter = ref.watch(todoFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDo Riverpod'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SegmentedButton(
              segments: const [
                ButtonSegment(
                  value: TodoFilter.all,
                  label: Text('Semua'),
                ),
                ButtonSegment(
                  value: TodoFilter.active,
                  label: Text('Aktif'),
                ),
                ButtonSegment(
                  value: TodoFilter.completed,
                  label: Text('Selesai'),
                ),
              ],
              selected: {activeFilter},
              onSelectionChanged: (newSelection) {
                ref
                    .read(todoFilterProvider.notifier)
                    .setFilter(newSelection.first);
              },
            ),
          ),
          Expanded(
            child: todos.isEmpty
                ? const Center(child: Text('Belum ada tugas'))
                : ListView.builder(
                    itemCount: todos.length,
                    itemBuilder: (context, index) => TodoTile(
                      index: index,
                      todo: todos[index],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tugas baru'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nama tugas...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                ref.read(todoListProvider.notifier).add(text);
              }
              Navigator.pop(context);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }
}