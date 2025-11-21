import 'package:flutter_test/flutter_test.dart';
import 'package:ganesh_auto_parts/src/models/item.dart';
import 'package:ganesh_auto_parts/src/db/database_helper.dart';
import 'package:ganesh_auto_parts/src/db/item_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Integration tests for Inventory Management flow
///
/// Tests the complete lifecycle of inventory items:
/// - Adding new items
/// - Updating existing items
/// - Stock adjustments
/// - Low stock detection
/// - Searching and filtering
/// - Deletion
void main() {
  late ERPDatabase database;
  late ItemRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Delete any existing test database first
    try {
      await databaseFactoryFfi.deleteDatabase('erp_db.sqlite');
    } catch (e) {
      // Ignore if database doesn't exist
    }

    // Create a fresh database for each test
    database = ERPDatabase();
    await database.database; // Initialize database
    repository = ItemRepository();
  });

  tearDown(() async {
    await database.close();
    // Delete the test database to ensure clean state for next test
    await databaseFactoryFfi.deleteDatabase('erp_db.sqlite');
  });

  group('Inventory Management Flow', () {
    test('Add new item successfully', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final item = Item(
        sku: 'PART-001',
        name: 'Brake Pad',
        company: 'Bosch',
        unitPrice: 500.0,
        stock: 20,
        reorderLevel: 5,
        createdAt: now,
        updatedAt: now,
      );

      final id = await repository.insert(item);
      expect(id, greaterThan(0));

      // Verify item was added
      final retrievedItem = await repository.getById(id);
      expect(retrievedItem, isNotNull);
      expect(retrievedItem!.sku, 'PART-001');
      expect(retrievedItem.name, 'Brake Pad');
      expect(retrievedItem.stock, 20);
    });

    test('Prevent duplicate SKU', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final item1 = Item(
        sku: 'PART-001',
        name: 'Brake Pad',
        unitPrice: 500.0,
        stock: 20,
        reorderLevel: 5,
        createdAt: now,
        updatedAt: now,
      );

      await repository.insert(item1);

      // Try to add another item with same SKU
      final exists = await repository.skuExists('PART-001');
      expect(exists, isTrue);
    });

    test('Update item successfully', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final item = Item(
        sku: 'PART-001',
        name: 'Brake Pad',
        unitPrice: 500.0,
        stock: 20,
        reorderLevel: 5,
        createdAt: now,
        updatedAt: now,
      );

      final id = await repository.insert(item);

      // Update the item
      final updatedItem = item.copyWith(
        id: id,
        name: 'Brake Pad Premium',
        unitPrice: 650.0,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await repository.update(updatedItem);

      // Verify update
      final retrieved = await repository.getById(id);
      expect(retrieved!.name, 'Brake Pad Premium');
      expect(retrieved.unitPrice, 650.0);
      expect(retrieved.stock, 20); // Stock unchanged
    });

    test('Stock adjustment - increment', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final item = Item(
        sku: 'PART-001',
        name: 'Brake Pad',
        unitPrice: 500.0,
        stock: 20,
        reorderLevel: 5,
        createdAt: now,
        updatedAt: now,
      );

      final id = await repository.insert(item);

      // Increment stock by 10
      final success = await repository.incrementStock(id, 10);
      expect(success, isTrue);

      // Verify stock increased
      final updated = await repository.getById(id);
      expect(updated!.stock, 30);
    });

    test('Stock adjustment - decrement', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final item = Item(
        sku: 'PART-001',
        name: 'Brake Pad',
        unitPrice: 500.0,
        stock: 20,
        reorderLevel: 5,
        createdAt: now,
        updatedAt: now,
      );

      final id = await repository.insert(item);

      // Decrement stock by 5
      final success = await repository.decrementStock(id, 5);
      expect(success, isTrue);

      // Verify stock decreased
      final updated = await repository.getById(id);
      expect(updated!.stock, 15);
    });

    test('Low stock detection', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Add item with stock below reorder level
      final lowStockItem = Item(
        sku: 'PART-001',
        name: 'Brake Pad',
        unitPrice: 500.0,
        stock: 3,
        reorderLevel: 5,
        createdAt: now,
        updatedAt: now,
      );

      // Add item with adequate stock
      final normalStockItem = Item(
        sku: 'PART-002',
        name: 'Oil Filter',
        unitPrice: 200.0,
        stock: 20,
        reorderLevel: 5,
        createdAt: now,
        updatedAt: now,
      );

      await repository.insert(lowStockItem);
      await repository.insert(normalStockItem);

      // Get low stock items
      final lowStockItems = await repository.getLowStockItems();
      expect(lowStockItems.length, 1);
      expect(lowStockItems.first.sku, 'PART-001');
    });

    test('Search items by name', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await repository.insert(
        Item(
          sku: 'PART-001',
          name: 'Brake Pad',
          unitPrice: 500.0,
          stock: 20,
          reorderLevel: 5,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await repository.insert(
        Item(
          sku: 'PART-002',
          name: 'Brake Disc',
          unitPrice: 1500.0,
          stock: 10,
          reorderLevel: 3,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await repository.insert(
        Item(
          sku: 'PART-003',
          name: 'Oil Filter',
          unitPrice: 200.0,
          stock: 30,
          reorderLevel: 10,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Search for "brake"
      final brakeItems = await repository.searchItems(query: 'brake');
      expect(brakeItems.length, 2);

      // Search by SKU
      final skuItems = await repository.searchItems(query: 'PART-003');
      expect(skuItems.length, 1);
      expect(skuItems.first.name, 'Oil Filter');
    });

    test('Delete item', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final item = Item(
        sku: 'PART-001',
        name: 'Brake Pad',
        unitPrice: 500.0,
        stock: 20,
        reorderLevel: 5,
        createdAt: now,
        updatedAt: now,
      );

      final id = await repository.insert(item);

      // Delete the item
      await repository.delete(id);

      // Verify deletion
      final deleted = await repository.getById(id);
      expect(deleted, isNull);
    });

    test('Get item count', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Initially should be 0
      var count = await repository.getCount();
      expect(count, 0);

      // Add 3 items
      for (int i = 1; i <= 3; i++) {
        await repository.insert(
          Item(
            sku: 'PART-00$i',
            name: 'Item $i',
            unitPrice: 100.0 * i,
            stock: 10,
            reorderLevel: 5,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      count = await repository.getCount();
      expect(count, 3);
    });

    test('Stock cannot go negative', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final item = Item(
        sku: 'PART-001',
        name: 'Brake Pad',
        unitPrice: 500.0,
        stock: 5,
        reorderLevel: 5,
        createdAt: now,
        updatedAt: now,
      );

      final id = await repository.insert(item);

      // Try to decrement more than available stock
      final success = await repository.decrementStock(id, 10);
      expect(success, isFalse);

      // Verify stock unchanged
      final retrieved = await repository.getById(id);
      expect(retrieved!.stock, 5);
    });
  });
}
