import 'package:riverpod/riverpod.dart';
import '../db/database_helper.dart';
import '../db/item_repository.dart';
import '../db/customer_repository.dart';
import '../db/invoice_repository.dart';
import '../db/settings_repository.dart';

/// Provider for database instance
final databaseProvider = Provider<ERPDatabase>((ref) {
  return ERPDatabase();
});

/// Provider for ItemRepository
final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository();
});

/// Provider for CustomerRepository
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

/// Provider for InvoiceRepository
final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository();
});

/// Provider for SettingsRepository
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SettingsRepository(db);
});
