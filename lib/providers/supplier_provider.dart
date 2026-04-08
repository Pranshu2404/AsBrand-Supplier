import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class SupplierProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _error;

  // Dashboard stats
  Map<String, dynamic>? _dashboardStats;

  // Supplier products
  List<Product> _products = [];

  // Supplier orders
  List<Order> _orders = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  List<Product> get products => _products;
  List<Order> get orders => _orders;

  int get totalProducts => _dashboardStats?['totalProducts'] ?? 0;
  int get activeProducts => _dashboardStats?['activeProducts'] ?? 0;
  int get totalOrders => _dashboardStats?['totalOrders'] ?? 0;
  int get totalRevenue => _dashboardStats?['totalRevenue'] ?? 0;
  int get pendingOrders => _dashboardStats?['pendingOrders'] ?? 0;

  // Verify GST
  Future<Map<String, dynamic>> verifyGst(String gstin) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.verifyGst(gstin);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Verify Udyam
  Future<Map<String, dynamic>> verifyUdyam(String udyam) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.verifyUdyam(udyam);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Register as supplier
  Future<Map<String, dynamic>> registerAsSupplier(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.registerAsSupplier(data);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Fetch dashboard stats
  Future<void> fetchDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getSupplierDashboard();
      if (response['success'] == true) {
        _dashboardStats = response['data'];
      }
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Fetch supplier products
  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _products = await _apiService.getSupplierProducts();
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Check for duplicate products
  Future<Map<String, dynamic>> checkDuplicate({
    required String name,
    required String proCategoryId,
  }) async {
    try {
      return await _apiService.checkDuplicateSupplierProduct(
        name: name,
        proCategoryId: proCategoryId,
      );
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'duplicate': false};
    }
  }

  // Add product
  Future<bool> addProduct({
    required Map<String, String> fields,
    List<String>? preUploadedUrls,
    List<dynamic>? skuData,
    List<dynamic>? proVariants,
    String? selectedProductId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final submitFields = Map<String, String>.from(fields);
      if (selectedProductId != null) {
        submitFields['selected_product_id'] = selectedProductId;
      }
      
      await _apiService.addSupplierProduct(
        fields: submitFields,
        preUploadedUrls: preUploadedUrls,
        skuData: skuData,
        proVariants: proVariants,
      );
      // Product created successfully — try to refresh list (but don't fail if this errors)
      try {
        await fetchProducts();
      } catch (_) {}
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      debugPrint('[SupplierProvider] addProduct error: $e');
      notifyListeners();
      return false;
    }
  }

  // Update existing product
  Future<bool> updateProduct(
    String id,
    Map<String, dynamic> fields, {
    List<String>? preUploadedUrls,
    List<dynamic>? skuData,
    List<dynamic>? proVariants,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.updateSupplierProduct(
        id,
        fields: fields,
        preUploadedUrls: preUploadedUrls,
        skuData: skuData,
        proVariants: proVariants,
      );
      
      if (response['success'] == true) {
        // Refresh list
        try {
          await fetchProducts();
        } catch (_) {}
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      _error = response['message'] ?? 'Failed to update product';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      debugPrint('[SupplierProvider] updateProduct error: $e');
      notifyListeners();
      return false;
    }
  }

  // Delete product
  Future<bool> deleteProduct(String id) async {
    try {
      await _apiService.deleteSupplierProduct(id);
      _products.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Fetch orders
  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      _orders = await _apiService.getSupplierOrders();
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearData() {
    _dashboardStats = null;
    _products = [];
    _orders = [];
    _error = null;
    notifyListeners();
  }
}
