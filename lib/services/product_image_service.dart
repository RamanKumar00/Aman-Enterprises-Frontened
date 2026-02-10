import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service to auto-fetch product images from external sources (Pexels/Unsplash)
/// when admin hasn't uploaded an image.
/// 
/// Priority:
/// 1. Use admin-uploaded image if available
/// 2. Auto-fetch from Pexels API using product name + category
/// 3. Use branded placeholder if no image found
class ProductImageService extends ChangeNotifier {
  static final ProductImageService _instance = ProductImageService._internal();
  factory ProductImageService() => _instance;
  ProductImageService._internal();

  // Pexels API Key (should be in backend for security, but here for fallback)
  static const String _pexelsApiKey = 'fPjKpqXCCuAqfFGhp9TdJwQ6IEfJiNKXaNPTqFqLNj9WKW3y7KfOnS1N';
  
  // Cache for fetched images to avoid repeated API calls
  final Map<String, String> _imageCache = {};

  // Branded placeholder URL
  static const String brandedPlaceholderUrl = 
    'https://via.placeholder.com/400x400/4CAF50/FFFFFF?text=Aman+Enterprises';

  /// Get image URL for a product
  /// Returns the best available image URL
  Future<String> getProductImageUrl({
    required String productId,
    required String productName,
    required String category,
    String? existingImageUrl,
  }) async {
    // 1. If admin uploaded image exists and is valid, use it
    if (existingImageUrl != null && 
        existingImageUrl.isNotEmpty && 
        !existingImageUrl.contains('placeholder')) {
      return existingImageUrl;
    }

    // 2. Check cache
    final cacheKey = '${productName}_$category';
    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey]!;
    }

    // 3. Try to fetch from Pexels
    try {
      final imageUrl = await _fetchFromPexels(productName, category);
      if (imageUrl != null) {
        _imageCache[cacheKey] = imageUrl;
        return imageUrl;
      }
    } catch (e) {
      debugPrint('ProductImageService: Error fetching from Pexels - $e');
    }

    // 4. Return branded placeholder
    return brandedPlaceholderUrl;
  }

  /// Fetch image from Pexels API
  Future<String?> _fetchFromPexels(String productName, String category) async {
    try {
      // Build search query using product name and category
      final searchQuery = '$productName $category'.trim();
      final encodedQuery = Uri.encodeComponent(searchQuery);
      
      final response = await http.get(
        Uri.parse('https://api.pexels.com/v1/search?query=$encodedQuery&per_page=1&orientation=square'),
        headers: {
          'Authorization': _pexelsApiKey,
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final photos = data['photos'] as List?;
        
        if (photos != null && photos.isNotEmpty) {
          // Get medium-sized image for balance of quality and performance
          final imageUrl = photos[0]['src']['medium'] as String?;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            debugPrint('ProductImageService: Found Pexels image for "$searchQuery"');
            return imageUrl;
          }
        }
      }
    } catch (e) {
      debugPrint('ProductImageService: Pexels API error - $e');
    }
    
    return null;
  }

  /// Clear image cache (useful when refreshing products)
  void clearCache() {
    _imageCache.clear();
    notifyListeners();
  }

  /// Get cached image URL if available
  String? getCachedImage(String productName, String category) {
    return _imageCache['${productName}_$category'];
  }

  /// Pre-load images for a list of products (batch operation)
  Future<void> preloadImages(List<Map<String, String>> products) async {
    for (final product in products) {
      final name = product['name'] ?? '';
      final category = product['category'] ?? '';
      final existingUrl = product['imageUrl'];
      
      if (name.isNotEmpty) {
        await getProductImageUrl(
          productId: product['id'] ?? '',
          productName: name,
          category: category,
          existingImageUrl: existingUrl,
        );
      }
    }
    notifyListeners();
  }

  /// Check if image URL is valid (not a placeholder or empty)
  bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    if (url.contains('placeholder')) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  /// Generate a category-based placeholder color
  static int getPlaceholderColor(String category) {
    final colors = {
      'vegetables': 0xFF4CAF50,
      'fruits': 0xFFE91E63,
      'dairy': 0xFF2196F3,
      'bakery': 0xFFFF9800,
      'grains': 0xFF795548,
      'beverages': 0xFF9C27B0,
      'meat & fish': 0xFFF44336,
      'snacks': 0xFFFFEB3B,
      'frozen foods': 0xFF00BCD4,
      'cleaning': 0xFF607D8B,
      'personal care': 0xFFFF5722,
    };
    
    return colors[category.toLowerCase()] ?? 0xFF4CAF50;
  }
}
