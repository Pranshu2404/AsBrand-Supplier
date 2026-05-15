import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../providers/supplier_provider.dart';
import '../../models/order.dart';

class SupplierActiveOrderDetailScreen extends StatefulWidget {
  final Order order;
  const SupplierActiveOrderDetailScreen({super.key, required this.order});

  @override
  State<SupplierActiveOrderDetailScreen> createState() =>
      _SupplierActiveOrderDetailScreenState();
}

class _SupplierActiveOrderDetailScreenState
    extends State<SupplierActiveOrderDetailScreen> {
  late Order _order;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Poll to keep driver and status updated
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!mounted) return;
      await context.read<SupplierProvider>().fetchOrders();
      if (!mounted) return;
      
      final updatedOrders = context.read<SupplierProvider>().orders;
      final match = updatedOrders.indexWhere((o) => o.id == _order.id);
      if (match != -1) {
        setState(() {
          _order = updatedOrders[match];
        });
      }
    });
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
        return const Color(0xFF8B5CF6);
      case 'picked_up':
      case 'shipped':
        return const Color(0xFF10B981);
      case 'delivered':
        return const Color(0xFF22C55E);
      case 'cancelled':
      case 'failed':
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _markReady() async {
    final success = await context.read<SupplierProvider>().markOrderReady(_order.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order marked ready!'), backgroundColor: Color(0xFF3B82F6)),
      );
      // Let polling update it, or we can manually refresh
      context.read<SupplierProvider>().fetchOrders();
    }
  }

  Future<void> _markPickedUp() async {
    // Check if delivery partner is assigned
    if (_order.assignedDriver == null) {
      _showWarningDialog(
        'Delivery Partner Not Assigned',
        'A delivery partner has not been assigned to this order yet. Please wait for a driver to be assigned before marking as picked up.',
        Iconsax.close_circle,
      );
      return;
    }

    // Check if delivery partner has reached pickup location
    final deliveryStatus = _order.deliveryStatus?.toUpperCase() ?? '';
    if (deliveryStatus != 'REACHED_PICKUP') {
      _showWarningDialog(
        'Driver Has Not Arrived',
        'The delivery partner has not reached the pickup location yet. Please wait for the driver to arrive before handing over the order.',
        Iconsax.location,
      );
      return;
    }

    final success = await context.read<SupplierProvider>().markOrderPickedUp(_order.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order picked up!'), backgroundColor: Color(0xFF8B5CF6)),
      );
      Navigator.pop(context);
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
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
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

  @override
  Widget build(BuildContext context) {
    final orderIdStr = _order.id.length >= 8
        ? _order.id.substring(_order.id.length - 8).toUpperCase()
        : _order.id.toUpperCase();
    final timeStr = DateFormat('h:mm a').format(_order.orderDate);
    final total = _order.orderTotal?.total ?? _order.totalPrice;
    final isPreparing = _order.orderStatus == 'preparing';
    final isReady = _order.orderStatus == 'ready';
    final isPickedUp = _order.orderStatus == 'picked_up' || _order.orderStatus == 'shipped';
    final isDelivered = _order.orderStatus == 'delivered';
    final isRejected = _order.orderStatus == 'rejected' || _order.orderStatus == 'cancelled';

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Column(
          children: [
            Text('Order #$orderIdStr', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            Text(timeStr, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Hero
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _statusColor(_order.orderStatus).withValues(alpha: 0.3), width: 1.5),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  Icon(
                    isPreparing ? Iconsax.timer_1
                      : isReady ? Iconsax.box_tick
                      : isPickedUp ? Iconsax.truck_fast
                      : isDelivered ? Iconsax.tick_circle
                      : isRejected ? Iconsax.close_circle
                      : Iconsax.box,
                    size: 40,
                    color: _statusColor(_order.orderStatus),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isPickedUp ? 'IN TRANSIT' : _order.orderStatus.toUpperCase(),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _statusColor(_order.orderStatus), letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPreparing ? 'Prepare the items carefully.'
                      : isReady ? 'Waiting for delivery partner'
                      : isPickedUp ? 'Driver is on the way to customer'
                      : isDelivered ? 'Order delivered successfully!'
                      : isRejected ? 'This order was rejected or cancelled'
                      : 'Order picked up successfully',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  // Show delivery status for in-transit orders
                  if (isPickedUp && _order.deliveryStatus != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFED7AA)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Iconsax.truck_fast, size: 14, color: Color(0xFFEA580C)),
                          const SizedBox(width: 6),
                          Text(
                            _getDeliveryStatusText(_order.deliveryStatus),
                            style: const TextStyle(color: Color(0xFFEA580C), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Items List
            const Text('ORDER ITEMS', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: _order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${item.quantity}x', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName ?? 'Product', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                              if (item.variant != null && item.variant!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('Variant: ${item.variant}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                ),
                            ],
                          ),
                        ),
                        Text('₹${(item.price * item.quantity).toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Customer Details
            if (_order.customerName != null) ...[
              const Text('CUSTOMER', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.surfaceColor,
                      child: Icon(Iconsax.user, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_order.customerName!, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                          if (_order.customerPhone != null)
                            Text(_order.customerPhone!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    if (_order.customerPhone != null)
                      IconButton(
                        icon: const Icon(Icons.call, color: Color(0xFF3B82F6)),
                        onPressed: () => _makeCall(_order.customerPhone!),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Delivery Partner Details
            if (_order.assignedDriver != null) ...[
              const Text('DELIVERY PARTNER', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFDCFCE7),
                      child: Icon(Iconsax.truck, color: Color(0xFF22C55E)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_order.assignedDriver?['name'] ?? 'Partner', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                          Text(_order.assignedDriver?['phone'] ?? 'Driving to store', style: const TextStyle(color: Color(0xFF22C55E), fontSize: 12)),
                        ],
                      ),
                    ),
                    if (_order.assignedDriver?['phone'] != null)
                      IconButton(
                        icon: const Icon(Icons.call, color: Color(0xFF22C55E)),
                        onPressed: () => _makeCall(_order.assignedDriver!['phone']),
                      ),
                  ],
                ),
              ),
            ] else if (isReady) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)),
                    ),
                    SizedBox(width: 16),
                    Text('Assigning delivery partner...', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: AppTheme.borderColor)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              if (isPreparing)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _markReady,
                    child: const Text('MARK ORDER READY', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.white)),
                  ),
                ),
              if (isReady)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _markPickedUp,
                    child: const Text('MARK PICKED UP', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.white)),
                  ),
                ),
              if (isPickedUp)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: const Center(
                    child: Text(
                      'Order is in transit to customer',
                      style: TextStyle(color: Color(0xFFEA580C), fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              if (isDelivered)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Center(
                    child: Text(
                      '✓ Order delivered successfully',
                      style: TextStyle(color: Color(0xFF22C55E), fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              if (isRejected)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: const Center(
                    child: Text(
                      'Order was rejected / cancelled',
                      style: TextStyle(color: Color(0xFFEF4444), fontSize: 14, fontWeight: FontWeight.w700),
                    ),
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
      case 'DELIVERED':
        return 'Order has been delivered';
      default:
        return 'En route to customer';
    }
  }
}
