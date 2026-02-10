import 'package:flutter/material.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/models/product_model.dart';
import 'package:aman_enterprises/services/cart_service.dart';
import 'package:aman_enterprises/services/user_service.dart';

/// Role-Aware Quantity Selector Widget
/// Adapts to user role:
/// - Customers (B2C): Simple +1/-1 controls
/// - Retailers (B2B): Pack-based +6/-6 controls with minimum quantity enforcement
class RoleAwareQuantitySelector extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool compact;

  const RoleAwareQuantitySelector({
    super.key,
    required this.product,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final isRetailer = userService.isRetailer;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // B2B Pack Size Indicator - Only shown for Retailers
        if (isRetailer && !compact)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              'Pack of ${product.b2bMinQty ?? 6}',
              style: TextStyle(
                fontSize: 9,
                color: Colors.blue.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        // Quantity Controls
        Container(
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(compact ? 6 : 8),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 4 : 8,
            vertical: compact ? 2 : 4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decrement Button
              InkWell(
                onTap: onDecrement,
                child: Icon(
                  Icons.remove,
                  color: Colors.white,
                  size: compact ? 14 : 18,
                ),
              ),

              // Quantity Display
              Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10),
                child: Text(
                  '$quantity',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: compact ? 12 : 14,
                  ),
                ),
              ),

              // Increment Button
              InkWell(
                onTap: onIncrement,
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: compact ? 14 : 18,
                ),
              ),
            ],
          ),
        ),

        // Step Indicator - For retailers to show increment info
        if (isRetailer && !compact)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '±${product.b2bMinQty ?? 6} units',
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey.shade600,
              ),
            ),
          ),
      ],
    );
  }
}

/// Simple Add to Cart Button
/// Shows "ADD" for Customers, "ADD 6" for Retailers
class RoleAwareAddButton extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final bool compact;

  const RoleAwareAddButton({
    super.key,
    required this.product,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Keep the widget simple with just "ADD" text for both B2B and B2C
    // Role-specific quantity rules are handled by CartService.addToCart()

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(compact ? 6 : 8),
          border: Border.all(color: AppColors.primaryGreen),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ADD',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: compact ? 10 : 12,
              ),
            ),
            // For B2B, show the minimum quantity they're adding
            // For B2C, keep it simple
            // Comment: Hidden for cleaner UI, enabled when needed
            // if (isRetailer) ...[
            //   const SizedBox(width: 4),
            //   Text(
            //     '$minQty',
            //     style: TextStyle(
            //       color: AppColors.primaryGreen,
            //       fontWeight: FontWeight.bold,
            //       fontSize: compact ? 8 : 10,
            //     ),
            //   ),
            // ],
          ],
        ),
      ),
    );
  }
}

/// Cart Quantity Manager Widget - Combines Add Button and Quantity Selector
/// Automatically switches between button and selector based on cart state
class CartQuantityManager extends StatelessWidget {
  final Product product;
  final CartService cartService;
  final bool compact;
  final Function(String message)? onAction;

  const CartQuantityManager({
    super.key,
    required this.product,
    required this.cartService,
    this.compact = false,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cartService,
      builder: (context, _) {
        final isInCart = cartService.isInCart(product.id);
        final quantity = cartService.getQuantity(product.id);
        final isOutOfStock = !product.inStock;

        // Out of Stock State
        if (isOutOfStock) {
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 6 : 8,
              vertical: compact ? 3 : 4,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(compact ? 4 : 6),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Text(
              'SOLD OUT',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: compact ? 8 : 10,
              ),
            ),
          );
        }

        // In Cart - Show Quantity Selector
        if (isInCart) {
          return RoleAwareQuantitySelector(
            product: product,
            quantity: quantity,
            onIncrement: () => cartService.incrementQuantity(product.id),
            onDecrement: () => cartService.decrementQuantity(product.id),
            compact: compact,
          );
        }

        // Not in Cart - Show Add Button
        return RoleAwareAddButton(
          product: product,
          compact: compact,
          onTap: () {
            cartService.addToCart(product);
            onAction?.call('${product.name} added to cart');
          },
        );
      },
    );
  }
}
