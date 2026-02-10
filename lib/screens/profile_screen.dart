import 'package:flutter/material.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aman_enterprises/screens/edit_profile_screen.dart';
import 'package:aman_enterprises/screens/address_management_screen.dart';
import 'package:aman_enterprises/screens/login_screen.dart';
import 'package:aman_enterprises/screens/notifications_screen.dart';
import 'package:aman_enterprises/screens/order_history_screen.dart';
import 'package:aman_enterprises/screens/help_support_screen.dart';
import 'package:aman_enterprises/screens/about_us_screen.dart';
import 'package:aman_enterprises/services/user_service.dart';
import 'package:aman_enterprises/services/wishlist_service.dart';
import 'package:aman_enterprises/services/order_service.dart';
import 'package:aman_enterprises/screens/admin/admin_dashboard_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: CustomScrollView(
        slivers: [
          // App Bar with Profile
          SliverToBoxAdapter(child: _buildProfileHeader(context)),
          
          // Stats Section
          SliverToBoxAdapter(child: _buildStatsSection()),
          
          // Menu Items
          SliverToBoxAdapter(child: _buildMenuSection(context)),
          
          // Logout Button
          SliverToBoxAdapter(child: _buildLogoutButton(context)),
          
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 30,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryGreenLight, AppColors.primaryGreen],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      child: AnimatedBuilder(
        animation: UserService(),
        builder: (context, _) {
          return Column(
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Profile',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Profile Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryGreenLight,
                            AppColors.primaryGreen,
                          ],
                        ),
                        shape: BoxShape.circle,
                        image: UserService().photoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(UserService().photoUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreen.withAlpha(77),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: UserService().photoUrl == null
                          ? const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 40,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    
                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            UserService().name,
                            style: AppTextStyles.headingSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            UserService().email.isNotEmpty ? UserService().email : UserService().phone,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textLight,
                            ),
                          ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withAlpha(26),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Gold Member',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
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
                
                // Edit Button
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCream,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.primaryGreen,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
          );
        },
      ),
    );
  }

  Widget _buildStatsSection() {
    return AnimatedBuilder(
      animation: Listenable.merge([OrderService(), WishlistService()]),
      builder: (context, _) {
        final stats = [
          {'icon': Icons.shopping_bag_outlined, 'value': OrderService().orderCount.toString(), 'label': 'Orders'},
          {'icon': Icons.favorite_outline, 'value': WishlistService().itemCount.toString(), 'label': 'Wishlist'},
          {'icon': Icons.local_offer_outlined, 'value': '0', 'label': 'Coupons'}, // Keep coupons 0 for now
        ];

        return Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Row(
            children: stats.map((stat) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withAlpha(26),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          stat['icon'] as IconData,
                          color: AppColors.primaryGreen,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        stat['value'] as String,
                        style: AppTextStyles.headingSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        stat['label'] as String,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    final menuItems = [
      if (UserService().role == 'Admin')
        {
          'icon': Icons.admin_panel_settings_outlined,
          'title': 'Admin Panel',
          'subtitle': 'Manage store & products',
        },
      {
        'icon': Icons.location_on_outlined,
        'title': 'Delivery Addresses',
        'subtitle': 'Manage your addresses',
      },
      {
        'icon': Icons.credit_card_outlined,
        'title': 'Payment Methods',
        'subtitle': 'Add or remove payment methods',
      },
      {
        'icon': Icons.receipt_long_outlined,
        'title': 'Order History',
        'subtitle': 'View past orders',
      },
      {
        'icon': Icons.notifications_outlined,
        'title': 'Notifications',
        'subtitle': 'Manage notifications',
      },
      {
        'icon': Icons.help_outline_rounded,
        'title': 'Help & Support',
        'subtitle': 'Get help with your orders',
      },
      {
        'icon': Icons.info_outline_rounded,
        'title': 'About Us',
        'subtitle': 'Learn more about Aman Enterprises',
      },
      {
        'icon': Icons.language_rounded,
        'title': 'Language / भाषा', 
        'subtitle': 'English / हिन्दी',
        'isLanguage': true,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: menuItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == menuItems.length - 1;
            
            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withAlpha(26),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: AppColors.primaryGreen,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    item['title'] as String,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    item['subtitle'] as String,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.textLight,
                  ),
                  onTap: () {
                    if (item['title'] == 'Admin Panel') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                      );
                    } else if (item['title'] == 'Delivery Addresses') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddressManagementScreen()),
                      );
                    } else if (item['title'] == 'Order History') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                      );
                    } else if (item['title'] == 'Notifications') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    } else if (item['title'] == 'Help & Support') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                      );
                    } else if (item['title'] == 'About Us') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                      );
                    } else if (item['isLanguage'] == true) {
                      _showLanguageBottomSheet(context);
                    } else if (item['title'] == 'Payment Methods') {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment Methods coming soon!'), behavior: SnackBarBehavior.floating),
                      );
                    }
                  },
                ),
                if (!isLast)
                  const Divider(
                    height: 1,
                    indent: 70,
                    endIndent: 20,
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(26),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Colors.red,
              size: 22,
            ),
          ),
          title: Text(
            'Logout',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.red,
            ),
          ),
          subtitle: Text(
            'Sign out of your account',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textLight,
            ),
          ),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
                ),
                title: Text('Logout', style: AppTextStyles.headingSmall),
                content: Text(
                  'Are you sure you want to logout?',
                  style: AppTextStyles.bodyMedium,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await UserService().clearUser();
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      // Navigate to login screen
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                    ),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  void _showLanguageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Language / भाषा चुनें',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                title: const Text('English'),
                trailing: context.locale.languageCode == 'en' 
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen)
                    : null,
                onTap: () {
                  context.setLocale(const Locale('en', 'US'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🇮🇳', style: TextStyle(fontSize: 24)),
                title: const Text('हिन्दी (Hindi)'),
                trailing: context.locale.languageCode == 'hi' 
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen)
                    : null,
                onTap: () {
                  context.setLocale(const Locale('hi', 'IN'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
