import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/theme.dart';
import '../../providers/supplier_provider.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import 'supplier_order_history_detail_screen.dart';
import 'package:intl/intl.dart';

class SupplierOrderHistoryScreen extends StatefulWidget {
  const SupplierOrderHistoryScreen({super.key});

  @override
  State<SupplierOrderHistoryScreen> createState() => _SupplierOrderHistoryScreenState();
}

class _SupplierOrderHistoryScreenState extends State<SupplierOrderHistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupplierProvider>();
    
    // Filter for completed/history statuses
    var historyOrders = provider.orders.where((o) {
      final status = o.orderStatus.toLowerCase();
      return ['delivered', 'rejected', 'cancelled'].contains(status);
    }).toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      historyOrders = historyOrders.where((o) {
        final orderId = o.id.length > 8 ? o.id.substring(o.id.length - 8).toUpperCase() : o.id.toUpperCase();
        return orderId.contains(_searchQuery.toUpperCase());
      }).toList();
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Order History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by Order ID...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Iconsax.search_normal, color: Colors.grey, size: 18),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // List mapping
          Expanded(
            child: historyOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.document_text_1, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No past orders found', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async => await provider.fetchOrders(),
                    color: AppTheme.primaryColor,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: historyOrders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildHistoryCard(historyOrders[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Order order) {
    final orderId = order.id.length > 8 ? order.id.substring(order.id.length - 8).toUpperCase() : order.id.toUpperCase();
    final status = order.orderStatus.toLowerCase();
    
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (status == 'delivered') {
      statusColor = Colors.green;
      statusText = 'Completed';
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.red;
      statusText = status == 'cancelled' ? 'Cancelled by User' : 'Rejected by You';
      statusIcon = Icons.cancel;
    }

    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(order.orderDate);
    
    // Filter items specific to this supplier
    final authProvider = context.read<AuthProvider>();
    final supplierItems = order.items.where((i) => i.supplierId == authProvider.user?.id).toList();
    final totalQty = supplierItems.fold<int>(0, (sum, i) => sum + i.quantity);
    
    // Calculate supplier-specific total for this order
    final earnings = supplierItems.fold<double>(0, (sum, i) => sum + (i.price * i.quantity));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SupplierOrderHistoryDetailScreen(order: order),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #$orderId',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(dateStr, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFE5E7EB)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    text: '$totalQty items',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary),
                    children: [
                      TextSpan(
                        text: ' for ',
                        style: TextStyle(fontWeight: FontWeight.normal, color: Colors.grey.shade500),
                      ),
                      TextSpan(
                        text: '₹${earnings.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
              ],
            )
          ],
        ),
      ),
    );
  }
}
