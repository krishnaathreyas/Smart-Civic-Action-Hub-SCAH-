import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/onboarding/welcome_screen.dart';
import '../presentation/screens/onboarding/permissions_screen.dart';
import '../presentation/screens/onboarding/profile_creation_screen.dart';
import '../presentation/screens/onboarding/tutorial_screen.dart';
import '../presentation/screens/dashboard/home_screen.dart';
import '../presentation/screens/report/report_submission_screen.dart';
import '../presentation/screens/report/report_detail_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/providers/auth_provider.dart';

class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final router = GoRouter(
    initialLocation: '/welcome',
    redirect: (context, state) {
      final isLoggedIn = authProvider.isAuthenticated;
      final isOnboardingComplete = authProvider.isOnboardingComplete;

      if (!isLoggedIn) {
        return '/welcome';
      }

      if (!isOnboardingComplete) {
        return '/permissions';
      }

      return null;
    },
    routes: [
      // Onboarding Routes
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/permissions',
        name: 'permissions',
        builder: (context, state) => const PermissionsScreen(),
      ),
      GoRoute(
        path: '/profile-creation',
        name: 'profile-creation',
        builder: (context, state) => const ProfileCreationScreen(),
      ),
      GoRoute(
        path: '/tutorial',
        name: 'tutorial',
        builder: (context, state) => const TutorialScreen(),
      ),

      // Main App Routes
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: '/report-detail/:id',
            name: 'report-detail',
            builder: (context, state) =>
                ReportDetailScreen(reportId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/submit-report',
        name: 'submit-report',
        builder: (context, state) => const ReportSubmissionScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
