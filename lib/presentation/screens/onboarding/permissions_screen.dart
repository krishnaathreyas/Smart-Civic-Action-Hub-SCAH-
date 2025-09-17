// presentation/screens/onboarding/permissions_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_theme.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({Key? key}) : super(key: key);

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _locationGranted = false;
  bool _notificationGranted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final locationStatus = await Permission.location.status;
    final notificationStatus = await Permission.notification.status;

    if (mounted) {
      setState(() {
        _locationGranted = locationStatus.isGranted;
        _notificationGranted = notificationStatus.isGranted;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    final status = await Permission.location.request();

    if (status.isDenied) {
      _showPermissionDialog(
        title: 'Location Access Required',
        message:
            'SCAH needs location access to show nearby issues and verify your eligibility to vote on local reports.',
        onRetry: _requestLocationPermission,
      );
    } else if (status.isPermanentlyDenied) {
      _showSettingsDialog('Location');
    }

    if (mounted) {
      setState(() {
        _locationGranted = status.isGranted;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    final status = await Permission.notification.request();

    if (status.isDenied) {
      _showPermissionDialog(
        title: 'Notification Permission',
        message:
            'Stay updated on your submitted reports and community activity.',
        onRetry: _requestNotificationPermission,
      );
    } else if (status.isPermanentlyDenied) {
      _showSettingsDialog('Notifications');
    }

    if (mounted) {
      setState(() {
        _notificationGranted = status.isGranted;
        _isLoading = false;
      });
    }
  }

  void _showPermissionDialog({
    required String title,
    required String message,
    required VoidCallback onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onRetry();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionType Permission'),
        content: Text(
          'Please enable $permissionType permission in Settings to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _continue() {
    if (_locationGranted) {
      context.go('/profile-creation');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission is required to continue.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Grant Essential Permissions'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Header
              Text(
                'Grant Essential\nPermissions',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGray,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'SCAH needs a few permissions to help you make a real impact in your community.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.mediumGray,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 40),

              // Location Permission Card
              _buildPermissionCard(
                icon: Icons.location_on,
                title: 'Location Services',
                description:
                    'To identify local issues in your area and enable community-specific alerts for effective civic action.',
                isGranted: _locationGranted,
                isRequired: true,
                onTap: _locationGranted ? null : _requestLocationPermission,
              ),

              const SizedBox(height: 20),

              // Notification Permission Card
              _buildPermissionCard(
                icon: Icons.notifications,
                title: 'Notifications',
                description:
                    'To keep you updated on issue statuses, community actions, and urgent public safety alerts.',
                isGranted: _notificationGranted,
                isRequired: false,
                onTap: _notificationGranted
                    ? null
                    : _requestNotificationPermission,
              ),

              const SizedBox(height: 40),

              // Grant Permissions Button
              if (!_locationGranted || !_notificationGranted)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (!_locationGranted) {
                              await _requestLocationPermission();
                            }
                            if (!_notificationGranted) {
                              await _requestNotificationPermission();
                            }
                          },
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Grant Permissions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

              // Continue Button
              if (_locationGranted)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _continue,
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Skip Button (only for non-essential permissions)
              if (!_notificationGranted && _locationGranted)
                Center(
                  child: TextButton(
                    onPressed: _continue,
                    child: const Text(
                      'Skip Notifications',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required bool isRequired,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isGranted
              ? AppTheme.successGreen.withOpacity(0.05)
              : Colors.white,
          border: Border.all(
            color: isGranted
                ? AppTheme.successGreen.withOpacity(0.3)
                : AppTheme.mediumGray.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isGranted
                        ? AppTheme.successGreen
                        : AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isGranted ? Icons.check : icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.darkGray,
                                ),
                          ),
                          if (isRequired)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.errorRed,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Required',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isGranted ? 'Permission granted' : description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mediumGray,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
