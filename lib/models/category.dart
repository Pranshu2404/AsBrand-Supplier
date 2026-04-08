class Category {
  final String id;
  final String name;
  final String? image;

  Category({
    required this.id,
    required this.name,
    this.image,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] is Map ? (json['image']['path'] ?? json['image']['url']) : json['image'],
    );
  }

  /// Default clothing categories when backend categories are not clothing-focused
  static List<Category> getDefaultClothingCategories() {
    return [
      Category(
        id: 'cat_men',
        name: "Men's Wear",
        image: 'https://images.unsplash.com/photo-1617137968427-85924c800a22?w=200&h=200&fit=crop',
      ),
      Category(
        id: 'cat_women',
        name: "Women's Wear",
        image: 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=200&h=200&fit=crop',
      ),
      Category(
        id: 'cat_kids',
        name: 'Kids Wear',
        image: 'https://images.unsplash.com/photo-1622290291468-a28f7a7dc6a8?w=200&h=200&fit=crop',
      ),
      Category(
        id: 'cat_ethnic',
        name: 'Ethnic Wear',
        image: 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?w=200&h=200&fit=crop',
      ),
      Category(
        id: 'cat_winter',
        name: 'Winter Wear',
        image: 'https://images.unsplash.com/photo-1544923246-77307dd628b4?w=200&h=200&fit=crop',
      ),
      Category(
        id: 'cat_sportswear',
        name: 'Sportswear',
        image: 'https://images.unsplash.com/photo-1556906781-9a412961c28c?w=200&h=200&fit=crop',
      ),
      Category(
        id: 'cat_footwear',
        name: 'Footwear',
        image: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=200&h=200&fit=crop',
      ),
      Category(
        id: 'cat_accessories',
        name: 'Accessories',
        image: 'https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=200&h=200&fit=crop',
      ),
    ];
  }

  /// Check if a category name is clothing-related
  static bool isClothingCategory(String name) {
    final lower = name.toLowerCase();
    final clothingKeywords = [
      'men', 'women', 'kids', 'child', 'fashion', 'cloth', 'wear',
      'dress', 'shirt', 'jeans', 'pants', 'kurta', 'saree', 'ethnic',
      'winter', 'jacket', 'sweater', 'sportswear', 'footwear', 'shoe',
      'accessories', 'bag', 'watch', 'jewelry', 'top', 'bottom',
      'formal', 'casual', 'traditional', 'western', 'indian'
    ];
    return clothingKeywords.any((keyword) => lower.contains(keyword));
  }
}

class SubCategory {
  final String id;
  final String name;
  final Category? category;

  SubCategory({
    required this.id,
    required this.name,
    this.category,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      category: json['categoryId'] is Map 
          ? Category.fromJson(json['categoryId']) 
          : null, // Ignore if it's just an ID string, as we can't build a full Category object
    );
  }
}
