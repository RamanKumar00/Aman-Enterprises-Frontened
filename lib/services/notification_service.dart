import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:aman_enterprises/services/api_service.dart';
import 'package:aman_enterprises/services/user_service.dart';
import 'package:aman_enterprises/widgets/order_notification_overlay.dart';
import 'package:flutter/material.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  
  // Global context for showing overlays
  BuildContext? _globalContext;
  
  // Callback for navigating to orders screen
  VoidCallback? _onNavigateToOrders;
  
  // In-app notifications list for display in NotificationsScreen
  final List<Map<String, dynamic>> _notifications = [];
  
  /// Set the global context for overlay display (call this from admin dashboard)
  void setGlobalContext(BuildContext context) {
    _globalContext = context;
  }
  
  /// Set callback for navigating to orders (call from admin dashboard)
  void setOrdersNavigationCallback(VoidCallback callback) {
    _onNavigateToOrders = callback;
  }

  // ===========================================
  // GETTERS FOR UI
  // ===========================================
  
  /// Get all notifications
  List<Map<String, dynamic>> get notifications => List.unmodifiable(_notifications);
  
  /// Get unread notification count
  int get unreadCount => _notifications.where((n) => n['isRead'] == false).length;

  // ===========================================
  // INITIALIZATION
  // ===========================================

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Request Permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      debugPrint('User granted permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // 2. Init Local Notifications
        await _initLocalNotifications();

        // 3. Get Token and Sync
        try {
          String? token = await _messaging.getToken();
          if (token != null) {
            debugPrint('FCM Token: $token');
            await _syncTokenToServer(token);
          }
        } catch(e) {
          debugPrint('Error getting FCM token: $e');
        }

        // 4. Token Refresh Listener
        _messaging.onTokenRefresh.listen(_syncTokenToServer);

        // 5. Handle Foreground Messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Got a message whilst in the foreground!');
          debugPrint('Message data: ${message.data}');

          if (message.notification != null) {
            debugPrint('Message also contained a notification: ${message.notification}');
            _showLocalNotification(message);
            _addNotification(message);
            
            // Show in-app overlay for NEW_ORDER notifications if context is available
            if (message.data['type'] == 'NEW_ORDER' && _globalContext != null) {
              _showInAppOrderNotification(message);
            }
          }
        });
        
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  Future<void> _syncTokenToServer(String fcmToken) async {
    final userService = UserService();
    final authToken = userService.authToken;
    // Only update if user is logged in (has auth token)
    if (authToken != null && authToken.isNotEmpty) {
       await ApiService.updateFcmToken(authToken, fcmToken);
       debugPrint('FCM Token synced to server');
    }
  }

  Future<void> _initLocalNotifications() async {
    // Android Setup
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); 

    // iOS Setup
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // flutter_local_notifications 20.0.0 uses named parameters
    await _localNotifications.initialize(settings: initializationSettings);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    // flutter_local_notifications 20.0.0+ requires named parameters
    await _localNotifications.show(
      id: 0,
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      notificationDetails: platformChannelSpecifics,
      payload: 'item x',
    );
  }

  /// Show in-app overlay notification for new orders (Admin only)
  void _showInAppOrderNotification(RemoteMessage message) {
    if (_globalContext == null) return;
    
    try {
      OrderNotificationManager().showOrderNotification(
        context: _globalContext!,
        title: message.notification?.title ?? 'New Order!',
        message: message.notification?.body ?? 'A new order has been placed',
        orderId: message.data['orderId'],
        trackingId: message.data['trackingId'],
        onTap: () {
          // Navigate to orders screen when tapped
          _onNavigateToOrders?.call();
        },
      );
    } catch (e) {
      debugPrint('Error showing in-app notification: $e');
    }
  }

  // ===========================================
  // NOTIFICATION MANAGEMENT (for NotificationsScreen)
  // ===========================================
  
  /// Add a notification from FCM message
  void _addNotification(RemoteMessage message) {
    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': message.notification?.title ?? 'New Notification',
      'message': message.notification?.body ?? '',
      'time': 'Just now',
      'isRead': false,
      'type': message.data['type'] ?? 'general',
      'icon': _getIconForType(message.data['type']),
      'color': _getColorForType(message.data['type']),
    };
    
    _notifications.insert(0, notification);
    notifyListeners();
  }
  
  /// Add a manual notification (e.g., for orders)
  void addManualNotification({
    required String title,
    required String message,
    String type = 'general',
  }) {
    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'message': message,
      'time': 'Just now',
      'isRead': false,
      'type': type,
      'icon': _getIconForType(type),
      'color': _getColorForType(type),
    };
    
    _notifications.insert(0, notification);
    notifyListeners();
  }
  
  /// Delete a notification by ID
  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n['id'] == id);
    notifyListeners();
  }
  
  /// Mark a notification as read
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n['id'] == id);
    if (index >= 0) {
      _notifications[index]['isRead'] = true;
      notifyListeners();
    }
  }
  
  /// Mark all notifications as read
  void markAllAsRead() {
    for (var notification in _notifications) {
      notification['isRead'] = true;
    }
    notifyListeners();
  }
  
  /// Clear all notifications
  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }
  
  /// Get icon based on notification type
  IconData _getIconForType(String? type) {
    switch (type) {
      case 'order':
        return Icons.shopping_bag_rounded;
      case 'promo':
        return Icons.local_offer_rounded;
      case 'delivery':
        return Icons.local_shipping_rounded;
      case 'NEW_ORDER':
        return Icons.receipt_long_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
  
  /// Get color based on notification type
  Color _getColorForType(String? type) {
    switch (type) {
      case 'order':
        return Colors.blue;
      case 'promo':
        return Colors.orange;
      case 'delivery':
        return Colors.green;
      case 'NEW_ORDER':
        return Colors.purple;
      default:
        return Colors.teal;
    }
  }
}

