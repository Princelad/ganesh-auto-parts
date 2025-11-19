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
}
