import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import '../local/db.dart';
import '../local/post.dart';

class PostRepository {
  PostRepository(this._dio, {Future<Database> Function()? openDb})
    : _openDb = openDb ?? openNotesDb;

  final Dio _dio;
  final Future<Database> Function() _openDb;

  /// Fetch all posts from the API (backward compatibility).
  Future<List<Post>> fetchPosts() async {
    final response = await _dio.get<List<dynamic>>('/posts');
    return (response.data ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Post.fromJson)
        .toList();
  }

  /// Fetch posts with pagination parameters (_page & _limit) for lazy loading.
  Future<List<Post>> fetchPostsPaged({int page = 1, int limit = 10}) async {
    final response = await _dio.get<List<dynamic>>(
      '/posts',
      queryParameters: {'_page': page, '_limit': limit},
    );
    return (response.data ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Post.fromJson)
        .toList();
  }

  /// Read cached posts from local SQLite with optional pagination.
  Future<List<Post>> readCachedPosts({int? limit, int? offset}) async {
    final db = await _openDb();
    final rows = await db.query(
      'cached_posts',
      orderBy: 'id ASC',
      limit: limit,
      offset: offset,
    );
    return rows
        .map(
          (row) => Post.fromJson(
            jsonDecode(row['payload']! as String) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// Replace entire cached posts table.
  Future<void> cachePosts(List<Post> posts) async {
    final db = await _openDb();
    await db.transaction((txn) async {
      final batch = txn.batch();
      batch.delete('cached_posts');
      final cachedAt = DateTime.now().toIso8601String();
      for (final post in posts) {
        batch.insert('cached_posts', {
          'id': post.id,
          'payload': jsonEncode(post.toJson()),
          'cached_at': cachedAt,
        });
      }
      await batch.commit(noResult: true);
    });
  }

  /// Append or update cached posts without deleting existing ones (incremental caching).
  Future<void> appendCachedPosts(List<Post> posts) async {
    final db = await _openDb();
    await db.transaction((txn) async {
      final batch = txn.batch();
      final cachedAt = DateTime.now().toIso8601String();
      for (final post in posts) {
        batch.insert('cached_posts', {
          'id': post.id,
          'payload': jsonEncode(post.toJson()),
          'cached_at': cachedAt,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }
}
