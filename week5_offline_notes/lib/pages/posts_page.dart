import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';

class PostsPage extends ConsumerStatefulWidget {
  const PostsPage({super.key});

  @override
  ConsumerState<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends ConsumerState<PostsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) cacheFirstPosts(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(cachedPostsProvider);
    final message = ref.watch(postsRefreshMessageProvider);
    final offline = ref.watch(forceOfflineProvider);
    return Column(
      children: [
        if (offline)
          const MaterialBanner(
            content: Text('Mode offline aktif - menampilkan data lokal.'),
            leading: Icon(Icons.wifi_off),
            actions: [SizedBox.shrink()],
          ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),
        Expanded(
          child: posts.when(
            data: (items) => items.isEmpty
                ? const Center(
                    child: Text('Cache kosong. Periksa koneksi untuk memuat API.'),
                  )
                : RefreshIndicator(
                    onRefresh: () => ref
                        .read(postsRefreshControllerProvider)
                        .refreshInBackground(),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final post = items[index];
                        return ListTile(
                          leading: CircleAvatar(child: Text('${post.id}')),
                          title: Text(post.title),
                          subtitle: Text(
                            post.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
            error: (error, _) => Center(
              child: Text('Gagal membaca cache lokal: $error'),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }
}
