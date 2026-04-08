import 'category.dart';

class SubSubCategory {
  final String id;
  final String name;
  final String? image;
  final SubCategory? subCategory;
  final Category? category;

  SubSubCategory({
    required this.id,
    required this.name,
    this.image,
    this.subCategory,
    this.category,
  });

  factory SubSubCategory.fromJson(Map<String, dynamic> json) {
    return SubSubCategory(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] is Map ? (json['image']['path'] ?? json['image']['url']) : json['image'],
      subCategory: json['subCategoryId'] is Map 
          ? SubCategory.fromJson(json['subCategoryId']) 
          : null,
      category: json['categoryId'] is Map 
          ? Category.fromJson(json['categoryId']) 
          : null,
    );
  }
}
