import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/supplier_provider.dart';
import '../models/user.dart';

class SupplierProfileScreen extends StatefulWidget {
  const SupplierProfileScreen({super.key});

  @override
  State<SupplierProfileScreen> createState() => _SupplierProfileScreenState();
}

class _SupplierProfileScreenState extends State<SupplierProfileScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final profile = user?.supplierProfile;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
                // ── Profile Hero ──
                _buildProfileHero(context, user, profile, topPad),

                const SizedBox(height: 16),

                // ── Store info ──
                if (profile != null)
                  _buildSection(
                    title: 'Store Information',
                    icon: Iconsax.shop,
                    children: [
                      _buildInfoTile(
                        icon: Iconsax.shop,
                        label: 'Store Name',
                        value: profile.storeName ?? '—',
                      ),
                      if (profile.gstin != null && profile.gstin!.isNotEmpty)
                        _buildInfoTile(
                          icon: Iconsax.document_text,
                          label: 'GSTIN',
                          value: profile.gstin!,
                        )
                      else if (profile.udyam != null && profile.udyam!.isNotEmpty)
                        _buildInfoTile(
                          icon: Iconsax.document_text,
                          label: 'Udyam Number',
                          value: profile.udyam!,
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

                // ── Pickup Address ──
                if (profile?.pickupAddress != null)
                  _buildSection(
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

                // ── Account Info ──
                _buildSection(
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

                // ── Bank Details ──
                if (profile?.bankDetails != null)
                  _buildSection(
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

                // ── Logout ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmLogout(context),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 48),
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
              ],
            ),
          ),
        );
      }

  // ── Profile Hero (always visible at top of scroll) ──
  Widget _buildProfileHero(BuildContext context, dynamic user, SupplierProfile? profile, double topPad) {
    final initial = (user?.name ?? 'S').isNotEmpty
        ? user!.name.substring(0, 1).toUpperCase()
        : 'S';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPad + 20,
        left: 20,
        right: 20,
        bottom: 28,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFF6B21A8)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile?.storeName ?? user?.email ?? '',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
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

  // ── Section card ──
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
                  Icon(icon, size: 16, color: AppTheme.primaryAccent),
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

  // ── Info row ──
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
          Icon(icon, size: 18, color: AppTheme.textHint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
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
