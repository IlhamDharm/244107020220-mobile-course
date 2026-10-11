import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import 'notes_page.dart';
import 'posts_page.dart';
import 'settings_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;
  static const _pages = [NotesPage(), PostsPage(), SettingsPage()];
  static const _titles = ['Catatan', 'Posts API (cache-first)', 'Pengaturan'];

  @override
  Widget build(BuildContext context) {
    final dirtyCount = ref.watch(dirtyCountProvider).value ?? 0;
    final syncing = ref.watch(noteSyncingProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              tooltip: 'Sinkronkan catatan',
              onPressed: syncing
                  ? null
                  : () async {
                      try {
                        final count = await ref.read(noteSyncingProvider.notifier).run(
                              () => ref
                                  .read(noteSyncControllerProvider)
                                  .sync(),
                            );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              count == 0
                                  ? 'Tidak ada catatan dirty untuk disinkronkan.'
                                  : '$count catatan berhasil disinkronkan.',
                            ),
                          ),
                        );
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sinkronisasi gagal: $error')),
                        );
                      }
                    },
              icon: syncing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
            ),
          if (_selectedIndex == 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Chip(
                  label: Text('$dirtyCount dirty'),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.note_alt_outlined),
            label: 'Catatan',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_download_outlined),
            label: 'Posts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}

final noteSyncingProvider =
    NotifierProvider<NoteSyncingNotifier, bool>(NoteSyncingNotifier.new);

class NoteSyncingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<T> run<T>(Future<T> Function() operation) async {
    state = true;
    try {
      return await operation();
    } finally {
      state = false;
    }
  }
}
