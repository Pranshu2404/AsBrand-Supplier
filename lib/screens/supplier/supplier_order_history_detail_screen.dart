import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';

class SupplierOrderHistoryDetailScreen extends StatelessWidget {
  final Order order;

  const SupplierOrderHistoryDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final orderId = order.id.length > 8 ? order.id.substring(order.id.length - 8).toUpperCase() : order.id.toUpperCase();
    final isDelivered = order.orderStatus.toLowerCase() == 'delivered';
    final isCancelled = ['cancelled', 'rejected'].contains(order.orderStatus.toLowerCase());
    
    final authProvider = context.read<AuthProvider>();
    final supplierItems = order.items.where((i) => i.supplierId == authProvider.user?.id).toList();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text('Order #$orderId', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status Header
            Container(
              width: double.infinity,
              color: isDelivered ? const Color(0xFF10B981) : (isCancelled ? Colors.red.shade500 : Colors.orange),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDelivered ? 'Order Delivered Successfully' : (isCancelled ? 'Order Cancelled' : 'Order Processing'),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(order.orderDate),
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline tracking
                  if (!isCancelled) _buildTimeline(order),
                  
                  const SizedBox(height: 24),
                  
                  // Item Breakdown
                  _buildSectionTitle('Items ordered'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: supplierItems.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                alignment: Alignment.center,
                                child: Text('${item.quantity}x', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    if (item.variant != null && item.variant!.isNotEmpty)
                                      Text(item.variant!, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Text('₹${(item.price * item.quantity).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Customer Details
                  _buildSectionTitle('Customer Details'),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(order.customerName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(order.shippingAddress?.phone ?? 'Unknown', style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${order.shippingAddress?.street ?? ''}, ${order.shippingAddress?.city ?? ''}, ${order.shippingAddress?.state ?? ''} ${order.shippingAddress?.postalCode ?? ''}'.trim(),
                                style: const TextStyle(fontSize: 13, height: 1.4),
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
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildTimeline(Order order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTimelineItem(
            title: 'Order Placed',
            time: order.orderDate,
            isCompleted: true,
            isFirst: true,
          ),
          _buildTimelineItem(
            title: 'Order Accepted',
            time: order.supplierAcceptedAt ?? order.orderDate,
            isCompleted: order.supplierAcceptedAt != null,
          ),
          _buildTimelineItem(
            title: 'Food Ready',
            time: order.readyAt,
            isCompleted: order.readyAt != null,
          ),
          _buildTimelineItem(
            title: 'Picked Up',
            time: order.pickedUpAt,
            isCompleted: order.pickedUpAt != null,
          ),
          _buildTimelineItem(
            title: 'Delivered',
            time: order.orderStatus.toLowerCase() == 'delivered' ? DateTime.now() : null, // Backend doesn't give us deliveredAt but we know status
            isCompleted: order.orderStatus.toLowerCase() == 'delivered',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({required String title, DateTime? time, required bool isCompleted, bool isFirst = false, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 16,
                    color: isCompleted ? const Color(0xFF10B981) : Colors.grey.shade300,
                  ),
                Container(
                  width: 12,
                  height: 12,
                  margin: EdgeInsets.only(top: isFirst ? 4 : 0, bottom: isLast ? 4 : 0),
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0xFF10B981) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted ? const Color(0xFF10B981) : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted ? const Color(0xFF10B981) : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted ? AppTheme.textPrimary : Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('hh:mm a').format(time),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
