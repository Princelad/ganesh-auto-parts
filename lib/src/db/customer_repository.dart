import 'package:sqflite/sqflite.dart';
import '../models/customer.dart';
import 'database_helper.dart';

/// Repository for Customer CRUD operations
class CustomerRepository {
  final ERPDatabase _db = ERPDatabase();

  /// Insert a new customer
  Future<int> insert(Customer customer) async {
    final database = await _db.database;
    return await database.insert('customers', customer.toMap());
  }

  /// Update an existing customer
  Future<int> update(Customer customer) async {
    final database = await _db.database;
    return await database.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  /// Delete a customer by id
  Future<int> delete(int id) async {
    final database = await _db.database;
    return await database.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  /// Get customer by id
  Future<Customer?> getById(int id) async {
    final database = await _db.database;
    final maps = await database.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  /// Get customer by phone
  Future<Customer?> getByPhone(String phone) async {
    final database = await _db.database;
    final maps = await database.query(
      'customers',
      where: 'phone = ?',
      whereArgs: [phone],
    );

    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  /// Get all customers
  Future<List<Customer>> getAll() async {
    final database = await _db.database;
    final maps = await database.query('customers', orderBy: 'name ASC');
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  /// Search customers by name or phone with pagination
  Future<List<Customer>> searchCustomers({
    String? query,
    int limit = 50,
    int offset = 0,
  }) async {
    final database = await _db.database;

    if (query == null || query.isEmpty) {
      final maps = await database.query(
        'customers',
        orderBy: 'name ASC',
        limit: limit,
        offset: offset,
      );
      return maps.map((map) => Customer.fromMap(map)).toList();
    }

    final searchTerm = '%$query%';
    final maps = await database.query(
      'customers',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: [searchTerm, searchTerm],
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  /// Get customers with outstanding balance
  Future<List<Customer>> getCustomersWithBalance() async {
    final database = await _db.database;
    final maps = await database.query(
      'customers',
      where: 'balance > 0',
      orderBy: 'balance DESC',
    );
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  /// Update customer balance
  Future<bool> updateBalance(int customerId, double newBalance) async {
    final database = await _db.database;

    final updateCount = await database.update(
      'customers',
      {
        'balance': newBalance,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [customerId],
    );

    return updateCount > 0;
  }

  /// Increment customer balance (when invoice created)
  Future<bool> incrementBalance(int customerId, double amount) async {
    final database = await _db.database;

    final updateCount = await database.rawUpdate(
      '''
      UPDATE customers 
      SET balance = balance + ?, updatedAt = ? 
      WHERE id = ?
    ''',
      [amount, DateTime.now().millisecondsSinceEpoch, customerId],
    );

    return updateCount > 0;
  }

  /// Decrement customer balance (when payment received)
  Future<bool> decrementBalance(int customerId, double amount) async {
    final database = await _db.database;

    final updateCount = await database.rawUpdate(
      '''
      UPDATE customers 
      SET balance = balance - ?, updatedAt = ? 
      WHERE id = ?
    ''',
      [amount, DateTime.now().millisecondsSinceEpoch, customerId],
    );

    return updateCount > 0;
  }

  /// Get total customer count
  Future<int> getCount() async {
    final database = await _db.database;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM customers',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Check if phone number exists
  Future<bool> phoneExists(String phone, {int? excludeId}) async {
    final database = await _db.database;

    List<Map<String, dynamic>> maps;
    if (excludeId != null) {
      maps = await database.query(
        'customers',
        columns: ['id'],
        where: 'phone = ? AND id != ?',
        whereArgs: [phone, excludeId],
      );
    } else {
      maps = await database.query(
        'customers',
        columns: ['id'],
        where: 'phone = ?',
        whereArgs: [phone],
      );
    }

    return maps.isNotEmpty;
  }

  /// Get total outstanding balance across all customers
  Future<double> getTotalOutstandingBalance() async {
    final database = await _db.database;
    final result = await database.rawQuery(
      'SELECT SUM(balance) as total FROM customers',
    );
    final total = result.first['total'];
    return total != null ? (total as num).toDouble() : 0.0;
  }
}
