// presentation/utils/department_stats_generator.dart
import 'package:flutter/material.dart';

import '../../data/models/department_stats.dart';
import '../../data/models/report_models.dart';

class DepartmentStatsGenerator {
  static List<DepartmentStats> generateStats(List<ReportModel> reports) {
    // Define department colors
    final Map<String, Color> departmentColors = {
      'Public Works': Colors.orange,
      'Police & Security': Colors.red,
      'Environmental Dept': Colors.green,
      'Transport Authority': Colors.blue,
      'Municipal Services': Colors.purple,
      'Health Department': Colors.pink,
      'Education Board': Colors.teal,
      'Utilities Board': Colors.amber,
      'General Administration': Colors.grey,
    };

    // Group reports by department
    final Map<String, List<ReportModel>> reportsByDepartment = {};

    for (final report in reports) {
      final department = CategoryDepartmentMapping.getDepartmentForCategory(
        report.category,
      );
      reportsByDepartment.putIfAbsent(department, () => []);
      reportsByDepartment[department]!.add(report);
    }

    // Generate stats for each department
    final List<DepartmentStats> stats = [];

    reportsByDepartment.forEach((department, deptReports) {
      final totalReports = deptReports.length;
      final resolvedReports = deptReports
          .where((r) => r.status.toLowerCase() == 'resolved')
          .length;
      final inProgressReports = deptReports
          .where(
            (r) =>
                r.status.toLowerCase() == 'in progress' ||
                r.status.toLowerCase() == 'in_progress',
          )
          .length;
      final pendingReports = deptReports
          .where(
            (r) =>
                r.status.toLowerCase() == 'pending' ||
                r.status.toLowerCase() == 'submitted',
          )
          .length;

      final resolutionRate = totalReports > 0
          ? (resolvedReports / totalReports * 100)
          : 0.0;

      // Calculate average resolution time (simplified - in real app this would use actual timestamps)
      final avgResolutionTime = _calculateAvgResolutionTime(deptReports);

      stats.add(
        DepartmentStats(
          department: department,
          totalReports: totalReports,
          resolvedReports: resolvedReports,
          inProgressReports: inProgressReports,
          pendingReports: pendingReports,
          resolutionRate: resolutionRate,
          avgResolutionTime: avgResolutionTime,
          color: departmentColors[department] ?? Colors.grey,
        ),
      );
    });

    // Sort by total reports (descending)
    stats.sort((a, b) => b.totalReports.compareTo(a.totalReports));

    return stats;
  }

  static double _calculateAvgResolutionTime(List<ReportModel> reports) {
    // Simplified calculation - in real app this would calculate actual time differences
    final resolvedReports = reports
        .where((r) => r.status.toLowerCase() == 'resolved')
        .toList();

    if (resolvedReports.isEmpty) return 0.0;

    // For demo purposes, calculate based on report priority and category
    double totalTime = 0;
    for (final report in resolvedReports) {
      // Simulate resolution time based on priority and urgency
      if (report.isUrgent) {
        totalTime += 1.0; // 1 day for urgent issues
      } else if (report.priority == 'High') {
        totalTime += 2.0; // 2 days for high priority
      } else if (report.priority == 'Medium') {
        totalTime += 5.0; // 5 days for medium priority
      } else {
        totalTime += 10.0; // 10 days for low priority
      }
    }

    return totalTime / resolvedReports.length;
  }

  // Generate summary statistics for overview cards
  static Map<String, dynamic> generateSummaryStats(List<ReportModel> reports) {
    final departmentStats = generateStats(reports);

    final totalReports = reports.length;
    final totalResolved = reports
        .where((r) => r.status.toLowerCase() == 'resolved')
        .length;
    final overallResolutionRate = totalReports > 0
        ? (totalResolved / totalReports * 100)
        : 0.0;

    // Find best performing department
    final bestDepartment = departmentStats.isNotEmpty
        ? departmentStats.reduce(
            (a, b) => a.resolutionRate > b.resolutionRate ? a : b,
          )
        : null;

    // Find most active department
    final mostActiveDepartment = departmentStats.isNotEmpty
        ? departmentStats.reduce(
            (a, b) => a.totalReports > b.totalReports ? a : b,
          )
        : null;

    // Calculate average response time across all departments
    final avgResponseTime = departmentStats.isNotEmpty
        ? departmentStats
                  .map((d) => d.avgResolutionTime)
                  .reduce((a, b) => a + b) /
              departmentStats.length
        : 0.0;

    return {
      'totalReports': totalReports,
      'overallResolutionRate': overallResolutionRate,
      'bestDepartment': bestDepartment,
      'mostActiveDepartment': mostActiveDepartment,
      'avgResponseTime': avgResponseTime,
      'departmentCount': departmentStats.length,
    };
  }
}
