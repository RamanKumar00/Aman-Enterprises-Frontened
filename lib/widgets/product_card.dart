import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/models/product_model.dart';
import 'package:aman_enterprises/services/cart_service.dart';
import 'package:aman_enterprises/services/user_service.dart';
import 'package:aman_enterprises/services/wishlist_service.dart';
import 'package:aman_enterprises/services/asset_image_manager.dart';
import 'package:aman_enterprises/screens/product_details_screen.dart';
import 'package:aman_enterprises/screens/cart_screen.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final bool compact; // For smaller grids if needed

  const ProductCard({
    super.key,
    required this.product,
    this.compact = false,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  final CartService _cartService = CartService();
  final WishlistService _wishlistService = WishlistService();
  final AssetImageManager _assetManager = AssetImageManager();

  @override
  Widget build(BuildContext context) {
    // Listen to changes to rebuild UI when cart/wishlist updates
    return ListenableBuilder(
      listenable: Listenable.merge([_cartService, _wishlistService]),
      builder: (context, _) => _buildCardContent(context),
    );
  }

  /// Build product image - prioritize local assets, fallback to network
  Widget _buildProductImage() {
    // Check if we have a local asset for this product
    final localAsset = _assetManager.getProductAssetPath(widget.product.name);
    
    if (localAsset != null) {
      // Use local asset (much faster!)
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLarge),
        ),
        child: Image.asset(
          localAsset,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to network if asset fails
            return _buildNetworkImage();
          },
        ),
      );
    }
    
    // Fallback to network image
    return _buildNetworkImage();
  }

  /// Build network image with caching
  Widget _buildNetworkImage() {
    if (widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLarge),
        ),
        child: CachedNetworkImage(
          imageUrl: widget.product.imageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(widget.product.iconColor),
            ),
          ),
          errorWidget: (context, url, error) => Center(
            child: Icon(
              widget.product.icon,
              size: 60,
              color: widget.product.iconColor,
            ),
          ),
        ),
      );
    }
    
    // No image available - show icon placeholder
    return Center(
      child: Icon(
        widget.product.icon,
        size: 60,
        color: widget.product.iconColor,
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    final isInWishlist = _wishlistService.isInWishlist(widget.product.id);
    final isInCart = _cartService.isInCart(widget.product.id);
    final isOutOfStock = !widget.product.inStock;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: widget.product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  // Product Image
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: widget.product.backgroundColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppDimensions.radiusLarge),
                      ),
                    ),
                    child: Hero(
                      tag: 'product_${widget.product.id}',
                      child: _buildProductImage(),
                    ),
                  ),
                  
                  // Out of Stock Overlay
                  if (isOutOfStock)
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5), // Fade out the image
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppDimensions.radiusLarge),
                        ),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          transform: Matrix4.rotationZ(-0.1), // Slight tilt
                          child: Text(
                            'SOLD OUT',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Discount Badge (Hide if out of stock to reduce clutter?) 
                  // Keeping it but maybe below overlays if needed.
                  if (!isOutOfStock && widget.product.discount > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        ),
                        child: Text(
                          '${widget.product.discount}% OFF',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                  // Favorite Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () async {
                        await _wishlistService.toggleWishlist(widget.product);
                        if (context.mounted) {
                          final added = _wishlistService.isInWishlist(widget.product.id);
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                added ? '${widget.product.name} added to wishlist' : '${widget.product.name} removed from wishlist',
                              ),
                              backgroundColor: added ? AppColors.primaryGreen : Colors.grey,
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(26),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          isInWishlist ? Icons.favorite : Icons.favorite_border,
                          color: isInWishlist ? Colors.red : AppColors.textLight,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info Section
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.product.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isOutOfStock ? AppColors.textLight : AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.product.unit,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                            Builder(
                              builder: (context) {
                                final userService = UserService();
                                final isRetailer = userService.isRetailer;
                                
                                // For Retailers: Show B2B price
                                // For Customers: Show regular price with discounts
                                final effectivePrice = (isRetailer && widget.product.b2bPrice != null) 
                                    ? widget.product.b2bPrice! 
                                    : widget.product.price;
                                
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                     Text(
                                      '₹${effectivePrice.toStringAsFixed(0)}',
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        color: isOutOfStock ? AppColors.textLight : AppColors.primaryGreen,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    // ONLY show B2B label for Retailers (B2B mode)
                                    // Customers should NOT see any B2B-related text
                                    if (isRetailer)
                                       Text(
                                         "B2B Price", 
                                         style: TextStyle(fontSize: 10, color: Colors.blue.shade800, fontWeight: FontWeight.bold)
                                       )
                                    // Show original price (crossed out) ONLY for Customers when there's a discount
                                    else if (widget.product.originalPrice != null && !isRetailer)
                                      Text(
                                        '₹${widget.product.originalPrice!.toStringAsFixed(0)}',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textLight,
                                          decoration: TextDecoration.lineThrough,
                                          fontSize: 10,
                                        ),
                                      ),
                                  ],
                                );
                              }
                            ),
                        
                        // Add to Cart / Quantity / Out of Stock
                        if (isOutOfStock)
                           Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: Text(
                                'SOLD OUT',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            )
                        else if (isInCart)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => _cartService.decrementQuantity(widget.product.id),
                                  child: const Icon(Icons.remove, color: Colors.white, size: 18),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    '${_cartService.getQuantity(widget.product.id)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _cartService.incrementQuantity(widget.product.id),
                                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                                ),
                              ],
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () {
                              _cartService.addToCart(widget.product);
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${widget.product.name} added to cart'),
                                  backgroundColor: AppColors.primaryGreen,
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  action: SnackBarAction(
                                    label: 'VIEW CART',
                                    textColor: Colors.white,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const CartScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primaryGreen),
                              ),
                              child: Text(
                                'ADD',
                                style: AppTextStyles.buttonText.copyWith(
                                  color: AppColors.primaryGreen,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
