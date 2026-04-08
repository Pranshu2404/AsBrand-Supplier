import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class SupplierProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  bool _isLoading = false;
  String? _error;

  // Dashboard stats
  Map<String, dynamic>? _dashboardStats;

  // Supplier products
  List<Product> _products = [];

  // Supplier orders
  List<Order> _orders = [];

  // New incoming orders (not yet accepted)
  final List<Order> _pendingNewOrders = [];

  StreamSubscription? _newOrderSub;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  List<Product> get products => _products;
  List<Order> get orders => _orders;
  List<Order> get pendingNewOrders => _pendingNewOrders;

  int get totalProducts => _dashboardStats?['totalProducts'] ?? 0;
  int get activeProducts => _dashboardStats?['activeProducts'] ?? 0;
  int get totalOrders => _dashboardStats?['totalOrders'] ?? 0;
  int get totalRevenue => _dashboardStats?['totalRevenue'] ?? 0;
  int get pendingOrders => _dashboardStats?['pendingOrders'] ?? 0;

  // ============================================================
  // Zomato-style filtered order getters
  // ============================================================

  List<Order> get newOrders =>
      _orders.where((o) => o.orderStatus == 'pending' || o.orderStatus == 'processing').toList();

  List<Order> get preparingOrders =>
      _orders.where((o) => o.orderStatus == 'preparing' || o.orderStatus == 'accepted').toList();

  List<Order> get readyOrders =>
      _orders.where((o) => o.orderStatus == 'ready').toList();

  List<Order> get pickedUpOrders =>
      _orders.where((o) => o.orderStatus == 'picked_up' || o.orderStatus == 'shipped').toList();

  // ============================================================
  // Socket integration
  // ============================================================

  void connectSocket(String supplierId) {
    _socketService.connect(supplierId);
    _newOrderSub?.cancel();
    _newOrderSub = _socketService.onNewOrder.listen((order) {
      _pendingNewOrders.insert(0, order);
      // Also add to main orders list
      _orders.insert(0, order);
      notifyListeners();
    });
  }

  void disconnectSocket() {
    _newOrderSub?.cancel();
    _socketService.disconnect();
  }

  void dismissNewOrder(String orderId) {
    _pendingNewOrders.removeWhere((o) => o.id == orderId);
    notifyListeners();
  }

  // ============================================================
  // Order actions (Zomato lifecycle)
  // ============================================================

  Future<bool> acceptOrder(String orderId, {int prepMinutes = 15}) async {
    try {
      final response = await _apiService.acceptOrder(orderId, prepMinutes: prepMinutes);
      if (response['success'] == true) {
        dismissNewOrder(orderId);
        await fetchOrders();
        return true;
      }
      _error = response['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectOrder(String orderId) async {
    try {
      final response = await _apiService.rejectOrder(orderId);
      if (response['success'] == true) {
        dismissNewOrder(orderId);
        await fetchOrders();
        return true;
      }
      _error = response['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> markOrderReady(String orderId) async {
    try {
      final response = await _apiService.markOrderReady(orderId);
      if (response['success'] == true) {
        await fetchOrders();
        return true;
      }
      _error = response['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> markOrderPickedUp(String orderId) async {
    try {
      final response = await _apiService.markOrderPickedUp(orderId);
      if (response['success'] == true) {
        await fetchOrders();
        return true;
      }
      _error = response['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // Existing methods preserved
  // ============================================================

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
    _pendingNewOrders.clear();
    _error = null;
    disconnectSocket();
    notifyListeners();
  }
}
