// presentation/screens/report/enhanced_report_detail_screen.dart
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/models/evidence_model.dart';
import '../../../data/models/report_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/comments_provider.dart';
import '../../providers/report_provider.dart';

class EnhancedReportDetailScreen extends StatefulWidget {
  final ReportModel report;

  const EnhancedReportDetailScreen({super.key, required this.report});

  @override
  State<EnhancedReportDetailScreen> createState() =>
      _EnhancedReportDetailScreenState();
}

class _EnhancedReportDetailScreenState
    extends State<EnhancedReportDetailScreen> {
  int _currentUpvotes = 0;
  int _currentDownvotes = 0;
  int _currentViews = 0;
  bool? _userCurrentChoice; // true=support, false=oppose, null=none
  List<EvidenceModel> _evidence = const [];

  @override
  void initState() {
    super.initState();
    _currentUpvotes = widget.report.upvotes;
    _currentDownvotes = widget.report.downvotes;
    _currentViews = widget.report.viewCount;
    // Load current user's vote
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final rp = Provider.of<ReportProvider>(context, listen: false);
      final uid = auth.currentUser?.id;
      if (uid != null) {
        final v = rp.getUserVoteForReport(widget.report.id, uid);
        setState(() => _userCurrentChoice = v?.isUpvote);
      }
      // Load evidence list for this report
      setState(() => _evidence = rp.getEvidenceForReport(widget.report.id));
    });

    // Increment view count once when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Optimistically update UI
      setState(() {
        _currentViews = _currentViews + 1;
      });
      // Update provider/state (and persist if needed)
      try {
        final rp = Provider.of<ReportProvider>(context, listen: false);
        rp.incrementViewCount(widget.report.id);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final rp = Provider.of<ReportProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isFollowed = rp.isFollowed(widget.report.id);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, isFollowed, () async {
            if (!auth.isAuthenticated) {
              context.push('/sign-in?from=/home');
              return;
            }
            await rp.toggleFollow(widget.report.id);
            if (!mounted) return;
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  rp.isFollowed(widget.report.id)
                      ? 'Following report'
                      : 'Unfollowed report',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }),
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
                  _buildCommentsSection(),
                  const SizedBox(height: 24),
                  _buildEvidenceSection(),
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

  Widget _buildAppBar(
    BuildContext context,
    bool isFollowed,
    Future<void> Function() onToggleFollow,
  ) {
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
                  child: const Icon(
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
            // Follow button
            Positioned(
              top: 60,
              right: 20 + 120, // offset from status badge
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black45,
                  foregroundColor: Colors.white,
                ),
                onPressed: onToggleFollow,
                icon: Icon(
                  isFollowed ? Icons.bookmark : Icons.bookmark_outline,
                  size: 18,
                ),
                label: Text(isFollowed ? 'Following' : 'Follow'),
              ),
            ),
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
            color: Colors.black.withValues(alpha: 0.2),
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
  color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
  border: Border.all(color: color.withValues(alpha: 0.3)),
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
                const Icon(
                  Icons.description,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
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
                const Icon(
                  Icons.how_to_vote,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
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
                    selected: _userCurrentChoice == true,
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
                    selected: _userCurrentChoice == false,
                    onPressed: () => _onOpposePressed(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.visibility,
                  size: 16,
                  color: AppTheme.mediumGray,
                ),
                const SizedBox(width: 4),
                Text(
                  '$_currentViews views',
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

  Future<void> _onOpposePressed() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      final from = '/report-detail/${widget.report.id}';
      context.push('/sign-in?from=$from');
      return;
    }

    String? reason;
    String? imageBase64;
    bool markFake = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final reasonController = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.report_gmailerrorred, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'Oppose with evidence',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason (optional)',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 2,
                    maxLines: 4,
                    onChanged: (v) => reason = v,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final img = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 75,
                          );
                          if (img != null) {
                            final bytes = await img.readAsBytes();
                            setSheetState(
                              () => imageBase64 = base64Encode(bytes),
                            );
                          }
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Add photo'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            final picker = ImagePicker();
                            final img = await picker.pickImage(
                              source: ImageSource.camera,
                              imageQuality: 75,
                            );
                            if (img != null) {
                              final bytes = await img.readAsBytes();
                              setSheetState(
                                () => imageBase64 = base64Encode(bytes),
                              );
                            }
                          } catch (e) {
                            // Graceful fallback when camera isn't available
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Camera not available on this device',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('Take photo'),
                      ),
                      const SizedBox(width: 12),
                      if (imageBase64 != null)
                        const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Switch(
                        value: markFake,
                        onChanged: (v) => setSheetState(() => markFake = v),
                      ),
                      const SizedBox(width: 8),
                      const Text('Report this as fake'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop('submit'),
                          child: const Text('Submit Oppose'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    ).then((value) async {
      if (value == 'submit') {
        // Record the oppose vote and save evidence
        final rp = Provider.of<ReportProvider>(context, listen: false);
        final user = auth.currentUser!;
        await rp.voteOnReport(
          reportId: widget.report.id,
          userId: user.id,
          isUpvote: false,
          voteWeight: user.voteWeight,
          reason: reason,
        );

        await rp.addEvidence(
          EvidenceModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            reportId: widget.report.id,
            userId: user.id,
            reason: reason,
            imageBase64: imageBase64,
            markedAsFake: markFake,
            createdAt: DateTime.now(),
          ),
        );

        final updated = rp.getReportById(widget.report.id);
        if (updated != null && mounted) {
          setState(() {
            _currentUpvotes = updated.upvotes;
            _currentDownvotes = updated.downvotes;
            _userCurrentChoice = false;
            _evidence = rp.getEvidenceForReport(widget.report.id);
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              markFake
                  ? 'Opposed with evidence and reported as fake'
                  : 'Opposed with evidence submitted',
            ),
          ),
        );
      }
    });
  }

  Widget _buildVoteButton({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    bool selected = false,
    required VoidCallback onPressed,
  }) {
  final bg = selected ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.1);
  final border = selected ? color : color.withValues(alpha: 0.5);
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color),
      label: Text('$label ($count)', style: TextStyle(color: color)),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: bg,
        foregroundColor: color,
        side: BorderSide(color: border),
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
                const Icon(
                  Icons.timeline,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
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
            else ...[
              // Mini progress chart showing each step as a bar
              SizedBox(
                height: 160,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 ||
                                idx >= widget.report.progressUpdates.length) {
                              return const SizedBox.shrink();
                            }
                            final label = 'S${idx + 1}';
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                label,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: List.generate(
                      widget.report.progressUpdates.length,
                      (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: (i + 1).toDouble(),
                              color: AppTheme.primaryBlue,
                              width: 14,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      },
                    ),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.black87,
                        tooltipPadding: const EdgeInsets.all(8),
                        getTooltipItem: (group, groupIdx, rod, rodIdx) {
                          final step = group.x;
                          final text = widget.report.progressUpdates[step];
                          return BarTooltipItem(
                            text,
                            const TextStyle(color: Colors.white, fontSize: 12),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Line chart (sparkline) to visualize progression across steps
              SizedBox(
                height: 140,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 ||
                                idx >= widget.report.progressUpdates.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'S${idx + 1}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => Colors.black87,
                        getTooltipItems: (spots) {
                          return spots.map((s) {
                            final idx = s.x.toInt();
                            final text =
                                (idx >= 0 &&
                                    idx < widget.report.progressUpdates.length)
                                ? widget.report.progressUpdates[idx]
                                : '';
                            return LineTooltipItem(
                              text,
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        color: AppTheme.primaryBlue,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        spots: List.generate(
                          widget.report.progressUpdates.length,
                          (i) => FlSpot(i.toDouble(), (i + 1).toDouble()),
                        ),
                      ),
                    ],
                    minY: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Removed the text-based progress item renderer in favor of charts.

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
                  const Icon(
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
                const Icon(Icons.person, color: AppTheme.primaryBlue, size: 20),
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
                  backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  child: Text(
                    widget.report.assignedAgentName
                            ?.substring(0, 2)
                            .toUpperCase() ??
                        'AG',
                    style: const TextStyle(
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
                          const Icon(
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
                          const Icon(
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
                const Icon(
                  Icons.bar_chart,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
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
    final viewsScaled = _currentViews / 10.0; // scale for visualization
    double maxVal = _currentUpvotes.toDouble();
    if (_currentDownvotes.toDouble() > maxVal) {
      maxVal = _currentDownvotes.toDouble();
    }
    if (viewsScaled > maxVal) maxVal = viewsScaled;
    final maxY = maxVal == 0 ? 5.0 : maxVal * 1.3;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return const Text(
                      'Support',
                      style: TextStyle(
                        color: AppTheme.mediumGray,
                        fontSize: 12,
                      ),
                    );
                  case 1:
                    return const Text(
                      'Oppose',
                      style: TextStyle(
                        color: AppTheme.mediumGray,
                        fontSize: 12,
                      ),
                    );
                  case 2:
                    return const Text(
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
                  style: const TextStyle(
                    color: AppTheme.mediumGray,
                    fontSize: 10,
                  ),
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
                toY: viewsScaled,
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

  Widget _buildEvidenceSection() {
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
                const Icon(
                  Icons.fact_check,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Submitted Evidence',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_evidence.length}',
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_evidence.isEmpty)
              Text(
                'No evidence submitted yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mediumGray,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Column(
                children: _evidence.map((e) => _buildEvidenceTile(e)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceTile(EvidenceModel e) {
    Widget leading;
    if (e.imageBase64 != null && e.imageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(e.imageBase64!);
        leading = ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(bytes, width: 56, height: 56, fit: BoxFit.cover),
        );
      } catch (_) {
        leading = const CircleAvatar(child: Icon(Icons.image_not_supported));
      }
    } else {
      leading = const CircleAvatar(child: Icon(Icons.description_outlined));
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final rp = Provider.of<ReportProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.reason?.isNotEmpty == true
                            ? e.reason!
                            : 'No reason provided',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (e.markedAsFake)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Marked Fake',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, h:mm a').format(e.createdAt),
                  style: const TextStyle(
                    color: AppTheme.mediumGray,
                    fontSize: 11,
                  ),
                ),
                if (auth.isAdmin) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Remove evidence?'),
                              content: const Text(
                                'This will permanently remove the selected evidence.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text(
                                    'Remove',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await rp.removeEvidence(widget.report.id, e.id);
                            if (mounted) {
                              setState(() {
                                _evidence = rp.getEvidenceForReport(
                                  widget.report.id,
                                );
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Evidence removed'),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(
                          Icons.delete,
                          size: 16,
                          color: Colors.red,
                        ),
                        label: const Text('Remove'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () async {
                          await rp.setEvidenceMarkedFake(
                            widget.report.id,
                            e.id,
                            !e.markedAsFake,
                          );
                          if (mounted) {
                            setState(() {
                              _evidence = rp.getEvidenceForReport(
                                widget.report.id,
                              );
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  !e.markedAsFake
                                      ? 'Marked as fake'
                                      : 'Unmarked as fake',
                                ),
                              ),
                            );
                          }
                        },
                        icon: Icon(
                          e.markedAsFake ? Icons.remove_done : Icons.verified,
                          size: 16,
                          color: e.markedAsFake
                              ? AppTheme.mediumGray
                              : Colors.red,
                        ),
                        label: Text(
                          e.markedAsFake ? 'Unmark Fake' : 'Mark Fake',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
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
                const Icon(
                  Icons.location_on,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
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

  Widget _buildCommentsSection() {
    return Consumer2<AuthProvider, CommentsProvider>(
      builder: (context, auth, comments, child) {
        final reportId = widget.report.id;
        final list = comments.getComments(reportId);
        final controller = TextEditingController();
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.comment,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Comments',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGray,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (list.isEmpty)
                  Text(
                    'Be the first to comment.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ...list.map((c) => _buildCommentTile(c, auth, comments)),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'Write a comment…',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        minLines: 1,
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (!auth.isAuthenticated) {
                          context.push('/sign-in?from=/home');
                          return;
                        }
                        final text = controller.text.trim();
                        if (text.isEmpty) return;
                        final comment = CommentModel(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          userId: auth.currentUser?.id ?? 'anon',
                          reportId: widget.report.id,
                          content: text,
                          createdAt: DateTime.now(),
                          author: auth.currentUser,
                        );
                        await comments.addComment(comment);
                        controller.clear();
                      },
                      child: const Text('Post'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentTile(
    CommentModel c,
    AuthProvider auth,
    CommentsProvider comments,
  ) {
    final userId = auth.currentUser?.id ?? 'anon';
    final isUpvoted = comments.isCommentUpvoted(c.id, userId);
    final upvotes = comments.upvoteCount(c.id);
    final isSpam = comments.isSpam(c.id);
    final isOfficial = comments.isOfficial(c.id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            child: Text(
              (c.author?.name ?? 'U').substring(0, 1).toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      c.author?.name ?? 'User',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    if (isOfficial)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Official Response',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      DateFormat('MMM d, h:mm a').format(c.createdAt),
                      style: const TextStyle(
                        color: AppTheme.mediumGray,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (isSpam)
                  Text(
                    '[Flagged as spam]',
                    style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                  ),
                Text(c.content),
                const SizedBox(height: 6),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        if (!auth.isAuthenticated) {
                          context.push('/sign-in?from=/home');
                          return;
                        }
                        await comments.toggleUpvote(c.id, userId);
                      },
                      icon: Icon(
                        Icons.thumb_up,
                        size: 16,
                        color: isUpvoted ? Colors.green : AppTheme.mediumGray,
                      ),
                      label: Text('$upvotes'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () async {
                        await comments.flagSpam(c.id);
                      },
                      icon: const Icon(Icons.flag, size: 16, color: Colors.red),
                      label: const Text('Flag'),
                    ),
                    const SizedBox(width: 8),
                    if (auth.isAdmin)
                      TextButton.icon(
                        onPressed: () async {
                          await comments.markOfficial(c.id);
                        },
                        icon: const Icon(
                          Icons.verified,
                          size: 16,
                          color: Colors.green,
                        ),
                        label: const Text('Official'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _vote(bool isUpvote) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      final from = '/report-detail/${widget.report.id}';
      context.push('/sign-in?from=$from');
      return;
    }

    final rp = Provider.of<ReportProvider>(context, listen: false);
    final userId = auth.currentUser!.id;
    final current = _userCurrentChoice;

    // Call provider to toggle: same choice -> remove, different -> switch
    await rp.voteOnReport(
      reportId: widget.report.id,
      userId: userId,
      isUpvote: isUpvote,
      voteWeight: auth.currentUser!.voteWeight,
    );

    // Refresh UI from provider state
    final updated = rp.getReportById(widget.report.id);
    if (updated != null && mounted) {
      setState(() {
        _currentUpvotes = updated.upvotes;
        _currentDownvotes = updated.downvotes;
        _userCurrentChoice = (current == isUpvote) ? null : isUpvote;
      });
    }
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
