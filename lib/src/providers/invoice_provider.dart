import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../db/invoice_repository.dart';
import 'database_provider.dart';

/// Notifier for managing invoices
class InvoiceNotifier extends Notifier<AsyncValue<List<Invoice>>> {
  InvoiceRepository get _repository => ref.read(invoiceRepositoryProvider);

  @override
  AsyncValue<List<Invoice>> build() {
    loadInvoices();
    return const AsyncValue.loading();
  }

  /// Load all invoices
  Future<void> loadInvoices({int limit = 100, int offset = 0}) async {
    state = const AsyncValue.loading();
    try {
      final invoices = await _repository.getAll(limit: limit, offset: offset);
      state = AsyncValue.data(invoices);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create new invoice with items
  Future<int?> createInvoice(Invoice invoice, List<InvoiceItem> items) async {
    try {
      // Check if invoice number exists
      final exists = await _repository.invoiceNoExists(invoice.invoiceNo);
      if (exists) {
        return null;
      }

      final invoiceId = await _repository.insertWithItems(invoice, items);
      await loadInvoices();
      return invoiceId;
    } catch (e) {
      return null;
    }
  }

  /// Update invoice payment
  Future<bool> updatePayment(int invoiceId, double newPaidAmount) async {
    try {
      final success = await _repository.updatePayment(invoiceId, newPaidAmount);
      if (success) {
        await loadInvoices();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Delete invoice
  Future<bool> deleteInvoice(int id) async {
    try {
      await _repository.delete(id);
      await loadInvoices();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Load invoices by customer
  Future<void> loadInvoicesByCustomer(int customerId) async {
    state = const AsyncValue.loading();
    try {
      final invoices = await _repository.getByCustomer(customerId);
      state = AsyncValue.data(invoices);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Load unpaid invoices
  Future<void> loadUnpaidInvoices() async {
    state = const AsyncValue.loading();
    try {
      final invoices = await _repository.getUnpaidInvoices();
      state = AsyncValue.data(invoices);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Provider for invoice list state
final invoiceProvider =
    NotifierProvider<InvoiceNotifier, AsyncValue<List<Invoice>>>(
      InvoiceNotifier.new,
    );

/// Provider for unpaid invoices
final unpaidInvoicesProvider = FutureProvider<List<Invoice>>((ref) async {
  final repository = ref.watch(invoiceRepositoryProvider);
  return await repository.getUnpaidInvoices();
});

/// Provider for invoice count
final invoiceCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(invoiceRepositoryProvider);
  return await repository.getCount();
});

/// Provider for single invoice by id
final invoiceByIdProvider = FutureProvider.family<Invoice?, int>((
  ref,
  id,
) async {
  final repository = ref.watch(invoiceRepositoryProvider);
  return await repository.getById(id);
});

/// Provider for invoice items
final invoiceItemsProvider = FutureProvider.family<List<InvoiceItem>, int>((
  ref,
  invoiceId,
) async {
  final repository = ref.watch(invoiceRepositoryProvider);
  return await repository.getInvoiceItems(invoiceId);
});

/// Provider for invoice items with details
final invoiceItemsWithDetailsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((
      ref,
      invoiceId,
    ) async {
      final repository = ref.watch(invoiceRepositoryProvider);
      return await repository.getInvoiceItemsWithDetails(invoiceId);
    });

/// Provider for generating next invoice number
final nextInvoiceNoProvider = FutureProvider<String>((ref) async {
  final repository = ref.watch(invoiceRepositoryProvider);
  return await repository.generateNextInvoiceNo();
});

/// Provider for total sales in a date range
final totalSalesProvider = FutureProvider.family<double, Map<String, int>>((
  ref,
  dateRange,
) async {
  final repository = ref.watch(invoiceRepositoryProvider);
  return await repository.getTotalSales(dateRange['start']!, dateRange['end']!);
});
