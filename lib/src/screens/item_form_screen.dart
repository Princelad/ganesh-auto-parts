import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../utils/validators.dart';
import '../utils/date_helper.dart';
import 'barcode_scanner_screen.dart';

class ItemFormScreen extends ConsumerStatefulWidget {
  final Item? item;

  const ItemFormScreen({super.key, this.item});

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _skuController;
  late final TextEditingController _nameController;
  late final TextEditingController _companyController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _reorderLevelController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _skuController = TextEditingController(text: widget.item?.sku ?? '');
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _companyController = TextEditingController(
      text: widget.item?.company ?? '',
    );
    _priceController = TextEditingController(
      text: widget.item?.unitPrice.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: widget.item?.stock.toString() ?? '0',
    );
    _reorderLevelController = TextEditingController(
      text: widget.item?.reorderLevel.toString() ?? '10',
    );
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _companyController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _reorderLevelController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final now = DateTimeHelper.now();
    final item = Item(
      id: widget.item?.id,
      sku: _skuController.text.trim(),
      name: _nameController.text.trim(),
      company: _companyController.text.trim().isEmpty
          ? null
          : _companyController.text.trim(),
      unitPrice: double.parse(_priceController.text),
      stock: int.parse(_stockController.text),
      reorderLevel: int.parse(_reorderLevelController.text),
      createdAt: widget.item?.createdAt ?? now,
      updatedAt: now,
    );

    final success = widget.item == null
        ? await ref.read(itemProvider.notifier).addItem(item)
        : await ref.read(itemProvider.notifier).updateItem(item);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.item == null
                ? 'Item added successfully'
                : 'Item updated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SKU already exists. Please use a different SKU.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _scanBarcode() async {
    try {
      final scannedCode = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
      );

      if (scannedCode != null && scannedCode.isNotEmpty) {
        setState(() {
          _skuController.text = scannedCode;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scanning barcode: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteItem() async {
    if (widget.item?.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    final success = await ref
        .read(itemProvider.notifier)
        .deleteItem(widget.item!.id!);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete item'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Add Item' : 'Edit Item'),
        actions: [
          if (widget.item != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _deleteItem,
              tooltip: 'Delete',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _skuController,
              decoration: InputDecoration(
                labelText: 'SKU *',
                hintText: 'e.g., PART-001',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _isLoading ? null : _scanBarcode,
                  tooltip: 'Scan Barcode',
                ),
              ),
              validator: Validators.validateSku,
              enabled: !_isLoading,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name *',
                hintText: 'e.g., Brake Pad',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  Validators.validateName(value, fieldName: 'Item Name'),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Company',
                hintText: 'e.g., Bosch',
                border: OutlineInputBorder(),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Unit Price *',
                hintText: 'e.g., 150.00',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) =>
                  Validators.validatePrice(value, fieldName: 'Unit Price'),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(
                labelText: 'Stock *',
                hintText: 'e.g., 100',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: Validators.validateStock,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reorderLevelController,
              decoration: const InputDecoration(
                labelText: 'Reorder Level *',
                hintText: 'e.g., 10',
                helperText: 'Alert when stock reaches this level',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: Validators.validateStock,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveItem,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.item == null ? 'Add Item' : 'Update Item'),
            ),
          ],
        ),
      ),
    );
  }
}
