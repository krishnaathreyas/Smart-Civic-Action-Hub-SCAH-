// presentation/screens/onboarding/tutorial_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({Key? key}) : super(key: key);

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<TutorialPage> _pages = [
    TutorialPage(
      icon: Icons.how_to_vote,
      title: 'Your vote has power',
      description:
          'See your opinions shape community priorities and drive real change.\n\nEvery vote matters in tackling local issues.',
      color: AppTheme.primaryBlue,
    ),
    TutorialPage(
      icon: Icons.trending_up,
      title: 'Build your reputation',
      description:
          'Submitting valid reports that get resolved earns you points and increases your vote\'s influence.\n\nBe a trusted voice in your community.',
      color: AppTheme.successGreen,
    ),
    TutorialPage(
      icon: Icons.emergency,
      title: 'Flag emergencies',
      description:
          'Use the \'Urgency Flag\' for critical safety hazards that need immediate attention.\n\nHelp keep your community safe.',
      color: AppTheme.errorRed,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishTutorial();
    }
  }

  void _finishTutorial() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.completeOnboarding();
    context.go('/home');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
            onPressed: _finishTutorial,
            child: const Text(
              'Skip Tutorial',
              style: TextStyle(color: AppTheme.mediumGray, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Page Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
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

            const SizedBox(height: 40),

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
                  return _buildTutorialPage(_pages[index]);
                },
              ),
            ),

            // Bottom Navigation
            Padding(
              padding: const EdgeInsets.all(24.0),
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
                        child: const Text(
                          'Previous',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
      ),
    );
  }

  Widget _buildTutorialPage(TutorialPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
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

          const SizedBox(height: 40),

          // Title
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGray,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.mediumGray,
              height: 1.5,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

class TutorialPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  TutorialPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
