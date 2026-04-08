import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/supplier_provider.dart';
import '../models/order.dart';

class SupplierNewOrdersScreen extends StatefulWidget {
  const SupplierNewOrdersScreen({super.key});

  @override
  State<SupplierNewOrdersScreen> createState() =>
      _SupplierNewOrdersScreenState();
}

class _SupplierNewOrdersScreenState
    extends State<SupplierNewOrdersScreen> with AutomaticKeepAliveClientMixin {
  // Filter
  String _statusFilter = 'All';
  final List<String> _statuses = [
    'All',
    'pending',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final supplier = context.watch<SupplierProvider>();

    // Filter orders
    final allOrders = supplier.orders;
    final filtered = _statusFilter == 'All'
        ? allOrders
        : allOrders
            .where((o) =>
                o.orderStatus.toLowerCase() == _statusFilter.toLowerCase())
            .toList();

    // Group into today and previous
    final today = DateTime.now();
    final todayOrders = filtered.where((o) {
      return o.orderDate.year == today.year &&
          o.orderDate.month == today.month &&
          o.orderDate.day == today.day;
    }).toList();

    final previousOrders = filtered.where((o) {
      return !(o.orderDate.year == today.year &&
          o.orderDate.month == today.month &&
          o.orderDate.day == today.day);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          children: [
            const Text(
              'Orders',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            if (!supplier.isLoading && allOrders.isNotEmpty)
              Text(
                '${allOrders.length} total',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh, color: AppTheme.textPrimary, size: 20),
            onPressed: () => supplier.fetchOrders(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status filter chips
          _buildFilterChips(),

          // Orders list
          Expanded(
            child: supplier.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent))
                : filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: () => supplier.fetchOrders(),
                        color: AppTheme.primaryAccent,
                        backgroundColor: AppTheme.surfaceColor,
                        child: CustomScrollView(
                          slivers: [
                            // Today's orders section
                            if (todayOrders.isNotEmpty) ...[
                              SliverToBoxAdapter(
                                child: _buildSectionHeader(
                                  'Today',
                                  '${todayOrders.length} order${todayOrders.length > 1 ? 's' : ''}',
                                  AppTheme.successGreen,
                                ),
                              ),
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (ctx, i) => _OrderCard(
                                    order: todayOrders[i],
                                    isToday: true,
                                  ),
                                  childCount: todayOrders.length,
                                ),
                              ),
                            ],

                            // Previous orders section
                            if (previousOrders.isNotEmpty) ...[
                              SliverToBoxAdapter(
                                child: _buildSectionHeader(
                                  'Previous',
                                  '${previousOrders.length} order${previousOrders.length > 1 ? 's' : ''}',
                                  AppTheme.textSecondary,
                                ),
                              ),
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (ctx, i) => _OrderCard(
                                    order: previousOrders[i],
                                    isToday: false,
                                  ),
                                  childCount: previousOrders.length,
                                ),
                              ),
                            ],

                            const SliverToBoxAdapter(child: SizedBox(height: 24)),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: AppTheme.scaffoldBackground,
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _statuses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final s = _statuses[i];
          final isActive = _statusFilter == s;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _statusFilter = s);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryAccent : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppTheme.primaryAccent : const Color(0xFF27272A),
                ),
              ),
              child: Text(
                s == 'All' ? 'All' : _capitalize(s),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: AppTheme.surfaceColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.shopping_bag,
                size: 46,
                color: AppTheme.textHint,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Orders Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusFilter == 'All'
                  ? 'Orders from customers will appear here'
                  : 'No $_statusFilter orders found',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Order Card ──────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final Order order;
  final bool isToday;

  const _OrderCard({required this.order, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.orderStatus);
    final orderId = order.id.length >= 8
        ? order.id.substring(order.id.length - 8).toUpperCase()
        : order.id.toUpperCase();
    final timeLabel = isToday
        ? DateFormat('hh:mm a').format(order.orderDate)
        : DateFormat('dd MMM, hh:mm a').format(order.orderDate);

    return GestureDetector(
      onTap: () => _showOrderDetails(context, order),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                color: isToday
                    ? const Color(0xFF10B981).withOpacity(0.04)
                    : Colors.transparent,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  // Order ID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.receipt_long_outlined,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Order #$orderId',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          timeLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _capitalize(order.orderStatus),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            const Divider(height: 1, color: Color(0xFF27272A)),

            // Items preview
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  ...order.items.take(2).map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(10),
                                image: item.productImage.isNotEmpty
                                    ? DecorationImage(
                                        image:
                                            NetworkImage(item.productImage),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: item.productImage.isEmpty
                                  ? const Icon(Icons.inventory_2_outlined,
                                      color: AppTheme.textHint, size: 20)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (item.variant != null)
                                    Text(
                                      item.variant!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              'x${item.quantity}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₹${item.price.toInt()}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      )),

                  if (order.items.length > 2)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '+${order.items.length - 2} more items',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Footer with total + tap hint
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(18)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (order.paymentMethod != null) ...[
                        Icon(
                          order.paymentMethod!.toLowerCase() == 'cod'
                              ? Icons.money_outlined
                              : Icons.credit_card_outlined,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order.paymentMethod!.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '₹${order.totalPrice.toInt()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppTheme.textHint,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'processing':
        return const Color(0xFF3B82F6);
      case 'shipped':
        return const Color(0xFF6366F1);
      case 'delivered':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void _showOrderDetails(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailSheet(order: order),
    );
  }
}

// ── Order Detail Bottom Sheet ────────────────────────────────────────────────

class _OrderDetailSheet extends StatelessWidget {
  final Order order;

  const _OrderDetailSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    final orderId = order.id.length >= 8
        ? order.id.substring(order.id.length - 8).toUpperCase()
        : order.id.toUpperCase();
    final statusColor = _statusColor(order.orderStatus);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.scaffoldBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textHint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  children: [
                    // ── Order ID Highlight Card ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E1E2E), Color(0xFF0A0A0B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.receipt_long,
                                    color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order #$orderId',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd MMM yyyy, hh:mm a')
                                          .format(order.orderDate),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.55),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _capitalize(order.orderStatus),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          // Driver verification section
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF10B981).withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.local_shipping_outlined,
                                        color: Color(0xFF10B981), size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Driver Verification',
                                      style: TextStyle(
                                        color: Color(0xFF10B981),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ask the driver for this Order ID before handing over the package:',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(
                                        ClipboardData(text: order.id));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Order ID copied to clipboard'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: Colors.white.withOpacity(0.15)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            order.id,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'monospace',
                                              fontSize: 12,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.copy_outlined,
                                            color: Color(0xFF10B981), size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Order Items ──────────────────────────────────────────
                    _buildSection(
                      title: 'Order Items',
                      icon: Iconsax.box,
                      child: Column(
                        children: order.items
                            .map((item) => _buildItemRow(item))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Price Breakdown ─────────────────────────────────────
                    _buildSection(
                      title: 'Price Breakdown',
                      icon: Iconsax.money,
                      child: Column(
                        children: [
                          _buildPriceRow(
                            'Subtotal',
                            '₹${order.orderTotal?.subtotal.toInt() ?? order.totalPrice.toInt()}',
                          ),
                          if (order.shippingCharge != null &&
                              order.shippingCharge! > 0)
                            _buildPriceRow(
                              'Shipping',
                              '₹${order.shippingCharge!.toInt()}',
                            ),
                          if (order.orderTotal != null &&
                              order.orderTotal!.discount > 0)
                            _buildPriceRow(
                              'Discount',
                              '-₹${order.orderTotal!.discount.toInt()}',
                              valueColor: const Color(0xFF10B981),
                            ),
                          const Divider(height: 20),
                          _buildPriceRow(
                            'Total',
                            '₹${order.totalPrice.toInt()}',
                            isBold: true,
                          ),
                          _buildPriceRow(
                            'Payment',
                            order.paymentMethod?.toUpperCase() ?? '—',
                            valueColor: order.paymentStatus?.toLowerCase() ==
                                    'paid'
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Delivery Address ─────────────────────────────────────
                    if (order.shippingAddress != null)
                      _buildSection(
                        title: 'Delivery Address',
                        icon: Iconsax.location,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.shippingAddress!.street,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${order.shippingAddress!.city}, ${order.shippingAddress!.state} - ${order.shippingAddress!.postalCode}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined,
                                    size: 14, color: AppTheme.primaryColor),
                                const SizedBox(width: 6),
                                Text(
                                  order.shippingAddress!.phone,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(10),
              image: item.productImage.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(item.productImage),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: item.productImage.isEmpty
                ? const Icon(Icons.inventory_2_outlined,
                    color: AppTheme.textHint, size: 22)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (item.variant != null)
                  Text(
                    item.variant!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${item.price.toInt()}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Qty: ${item.quantity}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isBold ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 16 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'processing':
        return const Color(0xFF3B82F6);
      case 'shipped':
        return const Color(0xFF6366F1);
      case 'delivered':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
