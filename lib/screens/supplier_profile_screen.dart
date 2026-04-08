import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/supplier_provider.dart';
import '../models/user.dart';

class SupplierProfileScreen extends StatelessWidget {
  const SupplierProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final supplier = context.watch<SupplierProvider>();
    final user = auth.user;
    final profile = user?.supplierProfile;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: CustomScrollView(
        slivers: [
          // Premium header
          SliverToBoxAdapter(child: _buildHeader(context, user, profile)),

          // Stats row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Products',
                      value: '${supplier.totalProducts}',
                      icon: Iconsax.box,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: 'Orders',
                      value: '${supplier.totalOrders}',
                      icon: Iconsax.shopping_bag,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: 'Revenue',
                      value: '₹${supplier.totalRevenue}',
                      icon: Iconsax.money,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Store info section
          if (profile != null)
            SliverToBoxAdapter(
              child: _buildSection(
                title: 'Store Information',
                icon: Iconsax.shop,
                children: [
                  _buildInfoTile(
                    icon: Iconsax.shop,
                    label: 'Store Name',
                    value: profile.storeName ?? '—',
                  ),
                  if (profile.gstin != null)
                    _buildInfoTile(
                      icon: Iconsax.document_text,
                      label: 'GSTIN',
                      value: profile.gstin!,
                    ),
                  _buildInfoTile(
                    icon: Iconsax.tick_circle,
                    label: 'Status',
                    value: profile.isApproved ? 'Approved ✓' : 'Pending Review',
                    valueColor:
                        profile.isApproved ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  ),
                  if (profile.supplierSince != null)
                    _buildInfoTile(
                      icon: Iconsax.calendar,
                      label: 'Supplier Since',
                      value: _formatDate(profile.supplierSince!),
                    ),
                ],
              ),
            ),

          // Pickup Address
          if (profile?.pickupAddress != null)
            SliverToBoxAdapter(
              child: _buildSection(
                title: 'Pickup Address',
                icon: Iconsax.location,
                children: [
                  _buildInfoTile(
                    icon: Iconsax.home,
                    label: 'Street',
                    value: profile!.pickupAddress!.address,
                  ),
                  _buildInfoTile(
                    icon: Iconsax.building,
                    label: 'City',
                    value: profile.pickupAddress!.city,
                  ),
                  _buildInfoTile(
                    icon: Iconsax.map,
                    label: 'State',
                    value: profile.pickupAddress!.state,
                  ),
                  _buildInfoTile(
                    icon: Iconsax.location_tick,
                    label: 'Pincode',
                    value: profile.pickupAddress!.pincode,
                  ),
                ],
              ),
            ),

          // Account Info
          SliverToBoxAdapter(
            child: _buildSection(
              title: 'Account Information',
              icon: Iconsax.user,
              children: [
                _buildInfoTile(
                  icon: Iconsax.user_square,
                  label: 'Name',
                  value: user?.name ?? '—',
                ),
                _buildInfoTile(
                  icon: Iconsax.sms,
                  label: 'Email',
                  value: user?.email ?? '—',
                ),
                _buildInfoTile(
                  icon: Iconsax.call,
                  label: 'Phone',
                  value: user?.phone ?? '—',
                ),
              ],
            ),
          ),

          // Bank Details
          if (profile?.bankDetails != null)
            SliverToBoxAdapter(
              child: _buildSection(
                title: 'Bank Details',
                icon: Iconsax.bank,
                children: [
                  _buildInfoTile(
                    icon: Iconsax.user,
                    label: 'Account Name',
                    value: profile!.bankDetails!.accountName,
                  ),
                  _buildInfoTile(
                    icon: Iconsax.card,
                    label: 'Account Number',
                    value: profile.bankDetails!.accountNumber,
                    obscure: true,
                  ),
                  _buildInfoTile(
                    icon: Iconsax.document,
                    label: 'IFSC Code',
                    value: profile.bankDetails!.ifscCode,
                  ),
                  _buildInfoTile(
                    icon: Iconsax.bank,
                    label: 'Bank Name',
                    value: profile.bankDetails!.bankName,
                  ),
                ],
              ),
            ),

          // Logout
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              child: ElevatedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Iconsax.logout, size: 18),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, user, SupplierProfile? profile) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 32,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1E2E), Color(0xFF0A0A0B)],
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                (user?.name ?? 'S').isNotEmpty
                    ? user!.name.substring(0, 1).toUpperCase()
                    : 'S',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user?.name ?? 'Supplier',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile?.storeName ?? user?.email ?? '',
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          if (profile?.isApproved == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.4),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: Color(0xFF10B981), size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Verified Supplier',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade100),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool obscure = false,
  }) {
    final displayValue = obscure && value.length > 4
        ? '${'•' * (value.length - 4)}${value.substring(value.length - 4)}'
        : value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              context.read<SupplierProvider>().clearData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
