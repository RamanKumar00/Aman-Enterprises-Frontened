import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aman_enterprises/models/product_model.dart';
// Assume ApiService has baseUrl

class WishlistService extends ChangeNotifier {
  static final WishlistService _instance = WishlistService._internal();
  factory WishlistService() => _instance;
  WishlistService._internal();
  
  // Base URL should be consistent (ideally from ApiService constants)
  final String baseUrl = "https://aman-enterprises-api.onrender.com/api/v1";

  List<Product> _wishlistProducts = [];
  Set<String> _wishlistIds = {};

  List<Product> get wishlistProducts => List.unmodifiable(_wishlistProducts);
  Set<String> get wishlistIds => Set.unmodifiable(_wishlistIds);
  int get itemCount => _wishlistProducts.length;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  bool isInWishlist(String productId) {
    return _wishlistIds.contains(productId);
  }

  // Fetch Wishlist from Backend
  Future<void> fetchWishlist() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/wishlist/my'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['wishlist'];
        
        _wishlistProducts = items.map((item) {
           // Backend returns { product: {...}, addedAt: ... }
           // We need to map the nested 'product' object to Product model
           return Product.fromJson(item['product']);
        }).toList();

        _wishlistIds = _wishlistProducts.map((p) => p.id).toSet();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching wishlist: $e");
    }
  }

  // Toggle Wishlist (Add/Remove)
  Future<void> toggleWishlist(Product product) async {
    final isAdded = _wishlistIds.contains(product.id);
    
    // Optimistic Update
    if (isAdded) {
      _wishlistIds.remove(product.id);
      _wishlistProducts.removeWhere((p) => p.id == product.id);
    } else {
      _wishlistIds.add(product.id);
      _wishlistProducts.add(product);
    }
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) return;
      
      http.Response response;
      if (isAdded) {
        // Remove
        response = await http.delete(
          Uri.parse('$baseUrl/wishlist/remove/${product.id}'),
          headers: {"Authorization": "Bearer $token"},
        );
      } else {
        // Add
        response = await http.post(
          Uri.parse('$baseUrl/wishlist/add'),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
          body: jsonEncode({"productId": product.id}),
        );
      }

      if (response.statusCode != 200) {
        // Revert on failure
        fetchWishlist(); // Refresh from server to be safe
      }
    } catch (e) {
      debugPrint("Error toggling wishlist: $e");
       fetchWishlist(); // Refresh from server to be safe
    }
  }

  // Clear (Local only, usually on logout)
  void clearWishlist() {
    _wishlistIds.clear();
    _wishlistProducts.clear();
    notifyListeners();
  }
}
