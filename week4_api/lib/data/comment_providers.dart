import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart'; // Menggunakan dioProvider yang sudah dibuat sebelumnya
import 'models/comment.dart';
import 'repositories/comment_repository.dart';

/// Provider instance CommentRepository
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository(ref.watch(dioProvider));
});

/// AsyncNotifier dengan parameter (family) untuk postId
/// Provider komentar berdasarkan postId
final commentsProvider = FutureProvider.family<List<Comment>, int>((ref, postId) async {
  final repository = ref.watch(commentRepositoryProvider);
  return repository.fetchComments(postId);
});

/// Helper pemetaan exception jaringan ke pesan ramah pengguna
String commentFriendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Server memakan waktu terlalu lama merespons.';
      case DioExceptionType.connectionError:
        return 'Tidak ada koneksi internet. Periksa jaringan Anda.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) {
          return 'Komentar tidak ditemukan (404).';
        }
        if (statusCode == 500) {
          return 'Terjadi gangguan pada internal server (500).';
        }
        return 'Server bermasalah dengan kode: $statusCode';
      default:
        return 'Terjadi masalah pada jaringan. Silakan coba lagi.';
    }
  }
  return 'Terjadi kesalahan sistem: $error';
}