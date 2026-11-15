import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week5_offline_notes/data/local/post.dart';
import 'package:week5_offline_notes/data/providers.dart';
import 'package:week5_offline_notes/data/repositories/post_repository.dart';

class FakeOfflineNotifier extends ForceOfflineNotifier {
  @override
  bool build() => true;
}

class FakePostRepository extends PostRepository {
  FakePostRepository({List<Post>? initial})
    : _cachedItems = List.of(initial ?? []),
      super(Dio(), openDb: () => throw UnimplementedError());

  final List<Post> _cachedItems;

  @override
  Future<List<Post>> readCachedPosts({int? limit, int? offset}) async {
    var result = List<Post>.from(_cachedItems);
    if (offset != null) {
      if (offset >= result.length) return [];
      result = result.sublist(offset);
    }
    if (limit != null && limit < result.length) {
      result = result.sublist(0, limit);
    }
    return result;
  }

  @override
  Future<void> appendCachedPosts(List<Post> posts) async {
    for (final post in posts) {
      final index = _cachedItems.indexWhere((p) => p.id == post.id);
      if (index >= 0) {
        _cachedItems[index] = post;
      } else {
        _cachedItems.add(post);
      }
    }
  }

  @override
  Future<List<Post>> fetchPostsPaged({int page = 1, int limit = 10}) async {
    return readCachedPosts(limit: limit, offset: (page - 1) * limit);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Week 11 Performance Optimization Tests', () {
    late FakePostRepository postRepo;

    setUp(() {
      postRepo = FakePostRepository();
    });

    test('appendCachedPosts() menyimpan data incremental tanpa menghapus yang lama', () async {
      final initialPosts = [
        Post(id: 1, userId: 1, title: 'Post 1', body: 'Body 1'),
        Post(id: 2, userId: 1, title: 'Post 2', body: 'Body 2'),
      ];
      await postRepo.appendCachedPosts(initialPosts);

      var cached = await postRepo.readCachedPosts();
      expect(cached.length, 2);

      final nextPosts = [
        Post(id: 3, userId: 1, title: 'Post 3', body: 'Body 3'),
        Post(id: 4, userId: 1, title: 'Post 4', body: 'Body 4'),
      ];
      await postRepo.appendCachedPosts(nextPosts);

      cached = await postRepo.readCachedPosts();
      expect(cached.length, 4);
      expect(cached.map((p) => p.id).toList(), [1, 2, 3, 4]);
    });

    test(
      'readCachedPosts() mendukung parameter pagination (limit & offset)',
      () async {
        final posts = List.generate(
          15,
          (i) => Post(
            id: i + 1,
            userId: 1,
            title: 'Post ${i + 1}',
            body: 'Body ${i + 1}',
          ),
        );
        await postRepo.appendCachedPosts(posts);

        final page1 = await postRepo.readCachedPosts(limit: 5, offset: 0);
        expect(page1.length, 5);
        expect(page1.first.id, 1);
        expect(page1.last.id, 5);

        final page2 = await postRepo.readCachedPosts(limit: 5, offset: 5);
        expect(page2.length, 5);
        expect(page2.first.id, 6);
        expect(page2.last.id, 10);
      },
    );

    test('PaginatedPostsState copyWith mempertahankan immutability', () {
      const initial = PaginatedPostsState(items: []);
      expect(initial.page, 1);
      expect(initial.isLoading, false);
      expect(initial.hasMore, true);

      final updated = initial.copyWith(
        items: [Post(id: 1, userId: 1, title: 'A', body: 'B')],
        page: 2,
        isLoading: true,
      );

      expect(updated.items.length, 1);
      expect(updated.page, 2);
      expect(updated.isLoading, true);
      expect(initial.items.isEmpty, true);
    });

    test(
      'PaginatedPostsNotifier mengelola transisi pagination dengan benar',
      () async {
        final container = ProviderContainer(
          overrides: [
            postRepositoryProvider.overrideWithValue(postRepo),
            forceOfflineProvider.overrideWith(FakeOfflineNotifier.new),
          ],
        );
        addTearDown(container.dispose);

        final seedPosts = List.generate(
          15,
          (i) => Post(
            id: i + 1,
            userId: 1,
            title: 'Title ${i + 1}',
            body: 'Body ${i + 1}',
          ),
        );
        await postRepo.appendCachedPosts(seedPosts);

        final notifier = container.read(paginatedPostsProvider.notifier);

        // Load initial (page 1, limit 10)
        await notifier.init();
        var state = container.read(paginatedPostsProvider);
        expect(state.items.length, 10);
        expect(state.page, 1);
        expect(state.hasMore, true);

        // Load next page (page 2, remaining 5 items)
        await notifier.loadNextPage();
        state = container.read(paginatedPostsProvider);
        expect(state.items.length, 15);
        expect(state.page, 2);
        expect(state.hasMore, false);
      },
    );
  });
}
