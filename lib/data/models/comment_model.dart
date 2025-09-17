// data/models/comment_model.dart
class CommentModel {
  final String id;
  final String userId;
  final String reportId;
  final String content;
  final DateTime createdAt;
  final UserModel? author;

  CommentModel({
    required this.id,
    required this.userId,
    required this.reportId,
    required this.content,
    required this.createdAt,
    this.author,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      userId: json['userId'],
      reportId: json['reportId'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      author: json['author'] != null
          ? UserModel.fromJson(json['author'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'reportId': reportId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'author': author?.toJson(),
    };
  }
}

// Extension for String capitalization
extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
