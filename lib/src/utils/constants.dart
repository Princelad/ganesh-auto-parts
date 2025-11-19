/// Application-wide constants
class AppConstants {
  // App Info
  static const String appName = 'Ganesh Auto Parts';
  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'erp_db.sqlite';
  static const int databaseVersion = 1;

  // Pagination
  static const int defaultPageSize = 50;
  static const int itemsPerPage = 20;

  // Invoice
  static const String invoicePrefix = 'INV-';
  static const int invoiceNumberLength = 4;

  // Validation
  static const int minPhoneLength = 10;
  static const int maxPhoneLength = 15;
  static const int minSkuLength = 1;
  static const int maxSkuLength = 50;
  static const double minPrice = 0.01;
  static const double maxPrice = 999999.99;

  // Date formats
  static const String displayDateFormat = 'dd MMM yyyy';
  static const String displayDateTimeFormat = 'dd MMM yyyy hh:mm a';
  static const String exportDateFormat = 'yyyy-MM-dd';

  // Stock
  static const int defaultReorderLevel = 10;
  static const int minStock = 0;

  // File exports
  static const String csvFilePrefix = 'ganesh_auto_parts_';
  static const String backupFilePrefix = 'backup_';

  // Sync
  static const int syncedStatus = 1;
  static const int notSyncedStatus = 0;

  // Colors
  static const int primaryColorValue = 0xFF3F51B5; // Indigo

  // Limits
  static const int searchResultsLimit = 100;
  static const int recentInvoicesLimit = 10;
}
