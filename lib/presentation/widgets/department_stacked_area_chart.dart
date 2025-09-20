// presentation/widgets/department_stacked_area_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/department_stats.dart';
import '../../data/models/report_models.dart';

class DepartmentStackedAreaChart extends StatelessWidget {
  final List<ReportModel> reports;
  final int timeframeDays; // 0 means All
  final Set<String>? visibleDepartments; // null => all
  final bool percentMode; // normalize to 0..100 when true

  const DepartmentStackedAreaChart({
    super.key,
    required this.reports,
    required this.timeframeDays,
    this.visibleDepartments,
    this.percentMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const Center(child: Text('No data to display'));
    }

    final now = DateTime.now();
    final startDate = timeframeDays == 0
        ? _minDate(reports.map((r) => r.createdAt))
        : now.subtract(Duration(days: timeframeDays - 1));

    // Build per-department day series
    final grouped = _groupReportsByDepartmentAndDay(reports, startDate, now);
    var departments = grouped.keys.toList();
    if (visibleDepartments != null) {
      departments = departments
          .where((d) => visibleDepartments!.contains(d))
          .toList();
    }

    if (departments.isEmpty) {
      return const Center(child: Text('No department data'));
    }

    // Build stacked series: for each department, create a cumulative area stacked over previous ones
    final int days = grouped.values.first.length;

    // Determine totals per day (selected departments only)
    final List<int> totalPerDay = List<int>.filled(days, 0);
    for (var i = 0; i < days; i++) {
      int sum = 0;
      for (final dept in departments) {
        sum += grouped[dept]![i];
      }
      totalPerDay[i] = sum;
    }
    final maxYCounts = totalPerDay
        .fold<int>(0, (a, b) => a > b ? a : b)
        .toDouble();

    // Colors per department
    final departmentColors = _departmentColorsFor(departments);

    // Build layered areas: bottom-most is first dept in list
    final List<LineChartBarData> layers = [];
    if (!percentMode) {
      final List<int> running = List<int>.filled(days, 0);
      for (final dept in departments) {
        final series = grouped[dept]!;
        final List<FlSpot> spots = [];
        for (var i = 0; i < days; i++) {
          running[i] += series[i];
          spots.add(FlSpot(i.toDouble(), running[i].toDouble()));
        }
        layers.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 0,
            dotData: const FlDotData(show: false),
            color: departmentColors[dept]!.withValues(alpha: 0.0),
            belowBarData: BarAreaData(
              show: true,
              color: departmentColors[dept]!.withValues(alpha: 0.35),
            ),
          ),
        );
      }
    } else {
      final List<double> runningPct = List<double>.filled(days, 0);
      for (final dept in departments) {
        final series = grouped[dept]!;
        final List<FlSpot> spots = [];
        for (var i = 0; i < days; i++) {
          final total = totalPerDay[i];
          final pct = total > 0 ? (series[i] / total) * 100.0 : 0.0;
          runningPct[i] += pct;
          spots.add(FlSpot(i.toDouble(), runningPct[i]));
        }
        layers.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 0,
            dotData: const FlDotData(show: false),
            color: departmentColors[dept]!.withValues(alpha: 0.0),
            belowBarData: BarAreaData(
              show: true,
              color: departmentColors[dept]!.withValues(alpha: 0.35),
            ),
          ),
        );
      }
    }

    // X-axis labels at interval
    final labels = <int, String>{};
    final interval = days <= 7
        ? 1
        : days <= 14
        ? 2
        : days <= 31
        ? 5
        : 10;
    for (var i = 0; i < days; i += interval) {
      final date = startDate.add(Duration(days: i));
      labels[i] = _formatShortDate(date);
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (days - 1).toDouble(),
        minY: 0,
        maxY: percentMode ? 100.0 : (maxYCounts * 1.25).clamp(2.0, 100000.0),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha: 0.25),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) => Text(
                percentMode ? '${value.toInt()}%' : value.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (labels.containsKey(idx)) {
                  return Transform.rotate(
                    angle: -0.6,
                    child: Text(
                      labels[idx]!,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppTheme.primaryBlue.withValues(alpha: 0.9),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((t) {
                final idx = t.x.toInt();
                final date = startDate.add(Duration(days: idx));
                // Build per-dept values on that day
                final details = departments
                    .map((d) {
                      final count = grouped[d]![idx];
                      if (percentMode) {
                        final total = totalPerDay[idx];
                        final pct = total > 0 ? (count / total * 100.0) : 0.0;
                        return '${d.split(' ').first}: ${pct.toStringAsFixed(0)}%';
                      }
                      return '${d.split(' ').first}: $count';
                    })
                    .join(' \u2022 ');
                final totalLabel = percentMode ? '100%' : '${totalPerDay[idx]}';
                return LineTooltipItem(
                  '${_formatFullDate(date)}\n$details\nTotal: $totalLabel',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: layers,
      ),
    );
  }

  // Helpers
  static Map<String, List<int>> _groupReportsByDepartmentAndDay(
    List<ReportModel> reports,
    DateTime start,
    DateTime end,
  ) {
    final days = end.difference(start).inDays + 1;
    final Map<String, List<int>> result = {};

    for (final r in reports) {
      if (r.createdAt.isBefore(start) || r.createdAt.isAfter(end)) continue;
      final dept = CategoryDepartmentMapping.getDepartmentForCategory(
        r.category,
      );
      result.putIfAbsent(dept, () => List<int>.filled(days, 0));
      final idx = r.createdAt.difference(start).inDays;
      if (idx >= 0 && idx < days) {
        result[dept]![idx] += 1;
      }
    }

    // Ensure all departments exist with consistent length
    if (result.isEmpty) return result;

    final length = result.values.first.length;
    for (final entry in result.entries) {
      if (entry.value.length != length) {
        result[entry.key] = List<int>.from(entry.value)..length = length;
      }
    }

    return result;
  }

  static Map<String, Color> _departmentColorsFor(List<String> departments) {
    final Map<String, Color> palette = {
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

    final List<Color> fallback = [
      Colors.blueGrey,
      Colors.indigo,
      Colors.cyan,
      Colors.lime,
      Colors.brown,
    ];

    final Map<String, Color> out = {};
    int i = 0;
    for (final d in departments) {
      out[d] = palette[d] ?? fallback[i % fallback.length];
      i++;
    }
    return out;
  }

  static DateTime _minDate(Iterable<DateTime> dates) {
    DateTime? min;
    for (final d in dates) {
      if (min == null || d.isBefore(min)) min = d;
    }
    return min ?? DateTime.now();
  }

  static String _formatShortDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  static String _formatFullDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final wk = weekdays[d.weekday - 1];
    final mo = months[d.month - 1];
    return '$wk, $mo ${d.day}, ${d.year}';
  }
}
