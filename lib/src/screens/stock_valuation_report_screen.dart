import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/item_repository.dart';
import '../models/item.dart';
import '../utils/currency_helper.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_state_widget.dart';

/// Stock Valuation Report Screen
/// Shows total inventory value and breakdown by company
class StockValuationReportScreen extends ConsumerStatefulWidget {
  const StockValuationReportScreen({super.key});

  @override
  ConsumerState<StockValuationReportScreen> createState() =>
      _StockValuationReportScreenState();
}

class _StockValuationReportScreenState
    extends ConsumerState<StockValuationReportScreen> {
  final ItemRepository _itemRepository = ItemRepository();

  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>>? _companyBreakdown;
  List<Item>? _lowStockItems;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadValuationData();
  }

  Future<void> _loadValuationData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summary = await _itemRepository.getStockValuationSummary();
      final breakdown = await _itemRepository.getStockValuationByCompany();
      final lowStock = await _itemRepository.getLowStockItems();

      setState(() {
        _summary = summary;
        _companyBreakdown = breakdown;
        _lowStockItems = lowStock;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Valuation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadValuationData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Calculating stock value...')
          : _error != null
          ? ErrorStateWidget(error: _error!, onRetry: _loadValuationData)
          : RefreshIndicator(
              onRefresh: _loadValuationData,
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
                              'Current inventory valuation based on stock quantity and unit prices.',
                              style: TextStyle(color: Colors.blue.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Summary section
                  if (_summary != null) ...[
                    _buildSectionHeader('Valuation Summary'),
                    const SizedBox(height: 12),
                    _buildSummaryCard(),
                    const SizedBox(height: 24),
                  ],

                  // Company breakdown
                  if (_companyBreakdown != null &&
                      _companyBreakdown!.isNotEmpty) ...[
                    _buildSectionHeader('Breakdown by Company'),
                    const SizedBox(height: 12),
                    ..._companyBreakdown!.map(_buildCompanyCard),
                    const SizedBox(height: 24),
                  ],

                  // Low stock items
                  if (_lowStockItems != null && _lowStockItems!.isNotEmpty) ...[
                    _buildSectionHeader('Low Stock Items'),
                    const SizedBox(height: 12),
                    _buildLowStockSummary(),
                    const SizedBox(height: 12),
                    ..._lowStockItems!.take(10).map(_buildLowStockItemCard),
                  ],

                  // Empty state
                  if (_summary?['itemCount'] == 0) ...[
                    const SizedBox(height: 48),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No items in inventory',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add items to see stock valuation',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSummaryCard() {
    final summary = _summary!;
    final itemCount = summary['itemCount'] as int;
    final totalStock = summary['totalStock'] as int;
    final totalValue = summary['totalValue'] as double;
    final lowStockValue = summary['lowStockValue'] as double;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Total inventory value (highlighted)
            _buildSummaryRow(
              'Total Inventory Value',
              CurrencyHelper.format(totalValue),
              Icons.account_balance_wallet,
              Colors.green,
              isHighlight: true,
              isLarge: true,
            ),
            const Divider(height: 24),

            // Total items
            _buildSummaryRow(
              'Total Items',
              '$itemCount items',
              Icons.inventory_2,
              Colors.blue,
            ),
            const Divider(height: 24),

            // Total stock quantity
            _buildSummaryRow(
              'Total Stock Quantity',
              '$totalStock units',
              Icons.analytics,
              Colors.purple,
            ),
            const Divider(height: 24),

            // Low stock value
            _buildSummaryRow(
              'Low Stock Value',
              CurrencyHelper.format(lowStockValue),
              Icons.warning_amber,
              Colors.orange,
            ),
            if (lowStockValue > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Items at or below reorder level',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isHighlight = false,
    bool isLarge = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: isLarge ? 32 : 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: isLarge
                    ? Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isHighlight ? color : null,
                      )
                    : Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isHighlight ? color : null,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyCard(Map<String, dynamic> data) {
    final company = data['company'] as String;
    final itemCount = data['itemCount'] as int;
    final totalStock = data['totalStock'] as int;
    final totalValue = data['totalValue'] as double;

    // Calculate percentage of total inventory value
    final totalInventoryValue = _summary?['totalValue'] as double? ?? 1.0;
    final percentage = totalInventoryValue > 0
        ? (totalValue / totalInventoryValue * 100)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    company,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailColumn(
                    'Value',
                    CurrencyHelper.format(totalValue),
                    color: Colors.green,
                    isBold: true,
                  ),
                ),
                Expanded(child: _buildDetailColumn('Items', '$itemCount')),
                Expanded(
                  child: _buildDetailColumn('Stock', '$totalStock units'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockSummary() {
    final lowStockValue = _summary?['lowStockValue'] as double? ?? 0.0;
    final lowStockCount = _lowStockItems?.length ?? 0;

    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_amber,
                color: Colors.orange.shade900,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'At Risk Inventory',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$lowStockCount items worth ${CurrencyHelper.format(lowStockValue)}',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Items at or below reorder level need restocking',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade700,
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

  Widget _buildLowStockItemCard(Item item) {
    final itemValue = item.stock * item.unitPrice;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: Icon(
            Icons.inventory_2,
            color: Colors.orange.shade900,
            size: 20,
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${item.company ?? 'No Brand'} • SKU: ${item.sku}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyHelper.format(itemValue),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              '${item.stock} units',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailColumn(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
