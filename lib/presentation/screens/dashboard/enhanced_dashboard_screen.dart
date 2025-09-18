// presentation/screens/dashboard/enhanced_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/demo/demo_reports.dart';
import '../../../data/models/report_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/enhanced_report_card.dart';
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
  List<ReportModel> _filteredReports = [];
  List<ReportModel> _allReports = [];

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
    _allReports = DemoReports.getDemoReports();
    _filteredReports = _allReports;
    _applyFilters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Reports',
                _allReports.length.toString(),
                Icons.report,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Resolved',
                _getResolvedCount().toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'In Progress',
                _getInProgressCount().toString(),
                Icons.hourglass_empty,
                Colors.orange,
              ),
            ),
          ],
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.darkGray,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildFilterDropdown(
                    'Category',
                    _selectedCategory,
                    _categories,
                    (value) => setState(() {
                      _selectedCategory = value!;
                      _applyFilters();
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFilterDropdown(
                    'Status',
                    _selectedStatus,
                    _statuses,
                    (value) => setState(() {
                      _selectedStatus = value!;
                      _applyFilters();
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFilterDropdown(
                    'Sort By',
                    _sortBy,
                    _sortOptions,
                    (value) => setState(() {
                      _sortBy = value!;
                      _applyFilters();
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.darkGray),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: AppTheme.mediumGray,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    if (_filteredReports.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView.builder(
        itemCount: _filteredReports.length,
        itemBuilder: (context, index) {
          final report = _filteredReports[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: EnhancedReportCard(
              report: report,
              onTap: () => _openReportDetail(report),
            ),
          );
        },
      ),
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
    final reports = _filteredReports;

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
      // Report markers
      ...reports.map(
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

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(currentPosition.latitude, currentPosition.longitude),
        zoom: 14.0,
      ),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      compassEnabled: true,
      mapToolbarEnabled: true,
      zoomControlsEnabled: true,
      onMapCreated: (GoogleMapController controller) {
        // Map controller setup if needed
      },
    );
  }

  double _getMarkerColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return BitmapDescriptor.hueGreen;
      case 'in_progress':
        return BitmapDescriptor.hueOrange;
      case 'pending':
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTrendCard(
            'Most Active Category',
            'Infrastructure',
            '${_getCategoryCount('Infrastructure')} reports',
            Icons.construction,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildTrendCard(
            'Resolution Rate',
            '${(_getResolvedCount() / _allReports.length * 100).toInt()}%',
            'This month',
            Icons.trending_up,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildTrendCard(
            'Average Response Time',
            '2.3 days',
            'Government agencies',
            Icons.schedule,
            AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.mediumGray),
                ),
                const SizedBox(height: 4),
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
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 80, color: AppTheme.mediumGray),
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
            'Try adjusting your filters or create a new report.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.mediumGray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      heroTag: "dashboard_fab",
      onPressed: () => context.push('/report-submission'),
      backgroundColor: AppTheme.primaryBlue,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'New Report',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _applyFilters() {
    setState(() {
      _filteredReports = _allReports.where((report) {
        // Category filter
        if (_selectedCategory != 'All' &&
            report.category != _selectedCategory) {
          return false;
        }

        // Status filter
        if (_selectedStatus != 'All') {
          String normalizedStatus = _selectedStatus.toLowerCase().replaceAll(
            ' ',
            '_',
          );
          if (report.status != normalizedStatus) {
            return false;
          }
        }

        return true;
      }).toList();

      // Apply sorting
      switch (_sortBy) {
        case 'Recent':
          _filteredReports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'Votes':
          _filteredReports.sort(
            (a, b) =>
                (b.upvotes - b.downvotes).compareTo(a.upvotes - a.downvotes),
          );
          break;
        case 'Priority':
          _filteredReports.sort(
            (a, b) => _priorityValue(
              b.priority,
            ).compareTo(_priorityValue(a.priority)),
          );
          break;
        case 'Status':
          _filteredReports.sort((a, b) => a.status.compareTo(b.status));
          break;
      }
    });
  }

  int _priorityValue(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  int _getResolvedCount() {
    return _allReports.where((report) => report.status == 'resolved').length;
  }

  int _getInProgressCount() {
    return _allReports.where((report) => report.status == 'in_progress').length;
  }

  int _getCategoryCount(String category) {
    return _allReports.where((report) => report.category == category).length;
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
