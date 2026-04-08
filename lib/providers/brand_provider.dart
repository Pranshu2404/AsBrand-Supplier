import 'package:flutter/material.dart';
import '../models/brand.dart';
import '../services/api_service.dart';

/// Provider for fetching and organizing brands from the backend.
/// Brands are grouped by Category → SubCategory hierarchy.
class BrandProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Brand> _brands = [];
  List<Brand> get brands => _brands;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Brands grouped by category name → list of brands
  Map<String, List<Brand>> get brandsByCategory {
    final Map<String, List<Brand>> grouped = {};
    for (final brand in _brands) {
      final key = brand.categoryName ?? 'Other';
      grouped.putIfAbsent(key, () => []).add(brand);
    }
    return grouped;
  }

  /// Brands grouped by subcategory name → list of brands
  Map<String, List<Brand>> get brandsBySubCategory {
    final Map<String, List<Brand>> grouped = {};
    for (final brand in _brands) {
      final key = brand.subcategoryName ?? 'Other';
      grouped.putIfAbsent(key, () => []).add(brand);
    }
    return grouped;
  }

  /// Get all unique category names
  List<String> get categoryNames {
    final names = _brands
        .map((b) => b.categoryName ?? 'Other')
        .toSet()
        .toList();
    names.sort();
    return names;
  }

  /// Get brands for a specific category
  List<Brand> getBrandsForCategory(String categoryName) {
    return _brands.where((b) => (b.categoryName ?? 'Other') == categoryName).toList();
  }

  /// Fetch all brands from the backend
  Future<void> fetchBrands() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _brands = await _apiService.getBrands();
    } catch (e) {
      _error = e.toString();
      debugPrint('Brand fetch failed: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
