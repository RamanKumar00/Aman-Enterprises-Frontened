import 'package:flutter/material.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/screens/home_screen.dart';
import 'package:aman_enterprises/screens/categories_screen.dart';
import 'package:aman_enterprises/screens/cart_screen.dart';
import 'package:aman_enterprises/screens/profile_screen.dart';
import 'package:aman_enterprises/services/cart_service.dart';
import 'package:aman_enterprises/services/user_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const CategoriesScreen(),
    const CartScreen(),
    const ProfileScreen(),
  ];

  late List<AnimationController> _animationControllers;
  final CartService _cartService = CartService();

  @override
  void initState() {
    super.initState();
    _animationControllers = List.generate(
      4,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );
    _animationControllers[0].forward();
    _cartService.addListener(_onCartChange);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAddress();
    });
  }

  void _checkAddress() async {
    // Removed automatic redirect to LocationScreen
    // Location permission will only be requested during checkout when user places an order
    // This improves user experience by not interrupting browsing with permission dialogs
    
    // We still load user data for display purposes
    final userService = UserService();
    await userService.loadUser();
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
    _cartService.removeListener(_onCartChange);
  }

  void _onCartChange() {
    if (mounted) setState(() {});
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    
    _animationControllers[_currentIndex].reverse();
    _animationControllers[index].forward();
    
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
              _buildNavItem(1, Icons.grid_view_rounded, Icons.grid_view_outlined, 'Categories'),
              _buildNavItem(2, Icons.shopping_cart_rounded, Icons.shopping_cart_outlined, 'Cart', showBadge: true, badgeCount: _cartService.itemCount),
              _buildNavItem(3, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label, {bool showBadge = false, int badgeCount = 0}) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _animationControllers[index],
        builder: (context, child) {
          final scale = 0.9 + (_animationControllers[index].value * 0.1);
          
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryGreen.withAlpha(26)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        isSelected ? activeIcon : inactiveIcon,
                        color: isSelected
                            ? AppColors.primaryGreen
                            : AppColors.textLight,
                        size: 26,
                      ),
                      if (showBadge && badgeCount > 0)
                        Positioned(
                          right: -6,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$badgeCount',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected
                          ? AppColors.primaryGreen
                          : AppColors.textLight,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
