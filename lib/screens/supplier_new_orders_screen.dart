import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/supplier_provider.dart';
import '../models/order.dart';
import 'supplier/supplier_active_order_detail_screen.dart';

// ─────────────────────────────────────────────────────────────
// Supplier Orders Screen — Light Theme
// Tabs: Preparing | Ready | Picked up
// New order popup with countdown timer
// ─────────────────────────────────────────────────────────────

class SupplierNewOrdersScreen extends StatefulWidget {
  const SupplierNewOrdersScreen({super.key});

  @override
  State<SupplierNewOrdersScreen> createState() =>
      _SupplierNewOrdersScreenState();
}

class _SupplierNewOrdersScreenState
    extends State<SupplierNewOrdersScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription? _newOrderSub;
  Order? _incomingOrder;
  Timer? _countdownTimer;
  int _acceptCountdown = 300; // 5 minutes in seconds

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().fetchOrders();
      _listenForNewOrders();
    });
  }

  void _listenForNewOrders() {
    final provider = context.read<SupplierProvider>();
    _newOrderSub?.cancel();
    _newOrderSub = provider.pendingNewOrders.isNotEmpty
        ? null
        : null; // Will be triggered via provider listener
  }

  @override
  void dispose() {
    _tabController.dispose();
    _newOrderSub?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _showNewOrderPopup(Order order) {
    if (_incomingOrder != null) return; // Already showing one
    
    final now = DateTime.now();
    // Assuming backend passes UTC timezone properly
    final elapsed = now.difference(order.orderDate).inSeconds;
    int remaining = 300 - elapsed;
    if (remaining < 0) remaining = 0;

    setState(() {
      _incomingOrder = order;
      _acceptCountdown = remaining; 
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_acceptCountdown <= 0) {
        _autoRejectExpiredOrder(order.id); // Auto-reject expired order
        timer.cancel();
      } else {
        setState(() => _acceptCountdown--);
      }
    });

    if (remaining > 0) {
      HapticFeedback.heavyImpact();
    }
  }

  void _dismissPopup() {
    _countdownTimer?.cancel();
    setState(() {
      if (_incomingOrder != null) {
        context.read<SupplierProvider>().dismissNewOrder(_incomingOrder!.id);
      }
      _incomingOrder = null;
    });
  }

  Future<void> _acceptOrder(String orderId) async {
    _dismissPopup();
    final success = await context.read<SupplierProvider>().acceptOrder(orderId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order accepted! Preparing started.'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    }
  }

  Future<void> _rejectOrder(String orderId) async {
    _dismissPopup();
    await context.read<SupplierProvider>().rejectOrder(orderId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order rejected.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _autoRejectExpiredOrder(String orderId) async {
    _dismissPopup();
    await context.read<SupplierProvider>().rejectOrder(orderId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order auto-rejected — timer expired.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _markReady(String orderId) async {
    final success = await context.read<SupplierProvider>().markOrderReady(orderId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order marked ready for pickup!'),
          backgroundColor: Color(0xFF3B82F6),
        ),
      );
    }
  }

  Future<void> _markPickedUp(Order order) async {
    // Check if delivery partner is assigned
    if (order.assignedDriver == null) {
      _showWarningDialog(
        'Delivery Partner Not Assigned',
        'A delivery partner has not been assigned to this order yet. Please wait for a driver to be assigned before marking as picked up.',
        Iconsax.close_circle,
      );
      return;
    }

    // Check if delivery partner has reached pickup location
    final deliveryStatus = order.deliveryStatus?.toUpperCase() ?? '';
    if (deliveryStatus != 'REACHED_PICKUP') {
      _showWarningDialog(
        'Driver Has Not Arrived',
        'The delivery partner has not reached the pickup location yet. Please wait for the driver to arrive before handing over the order.',
        Iconsax.location,
      );
      return;
    }

    final success = await context.read<SupplierProvider>().markOrderPickedUp(order.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order picked up by delivery partner!'),
          backgroundColor: Color(0xFF8B5CF6),
        ),
      );
    }
  }

  void _showWarningDialog(String title, String message, IconData icon) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFF59E0B), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('OK, Got It', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCountdown(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final supplier = context.watch<SupplierProvider>();

    // Check for new pending orders and show popup
    if (supplier.pendingNewOrders.isNotEmpty && _incomingOrder == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNewOrderPopup(supplier.pendingNewOrders.first);
      });
    }

    final preparing = supplier.preparingOrders;
    final ready = supplier.readyOrders;
    final inTransit = supplier.inTransitOrders;
    final rejected = supplier.rejectedOrders;
    final newOrds = supplier.newOrders;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Iconsax.refresh, color: AppTheme.textPrimary, size: 20),
                onPressed: () => supplier.fetchOrders(),
                tooltip: 'Refresh',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppTheme.primaryAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textSecondary,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  labelPadding: EdgeInsets.zero,
                  tabs: [
                    Tab(text: 'Preparing (${preparing.length})'),
                    Tab(text: 'Ready (${ready.length})'),
                    Tab(text: 'In Transit (${inTransit.length})'),
                    Tab(text: 'Rejected (${rejected.length})'),
                  ],
                ),
              ),
            ),
          ),
          body: supplier.isLoading && supplier.orders.isEmpty
              ? Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent))
              : Column(
                  children: [
                    // New orders banner
                    if (newOrds.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          if (newOrds.isNotEmpty) _showNewOrderPopup(newOrds.first);
                        },
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B2B), Color(0xFFFF3F6C)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Iconsax.notification, color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                '${newOrds.length} new order${newOrds.length > 1 ? 's' : ''} waiting',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              const Spacer(),
                              const Text('TAP TO VIEW', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOrderList(preparing, 'preparing'),
                          _buildOrderList(ready, 'ready'),
                          _buildOrderList(inTransit, 'in_transit'),
                          _buildOrderList(rejected, 'rejected'),
                        ],
                      ),
                    ),
                  ],
                ),
        ),

        // ── New order overlay popup ──
        if (_incomingOrder != null)
          _buildNewOrderPopup(_incomingOrder!),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ORDER LIST
  // ─────────────────────────────────────────────────────────────

  Widget _buildOrderList(List<Order> orders, String tab) {
    if (orders.isEmpty) {
      IconData emptyIcon;
      String emptyText;
      switch (tab) {
        case 'preparing':
          emptyIcon = Iconsax.timer;
          emptyText = 'No orders being prepared';
          break;
        case 'ready':
          emptyIcon = Iconsax.box_tick;
          emptyText = 'No orders ready for pickup';
          break;
        case 'in_transit':
          emptyIcon = Iconsax.truck_fast;
          emptyText = 'No orders in transit';
          break;
        case 'rejected':
          emptyIcon = Iconsax.close_circle;
          emptyText = 'No rejected orders';
          break;
        default:
          emptyIcon = Iconsax.box;
          emptyText = 'No orders';
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, size: 56, color: AppTheme.textHint),
            const SizedBox(height: 16),
            Text(emptyText, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryAccent,
      onRefresh: () => context.read<SupplierProvider>().fetchOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(orders[index], tab);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ORDER CARD (per tab)
  // ─────────────────────────────────────────────────────────────

  Widget _buildOrderCard(Order order, String tab) {
    final orderId = order.id.length >= 8 ? order.id.substring(order.id.length - 8).toUpperCase() : order.id.toUpperCase();
    final timeStr = DateFormat('h:mm a').format(order.orderDate);
    final total = order.orderTotal?.total ?? order.totalPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: AppTheme.softShadow,
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SupplierActiveOrderDetailScreen(order: order),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(order.orderStatus).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.orderStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _statusColor(order.orderStatus),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('ID: $orderId', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                const Spacer(),
                Text(timeStr, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),

          // Customer info
          if (order.customerName != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  const Icon(Iconsax.user, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    order.customerName!,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  if (order.customerPhone != null) ...[
                    const SizedBox(width: 12),
                    const Icon(Iconsax.call, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(order.customerPhone!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ],
              ),
            ),

          // Items
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(child: Icon(Icons.circle, size: 8, color: Color(0xFF22C55E))),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item.quantity} x ${item.productName}',
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Divider
          const Divider(color: AppTheme.borderColor, height: 1),

          // Total + payment
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Text('Total Bill', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    (order.paymentMethod ?? 'prepaid').toUpperCase(),
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF22C55E)),
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
          ),

          // Driver assignment info (Ready tab)
          if (tab == 'ready' && order.assignedDriver == null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Iconsax.truck_fast, size: 16, color: Color(0xFF3B82F6)),
                  SizedBox(width: 8),
                  Text(
                    'Assigning delivery partner...',
                    style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

          if (tab == 'ready' && order.assignedDriver != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(Iconsax.tick_circle, size: 16, color: Color(0xFF22C55E)),
                  SizedBox(width: 8),
                  Text(
                    'Delivery partner assigned',
                    style: TextStyle(color: Color(0xFF22C55E), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

          // In-transit delivery status info
          if (tab == 'in_transit') ...[
            if (order.pickedUpAt != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.truck_tick, size: 16, color: Color(0xFF8B5CF6)),
                    const SizedBox(width: 8),
                    Text(
                      'Picked up at ${DateFormat('h:mm a').format(order.pickedUpAt!)}',
                      style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.truck_fast, size: 16, color: Color(0xFFEA580C)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getDeliveryStatusText(order.deliveryStatus),
                      style: const TextStyle(color: Color(0xFFEA580C), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Rejected info
          if (tab == 'rejected')
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                children: [
                  Icon(Iconsax.close_circle, size: 16, color: Color(0xFFEF4444)),
                  SizedBox(width: 8),
                  Text(
                    'Order was rejected or expired',
                    style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

          // Action buttons
          if (tab == 'preparing')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => _markReady(order.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Order Ready', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ),

          if (tab == 'ready')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => _markPickedUp(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Picked Up', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // NEW ORDER POPUP (overlay)
  // ─────────────────────────────────────────────────────────────

  Widget _buildNewOrderPopup(Order order) {
    final orderId = order.id.length >= 8 ? order.id.substring(order.id.length - 8).toUpperCase() : order.id.toUpperCase();
    final timeStr = DateFormat('h:mm a').format(order.orderDate);
    final total = order.orderTotal?.total ?? order.totalPrice;

    return Container(
      color: Colors.black38,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 40, spreadRadius: 4),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header — "NEW ORDER" banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFFF6B2B), Color(0xFFFF3F6C)]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.notification, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text('NEW ORDER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1)),
                    const Spacer(),
                    GestureDetector(
                      onTap: _dismissPopup,
                      child: const Icon(Icons.close, color: Colors.white70, size: 22),
                    ),
                  ],
                ),
              ),

              // Order meta
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    Text('ID: $orderId', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(width: 8),
                    Text('| $timeStr', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    const Spacer(),
                    if (order.customerName != null)
                      Text(order.customerName!, style: const TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),

              // Customer phone
              if (order.customerPhone != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Row(
                    children: [
                      const Icon(Iconsax.call, size: 13, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(order.customerPhone!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),

              const SizedBox(height: 12),
              const Divider(color: AppTheme.borderColor, height: 1),

              // Items list
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: order.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Center(child: Icon(Icons.circle, size: 8, color: Color(0xFF22C55E))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.quantity} x ${item.productName}',
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                if (item.variant != null && item.variant!.isNotEmpty)
                                  Text(item.variant!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                              ],
                            ),
                          ),
                          Text(
                            '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Divider(color: AppTheme.borderColor, height: 1),

              // Total
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Text('Total Bill', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (order.paymentMethod ?? 'PAID').toUpperCase(),
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF22C55E)),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₹${total.toStringAsFixed(0)}',
                      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Accept / Reject buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    // Reject
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => _rejectOrder(order.id),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Reject', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Accept with countdown
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => _acceptOrder(order.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(
                            'Accept (${_formatCountdown(_acceptCountdown)})',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDeliveryStatusText(String? deliveryStatus) {
    switch (deliveryStatus?.toUpperCase()) {
      case 'PICKED_UP':
        return 'Driver picked up — heading to customer';
      case 'OUT_FOR_DELIVERY':
        return 'Out for delivery — arriving soon';
      case 'IN_TRANSIT':
        return 'In transit to customer';
      default:
        return 'En route to customer';
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'processing':
        return const Color(0xFFF59E0B);
      case 'accepted':
      case 'preparing':
        return const Color(0xFF3B82F6);
      case 'ready':
        return const Color(0xFF22C55E);
      case 'picked_up':
      case 'shipped':
        return const Color(0xFF8B5CF6);
      case 'delivered':
        return const Color(0xFF10B981);
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return AppTheme.textSecondary;
    }
  }
}
