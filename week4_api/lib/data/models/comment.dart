class Comment {
  final int postId;
  final int id;
  final String name;
  final String email;
  final String body;

  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  /// Factory fromJson aman null:
  /// Menggunakan fallback default value jika key tidak ditemukan atau bernilai null.
  factory Comment.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const Comment(
        postId: 0,
        id: 0,
        name: '',
        email: '',
        body: '',
      );
    }

    return Comment(
      postId: json['postId'] is int
          ? json['postId'] as int
          : int.tryParse(json['postId']?.toString() ?? '') ?? 0,
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'postId': postId,
        'id': id,
        'name': name,
        'email': email,
        'body': body,
      };
}