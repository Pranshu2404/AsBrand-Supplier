import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../core/theme.dart';
import '../providers/supplier_provider.dart';
import '../models/product.dart';
import 'add_supplier_product_screen.dart';
import 'edit_supplier_product_screen.dart';

class SupplierProductsScreen extends StatefulWidget {
  const SupplierProductsScreen({super.key});

  @override
  State<SupplierProductsScreen> createState() => _SupplierProductsScreenState();
}

class _SupplierProductsScreenState extends State<SupplierProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final supplier = context.watch<SupplierProvider>();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Inventory',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, letterSpacing: -0.5)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSupplierProductScreen()));
          if (mounted) context.read<SupplierProvider>().fetchProducts();
        },
        backgroundColor: AppTheme.primaryAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add SKU', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: supplier.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent))
          : supplier.products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: AppTheme.surfaceColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Iconsax.box, size: 48, color: AppTheme.textHint),
                      ),
                      const SizedBox(height: 24),
                      const Text('No Inventory Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      const SizedBox(height: 8),
                      const Text('Tap the + button to add your first SKU',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => supplier.fetchProducts(),
                  color: AppTheme.primaryAccent,
                  backgroundColor: AppTheme.surfaceColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: supplier.products.length,
                    itemBuilder: (context, index) => _buildProductCard(supplier.products[index]),
                  ),
                ),
    );
  }

  Widget _buildProductCard(Product product) {
    final imageUrl = product.images.isNotEmpty ? product.images.first : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Product image
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                image: imageUrl != null
                    ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: imageUrl == null
                  ? const Icon(Iconsax.image, color: AppTheme.textHint, size: 30)
                  : null,
            ),
            const SizedBox(width: 14),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('₹${product.offerPrice ?? product.price}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      if (product.offerPrice != null && product.offerPrice! < product.price) ...[
                        const SizedBox(width: 6),
                        Text('₹${product.price}',
                          style: const TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough, color: AppTheme.textSecondary)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.quantity > 0 ? AppTheme.successGreen.withOpacity(0.15) : AppTheme.errorColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.quantity > 0 ? 'In Stock (${product.quantity})' : 'Out of Stock',
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: product.quantity > 0 ? AppTheme.successGreen : AppTheme.errorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                IconButton(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => EditSupplierProductScreen(product: product)
                    ));
                    if (mounted) context.read<SupplierProvider>().fetchProducts();
                  },
                  icon: const Icon(Iconsax.edit, color: AppTheme.primaryAccent, size: 20),
                ),
                IconButton(
                  onPressed: () => _confirmDelete(product),
                  icon: const Icon(Iconsax.trash, color: AppTheme.errorColor, size: 20),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Product product) {
    // For linked products, use supplierProductId; for own listings, use product.id
    final idToDelete = product.supplierProductId ?? product.id;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF27272A)),
        ),
        title: const Text('Delete SKU?', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${product.name}"?', 
          style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<SupplierProvider>().deleteProduct(idToDelete);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('SKU deleted successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
