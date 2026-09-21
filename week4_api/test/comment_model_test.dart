import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/comment.dart';

void main() {
  group('Comment Model Unit Tests', () {
    test('fromJson menghasilkan default value jika ada field yang hilang / null', () {
      final Map<String, dynamic> partialJson = {
        'postId': 1,
        'id': 101,
        // name, email, dan body sengaja dihilangkan (missing)
      };

      final comment = Comment.fromJson(partialJson);

      expect(comment.postId, 1);
      expect(comment.id, 101);
      expect(comment.name, '');
      expect(comment.email, '');
      expect(comment.body, '');
    });

    test('Edge Case: fromJson menangani ID berupa string angka dan data bernilai null eksplisit', () {
      final Map<String, dynamic> dirtyJson = {
        'postId': '5', // Dikirim sebagai String bukan int
        'id': null,
        'name': null,
        'email': 'user@example.com',
        'body': null,
      };

      final comment = Comment.fromJson(dirtyJson);

      expect(comment.postId, 5); // Berhasil diparse ke int
      expect(comment.id, 0); // Null menjadi 0
      expect(comment.name, '');
      expect(comment.email, 'user@example.com');
      expect(comment.body, '');
    });
  });
}