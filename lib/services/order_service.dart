import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aman_enterprises/models/order_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // For ChangeNotifier

class OrderService extends ChangeNotifier {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final String baseUrl = "https://aman-enterprises-api.onrender.com/api/v1";

  int _orderCount = 0;
  int get orderCount => _orderCount;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Update order count manually or fetch it
  Future<void> fetchOrderCount() async {
    try {
      final orders = await getMyOrders();
      _orderCount = orders.length;
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to fetch order count: $e");
    }
  }

  // Place Order
  Future<OrderModel> placeOrder({
    required List<Map<String, dynamic>> products,
    required Map<String, dynamic> deliveryAddress,
    required String paymentMethod,
    String? couponCode,
    Map<String, dynamic>? deliverySlot,
  }) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/order/place');

    final body = {
      "products": products,
      "deliveryAddress": deliveryAddress,
      "paymentMethod": paymentMethod,
      if (couponCode != null) "couponCode": couponCode,
      if (deliverySlot != null) "deliverySlot": deliverySlot,
    };

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final order = OrderModel.fromJson(data['order']);
      
      // Update count
      _orderCount++;
      notifyListeners();
      
      return order;
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to place order');
    }
  }

  // Get My Orders
  Future<List<OrderModel>> getMyOrders() async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/order/my');

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = (data['orders'] as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();
      
      // Update count
      _orderCount = list.length;
      notifyListeners();

      return list;
    } else {
      throw Exception('Failed to fetch orders');
    }
  }

  // Get Order Details / Track
  Future<OrderModel> getOrderDetails(String orderId) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/order/$orderId'); 

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return OrderModel.fromJson(data['order']);
    } else {
      throw Exception('Failed to fetch order details');
    }
  }

  // Cancel Order
  Future<void> cancelOrder(String orderId) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/order/$orderId/cancel');

    final response = await http.put(
      url,
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200) {
       throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to cancel order');
    }
    
    // Refresh count/stats if needed (cancelled still counts as order usually, but maybe we want active?)
    // For now, just refresh list
    fetchOrderCount(); 
  }
}
