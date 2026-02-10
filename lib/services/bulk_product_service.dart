import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:aman_enterprises/services/api_service.dart';
import 'package:aman_enterprises/services/user_service.dart';
import 'package:path/path.dart' as path;

class BulkProductService {
  static String get baseUrl => ApiService.baseUrl;

  // ==================== TEMPLATE DOWNLOADS ====================

  /// Download product upload template
  static Future<ApiResponse> downloadProductTemplate() async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/bulk/template/products'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: 'Template downloaded',
          data: {'bytes': response.bodyBytes, 'filename': 'product_upload_template.xlsx'},
        );
      }

      return ApiResponse(success: false, message: 'Failed to download template');
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  /// Download stock update template
  static Future<ApiResponse> downloadStockTemplate() async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/bulk/template/stock'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: 'Template downloaded',
          data: {'bytes': response.bodyBytes, 'filename': 'stock_update_template.xlsx'},
        );
      }

      return ApiResponse(success: false, message: 'Failed to download template');
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  // ==================== BULK UPLOAD ====================

  /// Parse and validate upload file
  static Future<ApiResponse> parseUploadFile(File file) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/bulk/upload/parse'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: path.basename(file.path),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  /// Execute bulk upload
  static Future<ApiResponse> executeBulkUpload(List<Map<String, dynamic>> products) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/bulk/upload/execute'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'products': products}),
      );

      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  // ==================== BULK PRICE UPDATE ====================

  /// Get products for price update
  static Future<ApiResponse> getProductsForPriceUpdate({
    String? category,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      String url = '$baseUrl/bulk/price/products?page=$page&limit=$limit';
      if (category != null && category.isNotEmpty) {
        url += '&category=$category';
      }
      if (search != null && search.isNotEmpty) {
        url += '&search=$search';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  /// Preview price changes
  static Future<ApiResponse> previewPriceUpdate({
    required List<String> productIds,
    required String updateType, // percentage, fixed, replace
    required double updateValue,
    String priceField = 'sellingPrice',
  }) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/bulk/price/preview'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'productIds': productIds,
          'updateType': updateType,
          'updateValue': updateValue,
          'priceField': priceField,
        }),
      );

      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  /// Execute price update
  static Future<ApiResponse> executePriceUpdate({
    required List<Map<String, dynamic>> updates,
    String priceField = 'sellingPrice',
  }) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/bulk/price/execute'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'updates': updates,
          'priceField': priceField,
        }),
      );

      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  // ==================== BULK STOCK UPDATE ====================

  /// Get low stock products
  static Future<ApiResponse> getLowStockProducts({int threshold = 10}) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/bulk/stock/low?threshold=$threshold'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  /// Parse stock update file
  static Future<ApiResponse> parseStockFile(File file) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/bulk/stock/parse'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: path.basename(file.path),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  /// Execute stock update
  static Future<ApiResponse> executeStockUpdate(List<Map<String, dynamic>> updates) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/bulk/stock/execute'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'updates': updates}),
      );

      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  /// Manual stock update (without file)
  static Future<ApiResponse> manualStockUpdate({
    required List<String> productIds,
    required String updateType, // add, reduce, replace
    required int stockValue,
  }) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/bulk/stock/manual'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'productIds': productIds,
          'updateType': updateType,
          'stockValue': stockValue,
        }),
      );

      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }
}

/// Parsed product row from Excel/CSV
class ParsedProductRow {
  final int rowNumber;
  final String productName;
  final String category;
  final String description;
  final double mrp;
  final double sellingPrice;
  final int stockQuantity;
  final double b2bPrice;
  final int b2bMinQty;
  final String hsnCode;
  final String imageUrl;
  final bool availability;
  final String unit;
  final String weight;
  final List<String> errors;
  final bool isValid;

  ParsedProductRow({
    required this.rowNumber,
    required this.productName,
    required this.category,
    required this.description,
    required this.mrp,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.b2bPrice,
    required this.b2bMinQty,
    required this.hsnCode,
    required this.imageUrl,
    required this.availability,
    required this.unit,
    required this.weight,
    required this.errors,
    required this.isValid,
  });

  factory ParsedProductRow.fromJson(Map<String, dynamic> json) {
    return ParsedProductRow(
      rowNumber: json['rowNumber'] ?? 0,
      productName: json['productName'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      mrp: (json['mrp'] ?? 0).toDouble(),
      sellingPrice: (json['sellingPrice'] ?? 0).toDouble(),
      stockQuantity: json['stockQuantity'] ?? 0,
      b2bPrice: (json['b2bPrice'] ?? 0).toDouble(),
      b2bMinQty: json['b2bMinQty'] ?? 6,
      hsnCode: json['hsnCode'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      availability: json['availability'] ?? true,
      unit: json['unit'] ?? 'unit',
      weight: json['weight'] ?? '1',
      errors: List<String>.from(json['errors'] ?? []),
      isValid: json['isValid'] ?? false,
    );
  }

  Map<String, dynamic> toUploadJson() {
    return {
      'productName': productName,
      'category': category,
      'description': description,
      'mrp': mrp,
      'sellingPrice': sellingPrice,
      'stockQuantity': stockQuantity,
      'b2bPrice': b2bPrice,
      'b2bMinQty': b2bMinQty,
      'hsnCode': hsnCode,
      'imageUrl': imageUrl,
      'availability': availability,
      'unit': unit,
      'weight': weight,
    };
  }
}

/// Price update preview item
class PriceUpdatePreview {
  final String id;
  final String productName;
  final String category;
  final double currentPrice;
  final double newPrice;
  final double change;
  final String changePercent;

  PriceUpdatePreview({
    required this.id,
    required this.productName,
    required this.category,
    required this.currentPrice,
    required this.newPrice,
    required this.change,
    required this.changePercent,
  });

  factory PriceUpdatePreview.fromJson(Map<String, dynamic> json) {
    return PriceUpdatePreview(
      id: json['id'] ?? '',
      productName: json['productName'] ?? '',
      category: json['category'] ?? '',
      currentPrice: (json['currentPrice'] ?? 0).toDouble(),
      newPrice: (json['newPrice'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changePercent: json['changePercent']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'id': id,
      'productName': productName,
      'newPrice': newPrice,
    };
  }
}

/// Stock update row
class StockUpdateRow {
  final int rowNumber;
  final String productName;
  final String? productId;
  final int currentStock;
  final int stockChange;
  final String updateType;
  final int newStock;
  final List<String> errors;
  final bool isValid;

  StockUpdateRow({
    required this.rowNumber,
    required this.productName,
    this.productId,
    required this.currentStock,
    required this.stockChange,
    required this.updateType,
    required this.newStock,
    required this.errors,
    required this.isValid,
  });

  factory StockUpdateRow.fromJson(Map<String, dynamic> json) {
    return StockUpdateRow(
      rowNumber: json['rowNumber'] ?? 0,
      productName: json['productName'] ?? '',
      productId: json['productId'],
      currentStock: json['currentStock'] ?? 0,
      stockChange: json['stockChange'] ?? 0,
      updateType: json['updateType'] ?? 'add',
      newStock: json['newStock'] ?? 0,
      errors: List<String>.from(json['errors'] ?? []),
      isValid: json['isValid'] ?? false,
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'productId': productId,
      'productName': productName,
      'newStock': newStock,
    };
  }
}
