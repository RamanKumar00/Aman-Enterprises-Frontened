import 'package:flutter/foundation.dart';
import 'package:aman_enterprises/models/product_model.dart';
import 'package:aman_enterprises/services/user_service.dart';
import 'package:aman_enterprises/services/flash_deal_service.dart';

/// Cart item model that contains product and quantity
class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice {
    final userService = UserService();
    // Use isRetailer getter for proper role detection
    final effectivePrice = (userService.isRetailer && product.b2bPrice != null) ? product.b2bPrice! : product.price;
    return effectivePrice * quantity;
  }
}

/// Cart service to manage shopping cart state
class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];

  /// Get all cart items
  List<CartItem> get items => List.unmodifiable(_items);

  /// Get total number of items in cart
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Get total price of all items in cart
  double get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);

  /// Check if a product is in the cart
  bool isInCart(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  /// Get quantity of a product in cart
  int getQuantity(String productId) {
    final item = _items.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => CartItem(product: Product.sampleProducts.first, quantity: 0),
    );
    return item.product.id == productId ? item.quantity : 0;
  }

  /// Add a product to the cart
  /// For Customers (B2C): Add with quantity 1, increment by 1 - NO forced quantities
  /// For Retailers (B2B): Add with minimum pack size, increment by pack size
  void addToCart(Product product, {int? quantity}) {
    final userService = UserService();
    final isRetailer = userService.isRetailer;
    
    // Quantity rules:
    // - Customers: Min 1, Step 1 (completely free choice)
    // - Retailers: Min 6 (or b2bMinQty), Step 6 (must be multiples)
    final minQty = isRetailer ? (product.b2bMinQty ?? 6) : 1;
    final step = isRetailer ? (product.b2bMinQty ?? 6) : 1;
    
    // Default add quantity: Customers get 1, Retailers get pack size
    // If quantity is explicitly provided, use that
    int addQty = quantity ?? (isRetailer ? step : 1);

    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex >= 0) {
      // Product already in cart - add the step amount
      _items[existingIndex].quantity += (quantity ?? step);
    } else {
      // New item - customers start at 1, retailers at pack size
      _items.add(CartItem(product: product, quantity: addQty >= minQty ? addQty : minQty));
    }
    notifyListeners();
  }

  /// Remove a product from the cart
  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  /// Update quantity of a product in cart
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  /// Increment quantity of a product
  /// Customers: +1 freely
  /// Retailers: +6 (pack size) to maintain multiples
  void incrementQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final userService = UserService();
      final step = userService.isRetailer ? (_items[index].product.b2bMinQty ?? 6) : 1;
      
      _items[index].quantity += step;
      notifyListeners();
    }
  }

  /// Decrement quantity of a product
  /// Customers: -1 freely, remove when reaching 0
  /// Retailers: -6 (pack size), remove when reaching below pack size
  void decrementQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final userService = UserService();
      final minQty = userService.isRetailer ? (_items[index].product.b2bMinQty ?? 6) : 1;
      final step = minQty;
      
      if (_items[index].quantity > minQty) {
        _items[index].quantity -= step;
      } else {
        // Remove from cart when at or below minimum
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  /// Clear all items from cart
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // --- Flash Deal Logic ---
  
  double _flashDealThreshold = 1000.0;
  double _flashDealPercentage = 0.05; // 5%
  bool _isDealActive = true;

  // Public Getters for UI access
  double get flashDealThreshold => _flashDealThreshold;
  double get flashDealPercentage => _flashDealPercentage;
  bool get isDealActive => _isDealActive;

  bool get isFlashDealApplied => _isDealActive && totalPrice >= _flashDealThreshold;

  double get discountAmount {
    if (isFlashDealApplied) {
      return totalPrice * _flashDealPercentage;
    }
    return 0.0;
  }

  double get finalPrice => totalPrice - discountAmount;

  // New Method to fetch rules
  Future<void> fetchDealRules() async {
    try {
      final FlashDealService flashDealService = FlashDealService();
      final deal = await flashDealService.getActiveDeal();
      if (deal != null) {
        _flashDealThreshold = deal.minOrderValue;
        _flashDealPercentage = deal.discountPercentage / 100.0;
        _isDealActive = deal.isActive;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Failed to fetch deal rules: $e");
    }
  }
}
