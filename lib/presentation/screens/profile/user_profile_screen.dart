// presentation/screens/profile/user_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/report_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/report_provider.dart';
import '../report/enhanced_report_detail_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize location when profile loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );
      if (locationProvider.currentAddress == null) {
        locationProvider.getCurrentLocation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: Consumer2<AuthProvider, ReportProvider>(
        builder: (context, authProvider, reportProvider, child) {
          final user = authProvider.currentUser;
          if (user == null) {
            return const Center(
              child: Text('Please log in to view your profile'),
            );
          }

          final userReports = reportProvider.getReportsByUserId(user.id);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserInfo(user.name, user.email),
                const SizedBox(height: 24),
                _buildStatsSection(userReports),
                const SizedBox(height: 24),
                _buildUserReportsSection(userReports),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserInfo(String name, String email) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.green.shade100,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (user != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  // Account Details
                  _buildDetailRow(
                    'Phone Number',
                    user.phoneNumber ?? 'Not provided',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Municipal Ward', user.municipalWard),
                  const SizedBox(height: 8),
                  _buildDetailRow('Home Address', user.homeAddress),
                  const SizedBox(height: 12),
                  // Current Location Section
                  Consumer<LocationProvider>(
                    builder: (context, locationProvider, child) {
                      return Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              locationProvider.currentAddress ??
                                  'Getting current location...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontStyle:
                                    locationProvider.currentAddress == null
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                            ),
                          ),
                          if (locationProvider.isLoading)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.green.shade600,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(List<ReportModel> userReports) {
    final totalReports = userReports.length;
    final resolvedReports = userReports
        .where((r) => r.status == 'resolved')
        .length;
    final inProgressReports = userReports
        .where((r) => r.status == 'in_progress')
        .length;
    final pendingReports = userReports
        .where((r) => r.status == 'pending')
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Reports',
                    totalReports.toString(),
                    Colors.blue,
                    Icons.report,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Resolved',
                    resolvedReports.toString(),
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'In Progress',
                    inProgressReports.toString(),
                    Colors.orange,
                    Icons.pending,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Pending',
                    pendingReports.toString(),
                    Colors.red,
                    Icons.hourglass_empty,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserReportsSection(List<ReportModel> userReports) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Reports',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (userReports.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.report_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No reports submitted yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Submit your first report to help improve your community!',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: userReports.length,
            itemBuilder: (context, index) {
              final report = userReports[index];
              return _buildReportCard(report, context);
            },
          ),
      ],
    );
  }

  Widget _buildReportCard(ReportModel report, BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (report.status) {
      case 'resolved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'in_progress':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      default:
        statusColor = Colors.red;
        statusIcon = Icons.hourglass_empty;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openReportDetail(report, context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          report.status.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report.description,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report.address,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      report.category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              if (report.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: report.imageUrls.length,
                    itemBuilder: (context, imageIndex) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            report.imageUrls[imageIndex],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey.shade400,
                                  size: 24,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Submitted ${_formatDate(report.createdAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openReportDetail(ReportModel report, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedReportDetailScreen(report: report),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
