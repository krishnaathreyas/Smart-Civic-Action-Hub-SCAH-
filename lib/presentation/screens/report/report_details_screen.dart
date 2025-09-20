// presentation/screens/report/report_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load additional details if needed
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, reportProvider, child) {
        final report = reportProvider.getReportById(widget.reportId);

        if (report == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Report Details')),
            body: const Center(child: Text('Report not found')),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    report.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  background: report.imageUrls.isNotEmpty
                      ? Image.network(
                          report.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.primaryBlue,
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.white,
                                size: 64,
                              ),
                            );
                          },
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.description,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ),

              // Report content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category + Timestamp
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            label: Text(
                              report.category,
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: AppTheme.primaryBlue,
                          ),
                          Text(
                            AppUtils.formatDate(report.createdAt),
                            style: const TextStyle(
                              color: AppTheme.mediumGray,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        report.description,
                        style: const TextStyle(fontSize: 16, height: 1.4),
                      ),
                      const SizedBox(height: 24),

                      // Location
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 20,
                            color: AppTheme.primaryBlue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              report.address.isNotEmpty
                                  ? report.address
                                  : 'No location provided',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Reporter details
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          final user = authProvider.currentUser;
                          return Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppTheme.primaryBlue,
                                backgroundImage: user?.profileImageUrl != null
                                    ? NetworkImage(user!.profileImageUrl!)
                                    : null,
                                child: user?.profileImageUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                user?.name ?? "Anonymous",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Upvote report
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(
                              Icons.thumb_up,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Upvote",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Share report
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryBlue,
                              side: const BorderSide(
                                color: AppTheme.primaryBlue,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.share),
                            label: const Text("Share"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
