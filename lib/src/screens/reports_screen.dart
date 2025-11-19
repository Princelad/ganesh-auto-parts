import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'low_stock_report_screen.dart';
import 'customer_balance_report_screen.dart';
import 'sales_summary_report_screen.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Access various business reports and analytics to track your business performance.',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Inventory Reports Section
          _buildSectionHeader(context, 'Inventory Reports', Icons.inventory_2),
          const SizedBox(height: 12),
          _buildReportCard(
            context,
            icon: Icons.warning_amber,
            title: 'Low Stock Report',
            subtitle: 'Items below reorder level',
            color: Colors.red,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LowStockReportScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            context,
            icon: Icons.list_alt,
            title: 'Stock Valuation',
            subtitle: 'Current inventory value',
            color: Colors.blue,
            onTap: () => _showComingSoon(context),
          ),
          const SizedBox(height: 24),
          // Customer Reports Section
          _buildSectionHeader(context, 'Customer Reports', Icons.people),
          const SizedBox(height: 12),
          _buildReportCard(
            context,
            icon: Icons.account_balance_wallet,
            title: 'Outstanding Balances',
            subtitle: 'Customers with pending payments',
            color: Colors.orange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CustomerBalanceReportScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            context,
            icon: Icons.people_outline,
            title: 'Customer List',
            subtitle: 'All customers with details',
            color: Colors.green,
            onTap: () => _showComingSoon(context),
          ),
          const SizedBox(height: 24),
          // Sales Reports Section
          _buildSectionHeader(context, 'Sales Reports', Icons.receipt_long),
          const SizedBox(height: 12),
          _buildReportCard(
            context,
            icon: Icons.trending_up,
            title: 'Sales Summary',
            subtitle: 'Sales overview and trends',
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SalesSummaryReportScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            context,
            icon: Icons.date_range,
            title: 'Sales by Period',
            subtitle: 'Daily, weekly, monthly sales',
            color: Colors.teal,
            onTap: () => _showComingSoon(context),
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            context,
            icon: Icons.star,
            title: 'Top Selling Items',
            subtitle: 'Most popular products',
            color: Colors.amber,
            onTap: () => _showComingSoon(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Coming soon!')));
  }
}
