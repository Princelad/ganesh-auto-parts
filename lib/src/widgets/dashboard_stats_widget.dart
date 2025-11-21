import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/item_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/invoice_provider.dart';
import '../utils/currency_helper.dart';

class DashboardStatsWidget extends ConsumerWidget {
  const DashboardStatsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemCountAsync = ref.watch(itemCountProvider);
    final customerCountAsync = ref.watch(customerCountProvider);
    final invoiceCountAsync = ref.watch(invoiceCountProvider);
    final outstandingBalanceAsync = ref.watch(totalOutstandingBalanceProvider);
    final lowStockItemsAsync = ref.watch(lowStockItemsProvider);
    final todayRevenueAsync = ref.watch(todayRevenueProvider);
    final weekRevenueAsync = ref.watch(weekRevenueProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Stats',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.inventory_2,
                    label: 'Items',
                    valueAsync: itemCountAsync,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.people,
                    label: 'Customers',
                    valueAsync: customerCountAsync,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.receipt_long,
                    label: 'Invoices',
                    valueAsync: invoiceCountAsync,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: lowStockItemsAsync.when(
                    data: (items) => _buildStatCard(
                      context,
                      icon: Icons.warning,
                      label: 'Low Stock',
                      value: items.length.toString(),
                      color: items.isEmpty ? Colors.grey : Colors.red,
                    ),
                    loading: () => _buildStatCard(
                      context,
                      icon: Icons.warning,
                      label: 'Low Stock',
                      value: '-',
                      color: Colors.grey,
                    ),
                    error: (_, _) => _buildStatCard(
                      context,
                      icon: Icons.warning,
                      label: 'Low Stock',
                      value: '-',
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Revenue Cards
            Row(
              children: [
                Expanded(
                  child: todayRevenueAsync.when(
                    data: (revenue) => _buildRevenueCard(
                      context,
                      'Today\'s Revenue',
                      revenue,
                      Icons.today,
                      Colors.green,
                    ),
                    loading: () => _buildRevenueCard(
                      context,
                      'Today\'s Revenue',
                      0,
                      Icons.today,
                      Colors.green,
                      loading: true,
                    ),
                    error: (_, _) => _buildRevenueCard(
                      context,
                      'Today\'s Revenue',
                      0,
                      Icons.today,
                      Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: weekRevenueAsync.when(
                    data: (revenue) => _buildRevenueCard(
                      context,
                      'This Week',
                      revenue,
                      Icons.calendar_today,
                      Colors.indigo,
                    ),
                    loading: () => _buildRevenueCard(
                      context,
                      'This Week',
                      0,
                      Icons.calendar_today,
                      Colors.indigo,
                      loading: true,
                    ),
                    error: (_, _) => _buildRevenueCard(
                      context,
                      'This Week',
                      0,
                      Icons.calendar_today,
                      Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            outstandingBalanceAsync.when(
              data: (balance) => _buildBalanceCard(context, balance),
              loading: () => _buildBalanceCard(context, 0, loading: true),
              error: (_, _) => _buildBalanceCard(context, 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    AsyncValue<int>? valueAsync,
    String? value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          if (valueAsync != null)
            valueAsync.when(
              data: (val) => Text(
                val.toString(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              loading: () => const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, _) => Text(
                '-',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            )
          else
            Text(
              value ?? '-',
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
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    double balance, {
    bool loading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Outstanding Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                if (loading)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Text(
                    CurrencyHelper.format(balance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(
    BuildContext context,
    String label,
    double revenue,
    IconData icon,
    Color color, {
    bool loading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (loading)
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(
              CurrencyHelper.format(revenue),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}
