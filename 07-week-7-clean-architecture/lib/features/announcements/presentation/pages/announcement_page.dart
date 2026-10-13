import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format.dart';
import '../providers/announcement_providers.dart';

class AnnouncementPage extends ConsumerWidget {
  const AnnouncementPage({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(announcementDetailProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('Detail pengumuman')),
      body: Center(
        child: state.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, stackTrace) => Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text('$error', textAlign: TextAlign.center),
            ),
          ),
          data: (announcement) => Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.campaign, size: 44),
                  const SizedBox(height: 12),
                  Text(
                    'Pengumuman #${announcement.id}',
                    key: const Key('announcement-detail'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    announcement.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(announcement.body, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(
                    'Diperbarui ${compactDateTime(announcement.updatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
