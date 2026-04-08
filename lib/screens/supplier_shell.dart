import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/supplier_provider.dart';
import '../models/order.dart';
import 'supplier_dashboard_embedded.dart';
import 'supplier_new_orders_screen.dart';
import 'supplier_profile_screen.dart';

class SupplierShell extends StatefulWidget {
  const SupplierShell({super.key});

  @override
  State<SupplierShell> createState() => _SupplierShellState();
}

class _SupplierShellState extends State<SupplierShell>
    with TickerProviderStateMixin {
  int _currentIndex = 0;


  // Polling state
  Timer? _pollingTimer;
  String? _lastKnownOrderId;
  bool _isFirstPoll = true;

  // New order popup animation
  late AnimationController _popupController;

  late Animation<double> _popupFade;

  Order? _incomingOrder;
  OverlayEntry? _popupEntry;

  final List<Widget> _pages = const [
    _DashboardTab(),
    _OrdersTab(),
    _ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();

    _popupController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _popupFade = CurvedAnimation(parent: _popupController, curve: Curves.easeIn);

    // Connect socket for real-time new order notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;
      if (userId != null) {
        context.read<SupplierProvider>().connectSocket(userId);
      }
    });

    // Start polling for new orders as fallback
    _startPolling();
  }

  void _startPolling() {
    // Poll every 15 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkForNewOrders();
    });
    // Initial check after 3 seconds (let provider settle)
    Future.delayed(const Duration(seconds: 3), _checkForNewOrders);
  }

  Future<void> _checkForNewOrders() async {
    if (!mounted) return;
    try {
      final provider = context.read<SupplierProvider>();
      await provider.fetchOrders();
      if (!mounted) return;

      final orders = provider.orders;
      if (orders.isEmpty) return;

      final latestOrder = orders.first;

      if (_isFirstPoll) {
        _isFirstPoll = false;
        _lastKnownOrderId = latestOrder.id;
        return;
      }



      // Show popup if genuinely new order arrived
      if (latestOrder.id != _lastKnownOrderId) {
        _lastKnownOrderId = latestOrder.id;
        _showNewOrderPopup(latestOrder);
        HapticFeedback.heavyImpact();
      }
    } catch (_) {}
  }

  void _showNewOrderPopup(Order order) {
    if (_popupEntry != null) return;
    
    _incomingOrder = order;

    _popupEntry = OverlayEntry(
      builder: (ctx) {
        return AnimatedBuilder(
          animation: _popupController,
          builder: (context, _) {
            return Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _popupFade,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _popupController,
                    curve: Curves.easeOutBack,
                  )),
                  child: _NewOrderPopupCard(
                    order: _incomingOrder!,
                    onDismiss: _dismissPopup,
                    onViewOrder: () {
                      _dismissPopup();
                      // Close any pushed screens to return to the shell
                      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
                      setState(() => _currentIndex = 1);
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_popupEntry!);
    _popupController.forward();

    // Auto dismiss after 12 seconds
    Future.delayed(const Duration(seconds: 12), () {
      if (mounted && _popupEntry != null) _dismissPopup();
    });
  }

  void _dismissPopup() {
    if (_popupEntry == null) return;
    _popupController.reverse().then((_) {
      if (mounted) {
        _popupEntry?.remove();
        _popupEntry = null;
        _incomingOrder = null;
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _popupController.dispose();
    if (_popupEntry != null && _popupEntry!.mounted) {
      _popupEntry!.remove();
    }
    // Disconnect socket on dispose
    context.read<SupplierProvider>().disconnectSocket();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(top: BorderSide(color: Color(0xFF27272A), width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Iconsax.home_2,
                activeIcon: Iconsax.home_2_copy,
                label: 'Dashboard',
              ),
              _buildNavItem(
                index: 1,
                icon: Iconsax.box,
                activeIcon: Iconsax.box_copy,
                label: 'Orders',
                badge: context.watch<SupplierProvider>().newOrders.length,
              ),
              _buildNavItem(
                index: 2,
                icon: Iconsax.user,
                activeIcon: Iconsax.user_copy,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int badge = 0,
  }) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _currentIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? AppTheme.primaryAccent : AppTheme.textSecondary,
                  size: 24,
                ),
                if (badge > 0)
                  Positioned(
                    top: -5,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor, // Zepto style urgent red badge
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.cardBackground, width: 2),
                      ),
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? AppTheme.primaryAccent : AppTheme.textSecondary,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

}

// ── Wrapper Tabs (to avoid rebuilding) ─────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();
  @override
  Widget build(BuildContext context) => const SupplierDashboardScreenEmbedded();
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();
  @override
  Widget build(BuildContext context) => const SupplierNewOrdersScreen();
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) => const SupplierProfileScreen();
}

// ── New Order Popup Card ───────────────────────────────────────────────────

class _NewOrderPopupCard extends StatelessWidget {
  final Order order;
  final VoidCallback onDismiss;
  final VoidCallback onViewOrder;

  const _NewOrderPopupCard({
    required this.order,
    required this.onDismiss,
    required this.onViewOrder,
  });

  @override
  Widget build(BuildContext context) {
    final orderId = order.id.length >= 8
        ? order.id.substring(order.id.length - 8).toUpperCase()
        : order.id.toUpperCase();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Material(
          elevation: 16,
          borderRadius: BorderRadius.circular(20),
          shadowColor: Colors.black.withOpacity(0.3),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E1E2E), Color(0xFF12122A)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Alert banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, color: Colors.white, size: 9),
                      const SizedBox(width: 8),
                      const Text(
                        '🛍️  New Order Received!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onDismiss,
                        child: const Icon(Icons.close, color: Colors.white70, size: 18),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order ID row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ORDER #$orderId',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              order.paymentMethod?.toUpperCase() ?? 'PAID',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Items list (up to 3)
                      ...order.items.take(3).map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(8),
                                image: item.productImage.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(item.productImage),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: item.productImage.isEmpty
                                  ? const Icon(Icons.inventory_2_outlined,
                                      color: Colors.white38, size: 18)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.productName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'x${item.quantity}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₹${item.price.toInt()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )),

                      if (order.items.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '+${order.items.length - 3} more items',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ),

                      Divider(color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 4),

                      // Total row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '₹${order.totalPrice.toInt()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      if (order.shippingAddress != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                color: Colors.white38, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${order.shippingAddress!.street}, ${order.shippingAddress!.city}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onDismiss,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Dismiss', style: TextStyle(fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: onViewOrder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.visibility_outlined, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'View Order',
                                    style: TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
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
        ),
      ),
    );
  }
}
