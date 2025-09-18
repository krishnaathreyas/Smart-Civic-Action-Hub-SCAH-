// data/models/department_stats.dart
import 'package:flutter/material.dart';

class DepartmentStats {
  final String department;
  final int totalReports;
  final int resolvedReports;
  final int inProgressReports;
  final int pendingReports;
  final double resolutionRate;
  final double avgResolutionTime; // in days
  final Color color;

  DepartmentStats({
    required this.department,
    required this.totalReports,
    required this.resolvedReports,
    required this.inProgressReports,
    required this.pendingReports,
    required this.resolutionRate,
    required this.avgResolutionTime,
    required this.color,
  });
}

// Mapping categories to government departments
class CategoryDepartmentMapping {
  static const Map<String, String> categoryToDepartment = {
    'Infrastructure': 'Public Works',
    'Safety': 'Police & Security',
    'Environment': 'Environmental Dept',
    'Transportation': 'Transport Authority',
    'Public Services': 'Municipal Services',
    'Health': 'Health Department',
    'Education': 'Education Board',
    'Utilities': 'Utilities Board',
  };

  static String getDepartmentForCategory(String category) {
    return categoryToDepartment[category] ?? 'General Administration';
  }
}