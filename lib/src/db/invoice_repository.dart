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

  /// Simple search method for global search (search by invoice number)
  Future<List<Invoice>> search(String query) async {
    final database = await _db.database;
    final searchTerm = '%$query%';
    final maps = await database.query(
      'invoices',
      where: 'invoiceNo LIKE ?',
      whereArgs: [searchTerm],
      orderBy: 'date DESC',
      limit: 20,
    );
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

  /// Get revenue for today (total sales)
  Future<double> getTodayRevenue() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return await getTotalSales(
      startOfDay.millisecondsSinceEpoch,
      endOfDay.millisecondsSinceEpoch,
    );
  }

  /// Get revenue for this week (total sales)
  Future<double> getWeekRevenue() async {
    final now = DateTime.now();
    // Start of week (Monday)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDate = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return await getTotalSales(
      startOfWeekDate.millisecondsSinceEpoch,
      endOfDay.millisecondsSinceEpoch,
    );
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

  /// Get top selling items for a date range
  Future<List<Map<String, dynamic>>> getTopSellingItems({
    int? startDate,
    int? endDate,
    int limit = 50,
  }) async {
    final database = await _db.database;

    String dateFilter = '';
    List<dynamic> args = [];

    if (startDate != null && endDate != null) {
      dateFilter = 'WHERE i.date >= ? AND i.date <= ?';
      args = [startDate, endDate];
    }

    final result = await database.rawQuery(
      '''
      SELECT 
        it.id,
        it.name,
        it.sku,
        it.company,
        it.unitPrice,
        SUM(ii.qty) as totalQtySold,
        SUM(ii.lineTotal) as totalRevenue,
        COUNT(DISTINCT ii.invoiceId) as invoiceCount,
        AVG(ii.unitPrice) as avgSellingPrice
      FROM invoice_items ii
      INNER JOIN items it ON ii.itemId = it.id
      INNER JOIN invoices i ON ii.invoiceId = i.id
      $dateFilter
      GROUP BY it.id
      ORDER BY totalQtySold DESC
      LIMIT ?
    ''',
      [...args, limit],
    );

    return result.map((row) {
      return {
        'itemId': row['id'] as int,
        'name': row['name'] as String,
        'sku': row['sku'] as String,
        'company': row['company'] as String?,
        'unitPrice': (row['unitPrice'] as num).toDouble(),
        'totalQtySold': row['totalQtySold'] as int? ?? 0,
        'totalRevenue': (row['totalRevenue'] as num?)?.toDouble() ?? 0.0,
        'invoiceCount': row['invoiceCount'] as int? ?? 0,
        'avgSellingPrice': (row['avgSellingPrice'] as num?)?.toDouble() ?? 0.0,
      };
    }).toList();
  }

  /// Get sales by period (daily, weekly, monthly)
  Future<List<Map<String, dynamic>>> getSalesByPeriod({
    required String period, // 'day', 'week', 'month'
    int? startDate,
    int? endDate,
  }) async {
    final database = await _db.database;

    String dateFormat;
    switch (period.toLowerCase()) {
      case 'day':
        dateFormat = '%Y-%m-%d';
        break;
      case 'week':
        dateFormat = '%Y-W%W';
        break;
      case 'month':
        dateFormat = '%Y-%m';
        break;
      default:
        dateFormat = '%Y-%m-%d';
    }

    String dateFilter = '';
    List<dynamic> args = [];

    if (startDate != null && endDate != null) {
      dateFilter = 'WHERE date >= ? AND date <= ?';
      args = [startDate, endDate];
    }

    final result = await database.rawQuery('''
      SELECT 
        strftime('$dateFormat', datetime(date/1000, 'unixepoch')) as period,
        COUNT(*) as invoiceCount,
        SUM(subtotal) as totalSubtotal,
        SUM(taxAmount) as totalTax,
        SUM(total) as totalRevenue,
        SUM(paid) as totalCollected
      FROM invoices
      $dateFilter
      GROUP BY period
      ORDER BY period DESC
    ''', args);

    return result.map((row) {
      return {
        'period': row['period'] as String,
        'invoiceCount': row['invoiceCount'] as int,
        'totalSubtotal': (row['totalSubtotal'] as num?)?.toDouble() ?? 0.0,
        'totalTax': (row['totalTax'] as num?)?.toDouble() ?? 0.0,
        'totalRevenue': (row['totalRevenue'] as num?)?.toDouble() ?? 0.0,
        'totalCollected': (row['totalCollected'] as num?)?.toDouble() ?? 0.0,
      };
    }).toList();
  }

  /// Get sales by company/brand for category analysis
  Future<List<Map<String, dynamic>>> getSalesByCompany({
    int? startDate,
    int? endDate,
  }) async {
    final database = await _db.database;

    String dateFilter = '';
    List<dynamic> args = [];

    if (startDate != null && endDate != null) {
      dateFilter = 'WHERE i.date >= ? AND i.date <= ?';
      args = [startDate, endDate];
    }

    final result = await database.rawQuery('''
      SELECT 
        it.company,
        COUNT(DISTINCT ii.invoiceId) as invoiceCount,
        SUM(ii.qty) as totalQtySold,
        SUM(ii.lineTotal) as totalRevenue,
        COUNT(DISTINCT it.id) as uniqueItems
      FROM invoice_items ii
      INNER JOIN items it ON ii.itemId = it.id
      INNER JOIN invoices i ON ii.invoiceId = i.id
      $dateFilter
      WHERE it.company IS NOT NULL AND it.company != ''
      GROUP BY it.company
      ORDER BY totalRevenue DESC
    ''', args);

    return result.map((row) {
      return {
        'company': row['company'] as String,
        'invoiceCount': row['invoiceCount'] as int? ?? 0,
        'totalQtySold': row['totalQtySold'] as int? ?? 0,
        'totalRevenue': (row['totalRevenue'] as num?)?.toDouble() ?? 0.0,
        'uniqueItems': row['uniqueItems'] as int? ?? 0,
      };
    }).toList();
  }

  /// Get customer purchase summary
  Future<List<Map<String, dynamic>>> getCustomerPurchaseSummary({
    int? startDate,
    int? endDate,
    int limit = 50,
  }) async {
    final database = await _db.database;

    String dateFilter = '';
    List<dynamic> args = [];

    if (startDate != null && endDate != null) {
      dateFilter = 'AND i.date >= ? AND i.date <= ?';
      args.addAll([startDate, endDate]);
    }

    args.add(limit);

    final result = await database.rawQuery('''
      SELECT 
        c.id,
        c.name,
        c.phone,
        c.balance,
        COUNT(i.id) as invoiceCount,
        SUM(i.total) as totalRevenue,
        SUM(i.paid) as totalPaid,
        AVG(i.total) as avgOrderValue,
        MAX(i.date) as lastPurchaseDate
      FROM customers c
      INNER JOIN invoices i ON c.id = i.customerId
      WHERE i.customerId IS NOT NULL $dateFilter
      GROUP BY c.id
      ORDER BY totalRevenue DESC
      LIMIT ?
    ''', args);

    return result.map((row) {
      return {
        'customerId': row['id'] as int,
        'name': row['name'] as String,
        'phone': row['phone'] as String,
        'balance': (row['balance'] as num).toDouble(),
        'invoiceCount': row['invoiceCount'] as int? ?? 0,
        'totalRevenue': (row['totalRevenue'] as num?)?.toDouble() ?? 0.0,
        'totalPaid': (row['totalPaid'] as num?)?.toDouble() ?? 0.0,
        'avgOrderValue': (row['avgOrderValue'] as num?)?.toDouble() ?? 0.0,
        'lastPurchaseDate': row['lastPurchaseDate'] as int,
      };
    }).toList();
  }

  /// Get daily sales data for a date range (for charts)
  Future<List<Map<String, dynamic>>> getDailySales({
    required int startDate,
    required int endDate,
  }) async {
    final database = await _db.database;

    final result = await database.rawQuery(
      '''
      SELECT 
        date,
        COUNT(*) as invoiceCount,
        SUM(total) as totalSales,
        SUM(paid) as totalPaid,
        AVG(total) as avgSale
      FROM invoices
      WHERE date >= ? AND date <= ?
      GROUP BY date
      ORDER BY date ASC
    ''',
      [startDate, endDate],
    );

    return result.map((row) {
      return {
        'date': row['date'] as int,
        'invoiceCount': row['invoiceCount'] as int,
        'totalSales': (row['totalSales'] as num).toDouble(),
        'totalPaid': (row['totalPaid'] as num).toDouble(),
        'avgSale': (row['avgSale'] as num).toDouble(),
      };
    }).toList();
  }

  /// Get sales by hour (for daily pattern analysis)
  Future<List<Map<String, dynamic>>> getSalesByHour(int date) async {
    final database = await _db.database;

    // Get all invoices for the day
    final startOfDay = DateTime.fromMillisecondsSinceEpoch(date);
    final endOfDay = DateTime(
      startOfDay.year,
      startOfDay.month,
      startOfDay.day,
      23,
      59,
      59,
    );

    final invoices = await database.query(
      'invoices',
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
    );

    // Group by hour
    final Map<int, double> hourlyMap = {};
    for (var row in invoices) {
      final invoiceDate = row['date'] as int;
      final dateTime = DateTime.fromMillisecondsSinceEpoch(invoiceDate);
      final hour = dateTime.hour;
      final total = (row['total'] as num).toDouble();
      hourlyMap[hour] = (hourlyMap[hour] ?? 0) + total;
    }

    // Convert to list
    return List.generate(24, (hour) {
      return {'hour': hour, 'total': hourlyMap[hour] ?? 0.0};
    });
  }

  /// Get sales trends (last 7 days, 30 days, etc.)
  Future<Map<String, dynamic>> getSalesTrends(int days) async {
    final database = await _db.database;
    final now = DateTime.now();
    final startDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days)).millisecondsSinceEpoch;
    final endDate = DateTime.now().millisecondsSinceEpoch;

    final result = await database.rawQuery(
      '''
      SELECT 
        COUNT(*) as totalInvoices,
        SUM(total) as totalSales,
        SUM(paid) as totalPaid,
        AVG(total) as avgSale,
        MIN(total) as minSale,
        MAX(total) as maxSale
      FROM invoices
      WHERE date >= ? AND date <= ?
    ''',
      [startDate, endDate],
    );

    if (result.isEmpty) {
      return {
        'totalInvoices': 0,
        'totalSales': 0.0,
        'totalPaid': 0.0,
        'avgSale': 0.0,
        'minSale': 0.0,
        'maxSale': 0.0,
      };
    }

    final row = result.first;
    return {
      'totalInvoices': row['totalInvoices'] as int,
      'totalSales': (row['totalSales'] as num?)?.toDouble() ?? 0.0,
      'totalPaid': (row['totalPaid'] as num?)?.toDouble() ?? 0.0,
      'avgSale': (row['avgSale'] as num?)?.toDouble() ?? 0.0,
      'minSale': (row['minSale'] as num?)?.toDouble() ?? 0.0,
      'maxSale': (row['maxSale'] as num?)?.toDouble() ?? 0.0,
    };
  }
}
