import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/item_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/invoice_provider.dart';
import '../services/csv_service.dart';
import '../widgets/dialogs.dart';

class CsvExportImportScreen extends ConsumerStatefulWidget {
  const CsvExportImportScreen({super.key});

  @override
  ConsumerState<CsvExportImportScreen> createState() =>
      _CsvExportImportScreenState();
}

class _CsvExportImportScreenState extends ConsumerState<CsvExportImportScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CSV Export/Import')),
      body: ListView(
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
                      'Export your data to CSV for backup or import CSV files to add bulk data.',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Export Section
          _buildSectionHeader(context, 'Export Data', Icons.file_download),
          const SizedBox(height: 12),
          _buildExportCard(
            context,
            icon: Icons.inventory_2,
            title: 'Export Items',
            subtitle: 'Export all items to CSV',
            color: Colors.blue,
            onTap: _exportItems,
          ),
          const SizedBox(height: 12),
          _buildExportCard(
            context,
            icon: Icons.people,
            title: 'Export Customers',
            subtitle: 'Export all customers to CSV',
            color: Colors.green,
            onTap: _exportCustomers,
          ),
          const SizedBox(height: 12),
          _buildExportCard(
            context,
            icon: Icons.receipt_long,
            title: 'Export Invoices',
            subtitle: 'Export all invoices to CSV',
            color: Colors.orange,
            onTap: _exportInvoices,
          ),
          const SizedBox(height: 24),
          // Import Section
          _buildSectionHeader(context, 'Import Data', Icons.file_upload),
          const SizedBox(height: 12),
          _buildImportCard(
            context,
            icon: Icons.inventory_2,
            title: 'Import Items',
            subtitle: 'Import items from CSV',
            color: Colors.blue,
            onTap: _importItems,
          ),
          const SizedBox(height: 12),
          _buildImportCard(
            context,
            icon: Icons.people,
            title: 'Import Customers',
            subtitle: 'Import customers from CSV',
            color: Colors.green,
            onTap: _importCustomers,
          ),
          const SizedBox(height: 24),
          // Templates Section
          _buildSectionHeader(context, 'CSV Templates', Icons.description),
          const SizedBox(height: 12),
          _buildTemplateCard(
            context,
            icon: Icons.inventory_2,
            title: 'Items Template',
            subtitle: 'Download CSV template for items',
            onTap: _downloadItemsTemplate,
          ),
          const SizedBox(height: 12),
          _buildTemplateCard(
            context,
            icon: Icons.people,
            title: 'Customers Template',
            subtitle: 'Download CSV template for customers',
            onTap: _downloadCustomersTemplate,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildExportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _isProcessing ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.file_download, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isProcessing)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
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

  Widget _buildImportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _isProcessing ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.file_upload, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isProcessing)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
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

  Widget _buildTemplateCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _isProcessing ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.grey.shade700, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.download, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportItems() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      var itemsAsync = ref.read(itemProvider);

      // If data is still loading, wait for it to complete
      if (itemsAsync.isLoading) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading data, please wait...'),
            duration: Duration(seconds: 2),
          ),
        );

        // Wait for data to load by watching the provider
        await Future.delayed(const Duration(milliseconds: 500));
        itemsAsync = ref.read(itemProvider);

        // If still loading after delay, wait a bit more
        int attempts = 0;
        while (itemsAsync.isLoading && attempts < 10) {
          await Future.delayed(const Duration(milliseconds: 500));
          itemsAsync = ref.read(itemProvider);
          attempts++;
        }
      }

      // Check for errors
      if (itemsAsync.hasError) {
        if (!mounted) return;
        showErrorSnackBar(context, 'Error loading items: ${itemsAsync.error}');
        return;
      }

      final items = itemsAsync.value ?? [];
      if (items.isEmpty) {
        if (!mounted) return;
        showErrorSnackBar(context, 'No items to export');
        return;
      }

      final file = await CsvService.exportItems(items);
      if (!mounted) return;

      await _shareFile(file, 'Items exported successfully');
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Failed to export items: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _exportCustomers() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      var customersAsync = ref.read(customerProvider);

      // If data is still loading, wait for it to complete
      if (customersAsync.isLoading) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading data, please wait...'),
            duration: Duration(seconds: 2),
          ),
        );

        // Wait for data to load by watching the provider
        await Future.delayed(const Duration(milliseconds: 500));
        customersAsync = ref.read(customerProvider);

        // If still loading after delay, wait a bit more
        int attempts = 0;
        while (customersAsync.isLoading && attempts < 10) {
          await Future.delayed(const Duration(milliseconds: 500));
          customersAsync = ref.read(customerProvider);
          attempts++;
        }
      }

      // Check for errors
      if (customersAsync.hasError) {
        if (!mounted) return;
        showErrorSnackBar(
          context,
          'Error loading customers: ${customersAsync.error}',
        );
        return;
      }

      final customers = customersAsync.value ?? [];
      if (customers.isEmpty) {
        if (!mounted) return;
        showErrorSnackBar(context, 'No customers to export');
        return;
      }

      final file = await CsvService.exportCustomers(customers);
      if (!mounted) return;

      await _shareFile(file, 'Customers exported successfully');
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Failed to export customers: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _exportInvoices() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      var invoicesAsync = ref.read(invoiceProvider);

      // If data is still loading, wait for it to complete
      if (invoicesAsync.isLoading) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading data, please wait...'),
            duration: Duration(seconds: 2),
          ),
        );

        // Wait for data to load by watching the provider
        await Future.delayed(const Duration(milliseconds: 500));
        invoicesAsync = ref.read(invoiceProvider);

        // If still loading after delay, wait a bit more
        int attempts = 0;
        while (invoicesAsync.isLoading && attempts < 10) {
          await Future.delayed(const Duration(milliseconds: 500));
          invoicesAsync = ref.read(invoiceProvider);
          attempts++;
        }
      }

      // Check for errors
      if (invoicesAsync.hasError) {
        if (!mounted) return;
        showErrorSnackBar(
          context,
          'Error loading invoices: ${invoicesAsync.error}',
        );
        return;
      }

      final invoices = invoicesAsync.value ?? [];
      if (invoices.isEmpty) {
        if (!mounted) return;
        showErrorSnackBar(context, 'No invoices to export');
        return;
      }

      final file = await CsvService.exportInvoices(invoices);
      if (!mounted) return;

      await _shareFile(file, 'Invoices exported successfully');
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Failed to export invoices: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _importItems() async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Import Items',
      message:
          'This will import items from a CSV file. Duplicate SKUs will be skipped. Continue?',
    );

    if (!confirmed) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
        return;
      }

      final file = File(result.files.single.path!);
      final csvContent = await file.readAsString();
      final items = await CsvService.parseItemsCsv(csvContent);

      if (items.isEmpty) {
        if (!mounted) return;
        showErrorSnackBar(context, 'No valid items found in CSV');
        return;
      }

      int imported = 0;
      for (final item in items) {
        final success = await ref.read(itemProvider.notifier).addItem(item);
        if (success) imported++;
      }

      if (!mounted) return;
      showSuccessSnackBar(
        context,
        'Imported $imported of ${items.length} items',
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Failed to import items: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _importCustomers() async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Import Customers',
      message:
          'This will import customers from a CSV file. Duplicate phone numbers will be skipped. Continue?',
    );

    if (!confirmed) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
        return;
      }

      final file = File(result.files.single.path!);
      final csvContent = await file.readAsString();
      final customers = await CsvService.parseCustomersCsv(csvContent);

      if (customers.isEmpty) {
        if (!mounted) return;
        showErrorSnackBar(context, 'No valid customers found in CSV');
        return;
      }

      int imported = 0;
      for (final customer in customers) {
        final success = await ref
            .read(customerProvider.notifier)
            .addCustomer(customer);
        if (success) imported++;
      }

      if (!mounted) return;
      showSuccessSnackBar(
        context,
        'Imported $imported of ${customers.length} customers',
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Failed to import customers: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _downloadItemsTemplate() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final template = CsvService.getItemsTemplate();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/items_template.csv');
      await file.writeAsString(template);

      if (!mounted) return;
      await _shareFile(file, 'Items template downloaded');
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Failed to download template: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _downloadCustomersTemplate() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final template = CsvService.getCustomersTemplate();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/customers_template.csv');
      await file.writeAsString(template);

      if (!mounted) return;
      await _shareFile(file, 'Customers template downloaded');
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Failed to download template: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _shareFile(File file, String successMessage) async {
    try {
      final xFile = XFile(file.path);
      await SharePlus.instance.share(
        ShareParams(files: [xFile], text: 'Export from Ganesh Auto Parts'),
      );

      if (!mounted) return;
      showSuccessSnackBar(context, successMessage);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'File saved at: ${file.path}');
    }
  }
}
