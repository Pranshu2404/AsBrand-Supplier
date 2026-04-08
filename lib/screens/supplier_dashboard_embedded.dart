import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/supplier_provider.dart';
import 'supplier_products_screen.dart';
import 'supplier_new_orders_screen.dart';
import 'add_supplier_product_screen.dart';
import 'supplier/supplier_finance_screen.dart';

/// Embedded version of the dashboard — used inside SupplierShell (no back button).
class SupplierDashboardScreenEmbedded extends StatefulWidget {
  const SupplierDashboardScreenEmbedded({super.key});

  @override
  State<SupplierDashboardScreenEmbedded> createState() =>
      _SupplierDashboardScreenEmbeddedState();
}

class _SupplierDashboardScreenEmbeddedState
    extends State<SupplierDashboardScreenEmbedded>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final auth = context.watch<AuthProvider>();
    final supplier = context.watch<SupplierProvider>();
    final storeName = auth.user?.supplierProfile?.storeName ?? 'My Store';

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${auth.user?.name?.split(' ').first ?? 'Supplier'} 👋',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh, color: AppTheme.textPrimary, size: 22),
            onPressed: () => supplier.fetchDashboard(),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(auth, supplier, storeName),
    );
  }

  Widget _buildBody(AuthProvider auth, SupplierProvider supplier, String storeName) {
    final isApproved = auth.user?.supplierProfile?.isApproved ?? false;
    if (!isApproved) return _buildPendingApproval(storeName);
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
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.warningYellow.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_empty_rounded, color: AppTheme.warningYellow, size: 44),
            ),
            const SizedBox(height: 24),
            const Text('Application Under Review',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            Text(
              'Your supplier account "$storeName" is pending admin approval.\nYou\'ll get access to the dashboard once approved.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovedDashboard(SupplierProvider supplier, String storeName) {
    return RefreshIndicator(
      onRefresh: () => supplier.fetchDashboard(),
      color: AppTheme.primaryAccent,
      backgroundColor: AppTheme.surfaceColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Operational Revenue Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.activeOrderGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Iconsax.shop, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(storeName,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.successGreen.withOpacity(0.5)),
                              ),
                              child: const Text('VERIFIED',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                      color: AppTheme.successGreen)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TOTAL REVENUE',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: Colors.white.withOpacity(0.7))),
                          const SizedBox(height: 6),
                          Text('₹${supplier.totalRevenue}',
                              style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.0,
                                  color: Colors.white)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SupplierFinanceScreen()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.15),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('View Payouts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios, size: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // High-Contrast Operational Stats
            const Text('OPERATIONAL METRICS',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Iconsax.clock,
                    label: 'Pending',
                    value: '${supplier.pendingOrders}',
                    color: AppTheme.accentOrange,
                    isAlert: supplier.pendingOrders > 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Iconsax.shopping_bag,
                    label: 'Orders',
                    value: '${supplier.totalOrders}',
                    color: AppTheme.primaryAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Iconsax.tick_circle,
                    label: 'Active Items',
                    value: '${supplier.activeProducts}',
                    color: AppTheme.successGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Iconsax.box,
                    label: 'Total Items',
                    value: '${supplier.totalProducts}',
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions (Zepto style solid un-raised cards)
            const Text('QUICK ACTIONS',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            _buildActionCard(
              icon: Iconsax.add_circle,
              title: 'Add New Product',
              subtitle: 'Instantly list a new SKU',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddSupplierProductScreen())),
            ),
            const SizedBox(height: 10),
            _buildActionCard(
              icon: Iconsax.box,
              title: 'Inventory & Pricing',
              subtitle: 'Update stock to avoid cancellations',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SupplierProductsScreen())),
            ),
            const SizedBox(height: 10),
            _buildActionCard(
              icon: Iconsax.receipt,
              title: 'Order History',
              subtitle: 'View completed and cancelled orders',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SupplierNewOrdersScreen())),
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
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlert ? color.withOpacity(0.5) : const Color(0xFF27272A),
          width: isAlert ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              if (isAlert)
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                )
            ],
          ),
          const SizedBox(height: 16),
          Text(value,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.0,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.textPrimary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Iconsax.arrow_right_3_copy, size: 18, color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }
}
