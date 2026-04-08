import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/sub_sub_category.dart';
import '../models/poster.dart';
import '../models/order.dart';
import '../models/brand.dart';
import '../models/coupon.dart';
import '../models/emi_plan.dart';
import '../models/user_kyc.dart';
import '../models/notification.dart';
import '../models/review.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();

  // Helper to get headers with token
  Future<Map<String, String>> _getHeaders() async {
    String? token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Generic GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(endpoint), headers: headers);
      return _processResponse(response);
    } catch (e) {
      throw Exception('Connection Error: $e');
    }
  }

  // Generic POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Connection Error: $e');
    }
  }

  // Generic PUT request
  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Connection Error: $e');
    }
  }

  // Generic DELETE request
  Future<dynamic> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(Uri.parse(endpoint), headers: headers);
      return _processResponse(response);
    } catch (e) {
      throw Exception('Connection Error: $e');
    }
  }

  // Helper to process response
  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      String message = 'Unknown Error';
      try {
        final body = jsonDecode(response.body);
        message = body['message'] ?? response.reasonPhrase;
      } catch (_) {
        message = response.reasonPhrase ?? 'Error ${response.statusCode}';
      }
      throw Exception(message);
    }
  }

  // ============================================================
  // PRODUCT ENDPOINTS
  // ============================================================

  Future<List<Product>> getProducts({Map<String, dynamic>? params}) async {
    String endpoint = ApiConstants.products;
    if (params != null && params.isNotEmpty) {
      final uri = Uri.parse(endpoint).replace(queryParameters: params);
      endpoint = uri.toString();
    }
    final response = await get(endpoint);
    if (response['success'] == true && response['data'] != null) {
      final list = <Product>[];
      for (var json in response['data']) {
        try {
          list.add(Product.fromJson(json));
        } catch (e) {
          print('Error parsing Product: $e');
        }
      }
      return list;
    }
    return [];
  }

  Future<Product?> getProductById(String id) async {
    final response = await get('${ApiConstants.products}/$id');
    if (response['success'] == true && response['data'] != null) {
      return Product.fromJson(response['data']);
    }
    return null;
  }

  // ============================================================
  // CATEGORY ENDPOINTS
  // ============================================================

  Future<List<Category>> getCategories() async {
    final response = await get(ApiConstants.categories);
    if (response['success'] == true && response['data'] != null) {
      return (response['data'] as List)
          .map((json) => Category.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<List<SubCategory>> getSubCategories() async {
    final response = await get(ApiConstants.subCategories);
    if (response['success'] == true && response['data'] != null) {
      return (response['data'] as List)
          .map((json) => SubCategory.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<List<SubSubCategory>> getSubSubCategories() async {
    final response = await get(ApiConstants.subSubCategories);
    if (response['success'] == true && response['data'] != null) {
      return (response['data'] as List)
          .map((json) => SubSubCategory.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<List<Brand>> getBrands() async {
    final response = await get(ApiConstants.brands);
    if (response['success'] == true && response['data'] != null) {
      return (response['data'] as List)
          .map((json) => Brand.fromJson(json))
          .toList();
    }
    return [];
  }

  // ============================================================
  // POSTER ENDPOINTS
  // ============================================================

  Future<List<Poster>> getPosters() async {
    final response = await get(ApiConstants.posters);
    if (response['success'] == true && response['data'] != null) {
      return (response['data'] as List)
          .map((json) => Poster.fromJson(json))
          .toList();
    }
    return [];
  }

  // ============================================================
  // ORDER ENDPOINTS
  // ============================================================

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    return await post(ApiConstants.orders, orderData);
  }

  Future<List<Order>> getMyOrders() async {
    final response = await get('${ApiConstants.orders}/my-orders');
    if (response['success'] == true && response['data'] != null) {
      return (response['data'] as List)
          .map((json) => Order.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<List<Order>> getMyOrdersByUserId(String userId) async {
    final response = await get('${ApiConstants.orders}/orderByUserId/$userId');
    if (response['success'] == true && response['data'] != null) {
      return (response['data'] as List)
          .map((json) => Order.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<Order?> getOrderById(String id) async {
    final response = await get('${ApiConstants.orders}/$id');
    if (response['success'] == true && response['data'] != null) {
      return Order.fromJson(response['data']);
    }
    return null;
  }

  /// Get tracking info for an order from Shiprocket
  Future<Map<String, dynamic>> getOrderTracking(String orderId) async {
    return await get('${ApiConstants.shipping}/track/$orderId');
  }

  Future<Map<String, dynamic>> getSupplierFinance() async {
    return await get('${ApiConstants.baseUrl}/api/supplier/finance');
  }

  // ============================================================
  // COUPON ENDPOINTS
  // ============================================================

  Future<List<Coupon>> getCoupons() async {
    final response = await get('${ApiConstants.coupons}/my-coupons');
    if (response['success'] == true && response['data'] != null) {
      return (response['data'] as List)
          .map((json) => Coupon.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> validateCoupon(String code, double cartTotal) async {
    return await post('${ApiConstants.coupons}/check-coupon', {
      'couponCode': code,
      'purchaseAmount': cartTotal,
    });
  }

  // ============================================================
  // EMI ENDPOINTS
  // ============================================================

  Future<List<EmiPlan>> getEmiPlans() async {
    final response = await get(ApiConstants.emiPlans);
    if (response['success'] == true && response['data'] != null) {
      return (response['data'] as List)
          .map((json) => EmiPlan.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> applyForEmi(String orderId, String planId, double amount) async {
    return await post(ApiConstants.emiApply, {
      'orderId': orderId,
      'emiPlanId': planId,
      'principalAmount': amount,
    });
  }

  // ============================================================
  // KYC ENDPOINTS
  // ============================================================

  Future<UserKyc?> getKycStatus() async {
    final response = await get(ApiConstants.kycStatus);
    if (response['success'] == true && response['data'] != null) {
      return UserKyc.fromJson(response['data']);
    }
    return null;
  }

  Future<Map<String, dynamic>> submitKyc(Map<String, dynamic> kycData) async {
    return await post(ApiConstants.kycSubmit, kycData);
  }

  // ============================================================
  // NOTIFICATION ENDPOINTS
  // ============================================================

  Future<List<AppNotification>> getNotifications() async {
    final response = await get(ApiConstants.notifications);
    if (response['success'] == true && response['data'] != null) {
      return (response['data'] as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();
    }
    return [];
  }

  // ============================================================
  // REVIEW ENDPOINTS
  // ============================================================

  Future<List<Review>> getProductReviews(String productId, {int page = 1, int limit = 10}) async {
    final response = await get('${ApiConstants.reviews}/product/$productId?page=$page&limit=$limit');
    if (response['success'] == true && response['data'] != null) {
      return (response['data'] as List)
          .map((json) => Review.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<ReviewStats> getReviewStats(String productId) async {
    final response = await get('${ApiConstants.reviews}/stats/$productId');
    if (response['success'] == true && response['data'] != null) {
      return ReviewStats.fromJson(response['data']);
    }
    return ReviewStats();
  }

  Future<ReviewStats> getSupplierReviewStats(String supplierId) async {
    final response = await get('${ApiConstants.baseUrl}/supplier/stats/$supplierId');
    if (response['success'] == true && response['data'] != null) {
      return ReviewStats.fromJson(response['data']);
    }
    return ReviewStats();
  }

  Future<Map<String, dynamic>> canReview(String productId) async {
    final response = await get('${ApiConstants.reviews}/can-review/$productId');
    if (response['success'] == true && response['data'] != null) {
      return response['data'];
    }
    return {'canReview': false, 'reason': 'unknown'};
  }

  /// Submit a review with optional images (multipart upload)
  Future<Map<String, dynamic>> submitReview({
    required String productID,
    required String orderID,
    required int rating,
    String? title,
    String? comment,
    List<String>? imagePaths,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse(ApiConstants.reviews);
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll(headers);
    request.fields['productID'] = productID;
    request.fields['orderID'] = orderID;
    request.fields['rating'] = rating.toString();
    if (title != null && title.isNotEmpty) request.fields['title'] = title;
    if (comment != null && comment.isNotEmpty) request.fields['comment'] = comment;

    // Attach images
    if (imagePaths != null) {
      for (final path in imagePaths) {
        request.files.add(await http.MultipartFile.fromPath('images', path));
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _processResponse(response);
  }

  Future<void> deleteReview(String reviewId) async {
    await delete('${ApiConstants.reviews}/$reviewId');
  }

  // ============================================================
  // SUPPLIER ENDPOINTS
  // ============================================================

  Future<Map<String, dynamic>> registerAsSupplier(Map<String, dynamic> data) async {
    return await post(ApiConstants.supplierRegister, data);
  }

  Future<Map<String, dynamic>> verifyGst(String gstin) async {
    return await post(ApiConstants.supplierVerifyGst, {'gstin': gstin});
  }

  Future<Map<String, dynamic>> verifyUdyam(String udyam) async {
    return await post(ApiConstants.supplierVerifyUdyam, {'udyam': udyam});
  }

  Future<Map<String, dynamic>> getSupplierDashboard() async {
    return await get(ApiConstants.supplierDashboard);
  }

  Future<List<Map<String, dynamic>>> getNearestSuppliers(double lat, double lng, {String? keyword}) async {
    String endpoint = '${ApiConstants.baseUrl}/supplier/nearest?lat=$lat&lng=$lng';
    if (keyword != null && keyword.isNotEmpty) {
      endpoint += '&keyword=$keyword';
    }
    final response = await get(endpoint);
    if (response['success'] == true && response['data'] != null) {
      return List<Map<String, dynamic>>.from(response['data']);
    }
    return [];
  }

  Future<List<Product>> getSupplierProducts() async {
    final response = await get(ApiConstants.supplierProducts);
    if (response['success'] == true && response['data'] != null) {
      final list = <Product>[];
      for (var json in response['data']) {
        try {
          list.add(Product.fromJson(json));
        } catch (e) {
          print('Error parsing supplier product: $e');
        }
      }
      return list;
    }
    return [];
  }

  /// Upload a single product image to Cloudinary via backend
  Future<String?> uploadProductImage(String filePath) async {
    final headers = await _getHeaders();
    // Remove content-type — multipart sets it automatically
    headers.remove('Content-Type');

    final uri = Uri.parse('${ApiConstants.products}/upload-image');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(headers);
    request.files.add(await http.MultipartFile.fromPath('image', filePath));

    final streamedResponse = await request.send().timeout(const Duration(seconds: 120));
    final response = await http.Response.fromStream(streamedResponse);
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
      return body['data']?['url'] as String?;
    }
    return null;
  }

  /// Check if a product with same name/category already exists (Fuzzy search)
  Future<Map<String, dynamic>> checkDuplicateSupplierProduct({
    required String name,
    required String proCategoryId,
  }) async {
    return await post('${ApiConstants.supplierProducts}/check-duplicate', {
      'name': name,
      'proCategoryId': proCategoryId,
    });
  }

  /// Add a supplier product with pre-uploaded image URLs and optional SKU data
  Future<Map<String, dynamic>> addSupplierProduct({
    required Map<String, String> fields,
    List<String>? preUploadedUrls,
    List<dynamic>? skuData,
    List<dynamic>? proVariants,
  }) async {
    final headers = await _getHeaders();
    final body = <String, dynamic>{...fields};
    if (preUploadedUrls != null && preUploadedUrls.isNotEmpty) {
      body['preUploadedUrls'] = preUploadedUrls;
    }
    if (skuData != null && skuData.isNotEmpty) {
      body['skus'] = skuData;
    }
    if (proVariants != null && proVariants.isNotEmpty) {
      body['proVariants'] = proVariants;
    }
    final response = await http.post(
      Uri.parse(ApiConstants.supplierProducts),
      headers: headers,
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  Future<Map<String, dynamic>> updateSupplierProduct(
    String id, {
    required Map<String, dynamic> fields,
    List<String>? preUploadedUrls,
    List<dynamic>? skuData,
    List<dynamic>? proVariants,
  }) async {
    final body = <String, dynamic>{...fields};
    if (preUploadedUrls != null && preUploadedUrls.isNotEmpty) {
      body['preUploadedUrls'] = preUploadedUrls;
    }
    if (skuData != null && skuData.isNotEmpty) {
      body['skus'] = skuData;
    }
    if (proVariants != null && proVariants.isNotEmpty) {
      body['proVariants'] = proVariants;
    }
    return await put('${ApiConstants.supplierProducts}/$id', body);
  }

  Future<void> deleteSupplierProduct(String id) async {
    await delete('${ApiConstants.supplierProducts}/$id');
  }

  Future<List<Order>> getSupplierOrders() async {
    final response = await get(ApiConstants.supplierOrders);
    if (response['success'] == true && response['data'] != null) {
      return (response['data'] as List)
          .map((json) => Order.fromJson(json))
          .toList();
    }
    return [];
  }

  // ============================================================
  // SUPPLIER ORDER ACTIONS (Zomato lifecycle)
  // ============================================================

  Future<Map<String, dynamic>> acceptOrder(String orderId, {int prepMinutes = 15}) async {
    return await put('${ApiConstants.supplierOrders}/$orderId/accept', {
      'estimatedPrepMinutes': prepMinutes,
    });
  }

  Future<Map<String, dynamic>> rejectOrder(String orderId) async {
    return await put('${ApiConstants.supplierOrders}/$orderId/reject', {});
  }

  Future<Map<String, dynamic>> markOrderReady(String orderId) async {
    return await put('${ApiConstants.supplierOrders}/$orderId/ready', {});
  }

  Future<Map<String, dynamic>> markOrderPickedUp(String orderId) async {
    return await put('${ApiConstants.supplierOrders}/$orderId/picked-up', {});
  }

  Future<Map<String, dynamic>?> getSupplierById(String id) async {
    try {
      final response = await get('${ApiConstants.baseUrl}/supplier/$id');
      if (response['success'] == true && response['data'] != null) {
        return response['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
