// presentation/screens/dashboard/enhanced_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/report_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/report_provider.dart';
import '../../utils/department_stats_generator.dart';
import '../../widgets/department_charts.dart';
import '../../widgets/enhanced_report_card.dart';
import '../../widgets/safe_google_map.dart';
import '../debug_storage_screen.dart';
import '../report/enhanced_report_detail_screen.dart';

class EnhancedDashboardScreen extends StatefulWidget {
  const EnhancedDashboardScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedDashboardScreen> createState() =>
      _EnhancedDashboardScreenState();
}

class _EnhancedDashboardScreenState extends State<EnhancedDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  String _sortBy = 'Recent';

  final List<String> _categories = [
    'All',
    'Infrastructure',
    'Safety',
    'Environment',
    'Transportation',
    'Public Services',
  ];

  final List<String> _statuses = [
    'All',
    'Pending',
    'In Progress',
    'Resolved',
    'Rejected',
  ];

  final List<String> _sortOptions = ['Recent', 'Votes', 'Priority', 'Status'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize location and reports on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reportProvider = Provider.of<ReportProvider>(
        context,
        listen: false,
      );
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );

      // Load reports if not already loaded
      if (mounted) reportProvider.loadReports();

      // Get current location
      if (mounted) locationProvider.getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Check if any filters are active
  bool get _hasActiveFilters =>
      _selectedCategory != 'All' || _selectedStatus != 'All';

  // Filter and sort reports based on selected criteria
  List<ReportModel> _getFilteredAndSortedReports(List<ReportModel> reports) {
    List<ReportModel> filteredReports = reports;

    // Filter by category
    if (_selectedCategory != 'All') {
      filteredReports = filteredReports.where((report) {
        return report.category.toLowerCase() == _selectedCategory.toLowerCase();
      }).toList();
    }

    // Filter by status
    if (_selectedStatus != 'All') {
      filteredReports = filteredReports.where((report) {
        return report.status.toLowerCase() == _selectedStatus.toLowerCase();
      }).toList();
    }

    // Sort reports
    switch (_sortBy) {
      case 'Recent':
        filteredReports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Votes':
        filteredReports.sort((a, b) => b.upvotes.compareTo(a.upvotes));
        break;
      case 'Priority':
        // Sort by priority (High > Medium > Low)
        filteredReports.sort((a, b) {
          const priorityOrder = {'High': 3, 'Medium': 2, 'Low': 1};
          final aPriority = priorityOrder[a.priority] ?? 0;
          final bPriority = priorityOrder[b.priority] ?? 0;
          return bPriority.compareTo(aPriority);
        });
        break;
      case 'Status':
        // Sort by status (Pending > In Progress > Resolved > Rejected)
        filteredReports.sort((a, b) {
          const statusOrder = {
            'Pending': 4,
            'In Progress': 3,
            'Resolved': 2,
            'Rejected': 1,
          };
          final aStatus = statusOrder[a.status] ?? 0;
          final bStatus = statusOrder[b.status] ?? 0;
          return bStatus.compareTo(aStatus);
        });
        break;
    }

    return filteredReports;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildAppBar(authProvider),
            _buildStatsSection(),
            _buildFiltersSection(),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [_buildReportsTab(), _buildMapTab(), _buildTrendsTab()],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAppBar(AuthProvider authProvider) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryBlue,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryBlue,
                AppTheme.primaryBlue.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                            Text(
                              authProvider.currentUser?.name ?? 'Citizen',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showUserMenu(authProvider),
                        icon: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            authProvider.currentUser?.name != null &&
                                    authProvider.currentUser!.name.isNotEmpty
                                ? authProvider.currentUser!.name
                                      .substring(0, 1)
                                      .toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(icon: Icon(Icons.list), text: 'Reports'),
          Tab(icon: Icon(Icons.map), text: 'Map'),
          Tab(icon: Icon(Icons.trending_up), text: 'Trends'),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Consumer<ReportProvider>(
          builder: (context, reportProvider, child) {
            final reports = reportProvider.reports;
            final resolvedCount = reports
                .where((r) => r.status == 'resolved')
                .length;
            final inProgressCount = reports
                .where((r) => r.status == 'in_progress')
                .length;

            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Reports',
                    reports.length.toString(),
                    Icons.report,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Resolved',
                    resolvedCount.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'In Progress',
                    inProgressCount.toString(),
                    Icons.hourglass_empty,
                    Colors.orange,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: _categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: _statuses
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _sortBy,
              decoration: const InputDecoration(
                labelText: 'Sort By',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: _sortOptions
                  .map(
                    (option) =>
                        DropdownMenuItem(value: option, child: Text(option)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _sortBy = value;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            // Clear filters button and active filters indicator
            if (_hasActiveFilters) ...[
              Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filters active',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = 'All';
                        _selectedStatus = 'All';
                        _sortBy = 'Recent';
                      });
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    return Consumer<ReportProvider>(
      builder: (context, reportProvider, child) {
        if (reportProvider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading reports...'),
              ],
            ),
          );
        }

        final allReports = reportProvider.reports;
        if (allReports.isEmpty) {
          return _buildEmptyState();
        }

        // Apply filters and sorting
        final filteredReports = _getFilteredAndSortedReports(allReports);

        if (filteredReports.isEmpty) {
          return _buildNoResultsState();
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show filter results count
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Showing ${filteredReports.length} of ${allReports.length} reports',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ),
              // Reports list
              Expanded(
                child: ListView.builder(
                  itemCount: filteredReports.length,
                  itemBuilder: (context, index) {
                    final report = filteredReports[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: EnhancedReportCard(
                        report: report,
                        onTap: () => _openReportDetail(report),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapTab() {
    return Consumer2<LocationProvider, ReportProvider>(
      builder: (context, locationProvider, reportProvider, child) {
        if (locationProvider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Getting your location...'),
              ],
            ),
          );
        }

        if (locationProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off, size: 64, color: AppTheme.errorRed),
                const SizedBox(height: 16),
                Text(
                  'Location Error',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.darkGray,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  locationProvider.error ?? 'Unable to get location',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.mediumGray),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => locationProvider.getCurrentLocation(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Show Google Maps with current location and report markers
        if (locationProvider.currentPosition != null) {
          return _buildGoogleMap(locationProvider, reportProvider);
        }

        // Default fallback
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map, size: 64, color: AppTheme.mediumGray),
              SizedBox(height: 16),
              Text('Map loading...'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGoogleMap(
    LocationProvider locationProvider,
    ReportProvider reportProvider,
  ) {
    final currentPosition = locationProvider.currentPosition!;
    final allReports = reportProvider.reports;
    final filteredReports = _getFilteredAndSortedReports(allReports);

    // Create markers for reports
    final Set<Marker> markers = {
      // Current location marker
      Marker(
        markerId: const MarkerId('current_location'),
        position: LatLng(currentPosition.latitude, currentPosition.longitude),
        infoWindow: InfoWindow(
          title: 'Your Location',
          snippet: locationProvider.currentAddress ?? 'Current position',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
      // Report markers (filtered)
      ...filteredReports.map(
        (report) => Marker(
          markerId: MarkerId(report.id),
          position: LatLng(report.latitude, report.longitude),
          infoWindow: InfoWindow(
            title: report.title,
            snippet: '${report.category} • ${report.status.toUpperCase()}',
            onTap: () => _openReportDetail(report),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getMarkerColor(report.status),
          ),
        ),
      ),
    };

    return SafeGoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(currentPosition.latitude, currentPosition.longitude),
        zoom: 14.0,
      ),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
    );
  }

  double _getMarkerColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return BitmapDescriptor.hueGreen;
      case 'in_progress':
        return BitmapDescriptor.hueOrange;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  Widget _buildTrendsTab() {
    return Consumer<ReportProvider>(
      builder: (context, reportProvider, child) {
        final allReports = reportProvider.reports;
        final filteredReports = _getFilteredAndSortedReports(allReports);

        if (filteredReports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 64,
                  color: AppTheme.mediumGray,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Data Available',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.darkGray,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Submit some reports to see department analytics',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.mediumGray),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Generate department statistics from actual reports
        final departmentStats = DepartmentStatsGenerator.generateStats(
          filteredReports,
        );
        final summaryStats = DepartmentStatsGenerator.generateSummaryStats(
          filteredReports,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards Section
              Text(
                'Department Performance Overview',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGray,
                ),
              ),
              const SizedBox(height: 16),

              // Summary Statistics Cards
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Reports',
                      '${summaryStats['totalReports']}',
                      'Across all departments',
                      Icons.assignment,
                      AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'Overall Resolution',
                      '${summaryStats['overallResolutionRate'].toInt()}%',
                      'Success rate',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Best Performer',
                      summaryStats['bestDepartment']?.department
                              .split(' ')
                              .first ??
                          'N/A',
                      '${summaryStats['bestDepartment']?.resolutionRate.toInt() ?? 0}% resolved',
                      Icons.star,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'Avg Response',
                      '${summaryStats['avgResponseTime'].toStringAsFixed(1)} days',
                      'Resolution time',
                      Icons.schedule,
                      AppTheme.mediumGray,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Charts Section
              if (departmentStats.isNotEmpty)
                DepartmentChartsSection(departmentStats: departmentStats)
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'No department data available yet',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mediumGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.darkGray,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.report_off, size: 64, color: AppTheme.mediumGray),
          const SizedBox(height: 16),
          Text(
            'No Reports Found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.darkGray,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to report an issue in your community',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.mediumGray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off, size: 64, color: AppTheme.mediumGray),
          const SizedBox(height: 16),
          Text(
            'No Matching Reports',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.darkGray,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters to see more results',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.mediumGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedCategory = 'All';
                _selectedStatus = 'All';
                _sortBy = 'Recent';
              });
            },
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => context.push('/submit-report'),
      backgroundColor: AppTheme.primaryBlue,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('New Report', style: TextStyle(color: Colors.white)),
    );
  }

  void _openReportDetail(ReportModel report) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EnhancedReportDetailScreen(report: report),
      ),
    );
  }

  void _showUserMenu(AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                context.pop();
                context.push('/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                context.pop();
                // Navigate to settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
              onTap: () {
                context.pop();
                // Navigate to help
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report, color: Colors.orange),
              title: const Text('Debug Storage'),
              onTap: () {
                context.pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DebugStorageScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                context.pop();
                authProvider.signOut();
                context.go('/sign-in');
              },
            ),
          ],
        ),
      ),
    );
  }
}
