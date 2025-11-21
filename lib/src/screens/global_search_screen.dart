import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/item_repository.dart';
import '../db/customer_repository.dart';
import '../db/invoice_repository.dart';
import '../models/item.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../utils/currency_helper.dart';
import 'item_form_screen.dart';
import 'customer_form_screen.dart';
import 'package:intl/intl.dart';

/// Global search screen for searching across all entities
class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ItemRepository _itemRepository = ItemRepository();
  final CustomerRepository _customerRepository = CustomerRepository();
  final InvoiceRepository _invoiceRepository = InvoiceRepository();

  List<Item> _itemResults = [];
  List<Customer> _customerResults = [];
  List<Invoice> _invoiceResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _itemResults = [];
        _customerResults = [];
        _invoiceResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      // Search in parallel
      final results = await Future.wait([
        _itemRepository.search(query),
        _customerRepository.search(query),
        _invoiceRepository.search(query),
      ]);

      setState(() {
        _itemResults = results[0] as List<Item>;
        _customerResults = results[1] as List<Customer>;
        _invoiceResults = results[2] as List<Invoice>;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  int get _totalResults =>
      _itemResults.length + _customerResults.length + _invoiceResults.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search items, customers, invoices...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey.shade600),
          ),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            decoration: TextDecoration.none,
          ),
          cursorColor: Colors.black87,
          onChanged: (value) {
            // Debounce search
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_searchController.text == value) {
                _performSearch(value);
              }
            });
          },
          onSubmitted: _performSearch,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            ),
        ],
      ),
      body: _isSearching
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Searching...'),
                ],
              ),
            )
          : _hasSearched
          ? _totalResults == 0
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No results found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Summary
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: Colors.blue.shade700),
                              const SizedBox(width: 12),
                              Text(
                                'Found $_totalResults results',
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Items Section
                      if (_itemResults.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Items (${_itemResults.length})',
                          Icons.inventory_2,
                          Colors.blue,
                        ),
                        const SizedBox(height: 8),
                        ..._itemResults.map(_buildItemCard),
                        const SizedBox(height: 16),
                      ],

                      // Customers Section
                      if (_customerResults.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Customers (${_customerResults.length})',
                          Icons.people,
                          Colors.green,
                        ),
                        const SizedBox(height: 8),
                        ..._customerResults.map(_buildCustomerCard),
                        const SizedBox(height: 16),
                      ],

                      // Invoices Section
                      if (_invoiceResults.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Invoices (${_invoiceResults.length})',
                          Icons.receipt_long,
                          Colors.orange,
                        ),
                        const SizedBox(height: 8),
                        ..._invoiceResults.map(_buildInvoiceCard),
                      ],
                    ],
                  )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Global Search',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Search across items, customers, and invoices',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSearchTip('Search by item name or SKU'),
                        _buildSearchTip('Search by customer name or phone'),
                        _buildSearchTip('Search by invoice number'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(tip, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildItemCard(Item item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.inventory_2, color: Colors.blue.shade700),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKU: ${item.sku}'),
            if (item.company != null && item.company!.isNotEmpty)
              Text('Company: ${item.company}'),
            Row(
              children: [
                Text('Stock: ${item.stock}'),
                const SizedBox(width: 16),
                Text('Price: ${CurrencyHelper.format(item.unitPrice)}'),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ItemFormScreen(item: item)),
          );
        },
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.person, color: Colors.green.shade700),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone: ${customer.phone}'),
            if (customer.address != null && customer.address!.isNotEmpty)
              Text(
                'Address: ${customer.address}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (customer.balance > 0)
              Text(
                'Balance: ${CurrencyHelper.format(customer.balance)}',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerFormScreen(customer: customer),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    final date = DateTime.fromMillisecondsSinceEpoch(invoice.date);
    final formattedDate = DateFormat('dd MMM yyyy').format(date);
    final isPaid = invoice.paid >= invoice.total;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.receipt_long, color: Colors.orange.shade700),
        ),
        title: Text(
          invoice.invoiceNo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formattedDate),
            Row(
              children: [
                Text('Total: ${CurrencyHelper.format(invoice.total)}'),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPaid ? 'Paid' : 'Pending',
                    style: TextStyle(
                      fontSize: 12,
                      color: isPaid
                          ? Colors.green.shade900
                          : Colors.orange.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Show invoice details in bottom sheet (similar to invoices list screen)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Invoice ${invoice.invoiceNo} - ${CurrencyHelper.format(invoice.total)}',
              ),
              action: SnackBarAction(
                label: 'View All',
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
