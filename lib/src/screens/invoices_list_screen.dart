import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../models/invoice.dart';
import '../models/customer.dart';
import '../providers/invoice_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/database_provider.dart';
import '../widgets/dialogs.dart';
import 'invoice_form_screen.dart';
import '../services/pdf_service.dart';

class InvoicesListScreen extends ConsumerStatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  ConsumerState<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends ConsumerState<InvoicesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, paid, unpaid, partial

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<Invoice> _filterInvoices(List<Invoice> invoices) {
    var filtered = invoices;

    // Apply status filter
    if (_filterStatus != 'all') {
      filtered = filtered.where((invoice) {
        if (_filterStatus == 'paid') {
          return invoice.paid >= invoice.total;
        } else if (_filterStatus == 'unpaid') {
          return invoice.paid == 0;
        } else if (_filterStatus == 'partial') {
          return invoice.paid > 0 && invoice.paid < invoice.total;
        }
        return true;
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((invoice) {
        return invoice.invoiceNo.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoiceProvider);
    final customersAsync = ref.watch(customerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(invoiceProvider.notifier).loadInvoices(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by invoice number...',
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
                const SizedBox(height: 12),
                // Status filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Paid', 'paid'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Unpaid', 'unpaid'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Partial', 'partial'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Invoices list
          Expanded(
            child: invoicesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(invoiceProvider.notifier).loadInvoices(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (invoices) {
                final filteredInvoices = _filterInvoices(invoices);

                if (filteredInvoices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _filterStatus != 'all'
                              ? 'No invoices found'
                              : 'No invoices yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (_searchQuery.isEmpty && _filterStatus == 'all') ...[
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to create your first invoice',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredInvoices.length,
                  itemBuilder: (context, index) {
                    final invoice = filteredInvoices[index];
                    return _buildInvoiceCard(context, invoice, customersAsync);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InvoiceFormScreen()),
          );
          if (result == true && mounted) {
            ref.read(invoiceProvider.notifier).loadInvoices();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildInvoiceCard(
    BuildContext context,
    Invoice invoice,
    AsyncValue<List> customersAsync,
  ) {
    final customerName = customersAsync.when(
      data: (customers) {
        if (invoice.customerId == null) return 'Walk-in Customer';
        try {
          final customer = customers.firstWhere(
            (c) => c.id == invoice.customerId,
          );
          return customer.name;
        } catch (e) {
          return 'Unknown Customer';
        }
      },
      loading: () => '...',
      error: (_, __) => 'Unknown',
    );

    final balance = invoice.total - invoice.paid;
    final isFullyPaid = invoice.paid >= invoice.total;
    final isUnpaid = invoice.paid == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showInvoiceDetails(invoice, customerName),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Invoice number and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    invoice.invoiceNo,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isFullyPaid
                          ? Colors.green.withValues(alpha: 0.1)
                          : isUnpaid
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isFullyPaid
                          ? 'PAID'
                          : isUnpaid
                          ? 'UNPAID'
                          : 'PARTIAL',
                      style: TextStyle(
                        color: isFullyPaid
                            ? Colors.green.shade700
                            : isUnpaid
                            ? Colors.red.shade700
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Customer name
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    customerName,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat(
                      'dd MMM yyyy',
                    ).format(DateTime.fromMillisecondsSinceEpoch(invoice.date)),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Amounts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '₹${invoice.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paid',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '₹${invoice.paid.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (!isFullyPaid)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Balance',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '₹${balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInvoiceDetails(Invoice invoice, String customerName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) =>
            _buildInvoiceDetailsSheet(invoice, customerName, scrollController),
      ),
    );
  }

  Widget _buildInvoiceDetailsSheet(
    Invoice invoice,
    String customerName,
    ScrollController scrollController,
  ) {
    final balance = invoice.total - invoice.paid;
    final isFullyPaid = invoice.paid >= invoice.total;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                invoice.invoiceNo,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Details
          _buildDetailRow('Customer', customerName),
          _buildDetailRow(
            'Date',
            DateFormat(
              'dd MMM yyyy, hh:mm a',
            ).format(DateTime.fromMillisecondsSinceEpoch(invoice.date)),
          ),
          _buildDetailRow(
            'Total Amount',
            '₹${invoice.total.toStringAsFixed(2)}',
          ),
          _buildDetailRow(
            'Paid Amount',
            '₹${invoice.paid.toStringAsFixed(2)}',
            valueColor: Colors.green.shade700,
          ),
          if (!isFullyPaid)
            _buildDetailRow(
              'Balance',
              '₹${balance.toStringAsFixed(2)}',
              valueColor: Colors.red.shade700,
            ),
          const SizedBox(height: 24),
          // Actions
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _exportToPdf(invoice, customerName),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Export as PDF'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!isFullyPaid) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showPaymentDialog(invoice);
                },
                icon: const Icon(Icons.payment),
                label: const Text('Record Payment'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showDeleteConfirmation(invoice);
              },
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text(
                'Delete Invoice',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(Invoice invoice) {
    final balance = invoice.total - invoice.paid;
    final controller = TextEditingController(text: balance.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice: ${invoice.invoiceNo}'),
            const SizedBox(height: 8),
            Text('Balance: ₹${balance.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Payment Amount',
                prefixText: '₹',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount == null || amount <= 0) {
                showErrorSnackBar(context, 'Invalid amount');
                return;
              }

              if (amount > balance) {
                showErrorSnackBar(
                  context,
                  'Amount cannot exceed balance of ₹${balance.toStringAsFixed(2)}',
                );
                return;
              }

              Navigator.pop(context);

              final newPaid = invoice.paid + amount;
              final success = await ref
                  .read(invoiceProvider.notifier)
                  .updatePayment(invoice.id!, newPaid);

              if (mounted) {
                if (success) {
                  showSuccessSnackBar(context, 'Payment recorded successfully');
                } else {
                  showErrorSnackBar(context, 'Failed to record payment');
                }
              }
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text(
          'Are you sure you want to delete invoice ${invoice.invoiceNo}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final success = await ref
                  .read(invoiceProvider.notifier)
                  .deleteInvoice(invoice.id!);

              if (mounted) {
                if (success) {
                  showSuccessSnackBar(context, 'Invoice deleted successfully');
                } else {
                  showErrorSnackBar(context, 'Failed to delete invoice');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPdf(Invoice invoice, String customerName) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating PDF...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Get invoice items
      final invoiceItems = await ref.read(
        invoiceItemsProvider(invoice.id!).future,
      );

      // Get all items directly from repository
      final itemRepository = ref.read(itemRepositoryProvider);
      final allItems = await itemRepository.getAll();

      // Get customer if exists
      Customer? customer;
      if (invoice.customerId != null) {
        final customerRepository = ref.read(customerRepositoryProvider);
        final customers = await customerRepository.getAll();

        try {
          customer = customers.firstWhere((c) => c.id == invoice.customerId);
        } catch (e) {
          customer = null;
        }
      }

      // Generate PDF
      final pdfBytes = await PdfService.generateInvoice(
        invoice: invoice,
        items: invoiceItems,
        allItems: allItems,
        customer: customer,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show PDF preview with share/print options
      if (mounted) {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'Invoice-${invoice.invoiceNo}.pdf',
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.pop(context);
        showErrorSnackBar(context, 'Failed to generate PDF: $e');
      }
    }
  }
}
