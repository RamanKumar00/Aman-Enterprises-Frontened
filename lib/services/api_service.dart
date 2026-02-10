import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // --------------------------------------------------------
  // 🔧 CONFIGURATION: TOGGLE THIS FOR DEV/PROD
  // --------------------------------------------------------
  // Set to TRUE to use Render (Production) URL for global access
  // Set to FALSE to use Local IP (Development)
  static const bool isProduction = true;

  // Your Local IP (Used only when isProduction = false)
  static const String _localServerIP = '192.168.1.10'; // Updated to a more common generic local IP or keep your specific one
  
  // Automatically detect the correct base URL
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    }
    
    if (isProduction) {
      return 'https://aman-enterprises-api.onrender.com/api/v1';
    } else {
      // Local Development
      try {
        if (Platform.isAndroid) {
          return 'http://$_localServerIP:3000/api/v1';
        }
      } catch (e) {
        // Platform specific error
      }
      return 'http://localhost:3000/api/v1'; // Fallback
    }
  }

  /// Wake up the Render server (call this on app start)
  static Future<void> wakeUp() async {
    if (!isProduction) return;
    try {
      debugPrint('⚡ Waking up production server...');
      // Hitting the root URL to wake it up
      final rootUrl = 'https://aman-enterprises-api.onrender.com/';
      await http.get(Uri.parse(rootUrl)).timeout(const Duration(seconds: 10));
      debugPrint('✅ Server is awake!');
    } catch (e) {
      debugPrint('⚠️ Server wake-up signal sent (might need more time): $e');
    }
  }
  
  // Headers for JSON requests
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Headers with auth token
  static Map<String, String> authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ==================== USER AUTHENTICATION ====================

  /// Register a new user
  /// Required: shopName, phone, email, address, pincode, state, city, role, password
  static Future<ApiResponse> register({
    required String shopName,
    required String phone,
    required String email,
    required String address,
    required String pincode,
    required String state,
    required String city,
    required String role,
    required String password,
    String? adminSecretKey,
  }) async {
    try {
      final body = {
        'shopName': shopName,
        'phone': phone,
        'email': email,
        'address': address,
        'pincode': pincode,
        'state': state,
        'city': city,
        'role': role,
        'password': password,
      };

      if (adminSecretKey != null) {
        body['adminSecretKey'] = adminSecretKey;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/user/register'),
        headers: _headers,
        body: jsonEncode(body),
      );

      return handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Connection error: ${e.toString()}',
      );
    }
  }

  /// Login with phone and password
  static Future<ApiResponse> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/login'),
        headers: _headers,
        body: jsonEncode({
          'phone': phone,
          'password': password,
        }),
      );

      return handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Connection error: ${e.toString()}',
      );
    }
  }

  /// Send OTP to verify email
  static Future<ApiResponse> sendOtpToVerifyEmail({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/otp-verify-email'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
        }),
      );

      return handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Connection error: ${e.toString()}',
      );
    }
  }

  /// Verify email OTP
  static Future<ApiResponse> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/verify-email'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      return handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Connection error: ${e.toString()}',
      );
    }
  }

  /// Send OTP for password recovery
  static Future<ApiResponse> sendOtpForPasswordRecovery({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/otp-generate-password'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
        }),
      );

      return handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Connection error: ${e.toString()}',
      );
    }
  }

  /// Verify OTP for password recovery
  static Future<ApiResponse> verifyPasswordRecoveryOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/verify-otp-generate-password'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      return handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Connection error: ${e.toString()}',
      );
    }
  }

  /// Create new password after OTP verification
  static Future<ApiResponse> createNewPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/create-password'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );

      return handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Connection error: ${e.toString()}',
      );
    }
  }

  /// Update FCM Token
  static Future<ApiResponse> updateFcmToken(String token, String fcmToken) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/fcm'),
        headers: authHeaders(token),
        body: jsonEncode({'fcmToken': fcmToken}),
      );
      return handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: ${e.toString()}');
    }
  }

  /// Get user details (requires authentication)
  static Future<ApiResponse> getUserDetails(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/details/me'),
        headers: authHeaders(token),
      );

      return handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Connection error: ${e.toString()}',
      );
    }
  }

  // ==================== PRODUCT & CATEGORY APIs ====================

  /// Fetch all categories
  static Future<ApiResponse> getCategories() async {
    try {
      // Backend: /api/v1/category/
      final url = '$baseUrl/category/'; 
      debugPrint('Fetching categories from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers, // Note: Might need authHeaders if backend requires it
      );

      return handleResponse(response);
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return ApiResponse(
        success: false,
        message: 'Connection error: ${e.toString()}',
      );
    }
  }

  /// Search products
  static Future<ApiResponse> searchProduct(String query) async {
    try {
      final url = '$baseUrl/product/search?query=$query';
      debugPrint('Searching products: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      return handleResponse(response);
    } catch (e) {
      debugPrint('Error searching products: $e');
      return ApiResponse(
        success: false,
        message: 'Connection error: ${e.toString()}',
      );
    }
  }

  /// Get products by category name (filters from all products)
  /// This is more reliable than search for category-based product listing
  static Future<ApiResponse> getProductsByCategory(String categoryName) async {
    try {
      // First try to get all products and filter locally
      final response = await getProducts();
      
      if (response.success && response.data != null) {
        final List<dynamic> allProducts = response.data!['products'] ?? [];
        
        // Filter products by category (case-insensitive)
        final categoryLower = categoryName.toLowerCase();
        final filteredProducts = allProducts.where((product) {
          final productCategory = (product['parentCategory'] ?? product['category'] ?? '').toString().toLowerCase();
          final subCategory = (product['subCategory'] ?? '').toString().toLowerCase();
          
          return productCategory.contains(categoryLower) || 
                 categoryLower.contains(productCategory) ||
                 subCategory.contains(categoryLower);
        }).toList();
        
        return ApiResponse(
          success: true,
          message: 'Products fetched successfully',
          data: {'products': filteredProducts},
        );
      }
      
      return response;
    } catch (e) {
      debugPrint('Error fetching products by category: $e');
      return ApiResponse(
        success: false,
        message: 'Connection error: ${e.toString()}',
      );
    }
  }

  /// Fetch all products (PUBLIC - no auth required)
  static Future<ApiResponse> getProducts() async {
    try {
      final url = '$baseUrl/product/paginated';
      debugPrint('Fetching products from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      return handleResponse(response);
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return ApiResponse(
        success: false,
        message: 'Connection error: ${e.toString()}',
      );
    }
  }

  /// Get home screen data (banners + categories)
  static Future<ApiResponse> getHomeScreenData(String token) async {
    try {
      final url = '$baseUrl/product/homescreendata';
      debugPrint('Fetching home screen data from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: authHeaders(token),
      );

      return handleResponse(response);
    } catch (e) {
      debugPrint('Error fetching home screen data: $e');
      return ApiResponse(
        success: false,
        message: 'Connection error: ${e.toString()}',
      );
    }
  }

  // ==================== CART APIs ====================

  /// Get user's cart
  static Future<ApiResponse> getCart(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/order/cart'),
        headers: authHeaders(token),
      );
      return handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: ${e.toString()}');
    }
  }

  /// Add item to cart
  static Future<ApiResponse> addToCart(String token, String productId, {int quantity = 1}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/order/cart/add'),
        headers: authHeaders(token),
        body: jsonEncode({'productId': productId, 'quantity': quantity}),
      );
      return handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: ${e.toString()}');
    }
  }

  /// Remove item from cart
  static Future<ApiResponse> removeFromCart(String token, String productId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/order/cart/remove'),
        headers: authHeaders(token),
        body: jsonEncode({'productId': productId}),
      );
      return handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: ${e.toString()}');
    }
  }

  /// Update cart item quantity
  static Future<ApiResponse> updateCartQuantity(String token, String productId, int quantity) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/order/cart/update'),
        headers: authHeaders(token),
        body: jsonEncode({'productId': productId, 'quantity': quantity}),
      );
      return handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: ${e.toString()}');
    }
  }

  /// Clear entire cart
  static Future<ApiResponse> clearCart(String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/order/cart/clear'),
        headers: authHeaders(token),
      );
      return handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: ${e.toString()}');
    }
  }

  // ==================== ORDER APIs ====================

  /// Place a new order
  static Future<ApiResponse> placeOrder(String token, List<Map<String, dynamic>> products) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/order/place'),
        headers: authHeaders(token),
        body: jsonEncode({'products': products}),
      );
      return handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: ${e.toString()}');
    }
  }

  /// Get user's orders
  static Future<ApiResponse> getOrders(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/order/my-orders'),
        headers: authHeaders(token),
      );
      return handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: ${e.toString()}');
    }
  }

  /// Get single order by ID
  static Future<ApiResponse> getOrderById(String token, String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/order/$orderId'),
        headers: authHeaders(token),
      );
      return handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: ${e.toString()}');
    }
  }

  /// Cancel an order
  static Future<ApiResponse> cancelOrder(String token, String orderId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/order/cancel/$orderId'),
        headers: authHeaders(token),
      );
      return handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: ${e.toString()}');
    }
  }

  // ==================== ORDER TRACKING (HTTP POLLING) ====================

  /// Get order status for polling - lightweight endpoint
  /// Call this every 5-10 seconds for active orders
  static Future<ApiResponse> getOrderStatusForPolling(String token, String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/order/status?orderId=$orderId'),
        headers: authHeaders(token),
      );
      return handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: ${e.toString()}');
    }
  }

  /// Get all active orders that need polling
  static Future<ApiResponse> getActiveOrdersForPolling(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/order/active-orders'),
        headers: authHeaders(token),
      );
      return handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: ${e.toString()}');
    }
  }


  // ==================== ADMIN APIs ====================

  /// Add a new product (Admin)
  static Future<ApiResponse> addProduct(String token, Map<String, dynamic> data, File? image) async {
    try {
      final uri = Uri.parse('$baseUrl/product/addnew');
      var request = http.MultipartRequest('POST', uri);
      
      // Add Auth only - do NOT set Content-Type to application/json for Multipart!
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      
      // Add text fields
      data.forEach((key, value) {
        request.fields[key] = value.toString();
      });
      
      // Add image
      if (image != null) {
        request.files.add(await http.MultipartFile.fromPath('doc', image.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: ${e.toString()}');
    }
  }

  /// Update an existing product (Admin)
  static Future<ApiResponse> updateProduct(String token, String? productId, Map<String, dynamic> data, File? image) async {
    try {
      final uri = Uri.parse('$baseUrl/product/update/$productId');
      var request = http.MultipartRequest('PUT', uri);
      
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      
      data.forEach((key, value) {
        request.fields[key] = value.toString();
      });
      
      if (image != null) {
        request.files.add(await http.MultipartFile.fromPath('doc', image.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: ${e.toString()}');
    }
  }

  /// Add a new category (Admin)
  static Future<ApiResponse> addCategory(String token, String name, File? image) async {
    try {
      final uri = Uri.parse('$baseUrl/category/addnew');
      var request = http.MultipartRequest('POST', uri);
      
       // Add Auth only
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      
      request.fields['category'] = name;
      
      if (image != null) {
         request.files.add(await http.MultipartFile.fromPath('doc', image.path)); 
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: ${e.toString()}');
    }
  }

  /// Delete a category (Admin)
  static Future<ApiResponse> deleteCategory(String token, String publicId, String categoryName) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/category/'),
        headers: authHeaders(token),
        body: jsonEncode({
          'publicId': publicId,
          'categoryName': categoryName,
        }),
      );
      return handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: ${e.toString()}');
    }
  }

  /// Update a category (Admin)
  static Future<ApiResponse> updateCategory(String token, String categoryId, String? newName, File? newImage) async {
    try {
      final uri = Uri.parse('$baseUrl/category/update/$categoryId');
      var request = http.MultipartRequest('PUT', uri);
      
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      
      if (newName != null && newName.isNotEmpty) {
        request.fields['categoryName'] = newName;
      }
      
      if (newImage != null) {
        request.files.add(await http.MultipartFile.fromPath('doc', newImage.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: ${e.toString()}');
    }
  }

  /// Get ALL products (Admin) - Authenticated
  static Future<ApiResponse> getProductsAdmin(String token) async {
    try {
      final url = '$baseUrl/product/paginated';
      final response = await http.get(
        Uri.parse(url),
        headers: authHeaders(token),
      );
      return handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: ${e.toString()}');
    }
  }

  /// Get All Users (Admin)
  static Future<ApiResponse> getAllUsersAdmin(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/admin/all-users'),
        headers: authHeaders(token),
      );
      return handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: ${e.toString()}');
    }
  }

  /// Update User Role (Admin)
  static Future<ApiResponse> updateUserRole(String token, String userId, String newRole) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/admin/update-role/$userId'),
        headers: authHeaders(token),
        body: jsonEncode({'role': newRole}),
      );
      return handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: ${e.toString()}');
    }
  }

  /// Delete Product (Admin)
  static Future<ApiResponse> deleteProduct(String token, String productId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/product/delete/$productId'),
        headers: authHeaders(token),
      );
      return handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: ${e.toString()}');
    }
  }

  /// Get Dashboard Stats (Admin)
  static Future<ApiResponse> getDashboardStats(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/dashboard'),
        headers: authHeaders(token),
      );
      return handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: ${e.toString()}');
    }
  }

  static Future<ApiResponse> getAllOrdersAdmin(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/order/admin/all-orders'),
        headers: authHeaders(token),
      );
      return handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: ${e.toString()}');
    }
  }

  /// Update Order Status (Admin)
  static Future<ApiResponse> updateOrderStatus(String token, String orderId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/order/update-status/$orderId'),
        headers: authHeaders(token),
        body: jsonEncode({'status': status}),
      );
      return handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: ${e.toString()}');
    }
  }

  // ==================== HELPER METHODS ====================

  static ApiResponse handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          success: true,
          message: data['message'] ?? 'Success',
          data: data,
          token: data['token'],
        );
      } else {
        return ApiResponse(
          success: false,
          message: data['message'] ?? data['error'] ?? 'Something went wrong',
          data: data,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to parse response: ${e.toString()}',
      );
    }
  }
}

/// Response wrapper class
class ApiResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final String? token;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.token,
  });
}
