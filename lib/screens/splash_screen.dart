import 'package:flutter/material.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/screens/onboarding_screen.dart';
import 'package:aman_enterprises/services/api_service.dart';
import 'package:aman_enterprises/services/user_service.dart';
import 'package:aman_enterprises/screens/main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late AnimationController _pulseController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _progressValue;
  late Animation<double> _pulseAnimation;
  
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    ApiService.wakeUp(); // Wake up server early
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Progress bar animation controller
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Pulse animation for the logo ring
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Logo scale animation
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );
    
    // Logo opacity animation
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    
    // Text opacity animation
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );
    
    // Progress animation
    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Pulse animation
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Update progress value
    _progressController.addListener(() {
      setState(() {
        _currentProgress = _progressValue.value * 100;
      });
    });
    
    // Navigate to login after animation completes
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToLogin();
      }
    });
  }

  void _startAnimations() {
    _logoController.forward();
    
    // Start progress after logo animation
    Future.delayed(const Duration(milliseconds: 400), () {
      _progressController.forward();
    });
    
    // Start pulse animation loop
    _pulseController.repeat(reverse: true);
  }

  Future<void> _navigateToLogin() async {
    // Ensure User Service loads data from shared preferences
    final userService = UserService();
    await userService.loadUser(); // Make sure we wait for load
    
    final isLoggedIn = await userService.isSessionValid();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            isLoggedIn ? const MainNavigationScreen() : const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child, // Simple fade is cleaner for home switch
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.splashGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              
              // Animated Logo
              AnimatedBuilder(
                animation: Listenable.merge([_logoController, _pulseController]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoScale.value * _pulseAnimation.value,
                    child: Opacity(
                      opacity: _logoOpacity.value,
                      child: _buildLogo(),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 40),
              
              // Title & Subtitle
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textOpacity.value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _textOpacity.value)),
                      child: Column(
                        children: [
                          Text(
                            'Aman',
                            style: AppTextStyles.splashTitle,
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Enterprises',
                            style: AppTextStyles.splashTitle,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'Groceries at your doorstep in minutes',
                              style: AppTextStyles.splashSubtitle,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const Spacer(flex: 3),
              
              // Progress Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    // Progress Label
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'INITIALIZING FRESHNESS',
                          style: AppTextStyles.labelText.copyWith(
                            color: AppColors.textMedium,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          '${_currentProgress.toInt()}%',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Progress Bar
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return Container(
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.white.withAlpha(128),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Stack(
                              children: [
                                // Background shimmer effect
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withAlpha(51),
                                          Colors.white.withAlpha(102),
                                          Colors.white.withAlpha(51),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Progress Fill
                                FractionallySizedBox(
                                  widthFactor: _progressValue.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.primaryGreenLight,
                                          AppColors.primaryGreen,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryGreen.withAlpha(102),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Tagline
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textOpacity.value,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTagDot(),
                        const SizedBox(width: 8),
                        Text('FAST', style: AppTextStyles.splashTag),
                        const SizedBox(width: 8),
                        _buildTagDot(),
                        const SizedBox(width: 8),
                        Text('FRESH', style: AppTextStyles.splashTag),
                        const SizedBox(width: 8),
                        _buildTagDot(),
                        const SizedBox(width: 8),
                        Text('ENERGETIC', style: AppTextStyles.splashTag),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withAlpha(77),
            blurRadius: 30,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryGreenLight,
              AppColors.primaryGreen,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withAlpha(102),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(
          Icons.shopping_cart_rounded,
          size: 64,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTagDot() {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryGreen,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withAlpha(128),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}
