import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aman_enterprises/services/asset_image_manager.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';

/// Hybrid Image Widget - Loads local assets first, falls back to network
/// Priority: Local Asset > CDN/Cloudinary > Placeholder
class HybridImage extends StatelessWidget {
  final String? networkUrl;
  final String? assetName;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? placeholderColor;
  final IconData placeholderIcon;
  final bool isProduct;
  final bool isCategory;

  const HybridImage({
    super.key,
    this.networkUrl,
    this.assetName,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderColor,
    this.placeholderIcon = Icons.image_outlined,
    this.isProduct = false,
    this.isCategory = false,
  });

  /// Factory for product images
  factory HybridImage.product({
    Key? key,
    required String productName,
    String? networkUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    String? category,
  }) {
    return HybridImage(
      key: key,
      networkUrl: networkUrl,
      assetName: productName,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      placeholderColor: _getCategoryColor(category ?? ''),
      placeholderIcon: _getCategoryIcon(category ?? ''),
      isProduct: true,
    );
  }

  /// Factory for category images
  factory HybridImage.category({
    Key? key,
    required String categoryName,
    String? networkUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Color? categoryColor,
  }) {
    return HybridImage(
      key: key,
      networkUrl: networkUrl,
      assetName: categoryName,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      placeholderColor: categoryColor ?? _getCategoryColor(categoryName),
      placeholderIcon: _getCategoryIconByName(categoryName),
      isCategory: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final assetManager = AssetImageManager();
    
    // Determine the best image source
    ImageSource? source;
    
    if (isProduct && assetName != null) {
      source = assetManager.getProductImageSource(
        productName: assetName!,
        networkUrl: networkUrl,
      );
    } else if (isCategory && assetName != null) {
      source = assetManager.getCategoryImageSource(
        categoryName: assetName!,
        networkUrl: networkUrl,
      );
    } else if (assetName != null) {
      // Generic asset check
      final productPath = assetManager.getProductAssetPath(assetName!);
      final categoryPath = assetManager.getCategoryAssetPath(assetName!);
      
      if (productPath != null) {
        source = ImageSource(type: ImageSourceType.asset, path: productPath);
      } else if (categoryPath != null) {
        source = ImageSource(type: ImageSourceType.asset, path: categoryPath);
      } else if (networkUrl != null && networkUrl!.isNotEmpty) {
        source = ImageSource(type: ImageSourceType.network, path: networkUrl!);
      }
    }

    // If no source found, use network URL or placeholder
    source ??= networkUrl != null && networkUrl!.isNotEmpty
        ? ImageSource(type: ImageSourceType.network, path: networkUrl!)
        : ImageSource(
            type: ImageSourceType.network,
            path: AssetImageManager.networkPlaceholder,
          );

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: source.isAsset
          ? _buildAssetImage(source.path)
          : _buildNetworkImage(source.path),
    );
  }

  Widget _buildAssetImage(String assetPath) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to network if asset fails
        if (networkUrl != null && networkUrl!.isNotEmpty) {
          return _buildNetworkImage(networkUrl!);
        }
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildNetworkImage(String url) {
    if (!_isValidUrl(url)) {
      return _buildPlaceholder();
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: width != null ? (width! * 2).toInt() : 800,
      memCacheHeight: height != null ? (height! * 2).toInt() : 800,
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) => _buildLoadingPlaceholder(),
      errorWidget: (context, url, error) => _buildPlaceholder(),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: placeholderColor ?? const Color(0xFFF5F5F5),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.primaryGreen.withAlpha(128),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: placeholderColor ?? const Color(0xFFF5F5F5),
      child: Center(
        child: Icon(
          placeholderIcon,
          size: 40,
          color: (placeholderColor ?? Colors.grey).withAlpha(150),
        ),
      ),
    );
  }

  bool _isValidUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  static Color _getCategoryColor(String category) {
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
      'baby care': Colors.pink.shade200,
    };
    return colors[category.toLowerCase()] ?? AppColors.primaryGreen;
  }

  static IconData _getCategoryIcon(String category) {
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
      'baby care': Icons.child_friendly_rounded,
    };
    return icons[category.toLowerCase()] ?? Icons.shopping_bag_outlined;
  }

  static IconData _getCategoryIconByName(String categoryName) {
    return _getCategoryIcon(categoryName);
  }
}

/// Preloads critical images for fast display
class ImagePreloader {
  static final ImagePreloader _instance = ImagePreloader._internal();
  factory ImagePreloader() => _instance;
  ImagePreloader._internal();

  bool _preloaded = false;

  /// Preload critical category images
  Future<void> preloadCriticalImages(BuildContext context) async {
    if (_preloaded) return;

    final assetManager = AssetImageManager();
    await assetManager.initialize();

    final categoryAssets = assetManager.getAvailableCategoryAssets();

    // Preload first 6 category images
    final imagesToPreload = categoryAssets.take(6).toList();

    for (final asset in imagesToPreload) {
      try {
        await precacheImage(AssetImage(asset), context);
      } catch (e) {
        debugPrint('[ImagePreloader] Failed to preload $asset: $e');
      }
    }

    _preloaded = true;
    debugPrint('[ImagePreloader] Preloaded ${imagesToPreload.length} critical images');
  }

  /// Preload product images for a specific category
  Future<void> preloadProductImages(
    BuildContext context, 
    List<String> productNames,
  ) async {
    final assetManager = AssetImageManager();
    
    int preloaded = 0;
    for (final name in productNames.take(10)) {
      final path = assetManager.getProductAssetPath(name);
      if (path != null) {
        try {
          await precacheImage(AssetImage(path), context);
          preloaded++;
        } catch (e) {
          debugPrint('[ImagePreloader] Failed to preload product $name: $e');
        }
      }
    }
    
    debugPrint('[ImagePreloader] Preloaded $preloaded product images');
  }
}

/// Lazy loading wrapper for product lists
class LazyProductImage extends StatefulWidget {
  final String productName;
  final String? networkUrl;
  final String? category;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const LazyProductImage({
    super.key,
    required this.productName,
    this.networkUrl,
    this.category,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<LazyProductImage> createState() => _LazyProductImageState();
}

class _LazyProductImageState extends State<LazyProductImage> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      onVisibilityChanged: (visible) {
        if (visible && !_isVisible) {
          if (mounted) {
            setState(() => _isVisible = true);
          }
        }
      },
      child: _isVisible
          ? HybridImage.product(
              productName: widget.productName,
              networkUrl: widget.networkUrl,
              category: widget.category,
              width: widget.width,
              height: widget.height,
              borderRadius: widget.borderRadius,
            )
          : Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: widget.borderRadius,
              ),
            ),
    );
  }
}

/// Simple visibility detector for lazy loading
class VisibilityDetector extends StatefulWidget {
  final Widget child;
  final ValueChanged<bool> onVisibilityChanged;

  const VisibilityDetector({
    super.key,
    required this.child,
    required this.onVisibilityChanged,
  });

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  @override
  void initState() {
    super.initState();
    // Notify as visible after a short delay (simulating viewport entry)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onVisibilityChanged(true);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
