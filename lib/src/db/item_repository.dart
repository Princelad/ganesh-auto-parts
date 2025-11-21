import 'package:sqflite/sqflite.dart';
import '../models/item.dart';
import 'database_helper.dart';

/// Repository for Item CRUD operations
class ItemRepository {
  final ERPDatabase _db = ERPDatabase();

  /// Insert a new item
  Future<int> insert(Item item) async {
    final database = await _db.database;
    return await database.insert('items', item.toMap());
  }

  /// Update an existing item
  Future<int> update(Item item) async {
    final database = await _db.database;
    return await database.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Delete an item by id
  Future<int> delete(int id) async {
    final database = await _db.database;
    return await database.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  /// Get item by id
  Future<Item?> getById(int id) async {
    final database = await _db.database;
    final maps = await database.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Item.fromMap(maps.first);
  }

  /// Get item by SKU
  Future<Item?> getBySku(String sku) async {
    final database = await _db.database;
    final maps = await database.query(
      'items',
      where: 'sku = ?',
      whereArgs: [sku],
    );

    if (maps.isEmpty) return null;
    return Item.fromMap(maps.first);
  }

  /// Get all items
  Future<List<Item>> getAll() async {
    final database = await _db.database;
    final maps = await database.query('items', orderBy: 'name ASC');
    return maps.map((map) => Item.fromMap(map)).toList();
  }

  /// Search items by name or SKU with pagination
  Future<List<Item>> searchItems({
    String? query,
    int limit = 50,
    int offset = 0,
  }) async {
    final database = await _db.database;

    if (query == null || query.isEmpty) {
      final maps = await database.query(
        'items',
        orderBy: 'name ASC',
        limit: limit,
        offset: offset,
      );
      return maps.map((map) => Item.fromMap(map)).toList();
    }

    final searchTerm = '%$query%';
    final maps = await database.query(
      'items',
      where: 'name LIKE ? OR sku LIKE ? OR company LIKE ?',
      whereArgs: [searchTerm, searchTerm, searchTerm],
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => Item.fromMap(map)).toList();
  }

  /// Simple search method for global search
  Future<List<Item>> search(String query) async {
    return await searchItems(query: query, limit: 20);
  }

  /// Get items with low stock (below reorder level)
  Future<List<Item>> getLowStockItems() async {
    final database = await _db.database;
    final maps = await database.rawQuery('''
      SELECT * FROM items 
      WHERE stock <= reorderLevel 
      ORDER BY stock ASC
    ''');
    return maps.map((map) => Item.fromMap(map)).toList();
  }

  /// Get items by company
  Future<List<Item>> getByCompany(String company) async {
    final database = await _db.database;
    final maps = await database.query(
      'items',
      where: 'company = ?',
      whereArgs: [company],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Item.fromMap(map)).toList();
  }

  /// Decrement stock (with transaction for atomicity)
  Future<bool> decrementStock(int itemId, int quantity) async {
    final database = await _db.database;

    return await database.transaction((txn) async {
      // Get current stock
      final maps = await txn.query(
        'items',
        columns: ['stock'],
        where: 'id = ?',
        whereArgs: [itemId],
      );

      if (maps.isEmpty) return false;

      final currentStock = maps.first['stock'] as int;

      // Check if sufficient stock
      if (currentStock < quantity) return false;

      // Update stock
      final updateCount = await txn.rawUpdate(
        '''
        UPDATE items 
        SET stock = stock - ?, updatedAt = ? 
        WHERE id = ?
      ''',
        [quantity, DateTime.now().millisecondsSinceEpoch, itemId],
      );

      return updateCount > 0;
    });
  }

  /// Increment stock (for stock adjustments)
  Future<bool> incrementStock(int itemId, int quantity) async {
    final database = await _db.database;

    final updateCount = await database.rawUpdate(
      '''
      UPDATE items 
      SET stock = stock + ?, updatedAt = ? 
      WHERE id = ?
    ''',
      [quantity, DateTime.now().millisecondsSinceEpoch, itemId],
    );

    return updateCount > 0;
  }

  /// Update stock directly
  Future<bool> updateStock(int itemId, int newStock) async {
    final database = await _db.database;

    final updateCount = await database.update(
      'items',
      {'stock': newStock, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [itemId],
    );

    return updateCount > 0;
  }

  /// Get total item count
  Future<int> getCount() async {
    final database = await _db.database;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM items',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Check if SKU exists
  Future<bool> skuExists(String sku, {int? excludeId}) async {
    final database = await _db.database;

    List<Map<String, dynamic>> maps;
    if (excludeId != null) {
      maps = await database.query(
        'items',
        columns: ['id'],
        where: 'sku = ? AND id != ?',
        whereArgs: [sku, excludeId],
      );
    } else {
      maps = await database.query(
        'items',
        columns: ['id'],
        where: 'sku = ?',
        whereArgs: [sku],
      );
    }

    return maps.isNotEmpty;
  }

  /// Get stock valuation summary
  Future<Map<String, dynamic>> getStockValuationSummary() async {
    final database = await _db.database;
    final result = await database.rawQuery('''
      SELECT 
        COUNT(*) as itemCount,
        SUM(stock) as totalStock,
        SUM(stock * unitPrice) as totalValue,
        SUM(CASE WHEN stock <= reorderLevel THEN stock * unitPrice ELSE 0 END) as lowStockValue
      FROM items
    ''');

    if (result.isEmpty) {
      return {
        'itemCount': 0,
        'totalStock': 0,
        'totalValue': 0.0,
        'lowStockValue': 0.0,
      };
    }

    final row = result.first;
    return {
      'itemCount': row['itemCount'] as int,
      'totalStock': row['totalStock'] as int? ?? 0,
      'totalValue': (row['totalValue'] as num?)?.toDouble() ?? 0.0,
      'lowStockValue': (row['lowStockValue'] as num?)?.toDouble() ?? 0.0,
    };
  }

  /// Get stock valuation by company
  Future<List<Map<String, dynamic>>> getStockValuationByCompany() async {
    final database = await _db.database;
    final result = await database.rawQuery('''
      SELECT 
        company,
        COUNT(*) as itemCount,
        SUM(stock) as totalStock,
        SUM(stock * unitPrice) as totalValue
      FROM items
      WHERE company IS NOT NULL AND company != ''
      GROUP BY company
      ORDER BY totalValue DESC
    ''');

    return result.map((row) {
      return {
        'company': row['company'] as String,
        'itemCount': row['itemCount'] as int,
        'totalStock': row['totalStock'] as int? ?? 0,
        'totalValue': (row['totalValue'] as num?)?.toDouble() ?? 0.0,
      };
    }).toList();
  }

  /// Get all unique companies
  Future<List<String>> getAllCompanies() async {
    final database = await _db.database;
    final result = await database.rawQuery('''
      SELECT DISTINCT company 
      FROM items 
      WHERE company IS NOT NULL AND company != ''
      ORDER BY company ASC
    ''');

    return result.map((row) => row['company'] as String).toList();
  }

  /// Get top selling items (for charts)
  Future<List<Map<String, dynamic>>> getTopSellingItems({
    required int limit,
    int? startDate,
    int? endDate,
  }) async {
    final database = await _db.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause = 'WHERE i.date >= ? AND i.date <= ?';
      whereArgs = [startDate, endDate];
    }

    final result = await database.rawQuery(
      '''
      SELECT 
        it.id,
        it.name,
        it.sku,
        it.company,
        it.unitPrice,
        SUM(ii.qty) as totalQuantity,
        SUM(ii.lineTotal) as totalRevenue,
        COUNT(DISTINCT ii.invoiceId) as invoiceCount
      FROM items it
      INNER JOIN invoice_items ii ON it.id = ii.itemId
      INNER JOIN invoices i ON ii.invoiceId = i.id
      $whereClause
      GROUP BY it.id
      ORDER BY totalQuantity DESC
      LIMIT ?
    ''',
      [...whereArgs, limit],
    );

    return result.map((row) {
      return {
        'itemId': row['id'] as int,
        'name': row['name'] as String,
        'sku': row['sku'] as String,
        'company': row['company'] as String?,
        'unitPrice': (row['unitPrice'] as num).toDouble(),
        'totalQuantity': (row['totalQuantity'] as num).toDouble(),
        'totalRevenue': (row['totalRevenue'] as num).toDouble(),
        'invoiceCount': row['invoiceCount'] as int,
      };
    }).toList();
  }

  /// Get sales by company (for pie charts)
  Future<List<Map<String, dynamic>>> getSalesByCompany({
    int? startDate,
    int? endDate,
  }) async {
    final database = await _db.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause = 'WHERE i.date >= ? AND i.date <= ?';
      whereArgs = [startDate, endDate];
    }

    final result = await database.rawQuery('''
      SELECT 
        COALESCE(it.company, 'Unknown') as company,
        SUM(ii.qty) as totalQuantity,
        SUM(ii.lineTotal) as totalRevenue,
        COUNT(DISTINCT ii.invoiceId) as invoiceCount,
        COUNT(DISTINCT it.id) as itemCount
      FROM items it
      INNER JOIN invoice_items ii ON it.id = ii.itemId
      INNER JOIN invoices i ON ii.invoiceId = i.id
      $whereClause
      GROUP BY it.company
      ORDER BY totalRevenue DESC
    ''', whereArgs);

    return result.map((row) {
      return {
        'company': row['company'] as String,
        'totalQuantity': (row['totalQuantity'] as num).toDouble(),
        'totalRevenue': (row['totalRevenue'] as num).toDouble(),
        'invoiceCount': row['invoiceCount'] as int,
        'itemCount': row['itemCount'] as int,
      };
    }).toList();
  }
}
