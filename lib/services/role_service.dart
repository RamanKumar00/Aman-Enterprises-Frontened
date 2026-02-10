import 'package:flutter/foundation.dart';
import 'package:aman_enterprises/services/user_service.dart';

/// User role types for strict typing
enum UserRole {
  customer,
  retailer,
  admin,
  guest,
}

/// Centralized Role Service for managing user roles and UI rendering rules
/// This ensures strict separation between B2C (Customer) and B2B (Retailer) experiences
class RoleService extends ChangeNotifier {
  static final RoleService _instance = RoleService._internal();
  factory RoleService() => _instance;
  RoleService._internal();

  UserRole _currentRole = UserRole.guest;
  bool _isInitialized = false;

  // ===========================================
  // GETTERS
  // ===========================================

  /// Current user role
  UserRole get currentRole => _currentRole;

  /// Check if user is a customer (B2C)
  bool get isCustomer => _currentRole == UserRole.customer;

  /// Check if user is a retailer (B2B)
  bool get isRetailer => _currentRole == UserRole.retailer;

  /// Check if user is admin
  bool get isAdmin => _currentRole == UserRole.admin;

  /// Check if user is logged in (not guest)
  bool get isLoggedIn => _currentRole != UserRole.guest;

  /// Check if role service has been initialized
  bool get isInitialized => _isInitialized;

  // ===========================================
  // QUANTITY RULES
  // ===========================================

  /// Minimum quantity for products (based on role)
  /// - Customers: Start from 1
  /// - Retailers: Start from 6 (B2B pack size)
  int getMinQuantity({int? b2bMinQty}) {
    if (isRetailer) {
      return b2bMinQty ?? 6;
    }
    return 1;
  }

  /// Quantity step/increment (based on role)
  /// - Customers: +1 / -1 freely
  /// - Retailers: +6 / -6 (must be multiples of pack size)
  int getQuantityStep({int? b2bMinQty}) {
    if (isRetailer) {
      return b2bMinQty ?? 6;
    }
    return 1;
  }

  /// Validate quantity based on role
  /// Returns error message if invalid, null if valid
  String? validateQuantity(int quantity, {int? b2bMinQty}) {
    if (isRetailer) {
      final minQty = b2bMinQty ?? 6;
      if (quantity < minQty) {
        return 'Minimum order quantity is $minQty units';
      }
      if (quantity % minQty != 0) {
        return 'Quantity must be a multiple of $minQty';
      }
    } else {
      if (quantity < 1) {
        return 'Quantity must be at least 1';
      }
    }
    return null;
  }

  /// Get the next valid quantity when incrementing
  int getIncrementedQuantity(int currentQty, {int? b2bMinQty}) {
    final step = getQuantityStep(b2bMinQty: b2bMinQty);
    return currentQty + step;
  }

  /// Get the next valid quantity when decrementing
  /// Returns 0 if should remove from cart
  int getDecrementedQuantity(int currentQty, {int? b2bMinQty}) {
    final step = getQuantityStep(b2bMinQty: b2bMinQty);
    final minQty = getMinQuantity(b2bMinQty: b2bMinQty);
    
    if (currentQty <= minQty) {
      return 0; // Remove from cart
    }
    return currentQty - step;
  }

  // ===========================================
  // UI VISIBILITY RULES
  // ===========================================

  /// Should show B2B labels (Min Qty, Pack Size, etc.)
  /// Only visible for Retailers
  bool get shouldShowB2BLabels => isRetailer;

  /// Should show B2B price
  /// Only visible for Retailers
  bool get shouldShowB2BPrice => isRetailer;

  /// Should show bulk purchase info
  bool get shouldShowBulkInfo => isRetailer;

  /// Should show consumer discounts (original price crossed out)
  bool get shouldShowConsumerDiscounts => isCustomer || isAdmin;

  // ===========================================
  // ROLE DETECTION & MANAGEMENT
  // ===========================================

  /// Fetch and set role from backend/local storage
  /// Call this on app startup and after login
  Future<void> detectRole() async {
    try {
      final userService = UserService();
      
      // Wait for user service to load if needed
      if (userService.isLoading) {
        await userService.loadUser();
      }

      final roleString = userService.role;
      _currentRole = _parseRole(roleString);
      _isInitialized = true;
      
      debugPrint('RoleService: Detected role = $_currentRole (from: $roleString)');
      notifyListeners();
    } catch (e) {
      debugPrint('RoleService: Error detecting role - $e');
      _currentRole = UserRole.guest;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Update role (call after login)
  void updateRole(String roleString) {
    final newRole = _parseRole(roleString);
    if (_currentRole != newRole) {
      _currentRole = newRole;
      _isInitialized = true;
      debugPrint('RoleService: Updated role to $_currentRole');
      notifyListeners();
    }
  }

  /// Clear role data on logout
  void clearRole() {
    _currentRole = UserRole.guest;
    _isInitialized = false;
    debugPrint('RoleService: Role cleared (logout)');
    notifyListeners();
  }

  /// Rebuild UI after role change
  void rebuildUI() {
    notifyListeners();
  }

  // ===========================================
  // PRIVATE HELPERS
  // ===========================================

  /// Parse role string to enum
  UserRole _parseRole(String? roleString) {
    if (roleString == null || roleString.isEmpty) {
      return UserRole.guest;
    }

    switch (roleString.toLowerCase()) {
      case 'customer':
        return UserRole.customer;
      case 'retailuser':
      case 'retailer':
      case 'b2b':
        return UserRole.retailer;
      case 'admin':
        return UserRole.admin;
      default:
        // Default to customer for unknown roles
        debugPrint('RoleService: Unknown role "$roleString", defaulting to customer');
        return UserRole.customer;
    }
  }

  // ===========================================
  // DEBUGGING
  // ===========================================

  @override
  String toString() {
    return 'RoleService(role: $_currentRole, isInitialized: $_isInitialized)';
  }
}
