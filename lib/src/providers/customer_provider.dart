import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../db/customer_repository.dart';
import 'database_provider.dart';

/// Notifier for managing customers
class CustomerNotifier extends Notifier<AsyncValue<List<Customer>>> {
  CustomerRepository get _repository => ref.read(customerRepositoryProvider);

  @override
  AsyncValue<List<Customer>> build() {
    // Load customers immediately and return the result
    _loadInitialCustomers();
    return const AsyncValue.loading();
  }

  /// Load initial customers (called from build)
  Future<void> _loadInitialCustomers() async {
    try {
      final customers = await _repository.getAll();
      state = AsyncValue.data(customers);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Load all customers
  Future<void> loadCustomers() async {
    state = const AsyncValue.loading();
    try {
      final customers = await _repository.getAll();
      state = AsyncValue.data(customers);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Search customers
  Future<void> searchCustomers(String query) async {
    state = const AsyncValue.loading();
    try {
      final customers = await _repository.searchCustomers(query: query);
      state = AsyncValue.data(customers);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Add new customer
  Future<bool> addCustomer(Customer customer) async {
    try {
      // Check if phone exists
      final exists = await _repository.phoneExists(customer.phone);
      if (exists) {
        return false;
      }

      await _repository.insert(customer);
      await loadCustomers();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update existing customer
  Future<bool> updateCustomer(Customer customer) async {
    try {
      // Check if phone exists (excluding current customer)
      if (customer.id != null) {
        final exists = await _repository.phoneExists(
          customer.phone,
          excludeId: customer.id,
        );
        if (exists) {
          return false;
        }
      }

      await _repository.update(customer);
      await loadCustomers();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete customer
  Future<bool> deleteCustomer(int id) async {
    try {
      await _repository.delete(id);
      await loadCustomers();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update customer balance
  Future<bool> updateBalance(int customerId, double newBalance) async {
    try {
      final success = await _repository.updateBalance(customerId, newBalance);
      if (success) {
        await loadCustomers();
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}

/// Provider for customer list state
final customerProvider =
    NotifierProvider<CustomerNotifier, AsyncValue<List<Customer>>>(
      CustomerNotifier.new,
    );

/// Provider for customers with outstanding balance
final customersWithBalanceProvider = FutureProvider<List<Customer>>((
  ref,
) async {
  final repository = ref.watch(customerRepositoryProvider);
  return await repository.getCustomersWithBalance();
});

/// Provider for customer count
final customerCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(customerRepositoryProvider);
  return await repository.getCount();
});

/// Provider for total outstanding balance
final totalOutstandingBalanceProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(customerRepositoryProvider);
  return await repository.getTotalOutstandingBalance();
});

/// Provider for single customer by id
final customerByIdProvider = FutureProvider.family<Customer?, int>((
  ref,
  id,
) async {
  final repository = ref.watch(customerRepositoryProvider);
  return await repository.getById(id);
});
