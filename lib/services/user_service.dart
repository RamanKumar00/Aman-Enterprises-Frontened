import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User session service to manage authentication state and tokens
/// Provides secure session persistence with auto-refresh and expiry handling
class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal() {
    loadUser();
  }

  Map<String, dynamic>? _currentUser;
  String? _authToken;
  DateTime? _loginTimestamp;
  bool _isLoading = true;
  
  // Session expiry duration (30 days)
  static const int sessionExpiryDays = 30;

  // Getters
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get authToken => _authToken;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null && _authToken != null;

  // User info getters
  String get name => _currentUser?['name'] ?? _currentUser?['shopName'] ?? _currentUser?['displayName'] ?? 'User';
  String get email => _currentUser?['email'] ?? '';
  String get phone => _currentUser?['phone'] ?? '';
  String? get photoUrl => _currentUser?['photoURL'] ?? _currentUser?['avatar'];
  String get userId => _currentUser?['_id'] ?? _currentUser?['id'] ?? '';
  String get role => _currentUser?['role'] ?? 'Customer';
  String get address => _currentUser?['address'] ?? '';
  String get city => _currentUser?['city'] ?? '';
  String get state => _currentUser?['state'] ?? '';
  String get pincode => _currentUser?['pincode'] ?? '';

  // ===========================================
  // ROLE-BASED HELPERS (Strict Role Detection)
  // ===========================================

  /// Check if current user is a Customer (B2C)
  /// Customers get simple, flexible shopping experience
  bool get isCustomer => role.toLowerCase() == 'customer';

  /// Check if current user is a Retailer (B2B)
  /// Retailers get bulk purchase rules with pack sizes
  bool get isRetailer => role.toLowerCase() == 'retailuser' || role.toLowerCase() == 'retailer';

  /// Check if current user is an Admin
  bool get isAdmin => role.toLowerCase() == 'admin';

  /// Check if user is a guest (not logged in)
  bool get isGuest => !isLoggedIn;

  /// Load user and token from local storage
  Future<void> loadUser() async {
    if (!_isLoading) _isLoading = true;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load user data
      final userData = prefs.getString('user_data');
      if (userData != null) {
        _currentUser = jsonDecode(userData);
      }
      
      // Load auth token
      _authToken = prefs.getString('auth_token');
      
      // Load login timestamp
      final timestamp = prefs.getInt('login_timestamp');
      if (timestamp != null) {
        _loginTimestamp = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      
    } catch (e) {
      debugPrint('Error loading user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save user data and token after successful login
  /// Also saves login timestamp for session expiry tracking
  Future<void> saveUser(Map<String, dynamic> user, {String? token}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save user data
      await prefs.setString('user_data', jsonEncode(user));
      _currentUser = user;
      
      // Save token if provided
      if (token != null) {
        await prefs.setString('auth_token', token);
        _authToken = token;
      }
      
      // Save login timestamp for session expiry tracking
      _loginTimestamp = DateTime.now();
      await prefs.setInt('login_timestamp', _loginTimestamp!.millisecondsSinceEpoch);
      
      debugPrint('[UserService] Session saved for user: ${user['name'] ?? user['shopName']}');
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving user: $e');
    }
  }

  /// Update user data without changing token or session
  Future<void> updateUser(Map<String, dynamic> user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(user));
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user: $e');
    }
  }

  /// Clear user session (logout)
  Future<void> clearUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.remove('auth_token');
      await prefs.remove('login_timestamp');
      _currentUser = null;
      _authToken = null;
      _loginTimestamp = null;
      debugPrint('[UserService] Session cleared - user logged out');
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing user: $e');
    }
  }

  /// Check if user session is valid (token exists and not expired)
  /// Returns true if user is logged in and session hasn't expired
  Future<bool> isSessionValid() async {
    await loadUser();
    
    // Check if basic login state is valid
    if (!isLoggedIn) {
      return false;
    }
    
    // Check for session expiry
    if (_loginTimestamp != null) {
      final now = DateTime.now();
      final expiryDate = _loginTimestamp!.add(Duration(days: sessionExpiryDays));
      
      if (now.isAfter(expiryDate)) {
        debugPrint('[UserService] Session expired - clearing user data');
        await clearUser();
        return false;
      }
    }
    
    return true;
  }

  /// Refresh session timestamp (call after successful API interaction)
  Future<void> refreshSession() async {
    if (isLoggedIn) {
      try {
        final prefs = await SharedPreferences.getInstance();
        _loginTimestamp = DateTime.now();
        await prefs.setInt('login_timestamp', _loginTimestamp!.millisecondsSinceEpoch);
        debugPrint('[UserService] Session refreshed');
      } catch (e) {
        debugPrint('Error refreshing session: $e');
      }
    }
  }

  /// Get remaining session days
  int get remainingSessionDays {
    if (_loginTimestamp == null) return 0;
    final expiryDate = _loginTimestamp!.add(Duration(days: sessionExpiryDays));
    final remaining = expiryDate.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// Get full address string
  String get fullAddress {
    final parts = <String>[];
    if (address.isNotEmpty) parts.add(address);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (pincode.isNotEmpty) parts.add(pincode);
    return parts.join(', ');
  }
}
