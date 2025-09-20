// data/models/evidence_model.dart
class EvidenceModel {
  final String id;
  final String reportId;
  final String userId;
  final String? reason;
  final String? imageBase64; // Stored as base64 for cross-platform ease
  final bool markedAsFake;
  final DateTime createdAt;

  EvidenceModel({
    required this.id,
    required this.reportId,
    required this.userId,
    this.reason,
    this.imageBase64,
    this.markedAsFake = false,
    required this.createdAt,
  });

  factory EvidenceModel.fromJson(Map<String, dynamic> json) => EvidenceModel(
    id: json['id'] as String,
    reportId: json['reportId'] as String,
    userId: json['userId'] as String,
    reason: json['reason'] as String?,
    imageBase64: json['imageBase64'] as String?,
    markedAsFake: json['markedAsFake'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'reportId': reportId,
    'userId': userId,
    'reason': reason,
    'imageBase64': imageBase64,
    'markedAsFake': markedAsFake,
    'createdAt': createdAt.toIso8601String(),
  };
}
