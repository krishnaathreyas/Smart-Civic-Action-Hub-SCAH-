// presentation/screens/dashboard/enhanced_dashboard_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/report_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/comments_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/report_provider.dart';
import '../../utils/department_stats_generator.dart';
import '../../widgets/department_charts.dart';
import '../../widgets/department_stacked_area_chart.dart';
import '../../widgets/enhanced_report_card.dart';
import '../../widgets/reports_trend_chart.dart';
// Using flutter_map directly for OSM rendering
import '../debug_storage_screen.dart';
import '../report/enhanced_report_detail_screen.dart';

class EnhancedDashboardScreen extends StatefulWidget {
  const EnhancedDashboardScreen({super.key});

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
  int _timeframeDays = 30; // 7, 30, 90, or 0 for All
  bool _percentStacked = false;
  Set<String> _visibleDepartments = {};
  // Saved filter chips
  static const _prefsKeySavedFilters = 'saved_filters_v1';
  List<Map<String, String>> _savedFilters = [];
  static const _prefsKeyPercent = 'trends_percent_stacked';
  static const _prefsKeyVisible = 'trends_visible_departments';
  static const _prefsKeyTimeframe = 'trends_timeframe_days';

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
  bool _filterFollowedOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load saved trends preferences
    _loadTrendPrefs();

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

  Future<void> _loadTrendPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final percent = prefs.getBool(_prefsKeyPercent);
      final visible = prefs.getStringList(_prefsKeyVisible);
      final tf = prefs.getInt(_prefsKeyTimeframe);
      if (!mounted) return;
      setState(() {
        if (percent != null) _percentStacked = percent;
        if (visible != null && visible.isNotEmpty) {
          _visibleDepartments = visible.toSet();
        }
        if (tf != null) _timeframeDays = tf;
        // Load saved filters
        final saved = prefs.getStringList(_prefsKeySavedFilters);
        if (saved != null && saved.isNotEmpty) {
          _savedFilters = saved
              .map(
                (s) => Map<String, String>.from(
                  Map<String, dynamic>.from(
                    (s.isNotEmpty) ? (jsonDecode(s) as Map) : {},
                  ),
                ),
              )
              .toList();
        }
      });
    } catch (_) {
      // ignore prefs errors silently
    }
  }

  Future<void> _saveTrendPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKeyPercent, _percentStacked);
      await prefs.setStringList(_prefsKeyVisible, _visibleDepartments.toList());
      await prefs.setInt(_prefsKeyTimeframe, _timeframeDays);
      // Save filters
      await prefs.setStringList(
        _prefsKeySavedFilters,
        _savedFilters.map((m) => jsonEncode(m)).toList(),
      );
    } catch (_) {
      // ignore prefs errors silently
    }
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

    // Filter by followed if toggled
    final reportProvider = context.read<ReportProvider>();
    if (_filterFollowedOnly) {
      filteredReports = filteredReports
          .where((r) => reportProvider.isFollowed(r.id))
          .toList();
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
                AppTheme.primaryBlue.withValues(alpha: 0.8),
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
                        onPressed: () {
                          if (authProvider.isAuthenticated) {
                            _showUserMenu(authProvider);
                          } else {
                            // Navigate to sign in; return to home after
                            context.push('/sign-in?from=/home');
                          }
                        },
                        icon: authProvider.isAuthenticated
                            ? CircleAvatar(
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                child: Text(
                                  authProvider.currentUser?.name != null &&
                                          authProvider
                                              .currentUser!
                                              .name
                                              .isNotEmpty
                                      ? authProvider.currentUser!.name
                                            .substring(0, 1)
                                            .toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.login, color: Colors.white),
                                    SizedBox(width: 6),
                                    Text(
                                      'Sign in',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
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
            color: Colors.black.withValues(alpha: 0.05),
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
                    initialValue: _selectedCategory,
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
                    initialValue: _selectedStatus,
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
            // Followed quick filter
            Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: const Text('Followed'),
                selected: _filterFollowedOnly,
                onSelected: (v) {
                  setState(() => _filterFollowedOnly = v);
                },
                selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.18),
                checkmarkColor: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _sortBy,
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
                  const Icon(
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
                        _filterFollowedOnly = false;
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
          // Skeleton loader for list
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: List.generate(
                6,
                (i) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 96,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 14,
                              width: 160,
                              color: Colors.grey.shade200,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 12,
                              width: 220,
                              color: Colors.grey.shade100,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
              // Saved filter chips row
              if (_savedFilters.isNotEmpty) ...[
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (ctx, i) {
                      final f = _savedFilters[i];
                      final title = f['title'] ?? 'Saved';
                      return InputChip(
                        label: Text(title),
                        onPressed: () {
                          setState(() {
                            _selectedCategory = f['category'] ?? 'All';
                            _selectedStatus = f['status'] ?? 'All';
                            _sortBy = f['sortBy'] ?? 'Recent';
                          });
                        },
                        onDeleted: () {
                          setState(() {
                            _savedFilters.removeAt(i);
                          });
                          _saveTrendPrefs();
                        },
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemCount: _savedFilters.length,
                  ),
                ),
                const SizedBox(height: 12),
              ],
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
                    final rp = context.read<ReportProvider>();
                    final isFollowed = rp.isFollowed(report.id);
                    final commentsProvider = context.watch<CommentsProvider>();
                    final commentCount = commentsProvider
                        .getComments(report.id)
                        .length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onLongPress: () {
                          final exists = _savedFilters.any(
                            (m) =>
                                (m['category'] ?? 'All') == _selectedCategory &&
                                (m['status'] ?? 'All') == _selectedStatus &&
                                (m['sortBy'] ?? 'Recent') == _sortBy,
                          );
                          if (exists) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Filter already saved'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }

                          final title = '$_selectedCategory · $_selectedStatus';
                          setState(() {
                            _savedFilters.add({
                              'title': title,
                              'category': _selectedCategory,
                              'status': _selectedStatus,
                              'sortBy': _sortBy,
                            });
                          });
                          _saveTrendPrefs();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Saved current filters'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: EnhancedReportCard(
                          report: report,
                          onTap: () => _openReportDetail(report),
                          isFollowed: isFollowed,
                          commentCount: commentCount,
                          onFollowToggle: () async {
                            final auth = context.read<AuthProvider>();
                            if (!auth.isAuthenticated) {
                              // Require sign in, then return to home
                              context.push('/sign-in?from=/home');
                              return;
                            }
                            await rp.toggleFollow(report.id);
                            if (!mounted) return;
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  rp.isFollowed(report.id)
                                      ? 'Following report'
                                      : 'Unfollowed report',
                                ),
                                duration: const Duration(seconds: 2),
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
                const Icon(
                  Icons.location_off,
                  size: 64,
                  color: AppTheme.errorRed,
                ),
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

        // Show map with current location and report markers
        if (locationProvider.currentPosition != null) {
          return _buildOsmMap(locationProvider, reportProvider);
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

  Widget _buildOsmMap(
    LocationProvider locationProvider,
    ReportProvider reportProvider,
  ) {
    final currentPosition = locationProvider.currentPosition!;
    final allReports = reportProvider.reports;
    final filteredReports = _getFilteredAndSortedReports(allReports);

    // Create OSM markers
    final markers = <flutter_map.Marker>[];
    // Report markers
    for (final report in filteredReports) {
      markers.add(
        flutter_map.Marker(
          point: ll.LatLng(report.latitude, report.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _openReportDetail(report),
            child: Icon(
              Icons.location_on,
              color: _getOsmMarkerColor(report.status),
              size: 36,
            ),
          ),
        ),
      );
    }
    // Current location marker
    markers.add(
      flutter_map.Marker(
        point: ll.LatLng(currentPosition.latitude, currentPosition.longitude),
        width: 40,
        height: 40,
        child: const Icon(Icons.my_location, color: Colors.blue, size: 28),
      ),
    );
    // Return FlutterMap with clustering
    return flutter_map.FlutterMap(
      options: flutter_map.MapOptions(
        initialCenter: ll.LatLng(
          currentPosition.latitude,
          currentPosition.longitude,
        ),
        initialZoom: 14,
      ),
      children: [
        flutter_map.TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.scah',
        ),
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 60,
            size: const Size(40, 40),
            markers: markers,
            builder: (context, clusterMarkers) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  clusterMarkers.length.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getOsmMarkerColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.red;
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
                const Icon(
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

        // Timeframe filter UI
        final timeframeChips = Row(
          children: [
            _buildTimeframeChip('7D', 7),
            const SizedBox(width: 8),
            _buildTimeframeChip('30D', 30),
            const SizedBox(width: 8),
            _buildTimeframeChip('90D', 90),
            const SizedBox(width: 8),
            _buildTimeframeChip('All', 0),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _timeframeDays = 30;
                  _percentStacked = false;
                  // Clear and let seeding logic repopulate on next build
                  _visibleDepartments.clear();
                });
                _saveTrendPrefs();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
            ),
          ],
        );

        // Apply timeframe filter
        final now = DateTime.now();
        final reportsInTimeframe = _timeframeDays == 0
            ? filteredReports
            : filteredReports
                  .where(
                    (r) => r.createdAt.isAfter(
                      now.subtract(Duration(days: _timeframeDays)),
                    ),
                  )
                  .toList();

        // Generate department statistics from timeframe-filtered reports
        final departmentStats = DepartmentStatsGenerator.generateStats(
          reportsInTimeframe,
        );
        final summaryStats = DepartmentStatsGenerator.generateSummaryStats(
          reportsInTimeframe,
        );

        // Seed visible departments on first render (if empty)
        if (_visibleDepartments.isEmpty && departmentStats.isNotEmpty) {
          _visibleDepartments = departmentStats
              .map((d) => d.department)
              .toSet();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeframe selector
              timeframeChips,
              const SizedBox(height: 16),

              // Reports Trend chart
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reports Trend',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Daily report counts over selected timeframe',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 240,
                      child: ReportsTrendChart(
                        reports: reportsInTimeframe,
                        timeframeDays: _timeframeDays,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Department Contribution Stacked Area
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Department Contribution Over Time',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGray,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Legend + percent toggle
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ...departmentStats.map((d) {
                          final selected = _visibleDepartments.contains(
                            d.department,
                          );
                          return FilterChip(
                            label: Text(d.department.split(' ').first),
                            selected: selected,
                            onSelected: (_) {
                              setState(() {
                                if (selected) {
                                  _visibleDepartments.remove(d.department);
                                } else {
                                  _visibleDepartments.add(d.department);
                                }
                                if (_visibleDepartments.isEmpty) {
                                  // Avoid empty -> show all
                                  _visibleDepartments = departmentStats
                                      .map((x) => x.department)
                                      .toSet();
                                }
                              });
                              _saveTrendPrefs();
                            },
                            selectedColor: d.color.withValues(alpha: 0.18),
                            backgroundColor: d.color.withValues(alpha: 0.08),
                            checkmarkColor: d.color,
                          );
                        }),
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: _percentStacked,
                              onChanged: (v) {
                                setState(() => _percentStacked = v);
                                _saveTrendPrefs();
                              },
                            ),
                            const SizedBox(width: 4),
                            const Text('Percent'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stacked area of daily reports by department',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 260,
                      child: DepartmentStackedAreaChart(
                        reports: reportsInTimeframe,
                        timeframeDays: _timeframeDays,
                        visibleDepartments: _visibleDepartments,
                        percentMode: _percentStacked,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

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
            color: Colors.grey.withValues(alpha: 0.1),
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
                  color: color.withValues(alpha: 0.1),
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
          const Icon(Icons.report_off, size: 64, color: AppTheme.mediumGray),
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
          const Icon(
            Icons.filter_list_off,
            size: 64,
            color: AppTheme.mediumGray,
          ),
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

  Widget _buildTimeframeChip(String label, int days) {
    final selected = _timeframeDays == days;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : AppTheme.darkGray,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: selected,
      onSelected: (_) {
        setState(() => _timeframeDays = days);
        _saveTrendPrefs();
      },
      selectedColor: AppTheme.primaryBlue,
      backgroundColor: Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppTheme.primaryBlue : AppTheme.mediumGray,
        ),
      ),
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
