import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/screens/category_products_screen.dart';
import 'package:aman_enterprises/services/api_service.dart';
import 'package:aman_enterprises/widgets/shimmer_widgets.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];

  // Color palette for categories
  final List<Color> _categoryColors = [
    const Color(0xFF4CAF50), // Green
    const Color(0xFFE91E63), // Pink
    const Color(0xFF2196F3), // Blue
    const Color(0xFFFF9800), // Orange
    const Color(0xFF795548), // Brown
    const Color(0xFF9C27B0), // Purple
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFFFF5722), // Deep Orange
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFF8BC34A), // Light Green
    const Color(0xFFF44336), // Red
    const Color(0xFF607D8B), // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getCategories();
      if (response.success && response.data != null) {
        final List<dynamic> catList = response.data!['categories'] ?? [];
        
        setState(() {
          _categories = catList.asMap().entries.map((entry) {
            final index = entry.key;
            final json = entry.value;
            
            final name = json['categoryName'] ?? 'Unknown';
            
            // Get image URL from backend
            String imgUrl = 'https://via.placeholder.com/300';
            if (json['categoryImage'] is Map) {
              imgUrl = json['categoryImage']['url'] ?? imgUrl;
            } else if (json['categoryImage'] is String) {
              imgUrl = json['categoryImage'];
            }
            
            return {
              'name': name,
              'image': imgUrl,
              'color': _categoryColors[index % _categoryColors.length],
              'bgColor': _categoryColors[index % _categoryColors.length].withValues(alpha: 0.1),
              'itemCount': 0, // Will be fetched when entering category
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Categories',
          style: AppTextStyles.headingSmall,
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search_rounded,
              color: AppColors.textDark,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? GridView.builder(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 8,
              itemBuilder: (context, index) => const CategoryShimmer(),
            )
          : _categories.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchCategories,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return _buildCategoryCard(category, index);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No categories found',
            style: AppTextStyles.headingSmall.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _fetchCategories,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, int index) {
    final String imageUrl = category['image'] as String;
    final bool isNetworkImage = imageUrl.startsWith('http');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryProductsScreen(
              categoryName: category['name'] as String,
              categoryColor: category['color'] as Color,
              categoryImage: imageUrl,
            ),
          ),
        );
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300 + (index * 50)),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.5 + (value * 0.5),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
            boxShadow: [
              BoxShadow(
                color: (category['color'] as Color).withAlpha(38),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Category Image as Background
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
                  child: isNetworkImage
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: category['bgColor'] as Color,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: category['bgColor'] as Color,
                            child: Icon(
                              Icons.category_rounded,
                              size: 60,
                              color: (category['color'] as Color).withAlpha(77),
                            ),
                          ),
                        )
                      : Image.asset(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: category['bgColor'] as Color,
                            child: Icon(
                              Icons.category_rounded,
                              size: 60,
                              color: (category['color'] as Color).withAlpha(77),
                            ),
                          ),
                        ),
                ),
              ),
              
              // Gradient Overlay for Text Readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(26),
                        Colors.black.withAlpha(153),
                      ],
                      stops: const [0.3, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: Stack(
                  children: [
                    // Arrow Icon (top right)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(230),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(26),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: category['color'] as Color,
                          size: 18,
                        ),
                      ),
                    ),
                    
                    // Bottom Content (Name)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Category Name
                          Text(
                            category['name'] as String,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withAlpha(77),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
