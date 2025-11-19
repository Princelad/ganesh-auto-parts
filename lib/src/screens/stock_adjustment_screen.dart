import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../widgets/dialogs.dart';

class StockAdjustmentScreen extends ConsumerStatefulWidget {
  const StockAdjustmentScreen({super.key});

  @override
  ConsumerState<StockAdjustmentScreen> createState() =>
      _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends ConsumerState<StockAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();

  Item? _selectedItem;
  String _adjustmentType = 'add'; // add or remove
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Adjustment')),
      body: Form(
        key: _formKey,
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
                        'Use this screen to manually adjust stock quantities for inventory corrections, damages, or stock takes.',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Item selection
            InkWell(
              onTap: _pickItem,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Select Item *',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.search),
                ),
                child: Text(
                  _selectedItem?.name ?? 'Tap to select an item',
                  style: TextStyle(
                    color: _selectedItem == null
                        ? Colors.grey
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
            if (_selectedItem != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Current Stock: ${_selectedItem!.stock}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _selectedItem!.stock <= _selectedItem!.reorderLevel
                        ? Colors.red
                        : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Adjustment type
            DropdownButtonFormField<String>(
              initialValue: _adjustmentType,
              decoration: const InputDecoration(
                labelText: 'Adjustment Type *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'add', child: Text('Add Stock')),
                DropdownMenuItem(value: 'remove', child: Text('Remove Stock')),
              ],
              onChanged: (value) {
                setState(() {
                  _adjustmentType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            // Quantity
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity *',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  _adjustmentType == 'add' ? Icons.add : Icons.remove,
                  color: _adjustmentType == 'add' ? Colors.green : Colors.red,
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter quantity';
                }
                final qty = int.tryParse(value);
                if (qty == null || qty <= 0) {
                  return 'Please enter a valid quantity';
                }
                if (_adjustmentType == 'remove' &&
                    _selectedItem != null &&
                    qty > _selectedItem!.stock) {
                  return 'Cannot remove more than current stock (${_selectedItem!.stock})';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Reason
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason *',
                border: OutlineInputBorder(),
                hintText: 'e.g., Stock take correction, Damaged goods, etc.',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a reason for adjustment';
                }
                if (value.trim().length < 5) {
                  return 'Reason must be at least 5 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            // Preview card
            if (_selectedItem != null && _quantityController.text.isNotEmpty)
              _buildPreviewCard(),
            const SizedBox(height: 24),
            // Submit button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitAdjustment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _adjustmentType == 'add'
                    ? Colors.green
                    : Colors.red.shade700,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _adjustmentType == 'add' ? 'Add Stock' : 'Remove Stock',
                      style: const TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final qty = int.tryParse(_quantityController.text) ?? 0;
    final newStock = _adjustmentType == 'add'
        ? _selectedItem!.stock + qty
        : _selectedItem!.stock - qty;

    return Card(
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current Stock:'),
                Text(
                  _selectedItem!.stock.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_adjustmentType == 'add' ? 'Adding:' : 'Removing:'),
                Text(
                  '${_adjustmentType == 'add' ? '+' : '-'}$qty',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _adjustmentType == 'add' ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('New Stock:'),
                Text(
                  '$newStock',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: newStock <= _selectedItem!.reorderLevel
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
              ],
            ),
            if (newStock <= _selectedItem!.reorderLevel) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.orange.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Warning: Stock will be below reorder level (${_selectedItem!.reorderLevel})',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
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

  Future<void> _pickItem() async {
    final itemsAsync = ref.read(itemProvider);
    final items = itemsAsync.value ?? [];
    if (!mounted) return;

    final searchController = TextEditingController();
    String searchQuery = '';

    final item = await showDialog<Item>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final filteredItems = items.where((item) {
            return searchQuery.isEmpty ||
                item.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                item.sku.toLowerCase().contains(searchQuery.toLowerCase());
          }).toList();

          return AlertDialog(
            title: const Text('Select Item'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by name or SKU...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: filteredItems.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text('No items found'),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              final isLowStock =
                                  item.stock <= item.reorderLevel;
                              return ListTile(
                                title: Text(item.name),
                                subtitle: Text(
                                  '${item.sku} • Stock: ${item.stock}',
                                ),
                                trailing: isLowStock
                                    ? const Icon(
                                        Icons.warning,
                                        color: Colors.red,
                                        size: 20,
                                      )
                                    : null,
                                onTap: () => Navigator.pop(context, item),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );

    if (item != null) {
      setState(() {
        _selectedItem = item;
      });
    }
  }

  Future<void> _submitAdjustment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedItem == null) {
      showErrorSnackBar(context, 'Please select an item');
      return;
    }

    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Confirm Adjustment',
      message:
          'Are you sure you want to ${_adjustmentType == 'add' ? 'add' : 'remove'} ${_quantityController.text} units ${_adjustmentType == 'add' ? 'to' : 'from'} ${_selectedItem!.name}?',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final qty = int.parse(_quantityController.text);
      final newStock = _adjustmentType == 'add'
          ? _selectedItem!.stock + qty
          : _selectedItem!.stock - qty;

      final updatedItem = _selectedItem!.copyWith(
        stock: newStock,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await ref.read(itemProvider.notifier).updateItem(updatedItem);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock adjusted successfully. New stock: $newStock'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      setState(() {
        _selectedItem = null;
        _quantityController.clear();
        _reasonController.clear();
        _adjustmentType = 'add';
      });
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
