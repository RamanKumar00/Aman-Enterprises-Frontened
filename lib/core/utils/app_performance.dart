import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Performance optimization utilities for the app
class AppPerformance {
  static final AppPerformance _instance = AppPerformance._internal();
  factory AppPerformance() => _instance;
  AppPerformance._internal();

  /// Custom cache manager for product images with optimized settings
  static final productImageCacheManager = CacheManager(
    Config(
      'productImageCache',
      stalePeriod: const Duration(days: 7), // Cache for 7 days
      maxNrOfCacheObjects: 200, // Max 200 images cached
      repo: JsonCacheInfoRepository(databaseName: 'productImageCache'),
      fileService: HttpFileService(),
    ),
  );

  /// Custom cache manager for category images
  static final categoryImageCacheManager = CacheManager(
    Config(
      'categoryImageCache',
      stalePeriod: const Duration(days: 14), // Cache for 14 days
      maxNrOfCacheObjects: 50, // Max 50 category images
      repo: JsonCacheInfoRepository(databaseName: 'categoryImageCache'),
      fileService: HttpFileService(),
    ),
  );

  /// Initialize performance optimizations
  static Future<void> initialize() async {
    // Pre-warm image cache with placeholder
    debugPrint('[Performance] Initializing app performance optimizations...');
    
    // Set image cache size limits
    PaintingBinding.instance.imageCache.maximumSize = 100; // Max 100 images in memory
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50MB max
    
    debugPrint('[Performance] Image cache configured: max 100 images, 50MB');
  }

  /// Clear all image caches (useful for troubleshooting or logout)
  static Future<void> clearImageCaches() async {
    try {
      await DefaultCacheManager().emptyCache();
      await productImageCacheManager.emptyCache();
      await categoryImageCacheManager.emptyCache();
      PaintingBinding.instance.imageCache.clear();
      debugPrint('[Performance] All image caches cleared');
    } catch (e) {
      debugPrint('[Performance] Error clearing caches: $e');
    }
  }

  /// Preload images for a list of URLs (useful for prefetching)
  static Future<void> preloadImages(BuildContext context, List<String> imageUrls) async {
    for (final url in imageUrls) {
      if (url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'))) {
        try {
          await precacheImage(
            CachedNetworkImageProvider(url),
            context,
          );
        } catch (e) {
          // Silently fail - not critical
        }
      }
    }
  }

  /// Get cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    final imageCache = PaintingBinding.instance.imageCache;
    return {
      'currentSize': imageCache.currentSize,
      'maximumSize': imageCache.maximumSize,
      'currentSizeBytes': imageCache.currentSizeBytes,
      'maximumSizeBytes': imageCache.maximumSizeBytes,
    };
  }
}

/// Extension for lazy loading lists
extension LazyLoadingList<T> on List<T> {
  /// Returns items in chunks for lazy loading
  List<T> getChunk(int page, int pageSize) {
    final start = page * pageSize;
    if (start >= length) return [];
    final end = (start + pageSize).clamp(0, length);
    return sublist(start, end);
  }
}

/// Widget for lazy loading product grids
class LazyLoadingGrid extends StatefulWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry? padding;
  final int initialLoadCount;
  final int loadMoreCount;

  const LazyLoadingGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.65,
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
    this.padding,
    this.initialLoadCount = 10,
    this.loadMoreCount = 10,
  });

  @override
  State<LazyLoadingGrid> createState() => _LazyLoadingGridState();
}

class _LazyLoadingGridState extends State<LazyLoadingGrid> {
  late int _displayedCount;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _displayedCount = widget.initialLoadCount.clamp(0, widget.children.length);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_displayedCount < widget.children.length) {
      setState(() {
        _displayedCount = (_displayedCount + widget.loadMoreCount)
            .clamp(0, widget.children.length);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: _scrollController,
      padding: widget.padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        childAspectRatio: widget.childAspectRatio,
        crossAxisSpacing: widget.crossAxisSpacing,
        mainAxisSpacing: widget.mainAxisSpacing,
      ),
      itemCount: _displayedCount,
      itemBuilder: (context, index) => widget.children[index],
    );
  }
}
