import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'items_list_screen.dart';
import 'customers_list_screen.dart';
import 'stock_adjustment_screen.dart';
import 'reports_screen.dart';
import 'csv_export_import_screen.dart';
import 'invoices_list_screen.dart';
import '../widgets/dashboard_stats_widget.dart';
import '../providers/item_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/invoice_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ganesh Auto Parts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.pushNamed(context, '/about'),
            tooltip: 'About',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          const DashboardStatsWidget(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildMenuCard(
                  context,
                  icon: Icons.inventory_2,
                  title: 'Items',
                  color: Colors.blue,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ItemsListScreen(),
                      ),
                    );
                    // Refresh stats after returning
                    ref.invalidate(itemCountProvider);
                    ref.invalidate(lowStockItemsProvider);
                  },
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.people,
                  title: 'Customers',
                  color: Colors.green,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CustomersListScreen(),
                      ),
                    );
                    // Refresh stats after returning
                    ref.invalidate(customerCountProvider);
                    ref.invalidate(totalOutstandingBalanceProvider);
                  },
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.settings_backup_restore,
                  title: 'Stock Adjust',
                  color: Colors.teal,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StockAdjustmentScreen(),
                      ),
                    );
                    // Refresh stats after returning
                    ref.invalidate(itemCountProvider);
                    ref.invalidate(lowStockItemsProvider);
                  },
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.bar_chart,
                  title: 'Reports',
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReportsScreen(),
                    ),
                  ),
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.receipt_long,
                  title: 'Invoices',
                  color: Colors.indigo,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InvoicesListScreen(),
                      ),
                    );
                    // Refresh all data when returning from invoices
                    ref.invalidate(invoiceProvider);
                    ref.invalidate(invoiceCountProvider);
                    ref.invalidate(itemProvider);
                    ref.invalidate(itemCountProvider);
                    ref.invalidate(customerProvider);
                    ref.invalidate(customerCountProvider);
                    ref.invalidate(totalOutstandingBalanceProvider);
                    ref.invalidate(lowStockItemsProvider);
                  },
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.upload_file,
                  title: 'CSV Export/Import',
                  color: Colors.teal,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CsvExportImportScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
