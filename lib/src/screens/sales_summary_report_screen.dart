import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/invoice_provider.dart';
import '../providers/item_provider.dart';
import '../providers/customer_provider.dart';
import '../utils/currency_helper.dart';

class SalesSummaryReportScreen extends ConsumerWidget {
  const SalesSummaryReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceCountAsync = ref.watch(invoiceCountProvider);
    final itemCountAsync = ref.watch(itemCountProvider);
    final customerCountAsync = ref.watch(customerCountProvider);
    final totalBalanceAsync = ref.watch(totalOutstandingBalanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(invoiceCountProvider);
              ref.invalidate(itemCountProvider);
              ref.invalidate(customerCountProvider);
              ref.invalidate(totalOutstandingBalanceProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(invoiceCountProvider);
          ref.invalidate(itemCountProvider);
          ref.invalidate(customerCountProvider);
          ref.invalidate(totalOutstandingBalanceProvider);
        },
        child: ListView(
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
                        'Overview of your business performance and key metrics.',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Business Overview
            Text(
              'Business Overview',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: invoiceCountAsync.when(
                    data: (count) => _buildMetricCard(
                      context,
                      icon: Icons.receipt_long,
                      label: 'Total Invoices',
                      value: count.toString(),
                      color: Colors.purple,
                    ),
                    loading: () => _buildLoadingCard(context),
                    error: (_, _) => _buildErrorCard(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: customerCountAsync.when(
                    data: (count) => _buildMetricCard(
                      context,
                      icon: Icons.people,
                      label: 'Total Customers',
                      value: count.toString(),
                      color: Colors.green,
                    ),
                    loading: () => _buildLoadingCard(context),
                    error: (_, _) => _buildErrorCard(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: itemCountAsync.when(
                    data: (count) => _buildMetricCard(
                      context,
                      icon: Icons.inventory_2,
                      label: 'Total Items',
                      value: count.toString(),
                      color: Colors.blue,
                    ),
                    loading: () => _buildLoadingCard(context),
                    error: (_, _) => _buildErrorCard(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: totalBalanceAsync.when(
                    data: (balance) => _buildMetricCard(
                      context,
                      icon: Icons.account_balance_wallet,
                      label: 'Outstanding',
                      value: CurrencyHelper.formatCompact(balance),
                      color: Colors.orange,
                    ),
                    loading: () => _buildLoadingCard(context),
                    error: (_, _) => _buildErrorCard(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Additional Info
            Text(
              'Additional Information',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              icon: Icons.calendar_today,
              title: 'Sales Period Reports',
              subtitle: 'Daily, weekly, and monthly sales analysis',
              onTap: () => _showComingSoon(context),
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              context,
              icon: Icons.trending_up,
              title: 'Top Selling Items',
              subtitle: 'Most popular products by quantity sold',
              onTap: () => _showComingSoon(context),
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              context,
              icon: Icons.pie_chart,
              title: 'Category Analysis',
              subtitle: 'Sales distribution by product category',
              onTap: () => _showComingSoon(context),
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              context,
              icon: Icons.account_circle,
              title: 'Customer Insights',
              subtitle: 'Top customers and buying patterns',
              onTap: () => _showComingSoon(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Icon(Icons.error_outline, color: Colors.grey.shade400),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey.shade600, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
