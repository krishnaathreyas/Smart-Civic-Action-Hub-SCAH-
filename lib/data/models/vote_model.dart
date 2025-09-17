// data/models/vote_model.dart
class VoteModel {
  final String id;
  final String userId;
  final String reportId;
  final bool isUpvote;
  final double weight;
  final DateTime createdAt;
  final String? reason; // For downvotes

  VoteModel({
    required this.id,
    required this.userId,
    required this.reportId,
    required this.isUpvote,
    required this.weight,
    required this.createdAt,
    this.reason,
  });

  factory VoteModel.fromJson(Map<String, dynamic> json) {
    return VoteModel(
      id: json['id'],
      userId: json['userId'],
      reportId: json['reportId'],
      isUpvote: json['isUpvote'],
      weight: json['weight'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'reportId': reportId,
      'isUpvote': isUpvote,
      'weight': weight,
      'createdAt': createdAt.toIso8601String(),
      'reason': reason,
    };
  }
}
