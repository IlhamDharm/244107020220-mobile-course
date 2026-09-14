import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';

// ConsumerWidget digunakan agar widget memiliki akses langsung ke objek WidgetRef
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch dipanggil di dalam build untuk berlangganan pada perubahan AsyncValue
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Aplikasi'),
      ),
      // Pattern matching when() menangani ketiga kondisi state secara lengkap
      body: statsAsync.when(
        // State 1: Loading
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        // State 2: Error (menampilkan pesan error + tombol retry)
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  // ref.invalidate mereset state dan memicu build() ulang provider
                  onPressed: () => ref.invalidate(statsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        // State 3: Success / Data
        data: (stats) => ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: stats.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) => ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}'),
            ),
            title: Text(stats[index]),
          ),
        ),
      ),
    );
  }
}