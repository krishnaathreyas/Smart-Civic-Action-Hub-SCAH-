// presentation/screens/report/enhanced_report_detail_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/report_models.dart';

class EnhancedReportDetailScreen extends StatefulWidget {
  final ReportModel report;

  const EnhancedReportDetailScreen({Key? key, required this.report})
    : super(key: key);

  @override
  State<EnhancedReportDetailScreen> createState() =>
      _EnhancedReportDetailScreenState();
}

class _EnhancedReportDetailScreenState
    extends State<EnhancedReportDetailScreen> {
  bool _hasVoted = false;
  int _currentUpvotes = 0;
  int _currentDownvotes = 0;

  @override
  void initState() {
    super.initState();
    _currentUpvotes = widget.report.upvotes;
    _currentDownvotes = widget.report.downvotes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 24),
                  _buildDescriptionSection(),
                  const SizedBox(height: 24),
                  _buildVotingSection(),
                  const SizedBox(height: 24),
                  _buildProgressSection(),
                  const SizedBox(height: 24),
                  _buildAgentSection(),
                  const SizedBox(height: 24),
                  _buildChartsSection(),
                  const SizedBox(height: 24),
                  _buildLocationSection(),
                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActions(),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      backgroundColor: AppTheme.primaryBlue,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.report.imageUrls.isNotEmpty)
              CachedNetworkImage(
                imageUrl: widget.report.imageUrls.first,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.lightGray,
                  child: Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: AppTheme.mediumGray,
                  ),
                ),
              )
            else
              Container(
                color: AppTheme.primaryBlue,
                child: const Icon(
                  Icons.report_problem,
                  size: 64,
                  color: Colors.white,
                ),
              ),

            // Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),

            // Status badge
            Positioned(top: 60, right: 20, child: _buildStatusBadge()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color statusColor;
    String statusText;

    switch (widget.report.status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusText = 'In Progress';
        break;
      case 'resolved':
        statusColor = Colors.green;
        statusText = 'Resolved';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejected';
        break;
      default:
        statusColor = AppTheme.mediumGray;
        statusText = 'Submitted';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.report.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGray,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildInfoChip(
              Icons.category,
              widget.report.category,
              AppTheme.primaryBlue,
            ),
            if (widget.report.isUrgent)
              _buildInfoChip(Icons.priority_high, 'Urgent', Colors.red),
            _buildInfoChip(
              Icons.flag,
              widget.report.priority.toUpperCase(),
              _getPriorityColor(widget.report.priority),
            ),
            _buildInfoChip(
              Icons.access_time,
              _formatDate(widget.report.createdAt),
              AppTheme.mediumGray,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.report.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.darkGray,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVotingSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.how_to_vote, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Community Votes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildVoteButton(
                    icon: Icons.thumb_up,
                    label: 'Support',
                    count: _currentUpvotes,
                    color: Colors.green,
                    onPressed: () => _vote(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildVoteButton(
                    icon: Icons.thumb_down,
                    label: 'Oppose',
                    count: _currentDownvotes,
                    color: Colors.red,
                    onPressed: () => _vote(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.visibility, size: 16, color: AppTheme.mediumGray),
                const SizedBox(width: 4),
                Text(
                  '${widget.report.viewCount} views',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
                ),
                const Spacer(),
                Text(
                  'Net Score: ${_currentUpvotes - _currentDownvotes}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGray,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteButton({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: _hasVoted ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text('$label ($count)'),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(_hasVoted ? 0.3 : 0.1),
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Progress Updates',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.report.progressUpdates.isEmpty)
              Text(
                'No updates available yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mediumGray,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...widget.report.progressUpdates.asMap().entries.map(
                (entry) => _buildProgressItem(entry.value, entry.key),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String update, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              update,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.darkGray,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentSection() {
    if (widget.report.assignedAgentId == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    color: AppTheme.mediumGray,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Assignment Status',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGray,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'This issue has not been assigned to an agent yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mediumGray,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Assigned Agent',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                  child: Text(
                    widget.report.assignedAgentName
                            ?.substring(0, 2)
                            .toUpperCase() ??
                        'AG',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.report.assignedAgentName ?? 'Unknown Agent',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkGray,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 14,
                            color: AppTheme.mediumGray,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.report.assignedAgentPhone ?? 'No phone',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.mediumGray),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.email,
                            size: 14,
                            color: AppTheme.mediumGray,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.report.assignedAgentEmail ?? 'No email',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.mediumGray),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _contactAgent('phone'),
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _contactAgent('email'),
                    icon: const Icon(Icons.email, size: 18),
                    label: const Text('Email'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Analytics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: _buildVotingChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildVotingChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (_currentUpvotes + _currentDownvotes).toDouble() * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return Text(
                      'Support',
                      style: TextStyle(
                        color: AppTheme.mediumGray,
                        fontSize: 12,
                      ),
                    );
                  case 1:
                    return Text(
                      'Oppose',
                      style: TextStyle(
                        color: AppTheme.mediumGray,
                        fontSize: 12,
                      ),
                    );
                  case 2:
                    return Text(
                      'Views',
                      style: TextStyle(
                        color: AppTheme.mediumGray,
                        fontSize: 12,
                      ),
                    );
                  default:
                    return const Text('');
                }
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(color: AppTheme.mediumGray, fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: _currentUpvotes.toDouble(),
                color: Colors.green,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: _currentDownvotes.toDouble(),
                color: Colors.red,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: (widget.report.viewCount / 10)
                    .toDouble(), // Scale down for better visualization
                color: AppTheme.primaryBlue,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Location',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.report.address,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.darkGray),
            ),
            const SizedBox(height: 8),
            Text(
              'Lat: ${widget.report.latitude.toStringAsFixed(6)}, Lng: ${widget.report.longitude.toStringAsFixed(6)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: "share_fab",
          onPressed: () => _shareReport(),
          backgroundColor: AppTheme.primaryBlue,
          child: const Icon(Icons.share, color: Colors.white),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: "report_fab",
          onPressed: () => _reportIssue(),
          backgroundColor: Colors.red,
          child: const Icon(Icons.flag, color: Colors.white),
        ),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return AppTheme.mediumGray;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  void _vote(bool isUpvote) {
    if (_hasVoted) return;

    setState(() {
      if (isUpvote) {
        _currentUpvotes++;
      } else {
        _currentDownvotes++;
      }
      _hasVoted = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isUpvote
              ? 'Vote recorded - Supporting this issue'
              : 'Vote recorded - Opposing this issue',
        ),
        backgroundColor: isUpvote ? Colors.green : Colors.red,
      ),
    );
  }

  void _contactAgent(String method) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          method == 'phone'
              ? 'Opening phone dialer...'
              : 'Opening email client...',
        ),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  void _shareReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report link copied to clipboard'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  void _reportIssue() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report This Issue'),
        content: const Text(
          'Are you sure you want to report this as inappropriate or spam?',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report submitted for review'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Report', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
