import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:aman_enterprises/services/api_service.dart';
import 'package:aman_enterprises/services/user_service.dart';

/// Order status enum matching backend statuses
enum OrderStatus {
  placed(1, 'Order Placed', 'Your order has been placed'),
  confirmed(2, 'Order Confirmed', 'Seller has confirmed your order'),
  packed(3, 'Packed', 'Your order is packed and ready'),
  outForDelivery(4, 'Out for Delivery', 'Your order is on the way'),
  delivered(5, 'Delivered', 'Order delivered successfully'),
  cancelled(0, 'Cancelled', 'Order was cancelled');

  final int code;
  final String title;
  final String description;
  
  const OrderStatus(this.code, this.title, this.description);
  
  static OrderStatus fromCode(int code) {
    return OrderStatus.values.firstWhere(
      (s) => s.code == code,
      orElse: () => OrderStatus.placed,
    );
  }
  
  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
        return OrderStatus.placed;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'packed':
        return OrderStatus.packed;
      case 'out for delivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.placed;
    }
  }
}

/// Order tracking data model
class OrderTrackingInfo {
  final String orderId;
  final OrderStatus status;
  final bool isCancelled;
  final bool isDelivered;
  final DateTime updatedAt;

  OrderTrackingInfo({
    required this.orderId,
    required this.status,
    required this.isCancelled,
    required this.isDelivered,
    required this.updatedAt,
  });

  factory OrderTrackingInfo.fromJson(Map<String, dynamic> json) {
    return OrderTrackingInfo(
      orderId: json['orderId']?.toString() ?? '',
      status: OrderStatus.fromCode(json['statusCode'] ?? 1),
      isCancelled: json['isCancelled'] ?? false,
      isDelivered: json['isDelivered'] ?? false,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }
}

/// Order Tracking Service with HTTP Polling
/// Polls the server every [pollingInterval] seconds for order status updates
/// Automatically stops polling when order is delivered or cancelled
class OrderTrackingService extends ChangeNotifier {
  // Singleton pattern
  static final OrderTrackingService _instance = OrderTrackingService._internal();
  factory OrderTrackingService() => _instance;
  OrderTrackingService._internal();

  // Polling configuration
  static const Duration pollingInterval = Duration(seconds: 10);
  static const Duration fastPollingInterval = Duration(seconds: 5);
  
  // Active polling timers (orderId -> Timer)
  final Map<String, Timer> _pollingTimers = {};
  
  // Cached order statuses
  final Map<String, OrderTrackingInfo> _orderStatuses = {};
  
  // Status change callbacks
  final Map<String, Function(OrderTrackingInfo)> _statusCallbacks = {};

  /// Get cached status for an order
  OrderTrackingInfo? getStatus(String orderId) => _orderStatuses[orderId];

  /// Start polling for a specific order
  /// [onStatusChange] is called whenever status changes
  /// Polling automatically stops when order is delivered
  void startPolling(String orderId, {Function(OrderTrackingInfo)? onStatusChange}) {
    // Stop existing polling for this order if any
    stopPolling(orderId);
    
    if (onStatusChange != null) {
      _statusCallbacks[orderId] = onStatusChange;
    }
    
    // Fetch immediately
    _fetchOrderStatus(orderId);
    
    // Start periodic polling
    _pollingTimers[orderId] = Timer.periodic(pollingInterval, (_) {
      _fetchOrderStatus(orderId);
    });
    
    debugPrint('🔄 Started polling for order: $orderId');
  }

  /// Stop polling for a specific order
  void stopPolling(String orderId) {
    _pollingTimers[orderId]?.cancel();
    _pollingTimers.remove(orderId);
    _statusCallbacks.remove(orderId);
    debugPrint('⏹️ Stopped polling for order: $orderId');
  }

  /// Stop all polling (call when user logs out or app goes to background)
  void stopAllPolling() {
    for (var timer in _pollingTimers.values) {
      timer.cancel();
    }
    _pollingTimers.clear();
    _statusCallbacks.clear();
    debugPrint('⏹️ Stopped all order polling');
  }

  /// Fetch order status from server
  Future<void> _fetchOrderStatus(String orderId) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        debugPrint('❌ No auth token for polling');
        stopPolling(orderId);
        return;
      }

      final response = await ApiService.getOrderStatusForPolling(token, orderId);
      
      if (response.success && response.data != null) {
        final newStatus = OrderTrackingInfo.fromJson(response.data!);
        final oldStatus = _orderStatuses[orderId];
        
        // Check if status changed
        if (oldStatus == null || oldStatus.status != newStatus.status) {
          debugPrint('📦 Order $orderId status changed: ${newStatus.status.title}');
          
          // Update cache
          _orderStatuses[orderId] = newStatus;
          
          // Notify callback
          _statusCallbacks[orderId]?.call(newStatus);
          
          // Notify listeners (for widgets using ChangeNotifier)
          notifyListeners();
        }
        
        // Stop polling if delivered or cancelled
        if (newStatus.isDelivered || newStatus.isCancelled) {
          debugPrint('✅ Order $orderId completed. Stopping polling.');
          stopPolling(orderId);
        }
      }
    } catch (e) {
      debugPrint('❌ Polling error for order $orderId: $e');
    }
  }

  /// Manually refresh order status (for pull-to-refresh)
  Future<OrderTrackingInfo?> refreshStatus(String orderId) async {
    await _fetchOrderStatus(orderId);
    return _orderStatuses[orderId];
  }

  /// Get all active orders that need polling
  Future<List<Map<String, dynamic>>> getActiveOrders() async {
    try {
      final token = UserService().authToken;
      if (token == null) return [];

      final response = await ApiService.getActiveOrdersForPolling(token);
      
      if (response.success && response.data != null) {
        final activeOrders = response.data!['activeOrders'] as List? ?? [];
        return activeOrders.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('❌ Error fetching active orders: $e');
    }
    return [];
  }

  /// Start polling for all active orders
  Future<void> startPollingAllActiveOrders() async {
    final activeOrders = await getActiveOrders();
    for (var order in activeOrders) {
      final orderId = order['orderId']?.toString();
      if (orderId != null && !_pollingTimers.containsKey(orderId)) {
        startPolling(orderId);
      }
    }
  }
}
