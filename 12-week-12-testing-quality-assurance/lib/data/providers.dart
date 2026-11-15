import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local/note.dart';
import 'local/post.dart';
import 'repositories/note_repository.dart';
import 'repositories/post_repository.dart';
import 'services/note_sync.dart';
import '../domain/search_notes_use_case.dart';
import '../ai/ai_service.dart';

final forceOfflineProvider = NotifierProvider<ForceOfflineNotifier, bool>(
  ForceOfflineNotifier.new,
);

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

final aiServiceProvider = Provider<AiService>((ref) => AiService());

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(ref.watch(dioProvider)),
);

final notesProvider = FutureProvider<List<Note>>(
  (ref) => ref.watch(noteRepositoryProvider).fetchNotes(),
);

final searchNotesUseCaseProvider = Provider<SearchNotesUseCase>((ref) {
  return const SearchNotesUseCase();
});

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
  void clear() => state = '';
}

final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notesAsync = ref.watch(notesProvider);
  final query = ref.watch(searchQueryProvider);
  final useCase = ref.watch(searchNotesUseCaseProvider);

  return notesAsync.whenData((notes) => useCase.execute(notes, query));
});

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
      _ref
          .read(postsRefreshMessageProvider.notifier)
          .setMessage('Mode offline aktif. Menampilkan cache lokal.');
      return;
    }

    _refreshing = true;
    _ref
        .read(postsRefreshMessageProvider.notifier)
        .setMessage('Memperbarui data dari jaringan...');
    try {
      final repository = _ref.read(postRepositoryProvider);
      final posts = await repository.fetchPosts();
      await repository.cachePosts(posts);
      _ref.invalidate(cachedPostsProvider);
      _ref
          .read(postsRefreshMessageProvider.notifier)
          .setMessage('Data berhasil diperbarui dari jaringan.');
    } catch (error) {
      _ref
          .read(postsRefreshMessageProvider.notifier)
          .setMessage('Refresh gagal: $error');
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

// ---------------------------------------------------------------------------
// Week 11 Performance Optimization: Granular Pagination State & Notifier
// ---------------------------------------------------------------------------

class PaginatedPostsState {
  const PaginatedPostsState({
    required this.items,
    this.page = 1,
    this.isLoading = false,
    this.hasMore = true,
    this.errorMessage,
  });

  final List<Post> items;
  final int page;
  final bool isLoading;
  final bool hasMore;
  final String? errorMessage;

  PaginatedPostsState copyWith({
    List<Post>? items,
    int? page,
    bool? isLoading,
    bool? hasMore,
    String? errorMessage,
  }) {
    return PaginatedPostsState(
      items: items ?? this.items,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }
}

final paginatedPostsProvider =
    NotifierProvider<PaginatedPostsNotifier, PaginatedPostsState>(
      PaginatedPostsNotifier.new,
    );

class PaginatedPostsNotifier extends Notifier<PaginatedPostsState> {
  static const int pageSize = 10;

  @override
  PaginatedPostsState build() {
    return const PaginatedPostsState(items: []);
  }

  /// Stale-While-Revalidate: tampilkan cache lokal segera, lalu ambil data baru dari jaringan
  Future<void> init() async {
    final repo = ref.read(postRepositoryProvider);
    final cached = await repo.readCachedPosts(limit: pageSize);
    if (cached.isNotEmpty && state.items.isEmpty) {
      state = state.copyWith(items: cached, page: 1, hasMore: true);
    }
    await loadPage(1, isRefresh: true);
  }

  Future<void> loadPage(int page, {bool isRefresh = false}) async {
    if (state.isLoading && !isRefresh) return;
    if (!state.hasMore && !isRefresh) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    final isOffline = ref.read(forceOfflineProvider);
    if (isOffline) {
      final repo = ref.read(postRepositoryProvider);
      final localItems = await repo.readCachedPosts(
        limit: pageSize,
        offset: (page - 1) * pageSize,
      );
      final newItems = isRefresh ? localItems : [...state.items, ...localItems];
      state = state.copyWith(
        items: newItems,
        page: page,
        isLoading: false,
        hasMore: localItems.length >= pageSize,
      );
      return;
    }

    try {
      final repo = ref.read(postRepositoryProvider);
      final fresh = await repo.fetchPostsPaged(page: page, limit: pageSize);
      if (fresh.isEmpty) {
        state = state.copyWith(isLoading: false, hasMore: false);
      } else {
        final newItems = isRefresh ? fresh : [...state.items, ...fresh];
        state = state.copyWith(
          items: newItems,
          page: page,
          isLoading: false,
          hasMore: fresh.length >= pageSize,
        );
        unawaited(repo.appendCachedPosts(fresh));
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat halaman: $e',
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;
    await loadPage(state.page + 1);
  }

  Future<void> refresh() async {
    await loadPage(1, isRefresh: true);
  }
}
