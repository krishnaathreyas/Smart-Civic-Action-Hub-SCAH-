// presentation/providers/report_provider.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      debugPrint('=== LOADING REPORTS ===');

      // Load both demo reports and user-submitted reports
      _reports = [];

      // Add demo reports
      final demoReports = _generateMockReports();
      _reports.addAll(demoReports);
      debugPrint('Loaded ${demoReports.length} demo reports');

      // Load user-submitted reports from storage
      final userReports = await _loadUserReportsFromStorage();
      _reports.addAll(userReports);
      debugPrint('Loaded ${userReports.length} user reports from storage');

      // Sort by creation date (newest first)
      _reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint('Total reports loaded: ${_reports.length}');
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

      // Save user report to storage for persistence
      await _saveUserReportToStorage(report);
      debugPrint('Report saved to storage: ${report.title}');
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

  List<ReportModel> _generateMockReports() {
    return [
      ReportModel(
        id: 'demo_1',
        userId: 'demo_user1',
        title: 'Large Pothole on Main Street',
        description:
            'A dangerous pothole has formed near the intersection of Main Street and Oak Avenue. It\'s causing traffic issues and poses a safety hazard, especially during rainy weather when it\'s hard to see. The hole is approximately 2 feet wide and 6 inches deep.',
        category: 'Infrastructure',
        status: 'pending',
        latitude: 12.9716,
        longitude: 77.5946,
        address: 'Main St & Oak Ave, Springfield',
        imageUrls: ['assets/images/pothole.jpg'],
        upvotes: 24,
        downvotes: 3,
        weightedScore: 28.5,
        isInGracePeriod: false,
        gracePeriodEnds: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
        priority: 'high',
      ),
      ReportModel(
        id: 'demo_2',
        userId: 'demo_user2',
        title: 'Broken Streetlight at Park Entrance',
        description:
            'The streetlight at the main park entrance has been out for over two weeks, creating a safety hazard for evening joggers, dog walkers, and families. The area is completely dark after sunset.',
        category: 'Safety',
        status: 'in_progress',
        latitude: 12.9726,
        longitude: 77.5956,
        address: 'Central Park Entrance, Springfield',
        imageUrls: ['assets/images/broken-streetlight.png'],
        upvotes: 18,
        downvotes: 1,
        weightedScore: 19.5,
        isUrgent: true,
        isInGracePeriod: false,
        gracePeriodEnds: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
        priority: 'high',
        assignedAgentName: 'John Smith',
        progressUpdates: ['Investigation started', 'Parts ordered'],
      ),
      ReportModel(
        id: 'demo_3',
        userId: 'demo_user3',
        title: 'Overflowing Garbage Bins in Residential Area',
        description:
            'Multiple garbage bins on Elm Street have been overflowing for days. This is attracting pests and creating an unsanitary environment for residents. The garbage collection seems to have missed this area.',
        category: 'Environment',
        status: 'pending',
        latitude: 12.9706,
        longitude: 77.5936,
        address: 'Elm Street, Residential Block',
        imageUrls: ['assets/images/garbage.jpg'],
        upvotes: 12,
        downvotes: 0,
        weightedScore: 14.0,
        isInGracePeriod: true,
        gracePeriodEnds: DateTime.now().add(const Duration(hours: 8)),
        createdAt: DateTime.now().subtract(const Duration(hours: 16)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 16)),
        priority: 'medium',
      ),
      ReportModel(
        id: 'demo_4',
        userId: 'demo_user4',
        title: 'Graffiti on Public Building Wall',
        description:
            'Vandalism has occurred on the side wall of the community center. The graffiti is inappropriate and needs to be removed to maintain the area\'s appearance and community standards.',
        category: 'Public Services',
        status: 'resolved',
        latitude: 12.9696,
        longitude: 77.5926,
        address: 'Community Center, West Side',
        imageUrls: ['assets/images/graffiti.jpg'],
        upvotes: 8,
        downvotes: 2,
        weightedScore: 7.5,
        isInGracePeriod: false,
        gracePeriodEnds: DateTime.now().subtract(const Duration(days: 5)),
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        priority: 'low',
        assignedAgentName: 'Sarah Johnson',
        progressUpdates: [
          'Report acknowledged',
          'Cleaning scheduled',
          'Graffiti removed',
        ],
      ),
      ReportModel(
        id: 'demo_5',
        userId: 'demo_user5',
        title: 'Malfunctioning Traffic Light at Busy Intersection',
        description:
            'The traffic light at the intersection of First Avenue and Main Street is stuck on red in all directions, causing significant traffic backup during rush hours.',
        category: 'Transportation',
        status: 'in_progress',
        latitude: 12.9736,
        longitude: 77.5966,
        address: 'First Ave & Main St Intersection',
        imageUrls: ['assets/images/streetlight.jpg'],
        upvotes: 35,
        downvotes: 1,
        weightedScore: 42.0,
        isUrgent: true,
        isInGracePeriod: false,
        gracePeriodEnds: DateTime.now().subtract(const Duration(hours: 12)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        priority: 'urgent',
        assignedAgentName: 'Mike Wilson',
        assignedAgentPhone: '(555) 123-4567',
        progressUpdates: [
          'Emergency response dispatched',
          'Technician on site',
          'Repair in progress',
        ],
      ),
    ];
  }

  // Storage methods for user reports persistence
  static const String _userReportsKey = 'user_reports';

  Future<void> _saveUserReportToStorage(ReportModel report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingReportsJson = prefs.getString(_userReportsKey) ?? '[]';
      final List<dynamic> existingReports = jsonDecode(existingReportsJson);

      // Add new report
      existingReports.insert(0, report.toJson());

      // Save back to storage
      await prefs.setString(_userReportsKey, jsonEncode(existingReports));
      debugPrint('User report saved to storage successfully');
    } catch (e) {
      debugPrint('Error saving report to storage: $e');
    }
  }

  Future<List<ReportModel>> _loadUserReportsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = prefs.getString(_userReportsKey);

      if (reportsJson != null) {
        final List<dynamic> reportsList = jsonDecode(reportsJson);
        return reportsList.map((json) => ReportModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error loading reports from storage: $e');
    }
    return [];
  }

  Future<void> clearUserReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userReportsKey);
      debugPrint('User reports cleared from storage');
    } catch (e) {
      debugPrint('Error clearing user reports: $e');
    }
  }
}
