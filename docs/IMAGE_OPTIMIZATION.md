# 🖼️ Image Performance Optimization System

## Overview

This system eliminates slow image loading by prioritizing local assets over network images, with intelligent fallback mechanisms.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Image Loading Flow                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Request Image                                                 │
│        ↓                                                        │
│   ┌─────────────────┐                                          │
│   │ AssetImageManager│ ← Checks if local asset exists          │
│   └────────┬────────┘                                          │
│            ↓                                                    │
│   ┌────────┴────────┐                                          │
│   │ Local Asset?    │                                          │
│   └────────┬────────┘                                          │
│      Yes ↓    ↓ No                                             │
│   ┌──────────┐ ┌───────────────┐                               │
│   │AssetImage│ │CachedNetworkImg│                              │
│   └──────────┘ └───────┬───────┘                               │
│                        ↓                                        │
│                 ┌──────┴──────┐                                │
│                 │  Network OK? │                                │
│                 └──────┬──────┘                                │
│                  Yes ↓   ↓ No                                   │
│               ┌──────────┐ ┌────────────┐                       │
│               │  Display │ │ Placeholder │                      │
│               └──────────┘ └────────────┘                       │
└─────────────────────────────────────────────────────────────────┘
```

## Components

### 1. AssetImageManager (`lib/services/asset_image_manager.dart`)

Core service that manages local asset mapping.

**Features:**
- Maps product/category names to local asset paths
- Scans available assets on app startup
- Provides coverage reports for debugging
- Normalizes file names for matching

**Usage:**
```dart
final assetManager = AssetImageManager();
await assetManager.initialize();

// Check if local asset exists
final path = assetManager.getProductAssetPath('Mango');
// Returns: 'assets/images/products/mango.jpg' or null

// Get best image source
final source = assetManager.getProductImageSource(
  productName: 'Mango',
  networkUrl: 'https://cdn.example.com/mango.jpg',
);
// Returns local asset if available, otherwise network URL
```

### 2. HybridImage Widget (`lib/widgets/hybrid_image.dart`)

Smart image widget that automatically uses the best source.

**Usage:**
```dart
// For products
HybridImage.product(
  productName: 'Mango',
  networkUrl: product.imageUrl,
  category: 'Fruits',
  width: 100,
  height: 100,
)

// For categories
HybridImage.category(
  categoryName: 'Vegetables',
  networkUrl: category.imageUrl,
  width: 80,
  height: 80,
)
```

### 3. OptimizedImage Widget (`lib/widgets/optimized_image.dart`)

Enhanced CachedNetworkImage with local asset support.

**Usage:**
```dart
OptimizedImage(
  imageUrl: 'https://cdn.example.com/image.jpg',
  assetName: 'Mango', // Optional: check local first
  width: 100,
  height: 100,
)
```

### 4. ImagePreloader (`lib/widgets/hybrid_image.dart`)

Preloads critical images for instant display.

**Usage:**
```dart
// Preload category images on home screen
await ImagePreloader().preloadCriticalImages(context);

// Preload products when entering category
await ImagePreloader().preloadProductImages(context, productNames);
```

### 5. Image Sync Script (`scripts/sync_images.dart`)

Downloads images from backend to local assets.

**Run:**
```bash
dart run scripts/sync_images.dart
```

### 6. Image Verification Screen (`lib/screens/admin/image_verification_screen.dart`)

Admin screen to verify asset coverage.

## Asset Structure

```
assets/
└── images/
    ├── placeholder.png           # Default fallback image
    ├── categories/               # Category images
    │   ├── vegetables.jpg
    │   ├── fruits.jpg
    │   ├── dairy.jpg
    │   └── ...
    └── products/                 # Product images
        ├── mango.jpg
        ├── apple.jpg
        ├── milk.jpg
        └── ...
```

## File Naming Convention

Files are normalized for matching:
- Convert to lowercase
- Remove special characters
- Replace spaces with underscores

**Examples:**
- "Fresh Mango" → `fresh_mango.jpg`
- "Milk & Dairy" → `milk_dairy.jpg`
- "100% Natural Honey" → `100_natural_honey.jpg`

## Performance Benefits

| Metric | Before | After |
|--------|--------|-------|
| First Load | 2-5s (network) | <100ms (local) |
| Cached Load | 200-500ms | <50ms |
| Offline Support | ❌ | ✅ |
| APK Size Impact | 0 | ~5MB |

## Adding New Images

### Manual
1. Add image to `assets/images/products/` or `assets/images/categories/`
2. Name using convention: `product_name.jpg`
3. Run `flutter pub get` to update assets

### Automatic
1. Run sync script: `dart run scripts/sync_images.dart`
2. Images from backend are downloaded automatically

## Compression Guidelines

- **Max Resolution:** 800x800 pixels
- **Format:** JPEG for photos, PNG for icons
- **Quality:** 80% JPEG quality
- **Max File Size:** 100KB per image

## Troubleshooting

### Image not showing locally
1. Check file name matches (case-insensitive)
2. Run `flutter clean && flutter pub get`
3. Check `pubspec.yaml` has asset directories

### Coverage report shows missing images
1. Run sync script to download from backend
2. Or add images manually to asset folder
3. Check Image Verification screen in admin panel

## API Reference

### AssetImageManager

```dart
// Initialize (call once on app start)
await AssetImageManager().initialize();

// Get asset paths
String? getProductAssetPath(String productName);
String? getCategoryAssetPath(String categoryName);

// Check existence
bool hasProductAsset(String productName);
bool hasCategoryAsset(String categoryName);

// Get best source
ImageSource getProductImageSource({
  required String productName,
  String? networkUrl,
});

// Get coverage report
AssetCoverageReport getAssetCoverageReport(
  List<String> productNames,
  List<String> categoryNames,
);

// Get available assets
List<String> getAvailableProductAssets();
List<String> getAvailableCategoryAssets();
```

### ImageSource

```dart
enum ImageSourceType { asset, network }

class ImageSource {
  final ImageSourceType type;
  final String path;
  bool get isAsset;
  bool get isNetwork;
}
```

### AssetCoverageReport

```dart
class AssetCoverageReport {
  final int totalProducts;
  final int productsWithAssets;
  final int totalCategories;
  final int categoriesWithAssets;
  final List<String> missingProducts;
  final List<String> missingCategories;
  double get productCoverage;
  double get categoryCoverage;
}
```
