// presentation/screens/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.report_problem,
      title: 'Report Local Issues',
      description:
          'Spotted a pothole, broken streetlight, or other civic problem? Report it instantly with photos and location data.',
      color: AppTheme.primaryBlue,
    ),
    OnboardingPage(
      icon: Icons.people,
      title: 'Community Validation',
      description:
          'Your neighbors help verify and prioritize reports through a democratic voting system that prevents spam.',
      color: AppTheme.successGreen,
    ),
    OnboardingPage(
      icon: Icons.trending_up,
      title: 'Build Your Reputation',
      description:
          'Submit quality reports and participate constructively to earn reputation points and increase your voting influence.',
      color: AppTheme.warningOrange,
    ),
    OnboardingPage(
      icon: Icons.check_circle,
      title: 'See Real Results',
      description:
          'Track your reports as they get reviewed by authorities and watch your community improve together.',
      color: AppTheme.successGreen,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/permissions');
    }
  }

  void _skipOnboarding() {
    context.go('/permissions');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _skipOnboarding,
            child: const Text(
              'Skip',
              style: TextStyle(
                color: AppTheme.mediumGray,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Page indicators
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppTheme.primaryBlue
                        : AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),

          // PageView
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return _buildPage(_pages[index]);
              },
            ),
          ),

          // Bottom navigation
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Previous'),
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),

                const SizedBox(width: 16),

                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Next',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 60, color: page.color),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGray,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.mediumGray,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
