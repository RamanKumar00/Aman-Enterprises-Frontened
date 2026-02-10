import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aman_enterprises/services/api_service.dart';
import 'package:aman_enterprises/services/user_service.dart';

class ReviewService {
  static String get baseUrl => ApiService.baseUrl;

  // ==================== USER METHODS ====================

  /// Create a new review for a product
  static Future<ApiResponse> createReview({
    required String productId,
    required String orderId,
    required int rating,
    String? title,
    required String comment,
  }) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/review'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'productId': productId,
          'orderId': orderId,
          'rating': rating,
          'title': title ?? '',
          'comment': comment,
        }),
      );

      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  /// Get reviews for a product
  static Future<ApiResponse> getProductReviews({
    required String productId,
    int page = 1,
    int limit = 10,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    int? filterRating,
  }) async {
    try {
      String url = '$baseUrl/review/product/$productId?page=$page&limit=$limit&sortBy=$sortBy&sortOrder=$sortOrder';
      if (filterRating != null) {
        url += '&rating=$filterRating';
      }

      final response = await http.get(Uri.parse(url));
      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  /// Get average rating for a product
  static Future<ApiResponse> getProductRating(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/review/rating/$productId'),
      );
      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  /// Get user's own reviews
  static Future<ApiResponse> getMyReviews({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/review/my-reviews?page=$page&limit=$limit'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  /// Check if user can review a product
  static Future<ApiResponse> canReviewProduct(String productId) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/review/can-review/$productId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  /// Update a review
  static Future<ApiResponse> updateReview({
    required String reviewId,
    int? rating,
    String? title,
    String? comment,
  }) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      final body = <String, dynamic>{};
      if (rating != null) body['rating'] = rating;
      if (title != null) body['title'] = title;
      if (comment != null) body['comment'] = comment;

      final response = await http.put(
        Uri.parse('$baseUrl/review/$reviewId'),
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

  /// Delete a review
  static Future<ApiResponse> deleteReview(String reviewId) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/review/$reviewId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  /// Mark a review as helpful
  static Future<ApiResponse> markReviewHelpful(String reviewId) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/review/$reviewId/helpful'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  // ==================== ADMIN METHODS ====================

  /// Get all reviews (admin)
  static Future<ApiResponse> getAllReviewsAdmin({
    int page = 1,
    int limit = 20,
    String? status,
    int? rating,
    String? productId,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      String url = '$baseUrl/review/admin/all?page=$page&limit=$limit&sortBy=$sortBy&sortOrder=$sortOrder';
      if (status != null) url += '&status=$status';
      if (rating != null) url += '&rating=$rating';
      if (productId != null) url += '&productId=$productId';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  /// Moderate a review (admin)
  static Future<ApiResponse> moderateReview({
    required String reviewId,
    required String status, // approved, rejected, spam
    String? moderationNote,
  }) async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/review/admin/$reviewId/moderate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': status,
          'moderationNote': moderationNote ?? '',
        }),
      );
      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  /// Get review analytics (admin)
  static Future<ApiResponse> getReviewAnalytics() async {
    try {
      final token = UserService().authToken;
      if (token == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/review/admin/analytics'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return ApiService.handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }
}
