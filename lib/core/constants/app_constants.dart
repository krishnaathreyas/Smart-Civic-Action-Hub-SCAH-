// core/constants/app_constants.dart
class AppConstants {
  // App Info
  static const String appName = 'SCAH';
  static const String appFullName = 'Smart Civic Action Hub';
  static const String appTagline = 'Your Voice, Your Community';
  static const String appVersion = '1.0.0';

  // Voting System
  static const Duration votingGracePeriod = Duration(hours: 24);
  static const double minVoteWeight = 0.5;
  static const double maxVoteWeight = 3.0;
  static const int minReputationToVote = 10;

  // Reputation System
  static const Map<String, int> reputationTiers = {
    'Bronze': 0,
    'Silver': 100,
    'Gold': 500,
    'Platinum': 1000,
    'Diamond': 2500,
  };

  // Points System
  static const int pointsForValidReport = 10;
  static const int pointsForResolvedReport = 25;
  static const int pointsForHelpfulVote = 5;
  static const int penaltyForInvalidReport = -15;
  static const int penaltyForSpamReport = -25;

  // Report Categories
  static const List<String> reportCategories = [
    'Roads & Infrastructure',
    'Street Lighting',
    'Water & Sanitation',
    'Public Safety',
    'Waste Management',
    'Traffic & Transportation',
    'Parks & Recreation',
    'Public Buildings',
    'Environmental Issues',
    'Noise Pollution',
    'Other',
  ];

  // Report Status
  static const List<String> reportStatuses = [
    'submitted',
    'under_review',
    'in_progress',
    'resolved',
    'rejected',
    'duplicate',
  ];

  // Location Settings
  static const double maxReportDistanceKm = 10.0;
  static const double minAccuracyMeters = 50.0;

  // UI Constants
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const int maxImageUploads = 5;
  static const int maxDescriptionLength = 500;
  static const int maxTitleLength = 100;

  // Storage Keys
  static const String isFirstTimeKey = 'is_first_time';
  static const String hasSeenTutorialKey = 'has_seen_tutorial';
  static const String selectedThemeKey = 'selected_theme';

  // Error Messages
  static const String networkErrorMessage =
      'Please check your internet connection and try again.';
  static const String locationErrorMessage =
      'Unable to get your current location. Please enable location services.';
  static const String genericErrorMessage =
      'Something went wrong. Please try again.';
}
