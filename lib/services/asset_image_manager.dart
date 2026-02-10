import 'package:flutter/foundation.dart';

/// Asset Image Manager - Maps product/category names to local assets
/// Uses a static list of known assets
class AssetImageManager {
  static final AssetImageManager _instance = AssetImageManager._internal();
  factory AssetImageManager() => _instance;
  AssetImageManager._internal();

  bool _initialized = false;

  // Asset paths
  static const String _productsPath = 'assets/images/products/';
  static const String _categoriesPath = 'assets/images/categories/';
  
  // Placeholder image
  static const String placeholderAsset = 'assets/images/placeholder.png';
  static const String networkPlaceholder = 
    'https://via.placeholder.com/400x400/4CAF50/FFFFFF?text=Aman+Enterprises';

  // Known category assets (19 categories)
  static const Set<String> _categoryAssets = {
    'baby_care',
    'bakery',
    'beauty_and_grooming',
    'beverages',
    'biscuits_chips_and_namkeens',
    'body_and_skin_care',
    'chocolates_and_sweets',
    'cleaning',
    'dairy',
    'dry_fruits_nuts_and_seeds',
    'frozen',
    'fruits',
    'general',
    'grains',
    'hair_care',
    'meat_fish',
    'personal_care',
    'snacks',
    'vegetables',
  };

  // Known product assets (40 products)
  static const Set<String> _productAssets = {
    'apple_juice',
    'baby_food',
    'baby_oil',
    'baby_shampoo',
    'baby_soap',
    'capsicum',
    'chana_dal',
    'chicken_curry_cut',
    'chocolate_muffin',
    'coffee_powder',
    'conditioner',
    'cucumber',
    'cupcakes',
    'deodorant',
    'diapers_s',
    'digestive_biscuits',
    'dish_bar',
    'dragon_fruit',
    'feeding_bottle',
    'flavoured_milk',
    'frozen_pizza',
    'garlic',
    'hair_oil',
    'lemonade',
    'mango',
    'mop',
    'nachos',
    'namkeen',
    'pineapple',
    'pizza_base',
    'popsicles',
    'prawns',
    'salted_butter',
    'soda_water',
    'tea_bags',
    'toilet_cleaner',
    'toor_dal',
    'toothbrush',
    'vanilla_icecream',
    'watermelon',
  };

  /// Initialize the manager
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    debugPrint('[AssetImageManager] Initialized with ${_categoryAssets.length} categories and ${_productAssets.length} products');
  }

  /// Get local asset path for a product image
  String? getProductAssetPath(String productName) {
    final normalized = _normalizeFileName(productName);
    
    if (_productAssets.contains(normalized)) {
      return '$_productsPath$normalized.jpg';
    }
    
    // Also check if the product name contains any of our assets
    for (final asset in _productAssets) {
      if (normalized.contains(asset) || asset.contains(normalized)) {
        return '$_productsPath$asset.jpg';
      }
    }
    
    return null;
  }

  /// Get local asset path for a category image
  String? getCategoryAssetPath(String categoryName) {
    final normalized = _normalizeFileName(categoryName);
    
    if (_categoryAssets.contains(normalized)) {
      return '$_categoriesPath$normalized.jpg';
    }
    
    // Partial matching for categories
    for (final asset in _categoryAssets) {
      if (normalized.contains(asset) || asset.contains(normalized)) {
        return '$_categoriesPath$asset.jpg';
      }
    }
    
    return null;
  }

  /// Check if a local asset exists for product
  bool hasProductAsset(String productName) {
    return getProductAssetPath(productName) != null;
  }

  /// Check if a local asset exists for category
  bool hasCategoryAsset(String categoryName) {
    return getCategoryAssetPath(categoryName) != null;
  }

  /// Get the best image source for a product
  ImageSource getProductImageSource({
    required String productName,
    String? networkUrl,
  }) {
    final localPath = getProductAssetPath(productName);
    if (localPath != null) {
      return ImageSource(type: ImageSourceType.asset, path: localPath);
    }

    if (networkUrl != null && networkUrl.isNotEmpty && _isValidUrl(networkUrl)) {
      return ImageSource(type: ImageSourceType.network, path: networkUrl);
    }

    return ImageSource(type: ImageSourceType.network, path: networkPlaceholder);
  }

  /// Get the best image source for a category
  ImageSource getCategoryImageSource({
    required String categoryName,
    String? networkUrl,
  }) {
    final localPath = getCategoryAssetPath(categoryName);
    if (localPath != null) {
      return ImageSource(type: ImageSourceType.asset, path: localPath);
    }

    if (networkUrl != null && networkUrl.isNotEmpty && _isValidUrl(networkUrl)) {
      return ImageSource(type: ImageSourceType.network, path: networkUrl);
    }

    return ImageSource(type: ImageSourceType.network, path: networkPlaceholder);
  }

  /// Normalize file name
  String _normalizeFileName(String name) {
    return name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  bool _isValidUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  /// Get all available product assets
  List<String> getAvailableProductAssets() {
    return _productAssets.map((name) => '$_productsPath$name.jpg').toList();
  }

  /// Get all available category assets
  List<String> getAvailableCategoryAssets() {
    return _categoryAssets.map((name) => '$_categoriesPath$name.jpg').toList();
  }

  /// Get asset coverage report
  AssetCoverageReport getAssetCoverageReport(
    List<String> productNames, 
    List<String> categoryNames,
  ) {
    int productsWithAssets = 0;
    int categoriesWithAssets = 0;
    final List<String> missingProducts = [];
    final List<String> missingCategories = [];

    for (final name in productNames) {
      if (hasProductAsset(name)) {
        productsWithAssets++;
      } else {
        missingProducts.add(name);
      }
    }

    for (final name in categoryNames) {
      if (hasCategoryAsset(name)) {
        categoriesWithAssets++;
      } else {
        missingCategories.add(name);
      }
    }

    return AssetCoverageReport(
      totalProducts: productNames.length,
      productsWithAssets: productsWithAssets,
      totalCategories: categoryNames.length,
      categoriesWithAssets: categoriesWithAssets,
      missingProducts: missingProducts,
      missingCategories: missingCategories,
    );
  }
}

enum ImageSourceType { asset, network }

class ImageSource {
  final ImageSourceType type;
  final String path;

  ImageSource({required this.type, required this.path});

  bool get isAsset => type == ImageSourceType.asset;
  bool get isNetwork => type == ImageSourceType.network;
}

class AssetCoverageReport {
  final int totalProducts;
  final int productsWithAssets;
  final int totalCategories;
  final int categoriesWithAssets;
  final List<String> missingProducts;
  final List<String> missingCategories;

  AssetCoverageReport({
    required this.totalProducts,
    required this.productsWithAssets,
    required this.totalCategories,
    required this.categoriesWithAssets,
    required this.missingProducts,
    required this.missingCategories,
  });

  double get productCoverage => 
      totalProducts > 0 ? productsWithAssets / totalProducts * 100 : 0;
  
  double get categoryCoverage => 
      totalCategories > 0 ? categoriesWithAssets / totalCategories * 100 : 0;
}
