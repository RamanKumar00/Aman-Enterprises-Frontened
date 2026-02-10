import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aman_enterprises/services/api_service.dart';
import 'package:aman_enterprises/services/user_service.dart';

class InvoiceService {
  static String get baseUrl => ApiService.baseUrl;

  // ==================== USER METHODS ====================

  /// Generate invoice for an order
  static Future<ApiResponse> generateInvoice(String orderId) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/invoice/generate/$orderId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  /// Get invoice by order ID
  static Future<ApiResponse> getInvoiceByOrder(String orderId) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/invoice/order/$orderId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  /// Get invoice by invoice number
  static Future<ApiResponse> getInvoiceByNumber(String invoiceNumber) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/invoice/number/$invoiceNumber'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  /// Get user's invoices
  static Future<ApiResponse> getMyInvoices({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/invoice/my-invoices?page=$page&limit=$limit'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  // ==================== ADMIN METHODS ====================

  /// Get all invoices (admin)
  static Future<ApiResponse> getAllInvoicesAdmin({
    int page = 1,
    int limit = 20,
    String? status,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      String url = '$baseUrl/invoice/admin/all?page=$page&limit=$limit';
      if (status != null) url += '&status=$status';
      if (startDate != null) url += '&startDate=$startDate';
      if (endDate != null) url += '&endDate=$endDate';
      if (search != null) url += '&search=$search';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  /// Get GST summary report (admin)
  static Future<ApiResponse> getGSTSummary({
    String? startDate,
    String? endDate,
    String? period, // 'monthly', 'yearly'
  }) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      String url = '$baseUrl/invoice/admin/gst-summary?';
      if (period != null) url += 'period=$period&';
      if (startDate != null) url += 'startDate=$startDate&';
      if (endDate != null) url += 'endDate=$endDate&';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  /// Update company GST settings (admin)
  static Future<ApiResponse> updateCompanySettings({
    String? name,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? phone,
    String? email,
    String? gstin,
    String? pan,
    String? logo,
  }) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (address != null) body['address'] = address;
      if (city != null) body['city'] = city;
      if (state != null) body['state'] = state;
      if (pincode != null) body['pincode'] = pincode;
      if (phone != null) body['phone'] = phone;
      if (email != null) body['email'] = email;
      if (gstin != null) body['gstin'] = gstin;
      if (pan != null) body['pan'] = pan;
      if (logo != null) body['logo'] = logo;

      final response = await http.put(
        Uri.parse('$baseUrl/invoice/admin/company-settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  /// Export invoices (admin)
  static Future<ApiResponse> exportInvoices({
    String? startDate,
    String? endDate,
    String format = 'json',
  }) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      String url = '$baseUrl/invoice/admin/export?format=$format';
      if (startDate != null) url += '&startDate=$startDate';
      if (endDate != null) url += '&endDate=$endDate';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  /// Cancel an invoice (admin)
  static Future<ApiResponse> cancelInvoice({
    required String invoiceId,
    String? reason,
  }) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/invoice/admin/$invoiceId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'reason': reason ?? ''}),
      );
      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }
}

/// Invoice model for frontend use
class Invoice {
  final String id;
  final String invoiceNumber;
  final String orderId;
  final String orderTrackingId;
  final DateTime invoiceDate;
  final CompanyDetails companyDetails;
  final CustomerDetails customerDetails;
  final List<InvoiceItem> items;
  final InvoicePricing pricing;
  final GSTDetails gstDetails;
  final PaymentInfo paymentInfo;
  final String status;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.orderId,
    required this.orderTrackingId,
    required this.invoiceDate,
    required this.companyDetails,
    required this.customerDetails,
    required this.items,
    required this.pricing,
    required this.gstDetails,
    required this.paymentInfo,
    required this.status,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['_id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      orderId: json['order']?['_id'] ?? json['order'] ?? '',
      orderTrackingId: json['order']?['trackingId'] ?? '',
      invoiceDate: DateTime.tryParse(json['invoiceDate'] ?? '') ?? DateTime.now(),
      companyDetails: CompanyDetails.fromJson(json['companyDetails'] ?? {}),
      customerDetails: CustomerDetails.fromJson(json['customerDetails'] ?? {}),
      items: (json['items'] as List? ?? [])
          .map((item) => InvoiceItem.fromJson(item))
          .toList(),
      pricing: InvoicePricing.fromJson(json['pricing'] ?? {}),
      gstDetails: GSTDetails.fromJson(json['gstDetails'] ?? {}),
      paymentInfo: PaymentInfo.fromJson(json['paymentInfo'] ?? {}),
      status: json['status'] ?? 'generated',
    );
  }
}

class CompanyDetails {
  final String name;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String phone;
  final String email;
  final String gstin;
  final String pan;
  final String? logo;

  CompanyDetails({
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.phone,
    required this.email,
    required this.gstin,
    required this.pan,
    this.logo,
  });

  factory CompanyDetails.fromJson(Map<String, dynamic> json) {
    return CompanyDetails(
      name: json['name'] ?? 'Aman Enterprises',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      gstin: json['gstin'] ?? '',
      pan: json['pan'] ?? '',
      logo: json['logo'],
    );
  }
}

class CustomerDetails {
  final String name;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String? gstin;

  CustomerDetails({
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    this.gstin,
  });

  factory CustomerDetails.fromJson(Map<String, dynamic> json) {
    return CustomerDetails(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      gstin: json['gstin'],
    );
  }
}

class InvoiceItem {
  final String productId;
  final String name;
  final String? description;
  final String? hsn;
  final int quantity;
  final String unit;
  final double unitPrice;
  final double discount;
  final double taxableAmount;
  final double cgstRate;
  final double cgstAmount;
  final double sgstRate;
  final double sgstAmount;
  final double igstRate;
  final double igstAmount;
  final double totalAmount;

  InvoiceItem({
    required this.productId,
    required this.name,
    this.description,
    this.hsn,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.discount,
    required this.taxableAmount,
    required this.cgstRate,
    required this.cgstAmount,
    required this.sgstRate,
    required this.sgstAmount,
    required this.igstRate,
    required this.igstAmount,
    required this.totalAmount,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      productId: json['productId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      hsn: json['hsn'],
      quantity: json['quantity'] ?? 0,
      unit: json['unit'] ?? 'pcs',
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      taxableAmount: (json['taxableAmount'] ?? 0).toDouble(),
      cgstRate: (json['cgstRate'] ?? 0).toDouble(),
      cgstAmount: (json['cgstAmount'] ?? 0).toDouble(),
      sgstRate: (json['sgstRate'] ?? 0).toDouble(),
      sgstAmount: (json['sgstAmount'] ?? 0).toDouble(),
      igstRate: (json['igstRate'] ?? 0).toDouble(),
      igstAmount: (json['igstAmount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
    );
  }
}

class InvoicePricing {
  final double subtotal;
  final double totalDiscount;
  final double taxableAmount;
  final double cgstTotal;
  final double sgstTotal;
  final double igstTotal;
  final double totalTax;
  final double shippingCharges;
  final double roundOff;
  final double grandTotal;

  InvoicePricing({
    required this.subtotal,
    required this.totalDiscount,
    required this.taxableAmount,
    required this.cgstTotal,
    required this.sgstTotal,
    required this.igstTotal,
    required this.totalTax,
    required this.shippingCharges,
    required this.roundOff,
    required this.grandTotal,
  });

  factory InvoicePricing.fromJson(Map<String, dynamic> json) {
    return InvoicePricing(
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      totalDiscount: (json['totalDiscount'] ?? 0).toDouble(),
      taxableAmount: (json['taxableAmount'] ?? 0).toDouble(),
      cgstTotal: (json['cgstTotal'] ?? 0).toDouble(),
      sgstTotal: (json['sgstTotal'] ?? 0).toDouble(),
      igstTotal: (json['igstTotal'] ?? 0).toDouble(),
      totalTax: (json['totalTax'] ?? 0).toDouble(),
      shippingCharges: (json['shippingCharges'] ?? 0).toDouble(),
      roundOff: (json['roundOff'] ?? 0).toDouble(),
      grandTotal: (json['grandTotal'] ?? 0).toDouble(),
    );
  }
}

class GSTDetails {
  final bool isIntraState;
  final String placeOfSupply;

  GSTDetails({
    required this.isIntraState,
    required this.placeOfSupply,
  });

  factory GSTDetails.fromJson(Map<String, dynamic> json) {
    return GSTDetails(
      isIntraState: json['isIntraState'] ?? true,
      placeOfSupply: json['placeOfSupply'] ?? '',
    );
  }
}

class PaymentInfo {
  final String method;
  final String status;
  final String? transactionId;

  PaymentInfo({
    required this.method,
    required this.status,
    this.transactionId,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      method: json['method'] ?? 'COD',
      status: json['status'] ?? 'Pending',
      transactionId: json['transactionId'],
    );
  }
}
