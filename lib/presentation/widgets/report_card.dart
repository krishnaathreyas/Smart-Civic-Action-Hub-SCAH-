// presentation/widgets/report_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/report_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../providers/report_provider.dart';
import '../providers/auth_provider.dart';

class ReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback? onTap;

  const ReportCard({Key? key, required this.report, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and urgency
              Row(
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppUtils.getStatusColor(
                        report.status,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppUtils.getStatusColor(
                          report.status,
                        ).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      report.displayStatus,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppUtils.getStatusColor(report.status),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Urgency flag
                  if (report.isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'URGENT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const SizedBox(width: 8),

                  // Time
                  Text(
                    AppUtils.getRelativeTime(report.createdAt),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Title
              Text(
                report.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGray,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                report.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mediumGray,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Category and Location
              Row(
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 16,
                    color: AppTheme.mediumGray,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    report.category,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppTheme.mediumGray,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report.address,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Images preview
              if (report.imageUrls.isNotEmpty) ...[
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: report.imageUrls.length > 3
                        ? 3
                        : report.imageUrls.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppTheme.lightGray,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            report.imageUrls[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.broken_image,
                                color: AppTheme.mediumGray,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Voting section
              Row(
                children: [
                  // Upvotes
                  _buildVoteButton(
                    context,
                    icon: Icons.thumb_up_outlined,
                    count: report.upvotes,
                    isUpvote: true,
                    report: report,
                  ),

                  const SizedBox(width: 16),

                  // Downvotes
                  _buildVoteButton(
                    context,
                    icon: Icons.thumb_down_outlined,
                    count: report.downvotes,
                    isUpvote: false,
                    report: report,
                  ),

                  const Spacer(),

                  // Weighted score
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Score: ${report.weightedScore.toStringAsFixed(1)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoteButton(
    BuildContext context, {
    required IconData icon,
    required int count,
    required bool isUpvote,
    required ReportModel report,
  }) {
    return Consumer2<ReportProvider, AuthProvider>(
      builder: (context, reportProvider, authProvider, child) {
        final userVote = reportProvider.getUserVoteForReport(report.id);
        final hasVoted = userVote != null;
        final isCurrentVoteType = hasVoted && userVote.isUpvote == isUpvote;

        return InkWell(
          onTap: report.canVote
              ? () => _handleVote(context, isUpvote, report, authProvider)
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCurrentVoteType
                  ? (isUpvote ? AppTheme.successGreen : AppTheme.errorRed)
                        .withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isCurrentVoteType
                      ? (isUpvote ? AppTheme.successGreen : AppTheme.errorRed)
                      : AppTheme.mediumGray,
                ),
                const SizedBox(width: 4),
                Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isCurrentVoteType
                        ? (isUpvote ? AppTheme.successGreen : AppTheme.errorRed)
                        : AppTheme.mediumGray,
                    fontWeight: isCurrentVoteType ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleVote(
    BuildContext context,
    bool isUpvote,
    ReportModel report,
    AuthProvider authProvider,
  ) async {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) return;

    try {
      await reportProvider.voteOnReport(
        reportId: report.id,
        isUpvote: isUpvote,
        voteWeight: user.voteWeight,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error voting: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}
