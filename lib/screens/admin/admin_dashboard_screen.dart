import 'package:flutter/material.dart';
import 'package:aman_enterprises/services/api_service.dart';
import 'package:aman_enterprises/screens/login_screen.dart';
import 'package:aman_enterprises/services/user_service.dart';
import 'package:aman_enterprises/screens/admin/admin_products_screen.dart';
import 'package:aman_enterprises/screens/admin/admin_orders_screen.dart';
import 'package:aman_enterprises/screens/admin/admin_manage_categories_screen.dart';
import 'package:aman_enterprises/screens/admin/manage_flash_deals_screen.dart';
import 'package:aman_enterprises/screens/admin/admin_users_screen.dart';
import 'package:aman_enterprises/screens/admin/admin_reviews_screen.dart';
import 'package:aman_enterprises/screens/admin/admin_invoices_screen.dart';
import 'package:aman_enterprises/screens/admin/bulk_operations_screen.dart';
import 'package:aman_enterprises/services/notification_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with TickerProviderStateMixin {
  int _orderCount = 0;
  int _productCount = 0;
  int _userCount = 0;
  int _totalRevenue = 0;
  bool _isLoading = true;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    
    _fetchStats();
    _initNotificationService();
  }
  
  void _initNotificationService() {
    NotificationService().init();
    
    // Schedule the context setting for after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Set global context for in-app overlay notifications
        NotificationService().setGlobalContext(context);
        
        // Set callback to navigate to orders screen when notification is tapped
        NotificationService().setOrdersNavigationCallback(() {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
          ).then((_) => _fetchStats());
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _fetchStats() async {
    final token = UserService().authToken;
    if (token != null) {
      try {
        final response = await ApiService.getDashboardStats(token);
        
        if (mounted) {
          setState(() {
            if (response.success && response.data != null) {
              final stats = response.data!['stats'];
              if (stats != null) {
                _orderCount = stats['totalOrders'] ?? 0;
                _productCount = stats['totalProducts'] ?? 0;
                _userCount = stats['totalUsers'] ?? 0;
                _totalRevenue = stats['totalRevenue'] ?? 0;
              }
            }
            _isLoading = false;
          });
          _fadeController.forward();
          _slideController.forward();
        }
      } catch (e) {
        debugPrint('Error fetching stats: $e');
        if (mounted) {
          setState(() => _isLoading = false);
          _fadeController.forward();
          _slideController.forward();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
              const Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading 
            ? _buildLoadingState()
            : FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Custom App Bar
                      SliverToBoxAdapter(child: _buildHeader()),
                      
                      // Stats Section
                      SliverToBoxAdapter(child: _buildStatsSection()),
                      
                      // Quick Actions Title
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.amber, Colors.orange],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Quick Actions',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Action Cards Grid
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                          delegate: SliverChildListDelegate(_buildActionCards()),
                        ),
                      ),
                      
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: Colors.amber,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading Dashboard...',
            style: TextStyle(
              color: Colors.white.withAlpha(179),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final userName = UserService().currentUser?['shopName'] ?? 'Admin';
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Avatar with gradient border
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber, Colors.orange, Colors.deepOrange],
              ),
              shape: BoxShape.circle,
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A2E),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.amber,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Welcome Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white.withAlpha(179),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Action Buttons
          _buildHeaderIcon(Icons.refresh, () {
            setState(() => _isLoading = true);
            _fetchStats();
          }),
          const SizedBox(width: 8),
          _buildHeaderIcon(Icons.logout, () async {
            await UserService().clearUser();
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }, isLogout: true),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap, {bool isLogout = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isLogout ? Colors.red.withAlpha(51) : Colors.white.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLogout ? Colors.red.withAlpha(77) : Colors.white.withAlpha(51),
          ),
        ),
        child: Icon(
          icon,
          color: isLogout ? Colors.red.shade300 : Colors.white.withAlpha(204),
          size: 22,
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withAlpha(26),
            Colors.white.withAlpha(13),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(51)),
      ),
      child: Column(
        children: [
          // Revenue Card (Featured)
          _buildRevenueCard(),
          const SizedBox(height: 16),
          
          // Stats Row
          Row(
            children: [
              Expanded(child: _buildMiniStatCard('Orders', _orderCount.toString(), Icons.shopping_bag_rounded, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildMiniStatCard('Products', _productCount.toString(), Icons.inventory_2_rounded, Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _buildMiniStatCard('Users', _userCount.toString(), Icons.people_rounded, Colors.purple)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF11998e),
            const Color(0xFF38ef7d),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF11998e).withAlpha(102),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Revenue',
                  style: TextStyle(
                    color: Colors.white.withAlpha(230),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${_formatNumber(_totalRevenue)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Live',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 10000000) {
      return '${(number / 10000000).toStringAsFixed(1)}Cr';
    } else if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(1)}L';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildMiniStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withAlpha(179),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionCards() {
    final actions = [
      _ActionItem('Products', Icons.inventory_2_rounded, [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProductsScreen())).then((_) => _fetchStats())),
      _ActionItem('Categories', Icons.category_rounded, [const Color(0xFF4ECDC4), const Color(0xFF44B09E)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminManageCategoriesScreen())).then((_) => _fetchStats())),
      _ActionItem('Orders', Icons.shopping_bag_rounded, [const Color(0xFF667eea), const Color(0xFF764ba2)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminOrdersScreen())).then((_) => _fetchStats())),
      _ActionItem('Flash Deals', Icons.flash_on_rounded, [const Color(0xFFF093FB), const Color(0xFFF5576C)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageFlashDealsScreen()))),
      _ActionItem('Users', Icons.group_rounded, [const Color(0xFF5B86E5), const Color(0xFF36D1DC)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen())).then((_) => _fetchStats())),
      _ActionItem('Reviews', Icons.rate_review_rounded, [const Color(0xFFFFB75E), const Color(0xFFED8F03)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReviewsScreen()))),
      _ActionItem('Invoices', Icons.receipt_long_rounded, [const Color(0xFF00C9FF), const Color(0xFF92FE9D)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminInvoicesScreen()))),
      _ActionItem('Bulk Ops', Icons.upload_file_rounded, [const Color(0xFFA770EF), const Color(0xFFCF8BF3)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkOperationsScreen()))),
    ];

    return actions.asMap().entries.map((entry) {
      final index = entry.key;
      final action = entry.value;
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 400 + (index * 100)),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value,
              child: _buildActionCard(action),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildActionCard(_ActionItem action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: action.colors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: action.colors.first.withAlpha(102),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background decoration
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                action.icon,
                size: 80,
                color: Colors.white.withAlpha(26),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(action.icon, color: Colors.white, size: 26),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Manage',
                            style: TextStyle(
                              color: Colors.white.withAlpha(204),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white.withAlpha(204),
                            size: 12,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItem {
  final String title;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  _ActionItem(this.title, this.icon, this.colors, this.onTap);
}
