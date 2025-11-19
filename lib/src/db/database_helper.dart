import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton database helper for the ERP system
/// Manages SQLite database initialization, migrations, and access
class ERPDatabase {
  static final ERPDatabase _instance = ERPDatabase._internal();
  static Database? _database;

  factory ERPDatabase() => _instance;

  ERPDatabase._internal();

  /// Get database instance (creates if not exists)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'erp_db.sqlite');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables and indexes
  Future<void> _onCreate(Database db, int version) async {
    // Items table
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sku TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        company TEXT,
        unitPrice REAL NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        reorderLevel INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Customers table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT,
        balance REAL NOT NULL DEFAULT 0.0,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Invoices table
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceNo TEXT NOT NULL UNIQUE,
        customerId INTEGER,
        total REAL NOT NULL,
        paid REAL NOT NULL DEFAULT 0.0,
        date INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE SET NULL
      )
    ''');

    // Invoice Items table
    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceId INTEGER NOT NULL,
        itemId INTEGER NOT NULL,
        qty INTEGER NOT NULL,
        unitPrice REAL NOT NULL,
        lineTotal REAL NOT NULL,
        FOREIGN KEY (invoiceId) REFERENCES invoices (id) ON DELETE CASCADE,
        FOREIGN KEY (itemId) REFERENCES items (id) ON DELETE RESTRICT
      )
    ''');

    // Change Log table (for future sync)
    await db.execute('''
      CREATE TABLE change_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity TEXT NOT NULL,
        entityId INTEGER NOT NULL,
        action TEXT NOT NULL,
        payload TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create indexes for performance
    await _createIndexes(db);
  }

  /// Create database indexes
  Future<void> _createIndexes(Database db) async {
    // Item indexes
    await db.execute('CREATE INDEX idx_items_sku ON items(sku)');
    await db.execute('CREATE INDEX idx_items_name ON items(name)');
    await db.execute('CREATE INDEX idx_items_company ON items(company)');
    await db.execute('CREATE INDEX idx_items_stock ON items(stock)');

    // Customer indexes
    await db.execute('CREATE INDEX idx_customers_phone ON customers(phone)');
    await db.execute('CREATE INDEX idx_customers_name ON customers(name)');

    // Invoice indexes
    await db.execute(
      'CREATE INDEX idx_invoices_invoiceNo ON invoices(invoiceNo)',
    );
    await db.execute(
      'CREATE INDEX idx_invoices_customerId ON invoices(customerId)',
    );
    await db.execute('CREATE INDEX idx_invoices_date ON invoices(date)');
    await db.execute('CREATE INDEX idx_invoices_synced ON invoices(synced)');

    // Invoice Item indexes
    await db.execute(
      'CREATE INDEX idx_invoice_items_invoiceId ON invoice_items(invoiceId)',
    );
    await db.execute(
      'CREATE INDEX idx_invoice_items_itemId ON invoice_items(itemId)',
    );

    // Change Log indexes
    await db.execute(
      'CREATE INDEX idx_change_logs_entity ON change_logs(entity)',
    );
    await db.execute(
      'CREATE INDEX idx_change_logs_synced ON change_logs(synced)',
    );
    await db.execute(
      'CREATE INDEX idx_change_logs_timestamp ON change_logs(timestamp)',
    );
  }

  /// Handle database upgrades
  /// Migration placeholder - add version-specific migrations here
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Example migration pattern:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE items ADD COLUMN barcode TEXT');
    // }
    // if (oldVersion < 3) {
    //   await db.execute('CREATE TABLE ...');
    // }
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Delete database (for testing or reset)
  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'erp_db.sqlite');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  /// Execute raw query (for complex queries)
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// Execute raw insert/update/delete
  Future<int> rawExecute(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawUpdate(sql, arguments);
  }

  /// Run queries in a transaction
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }
}
