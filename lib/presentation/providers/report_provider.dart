import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/report_model.dart';
import '../../data/models/vote_model.dart';
import '../../data/services/civic_report_api_client.dart';
import 'auth_provider.dart';

class ReportProvider extends ChangeNotifier {
  final CivicReportApiClient _apiClient = CivicReportApiClient();
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

  // Get reports by user ID
  List<ReportModel> getReportsByUserId(String userId) {
    return _reports.where((report) => report.userId == userId).toList();
  }

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
      // Get reports from all departments
      final departments = await _apiClient.getDepartments();
      _reports.clear();

      for (var department in departments) {
        final response = await _apiClient.getDepartmentReports(department);
        final departmentReports = response['reports'] as List;

        for (var report in departmentReports) {
          _reports.add(
            ReportModel(
              id: report['id'],
              userId: 'system', // Update with actual user ID when available
              title: report['content'].split('\n')[0], // First line as title
              description: report['content'],
              category: report['metadata']['category'] ?? 'Uncategorized',
              latitude: report['metadata']['location']?['latitude'] ?? 0.0,
              longitude: report['metadata']['location']?['longitude'] ?? 0.0,
              address: report['metadata']['location']?['address'] ?? '',
              imageUrls: [], // Add image support in backend
              isUrgent: report['metadata']['urgency'] == 'high',
              status: report['metadata']['status'] ?? 'pending',
              gracePeriodEnds: DateTime.now().add(
                AppConstants.votingGracePeriod,
              ),
              createdAt: DateTime.now(), // Add timestamp in backend
              updatedAt: DateTime.now(),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading reports: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> submitReport({
    required BuildContext context,
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      // Determine department based on category
      String department = _getDepartmentForCategory(category);

      // Submit to API
      await _apiClient.submitReport(
        title: title,
        description: description,
        department: department,
        category: category,
        urgency: isUrgent ? 'high' : 'normal',
        location: {
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
        },
        imageUrls: imageUrls,
      );

      // Add to local state
      final report = ReportModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: currentUser?.id ?? 'anonymous',
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

  String _getDepartmentForCategory(String category) {
    // Map categories to departments
    switch (category.toLowerCase()) {
      case 'roads':
      case 'garbage':
      case 'parks':
        return 'BBMP';
      case 'electricity':
      case 'power':
        return 'BESCOM';
      case 'traffic':
      case 'accidents':
        return 'BTP';
      case 'water':
      case 'sewage':
        return 'BWHSP';
      default:
        return 'BBMP'; // Default department
    }
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
}
