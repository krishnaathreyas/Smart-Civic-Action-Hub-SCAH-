// data/models/report_model.dart
import 'user_model.dart';

class ReportModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String status;
  final double latitude;
  final double longitude;
  final String address;
  final List<String> imageUrls;
  final String? videoUrl;
  final int upvotes;
  final int downvotes;
  final double weightedScore;
  final bool isUrgent;
  final bool isInGracePeriod;
  final DateTime gracePeriodEnds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserModel? reporter;

  ReportModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    this.status = 'submitted',
    required this.latitude,
    required this.longitude,
    required this.address,
    this.imageUrls = const [],
    this.videoUrl,
    this.upvotes = 0,
    this.downvotes = 0,
    this.weightedScore = 0.0,
    this.isUrgent = false,
    this.isInGracePeriod = true,
    required this.gracePeriodEnds,
    required this.createdAt,
    required this.updatedAt,
    this.reporter,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      status: json['status'] ?? 'submitted',
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      address: json['address'],
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      videoUrl: json['videoUrl'],
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      weightedScore: (json['weightedScore'] ?? 0.0).toDouble(),
      isUrgent: json['isUrgent'] ?? false,
      isInGracePeriod: json['isInGracePeriod'] ?? true,
      gracePeriodEnds: DateTime.parse(json['gracePeriodEnds']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      reporter: json['reporter'] != null
          ? UserModel.fromJson(json['reporter'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'weightedScore': weightedScore,
      'isUrgent': isUrgent,
      'isInGracePeriod': isInGracePeriod,
      'gracePeriodEnds': gracePeriodEnds.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'reporter': reporter?.toJson(),
    };
  }

  bool get canVote => !isInGracePeriod;

  String get displayStatus {
    if (isInGracePeriod) return 'Under Review';
    return status
        .split('_')
        .map(
          (word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }
}

// String extension for capitalize functionality
extension StringExtension on String {
  String capitalize() {
    return isEmpty ? '' : this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
