import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/supplier_provider.dart';
import 'supplier_products_screen.dart';
import 'supplier_orders_screen.dart';
import 'add_supplier_product_screen.dart';

class SupplierDashboardScreen extends StatefulWidget {
  const SupplierDashboardScreen({super.key});

  @override
  State<SupplierDashboardScreen> createState() => _SupplierDashboardScreenState();
}

class _SupplierDashboardScreenState extends State<SupplierDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final supplier = context.watch<SupplierProvider>();
    final storeName = auth.user?.supplierProfile?.storeName ?? 'My Store';

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
        title: const Text('Supplier Dashboard',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        centerTitle: true,
      ),
      body: _buildBody(auth, supplier, storeName),
    );
  }

  Widget _buildBody(AuthProvider auth, SupplierProvider supplier, String storeName) {
    final isApproved = auth.user?.supplierProfile?.isApproved ?? false;

    if (!isApproved) {
      return _buildPendingApproval(storeName);
    }
    return _buildApprovedDashboard(supplier, storeName);
  }

  Widget _buildPendingApproval(String storeName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_empty_rounded, color: Colors.orange, size: 50),
            ),
            const SizedBox(height: 28),
            const Text('Application Under Review',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Your supplier account "$storeName" is pending admin approval.\nYou\'ll get access to the dashboard once approved.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.6),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.info_circle, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('This usually takes 1-2 business days.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovedDashboard(SupplierProvider supplier, String storeName) {
    return RefreshIndicator(
      onRefresh: () => supplier.fetchDashboard(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E1E2E), Color(0xFF0A0A0B)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Iconsax.shop, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(storeName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('✓ Verified Supplier',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.successGreen)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Total Revenue',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
                  const SizedBox(height: 4),
                  Text('₹${supplier.totalRevenue}',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats Grid
            Row(
              children: [
                Expanded(child: _buildStatCard(
                  icon: Iconsax.box,
                  label: 'Products',
                  value: '${supplier.totalProducts}',
                  color: const Color(0xFF6366F1),
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(
                  icon: Iconsax.shopping_bag,
                  label: 'Orders',
                  value: '${supplier.totalOrders}',
                  color: const Color(0xFFF59E0B),
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard(
                  icon: Iconsax.tick_circle,
                  label: 'Active',
                  value: '${supplier.activeProducts}',
                  color: AppTheme.successGreen,
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(
                  icon: Iconsax.clock,
                  label: 'Pending',
                  value: '${supplier.pendingOrders}',
                  color: const Color(0xFFEF4444),
                )),
              ],
            ),
            const SizedBox(height: 28),

            // Quick Actions
            const Text('Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 14),
            _buildActionCard(
              icon: Iconsax.add_circle,
              title: 'Add New Product',
              subtitle: 'List a new product for sale',
              color: const Color(0xFF6366F1),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSupplierProductScreen())),
            ),
            const SizedBox(height: 10),
            _buildActionCard(
              icon: Iconsax.box,
              title: 'My Products',
              subtitle: 'View and manage your products',
              color: AppTheme.successGreen,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupplierProductsScreen())),
            ),
            const SizedBox(height: 10),
            _buildActionCard(
              icon: Iconsax.shopping_bag,
              title: 'My Orders',
              subtitle: 'View orders on your products',
              color: const Color(0xFFF59E0B),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupplierOrdersScreen())),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
