/// Brand model matching backend Brand schema
/// Backend populates subcategoryId which contains categoryId
class Brand {
  final String id;
  final String name;
  final String? image;
  final String? subcategoryId;
  final String? subcategoryName;
  final String? categoryId;
  final String? categoryName;

  Brand({
    required this.id,
    required this.name,
    this.image,
    this.subcategoryId,
    this.subcategoryName,
    this.categoryId,
    this.categoryName,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    String? subCatId;
    String? subCatName;
    String? catId;
    String? catName;

    final subCat = json['subcategoryId'];
    if (subCat is Map<String, dynamic>) {
      subCatId = subCat['_id'] ?? subCat['id'];
      subCatName = subCat['name'];
      final cat = subCat['categoryId'];
      if (cat is Map<String, dynamic>) {
        catId = cat['_id'] ?? cat['id'];
        catName = cat['name'];
      } else if (cat is String) {
        catId = cat;
      }
    } else if (subCat is String) {
      subCatId = subCat;
    }

    return Brand(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] as String?,
      subcategoryId: subCatId,
      subcategoryName: subCatName,
      categoryId: catId,
      categoryName: catName,
    );
  }
}
