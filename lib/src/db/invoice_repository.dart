import 'package:sqflite/sqflite.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import 'database_helper.dart';

/// Repository for Invoice CRUD operations
class InvoiceRepository {
  final ERPDatabase _db = ERPDatabase();

  /// Insert a new invoice with items (atomic transaction)
  Future<int> insertWithItems(Invoice invoice, List<InvoiceItem> items) async {
    final database = await _db.database;

    return await database.transaction((txn) async {
      // Insert invoice
      final invoiceId = await txn.insert('invoices', invoice.toMap());

      // Insert invoice items and decrement stock
      for (var item in items) {
        final itemWithInvoiceId = item.copyWith(invoiceId: invoiceId);
        await txn.insert('invoice_items', itemWithInvoiceId.toMap());

        // Decrement stock for each item
        await txn.rawUpdate(
          '''
          UPDATE items 
          SET stock = stock - ?, updatedAt = ? 
          WHERE id = ?
          ''',
          [item.qty, DateTime.now().millisecondsSinceEpoch, item.itemId],
        );

        // Log the stock change
        await txn.insert('change_logs', {
          'entity': 'Item',
          'entityId': item.itemId,
          'action': 'update',
          'payload':
              '{"field":"stock","change":-${item.qty},"reason":"Invoice #${invoice.invoiceNo}"}',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'synced': 0,
        });
      }

      // Update customer balance if customer is specified
      if (invoice.customerId != null) {
        final balance = invoice.total - invoice.paid;
        if (balance > 0) {
          await txn.rawUpdate(
            '''
            UPDATE customers 
            SET balance = balance + ?, updatedAt = ? 
            WHERE id = ?
          ''',
            [
              balance,
              DateTime.now().millisecondsSinceEpoch,
              invoice.customerId,
            ],
          );
        }
      }

      return invoiceId;
    });
  }

  /// Update an existing invoice
  Future<int> update(Invoice invoice) async {
    final database = await _db.database;
    return await database.update(
      'invoices',
      invoice.toMap(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
  }

  /// Delete an invoice by id (cascade deletes invoice items)
  Future<int> delete(int id) async {
    final database = await _db.database;
    return await database.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }

  /// Get invoice by id
  Future<Invoice?> getById(int id) async {
    final database = await _db.database;
    final maps = await database.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Invoice.fromMap(maps.first);
  }

  /// Get invoice by invoice number
  Future<Invoice?> getByInvoiceNo(String invoiceNo) async {
    final database = await _db.database;
    final maps = await database.query(
      'invoices',
      where: 'invoiceNo = ?',
      whereArgs: [invoiceNo],
    );

    if (maps.isEmpty) return null;
    return Invoice.fromMap(maps.first);
  }

  /// Get invoice items for a specific invoice
  Future<List<InvoiceItem>> getInvoiceItems(int invoiceId) async {
    final database = await _db.database;
    final maps = await database.query(
      'invoice_items',
      where: 'invoiceId = ?',
      whereArgs: [invoiceId],
    );

    return maps.map((map) => InvoiceItem.fromMap(map)).toList();
  }

  /// Get invoice items with item details (JOIN query)
  Future<List<Map<String, dynamic>>> getInvoiceItemsWithDetails(
    int invoiceId,
  ) async {
    final database = await _db.database;
    return await database.rawQuery(
      '''
      SELECT 
        ii.*,
        i.sku as itemSku,
        i.name as itemName,
        i.company as itemCompany
      FROM invoice_items ii
      INNER JOIN items i ON ii.itemId = i.id
      WHERE ii.invoiceId = ?
    ''',
      [invoiceId],
    );
  }

  /// Get all invoices
  Future<List<Invoice>> getAll({int limit = 100, int offset = 0}) async {
    final database = await _db.database;
    final maps = await database.query(
      'invoices',
      orderBy: 'date DESC, createdAt DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => Invoice.fromMap(map)).toList();
  }

  /// Get invoices by customer
  Future<List<Invoice>> getByCustomer(int customerId) async {
    final database = await _db.database;
    final maps = await database.query(
      'invoices',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Invoice.fromMap(map)).toList();
  }

  /// Get invoices by date range
  Future<List<Invoice>> getByDateRange(int startDate, int endDate) async {
    final database = await _db.database;
    final maps = await database.query(
      'invoices',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Invoice.fromMap(map)).toList();
  }

  /// Get unpaid or partially paid invoices
  Future<List<Invoice>> getUnpaidInvoices() async {
    final database = await _db.database;
    final maps = await database.rawQuery('''
      SELECT * FROM invoices 
      WHERE paid < total 
      ORDER BY date DESC
    ''');
    return maps.map((map) => Invoice.fromMap(map)).toList();
  }

  /// Update payment for an invoice
  Future<bool> updatePayment(int invoiceId, double newPaidAmount) async {
    final database = await _db.database;

    return await database.transaction((txn) async {
      // Get current invoice
      final maps = await txn.query(
        'invoices',
        where: 'id = ?',
        whereArgs: [invoiceId],
      );

      if (maps.isEmpty) return false;

      final invoice = Invoice.fromMap(maps.first);
      final oldBalance = invoice.total - invoice.paid;
      final newBalance = invoice.total - newPaidAmount;
      final balanceChange = oldBalance - newBalance;

      // Update invoice payment
      await txn.update(
        'invoices',
        {'paid': newPaidAmount},
        where: 'id = ?',
        whereArgs: [invoiceId],
      );

      // Update customer balance if customer is specified
      if (invoice.customerId != null && balanceChange != 0) {
        await txn.rawUpdate(
          '''
          UPDATE customers 
          SET balance = balance - ?, updatedAt = ? 
          WHERE id = ?
        ''',
          [
            balanceChange,
            DateTime.now().millisecondsSinceEpoch,
            invoice.customerId,
          ],
        );
      }

      return true;
    });
  }

  /// Search invoices by invoice number or customer name
  Future<List<Map<String, dynamic>>> searchInvoices({
    String? query,
    int limit = 50,
    int offset = 0,
  }) async {
    final database = await _db.database;

    if (query == null || query.isEmpty) {
      return await database.rawQuery(
        '''
        SELECT 
          i.*,
          c.name as customerName,
          c.phone as customerPhone
        FROM invoices i
        LEFT JOIN customers c ON i.customerId = c.id
        ORDER BY i.date DESC, i.createdAt DESC
        LIMIT ? OFFSET ?
      ''',
        [limit, offset],
      );
    }

    final searchTerm = '%$query%';
    return await database.rawQuery(
      '''
      SELECT 
        i.*,
        c.name as customerName,
        c.phone as customerPhone
      FROM invoices i
      LEFT JOIN customers c ON i.customerId = c.id
      WHERE i.invoiceNo LIKE ? OR c.name LIKE ?
      ORDER BY i.date DESC, i.createdAt DESC
      LIMIT ? OFFSET ?
    ''',
      [searchTerm, searchTerm, limit, offset],
    );
  }

  /// Get total invoice count
  Future<int> getCount() async {
    final database = await _db.database;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM invoices',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get total sales for a date range
  Future<double> getTotalSales(int startDate, int endDate) async {
    final database = await _db.database;
    final result = await database.rawQuery(
      '''
      SELECT SUM(total) as total 
      FROM invoices 
      WHERE date >= ? AND date <= ?
    ''',
      [startDate, endDate],
    );

    final total = result.first['total'];
    return total != null ? (total as num).toDouble() : 0.0;
  }

  /// Get total collected amount for a date range
  Future<double> getTotalCollected(int startDate, int endDate) async {
    final database = await _db.database;
    final result = await database.rawQuery(
      '''
      SELECT SUM(paid) as total 
      FROM invoices 
      WHERE date >= ? AND date <= ?
    ''',
      [startDate, endDate],
    );

    final total = result.first['total'];
    return total != null ? (total as num).toDouble() : 0.0;
  }

  /// Check if invoice number exists
  Future<bool> invoiceNoExists(String invoiceNo, {int? excludeId}) async {
    final database = await _db.database;

    List<Map<String, dynamic>> maps;
    if (excludeId != null) {
      maps = await database.query(
        'invoices',
        columns: ['id'],
        where: 'invoiceNo = ? AND id != ?',
        whereArgs: [invoiceNo, excludeId],
      );
    } else {
      maps = await database.query(
        'invoices',
        columns: ['id'],
        where: 'invoiceNo = ?',
        whereArgs: [invoiceNo],
      );
    }

    return maps.isNotEmpty;
  }

  /// Generate next invoice number
  Future<String> generateNextInvoiceNo() async {
    final database = await _db.database;
    final result = await database.rawQuery('''
      SELECT invoiceNo FROM invoices 
      ORDER BY createdAt DESC 
      LIMIT 1
    ''');

    if (result.isEmpty) {
      return 'INV-0001';
    }

    final lastInvoiceNo = result.first['invoiceNo'] as String;
    // Extract number from format INV-XXXX
    final parts = lastInvoiceNo.split('-');
    if (parts.length == 2) {
      final number = int.tryParse(parts[1]) ?? 0;
      return 'INV-${(number + 1).toString().padLeft(4, '0')}';
    }

    return 'INV-0001';
  }

  /// Get GST summary for a date range
  Future<Map<String, dynamic>> getGstSummary(int startDate, int endDate) async {
    final database = await _db.database;
    final result = await database.rawQuery(
      '''
      SELECT 
        COUNT(*) as invoiceCount,
        SUM(subtotal) as totalSubtotal,
        SUM(taxAmount) as totalTax,
        SUM(total) as totalAmount
      FROM invoices 
      WHERE date >= ? AND date <= ?
    ''',
      [startDate, endDate],
    );

    if (result.isEmpty || result.first['invoiceCount'] == 0) {
      return {
        'invoiceCount': 0,
        'totalSubtotal': 0.0,
        'totalTax': 0.0,
        'totalAmount': 0.0,
      };
    }

    final row = result.first;
    return {
      'invoiceCount': row['invoiceCount'] as int,
      'totalSubtotal': (row['totalSubtotal'] as num?)?.toDouble() ?? 0.0,
      'totalTax': (row['totalTax'] as num?)?.toDouble() ?? 0.0,
      'totalAmount': (row['totalAmount'] as num?)?.toDouble() ?? 0.0,
    };
  }

  /// Get GST breakdown by tax rate for a date range
  Future<List<Map<String, dynamic>>> getGstBreakdownByRate(
    int startDate,
    int endDate,
  ) async {
    final database = await _db.database;
    final result = await database.rawQuery(
      '''
      SELECT 
        taxRate,
        COUNT(*) as invoiceCount,
        SUM(subtotal) as totalSubtotal,
        SUM(taxAmount) as totalTax,
        SUM(total) as totalAmount
      FROM invoices 
      WHERE date >= ? AND date <= ?
      GROUP BY taxRate
      ORDER BY taxRate DESC
    ''',
      [startDate, endDate],
    );

    return result.map((row) {
      return {
        'taxRate': (row['taxRate'] as num?)?.toDouble() ?? 0.0,
        'invoiceCount': row['invoiceCount'] as int,
        'totalSubtotal': (row['totalSubtotal'] as num?)?.toDouble() ?? 0.0,
        'totalTax': (row['totalTax'] as num?)?.toDouble() ?? 0.0,
        'totalAmount': (row['totalAmount'] as num?)?.toDouble() ?? 0.0,
      };
    }).toList();
  }

  /// Get monthly GST summary for the last N months
  Future<List<Map<String, dynamic>>> getMonthlyGstSummary(int months) async {
    final database = await _db.database;
    final now = DateTime.now();
    final startDate = DateTime(
      now.year,
      now.month - months + 1,
      1,
    ).millisecondsSinceEpoch;

    final result = await database.rawQuery(
      '''
      SELECT 
        strftime('%Y-%m', datetime(date/1000, 'unixepoch')) as month,
        COUNT(*) as invoiceCount,
        SUM(subtotal) as totalSubtotal,
        SUM(taxAmount) as totalTax,
        SUM(total) as totalAmount
      FROM invoices 
      WHERE date >= ?
      GROUP BY month
      ORDER BY month DESC
    ''',
      [startDate],
    );

    return result.map((row) {
      return {
        'month': row['month'] as String,
        'invoiceCount': row['invoiceCount'] as int,
        'totalSubtotal': (row['totalSubtotal'] as num?)?.toDouble() ?? 0.0,
        'totalTax': (row['totalTax'] as num?)?.toDouble() ?? 0.0,
        'totalAmount': (row['totalAmount'] as num?)?.toDouble() ?? 0.0,
      };
    }).toList();
  }
}
