// presentation/widgets/reports_trend_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/report_models.dart';

class ReportsTrendChart extends StatelessWidget {
  final List<ReportModel> reports;
  // timeframeDays: 0 means All; otherwise use last N days
  final int timeframeDays;

  const ReportsTrendChart({
    super.key,
    required this.reports,
    required this.timeframeDays,
  });

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const Center(child: Text('No data in this timeframe'));
    }

    final now = DateTime.now();
    final startDate = timeframeDays == 0
        ? _minDate(reports.map((r) => r.createdAt))
        : now.subtract(Duration(days: timeframeDays - 1));

    final series = _groupByDay(reports, startDate, now);
    final spots = <FlSpot>[];
    final labels = <int, String>{};

    for (var i = 0; i < series.length; i++) {
      spots.add(FlSpot(i.toDouble(), series[i].toDouble()));
    }

    // Build x-axis labels at reasonable intervals
    final totalDays = series.length;
    final interval = totalDays <= 7
        ? 1
        : totalDays <= 14
        ? 2
        : totalDays <= 31
        ? 5
        : 10;

    for (var i = 0; i < totalDays; i += interval) {
      final date = startDate.add(Duration(days: i));
      labels[i] = _formatShortDate(date);
    }

    final maxY = (series.isEmpty ? 0 : series.reduce((a, b) => a > b ? a : b))
        .toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (spots.isNotEmpty ? spots.last.x : 0),
        minY: 0,
        maxY: (maxY * 1.3).clamp(2.0, 1000.0),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.withOpacity(0.25), strokeWidth: 1),
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
                value.toInt().toString(),
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
            getTooltipColor: (_) => AppTheme.primaryBlue.withOpacity(0.9),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((t) {
                final idx = t.x.toInt();
                final date = startDate.add(Duration(days: idx));
                return LineTooltipItem(
                  '${_formatFullDate(date)}\n${t.y.toInt()} reports',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primaryBlue,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryBlue.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }

  static DateTime _minDate(Iterable<DateTime> dates) {
    DateTime? min;
    for (final d in dates) {
      if (min == null || d.isBefore(min)) min = d;
    }
    return min ?? DateTime.now();
  }

  static List<int> _groupByDay(
    List<ReportModel> reports,
    DateTime start,
    DateTime end,
  ) {
    final days = end.difference(start).inDays + 1;
    final counts = List<int>.filled(days, 0);
    for (final r in reports) {
      if (r.createdAt.isBefore(start) || r.createdAt.isAfter(end)) continue;
      final idx = r.createdAt.difference(start).inDays;
      if (idx >= 0 && idx < counts.length) counts[idx] += 1;
    }
    return counts;
  }

  static String _formatShortDate(DateTime d) {
    // e.g., Sep 18
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
    // e.g., Thu, Sep 18, 2025
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
