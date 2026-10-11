import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local/note.dart';
import 'local/post.dart';
import 'repositories/note_repository.dart';
import 'repositories/post_repository.dart';
import 'services/note_sync.dart';

final forceOfflineProvider =
    NotifierProvider<ForceOfflineNotifier, bool>(ForceOfflineNotifier.new);

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setOffline(bool value) => state = value;
}

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  );
});

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepository(),
);

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(ref.watch(dioProvider)),
);

final notesProvider = FutureProvider<List<Note>>(
  (ref) => ref.watch(noteRepositoryProvider).fetchNotes(),
);

final dirtyCountProvider = FutureProvider<int>(
  (ref) => ref.watch(noteRepositoryProvider).countDirty(),
);

final cachedPostsProvider = FutureProvider<List<Post>>(
  (ref) => ref.watch(postRepositoryProvider).readCachedPosts(),
);

final postsRefreshMessageProvider =
    NotifierProvider<PostsRefreshMessageNotifier, String?>(
  PostsRefreshMessageNotifier.new,
);

class PostsRefreshMessageNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setMessage(String? message) => state = message;
}

final postsRefreshControllerProvider = Provider<PostsRefreshController>(
  (ref) => PostsRefreshController(ref),
);

class PostsRefreshController {
  PostsRefreshController(this._ref);
  final Ref _ref;
  bool _refreshing = false;

  Future<void> refreshInBackground() async {
    if (_refreshing) return;
    if (_ref.read(forceOfflineProvider)) {
      _ref.read(postsRefreshMessageProvider.notifier).setMessage(
            'Mode offline aktif. Menampilkan cache lokal.',
          );
      return;
    }

    _refreshing = true;
    _ref.read(postsRefreshMessageProvider.notifier).setMessage(
          'Memperbarui data dari jaringan...',
        );
    try {
      final repository = _ref.read(postRepositoryProvider);
      final posts = await repository.fetchPosts();
      await repository.cachePosts(posts);
      _ref.invalidate(cachedPostsProvider);
      _ref.read(postsRefreshMessageProvider.notifier).setMessage(
            'Data berhasil diperbarui dari jaringan.',
          );
    } catch (error) {
      _ref.read(postsRefreshMessageProvider.notifier).setMessage(
            'Refresh gagal: $error',
          );
    } finally {
      _refreshing = false;
    }
  }
}

final noteSyncControllerProvider = Provider<NoteSyncController>(
  (ref) => NoteSyncController(ref),
);

class NoteSyncController {
  NoteSyncController(this._ref);
  final Ref _ref;

  Future<int> sync() async {
    final count = await syncNotes(
      _ref.read(noteRepositoryProvider),
      forceOffline: _ref.read(forceOfflineProvider),
    );
    _ref.invalidate(notesProvider);
    _ref.invalidate(dirtyCountProvider);
    return count;
  }
}

void cacheFirstPosts(WidgetRef ref) {
  unawaited(ref.read(postsRefreshControllerProvider).refreshInBackground());
}
