import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/services/asset_image_manager.dart';

/// Optimized image widget with built-in caching, placeholder, and error handling
/// Uses local assets first, then CachedNetworkImage for efficient memory and disk caching
class OptimizedImage extends StatelessWidget {
  final String? imageUrl;
  final String? assetName; // Product/Category name to check for local asset
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color placeholderColor;
  final IconData placeholderIcon;
  final Color placeholderIconColor;
  final Widget? customPlaceholder;
  final Widget? customErrorWidget;
  final bool checkLocalFirst; // Whether to check local assets first
  
  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.assetName,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderColor = const Color(0xFFF5F5F5),
    this.placeholderIcon = Icons.image_outlined,
    this.placeholderIconColor = const Color(0xFFBDBDBD),
    this.customPlaceholder,
    this.customErrorWidget,
    this.checkLocalFirst = true,
  });

  @override
  Widget build(BuildContext context) {
    // Try local asset first if assetName is provided
    if (checkLocalFirst && assetName != null && assetName!.isNotEmpty) {
      final assetManager = AssetImageManager();
      final localPath = assetManager.getProductAssetPath(assetName!) ??
                       assetManager.getCategoryAssetPath(assetName!);
      
      if (localPath != null) {
        return ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: Image.asset(
            localPath,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              // If asset fails, try network
              return _buildNetworkImage();
            },
          ),
        );
      }
    }

    // Fall back to network image
    return _buildNetworkImage();
  }

  Widget _buildNetworkImage() {
    // If no valid URL, show placeholder immediately
    if (imageUrl == null || imageUrl!.isEmpty || !_isValidUrl(imageUrl!)) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: _buildPlaceholder(),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        // Memory cache settings - limit memory usage
        memCacheWidth: width != null ? (width! * 2).toInt() : 800,
        memCacheHeight: height != null ? (height! * 2).toInt() : 800,
        // Fade in animation for smooth loading
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 200),
        // Placeholder while loading
        placeholder: (context, url) => customPlaceholder ?? _buildLoadingPlaceholder(),
        // Error widget when failed to load
        errorWidget: (context, url, error) => customErrorWidget ?? _buildPlaceholder(),
      ),
    );
  }

  bool _isValidUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: placeholderColor,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen.withAlpha(128)),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: placeholderColor,
      child: Center(
        child: Icon(
          placeholderIcon,
          size: 40,
          color: placeholderIconColor,
        ),
      ),
    );
  }
}

/// Product-specific optimized image with automatic sizing and category-based colors
class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final String category;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.category = '',
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return OptimizedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      borderRadius: borderRadius,
      fit: BoxFit.cover,
      placeholderColor: _getCategoryColor(category).withAlpha(26),
      placeholderIcon: _getCategoryIcon(category),
      placeholderIconColor: _getCategoryColor(category),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'vegetables': Colors.green,
      'fruits': Colors.orange,
      'dairy': Colors.blue,
      'bakery': Colors.brown,
      'grains': Colors.amber,
      'beverages': Colors.purple,
      'meat & fish': Colors.red,
      'snacks': Colors.yellow.shade700,
      'frozen foods': Colors.lightBlue,
      'cleaning': Colors.teal,
      'personal care': Colors.pink,
    };
    return colors[category.toLowerCase()] ?? AppColors.primaryGreen;
  }

  IconData _getCategoryIcon(String category) {
    final icons = {
      'vegetables': Icons.eco_rounded,
      'fruits': Icons.apple_rounded,
      'dairy': Icons.local_drink_rounded,
      'bakery': Icons.breakfast_dining_rounded,
      'grains': Icons.rice_bowl_rounded,
      'beverages': Icons.local_cafe_rounded,
      'meat & fish': Icons.set_meal_rounded,
      'snacks': Icons.fastfood_rounded,
      'frozen foods': Icons.ac_unit_rounded,
      'cleaning': Icons.cleaning_services_rounded,
      'personal care': Icons.spa_rounded,
    };
    return icons[category.toLowerCase()] ?? Icons.shopping_bag_outlined;
  }
}

/// Category image with optimized loading
class CategoryImage extends StatelessWidget {
  final String? imageUrl;
  final String categoryName;
  final Color categoryColor;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const CategoryImage({
    super.key,
    required this.imageUrl,
    required this.categoryName,
    this.categoryColor = Colors.green,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return OptimizedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      borderRadius: borderRadius,
      fit: BoxFit.cover,
      placeholderColor: categoryColor.withAlpha(38),
      placeholderIcon: _getCategoryIcon(categoryName),
      placeholderIconColor: categoryColor,
    );
  }

  IconData _getCategoryIcon(String name) {
    final icons = {
      'vegetables': Icons.eco_rounded,
      'fruits': Icons.apple_rounded,
      'dairy': Icons.local_drink_rounded,
      'bakery': Icons.breakfast_dining_rounded,
      'grains': Icons.rice_bowl_rounded,
      'beverages': Icons.local_cafe_rounded,
      'meat & fish': Icons.set_meal_rounded,
      'snacks': Icons.fastfood_rounded,
      'frozen foods': Icons.ac_unit_rounded,
      'cleaning': Icons.cleaning_services_rounded,
      'personal care': Icons.spa_rounded,
    };
    return icons[name.toLowerCase()] ?? Icons.category_rounded;
  }
}
