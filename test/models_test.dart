import 'package:flutter_test/flutter_test.dart';
import 'package:ganesh_auto_parts/src/models/item.dart';
import 'package:ganesh_auto_parts/src/models/customer.dart';
import 'package:ganesh_auto_parts/src/models/invoice.dart';
import 'package:ganesh_auto_parts/src/models/invoice_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Model Tests', () {
    test('Item model serialization', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final item = Item(
        id: 1,
        sku: 'TEST-001',
        name: 'Test Item',
        company: 'Test Company',
        unitPrice: 100.50,
        stock: 10,
        reorderLevel: 5,
        createdAt: now,
        updatedAt: now,
      );

      // Test toMap
      final map = item.toMap();
      expect(map['sku'], 'TEST-001');
      expect(map['name'], 'Test Item');
      expect(map['unitPrice'], 100.50);

      // Test fromMap
      final itemFromMap = Item.fromMap(map);
      expect(itemFromMap.sku, item.sku);
      expect(itemFromMap.name, item.name);
      expect(itemFromMap.unitPrice, item.unitPrice);

      // Test copyWith
      final updatedItem = item.copyWith(stock: 15);
      expect(updatedItem.stock, 15);
      expect(updatedItem.sku, item.sku);
    });

    test('Customer model serialization', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final customer = Customer(
        id: 1,
        name: 'John Doe',
        phone: '1234567890',
        address: '123 Test St',
        balance: 500.0,
        createdAt: now,
        updatedAt: now,
      );

      final map = customer.toMap();
      final customerFromMap = Customer.fromMap(map);

      expect(customerFromMap.name, customer.name);
      expect(customerFromMap.phone, customer.phone);
      expect(customerFromMap.balance, customer.balance);
    });

    test('Invoice model calculations', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final invoice = Invoice(
        id: 1,
        invoiceNo: 'INV-0001',
        customerId: 1,
        total: 1000.0,
        paid: 600.0,
        date: now,
        createdAt: now,
      );

      expect(invoice.balance, 400.0);
      expect(invoice.isFullyPaid, false);

      final paidInvoice = invoice.copyWith(paid: 1000.0);
      expect(paidInvoice.isFullyPaid, true);
    });

    test('InvoiceItem model serialization', () {
      final invoiceItem = InvoiceItem(
        id: 1,
        invoiceId: 1,
        itemId: 1,
        qty: 5,
        unitPrice: 100.0,
        lineTotal: 500.0,
      );

      final map = invoiceItem.toMap();
      final itemFromMap = InvoiceItem.fromMap(map);

      expect(itemFromMap.qty, 5);
      expect(itemFromMap.unitPrice, 100.0);
      expect(itemFromMap.lineTotal, 500.0);
    });

    test('Item equality', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final item1 = Item(
        id: 1,
        sku: 'TEST-001',
        name: 'Test Item',
        unitPrice: 100.0,
        stock: 10,
        reorderLevel: 5,
        createdAt: now,
        updatedAt: now,
      );

      final item2 = Item(
        id: 1,
        sku: 'TEST-001',
        name: 'Test Item',
        unitPrice: 100.0,
        stock: 10,
        reorderLevel: 5,
        createdAt: now,
        updatedAt: now,
      );

      expect(item1, equals(item2));
      expect(item1.hashCode, equals(item2.hashCode));
    });
  });
}
