import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aman_enterprises/services/api_service.dart';
import 'package:aman_enterprises/services/user_service.dart';
import 'package:aman_enterprises/models/courier_models.dart';

class CourierService {
  // Singleton pattern
  static final CourierService _instance = CourierService._internal();
  factory CourierService() => _instance;
  CourierService._internal();

  String get _baseUrl => ApiService.baseUrl;

  // Helper to get headers with auth token
  Map<String, String> get _headers {
    final token = UserService().authToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get all courier partners
  Future<List<CourierPartner>> getCourierPartners() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/courier/partners'),
        headers: _headers,
      );

      final result = ApiService.handleResponse(response);
      if (result.success && result.data != null) {
        final partners = result.data!['partners'] as List?;
        return partners?.map((e) => CourierPartner.fromJson(e)).toList() ?? [];
      }
      throw Exception(result.message);
    } catch (e) {
      throw Exception('Failed to fetch courier partners: ${e.toString()}');
    }
  }

  /// Check serviceability
  Future<ServiceabilityCheck> checkServiceability({
    required String pickupPincode,
    required String deliveryPincode,
    required bool cod,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/courier/check-service'),
        headers: _headers,
        body: jsonEncode({
          'pickupPincode': pickupPincode,
          'deliveryPincode': deliveryPincode,
          'cod': cod,
        }),
      );

      final result = ApiService.handleResponse(response);
      if (result.success && result.data != null) {
        return ServiceabilityCheck.fromJson(result.data!);
      }
      throw Exception(result.message);
    } catch (e) {
      throw Exception('Failed to check serviceability: ${e.toString()}');
    }
  }

  /// Get shipping rates
  Future<Map<String, dynamic>> getRates({
    required String pickupPincode,
    required String deliveryPincode,
    required double weight,
    required bool cod,
    double codAmount = 0,
  }) async {
    try {
      final queryParams = {
        'pickupPincode': pickupPincode,
        'deliveryPincode': deliveryPincode,
        'weight': weight.toString(),
        'cod': cod.toString(),
        'codAmount': codAmount.toString(),
      };

      final uri = Uri.parse('$_baseUrl/courier/rates')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _headers);

      final result = ApiService.handleResponse(response);
      if (result.success && result.data != null) {
        final ratesList = (result.data!['rates'] as List?)
                ?.map((e) => ShippingRate.fromJson(e))
                .toList() ??
            [];

        return {
          'rates': ratesList,
          'cheapest': result.data!['cheapest'] != null
              ? ShippingRate.fromJson(result.data!['cheapest'])
              : null,
          'fastest': result.data!['fastest'] != null
              ? ShippingRate.fromJson(result.data!['fastest'])
              : null,
        };
      }
      throw Exception(result.message);
    } catch (e) {
      throw Exception('Failed to get rates: ${e.toString()}');
    }
  }

  /// Get recommended courier
  Future<Map<String, dynamic>> getRecommendedCourier({
    required String pickupPincode,
    required String deliveryPincode,
    required double weight,
    required bool cod,
    double codAmount = 0,
    String priority = 'Normal',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/courier/recommend'),
        headers: _headers,
        body: jsonEncode({
          'pickupPincode': pickupPincode,
          'deliveryPincode': deliveryPincode,
          'weight': weight,
          'cod': cod,
          'codAmount': codAmount,
          'priority': priority,
        }),
      );

      final result = ApiService.handleResponse(response);
      if (result.success && result.data != null) {
        return {
          'recommended':
              ShippingRate.fromJson(result.data!['recommended']),
          'reason': result.data!['reason'],
        };
      }
      throw Exception(result.message);
    } catch (e) {
      throw Exception('Failed to get recommendation: ${e.toString()}');
    }
  }

  /// Create shipment
  Future<Shipment> createShipment({
    required String orderId,
    String? courierName,
    bool autoSelect = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/courier/create-shipment'),
        headers: _headers,
        body: jsonEncode({
          'orderId': orderId,
          'courierName': courierName,
          'autoSelect': autoSelect,
        }),
      );

      final result = ApiService.handleResponse(response);
      if (result.success && result.data != null) {
        return Shipment.fromJson(result.data?['shipment'] ?? {});
      }
      throw Exception(result.message);
    } catch (e) {
      throw Exception('Failed to create shipment: ${e.toString()}');
    }
  }

  /// Track shipment
  Future<TrackingData> trackShipment(String awb) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/courier/track/$awb'),
      ); // Public endpoint

      final result = ApiService.handleResponse(response);
      if (result.success && result.data != null) {
        return TrackingData.fromJson(result.data!['tracking'] ?? {});
      }
      throw Exception(result.message);
    } catch (e) {
      throw Exception('Failed to track shipment: ${e.toString()}');
    }
  }

  /// Track by Order ID
  Future<Map<String, dynamic>> trackByOrderId(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/courier/track/order/$orderId'),
        headers: _headers,
      );

      final result = ApiService.handleResponse(response);
      if (result.success && result.data != null) {
        return {
          'shipment': Shipment.fromJson(result.data!['shipment']),
          'tracking': TrackingData.fromJson(result.data!['tracking']),
        };
      }
      throw Exception(result.message);
    } catch (e) {
      throw Exception('Failed to track order: ${e.toString()}');
    }
  }

  /// Get shipments (Admin)
  Future<Map<String, dynamic>> getShipments({
    int page = 1,
    int limit = 20,
    String? status,
    String? courierName,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
        if (courierName != null) 'courierName': courierName,
      };

      final uri = Uri.parse('$_baseUrl/courier/shipments')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _headers);

      final result = ApiService.handleResponse(response);
      if (result.success && result.data != null) {
        final shipments = (result.data!['shipments'] as List?)
                ?.map((e) => Shipment.fromJson(e))
                .toList() ??
            [];
        return {
          'shipments': shipments,
          'pagination': result.data!['pagination'],
        };
      }
      throw Exception(result.message);
    } catch (e) {
      throw Exception('Failed to get shipments: ${e.toString()}');
    }
  }

  /// Cancel shipment
  Future<bool> cancelShipment(String awb, {String reason = 'Admin cancelled'}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/courier/cancel'),
        headers: _headers,
        body: jsonEncode({
          'awb': awb,
          'reason': reason,
        }),
      );

      final result = ApiService.handleResponse(response);
      return result.success;
    } catch (e) {
      throw Exception('Failed to cancel shipment: ${e.toString()}');
    }
  }

  /// Get performance stats
  Future<List<CourierPerformanceStats>> getPerformanceStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/courier/performance'),
        headers: _headers,
      );

      final result = ApiService.handleResponse(response);
      if (result.success && result.data != null) {
        final stats = result.data!['stats'] as List?;
        return stats?.map((e) => CourierPerformanceStats.fromJson(e)).toList() ?? [];
      }
      throw Exception(result.message);
    } catch (e) {
      throw Exception('Failed to get stats: ${e.toString()}');
    }
  }
}

class CourierPerformanceStats {
  final String name;
  final int totalShipments;
  final int successfulDeliveries;
  final int failedDeliveries;
  final int rtoCount;
  final double avgDeliveryDays;
  final double onTimeRate;
  final double deliverySuccessRate;
  final double rtoRate;

  CourierPerformanceStats({
    required this.name,
    required this.totalShipments,
    required this.successfulDeliveries,
    required this.failedDeliveries,
    required this.rtoCount,
    required this.avgDeliveryDays,
    required this.onTimeRate,
    required this.deliverySuccessRate,
    required this.rtoRate,
  });

  factory CourierPerformanceStats.fromJson(Map<String, dynamic> json) {
    return CourierPerformanceStats(
      name: json['name'] ?? '',
      totalShipments: json['totalShipments'] ?? 0,
      successfulDeliveries: json['successfulDeliveries'] ?? 0,
      failedDeliveries: json['failedDeliveries'] ?? 0,
      rtoCount: json['rtoCount'] ?? 0,
      avgDeliveryDays: (json['avgDeliveryDays'] ?? 0).toDouble(),
      onTimeRate: (json['onTimeRate'] ?? 0).toDouble(),
      deliverySuccessRate: (json['deliverySuccessRate'] != null ? double.parse(json['deliverySuccessRate'].toString()) : 0),
      rtoRate: (json['rtoRate'] != null ? double.parse(json['rtoRate'].toString()) : 0),
    );
  }
}
