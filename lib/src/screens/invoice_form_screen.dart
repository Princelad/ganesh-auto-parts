import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/item.dart';
import '../models/customer.dart';
import '../providers/invoice_provider.dart';
import '../providers/item_provider.dart';
import '../providers/customer_provider.dart';
import '../widgets/dialogs.dart';

class InvoiceFormScreen extends ConsumerStatefulWidget {
  const InvoiceFormScreen({super.key});

  @override
  ConsumerState<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNoController = TextEditingController();
  final _paidAmountController = TextEditingController(text: '0');

  Customer? _selectedCustomer;
  DateTime _selectedDate = DateTime.now();
  final List<_LineItem> _lineItems = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _generateInvoiceNumber();
  }

  void _generateInvoiceNumber() {
    final now = DateTime.now();
    final invoiceNo = 'INV-${DateFormat('yyyyMMdd-HHmmss').format(now)}';
    _invoiceNoController.text = invoiceNo;
  }

  @override
  void dispose() {
    _invoiceNoController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    return _lineItems.fold(0.0, (sum, item) => sum + item.lineTotal);
  }

  double get _paidAmount {
    return double.tryParse(_paidAmountController.text) ?? 0.0;
  }

  double get _balanceAmount {
    return _totalAmount - _paidAmount;
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemProvider);
    final customersAsync = ref.watch(customerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _generateInvoiceNumber,
            tooltip: 'Generate New Number',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Invoice Number
                  TextFormField(
                    controller: _invoiceNoController,
                    decoration: const InputDecoration(
                      labelText: 'Invoice Number *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.receipt),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter invoice number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Customer Selection
                  customersAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (error, stack) =>
                        Text('Error loading customers: $error'),
                    data: (customers) => DropdownButtonFormField<Customer?>(
                      value: _selectedCustomer,
                      decoration: const InputDecoration(
                        labelText: 'Customer',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: [
                        const DropdownMenuItem<Customer?>(
                          value: null,
                          child: Text('Walk-in Customer'),
                        ),
                        ...customers.map(
                          (customer) => DropdownMenuItem(
                            value: customer,
                            child: Text(customer.name),
                          ),
                        ),
                      ],
                      onChanged: (customer) {
                        setState(() {
                          _selectedCustomer = customer;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date Selection
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Invoice Date *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('dd MMM yyyy').format(_selectedDate),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Line Items Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showAddItemDialog(itemsAsync),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Item'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_lineItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No items added',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap "Add Item" to get started',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._lineItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final lineItem = entry.value;
                      return _buildLineItemCard(index, lineItem);
                    }),
                  const SizedBox(height: 24),

                  // Summary Card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Summary',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildSummaryRow('Total Amount', _totalAmount),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _paidAmountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Paid Amount',
                              border: OutlineInputBorder(),
                              prefixText: '₹',
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (value) {
                              final paid = double.tryParse(value ?? '0') ?? 0.0;
                              if (paid < 0) {
                                return 'Amount cannot be negative';
                              }
                              if (paid > _totalAmount) {
                                return 'Cannot exceed total amount';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryRow(
                            'Balance',
                            _balanceAmount,
                            color: _balanceAmount > 0
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveInvoice,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save Invoice'),
      ),
    );
  }

  Widget _buildLineItemCard(int index, _LineItem lineItem) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lineItem.itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${lineItem.itemSku}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _lineItems.removeAt(index);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Qty: ${lineItem.quantity}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                Text(
                  '@ ₹${lineItem.unitPrice.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                Text(
                  '₹${lineItem.lineTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showAddItemDialog(AsyncValue<List<Item>> itemsAsync) {
    itemsAsync.when(
      loading: () {
        showErrorSnackBar(context, 'Loading items, please wait...');
      },
      error: (error, stack) {
        showErrorSnackBar(context, 'Error loading items: $error');
      },
      data: (items) {
        if (items.isEmpty) {
          showErrorSnackBar(context, 'No items available. Add items first.');
          return;
        }

        Item? selectedItem;
        final quantityController = TextEditingController(text: '1');
        final priceController = TextEditingController();

        showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: const Text('Add Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Item selection
                    DropdownButtonFormField<Item>(
                      value: selectedItem,
                      decoration: const InputDecoration(
                        labelText: 'Select Item *',
                        border: OutlineInputBorder(),
                      ),
                      items: items.map((item) {
                        // Check if item already added
                        final alreadyAdded = _lineItems.any(
                          (lineItem) => lineItem.itemId == item.id,
                        );
                        return DropdownMenuItem(
                          value: item,
                          enabled: !alreadyAdded && item.stock > 0,
                          child: Text(
                            '${item.name} (Stock: ${item.stock})${alreadyAdded
                                ? ' - Already added'
                                : item.stock == 0
                                ? ' - Out of stock'
                                : ''}',
                            style: TextStyle(
                              color: alreadyAdded || item.stock == 0
                                  ? Colors.grey
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (item) {
                        setDialogState(() {
                          selectedItem = item;
                          if (item != null) {
                            priceController.text = item.unitPrice
                                .toStringAsFixed(2);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Quantity
                    TextFormField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity *',
                        border: const OutlineInputBorder(),
                        helperText: selectedItem != null
                            ? 'Available: ${selectedItem!.stock}'
                            : null,
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 16),
                    // Unit Price
                    TextFormField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Unit Price *',
                        border: OutlineInputBorder(),
                        prefixText: '₹',
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    if (selectedItem != null &&
                        quantityController.text.isNotEmpty &&
                        priceController.text.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Line Total:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '₹${((int.tryParse(quantityController.text) ?? 0) * (double.tryParse(priceController.text) ?? 0)).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedItem == null) {
                      showErrorSnackBar(context, 'Please select an item');
                      return;
                    }

                    final quantity = int.tryParse(quantityController.text);
                    if (quantity == null || quantity <= 0) {
                      showErrorSnackBar(context, 'Invalid quantity');
                      return;
                    }

                    if (quantity > selectedItem!.stock) {
                      showErrorSnackBar(
                        context,
                        'Insufficient stock. Available: ${selectedItem!.stock}',
                      );
                      return;
                    }

                    final price = double.tryParse(priceController.text);
                    if (price == null || price <= 0) {
                      showErrorSnackBar(context, 'Invalid price');
                      return;
                    }

                    setState(() {
                      _lineItems.add(
                        _LineItem(
                          itemId: selectedItem!.id!,
                          itemName: selectedItem!.name,
                          itemSku: selectedItem!.sku,
                          quantity: quantity,
                          unitPrice: price,
                          availableStock: selectedItem!.stock,
                        ),
                      );
                    });

                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_lineItems.isEmpty) {
      showErrorSnackBar(context, 'Please add at least one item');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Create invoice
      final invoice = Invoice(
        invoiceNo: _invoiceNoController.text.trim(),
        customerId: _selectedCustomer?.id,
        total: _totalAmount,
        paid: _paidAmount,
        date: _selectedDate.millisecondsSinceEpoch,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        synced: 0,
      );

      // Create invoice items
      final invoiceItems = _lineItems
          .map(
            (lineItem) => InvoiceItem(
              invoiceId: 0, // Will be set by repository
              itemId: lineItem.itemId,
              qty: lineItem.quantity,
              unitPrice: lineItem.unitPrice,
              lineTotal: lineItem.lineTotal,
            ),
          )
          .toList();

      // Save invoice
      final invoiceId = await ref
          .read(invoiceProvider.notifier)
          .createInvoice(invoice, invoiceItems);

      if (!mounted) return;

      if (invoiceId != null) {
        showSuccessSnackBar(context, 'Invoice created successfully');
        Navigator.pop(context, true);
      } else {
        showErrorSnackBar(
          context,
          'Failed to create invoice. Invoice number may already exist.',
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class _LineItem {
  final int itemId;
  final String itemName;
  final String itemSku;
  final int quantity;
  final double unitPrice;
  final int availableStock;

  _LineItem({
    required this.itemId,
    required this.itemName,
    required this.itemSku,
    required this.quantity,
    required this.unitPrice,
    required this.availableStock,
  });

  double get lineTotal => quantity * unitPrice;
}
