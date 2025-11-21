import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/item_provider.dart';
import '../models/item.dart';
import '../utils/currency_helper.dart';
import 'item_form_screen.dart';
import '../widgets/barcode_display_widget.dart';
import '../services/barcode_print_service.dart';

class ItemsListScreen extends ConsumerStatefulWidget {
  const ItemsListScreen({super.key});

  @override
  ConsumerState<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends ConsumerState<ItemsListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    if (query.isEmpty) {
      ref.read(itemProvider.notifier).loadItems();
    } else {
      ref.read(itemProvider.notifier).searchItems(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(itemProvider.notifier).loadItems(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(itemProvider.notifier).loadItems(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (items) {
          final lowStockItems = items
              .where((item) => item.stock <= item.reorderLevel)
              .toList();
          return Column(
            children: [
              // Low stock notification banner
              if (lowStockItems.isNotEmpty)
                Container(
                  width: double.infinity,
                  color: Colors.red.shade100,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Warning: ${lowStockItems.length} item(s) are low on stock!',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Search bar with print button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search items by name, SKU, or company...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.print),
                      tooltip: 'Print Barcodes',
                      onSelected: (value) {
                        if (value == 'print_all') {
                          _printAllBarcodes(context, items);
                        } else if (value == 'print_low_stock') {
                          _printLowStockBarcodes(context, lowStockItems);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'print_all',
                          child: Row(
                            children: [
                              Icon(Icons.print),
                              SizedBox(width: 8),
                              Text('Print All Items'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'print_low_stock',
                          enabled: lowStockItems.isNotEmpty,
                          child: Row(
                            children: [
                              Icon(Icons.warning),
                              SizedBox(width: 8),
                              Text('Print Low Stock'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Items list
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchQuery.isEmpty
                                    ? Icons.inventory_2_outlined
                                    : Icons.search_off,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No items yet'
                                    : 'No items found',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Start managing your inventory by adding your first item'
                                    : 'Try a different search term or check your filters',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                              if (_searchQuery.isEmpty) ...[
                                const SizedBox(height: 32),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ItemFormScreen(),
                                      ),
                                    );
                                    if (result == true && mounted) {
                                      ref
                                          .read(itemProvider.notifier)
                                          .loadItems();
                                    }
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add First Item'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _buildItemCard(context, item);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToItemForm(context, null),
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, Item item) {
    final isLowStock = item.stock <= item.reorderLevel;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLowStock ? Colors.red : Colors.indigo,
          child: Text(
            item.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('SKU: ${item.sku}'),
            if (item.company != null) Text('Company: ${item.company}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Stock: ${item.stock}'),
                if (isLowStock) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LOW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyHelper.format(item.unitPrice),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Icon(Icons.qr_code, size: 16, color: Colors.grey.shade600),
          ],
        ),
        onTap: () => _navigateToItemForm(context, item),
        onLongPress: () => _showBarcodeDialog(context, item),
      ),
    );
  }

  void _showBarcodeDialog(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (context) => BarcodeDialogWidget(
        sku: item.sku,
        itemName: item.name,
        company: item.company,
        price: item.unitPrice,
      ),
    );
  }

  Future<void> _navigateToItemForm(BuildContext context, Item? item) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => ItemFormScreen(item: item)),
    );

    if (result == true && mounted) {
      ref.read(itemProvider.notifier).loadItems();
    }
  }

  Future<void> _printAllBarcodes(BuildContext context, List<Item> items) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No items to print')));
      return;
    }

    try {
      final itemsData = items.map((item) {
        return {
          'sku': item.sku,
          'name': item.name,
          'company': item.company,
          'price': item.unitPrice,
        };
      }).toList();

      await BarcodePrintService.printBarcodeSheet(items: itemsData);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printLowStockBarcodes(
    BuildContext context,
    List<Item> items,
  ) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No low stock items to print')),
      );
      return;
    }

    try {
      final itemsData = items.map((item) {
        return {
          'sku': item.sku,
          'name': item.name,
          'company': item.company,
          'price': item.unitPrice,
        };
      }).toList();

      await BarcodePrintService.printBarcodeSheet(items: itemsData);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
