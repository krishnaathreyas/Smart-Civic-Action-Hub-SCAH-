import 'package:go_router/go_router.dart';

import '../presentation/providers/auth_provider.dart';
import '../presentation/screens/auth/sign_in_screen.dart';
import '../presentation/screens/dashboard/home_screen.dart';
import '../presentation/screens/onboarding/permissions_screen.dart';
import '../presentation/screens/onboarding/profile_creation_screen.dart';
import '../presentation/screens/onboarding/tutorial_screen.dart';
import '../presentation/screens/onboarding/welcome_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/report/report_detail_screen.dart';
import '../presentation/screens/report/report_submission_screen.dart';

class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final router = GoRouter(
    initialLocation: '/welcome',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final isOnboardingComplete = authProvider.isOnboardingComplete;

      // If user is authenticated and onboarding is complete, redirect to home
      if (isAuthenticated &&
          isOnboardingComplete &&
          (state.fullPath == '/welcome' || state.fullPath == '/')) {
        return '/home';
      }

      // Allow navigation during onboarding process
      return null;
    },
    routes: [
      // Authentication Routes
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        name: 'sign-in',
        builder: (context, state) => const SignInScreen(),
      ),

      // Onboarding Routes
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
      ),
      GoRoute(
        path: '/report-detail/:id',
        name: 'report-detail',
        builder: (context, state) =>
            ReportDetailScreen(reportId: state.pathParameters['id']!),
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
