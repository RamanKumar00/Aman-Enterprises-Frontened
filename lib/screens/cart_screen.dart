import 'package:flutter/material.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/services/cart_service.dart';
import 'package:aman_enterprises/screens/home_screen.dart';
import 'package:aman_enterprises/screens/checkout_new_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();

  @override
  void initState() {
    super.initState();
    _cartService.addListener(_update);
  }

  @override
  void dispose() {
    _cartService.removeListener(_update);
    super.dispose();
  }

  void _update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cartItems = _cartService.items;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: Text('My Cart (${_cartService.itemCount})', style: AppTextStyles.headingSmall),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context) ? const BackButton(color: Colors.black) : null,
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Cart?'),
                    content: const Text('Are you sure you want to remove all items?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          _cartService.clearCart();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return _buildCartItem(item);
                    },
                  ),
                ),
                _buildCheckoutSection(),
              ],
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: AppColors.primaryGreen.withAlpha(128),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your Cart is Empty',
            style: AppTextStyles.headingMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add some delicious items to get started!',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'Start Shopping',
              style: AppTextStyles.buttonText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: item.product.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: item.product.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        item.product.icon,
                        color: item.product.iconColor,
                        size: 40,
                      ),
                    ),
                  )
                : Icon(
                    item.product.icon,
                    color: item.product.iconColor,
                    size: 40,
                  ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  item.product.unit,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${(item.totalPrice / item.quantity).toStringAsFixed(0)}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Quantity Controls
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundCream,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => _cartService.decrementQuantity(item.product.id),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.remove, size: 16),
                      ),
                    ),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    InkWell(
                      onTap: () => _cartService.incrementQuantity(item.product.id),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.add, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection() {
    const double minOrderValue = 100.0;
    final double currentTotal = _cartService.totalPrice;
    final bool canCheckout = currentTotal >= minOrderValue;
    final double missingAmount = minOrderValue - currentTotal;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: AppTextStyles.bodyMedium),
              Text(
                '₹${currentTotal.toStringAsFixed(0)}',
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_cartService.isFlashDealApplied)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Row(
                   children: [
                     const Icon(Icons.flash_on, color: Colors.orange, size: 16),
                     const SizedBox(width: 4),
                     Text('Flash Deal (${(_cartService.flashDealPercentage * 100).toInt()}% OFF)', style: AppTextStyles.bodyMedium.copyWith(color: Colors.orange, fontWeight: FontWeight.bold)),
                   ],
                 ),
                 Text(
                  '-₹${_cartService.discountAmount.toStringAsFixed(0)}',
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600, color: Colors.orange),
                ),
              ],
            ),
          if (_cartService.isFlashDealApplied)
             const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delivery Fee', style: AppTextStyles.bodyMedium),
              Text(
                '₹40',
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTextStyles.headingSmall,
              ),
              Text(
                '₹${(_cartService.finalPrice + 40).toStringAsFixed(0)}',
                style: AppTextStyles.headingSmall.copyWith(color: AppColors.primaryGreen),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (!_cartService.isFlashDealApplied && _cartService.isDealActive && _cartService.totalPrice < _cartService.flashDealThreshold)
             Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withAlpha(128)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer, color: Colors.blue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Shop for ₹${(_cartService.flashDealThreshold - _cartService.totalPrice).toStringAsFixed(0)} more to get ${(_cartService.flashDealPercentage * 100).toInt()}% OFF!',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          if (!canCheckout)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withAlpha(128)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add items worth ₹${missingAmount.toStringAsFixed(0)} more to order',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: canCheckout ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CheckoutScreen()), // Class name is still CheckoutScreen inside the new file
                );
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: canCheckout ? 4 : 0,
              ),
              child: Text(
                canCheckout ? 'Proceed to Checkout' : 'Minimum Order ₹100',
                style: AppTextStyles.buttonText.copyWith(
                  fontSize: 18,
                  color: canCheckout ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
