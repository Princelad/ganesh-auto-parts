import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import '../db/item_repository.dart';
import 'database_provider.dart';

/// Notifier for managing items
class ItemNotifier extends Notifier<AsyncValue<List<Item>>> {
  late final ItemRepository _repository;

  @override
  AsyncValue<List<Item>> build() {
    _repository = ref.read(itemRepositoryProvider);
    loadItems();
    return const AsyncValue.loading();
  }

  /// Load all items
  Future<void> loadItems() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repository.getAll();
      state = AsyncValue.data(items);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Search items
  Future<void> searchItems(String query) async {
    state = const AsyncValue.loading();
    try {
      final items = await _repository.searchItems(query: query);
      state = AsyncValue.data(items);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Add new item
  Future<bool> addItem(Item item) async {
    try {
      // Check if SKU exists
      final exists = await _repository.skuExists(item.sku);
      if (exists) {
        return false;
      }

      await _repository.insert(item);
      await loadItems();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update existing item
  Future<bool> updateItem(Item item) async {
    try {
      // Check if SKU exists (excluding current item)
      if (item.id != null) {
        final exists = await _repository.skuExists(
          item.sku,
          excludeId: item.id,
        );
        if (exists) {
          return false;
        }
      }

      await _repository.update(item);
      await loadItems();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete item
  Future<bool> deleteItem(int id) async {
    try {
      await _repository.delete(id);
      await loadItems();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update stock
  Future<bool> updateStock(int itemId, int newStock) async {
    try {
      final success = await _repository.updateStock(itemId, newStock);
      if (success) {
        await loadItems();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Increment stock
  Future<bool> incrementStock(int itemId, int quantity) async {
    try {
      final success = await _repository.incrementStock(itemId, quantity);
      if (success) {
        await loadItems();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Decrement stock
  Future<bool> decrementStock(int itemId, int quantity) async {
    try {
      final success = await _repository.decrementStock(itemId, quantity);
      if (success) {
        await loadItems();
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}

/// Provider for item list state
final itemProvider = NotifierProvider<ItemNotifier, AsyncValue<List<Item>>>(
  ItemNotifier.new,
);

/// Provider for low stock items
final lowStockItemsProvider = FutureProvider<List<Item>>((ref) async {
  final repository = ref.watch(itemRepositoryProvider);
  return await repository.getLowStockItems();
});

/// Provider for item count
final itemCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(itemRepositoryProvider);
  return await repository.getCount();
});

/// Provider for single item by id
final itemByIdProvider = FutureProvider.family<Item?, int>((ref, id) async {
  final repository = ref.watch(itemRepositoryProvider);
  return await repository.getById(id);
});
