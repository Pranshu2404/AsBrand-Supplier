/// Store model with dummy data for fashion/clothing stores
class Store {
  final String id;
  final String name;
  final String logo;
  final String banner;
  final String description;
  final double rating;
  final String category;
  final int productCount;
  final List<String> tags;
  final String brandColor; // Hex color for fallback

  Store({
    required this.id,
    required this.name,
    required this.logo,
    required this.banner,
    required this.description,
    required this.rating,
    required this.category,
    required this.productCount,
    this.tags = const [],
    this.brandColor = '#006D77',
  });

  /// Get all dummy stores - Fashion focused
  static List<Store> getDummyStores() {
    return [
      // Multi-brand Fashion Stores
      Store(
        id: 'store_myntra',
        name: 'Myntra Fashion',
        logo: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800',
        description: 'India\'s largest fashion destination. Shop the latest trends in clothing, footwear, and accessories.',
        rating: 4.6,
        category: 'Multi-brand',
        productCount: 5000,
        tags: ['Fashion', 'Trending', 'All Brands'],
        brandColor: '#FF3F6C',
      ),
      Store(
        id: 'store_ajio',
        name: 'AJIO',
        logo: 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=800',
        description: 'Handpicked styles from top brands. Exclusive collections you won\'t find anywhere else.',
        rating: 4.5,
        category: 'Multi-brand',
        productCount: 4000,
        tags: ['Exclusive', 'Premium', 'Curated'],
        brandColor: '#5C5C5C',
      ),

      // Women's Fashion
      Store(
        id: 'store_hm',
        name: 'H&M',
        logo: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800',
        description: 'Fashion and quality at the best price. Explore the latest trends in clothing, accessories, and more.',
        rating: 4.5,
        category: "Women's Fashion",
        productCount: 2500,
        tags: ['Fashion', 'Trendy', 'Affordable'],
        brandColor: '#E50010',
      ),
      Store(
        id: 'store_zara',
        name: 'Zara',
        logo: 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=800',
        description: 'Latest fashion trends for women, men and kids at ZARA. Find the best styles and latest collections.',
        rating: 4.7,
        category: "Women's Fashion",
        productCount: 1800,
        tags: ['Premium', 'International', 'Chic'],
        brandColor: '#000000',
      ),
      Store(
        id: 'store_biba',
        name: 'Biba',
        logo: 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?w=800',
        description: 'India\'s leading ethnic wear brand. Beautiful kurtis, suits, and fusion wear for the modern woman.',
        rating: 4.4,
        category: "Women's Fashion",
        productCount: 1200,
        tags: ['Ethnic', 'Kurtas', 'Indian'],
        brandColor: '#B91C8B',
      ),
      Store(
        id: 'store_w',
        name: 'W for Woman',
        logo: 'https://images.unsplash.com/photo-1485968579169-a6e9ad7d7784?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1485968579169-a6e9ad7d7784?w=800',
        description: 'Contemporary Indian wear for the modern woman. Stylish kurtas, palazzos, and ethnic fusion.',
        rating: 4.3,
        category: "Women's Fashion",
        productCount: 900,
        tags: ['Fusion', 'Contemporary', 'Ethnic'],
        brandColor: '#FF6B35',
      ),
      Store(
        id: 'store_globaldesi',
        name: 'Global Desi',
        logo: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=800',
        description: 'Bohemian-inspired fashion with vibrant prints and colors. Express your free spirit.',
        rating: 4.2,
        category: "Women's Fashion",
        productCount: 800,
        tags: ['Boho', 'Prints', 'Colorful'],
        brandColor: '#E94F37',
      ),
      Store(
        id: 'store_forever21',
        name: 'Forever 21',
        logo: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
        description: 'Shop the latest trends in fashion and accessories for women, men, and girls.',
        rating: 4.2,
        category: "Women's Fashion",
        productCount: 1200,
        tags: ['Fashion', 'Youth', 'Trendy'],
        brandColor: '#FFD700',
      ),

      // Men's Fashion
      Store(
        id: 'store_allensolly',
        name: 'Allen Solly',
        logo: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800',
        description: 'Work to weekend fashion for men and women. Smart casuals and formals.',
        rating: 4.5,
        category: "Men's Fashion",
        productCount: 1500,
        tags: ['Formals', 'Smart Casual', 'Office'],
        brandColor: '#0066B3',
      ),
      Store(
        id: 'store_vanheusen',
        name: 'Van Heusen',
        logo: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800',
        description: 'Premium menswear for the modern professional. Suits, shirts, and accessories.',
        rating: 4.6,
        category: "Men's Fashion",
        productCount: 1200,
        tags: ['Premium', 'Formals', 'Professional'],
        brandColor: '#1A1A1A',
      ),
      Store(
        id: 'store_peterengland',
        name: 'Peter England',
        logo: 'https://images.unsplash.com/photo-1620012253295-c15cc3e65df4?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1620012253295-c15cc3e65df4?w=800',
        description: 'India\'s #1 menswear brand. Affordable formals and casuals for every occasion.',
        rating: 4.4,
        category: "Men's Fashion",
        productCount: 1800,
        tags: ['Affordable', 'Formals', 'Trusted'],
        brandColor: '#003366',
      ),
      Store(
        id: 'store_raymond',
        name: 'Raymond',
        logo: 'https://images.unsplash.com/photo-1617137968427-85924c800a22?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1617137968427-85924c800a22?w=800',
        description: 'The Complete Man. Premium suits, blazers, and fine fabrics since 1925.',
        rating: 4.7,
        category: "Men's Fashion",
        productCount: 800,
        tags: ['Premium', 'Suits', 'Legacy'],
        brandColor: '#4A4A4A',
      ),
      Store(
        id: 'store_levis',
        name: "Levi's",
        logo: 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=800',
        description: 'The inventor of the blue jean. Iconic jeans, jackets, and apparel for men and women.',
        rating: 4.7,
        category: "Men's Fashion",
        productCount: 1000,
        tags: ['Denim', 'Classic', 'Iconic'],
        brandColor: '#C41230',
      ),
      Store(
        id: 'store_pepe',
        name: 'Pepe Jeans',
        logo: 'https://images.unsplash.com/photo-1576995853123-5a10305d93c0?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1576995853123-5a10305d93c0?w=800',
        description: 'London-born denim brand. Premium jeans, shirts, and casual wear.',
        rating: 4.4,
        category: "Men's Fashion",
        productCount: 900,
        tags: ['Denim', 'Casual', 'International'],
        brandColor: '#1E3A5F',
      ),

      // Ethnic Wear
      Store(
        id: 'store_fabindia',
        name: 'Fabindia',
        logo: 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=800',
        description: 'Celebrate Indian craftsmanship. Handwoven textiles, ethnic wear, and home décor.',
        rating: 4.5,
        category: 'Ethnic Wear',
        productCount: 2000,
        tags: ['Handloom', 'Artisan', 'Sustainable'],
        brandColor: '#8B4513',
      ),
      Store(
        id: 'store_manyavar',
        name: 'Manyavar',
        logo: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800',
        description: 'India\'s largest ethnic wear brand for men. Sherwanis, kurtas, and wedding collection.',
        rating: 4.6,
        category: 'Ethnic Wear',
        productCount: 1500,
        tags: ['Wedding', 'Sherwanis', 'Festive'],
        brandColor: '#8B0000',
      ),
      Store(
        id: 'store_libas',
        name: 'Libas',
        logo: 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?w=800',
        description: 'Elegant ethnic wear for women. Kurta sets, salwar suits, and festive collections.',
        rating: 4.3,
        category: 'Ethnic Wear',
        productCount: 1100,
        tags: ['Kurtas', 'Festive', 'Traditional'],
        brandColor: '#D4AF37',
      ),

      // Sportswear & Activewear
      Store(
        id: 'store_nike',
        name: 'Nike',
        logo: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800',
        description: 'Just Do It. Shop the latest sneakers, athletic clothing, and sports gear.',
        rating: 4.8,
        category: 'Sportswear',
        productCount: 2000,
        tags: ['Sports', 'Sneakers', 'Athletic'],
        brandColor: '#000000',
      ),
      Store(
        id: 'store_adidas',
        name: 'Adidas',
        logo: 'https://images.unsplash.com/photo-1556906781-9a412961c28c?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1556906781-9a412961c28c?w=800',
        description: 'Impossible is Nothing. Premium sportswear, sneakers, and athletic accessories.',
        rating: 4.7,
        category: 'Sportswear',
        productCount: 1800,
        tags: ['Sports', 'Originals', 'Performance'],
        brandColor: '#000000',
      ),
      Store(
        id: 'store_puma',
        name: 'Puma',
        logo: 'https://images.unsplash.com/photo-1608231387042-66d1773070a5?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1608231387042-66d1773070a5?w=800',
        description: 'Forever Faster. Sports footwear, apparel, and accessories for athletes.',
        rating: 4.5,
        category: 'Sportswear',
        productCount: 1200,
        tags: ['Running', 'Training', 'Lifestyle'],
        brandColor: '#000000',
      ),
      Store(
        id: 'store_reebok',
        name: 'Reebok',
        logo: 'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=800',
        description: 'Be More Human. Fitness footwear and apparel for training and lifestyle.',
        rating: 4.4,
        category: 'Sportswear',
        productCount: 900,
        tags: ['Fitness', 'CrossFit', 'Training'],
        brandColor: '#D81B3C',
      ),

      // Footwear
      Store(
        id: 'store_bata',
        name: 'Bata',
        logo: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800',
        description: 'Shoes for everyone. Trusted footwear brand with styles for work, casual, and formal.',
        rating: 4.3,
        category: 'Footwear',
        productCount: 1500,
        tags: ['Shoes', 'Affordable', 'All Occasion'],
        brandColor: '#E31937',
      ),
      Store(
        id: 'store_woodland',
        name: 'Woodland',
        logo: 'https://images.unsplash.com/photo-1520639888713-7851133b1ed0?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1520639888713-7851133b1ed0?w=800',
        description: 'Adventure-ready footwear. Rugged shoes, boots, and outdoor gear.',
        rating: 4.5,
        category: 'Footwear',
        productCount: 600,
        tags: ['Outdoor', 'Boots', 'Adventure'],
        brandColor: '#2E5902',
      ),
      Store(
        id: 'store_clarks',
        name: 'Clarks',
        logo: 'https://images.unsplash.com/photo-1449505278894-297fdb3ed98c?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1449505278894-297fdb3ed98c?w=800',
        description: 'British footwear since 1825. Premium comfort shoes and boots.',
        rating: 4.6,
        category: 'Footwear',
        productCount: 500,
        tags: ['Premium', 'Comfort', 'Classic'],
        brandColor: '#1A1A1A',
      ),

      // Accessories
      Store(
        id: 'store_titan',
        name: 'Titan',
        logo: 'https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=800',
        description: 'Be More. India\'s leading watch brand with elegant timepieces.',
        rating: 4.6,
        category: 'Accessories',
        productCount: 500,
        tags: ['Watches', 'Premium', 'Indian'],
        brandColor: '#8B4513',
      ),
      Store(
        id: 'store_fossil',
        name: 'Fossil',
        logo: 'https://images.unsplash.com/photo-1587836374828-4dbafa94cf0e?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1587836374828-4dbafa94cf0e?w=800',
        description: 'Authentic vintage style watches, bags, and accessories.',
        rating: 4.5,
        category: 'Accessories',
        productCount: 400,
        tags: ['Watches', 'Bags', 'Vintage'],
        brandColor: '#000000',
      ),
      Store(
        id: 'store_lavie',
        name: 'Lavie',
        logo: 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=800',
        description: 'Trendy handbags and accessories for the modern woman. Style meets functionality.',
        rating: 4.3,
        category: 'Accessories',
        productCount: 600,
        tags: ['Handbags', 'Trendy', 'Women'],
        brandColor: '#FF1493',
      ),
      Store(
        id: 'store_caprese',
        name: 'Caprese',
        logo: 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=200&h=200&fit=crop',
        banner: 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=800',
        description: 'Chic handbags and wallets. Italian-inspired designs for the fashion-forward.',
        rating: 4.4,
        category: 'Accessories',
        productCount: 450,
        tags: ['Handbags', 'Wallets', 'Chic'],
        brandColor: '#C41E3A',
      ),
    ];
  }

  /// Get stores by category
  static List<Store> getStoresByCategory(String category) {
    if (category == 'All') return getDummyStores();
    return getDummyStores().where((s) => s.category == category).toList();
  }

  /// Get store categories - Fashion focused
  static List<String> getCategories() {
    return ['All', "Men's Fashion", "Women's Fashion", 'Ethnic Wear', 'Sportswear', 'Footwear', 'Accessories'];
  }

  /// Search stores
  static List<Store> searchStores(String query) {
    final lower = query.toLowerCase();
    return getDummyStores().where((s) => 
      s.name.toLowerCase().contains(lower) ||
      s.category.toLowerCase().contains(lower) ||
      s.tags.any((t) => t.toLowerCase().contains(lower))
    ).toList();
  }
}
