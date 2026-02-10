import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/screens/product_details_screen.dart';
import 'package:aman_enterprises/screens/search_screen.dart';
import 'package:aman_enterprises/screens/notifications_screen.dart';
import 'package:aman_enterprises/screens/category_products_screen.dart';
import 'package:aman_enterprises/models/product_model.dart';
import 'package:aman_enterprises/services/cart_service.dart';
import 'package:aman_enterprises/services/address_service.dart';
import 'package:aman_enterprises/screens/cart_screen.dart';
import 'package:aman_enterprises/services/api_service.dart';
import 'package:aman_enterprises/services/notification_service.dart';
import 'package:aman_enterprises/services/asset_image_manager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:aman_enterprises/screens/profile_screen.dart';
import 'package:aman_enterprises/screens/order_history_screen.dart';
import 'package:aman_enterprises/screens/wishlist_screen.dart';
import 'package:aman_enterprises/widgets/shimmer_widgets.dart';
import 'package:aman_enterprises/widgets/product_card.dart';
import 'package:aman_enterprises/services/user_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CartService _cartService = CartService();
  final NotificationService _notificationService = NotificationService();
  final PageController _pageController = PageController(viewportFraction: 0.9);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _timer;
  
  bool _isLoading = true;
  List<Product> _products = [];
  List<Map<String, dynamic>> _categories = [];

  // Fallback Categories
  final List<Map<String, dynamic>> _fallbackCategories = [
    {
      'name': 'Vegetables',
      'image': 'https://images.unsplash.com/photo-1566385101042-1a0aa0c1268c?auto=format&fit=crop&w=300&q=80',
      'color': const Color(0xFF4CAF50),
    },
    {
      'name': 'Fruits',
      'image': 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?auto=format&fit=crop&w=300&q=80',
      'color': const Color(0xFFE91E63),
    },
    {
      'name': 'Dairy',
      'image': 'https://images.unsplash.com/photo-1628088062854-d1870b4553da?auto=format&fit=crop&w=300&q=80',
      'color': const Color(0xFF2196F3),
    },
    {
      'name': 'Bakery',
      'image': 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&w=300&q=80',
      'color': const Color(0xFFFF9800),
    },
    {
      'name': 'Grains',
      'image': 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&w=300&q=80',
      'color': const Color(0xFF795548),
    },
    {
      'name': 'Beverages',
      'image': 'https://images.unsplash.com/photo-1544145945-f90425340c7e?auto=format&fit=crop&w=300&q=80',
      'color': const Color(0xFF9C27B0), 
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
    AddressService().addListener(_onAddressChange);
    _notificationService.addListener(_onNotificationChange);
    _cartService.addListener(_onCartChange);
    _cartService.fetchDealRules(); // Fetch flash deals
    
    // Auto-scroll banner
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_banners.isNotEmpty) {
        if (_pageController.hasClients) {
          int nextPage = _pageController.page!.round() + 1;
          if (nextPage >= _banners.length) {
            nextPage = 0;
          }
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    AddressService().removeListener(_onAddressChange);
    _notificationService.removeListener(_onNotificationChange);
    _cartService.removeListener(_onCartChange);
    super.dispose();
  }

  void _onAddressChange() {
    if (mounted) setState(() {});
  }

  void _onNotificationChange() {
    if (mounted) setState(() {});
  }

  void _onCartChange() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    
    // Parallel Fetching
    try {
      final results = await Future.wait([
        ApiService.getCategories(),
        ApiService.getProducts(),
      ]);
      
      final catResponse = results[0];
      final prodResponse = results[1];

      // 1. Process Categories
      if (catResponse.success && catResponse.data != null) {
        final List<dynamic> catList = catResponse.data!['categories'] ?? [];
        
        if (catList.isNotEmpty) {
          final List<Color> colors = [
            const Color(0xFF4CAF50),
            const Color(0xFFE91E63),
            const Color(0xFF2196F3),
            const Color(0xFFFF9800),
            const Color(0xFF795548),
            const Color(0xFF9C27B0),
          ];
          
          final assetManager = AssetImageManager();
          
          _categories = catList.asMap().entries.map((entry) {
            final index = entry.key;
            final json = entry.value;
            final name = json['categoryName'] ?? 'Unknown';
            
            // Check for local asset first, then fallback to network URL
            String imgUrl = '';
            final localAsset = assetManager.getCategoryAssetPath(name);
            
            if (localAsset != null) {
              // Use local asset (faster loading)
              imgUrl = localAsset;
            } else {
              // Fallback to network URL
              if (json['categoryImage'] is Map) {
                imgUrl = json['categoryImage']['url'] ?? '';
              } else if (json['categoryImage'] is String) {
                imgUrl = json['categoryImage'];
              }
            }
            
            return {
              'name': name,
              'image': imgUrl.isNotEmpty ? imgUrl : 'assets/images/placeholder.png',
              'color': colors[index % colors.length],
              'isLocal': localAsset != null,
            };
          }).toList();
        } else {
          _categories = _fallbackCategories;
        }
      } else {
        _categories = _fallbackCategories;
      }

      // 2. Process Products
      if (prodResponse.success && prodResponse.data != null) {
        final List<dynamic> prodList = prodResponse.data!['products'] ?? [];
        _products = prodList.map((json) => Product.fromJson(json)).toList();
      } else {
        _products = Product.sampleProducts;
      }

    } catch (e) {
      debugPrint('Error fetching data: $e');
      _categories = _fallbackCategories;
      _products = Product.sampleProducts; 
    }

    if (mounted) setState(() => _isLoading = false);
  }

  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'Fresh Vegetables',
      'subtitle': 'Up to 40% OFF',
      'color': const Color(0xFFE8F5E9),
      'icon': Icons.eco_rounded,
    },
    {
      'title': 'Organic Fruits',
      'subtitle': 'Buy 2 Get 1 Free',
      'color': const Color(0xFFFCE4EC),
      'icon': Icons.apple,
    },
    {
      'title': 'Dairy Products',
      'subtitle': 'Fresh & Pure',
      'color': const Color(0xFFE3F2FD),
      'icon': Icons.local_drink_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar (Includes Search)
            SliverToBoxAdapter(child: _buildAppBar()),
            
            // Banner Slider
            SliverToBoxAdapter(child: _buildBannerSlider()),
            
            // Categories
            SliverToBoxAdapter(child: _buildCategories()),
            

            
            // Section Title
            SliverToBoxAdapter(child: _buildSectionTitle('popular'.tr(), () {})),
            
            // Products Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
              sliver: _buildProductsGrid(),
            ),
            
            // Featured Section
            SliverToBoxAdapter(child: _buildSectionTitle('best_deals'.tr(), () {})),
            
            // Horizontal Products
            SliverToBoxAdapter(child: _buildHorizontalProducts()),
            
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
      floatingActionButton: null,
    );
  }

  Future<void> _openWhatsApp() async {
    const String phoneNumber = "919097037320"; 
    // Exact message as requested
    const String message = "Hello, I want to order groceries. Please help me.";
    
    final Uri url = Uri.parse("whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}");
    final Uri webUrl = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Could not launch WhatsApp')),
           );
        }
      }
    } catch (e) {
      debugPrint("Error launching WhatsApp: $e");
    }
  }

  Widget _buildDrawer() {
    final userService = UserService();
    final userName = userService.name;
    final userEmail = userService.email.isNotEmpty ? userService.email : 'Sign in to access more features';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Row(
              children: [
                Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(width: 8),
                // Show role badge for Retailers/Admins
                if (userService.isRetailer)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Retailer', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                else if (userService.isAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Admin', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            accountEmail: Text(userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'G',
                style: const TextStyle(fontSize: 40.0, color: Color(0xFF2E7D32)),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_rounded),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person_rounded),
            title: const Text('My Profile'),
             onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag_rounded),
            title: const Text('My Orders'),
             onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())); 
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_rounded),
            title: const Text('Wishlist'),
            onTap: () {
               Navigator.pop(context);
               Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen()));
            },
          ),
          // Admin Controls - Only visible for Admin users
          if (userService.isAdmin) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
              child: Text('Admin Controls', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded, color: Colors.indigo),
              title: const Text('Dashboard'),
              onTap: () {
                 Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Access Dashboard via Profile')));
              },
            ),
          ],
          const Divider(),
           ListTile(
            leading: const Icon(Icons.contact_support_rounded),
            title: const Text('Help & Support'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
               // Clear user session and cart on logout
               await userService.clearUser();
               CartService().clearCart(); // Clear cart on logout
               if (mounted) {
                   Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
               }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF43A047), // Green 600
            Color(0xFF2E7D32), // Green 800
          ], 
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          // Top Row: Menu | Brand | Actions
          Row(
            children: [
              // Hamburger Menu
              GestureDetector(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: const Icon(Icons.menu, color: Colors.white, size: 28),
              ),
              
              const SizedBox(width: 16),
              
              // Branding
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aman Enterprises',
                      style: const TextStyle(
                        fontFamily: 'Pacifico', // Cursive style if available
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'FRESHNESS DELIVERED',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // WhatsApp
              GestureDetector(
                onTap: _openWhatsApp,
                child: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              
              // Notification
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              
              // Cart
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 24),
                    if (_cartService.itemCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Center(
                            child: Text(
                              '${_cartService.itemCount}',
                              style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Search Bar (Embedded)
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2), 
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Grid Icon
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.grid_view_rounded, color: Colors.white70),
                ),
                
                // Divider
                Container(
                  width: 1, 
                  height: 24, 
                  color: Colors.white30,
                ),
                
                // Text
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Search From 10,000+ products',
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                
                // Search Icon
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.search, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSlider() {
    // Create a dynamic list of banners
    final List<Map<String, dynamic>> displayBanners = List.from(_banners);
    
    // Inject Flash Deal banner if active
    if (_cartService.isDealActive) {
      displayBanners.insert(0, {
        'title': 'Flash Deal Active!',
        'subtitle': 'Flat ${_cartService.flashDealPercentage * 100}% OFF on orders above ₹${_cartService.flashDealThreshold.toInt()}',
        'color': const Color(0xFFFFF3E0), // Orange tint
        'icon': Icons.flash_on_rounded,
      });
    }

    return Container(
      height: 160,
      margin: const EdgeInsets.only(top: AppDimensions.paddingMedium),
      child: PageView.builder(
        itemCount: displayBanners.length,
        controller: _pageController,
        itemBuilder: (context, index) {
          final banner = displayBanners[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: banner['color'] as Color,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    banner['icon'] as IconData,
                    size: 120,
                    color: Colors.black.withAlpha(13),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        banner['title'] as String,
                        style: AppTextStyles.headingMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 20, // Reduced from default
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2), // Reduced spacing
                      Text(
                        banner['subtitle'] as String,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 14, // Reduced size
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8), // Reduced spacing
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                        ),
                        child: Text(
                          'Shop Now',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategories() {
    // Filter out 'All' for the grid view
    final categories = _categories.where((c) => c['name'] != 'All').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            'shop_by_category'.tr(),
            style: AppTextStyles.headingSmall.copyWith(fontSize: 18),
          ),
        ),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];
            
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryProductsScreen(
                      categoryName: category['name'] as String,
                      categoryColor: category['color'] as Color,
                    ),
                  ),
                );
              },
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: (category['color'] as Color).withAlpha(30),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (category['color'] as Color).withAlpha(50),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: (category['image'] as String).startsWith('http')
                                  ? CachedNetworkImage(
                                      imageUrl: category['image'] as String,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(color: (category['color'] as Color).withValues(alpha: 0.3)),
                                      errorWidget: (context, url, error) => Center(
                                        child: Icon(
                                          Icons.category_rounded,
                                          color: category['color'] as Color,
                                          size: 32,
                                        ),
                                      ),
                                    )
                                  : Image.asset(
                                      category['image'] as String,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Center(
                                        child: Icon(
                                          Icons.category_rounded,
                                          color: category['color'] as Color,
                                          size: 32,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category['name'] as String,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.headingSmall,
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See All',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverGrid _buildProductsGrid() {
    if (_isLoading) {
      return SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65, 
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => const ProductCardShimmer(),
          childCount: 6,
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65, // Match aspect ratio for ProductCard
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => ProductCard(product: _products[index]),
        childCount: _products.length,
      ),
    );
  }


  Widget _buildHorizontalProducts() {
    final products = _products.isNotEmpty ? List.of(_products).reversed.toList() : Product.sampleProducts.reversed.toList();
    
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsScreen(product: product),
                ),
              );
            },
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: product.backgroundColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppDimensions.radiusLarge),
                        ),
                      ),
                      child: Hero(
                        tag: 'product_${product.id}',
                        child: product.imageUrl != null
                            ? ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppDimensions.radiusLarge),
                                ),
                                child: Image.network(
                                  product.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    product.icon,
                                    size: 50,
                                    color: product.iconColor,
                                  ),
                                ),
                              )
                            : Icon(
                                product.icon,
                                size: 50,
                                color: product.iconColor,
                              ),
                      ),
                    ),
                  ),
                  
                  // Info
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${product.price.toStringAsFixed(0)}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
