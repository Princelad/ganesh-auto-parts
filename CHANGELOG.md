# Changelog

All notable changes to Ganesh Auto Parts will be documented in this file.

## [1.0.2] - 2025-11-20

### Added
- PDF invoice generation feature with professional layout
- Export and share invoices as PDF files
- Print invoices directly from the app
- Company branding in PDF header
- Detailed items table with SKU, quantity, and pricing
- Payment status section showing paid amount and balance due
- Support for all invoice types (paid/unpaid/partial, with/without customer)

### Changed
- Updated invoice details sheet with "Export as PDF" button
- Enhanced invoice viewing experience

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
