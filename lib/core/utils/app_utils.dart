import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

class AppUtils {
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return formatDate(date);
    }
  }

  static String getReputationTier(int points) {
    final entries = AppConstants.reputationTiers.entries.toList();
    for (int i = entries.length - 1; i >= 0; i--) {
      if (points >= entries[i].value) {
        return entries[i].key;
      }
    }
    return 'Bronze';
  }

  static double calculateVoteWeight(int reputationPoints) {
    if (reputationPoints < 50) return AppConstants.minVoteWeight;
    if (reputationPoints < 100) return 1.0;
    if (reputationPoints < 500) return 1.5;
    if (reputationPoints < 1000) return 2.0;
    if (reputationPoints < 2500) return 2.5;
    return AppConstants.maxVoteWeight;
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return AppTheme.successGreen;
      case 'in_progress':
      case 'under_review':
        return AppTheme.warningOrange;
      case 'rejected':
        return AppTheme.errorRed;
      default:
        return AppTheme.primaryBlue;
    }
  }
}
