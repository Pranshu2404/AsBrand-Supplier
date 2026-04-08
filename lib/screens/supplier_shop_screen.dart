import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/product_card.dart';
import '../../providers/wishlist_provider.dart';
import '../models/review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../product/product_detail_screen.dart';

// ─────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────
class _C {
  static const primary      = Color(0xFFFF3F6C);
  static const primaryLight = Color(0xFFFFF0F4);
  static const accent       = Color(0xFFFF6B2B);
  static const textPrimary  = Color(0xFF1A1A2E);
  static const textSecondary= Color(0xFF6B7280);
  static const textHint     = Color(0xFF9CA3AF);
  static const surface      = Color(0xFFF8F8FC);
  static const border       = Color(0xFFF0F0F5);
  static const success      = Color(0xFF16A34A);
  static const gold         = Color(0xFFF5A623);
  static const white        = Colors.white;
  static const blue         = Color(0xFF4F46E5);
}

// ─────────────────────────────────────────────────────────────
//  SUPPLIER SHOP SCREEN — Zomato-style
// ─────────────────────────────────────────────────────────────
class SupplierShopScreen extends StatefulWidget {
  final String supplierId;
  final String storeName;
  final String distance;
  final Product? highlightedProduct;
  /// Full supplier data map from /nearest endpoint (optional but enriches header)
  final Map<String, dynamic>? supplierData;

  const SupplierShopScreen({
    super.key,
    required this.supplierId,
    required this.storeName,
    required this.distance,
    this.highlightedProduct,
    this.supplierData,
  });

  @override
  State<SupplierShopScreen> createState() => _SupplierShopScreenState();
}

class _SupplierShopScreenState extends State<SupplierShopScreen> {
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String? _error;
  String _activeFilter = 'All';
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  Map<String, dynamic>? _remoteSupplierData;
  bool _fetchingProfile = false;
  ReviewStats _stats = ReviewStats();

  // Info from supplierData
  String get _storeName {
    final data = widget.supplierData ?? _remoteSupplierData;
    return data?['supplierProfile']?['storeName'] ?? widget.storeName;
  }
  String get _city {
    final data = widget.supplierData ?? _remoteSupplierData;
    final pickup = data?['supplierProfile']?['pickupAddress'];
    if (pickup != null) {
      final parts = <String>[];
      if (pickup['city'] != null && pickup['city'].toString().isNotEmpty) parts.add(pickup['city']);
      if (pickup['state'] != null && pickup['state'].toString().isNotEmpty) parts.add(pickup['state']);
      return parts.join(', ');
    }
    return '';
  }
  String get _fullAddress {
    final data = widget.supplierData ?? _remoteSupplierData;
    final pickup = data?['supplierProfile']?['pickupAddress'];
    if (pickup != null) {
      return pickup['address']?.toString() ?? '';
    }
    return '';
  }
  int get _productCount => _allProducts.length;

  String? get _shopImage {
    if (_allProducts.isNotEmpty && _allProducts.first.primaryImage.isNotEmpty) {
      return _allProducts.first.primaryImage;
    }
    final sampleProducts = widget.supplierData?['sampleProducts'] as List?;
    if (sampleProducts != null && sampleProducts.isNotEmpty) {
      final images = sampleProducts[0]['images'] as List?;
      if (images != null && images.isNotEmpty) {
        return images[0]['url'];
      }
    }
    return null;
  }

  final List<String> _filters = ['All', 'In Stock', 'Price ↑', 'Price ↓', 'Newest'];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchSupplierStats();
    if (widget.supplierData == null) {
      _fetchSupplierProfile();
    }
  }

  Future<void> _fetchSupplierStats() async {
    try {
      final stats = await ApiService().getSupplierReviewStats(widget.supplierId);
      if (mounted) {
        setState(() => _stats = stats);
      }
    } catch (_) {}
  }

  Future<void> _fetchSupplierProfile() async {
    setState(() => _fetchingProfile = true);
    try {
      final profile = await ApiService().getSupplierById(widget.supplierId);
      if (profile != null && mounted) {
        setState(() => _remoteSupplierData = profile);
      }
    } catch (_) {}
    if (mounted) setState(() => _fetchingProfile = false);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    try {
      final products = await ApiService().getProducts(params: {'supplierId': widget.supplierId});
      if (mounted) {
        setState(() {
          _allProducts = products;
          // Put highlighted product first
          if (widget.highlightedProduct != null) {
            _allProducts.removeWhere((p) => p.id == widget.highlightedProduct!.id);
            _allProducts.insert(0, widget.highlightedProduct!);
          }
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load products';
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter() {
    List<Product> result = List.from(_allProducts);

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) =>
        p.name.toLowerCase().contains(q) ||
        (p.brand?.name?.toLowerCase().contains(q) ?? false) ||
        (p.description?.toLowerCase().contains(q) ?? false)
      ).toList();
    }

    // Apply filter
    switch (_activeFilter) {
      case 'In Stock':
        result = result.where((p) => p.quantity > 0).toList();
        break;
      case 'Price ↑':
        result.sort((a, b) => (a.offerPrice ?? a.price).compareTo(b.offerPrice ?? b.price));
        break;
      case 'Price ↓':
        result.sort((a, b) => (b.offerPrice ?? b.price).compareTo(a.offerPrice ?? a.price));
        break;
      case 'Newest':
        // Products are already sorted by createdAt desc from API
        break;
    }

    _filteredProducts = result;
  }

  void _onFilterTap(String filter) {
    setState(() {
      _activeFilter = filter;
      _applyFilter();
    });
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.surface,
        body: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            // ── Collapsing App Bar (with integrated Search) ──
            _buildSliverAppBar(),

            if (_fetchingProfile)
              const SliverToBoxAdapter(
                 child: LinearProgressIndicator(minHeight: 2, color: _C.primary),
              ),

            // ── Store Info & Trust Badges ──
            SliverToBoxAdapter(child: _buildStoreInfoCard()),

            // ── Filter Chips ──
            SliverToBoxAdapter(child: _buildFilterChips()),

            // ── Products Header ──
            SliverToBoxAdapter(child: _buildProductsHeader()),

            // ── Products Grid ──
            _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: _C.primary)),
                )
              : _error != null
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.warning_2, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: _C.textSecondary)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() { _isLoading = true; _error = null; });
                              _fetchProducts();
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: _C.primary),
                            child: const Text('Retry', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  )
                : _filteredProducts.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Iconsax.box, size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                ? 'No products match "$_searchQuery"'
                                : 'No products available',
                              style: const TextStyle(color: _C.textSecondary, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.56,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 14,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = _filteredProducts[index];
                            final isHighlighted = widget.highlightedProduct?.id == product.id;

                            return Consumer<WishlistProvider>(
                              builder: (context, wishlist, _) {
                                final isWishlisted = wishlist.isInWishlist(product.id);

                                return Container(
                                  decoration: isHighlighted
                                    ? BoxDecoration(
                                        border: Border.all(color: _C.primary, width: 2),
                                        borderRadius: BorderRadius.circular(20),
                                      )
                                    : null,
                                    child: ProductCard(
                                      imageUrl: product.primaryImage,
                                      name: product.name,
                                      price: product.offerPrice ?? product.price,
                                      originalPrice: product.price,
                                      rating: product.averageRating,
                                      reviewCount: product.totalReviews,
                                      emiPerMonth: product.emiPerMonth,
                                      isWishlisted: isWishlisted,
                                    brandName: product.brand?.name,
                                    isOutOfStock: !product.isInStock,
                                    isLowStock: product.isLowStock,
                                    onWishlistTap: () {
                                      wishlist.toggleWishlist(product);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(isWishlisted ? 'Removed from Wishlist' : 'Added to Wishlist'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductDetailScreen(product: product),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                          childCount: _filteredProducts.length,
                        ),
                      ),
                    ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  SLIVER APP BAR (gradient header with store name)
  // ─────────────────────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    final topPad = MediaQuery.of(context).padding.top;
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      toolbarHeight: 20,
      automaticallyImplyLeading: false,
      backgroundColor: _C.primary,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: _C.primary,
            image: _shopImage != null
                ? DecorationImage(
                    image: NetworkImage(_shopImage!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
                  )
                : null,
            gradient: _shopImage == null ? const LinearGradient(
              colors: [Color(0xFFFF3F6C), Color(0xFFFF6B44), Color(0xFFFF8C42)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ) : null,
          ),
          child: Stack(
            children: [
              // Decorative circles for a premium look
              Positioned(
                right: -20, top: -10,
                child: Container(
                  width: 120, height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -10, bottom: 20,
                child: Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              Column(
                children: [
                   SizedBox(height: topPad),
                  // Row 1: Back + Store Name + Share
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _storeName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_city.isNotEmpty)
                                Text(
                                  _city,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.75),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _shareShop, 
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.share, size: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          // Pinned search bar area
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildGlassSearchBar(),
        ),
      ),
    );
  }

  Widget _buildGlassSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.2),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                setState(() {
                  _searchQuery = v.trim();
                  _applyFilter();
                });
              },
              cursorColor: Colors.white,
              style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: 'Search in $_storeName',
                hintStyle: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w500),
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.search_rounded, size: 18, color: Colors.white.withOpacity(0.9)),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 40),
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {
                          _searchQuery = '';
                          _applyFilter();
                        });
                      },
                    )
                  : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  STORE INFO CARD (below app bar)
  // ─────────────────────────────────────────────────────────────
  Widget _buildStoreInfoCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildInfoChip(Iconsax.location, widget.distance, const Color(0xFFF3F4F6), _C.textPrimary),
              const SizedBox(width: 10),
              _buildInfoChip(Iconsax.box_1, '$_productCount Products', const Color(0xFFF0FDF4), _C.success),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _C.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: _C.gold),
                    const SizedBox(width: 4),
                    Text(_stats.averageRating > 0 ? _stats.averageRating.toStringAsFixed(1) : 'NEW', style: const TextStyle(color: _C.textPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
                    if (_stats.totalReviews > 0)
                      Text(' (${_stats.totalReviews})', style: const TextStyle(color: _C.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildBriefBadge(Icons.verified_rounded, 'Verified', _C.success),
              const SizedBox(width: 16),
              _buildBriefBadge(Iconsax.timer_1, 'Fast Delivery', _C.blue),
              const Spacer(),
              const Text('Open until 10 PM', style: TextStyle(fontSize: 11, color: _C.textSecondary, fontWeight: FontWeight.w500)),
            ],
          ),
          if (_fullAddress.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: _C.border, height: 1),
            ),
            GestureDetector(
              onTap: _openInGoogleMaps,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                   Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Iconsax.map, size: 16, color: _C.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fullAddress,
                          style: const TextStyle(fontSize: 12, color: _C.textPrimary, height: 1.3, fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Tap to open in Google Maps',
                          style: TextStyle(fontSize: 10, color: _C.blue, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _C.textHint),
                ],
              ),
            ),
          ],
          
          // Offers Banner (if any)
          if (_allProducts.any((p) => p.offerPrice != null && p.offerPrice! < p.price)) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_C.primary.withOpacity(0.08), Colors.orange.withOpacity(0.05)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.primary.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                   Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: _C.primary.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Iconsax.dcube, size: 14, color: _C.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Flat ${_getMaxDiscount()}% OFF on selected items',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _C.textPrimary),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Valid for a limited time',
                          style: TextStyle(fontSize: 11, color: _C.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: _C.textHint),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBriefBadge(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  int _getMaxDiscount() {
    int max = 0;
    for (final p in _allProducts) {
      if (p.offerPrice != null && p.offerPrice! < p.price) {
        final disc = (((p.price - p.offerPrice!) / p.price) * 100).round();
        if (disc > max) max = disc;
      }
    }
    return max;
  }

  Widget _buildInfoChip(IconData icon, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_rounded, size: 16, color: color),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  void _shareShop() {
    // Standard link (clickable in all apps)
    final webLink = 'https://asbrand.com/supplier/${widget.supplierId}';
    
    // Direct App Link (guaranteed redirection)
    final appLink = 'asbrand://supplier/${widget.supplierId}';

    final shareText = 'Check out *$_storeName* on AsBrand! 🏢\n\n'
        'Explore products: $webLink\n'
        '(If the link above doesn\'t open the app, use this: $appLink)\n\n'
        '📍 Store: $_fullAddress';

    Share.share(
      shareText,
      subject: 'Store spotlight: $_storeName',
    );
  }

  Future<void> _openInGoogleMaps() async {
    final profile = widget.supplierData?['supplierProfile'];
    final pickup = profile?['pickupAddress'];
    final location = pickup?['location'];
    
    String query = '';
    
    // Check for GeoJSON coordinates
    if (location != null && location['type'] == 'Point' && location['coordinates'] is List) {
      final lng = location['coordinates'][0];
      final lat = location['coordinates'][1];
      query = '$lat,$lng';
    } else if (_fullAddress.isNotEmpty) {
      // Fallback: search by address string
      query = Uri.encodeComponent('$_storeName, $_fullAddress');
    }

    if (query.isNotEmpty) {
      final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$query';
      try {
        if (await canLaunchUrlString(googleMapsUrl)) {
          await launchUrlString(googleMapsUrl, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not open Google Maps';
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to open Google Maps')),
          );
        }
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  FILTER CHIPS
  // ─────────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    return Container(
      height: 32,
      margin: const EdgeInsets.only(top: 20, bottom: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final filter = _filters[index];
          final isActive = _activeFilter == filter;

          return GestureDetector(
            onTap: () => _onFilterTap(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isActive ? _C.primary : _C.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    color: isActive ? Colors.white : _C.textPrimary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  PRODUCTS HEADER
  // ─────────────────────────────────────────────────────────────
  Widget _buildProductsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(
        children: [
          Text(
            _searchQuery.isNotEmpty
              ? '${_filteredProducts.length} results'
              : 'All Products',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _C.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '(${_filteredProducts.length})',
            style: const TextStyle(fontSize: 14, color: _C.textSecondary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
