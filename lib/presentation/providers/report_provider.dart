// presentation/providers/report_provider.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/evidence_model.dart';
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
  // Followed report IDs
  final Set<String> _followedIds = <String>{};
  // Evidence store (local/demo)
  final Map<String, List<EvidenceModel>> _evidenceByReport = {};
  // Votes persistence
  static const String _votesKey = 'user_votes_v1';

  // Getters
  List<ReportModel> get reports => _getFilteredAndSortedReports();
  bool get isLoading => _isLoading;
  String get sortBy => _sortBy;
  String? get filterByCategory => _filterByCategory;
  Set<String> get followedIds => Set.unmodifiable(_followedIds);
  List<EvidenceModel> getEvidenceForReport(String reportId) =>
      List.unmodifiable(_evidenceByReport[reportId] ?? const []);

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

  // Evidence API (demo local persistence)
  static const _evidenceKey = 'report_evidence_v1';

  Future<void> addEvidence(EvidenceModel e) async {
    final list = _evidenceByReport.putIfAbsent(e.reportId, () => []);
    list.add(e);
    await _saveEvidence();
    notifyListeners();
  }

  Future<void> loadEvidence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_evidenceKey);
      if (raw == null) return;
      final map = (jsonDecode(raw) as Map<String, dynamic>);
      _evidenceByReport.clear();
      map.forEach((rid, list) {
        _evidenceByReport[rid] = (list as List)
            .map((e) => EvidenceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _saveEvidence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _evidenceByReport.map(
        (rid, list) => MapEntry(rid, list.map((e) => e.toJson()).toList()),
      );
      await prefs.setString(_evidenceKey, jsonEncode(map));
    } catch (_) {}
  }

  Future<void> removeEvidence(String reportId, String evidenceId) async {
    final list = _evidenceByReport[reportId];
    if (list == null) return;
    list.removeWhere((e) => e.id == evidenceId);
    await _saveEvidence();
    notifyListeners();
  }

  Future<void> setEvidenceMarkedFake(
    String reportId,
    String evidenceId,
    bool marked,
  ) async {
    final list = _evidenceByReport[reportId];
    if (list == null) return;
    final idx = list.indexWhere((e) => e.id == evidenceId);
    if (idx == -1) return;
    final e = list[idx];
    list[idx] = EvidenceModel(
      id: e.id,
      reportId: e.reportId,
      userId: e.userId,
      reason: e.reason,
      imageBase64: e.imageBase64,
      markedAsFake: marked,
      createdAt: e.createdAt,
    );
    await _saveEvidence();
    notifyListeners();
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

      // Load followed IDs early for UI state
      await _loadFollowedFromStorage();
      // Load evidence for persistence
      await loadEvidence();

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

      // Load persisted votes and recompute scores now that reports are present
      await _loadVotesFromStorage();

      // Sort by creation date (newest first)
      _reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint('Total reports loaded: ${_reports.length}');
    } catch (e) {
      debugPrint('Error loading reports: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Follow/Unfollow API
  static const String _followedKey = 'followed_report_ids_v1';

  bool isFollowed(String reportId) => _followedIds.contains(reportId);

  Future<void> toggleFollow(String reportId) async {
    if (_followedIds.contains(reportId)) {
      _followedIds.remove(reportId);
    } else {
      _followedIds.add(reportId);
    }
    notifyListeners();
    await _saveFollowedToStorage();
  }

  Future<void> _loadFollowedFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_followedKey) ?? <String>[];
      _followedIds
        ..clear()
        ..addAll(ids);
    } catch (e) {
      debugPrint('Error loading followed IDs: $e');
    }
  }

  Future<void> _saveFollowedToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_followedKey, _followedIds.toList());
    } catch (e) {
      debugPrint('Error saving followed IDs: $e');
    }
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
    required String userId,
    required bool isUpvote,
    double voteWeight = 1.0,
    String? reason,
  }) async {
    try {
      // Check if this user already voted on this report
      final existingVoteIndex = _userVotes.indexWhere(
        (vote) => vote.reportId == reportId && vote.userId == userId,
      );

      if (existingVoteIndex != -1) {
        final existing = _userVotes[existingVoteIndex];
        if (existing.isUpvote == isUpvote) {
          // Toggling the same choice -> unvote (remove)
          _userVotes.removeAt(existingVoteIndex);
        } else {
          // Switching choice -> replace with new vote
          _userVotes.removeAt(existingVoteIndex);
          _userVotes.add(
            VoteModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              userId: userId,
              reportId: reportId,
              isUpvote: isUpvote,
              weight: voteWeight,
              createdAt: DateTime.now(),
              reason: reason,
            ),
          );
        }
      } else {
        // No existing vote -> add new
        _userVotes.add(
          VoteModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: userId,
            reportId: reportId,
            isUpvote: isUpvote,
            weight: voteWeight,
            createdAt: DateTime.now(),
            reason: reason,
          ),
        );
      }

      // Update report scores
      _updateReportScores(reportId);
      // Persist votes
      await _saveVotesToStorage();
      notifyListeners();
    } catch (e) {
      debugPrint('Error voting on report: $e');
      rethrow;
    }
  }

  // Increment view count for a report (called when a report detail screen is opened)
  Future<void> incrementViewCount(String reportId) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) return;

    final r = _reports[index];
    final updated = ReportModel(
      id: r.id,
      userId: r.userId,
      title: r.title,
      description: r.description,
      category: r.category,
      status: r.status,
      latitude: r.latitude,
      longitude: r.longitude,
      address: r.address,
      imageUrls: r.imageUrls,
      videoUrl: r.videoUrl,
      upvotes: r.upvotes,
      downvotes: r.downvotes,
      weightedScore: r.weightedScore,
      isUrgent: r.isUrgent,
      isInGracePeriod: r.isInGracePeriod,
      gracePeriodEnds: r.gracePeriodEnds,
      createdAt: r.createdAt,
      updatedAt: DateTime.now(),
      reporter: r.reporter,
      assignedAgentId: r.assignedAgentId,
      assignedAgentName: r.assignedAgentName,
      assignedAgentPhone: r.assignedAgentPhone,
      assignedAgentEmail: r.assignedAgentEmail,
      progressUpdates: r.progressUpdates,
      viewCount: r.viewCount + 1,
      priority: r.priority,
    );

    _reports[index] = updated;
    notifyListeners();

    // Try to persist if it's a user-submitted report
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = prefs.getString(_userReportsKey);
      if (reportsJson != null) {
        final List<dynamic> list = jsonDecode(reportsJson);
        final i = list.indexWhere((e) => e['id'] == reportId);
        if (i != -1) {
          list[i] = updated.toJson();
          await prefs.setString(_userReportsKey, jsonEncode(list));
        }
      }
    } catch (_) {}
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

  VoteModel? getUserVoteForReport(String reportId, String userId) {
    try {
      return _userVotes.firstWhere(
        (vote) => vote.reportId == reportId && vote.userId == userId,
      );
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
        // Assignment and engagement
        assignedAgentId: 'agent1',
        assignedAgentName: 'Tom Wilson',
        assignedAgentPhone: '+1-555-1001',
        assignedAgentEmail: 'tom.wilson@springfield.gov',
        progressUpdates: [
          'Report received',
          'Site inspection scheduled',
          'Repair team assigned',
        ],
        // Ensure views > support + oppose
        viewCount: 60,
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
        assignedAgentId: 'agent2',
        assignedAgentName: 'John Smith',
        assignedAgentPhone: '+1-555-1002',
        assignedAgentEmail: 'john.smith@springfield.gov',
        progressUpdates: [
          'Investigation started',
          'Parts ordered',
          'Repair scheduled',
        ],
        viewCount: 55,
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
        assignedAgentId: 'agent3',
        assignedAgentName: 'Lisa Anderson',
        assignedAgentPhone: '+1-555-1003',
        assignedAgentEmail: 'lisa.anderson@springfield.gov',
        progressUpdates: ['Reported', 'Sanitation team notified'],
        viewCount: 40,
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
        assignedAgentId: 'agent4',
        assignedAgentName: 'Sarah Johnson',
        assignedAgentPhone: '+1-555-1004',
        assignedAgentEmail: 'sarah.johnson@springfield.gov',
        progressUpdates: [
          'Report acknowledged',
          'Cleaning scheduled',
          'Graffiti removed',
        ],
        viewCount: 35,
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
        assignedAgentId: 'agent5',
        assignedAgentName: 'Mike Wilson',
        assignedAgentPhone: '(555) 123-4567',
        assignedAgentEmail: 'mike.wilson@springfield.gov',
        progressUpdates: [
          'Emergency response dispatched',
          'Technician on site',
          'Repair in progress',
        ],
        viewCount: 90,
      ),
    ];
  }

  // Storage methods for user reports persistence
  static const String _userReportsKey = 'user_reports';

  Future<void> _loadVotesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_votesKey);
      if (raw == null) return;
      final List<dynamic> list = jsonDecode(raw);
      _userVotes = list
          .map((e) => VoteModel.fromJson(e as Map<String, dynamic>))
          .toList();
      // Recompute scores for affected reports
      final affectedReportIds = _userVotes.map((v) => v.reportId).toSet();
      for (final rid in affectedReportIds) {
        _updateReportScores(rid);
      }
    } catch (e) {
      debugPrint('Error loading votes from storage: $e');
    }
  }

  Future<void> _saveVotesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _userVotes.map((v) => v.toJson()).toList();
      await prefs.setString(_votesKey, jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving votes to storage: $e');
    }
  }

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
