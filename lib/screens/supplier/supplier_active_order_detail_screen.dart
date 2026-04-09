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
    final success = await context.read<SupplierProvider>().markOrderPickedUp(_order.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order picked up!'), backgroundColor: Color(0xFF8B5CF6)),
      );
      Navigator.pop(context); // Go back after pick up? Or stay to see history
    }
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

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackground,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          children: [
            Text('Order #$orderIdStr', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _statusColor(_order.orderStatus).withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(color: _statusColor(_order.orderStatus).withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 0),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    isPreparing ? Iconsax.timer_1 : isReady ? Iconsax.box_tick : Iconsax.truck_fast,
                    size: 40,
                    color: _statusColor(_order.orderStatus),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _order.orderStatus.toUpperCase(),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _statusColor(_order.orderStatus), letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPreparing ? 'Prepare the items carefully.' : isReady ? 'Waiting for delivery partner' : 'Order picked up successfully',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Items List
            const Text('ORDER ITEMS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF27272A)),
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
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${item.quantity}x', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName ?? 'Product', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                              if (item.variant != null && item.variant!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('Variant: ${item.variant}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ),
                            ],
                          ),
                        ),
                        Text('₹${(item.price * item.quantity).toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Customer Details
            if (_order.customerName != null) ...[
              const Text('CUSTOMER', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF27272A)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF27272A),
                      child: Icon(Iconsax.user, color: Colors.white70),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_order.customerName!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                          if (_order.customerPhone != null)
                            Text(_order.customerPhone!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                    if (_order.customerPhone != null)
                      IconButton(
                        icon: const Icon(Icons.call, color: Color(0xFF60A5FA)),
                        onPressed: () => _makeCall(_order.customerPhone!),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Delivery Partner Details
            if (_order.assignedDriver != null) ...[
              const Text('DELIVERY PARTNER', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF052E16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF16A34A)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF166534),
                      child: Icon(Iconsax.truck, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_order.assignedDriver?['name'] ?? 'Partner', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                          Text(_order.assignedDriver?['phone'] ?? 'Driving to store', style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 12)),
                        ],
                      ),
                    ),
                    if (_order.assignedDriver?['phone'] != null)
                      IconButton(
                        icon: const Icon(Icons.call, color: Color(0xFF4ADE80)),
                        onPressed: () => _makeCall(_order.assignedDriver!['phone']),
                      ),
                  ],
                ),
              ),
            ] else if (isReady) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF60A5FA)),
                    ),
                    SizedBox(width: 16),
                    Text('Assigning delivery partner...', style: TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.w600)),
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
          decoration: const BoxDecoration(
            color: Color(0xFF18181B),
            border: Border(top: BorderSide(color: Color(0xFF27272A))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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
            ],
          ),
        ),
      ),
    );
  }
}
