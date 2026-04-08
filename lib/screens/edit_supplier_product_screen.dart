import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme.dart';
import '../providers/supplier_provider.dart';
import '../providers/category_provider.dart';
import '../models/category.dart';
import '../models/sub_sub_category.dart';
import '../models/product.dart';
import '../services/api_service.dart';

// ─── Data helpers ────────────────────────────────────────────────────────────

/// One variant row: a type name (e.g. "Color") and a comma-separated list of
/// values the user typed (e.g. "Red, Blue, Green").
class _VariantRow {
  String typeName;
  List<String> values; // individual tokens after splitting

  _VariantRow({this.typeName = '', List<String>? values})
      : values = values ?? [];
}

/// One generated SKU (a combination of one value from each variant row).
class _SkuEntry {
  final Map<String, String> attributes; // e.g. {"Color": "Red", "Size": "M"}
  final String skuId;
  List<String> imageUrls; // Cloudinary URLs
  bool isUploading;

  // Use controllers so TextFormField stays in sync across setStates
  final TextEditingController stockCtrl;
  final TextEditingController priceCtrl;

  int get stock => int.tryParse(stockCtrl.text) ?? 0;
  double get price => double.tryParse(priceCtrl.text) ?? 0;

  _SkuEntry({
    required this.attributes,
    required this.skuId,
    int initialStock = 0,
    double initialPrice = 0,
    List<String>? imageUrls,
    this.isUploading = false,
  })  : imageUrls = imageUrls ?? [],
        stockCtrl = TextEditingController(text: initialStock.toString()),
        priceCtrl = TextEditingController(
            text: initialPrice > 0 ? initialPrice.toStringAsFixed(0) : '');

  void dispose() {
    stockCtrl.dispose();
    priceCtrl.dispose();
  }

  String get colorKey =>
      attributes.keys.firstWhere(
        (k) => k.toLowerCase().contains('color') || k.toLowerCase().contains('colour'),
        orElse: () => '',
      );

  String get colorValue => colorKey.isNotEmpty ? (attributes[colorKey] ?? '') : '';
}

// ─── Main Screen ─────────────────────────────────────────────────────────────

class EditSupplierProductScreen extends StatefulWidget {
  final Product product;
  const EditSupplierProductScreen({super.key, required this.product});

  @override
  State<EditSupplierProductScreen> createState() => _EditSupplierProductScreenState();
}

class _EditSupplierProductScreenState extends State<EditSupplierProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _offerPriceController = TextEditingController();
  final _packagingChargeController = TextEditingController();
  final _quantityController = TextEditingController();

  // Category selection
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedSubCategoryId;
  String? _selectedSubCategoryName;
  String? _selectedSubSubCategoryId;
  String? _selectedSubSubCategoryName;

  String _selectedGender = 'Unisex';
  bool _isSubmitting = false;

  // General product images (used when no variants)
  final List<_UploadedImage> _uploadedImages = [];
  bool _isPickingImages = false;

  // Variant rows
  final List<_VariantRow> _variantRows = [];

  // Generated SKUs
  List<_SkuEntry> _skus = [];

  // Track selected SKU for preview (selected color index)
  int _selectedColorIndex = 0;

  final _genders = ['Men', 'Women', 'Kids', 'Unisex', 'Boys', 'Girls'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchAllData();
    });

    // Populate basic info
    _nameController.text = widget.product.name;
    if (widget.product.description != null) _descController.text = widget.product.description!;
    _priceController.text = widget.product.price.toStringAsFixed(0);
    if (widget.product.offerPrice != null) _offerPriceController.text = widget.product.offerPrice!.toStringAsFixed(0);
    if (widget.product.packagingCharge > 0) _packagingChargeController.text = widget.product.packagingCharge.toStringAsFixed(0);
    _quantityController.text = widget.product.quantity.toString();

    // Populate category IDs if references exist
    _selectedCategoryId = widget.product.category?.id;
    _selectedCategoryName = widget.product.category?.name;
    _selectedSubCategoryId = widget.product.subCategory?.id;
    _selectedSubCategoryName = widget.product.subCategory?.name;
    if (widget.product.subSubCategory != null) {
      _selectedSubSubCategoryId = widget.product.subSubCategory!.id;
      _selectedSubSubCategoryName = widget.product.subSubCategory!.name;
    }

    if (widget.product.gender != null) _selectedGender = widget.product.gender!;

    // Populate variant rows
    for (final group in widget.product.variantGroups) {
      if (group.typeName.isNotEmpty && group.items.isNotEmpty) {
        _variantRows.add(_VariantRow(typeName: group.typeName, values: List.from(group.items)));
      }
    }

    // Populate SKUs
    for (final sku in widget.product.skus) {
      _skus.add(_SkuEntry(
        attributes: Map.from(sku.attributes),
        skuId: sku.skuId,
        initialStock: sku.stock,
        initialPrice: sku.price,
        imageUrls: List.from(sku.images),
      ));
    }

    // Populate generic images if no SKUs
    if (_skus.isEmpty && widget.product.images.isNotEmpty) {
      for (final imgUrl in widget.product.images) {
        if (imgUrl.isNotEmpty) {
          _uploadedImages.add(_UploadedImage(cloudinaryUrl: imgUrl, isUploading: false));
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _offerPriceController.dispose();
    _packagingChargeController.dispose();
    _quantityController.dispose();
    // Dispose all SKU controllers
    for (final sku in _skus) {
      sku.dispose();
    }
    super.dispose();
  }

  // ── SKU Generation ──────────────────────────────────────────────────────────

  void _regenerateSkus() {
    // Filter rows that have both a type name and at least 1 value
    final validRows = _variantRows
        .where((r) => r.typeName.trim().isNotEmpty && r.values.isNotEmpty)
        .toList();

    if (validRows.isEmpty) {
      setState(() => _skus = []);
      return;
    }

    // Cartesian product of all variant values
    List<Map<String, String>> combos = [{}];
    for (final row in validRows) {
      final expanded = <Map<String, String>>[];
      for (final existing in combos) {
        for (final val in row.values) {
          expanded.add({...existing, row.typeName.trim(): val.trim()});
        }
      }
      combos = expanded;
    }

    // Merge new combos with existing SKUs to preserve stock/price/images
    final existingByKey = {
      for (final s in _skus) _skuKey(s.attributes): s,
    };

    // Group existing images by color value
    final imagesByColor = <String, List<String>>{};
    for (final s in _skus) {
      if (s.colorValue.isNotEmpty && s.imageUrls.isNotEmpty) {
        imagesByColor[s.colorValue] = s.imageUrls;
      }
    }

    final skuPrefix = _nameController.text.trim().replaceAll(' ', '-').toUpperCase();

    final newSkus = combos.asMap().entries.map((entry) {
      final idx = entry.key;
      final attrs = entry.value;
      final key = _skuKey(attrs);
      final existing = existingByKey[key];

      // Determine color for this SKU
      final colorKey = attrs.keys.firstWhere(
        (k) => k.toLowerCase().contains('color') || k.toLowerCase().contains('colour'),
        orElse: () => '',
      );
      final colorVal = colorKey.isNotEmpty ? (attrs[colorKey] ?? '') : '';
      final images = imagesByColor[colorVal] ?? existing?.imageUrls ?? [];

      return _SkuEntry(
        attributes: attrs,
        skuId: '${skuPrefix.isEmpty ? "SKU" : skuPrefix}-${_skuSuffix(attrs)}-${idx + 1}',
        initialStock: existing?.stock ?? int.tryParse(_quantityController.text.trim()) ?? 0,
        initialPrice: existing?.price ?? double.tryParse(_priceController.text.trim()) ?? 0,
        imageUrls: List<String>.from(images),
      );
    }).toList();

    // Dispose old controllers before replacing
    for (final old in _skus) {
      old.dispose();
    }

    setState(() {
      _skus = newSkus;
      _selectedColorIndex = 0;
    });
  }

  String _skuKey(Map<String, String> attrs) =>
      attrs.entries.map((e) => '${e.key}:${e.value}').join('|');

  String _skuSuffix(Map<String, String> attrs) =>
      attrs.values.map((v) => v.replaceAll(' ', '').toUpperCase()).join('-');

  // Returns unique colors from all SKUs (in order of first appearance)
  List<String> get _uniqueColors {
    final seen = <String>[];
    for (final sku in _skus) {
      if (sku.colorValue.isNotEmpty && !seen.contains(sku.colorValue)) {
        seen.add(sku.colorValue);
      }
    }
    return seen;
  }

  // Get SKUs for a given color value
  List<_SkuEntry> _skusForColor(String colorVal) =>
      _skus.where((s) => s.colorValue == colorVal).toList();

  // Get the first SKU of a given color (for image/display purposes)
  _SkuEntry? _firstSkuForColor(String colorVal) =>
      _skusForColor(colorVal).isNotEmpty ? _skusForColor(colorVal).first : null;

  // ── Image Upload ────────────────────────────────────────────────────────────

  Future<void> _pickAndUploadImages() async {
    if (_uploadedImages.length >= 5 || _isPickingImages) return;
    setState(() => _isPickingImages = true);
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(imageQuality: 70, maxWidth: 1200);
      if (pickedFiles.isNotEmpty) {
        for (var file in pickedFiles) {
          if (_uploadedImages.length >= 5) break;
          final idx = _uploadedImages.length;
          setState(() {
            _uploadedImages.add(_UploadedImage(localFile: File(file.path), isUploading: true));
          });
          try {
            final url = await ApiService().uploadProductImage(file.path);
            if (mounted) {
              setState(() {
                _uploadedImages[idx] = _UploadedImage(
                  localFile: File(file.path),
                  cloudinaryUrl: url,
                  isUploading: false,
                  failed: url == null,
                );
              });
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _uploadedImages[idx] = _UploadedImage(
                  localFile: File(file.path),
                  isUploading: false,
                  failed: true,
                );
              });
            }
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isPickingImages = false);
    }
  }

  Future<void> _pickSkuImage(String colorVal) async {
    // Find the first SKU index with this color (images are shared per color)
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 70, maxWidth: 1200);
    if (pickedFiles.isEmpty) return;

    // Mark first sku of this color as uploading
    final firstIdx = _skus.indexWhere((s) => s.colorValue == colorVal);
    if (firstIdx < 0) return;

    setState(() => _skus[firstIdx].isUploading = true);

    for (final file in pickedFiles) {
      try {
        final url = await ApiService().uploadProductImage(file.path);
        if (url != null && mounted) {
          setState(() {
            // Add url to ALL skus with this color
            for (final sku in _skus) {
              if (sku.colorValue == colorVal) {
                sku.imageUrls.add(url);
              }
            }
          });
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _skus[firstIdx].isUploading = false);
  }

  void _removeSkuImage(String colorVal, int imgIdx) {
    setState(() {
      for (final sku in _skus) {
        if (sku.colorValue == colorVal && imgIdx < sku.imageUrls.length) {
          sku.imageUrls.removeAt(imgIdx);
        }
      }
    });
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Determine if this is a linked product (SupplierProduct) or an own listing (Product)
    final isLinkedProduct = widget.product.supplierProductId != null;
    final idToUpdate = widget.product.supplierProductId ?? widget.product.id;

    if (!isLinkedProduct && (_selectedCategoryId == null || _selectedSubCategoryId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select category and subcategory')),
      );
      return;
    }

    // Images: either general or from SKUs
    final uploadedUrls = _uploadedImages
        .where((img) => img.cloudinaryUrl != null && !img.failed)
        .map((img) => img.cloudinaryUrl!)
        .toList();

    final hasSkuImages = _skus.isNotEmpty && _skus.any((s) => s.imageUrls.isNotEmpty);

    // Only require images for own listings (linked products use the base catalog images)
    if (!isLinkedProduct && uploadedUrls.isEmpty && !hasSkuImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one image')),
      );
      return;
    }

    if (_uploadedImages.any((img) => img.isUploading)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for images to finish uploading')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Build fields map — for linked products only send price/qty/offerPrice
      final Map<String, dynamic> fields = {
        'price': _priceController.text.trim(),
        'quantity': _quantityController.text.trim(),
      };

      if (_offerPriceController.text.trim().isNotEmpty) {
        fields['offerPrice'] = _offerPriceController.text.trim();
      }
      if (_packagingChargeController.text.trim().isNotEmpty) {
        fields['packagingCharge'] = _packagingChargeController.text.trim();
      }

      // For own listings, also include the full product fields
      if (!isLinkedProduct) {
        fields['name'] = _nameController.text.trim();
        fields['description'] = _descController.text.trim();
        if (_selectedCategoryId != null) fields['proCategoryId'] = _selectedCategoryId!;
        if (_selectedSubCategoryId != null) fields['proSubCategoryId'] = _selectedSubCategoryId!;
        if (_selectedSubSubCategoryId != null) fields['proSubSubCategoryId'] = _selectedSubSubCategoryId!;
        fields['gender'] = _selectedGender;
      }

      // Build typed SKU list
      List<dynamic>? skuData;
      List<dynamic>? proVariants;

      if (_skus.isNotEmpty) {
        skuData = _skus.map((s) => {
          'skuId': s.skuId,
          'attributes': s.attributes,
          'stock': s.stock,
          'price': s.price,
          'images': s.imageUrls,
        }).toList();

        if (!isLinkedProduct) {
          final groups = <String, List<String>>{};
          for (final row in _variantRows) {
            if (row.typeName.trim().isNotEmpty && row.values.isNotEmpty) {
              groups[row.typeName.trim()] = row.values;
            }
          }
          proVariants = groups.entries.map((e) => {
            'variantTypeName': e.key,
            'items': e.value,
          }).toList();
        }
      }

      final success = await context.read<SupplierProvider>().updateProduct(
        idToUpdate,
        fields,
        skuData: skuData,
        proVariants: proVariants,
        preUploadedUrls: !isLinkedProduct && uploadedUrls.isNotEmpty ? uploadedUrls : null,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isLinkedProduct ? 'Linked product updated! ✅' : 'Product submitted for review! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        final errorMsg = context.read<SupplierProvider>().error ?? 'Failed to update product';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg.replaceAll('Exception:', '').trim()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception:', '').trim()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoryProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Product',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Linked Product Banner ──
              if (widget.product.supplierProductId != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.link, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Linked Catalog Product',
                                style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('You can only update your selling price and stock quantity for linked products.',
                                style: TextStyle(color: Colors.blue.shade600, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // ── General Images (only shown if no variants & NOT a linked product) ──
              if (_skus.isEmpty && widget.product.supplierProductId == null) ...[
                _buildSectionTitle('Product Images'),
                const SizedBox(height: 10),
                _buildImagePicker(),
                const SizedBox(height: 24),
              ],

              // ── Basic Info ──
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 10),
              _buildInputField(
                controller: _nameController,
                label: 'Product Name',
                hint: 'e.g. Cotton Round Neck T-Shirt',
                icon: Iconsax.box,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              _buildInputField(
                controller: _descController,
                label: 'Description',
                hint: 'Describe your product...',
                icon: Iconsax.document_text,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // ── Pricing & Stock ──
              _buildSectionTitle('Pricing & Stock'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      controller: _priceController,
                      label: 'MRP (₹)',
                      hint: '999',
                      icon: Iconsax.money,
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField(
                      controller: _offerPriceController,
                      label: 'Offer Price (₹)',
                      hint: '799',
                      icon: Iconsax.tag,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      controller: _quantityController,
                      label: 'Default Quantity',
                      hint: '100',
                      icon: Iconsax.box_1,
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField(
                      controller: _packagingChargeController,
                      label: 'Packaging Charge',
                      hint: '0',
                      icon: Iconsax.box_2,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Category Picker ──
              _buildSectionTitle('Select Category *'),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _openCategoryPicker(catProvider),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _selectedSubCategoryId != null
                            ? AppTheme.primaryColor
                            : Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _selectedSubCategoryName != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedCategoryName ?? '',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedSubCategoryName!,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary),
                                  ),
                                  if (_selectedSubSubCategoryName != null) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.subdirectory_arrow_right,
                                            size: 14, color: AppTheme.primaryColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          _selectedSubSubCategoryName!,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              )
                            : Text('Click here to select category',
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 22),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Gender ──
              _buildSectionTitle('Gender'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _genders
                    .map((g) => ChoiceChip(
                          label: Text(g),
                          selected: _selectedGender == g,
                          onSelected: (_) => setState(() => _selectedGender = g),
                          backgroundColor: Colors.grey.shade100,
                          selectedColor: AppTheme.primaryColor,
                          labelStyle: TextStyle(
                            color: _selectedGender == g ? Colors.white : AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),

              // ── Variants Section ──
              _buildVariantsSection(),
              const SizedBox(height: 32),

              // ── Submit ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Update Product',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ── Variants Section Widget ──────────────────────────────────────────────────

  Widget _buildVariantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildSectionTitle('Product Variants')),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _variantRows.add(_VariantRow());
                });
              },
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Add Variant'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'e.g. Color → Red, Blue, Green | Size → S, M, L, XL',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 12),

        // Variant input rows
        ..._variantRows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          return _buildVariantRow(i, row);
        }),

        // Generate button
        if (_variantRows.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _regenerateSkus,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Generate SKUs'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],

        // SKU cards
        if (_skus.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildSkuSection(),
        ],
      ],
    );
  }

  Widget _buildVariantRow(int index, _VariantRow row) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: row.typeName,
                  decoration: InputDecoration(
                    labelText: 'Variant Type',
                    hintText: 'e.g. Color, Size',
                    labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                  onChanged: (v) => setState(() => row.typeName = v),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _variantRows.removeAt(index);
                    _regenerateSkus();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: row.values.join(', '),
            decoration: InputDecoration(
              labelText: 'Values (comma-separated)',
              hintText: 'e.g. Red, Blue, Green',
              labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.primaryColor),
              ),
            ),
            onChanged: (v) {
              setState(() {
                row.values = v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
              });
            },
          ),
        ],
      ),
    );
  }

  // ── SKU Section ──────────────────────────────────────────────────────────────

  Widget _buildSkuSection() {
    final colors = _uniqueColors;
    final hasColor = colors.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Generated SKUs (${_skus.length} combinations)'),
        const SizedBox(height: 12),

        // Color selector tabs (if color variant exists)
        if (hasColor) ...[
          _buildColorTabs(colors),
          const SizedBox(height: 16),
          _buildColorSkuPanel(colors[_selectedColorIndex.clamp(0, colors.length - 1)]),
        ] else
          // No color variant — show all SKUs directly
          ..._skus.map((sku) => _buildSkuCard(sku, showImageUpload: true)),
      ],
    );
  }

  Widget _buildColorTabs(List<String> colors) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        itemBuilder: (ctx, i) {
          final selected = i == _selectedColorIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedColorIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? AppTheme.primaryColor : Colors.grey.shade300,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 8)]
                    : [],
              ),
              child: Text(
                colors[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorSkuPanel(String colorVal) {
    final firstSku = _firstSkuForColor(colorVal);
    final colorSkus = _skusForColor(colorVal);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  colorVal,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
              ),
              const Spacer(),
              Text(
                '${colorSkus.length} size${colorSkus.length > 1 ? "s" : ""}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Color Images
          if (firstSku != null) ...[
            Row(
              children: [
                Text('Images for $colorVal',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                firstSku.isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                    : TextButton.icon(
                        onPressed: () => _pickSkuImage(colorVal),
                        icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                        label: const Text('Add Images', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 8),
            if (firstSku.imageUrls.isNotEmpty)
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: firstSku.imageUrls.length,
                  itemBuilder: (ctx, imgIdx) {
                    return Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                            image: DecorationImage(
                              image: NetworkImage(firstSku.imageUrls[imgIdx]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -2,
                          right: 6,
                          child: GestureDetector(
                            onTap: () => _removeSkuImage(colorVal, imgIdx),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                  color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 12),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              )
            else
              Text('No images yet — tap "Add Images" above',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade400, fontStyle: FontStyle.italic)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
          ],

          // Per-size SKU cards
          ...colorSkus.map((sku) => _buildSkuCard(sku, showImageUpload: false)),
        ],
      ),
    );
  }

  Widget _buildSkuCard(_SkuEntry sku, {required bool showImageUpload}) {
    final nonColorAttrs = Map<String, String>.fromEntries(
      sku.attributes.entries.where(
        (e) =>
            !e.key.toLowerCase().contains('color') && !e.key.toLowerCase().contains('colour'),
      ),
    );
    final label = nonColorAttrs.isEmpty
        ? sku.attributes.entries.map((e) => '${e.key}: ${e.value}').join(' · ')
        : nonColorAttrs.entries.map((e) => '${e.key}: ${e.value}').join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: showImageUpload ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(sku.skuId,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSkuField(
                  label: 'Stock',
                  controller: sku.stockCtrl,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSkuField(
                  label: 'Price Override (₹)',
                  controller: sku.priceCtrl,
                  hint: 'Same as MRP',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkuField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary));
  }

  Widget _buildImagePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          if (_uploadedImages.isNotEmpty) ...[
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _uploadedImages.length,
                itemBuilder: (context, i) {
                  final img = _uploadedImages[i];
                  return Stack(
                    children: [
                      Container(
                        width: 110,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade100,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (img.cloudinaryUrl != null)
                                Image.network(img.cloudinaryUrl!, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image, size: 32))
                              else
                                Image.file(img.localFile!, fit: BoxFit.cover),
                              if (img.isUploading)
                                Container(
                                  color: Colors.black.withOpacity(0.5),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 30, height: 30,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2.5),
                                    ),
                                  ),
                                ),
                              if (!img.isUploading)
                                Positioned(
                                  bottom: 4, left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: img.failed ? Colors.red : Colors.green,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      img.failed ? 'Failed' : '✓',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (!img.isUploading)
                        Positioned(
                          top: 4, right: 14,
                          child: GestureDetector(
                            onTap: () => setState(() => _uploadedImages.removeAt(i)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration:
                                  const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          GestureDetector(
            onTap: _uploadedImages.length >= 5 ? null : _pickAndUploadImages,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: Column(
                children: [
                  if (_isPickingImages)
                    const SizedBox(
                        width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Icon(Iconsax.gallery_add, size: 32, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    _uploadedImages.length >= 5
                        ? 'Max images reached'
                        : 'Tap to add images (${_uploadedImages.length}/5)',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text('Images are compressed & uploaded to cloud',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade400),
          labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder:
              OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ── Category Picker ──────────────────────────────────────────────────────────

  void _openCategoryPicker(CategoryProvider catProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _CategoryPickerSheet(
        categories: catProvider.categories,
        subCategories: catProvider.subCategories,
        subSubCategories: catProvider.subSubCategories,
        onSelected: (catId, catName, subId, subName, subSubId, subSubName) {
          setState(() {
            _selectedCategoryId = catId;
            _selectedCategoryName = catName;
            _selectedSubCategoryId = subId;
            _selectedSubCategoryName = subName;
            _selectedSubSubCategoryId = subSubId;
            _selectedSubSubCategoryName = subSubName;
          });
        },
      ),
    );
  }
}

// ─── Category Picker Bottom Sheet (3-level) ───────────────────────────────────

class _CategoryPickerSheet extends StatefulWidget {
  final List<Category> categories;
  final List<SubCategory> subCategories;
  final List<SubSubCategory> subSubCategories;
  final void Function(
    String catId,
    String catName,
    String subId,
    String subName,
    String? subSubId,
    String? subSubName,
  ) onSelected;

  const _CategoryPickerSheet({
    required this.categories,
    required this.subCategories,
    required this.subSubCategories,
    required this.onSelected,
  });

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  String _search = '';
  Category? _drillCategory;
  SubCategory? _drillSubCategory;

  // ── Level 1: Categories ──

  List<Category> get _filteredCategories {
    if (_search.isEmpty) return widget.categories;
    final lower = _search.toLowerCase();
    return widget.categories.where((c) => c.name.toLowerCase().contains(lower)).toList();
  }

  // ── Level 2: SubCategories ──

  List<SubCategory> get _filteredSubCategories {
    if (_drillCategory == null) return [];
    final subs = widget.subCategories.where((s) => s.category?.id == _drillCategory!.id).toList();
    if (_search.isEmpty) return subs;
    final lower = _search.toLowerCase();
    return subs.where((s) => s.name.toLowerCase().contains(lower)).toList();
  }

  // ── Level 3: SubSubCategories ──

  List<SubSubCategory> get _filteredSubSubCategories {
    if (_drillSubCategory == null) return [];
    final ssubs = widget.subSubCategories
        .where((ss) => ss.subCategory?.id == _drillSubCategory!.id)
        .toList();
    if (_search.isEmpty) return ssubs;
    final lower = _search.toLowerCase();
    return ssubs.where((ss) => ss.name.toLowerCase().contains(lower)).toList();
  }

  String get _headerTitle {
    if (_drillSubCategory != null) return _drillSubCategory!.name;
    if (_drillCategory != null) return _drillCategory!.name;
    return 'Select Category';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.78,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            child: Row(
              children: [
                if (_drillCategory != null)
                  GestureDetector(
                    onTap: () => setState(() {
                      if (_drillSubCategory != null) {
                        _drillSubCategory = null;
                      } else {
                        _drillCategory = null;
                      }
                      _search = '';
                    }),
                    child: const Icon(Icons.arrow_back_ios, size: 18),
                  ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _headerTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Breadcrumb
          if (_drillCategory != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                children: [
                  Text(_drillCategory!.name,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  if (_drillSubCategory != null) ...[
                    Icon(Icons.chevron_right, size: 14, color: Colors.grey.shade400),
                    Text(_drillSubCategory!.name,
                        style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor)),
                  ],
                ],
              ),
            ),

          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          // List
          Expanded(
            child: _drillSubCategory != null
                ? _buildSubSubCategoryList()
                : _drillCategory != null
                    ? _buildSubCategoryList()
                    : _buildCategoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    final cats = _filteredCategories;
    if (cats.isEmpty) {
      return Center(
          child: Text('No categories found', style: TextStyle(color: Colors.grey.shade400)));
    }
    return ListView.separated(
      itemCount: cats.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (_, i) {
        final cat = cats[i];
        return ListTile(
          title: Text(cat.name, style: const TextStyle(fontSize: 15)),
          trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          onTap: () => setState(() {
            _drillCategory = cat;
            _search = '';
          }),
        );
      },
    );
  }

  Widget _buildSubCategoryList() {
    final subs = _filteredSubCategories;
    if (subs.isEmpty) {
      return Center(
          child: Text('No subcategories found', style: TextStyle(color: Colors.grey.shade400)));
    }
    return ListView.separated(
      itemCount: subs.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (_, i) {
        final sub = subs[i];
        // Check if this subcategory has sub-subcategories
        final hasSubSub = widget.subSubCategories.any((ss) => ss.subCategory?.id == sub.id);
        return ListTile(
          title: Text(sub.name, style: const TextStyle(fontSize: 15)),
          subtitle: hasSubSub
              ? Text('Has sub-categories', style: TextStyle(fontSize: 11, color: Colors.grey.shade400))
              : null,
          trailing: hasSubSub
              ? Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20)
              : Icon(Icons.check_circle_outline, color: Colors.grey.shade300, size: 20),
          onTap: () {
            if (hasSubSub) {
              setState(() {
                _drillSubCategory = sub;
                _search = '';
              });
            } else {
              // Select directly without sub-subcategory
              widget.onSelected(
                _drillCategory!.id,
                _drillCategory!.name,
                sub.id,
                sub.name,
                null,
                null,
              );
              Navigator.pop(context);
            }
          },
        );
      },
    );
  }

  Widget _buildSubSubCategoryList() {
    final ssubs = _filteredSubSubCategories;

    return ListView(
      children: [
        // Option to select just the subcategory (without sub-sub)
        ListTile(
          leading: const Icon(Icons.arrow_upward, size: 18, color: AppTheme.primaryColor),
          title: Text('Select "${_drillSubCategory!.name}" directly',
              style: const TextStyle(fontSize: 14, color: AppTheme.primaryColor)),
          onTap: () {
            widget.onSelected(
              _drillCategory!.id,
              _drillCategory!.name,
              _drillSubCategory!.id,
              _drillSubCategory!.name,
              null,
              null,
            );
            Navigator.pop(context);
          },
        ),
        Divider(height: 1, color: Colors.grey.shade200),
        if (ssubs.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text('No sub-sub-categories found',
                  style: TextStyle(color: Colors.grey.shade400)),
            ),
          )
        else
          ...List.generate(ssubs.length, (i) {
            final ss = ssubs[i];
            return Column(
              children: [
                ListTile(
                  title: Text(ss.name, style: const TextStyle(fontSize: 15)),
                  trailing: const Icon(Icons.check_circle_outline,
                      color: AppTheme.primaryColor, size: 20),
                  onTap: () {
                    widget.onSelected(
                      _drillCategory!.id,
                      _drillCategory!.name,
                      _drillSubCategory!.id,
                      _drillSubCategory!.name,
                      ss.id,
                      ss.name,
                    );
                    Navigator.pop(context);
                  },
                ),
                Divider(height: 1, color: Colors.grey.shade200),
              ],
            );
          }),
      ],
    );
  }
}

// ─── Helper class to track per-image upload state ─────────────────────────────

class _UploadedImage {
  final File? localFile;
  final String? cloudinaryUrl;
  final bool isUploading;
  final bool failed;

  _UploadedImage({
    this.localFile,
    this.cloudinaryUrl,
    this.isUploading = false,
    this.failed = false,
  });
}
