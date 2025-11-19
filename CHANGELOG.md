# Changelog

All notable changes to Ganesh Auto Parts will be documented in this file.

## [1.0.1] - 2025-11-19

### Fixed

- Fixed `LateInitializationError` in ItemNotifier, CustomerNotifier, and InvoiceNotifier where `_repository` field was being initialized multiple times
- Fixed type error in invoices list screen where `firstWhere` orElse callback was returning incorrect type
- Changed provider repository fields from `late final` to getters to prevent re-initialization errors
- Wrapped customer lookup in try-catch to handle missing customer IDs gracefully

### Changed

- Improved error handling in invoice list display for unknown customers

## [1.0.0] - 2025-11-19

### Added

- Initial release of Ganesh Auto Parts ERP System
- Items Management (CRUD operations, SKU tracking, stock levels, reorder alerts)
- Customer Management (contacts, balance tracking, transaction history)
- Invoice Management (multi-item invoices, auto-numbering, stock deduction, payment tracking)
- Stock Adjustment (add/reduce stock with change logs)
- Reports (Sales Summary, Low Stock, Customer Balance, Inventory Valuation)
- CSV Export/Import (items, customers, invoices)
- Database Backup/Restore (JSON format with share functionality)
- PIN Security (4-6 digit PIN with SHA256 hashing, startup authentication)
- Sync Service placeholder (with change log tracking for future cloud sync)
- Custom G.A.P. logo and branding
- Offline-first SQLite database
- Material Design 3 UI
