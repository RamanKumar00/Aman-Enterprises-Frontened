import 'package:flutter/material.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/screens/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': 'Fresh Groceries\nAt Your Doorstep',
      'subtitle': 'Get fresh vegetables, fruits, dairy and more delivered to your home in minutes.',
      'icon': Icons.local_grocery_store_rounded,
      'color': const Color(0xFFE8F5E9),
      'iconColor': Colors.green,
    },
    {
      'title': 'Easy & Quick\nOrdering',
      'subtitle': 'Browse through thousands of products and order with just a few taps.',
      'icon': Icons.touch_app_rounded,
      'color': const Color(0xFFFFF3E0),
      'iconColor': Colors.orange,
    },
    {
      'title': 'Fast Delivery\nWithin 30 Minutes',
      'subtitle': 'Our delivery partners ensure your order reaches you in the shortest time.',
      'icon': Icons.delivery_dining_rounded,
      'color': const Color(0xFFE3F2FD),
      'iconColor': Colors.blue,
    },
    {
      'title': 'Secure Payments\n& Best Deals',
      'subtitle': 'Pay securely with multiple options and enjoy exclusive offers.',
      'icon': Icons.verified_user_rounded,
      'color': const Color(0xFFF3E5F5),
      'iconColor': Colors.purple,
    },
  ];

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
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
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _navigateToLogin,
                    child: Text(
                      'Skip',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_onboardingData[index]);
                },
              ),
            ),

            // Page Indicators & Button
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Container
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: data['color'] as Color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (data['iconColor'] as Color).withAlpha(51),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Icon(
                data['icon'] as IconData,
                size: 100,
                color: data['iconColor'] as Color,
              ),
            ),
          ),
          const SizedBox(height: 60),

          // Title
          Text(
            data['title'] as String,
            style: AppTextStyles.headingLarge.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Subtitle
          Text(
            data['subtitle'] as String,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textMedium,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Page Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_onboardingData.length, (index) {
              final isActive = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 32 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primaryGreen : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 40),

          // Next/Get Started Button
          Container(
            width: double.infinity,
            height: AppDimensions.buttonHeight,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryGreenLight, AppColors.primaryGreen],
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withAlpha(102),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentPage == _onboardingData.length - 1 ? 'Get Started' : 'Next',
                    style: AppTextStyles.buttonText,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _currentPage == _onboardingData.length - 1
                        ? Icons.arrow_forward_rounded
                        : Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
