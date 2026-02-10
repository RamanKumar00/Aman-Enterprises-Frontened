import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FlashDealModel {
  final double minOrderValue;
  final double discountPercentage;
  final bool isActive;

  FlashDealModel({
    required this.minOrderValue,
    required this.discountPercentage,
    required this.isActive,
  });

  factory FlashDealModel.fromJson(Map<String, dynamic> json) {
    return FlashDealModel(
      minOrderValue: (json['minOrderValue'] ?? 1000).toDouble(),
      discountPercentage: (json['discountPercentage'] ?? 5).toDouble(),
      isActive: json['isActive'] ?? false,
    );
  }
}

class FlashDealService {
  final String baseUrl = "https://aman-enterprises-api.onrender.com/api/v1";

  Future<FlashDealModel?> getActiveDeal() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/flash-deal/active'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['deal'] != null) {
          return FlashDealModel.fromJson(data['deal']);
        }
      }
    } catch (e) {
      debugPrint("Error fetching flash deal: $e");
    }
    return null;
  }

  Future<bool> updateDeal({
    required double minOrderValue,
    required double discountPercentage,
    required bool isActive,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/flash-deal/update'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "minOrderValue": minOrderValue,
          "discountPercentage": discountPercentage,
          "isActive": isActive
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint("Error updating flash deal: $e");
    }
    return false;
  }
}
