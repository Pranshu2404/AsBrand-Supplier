/// Product model with full field support for clothes e-commerce
class Product {
  final String id;
  final String name;
  final String? description;
  final int quantity;
  final double price;
  final double? offerPrice;
  final double packagingCharge;
  final List<String> images;
  final CategoryRef? category;
  final CategoryRef? subCategory;
  final CategoryRef? brand;
  final CategoryRef? subSubCategory;
  final String? gender;
  
  // Clothing-specific fields
  final String? material;
  final String? fit;
  final String? pattern;
  final String? sleeveLength;
  final String? neckline;
  final String? occasion;
  final String? careInstructions;

  // Other fields
  final String? sku;
  final bool emiEligible;
  final String stockStatus; // in_stock, out_of_stock, low_stock, pre_order
  final int lowStockThreshold;
  final double? weight;
  final ProductDimensions? dimensions;
  final String? variantType; // Legacy: single variant type name
  final List<String> variants; // Legacy: flat variant list
  final List<VariantGroup> variantGroups; // New: grouped variants by type
  final List<Sku> skus; // New: actual Stock Keeping Units for variant combos
  final List<ProductSpec> specifications;
  final List<String> tags;
  final String? warranty;
  final bool featured;
  final bool isActive;
  final double averageRating;
  final int totalReviews;
  
  // Multi-vendor support
  final String? supplierId;
  final bool hasOtherSellers;
  final List<OtherSeller> otherSellers;

  // Set when this product entry is a SupplierProduct link (not a direct Product listing)
  // Used to route edit/delete to the correct backend endpoint
  final String? supplierProductId;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.quantity,
    required this.price,
    this.offerPrice,
    this.packagingCharge = 0.0,
    required this.images,
    this.category,
    this.subCategory,
    this.brand,
    this.subSubCategory,
    this.gender,
    this.material,
    this.fit,
    this.pattern,
    this.sleeveLength,
    this.neckline,
    this.occasion,
    this.careInstructions,
    this.sku,
    this.emiEligible = true,
    this.stockStatus = 'in_stock',
    this.lowStockThreshold = 10,
    this.weight,
    this.dimensions,
    this.variantType,
    this.variants = const [],
    this.variantGroups = const [],
    this.skus = const [],
    this.specifications = const [],
    this.tags = const [],
    this.warranty,
    this.featured = false,
    this.isActive = true,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.supplierId,
    this.hasOtherSellers = false,
    this.otherSellers = const [],
    this.supplierProductId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Parse images from image1-image5 fields or images array
    List<String> imageList = [];
    for (int i = 1; i <= 5; i++) {
      final img = json['image$i'];
      String? imgUrl;
      if (img is String) {
        imgUrl = img;
      } else if (img is Map) {
        imgUrl = img['path'] ?? img['url'] ?? img['secure_url'];
      }
      if (imgUrl != null && imgUrl.isNotEmpty && imgUrl != 'no_url') {
        imageList.add(imgUrl);
      }
    }
    // Fallback to images array
    if (imageList.isEmpty && json['images'] != null && json['images'] is List) {
      for (var img in json['images']) {
        if (img is Map && img['url'] != null) {
          imageList.add(img['url'].toString());
        } else if (img is String) {
          imageList.add(img);
        }
      }
    }

    // Parse variants (legacy flat format)
    List<String> variantList = [];
    if (json['proVariantId'] != null && json['proVariantId'] is List) {
      variantList = List<String>.from(json['proVariantId']);
    }

    // Parse grouped variants (new format)
    List<VariantGroup> groups = [];
    if (json['proVariants'] != null && json['proVariants'] is List && (json['proVariants'] as List).isNotEmpty) {
      groups = (json['proVariants'] as List)
          .map((v) => VariantGroup.fromJson(v))
          .where((g) => g.items.isNotEmpty)
          .toList();
    }
    // Fallback: if no proVariants but has old flat format, convert it
    if (groups.isEmpty && variantList.isNotEmpty) {
      String? typeName;
      if (json['proVariantTypeId'] is Map) {
        typeName = json['proVariantTypeId']['name'] ?? json['proVariantTypeId']['type'];
      }
      groups = [VariantGroup(typeName: typeName ?? 'Variant', items: variantList)];
    }

    // Parse skus
    List<Sku> skuList = [];
    if (json['skus'] != null && json['skus'] is List) {
      skuList = (json['skus'] as List).map((s) => Sku.fromJson(s)).toList();
    }

    // Parse specifications
    List<ProductSpec> specList = [];
    if (json['specifications'] != null && json['specifications'] is List) {
      specList = (json['specifications'] as List)
          .map((e) => ProductSpec.fromJson(e))
          .toList();
    }

    // Parse tags
    List<String> tagList = [];
    if (json['tags'] != null && json['tags'] is List) {
      tagList = List<String>.from(json['tags']);
    }

    return Product(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description']?.toString(),
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      offerPrice: json['offerPrice'] != null ? (json['offerPrice']).toDouble() : null,
      packagingCharge: (json['packagingCharge'] ?? 0).toDouble(),
      images: imageList,
      category: json['proCategoryId'] is Map 
          ? CategoryRef.fromJson(json['proCategoryId']) 
          : (json['category'] is Map ? CategoryRef.fromJson(json['category']) : null),
      subCategory: json['proSubCategoryId'] is Map 
          ? CategoryRef.fromJson(json['proSubCategoryId']) 
          : null,
      subSubCategory: json['proSubSubCategoryId'] is Map 
          ? CategoryRef.fromJson(json['proSubSubCategoryId']) 
          : null,
      brand: json['proBrandId'] is Map 
          ? CategoryRef.fromJson(json['proBrandId']) 
          : null,
      gender: json['gender'],
      material: json['material'],
      fit: json['fit'],
      pattern: json['pattern'],
      sleeveLength: json['sleeveLength'],
      neckline: json['neckline'],
      occasion: json['occasion'],
      careInstructions: json['careInstructions'],
      sku: json['sku'],
      emiEligible: json['emiEligible'] ?? true,
      stockStatus: json['stockStatus'] ?? 'in_stock',
      lowStockThreshold: json['lowStockThreshold'] ?? 10,
      weight: json['weight']?.toDouble(),
      dimensions: json['dimensions'] != null 
          ? ProductDimensions.fromJson(json['dimensions']) 
          : null,
      variantType: json['proVariantTypeId'] is Map 
          ? json['proVariantTypeId']['type'] 
          : null,
      variants: variantList,
      variantGroups: groups,
      skus: skuList,
      specifications: specList,
      tags: tagList,
      warranty: json['warranty'],
      featured: json['featured'] ?? false,
      isActive: json['isActive'] ?? true,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      supplierId: json['supplierId'] is Map ? json['supplierId']['_id'] : json['supplierId'],
      hasOtherSellers: json['hasOtherSellers'] ?? false,
      otherSellers: (json['otherSellers'] as List?)?.map((e) => OtherSeller.fromJson(e)).toList() ?? [],
      supplierProductId: json['supplierProductId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'quantity': quantity,
    'price': price,
    'offerPrice': offerPrice,
    'packagingCharge': packagingCharge,
    'images': images,
    'category': category?.toJson(),
    'subCategory': subCategory?.toJson(),
    'subSubCategory': subSubCategory?.toJson(),
    'brand': brand?.toJson(),
    'gender': gender,
    'sku': sku,
    'emiEligible': emiEligible,
    'stockStatus': stockStatus,
    'weight': weight,
    'variantType': variantType,
    'variants': variants,
    'skus': skus.map((s) => s.toJson()).toList(),
    'specifications': specifications.map((s) => s.toJson()).toList(),
    'tags': tags,
    'warranty': warranty,
    'featured': featured,
    'isActive': isActive,
    'averageRating': averageRating,
    'totalReviews': totalReviews,
  };

  // Helper getters
  double get emiPerMonth => (offerPrice ?? price) / 12;

  int get discountPercentage {
    if (offerPrice == null || offerPrice! >= price) return 0;
    return (((price - offerPrice!) / price) * 100).round();
  }
  String get primaryImage {
    if (images.isNotEmpty && images.first.isNotEmpty) return images.first;
    // Fallback: Use the first available SKU image
    for (var sku in skus) {
      if (sku.images.isNotEmpty && sku.images.first.isNotEmpty) {
        return sku.images.first;
      }
    }
    return '';
  }

  String get stockLabel {
    switch (stockStatus) {
      case 'in_stock': return 'In Stock';
      case 'out_of_stock': return 'Out of Stock';
      case 'low_stock': return 'Only $quantity left!';
      case 'pre_order': return 'Pre-Order';
      default: return 'In Stock';
    }
  }

  bool get isInStock => stockStatus != 'out_of_stock' && quantity > 0;
  bool get isLowStock => stockStatus == 'low_stock' || (quantity > 0 && quantity <= lowStockThreshold);
}

/// A specific variant combination (SKU - Stock Keeping Unit)
class Sku {
  final String skuId;
  final Map<String, String> attributes;
  final int stock;
  final double price;
  final List<String> images;

  Sku({
    required this.skuId,
    required this.attributes,
    required this.stock,
    required this.price,
    this.images = const [],
  });

  factory Sku.fromJson(Map<String, dynamic> json) {
    // Parse images array, with backward-compat for old single 'image' field
    List<String> imgList = [];
    if (json['images'] != null && json['images'] is List) {
      imgList = List<String>.from((json['images'] as List).where((e) => e != null && e.toString().isNotEmpty));
    }
    // Fallback: old single image field
    if (imgList.isEmpty && json['image'] != null && json['image'].toString().isNotEmpty) {
      imgList = [json['image'].toString()];
    }

    return Sku(
      skuId: json['skuId'] ?? '',
      attributes: Map<String, String>.from(json['attributes'] ?? {}),
      stock: json['stock'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      images: imgList,
    );
  }

  Map<String, dynamic> toJson() => {
    'skuId': skuId,
    'attributes': attributes,
    'stock': stock,
    'price': price,
    'images': images,
  };

  /// Helper: first image or null
  String? get primaryImage => images.isNotEmpty ? images.first : null;
}

/// Product specification (Material, Fabric, Care Instructions, etc.)
class ProductSpec {
  final String key;
  final String value;

  ProductSpec({required this.key, required this.value});

  factory ProductSpec.fromJson(Map<String, dynamic> json) {
    return ProductSpec(
      key: json['key'] ?? '',
      value: json['value'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'key': key, 'value': value};
}

/// Product dimensions for shipping
class ProductDimensions {
  final double length;
  final double width;
  final double height;

  ProductDimensions({
    this.length = 0,
    this.width = 0,
    this.height = 0,
  });

  factory ProductDimensions.fromJson(Map<String, dynamic> json) {
    return ProductDimensions(
      length: (json['length'] ?? 0).toDouble(),
      width: (json['width'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'length': length,
    'width': width,
    'height': height,
  };

  String get displayString => '${length.round()} × ${width.round()} × ${height.round()} cm';
}

/// Reference to category/brand
class CategoryRef {
  final String id;
  final String name;

  CategoryRef({required this.id, required this.name});

  factory CategoryRef.fromJson(Map<String, dynamic> json) {
    return CategoryRef(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

/// Grouped variant type with its items (e.g., "Size" -> ["S", "M", "L"])
class VariantGroup {
  final String typeName;
  final List<String> items;

  VariantGroup({required this.typeName, required this.items});

  factory VariantGroup.fromJson(Map<String, dynamic> json) {
    // variantTypeName is denormalized, but also check populated variantTypeId
    String name = json['variantTypeName'] ?? '';
    if (name.isEmpty && json['variantTypeId'] is Map) {
      name = json['variantTypeId']['name'] ?? json['variantTypeId']['type'] ?? 'Variant';
    }
    if (name.isEmpty) name = 'Variant';

    List<String> items = [];
    if (json['items'] != null && json['items'] is List) {
      items = List<String>.from(json['items']);
    }

    return VariantGroup(typeName: name, items: items);
  }

  bool get isColor => typeName.toLowerCase().contains('color') || typeName.toLowerCase().contains('colour');
}

/// Seller option for multi-vendor products
class OtherSeller {
  final String supplierId;
  final String shopName;
  final double price;
  final double? offerPrice;
  final int quantity;
  final String stockStatus;
  final String? supplierProductId;
  final bool isBase;

  OtherSeller({
    required this.supplierId,
    required this.shopName,
    required this.price,
    this.offerPrice,
    required this.quantity,
    required this.stockStatus,
    this.supplierProductId,
    required this.isBase,
  });

  factory OtherSeller.fromJson(Map<String, dynamic> json) {
    return OtherSeller(
      supplierId: json['supplierId'] ?? '',
      shopName: json['shopName'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      offerPrice: json['offerPrice'] != null ? (json['offerPrice']).toDouble() : null,
      quantity: json['quantity'] ?? 0,
      stockStatus: json['stockStatus'] ?? 'out_of_stock',
      supplierProductId: json['supplierProductId'],
      isBase: json['isBase'] ?? false,
    );
  }
}
