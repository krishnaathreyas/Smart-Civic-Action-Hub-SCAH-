// presentation/widgets/department_charts.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/department_stats.dart';

class DepartmentChartsSection extends StatelessWidget {
  final List<DepartmentStats> departmentStats;

  const DepartmentChartsSection({Key? key, required this.departmentStats})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Department Performance Analytics',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.darkGray,
          ),
        ),
        const SizedBox(height: 20),

        // Resolution Rate Comparison Chart
        _buildChartCard(
          context,
          'Resolution Rate Comparison',
          'Percentage of resolved issues by department',
          _buildResolutionRateChart(),
        ),
        const SizedBox(height: 20),

        // Reports Volume Bar Chart
        _buildChartCard(
          context,
          'Reports Volume by Department',
          'Total number of reports received',
          _buildVolumeBarChart(),
        ),
        const SizedBox(height: 20),

        // Status Distribution Pie Chart
        _buildChartCard(
          context,
          'Overall Status Distribution',
          'Current status of all reports',
          _buildStatusPieChart(),
        ),
        const SizedBox(height: 20),

        // Performance Score Chart
        _buildChartCard(
          context,
          'Department Performance Score',
          'Based on resolution rate and response time',
          _buildPerformanceScoreChart(),
        ),
      ],
    );
  }

  Widget _buildChartCard(
    BuildContext context,
    String title,
    String subtitle,
    Widget chart,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGray,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.mediumGray),
          ),
          const SizedBox(height: 20),
          SizedBox(height: 300, child: chart),
        ],
      ),
    );
  }

  Widget _buildResolutionRateChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        minY: 0,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => AppTheme.primaryBlue.withOpacity(0.9),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${departmentStats[groupIndex].department}\n${rod.toY.round()}%',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < departmentStats.length) {
                  final dept = departmentStats[value.toInt()].department;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      dept.split(' ').first, // Show first word only
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 25,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
        ),
        barGroups: departmentStats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: stat.resolutionRate,
                color: stat.color,
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVolumeBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY:
            departmentStats
                .map((e) => e.totalReports.toDouble())
                .reduce((a, b) => a > b ? a : b) *
            1.2,
        minY: 0,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => AppTheme.primaryBlue.withOpacity(0.9),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${departmentStats[groupIndex].department}\n${rod.toY.round()} reports',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < departmentStats.length) {
                  final dept = departmentStats[value.toInt()].department;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      dept.split(' ').first, // Show first word only
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
        ),
        barGroups: departmentStats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: stat.totalReports.toDouble(),
                color: stat.color,
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusPieChart() {
    final totalResolved = departmentStats.fold(
      0,
      (sum, stat) => sum + stat.resolvedReports,
    );
    final totalInProgress = departmentStats.fold(
      0,
      (sum, stat) => sum + stat.inProgressReports,
    );
    final totalPending = departmentStats.fold(
      0,
      (sum, stat) => sum + stat.pendingReports,
    );
    final total = totalResolved + totalInProgress + totalPending;

    if (total == 0) {
      return const Center(child: Text('No data available'));
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  color: Colors.green,
                  value: totalResolved.toDouble(),
                  title: '${((totalResolved / total) * 100).round()}%',
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.orange,
                  value: totalInProgress.toDouble(),
                  title: '${((totalInProgress / total) * 100).round()}%',
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.red,
                  value: totalPending.toDouble(),
                  title: '${((totalPending / total) * 100).round()}%',
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem('Resolved', Colors.green, totalResolved),
              const SizedBox(height: 8),
              _buildLegendItem('In Progress', Colors.orange, totalInProgress),
              const SizedBox(height: 8),
              _buildLegendItem('Pending', Colors.red, totalPending),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$count reports',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceScoreChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 10,
        minY: 0,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => AppTheme.primaryBlue.withOpacity(0.9),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final score = _calculatePerformanceScore(
                departmentStats[groupIndex],
              );
              return BarTooltipItem(
                '${departmentStats[groupIndex].department}\nScore: ${score.toStringAsFixed(1)}/10',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < departmentStats.length) {
                  final dept = departmentStats[value.toInt()].department;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      dept.split(' ').first,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 2,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
        ),
        barGroups: departmentStats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          final score = _calculatePerformanceScore(stat);
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: score,
                color: _getPerformanceColor(score),
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  double _calculatePerformanceScore(DepartmentStats stat) {
    // Performance score based on resolution rate (70%) and response time (30%)
    final resolutionScore =
        stat.resolutionRate / 10; // Convert percentage to 0-10 scale
    final responseScore = stat.avgResolutionTime > 0
        ? (10 - (stat.avgResolutionTime / 10).clamp(0, 10))
        : 5; // Default score if no response time data

    return (resolutionScore * 0.7) + (responseScore * 0.3);
  }

  Color _getPerformanceColor(double score) {
    if (score >= 7) return Colors.green;
    if (score >= 5) return Colors.orange;
    return Colors.red;
  }
}
