// presentation/screens/dashboard/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_utils.dart';
import '../../providers/report_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/report_card.dart';
import '../../widgets/filter_chips.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isMapView = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    await Future.wait([
      reportProvider.loadReports(),
      locationProvider.getCurrentLocation(),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // View Toggle and Filters
          _buildTopControls(),

          // Main Content
          Expanded(child: _isMapView ? _buildMapView() : _buildListView()),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back!',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.mediumGray),
              ),
              Text(
                user?.name ?? 'Civic Citizen',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGray,
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        // Notification Icon
        Stack(
          children: [
            IconButton(
              onPressed: () {
                // TODO: Navigate to notifications
              },
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppTheme.darkGray,
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppTheme.errorRed,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '3',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),

        // Profile Icon
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.currentUser;
                return user?.profileImageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          user!.profileImageUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(Icons.person, color: Colors.white, size: 20);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopControls() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // View Toggle
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    onTap: (index) {
                      setState(() {
                        _isMapView = index == 1;
                      });
                    },
                    indicator: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.mediumGray,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(icon: Icon(Icons.list, size: 20), text: 'List View'),
                      Tab(icon: Icon(Icons.map, size: 20), text: 'Map View'),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Filter Chips
          if (!_isMapView) const FilterChips(),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return Consumer<ReportProvider>(
      builder: (context, reportProvider, child) {
        if (reportProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = reportProvider.reports;

        if (reports.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => reportProvider.loadReports(),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return ReportCard(
                report: report,
                onTap: () => context.go('/home/report-detail/${report.id}'),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    return Container(
      color: AppTheme.lightGray,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: AppTheme.mediumGray),
            SizedBox(height: 16),
            Text(
              'Map View',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppTheme.mediumGray),
            SizedBox(height: 16),
            Text(
              'No reports available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Pull down to refresh and check for new reports.',
              style: TextStyle(fontSize: 14, color: AppTheme.mediumGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => context.go('/home/create-report'),
      backgroundColor: AppTheme.primaryBlue,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
}
