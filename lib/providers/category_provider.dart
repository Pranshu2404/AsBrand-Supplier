import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/sub_sub_category.dart';
import '../models/poster.dart';
import '../services/api_service.dart';

class CategoryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  List<SubCategory> _subCategories = [];
  List<SubCategory> get subCategories => _subCategories;

  List<SubSubCategory> _subSubCategories = [];
  List<SubSubCategory> get subSubCategories => _subSubCategories;

  List<Poster> _posters = [];
  List<Poster> get posters => _posters;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Fetch all categories from backend
  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _apiService.getCategories();
    } catch (e) {
      _error = 'Failed to load categories';
      debugPrint('Category fetch failed: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchSubCategories() async {
    try {
      _subCategories = await _apiService.getSubCategories();
      notifyListeners();
    } catch (e) {
      debugPrint('SubCategory fetch failed: $e');
    }
  }

  // Fetch all sub-subcategories
  Future<void> fetchSubSubCategories() async {
    try {
      _subSubCategories = await _apiService.getSubSubCategories();
      notifyListeners();
    } catch (e) {
      debugPrint('SubSubCategory fetch failed: $e');
    }
  }

  // Fetch posters/banners
  Future<void> fetchPosters() async {
    try {
      _posters = await _apiService.getPosters();
      notifyListeners();
    } catch (e) {
      // Don't set error for posters - not critical
      debugPrint('Poster fetch failed: $e');
    }
  }

  // Get subcategories for a specific category
  List<SubCategory> getSubCategoriesFor(String categoryId) {
    return _subCategories.where((sub) => sub.category?.id == categoryId).toList();
  }

  // Get sub-subcategories for a specific subcategory
  List<SubSubCategory> getSubSubCategoriesFor(String subCategoryId) {
    return _subSubCategories.where((subSub) => subSub.subCategory?.id == subCategoryId).toList();
  }

  // Clear any errors
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Fetch all data at once
  Future<void> fetchAllData() async {
    _isLoading = true;
    _error = null; // Clear any previous errors
    notifyListeners();

    await Future.wait([
      fetchCategories(),
      fetchSubCategories(),
      fetchSubSubCategories(),
      fetchPosters(),
    ]);

    _isLoading = false;
    notifyListeners();
  }
}
