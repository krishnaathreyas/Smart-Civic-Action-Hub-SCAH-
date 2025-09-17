// presentation/screens/onboarding/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // App Logo and Name
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_city,
                  color: Colors.white,
                  size: 60,
                ),
              ),

              const SizedBox(height: 24),

              // App Name
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 48,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 8),

              // Tagline
              Text(
                AppConstants.appTagline,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.mediumGray,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Feature Highlights
              _buildFeatureCard(
                context,
                icon: Icons.report_problem,
                title: 'Report Issues',
                description: 'Quickly report civic problems in your community',
                color: AppTheme.primaryBlue,
              ),

              const SizedBox(height: 16),

              _buildFeatureCard(
                context,
                icon: Icons.people,
                title: 'Community Power',
                description:
                    'Your neighbors validate and prioritize reports together',
                color: AppTheme.successGreen,
              ),

              const SizedBox(height: 16),

              _buildFeatureCard(
                context,
                icon: Icons.trending_up,
                title: 'Real Impact',
                description:
                    'See your reports get resolved by local authorities',
                color: AppTheme.warningOrange,
              ),

              const Spacer(),

              // Get Started Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.go('/permissions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppTheme.primaryBlue.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Already have account
              TextButton(
                onPressed: () {
                  // TODO: Implement sign in functionality
                  context.go('/permissions');
                },
                child: Text(
                  'Already have an account? Sign In',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
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
    );
  }
}
