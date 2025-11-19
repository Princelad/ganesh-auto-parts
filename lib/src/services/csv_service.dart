import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../models/item.dart';
import '../models/customer.dart';
import '../models/invoice.dart';

/// Service for CSV export and import operations
class CsvService {
  /// Export items to CSV
  static Future<File> exportItems(List<Item> items) async {
    final rows = <List<dynamic>>[
      // Header row
      [
        'ID',
        'SKU',
        'Name',
        'Company',
        'Unit Price',
        'Stock',
        'Reorder Level',
        'Created At',
        'Updated At',
      ],
      // Data rows
      ...items.map(
        (item) => [
          item.id,
          item.sku,
          item.name,
          item.company ?? '',
          item.unitPrice,
          item.stock,
          item.reorderLevel,
          item.createdAt,
          item.updatedAt,
        ],
      ),
    ];

    return _writeCSV('items_export', rows);
  }

  /// Export customers to CSV
  static Future<File> exportCustomers(List<Customer> customers) async {
    final rows = <List<dynamic>>[
      // Header row
      ['ID', 'Name', 'Phone', 'Address', 'Balance', 'Created At'],
      // Data rows
      ...customers.map(
        (customer) => [
          customer.id,
          customer.name,
          customer.phone,
          customer.address ?? '',
          customer.balance,
          customer.createdAt,
        ],
      ),
    ];

    return _writeCSV('customers_export', rows);
  }

  /// Export invoices to CSV (basic info only)
  static Future<File> exportInvoices(List<Invoice> invoices) async {
    final rows = <List<dynamic>>[
      // Header row
      [
        'ID',
        'Invoice No',
        'Customer ID',
        'Total',
        'Paid',
        'Balance',
        'Date',
        'Created At',
      ],
      // Data rows
      ...invoices.map(
        (invoice) => [
          invoice.id,
          invoice.invoiceNo,
          invoice.customerId,
          invoice.total,
          invoice.paid,
          invoice.balance,
          invoice.date,
          invoice.createdAt,
        ],
      ),
    ];

    return _writeCSV('invoices_export', rows);
  }

  /// Parse items from CSV file
  static Future<List<Item>> parseItemsCsv(String csvContent) async {
    final rows = const CsvToListConverter().convert(csvContent);
    if (rows.isEmpty) return [];

    final items = <Item>[];
    // Skip header row
    for (var i = 1; i < rows.length; i++) {
      try {
        final row = rows[i];
        if (row.length < 7) continue; // Skip invalid rows

        items.add(
          Item(
            sku: row[1].toString(),
            name: row[2].toString(),
            company: row[3].toString().isEmpty ? null : row[3].toString(),
            unitPrice: double.parse(row[4].toString()),
            stock: int.parse(row[5].toString()),
            reorderLevel: int.parse(row[6].toString()),
            createdAt: DateTime.now().millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } catch (e) {
        // Skip invalid rows
        continue;
      }
    }

    return items;
  }

  /// Parse customers from CSV file
  static Future<List<Customer>> parseCustomersCsv(String csvContent) async {
    final rows = const CsvToListConverter().convert(csvContent);
    if (rows.isEmpty) return [];

    final customers = <Customer>[];
    // Skip header row
    for (var i = 1; i < rows.length; i++) {
      try {
        final row = rows[i];
        if (row.length < 3) continue; // Skip invalid rows

        customers.add(
          Customer(
            name: row[1].toString(),
            phone: row[2].toString(),
            address: row.length > 3 && row[3].toString().isNotEmpty
                ? row[3].toString()
                : null,
            balance: row.length > 4 ? double.parse(row[4].toString()) : 0,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } catch (e) {
        // Skip invalid rows
        continue;
      }
    }

    return customers;
  }

  /// Write CSV data to file
  static Future<File> _writeCSV(
    String filename,
    List<List<dynamic>> rows,
  ) async {
    final csv = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/${filename}_$timestamp.csv');
    return file.writeAsString(csv);
  }

  /// Get CSV template for items import
  static String getItemsTemplate() {
    const rows = [
      [
        'ID',
        'SKU',
        'Name',
        'Company',
        'Unit Price',
        'Stock',
        'Reorder Level',
        'Created At',
        'Updated At',
      ],
      [
        '',
        'ITEM001',
        'Sample Item',
        'Sample Company',
        '100.00',
        '50',
        '10',
        '',
        '',
      ],
    ];
    return const ListToCsvConverter().convert(rows);
  }

  /// Get CSV template for customers import
  static String getCustomersTemplate() {
    const rows = [
      ['ID', 'Name', 'Phone', 'Address', 'Balance', 'Created At'],
      ['', 'John Doe', '9876543210', '123 Main St', '0', ''],
    ];
    return const ListToCsvConverter().convert(rows);
  }
}
