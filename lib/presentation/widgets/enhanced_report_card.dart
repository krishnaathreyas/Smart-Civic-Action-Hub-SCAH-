// presentation/widgets/enhanced_report_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/report_models.dart';

class EnhancedReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback? onTap;
  final VoidCallback? onUpvote;
  final VoidCallback? onDownvote;
  final bool showScore;
  final bool isUserReport;

  const EnhancedReportCard({
    Key? key,
    required this.report,
    this.onTap,
    this.onUpvote,
    this.onDownvote,
    this.showScore = false,
    this.isUserReport = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final netScore = report.upvotes - report.downvotes;
    final hasImage = report.imageUrls.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background Image
              if (hasImage)
                Positioned.fill(
                  child: _buildReportImage(report.imageUrls.first),
                ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),

              // Content Container
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  minHeight: 220,
                  maxHeight: 280,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: hasImage ? Colors.transparent : Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Row with Status Badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            report.title,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: hasImage
                                      ? Colors.white
                                      : AppTheme.darkGray,
                                  fontSize: 18,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Category and Priority
                    Row(
                      children: [
                        _buildCategoryChip(),
                        const SizedBox(width: 8),
                        if (report.isUrgent) _buildUrgentBadge(),
                        if (report.priority == 'high') _buildPriorityBadge(),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Description
                    Flexible(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 60),
                        child: Text(
                          report.description,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: hasImage
                                    ? Colors.white.withOpacity(0.9)
                                    : AppTheme.mediumGray,
                                height: 1.3,
                              ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Footer Row
                    Row(
                      children: [
                        // Location
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: hasImage
                                    ? Colors.white.withOpacity(0.8)
                                    : AppTheme.mediumGray,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  report.address,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: hasImage
                                            ? Colors.white.withOpacity(0.8)
                                            : AppTheme.mediumGray,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Date
                        Text(
                          _formatDate(report.createdAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: hasImage
                                    ? Colors.white.withOpacity(0.8)
                                    : AppTheme.mediumGray,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Voting Section
                    Row(
                      children: [
                        // Upvote Button
                        _buildVoteButton(
                          icon: Icons.keyboard_arrow_up,
                          count: report.upvotes,
                          onPressed: onUpvote,
                          isUpvote: true,
                        ),

                        const SizedBox(width: 16),

                        // Downvote Button
                        _buildVoteButton(
                          icon: Icons.keyboard_arrow_down,
                          count: report.downvotes,
                          onPressed: onDownvote,
                          isUpvote: false,
                        ),

                        const Spacer(),

                        // Score (only for user's own reports)
                        if (showScore && isUserReport)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: (hasImage
                                  ? Colors.white.withOpacity(0.2)
                                  : AppTheme.lightGray),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Score: $netScore',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: hasImage
                                        ? Colors.white
                                        : AppTheme.darkGray,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),

                        // View Count
                        if (!isUserReport)
                          Row(
                            children: [
                              Icon(
                                Icons.visibility,
                                size: 16,
                                color: hasImage
                                    ? Colors.white.withOpacity(0.7)
                                    : AppTheme.mediumGray,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${report.viewCount}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: hasImage
                                          ? Colors.white.withOpacity(0.7)
                                          : AppTheme.mediumGray,
                                    ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color statusColor;
    String statusText;

    switch (report.status.toLowerCase()) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
      ),
      child: Text(
        report.category,
        style: TextStyle(
          color: AppTheme.primaryBlue,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildUrgentBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'URGENT',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPriorityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'HIGH',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildVoteButton({
    required IconData icon,
    required int count,
    required VoidCallback? onPressed,
    required bool isUpvote,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: (isUpvote
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isUpvote
                ? Colors.green.withOpacity(0.3)
                : Colors.red.withOpacity(0.3)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isUpvote ? Colors.green : Colors.red),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                color: isUpvote ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportImage(String imageUrl) {
    // Check if it's an asset image or network image
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppTheme.lightGray.withOpacity(0.3),
          child: Icon(
            Icons.image_not_supported,
            color: AppTheme.mediumGray,
            size: 32,
          ),
        ),
      );
    } else {
      // Network image - for user uploaded images
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppTheme.lightGray.withOpacity(0.3),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppTheme.lightGray.withOpacity(0.3),
          child: Icon(
            Icons.image_not_supported,
            color: AppTheme.mediumGray,
            size: 32,
          ),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '${difference}d ago';
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }
}
