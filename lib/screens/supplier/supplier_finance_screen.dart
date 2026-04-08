import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/supplier_provider.dart';

class SupplierFinanceScreen extends StatefulWidget {
  const SupplierFinanceScreen({super.key});

  @override
  State<SupplierFinanceScreen> createState() => _SupplierFinanceScreenState();
}

class _SupplierFinanceScreenState extends State<SupplierFinanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().fetchFinanceDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupplierProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Payouts & Finance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: AppTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: () async => await provider.fetchFinanceDetails(),
              color: AppTheme.primaryColor,
              child: provider.error != null
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.7,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Failed to load finance data', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildEarningsSummary(provider.financeData),
                          const SizedBox(height: 24),
                          _buildRecentTransactions(provider.financeData),
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _buildEarningsSummary(Map<String, dynamic>? data) {
    final totalEarnings = data?['totalEarnings'] ?? 0;
    final pendingPayouts = data?['pendingPayouts'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Earnings', style: TextStyle(color: Colors.grey.shade300, fontSize: 14)),
              const Icon(Iconsax.wallet_2, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${totalEarnings.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pending Payouts', style: TextStyle(color: Colors.grey.shade300, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('₹${pendingPayouts.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Settled', style: TextStyle(color: Colors.grey.shade300, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('₹${(totalEarnings - pendingPayouts).toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(Map<String, dynamic>? data) {
    if (data == null || data['recentTransactions'] == null) {
      return const SizedBox.shrink();
    }

    final transactions = data['recentTransactions'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 16),
        if (transactions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text('No transactions yet', style: TextStyle(color: Colors.grey.shade500)),
            ),
          )
        else
          ...transactions.map((t) {
            final date = DateTime.parse(t['date']);
            final amount = t['amount'];
            final orderId = t['orderId'];
            final shortId = orderId.length > 8 ? orderId.substring(orderId.length - 8).toUpperCase() : orderId;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.call_received, color: Colors.green.shade600, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order #$shortId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(DateFormat('dd MMM yyyy, hh:mm a').format(date), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('+₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                      const SizedBox(height: 4),
                      Text('Completed', style: TextStyle(color: Colors.green.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  )
                ],
              ),
            );
          }).toList(),
      ],
    );
  }
}
