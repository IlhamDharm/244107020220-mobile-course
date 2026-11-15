import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/post.dart';
import '../data/providers.dart';

class PostsPage extends ConsumerStatefulWidget {
  const PostsPage({super.key});

  @override
  ConsumerState<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends ConsumerState<PostsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(paginatedPostsProvider.notifier).init();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    // Trigger lazy loading when within 200px from the bottom
    if (currentScroll >= maxScroll - 200) {
      ref.read(paginatedPostsProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only watch items, loading, and hasMore from paginated state
    final state = ref.watch(paginatedPostsProvider);
    final items = state.items;

    return Column(
      children: [
        const _OfflineBanner(),
        const _PostsRefreshBanner(),
        Expanded(
          child: items.isEmpty && state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : items.isEmpty
              ? const Center(
                  child: Text(
                    'Tidak ada data postingan. Tarik untuk memuat ulang.',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(paginatedPostsProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length + (state.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: SizedBox.square(
                              dimension: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      return _PostTile(post: items[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

/// Extracted widget with RepaintBoundary for efficient rendering
class _PostTile extends StatelessWidget {
  const _PostTile({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ListTile(
        leading: CircleAvatar(child: Text('${post.id}')),
        title: Text(post.title),
        subtitle: Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// Granular banner listening only to forceOfflineProvider
class _OfflineBanner extends ConsumerWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(forceOfflineProvider);
    if (!offline) return const SizedBox.shrink();
    return const MaterialBanner(
      content: Text('Mode offline aktif - menampilkan data lokal.'),
      leading: Icon(Icons.wifi_off),
      actions: [SizedBox.shrink()],
    );
  }
}

/// Granular banner listening only to postsRefreshMessageProvider
class _PostsRefreshBanner extends ConsumerWidget {
  const _PostsRefreshBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(postsRefreshMessageProvider);
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Text(message, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
