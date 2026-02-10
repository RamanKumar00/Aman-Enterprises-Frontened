import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeliverySlotService extends ChangeNotifier {
  static final DeliverySlotService _instance = DeliverySlotService._internal();
  factory DeliverySlotService() => _instance;
  DeliverySlotService._internal();

  final String baseUrl = "https://aman-enterprises-api.onrender.com/api/v1";
  
  // Slots grouped by Date (YYYY-MM-DD) -> List of slots
  Map<String, List<dynamic>> _slots = {};
  Map<String, List<dynamic>> get slots => _slots;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchAvailableSlots() async {
    _isLoading = true;
    notifyListeners();

    final token = await _getToken();
    if (token == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/delivery-slot/available'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _slots = Map<String, List<dynamic>>.from(data['slots']);
      }
    } catch (e) {
      debugPrint("Error fetching slots: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
