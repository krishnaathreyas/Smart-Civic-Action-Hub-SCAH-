// presentation/providers/report_provider.dart
import 'package:flutter/foundation.dart';
import '../../data/models/report_model.dart';
import '../../data/models/vote_model.dart';
import '../../data/models/comment_model.dart';
import '../../core/constants/app_constants.dart';

class ReportProvider extends ChangeNotifier {
  List<ReportModel> _reports = [];
  List<VoteModel> _userVotes = [];
  bool _isLoading = false;
  String _sortBy = 'newest';
  String? _filterByCategory;

  // Getters
  List<ReportModel> get reports => _getFilteredAndSortedReports();
  bool get isLoading => _isLoading;
  String get sortBy => _sortBy;
  String? get filterByCategory => _filterByCategory;

  List<ReportModel> _getFilteredAndSortedReports() {
    var filteredReports = _reports;

    // Filter by category
    if (_filterByCategory != null && _filterByCategory!.isNotEmpty) {
      filteredReports = filteredReports
          .where((report) => report.category == _filterByCategory)
          .toList();
    }

    // Sort
    switch (_sortBy) {
      case 'newest':
        filteredReports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'trending':
        filteredReports.sort(
          (a, b) => b.weightedScore.compareTo(a.weightedScore),
        );
        break;
      case 'highest_score':
        filteredReports.sort(
          (a, b) => b.weightedScore.compareTo(a.weightedScore),
        );
        break;
    }

    return filteredReports;
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  void setFilterByCategory(String? category) {
    _filterByCategory = category;
    notifyListeners();
  }

  Future<void> loadReports() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call with mock data
      await Future.delayed(const Duration(seconds: 2));
      _reports = _generateMockReports();
    } catch (e) {
      debugPrint('Error loading reports: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> submitReport({
    required String title,
    required String description,
    required String category,
    required double latitude,
    required double longitude,
    required String address,
    List<String>? imageUrls,
    String? videoUrl,
    bool isUrgent = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      final report = ReportModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'current_user_id', // Would come from auth provider
        title: title,
        description: description,
        category: category,
        latitude: latitude,
        longitude: longitude,
        address: address,
        imageUrls: imageUrls ?? [],
        videoUrl: videoUrl,
        isUrgent: isUrgent,
        gracePeriodEnds: DateTime.now().add(AppConstants.votingGracePeriod),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _reports.insert(0, report);
    } catch (e) {
      debugPrint('Error submitting report: $e');
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> voteOnReport({
    required String reportId,
    required bool isUpvote,
    double voteWeight = 1.0,
    String? reason,
  }) async {
    try {
      // Check if user already voted
      final existingVoteIndex = _userVotes.indexWhere(
        (vote) => vote.reportId == reportId,
      );

      if (existingVoteIndex != -1) {
        // Remove existing vote
        _userVotes.removeAt(existingVoteIndex);
      }

      // Add new vote
      final vote = VoteModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'current_user_id',
        reportId: reportId,
        isUpvote: isUpvote,
        weight: voteWeight,
        createdAt: DateTime.now(),
        reason: reason,
      );

      _userVotes.add(vote);

      // Update report scores
      _updateReportScores(reportId);

      notifyListeners();
    } catch (e) {
      debugPrint('Error voting on report: $e');
      rethrow;
    }
  }

  void _updateReportScores(String reportId) {
    final reportIndex = _reports.indexWhere((report) => report.id == reportId);
    if (reportIndex == -1) return;

    final report = _reports[reportIndex];
    final reportVotes = _userVotes.where((vote) => vote.reportId == reportId);

    int upvotes = 0;
    int downvotes = 0;
    double weightedScore = 0;

    for (final vote in reportVotes) {
      if (vote.isUpvote) {
        upvotes++;
        weightedScore += vote.weight;
      } else {
        downvotes++;
        weightedScore -= vote.weight;
      }
    }

    // Update report
    _reports[reportIndex] = ReportModel(
      id: report.id,
      userId: report.userId,
      title: report.title,
      description: report.description,
      category: report.category,
      status: report.status,
      latitude: report.latitude,
      longitude: report.longitude,
      address: report.address,
      imageUrls: report.imageUrls,
      videoUrl: report.videoUrl,
      upvotes: upvotes,
      downvotes: downvotes,
      weightedScore: weightedScore,
      isUrgent: report.isUrgent,
      isInGracePeriod: DateTime.now().isBefore(report.gracePeriodEnds),
      gracePeriodEnds: report.gracePeriodEnds,
      createdAt: report.createdAt,
      updatedAt: DateTime.now(),
      reporter: report.reporter,
    );
  }

  VoteModel? getUserVoteForReport(String reportId) {
    try {
      return _userVotes.firstWhere((vote) => vote.reportId == reportId);
    } catch (e) {
      return null;
    }
  }

  ReportModel? getReportById(String reportId) {
    try {
      return _reports.firstWhere((report) => report.id == reportId);
    } catch (e) {
      return null;
    }
  }

  List<ReportModel> _generateMockReports() {
    return [
      ReportModel(
        id: '1',
        userId: 'user1',
        title: 'Pothole on Main Street',
        description:
            'A large pothole has formed near the intersection of Main Street and Oak Avenue. It\'s causing traffic issues and poses a safety hazard, especially during rainy weather when it\'s hard to see.',
        category: 'Roads & Infrastructure',
        latitude: 12.9716,
        longitude: 77.5946,
        address: 'Main St & Oak Ave, Springfield',
        imageUrls: ['https://example.com/pothole1.jpg'],
        upvotes: 15,
        downvotes: 2,
        weightedScore: 18.5,
        isInGracePeriod: false,
        gracePeriodEnds: DateTime.now().subtract(const Duration(hours: 2)),
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      ReportModel(
        id: '2',
        userId: 'user2',
        title: 'Broken Streetlight at Park Entrance',
        description:
            'The streetlight at the park entrance has been out for weeks, making it unsafe for evening joggers and families.',
        category: 'Street Lighting',
        latitude: 12.9716,
        longitude: 77.5946,
        address: 'Central Park Entrance, Springfield',
        imageUrls: ['https://example.com/streetlight1.jpg'],
        upvotes: 8,
        downvotes: 1,
        weightedScore: 7.5,
        isUrgent: true,
        isInGracePeriod: true,
        gracePeriodEnds: DateTime.now().add(const Duration(minutes: 15)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
    ];
  }
}
