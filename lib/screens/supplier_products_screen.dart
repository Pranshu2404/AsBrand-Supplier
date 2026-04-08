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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Products',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSupplierProductScreen()));
          if (mounted) context.read<SupplierProvider>().fetchProducts();
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: supplier.isLoading
          ? const Center(child: CircularProgressIndicator())
          : supplier.products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.box, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('No Products Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Tap the + button to add your first product',
                        style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => supplier.fetchProducts(),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Product image
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                image: imageUrl != null
                    ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: imageUrl == null
                  ? Icon(Iconsax.image, color: Colors.grey.shade300, size: 30)
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
                          style: TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough, color: Colors.grey.shade400)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: product.quantity > 0 ? AppTheme.successGreen.withOpacity(0.1) : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.quantity > 0 ? 'In Stock (${product.quantity})' : 'Out of Stock',
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: product.quantity > 0 ? AppTheme.successGreen : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Edit button
            IconButton(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => EditSupplierProductScreen(product: product)
                ));
                if (mounted) context.read<SupplierProvider>().fetchProducts();
              },
              icon: const Icon(Iconsax.edit, color: AppTheme.primaryColor, size: 20),
            ),
            // Delete button
            IconButton(
              onPressed: () => _confirmDelete(product),
              icon: const Icon(Iconsax.trash, color: Colors.red, size: 20),
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<SupplierProvider>().deleteProduct(idToDelete);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
