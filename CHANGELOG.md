# Changelog

All notable changes to Ganesh Auto Parts ERP will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.5.0] - 2025-01-22

### Added

- **Barcode Scanner & Generation** - Complete barcode integration
  - **Barcode Scanning**
    - Full-screen camera scanner with visual overlay and cutout
    - Support for multiple barcode formats (EAN-8, EAN-13, UPC-A, UPC-E, Code 39, Code 93, Code 128, ITF, QR Code, etc.)
    - Flash toggle and camera switching capabilities
    - Auto-detection with haptic feedback on successful scan
    - Scan button in Item Form screen to populate SKU field
    - Scan-to-add items feature in Invoice Form screen
    - **Scan button in Stock Adjustment screen to quickly select items**
    - Handles multiple items with same SKU (shows selection dialog)
  - **Barcode Display & Generation**
    - Long-press on items in Items List to view barcode
    - Code 128 barcode generation and display
    - Barcode icon indicator on list items
    - Full-screen barcode dialog for easy scanning
  - **Barcode Printing** - Professional barcode label printing
    - Print single barcode labels with item name, company, SKU, and price
    - Bulk print barcode sheets (2x4 labels per A4 page)
    - Print all items or filter by low stock items
    - Print button in barcode dialog for individual items
    - Print menu in Items List screen for batch printing
    - PDF generation with A6 format for single labels
    - Professional label layout with proper spacing and borders
  - **Camera Permissions**
    - Configured CAMERA permission in AndroidManifest.xml
    - Hardware camera features declared
  - New Dependencies:
    - `mobile_scanner: ^7.1.3` - Camera-based barcode scanning
    - `barcode_widget: ^2.0.4` - Barcode generation and display
    - `printing: ^5.14.2` - PDF printing and preview (already included)
    - `pdf: ^3.11.3` - PDF document generation (already included)
- **Analytics & Charts** - Comprehensive business intelligence dashboard
  - **Analytics Screen**
    - Interactive date range selection (7D, 30D, 90D, 1Y, Custom)
    - Custom date range picker for flexible analysis
    - Summary cards showing total sales, invoice count, and average sale
    - Pull-to-refresh functionality for live data updates
  - **Sales Trend Line Chart**
    - Daily sales visualization with curved lines
    - Interactive tooltips showing date, sales amount, and invoice count
    - Gradient area fill below the line
    - Responsive Y-axis with smart currency formatting (K for thousands, L for lakhs)
    - Date labels on X-axis (MMM dd format)
  - **Revenue Breakdown Pie Chart**
    - Revenue by Company pie chart for brand/manufacturer analysis
    - Interactive touch feedback with section highlighting
    - Percentage labels on segments
    - Detailed legend with absolute values
    - Center space design for better readability
  - **Top Selling Items Bar Chart**
    - Horizontal bar chart showing top 10 items by quantity sold
    - Interactive tooltips with item name, quantity, and revenue
    - Background bars for visual reference
    - Truncated labels to prevent overflow
    - Smart value formatting
  - **New Repository Methods**:
    - `InvoiceRepository.getDailySales()` - Get daily sales data for date range
    - `InvoiceRepository.getSalesByHour()` - Get hourly sales pattern for a day
    - `InvoiceRepository.getSalesTrends()` - Get aggregate trends (total, avg, min, max)
    - `ItemRepository.getTopSellingItems()` - Get best-selling items with filters
    - `ItemRepository.getSalesByCompany()` - Revenue breakdown by company/manufacturer
  - New Dependencies:
    - `fl_chart: ^1.1.1` - Beautiful, interactive charts and graphs
  - **Reports Screen Integration**:
    - Analytics Dashboard integrated into Reports screen
    - New "Analytics Dashboard" section at the top with visual charts
    - Access via Reports → Business Analytics
    - Consolidated all reporting and analytics in one place

### Changed

- **License**: Project is now open source under MIT License
  - Updated LICENSE file to MIT License
  - Updated README.md license badge from Private to MIT
  - Updated About Page to reflect open source MIT License

### Fixed

- Fixed BuildContext usage across async gaps (8 warnings resolved)
  - Captured Navigator and ScaffoldMessenger before async operations in invoices list
  - Captured context references before async PIN reset in PIN verify screen
- Replaced deprecated `withOpacity()` with `withValues(alpha:)` for Material 3 compatibility

## [1.4.0] - 2025-01-21

### Added

- **UI Polish & Enhancements** - Major UX improvements release
  - **Enhanced About Page**
    - Comprehensive app information with version display (1.4.0 build 6)
    - Feature highlights section with 8 key features and icons
    - Tech stack information (Flutter 3.27.1, Dart 3.9.2, Riverpod, SQLite, Material Design 3)
    - Developer information with functional GitHub repository link
    - License and latest release information
    - External URL launching capability
  - **Dashboard Quick Stats**
    - Today's revenue card with real-time sales data
    - This week's revenue card (Monday to today)
    - Color-coded revenue cards (green for today, indigo for week)
  - **Global Search Feature**
    - Unified search across items, customers, and invoices
    - Debounced search with 500ms delay for performance
    - Parallel search execution across all entity types
    - Results grouped by type with count badges
    - Custom card designs for each entity type (blue for items, green for customers, orange for invoices)
    - Search tips in empty state
    - Tap-to-navigate functionality for all results
  - **Enhanced Empty States**
    - Improved empty states in Items, Customers, and Invoices list screens
    - Larger icons (80px) with better visual hierarchy
    - "Call-to-Action" buttons (Add First Item, Add First Customer, Create First Invoice)
    - Different icons and messaging for empty vs no-search-results states
    - Better typography and spacing throughout
- New repository methods:
  - `InvoiceRepository.getTodayRevenue()` - Calculate today's sales revenue
  - `InvoiceRepository.getWeekRevenue()` - Calculate this week's revenue
  - `InvoiceRepository.search()` - Search invoices by invoice number
  - `ItemRepository.search()` - Search items (wrapper with limit 20)
  - `CustomerRepository.search()` - Search customers (wrapper with limit 20)
- New providers in `invoice_provider.dart`:
  - `todayRevenueProvider` - FutureProvider for today's revenue
  - `weekRevenueProvider` - FutureProvider for week's revenue
- New screen: `global_search_screen.dart` - Complete global search implementation (448 lines)
- Search button added to home page AppBar

### Changed

- About Page completely rebuilt from minimal 30-line page to comprehensive 405-line information screen
- Dashboard stats widget enhanced with revenue tracking before outstanding balance
- Empty states in all list screens redesigned for better first-user experience
- Text visibility improved in search bar (black text on light background)
- Version bumped to 1.4.0+6

### Fixed

- Search TextField text visibility (changed from white to black text)
- GitHub link in About Page (corrected URL and added error handling)
- GitHub link compatibility with StatelessWidget (simplified async URL launching)

## [1.3.0] - 2025-01-20

### Added

- **Comprehensive Reports Suite** - Major analytics and business intelligence release
  - **Stock Valuation Report**
    - Total inventory value with item count and total stock quantity
    - Breakdown by company/brand with percentages
    - Low stock items section with value analysis
    - Pull-to-refresh and real-time data
  - **Top Selling Items Report**
    - Ranked list of top 50 items by quantity sold
    - Medal icons for top 3 performers
    - Date range filtering with quick filters (Last 7 Days, Last Month, Last Quarter, Last Year)
    - Revenue, quantity sold, invoice count, and average price per item
    - Amber color scheme for "star" products
  - **Sales by Period Report**
    - Toggle between daily, weekly, and monthly views
    - Period-based sales cards with revenue breakdown
    - Collected amount and tax analysis per period
    - Date range selection
    - Teal color scheme
  - **Customer Insights Report**
    - Top 50 customers by revenue
    - Purchase frequency and average order value
    - Last purchase date with relative time display
    - Outstanding balance highlighting
    - Customer ranking with medals for top 3
    - Green color scheme
- New repository methods in `InvoiceRepository`:
  - `getTopSellingItems()` - Ranked items by quantity sold with date filtering
  - `getSalesByPeriod()` - Daily/weekly/monthly sales aggregation
  - `getCustomerPurchaseSummary()` - Top customers with buying patterns
- New repository methods in `ItemRepository`:
  - `getStockValuationSummary()` - Total inventory value and counts
  - `getStockValuationByCompany()` - Company-wise stock valuation
  - `getAllCompanies()` - List of unique companies
- Enhanced navigation in Reports and Sales Summary screens

### Changed

- Reports screen: Updated "Customer List" to "Customer Insights" with enhanced functionality
- All "Coming Soon" report placeholders now functional
- Version bumped to 1.3.0+5

## [1.2.0] - 2025-11-20

### Added

- **GST/Tax Reports** - Complete tax collection reporting system
  - View tax collection summary by date range
  - Breakdown of tax collection by GST rate (0%, 5%, 12%, 18%, 28%)
  - Monthly GST trend analysis for last 6 months
  - Quick date range filters (Today, Last 7 Days, Last Month, Last Quarter, Last Year)
  - Custom date range picker for flexible reporting
  - Detailed invoice count, subtotal, tax amount, and total amount breakdowns
- New repository methods in `InvoiceRepository`:
  - `getGstSummary()` - Aggregate GST data for date range
  - `getGstBreakdownByRate()` - Tax collection grouped by rate
  - `getMonthlyGstSummary()` - Monthly trends
- Tax Reports section added to Reports screen

### Changed

- Reports screen reorganized with new Tax Reports section
- Version bumped to 1.2.0+4

## [1.1.0] - 2024-XX-XX

### Added

- **GST/Tax System Implementation**
  - Settings screen for GST configuration
  - Configurable CGST, SGST, IGST rates
  - GSTIN (GST Identification Number) field
  - Enable/disable GST toggle
  - Default GST rate selection (0%, 5%, 12%, 18%, 28%)
- **Invoice GST Support**
  - Apply GST to invoices with rate selection
  - Real-time GST calculation and preview
  - Subtotal, tax amount, and total display
  - Tax rate stored per invoice
- **PDF GST Enhancement**
  - Item-level GST breakdown in PDF tables
  - Invoice-level GST summary section
  - Tax rate and tax amount clearly displayed
- **Database Schema v2**
  - Added `subtotal`, `taxRate`, `taxAmount` fields to invoices table
  - Created `settings` table for app configuration
  - Automatic migration from v1 to v2
- **AppSettings Model**
  - Complete settings data model with GST fields
  - Business information fields (name, address, phone, email, GSTIN)
  - Settings repository and provider

### Changed

- Invoice model updated with GST fields
- Invoice creation flow includes GST calculation
- PDF generation includes tax breakdown
- Database version upgraded to 2

## [1.0.2] - 2024-XX-XX

### Added

- **PDF Invoice Generation**
  - Generate professional PDF invoices
  - Company header with business details
  - Itemized table with SKU, company, quantity, rate
  - Subtotal and total calculations
  - Share PDF via email, WhatsApp, or other apps
- PDF Service with customizable formatting
- Share functionality for generated PDFs

### Changed

- Invoice view screen includes "Generate PDF" button
- Enhanced invoice details display

## [1.0.1] - 2024-XX-XX

### Changed

- Minor bug fixes and performance improvements
- UI polish and refinements

## [1.0.0] - 2024-XX-XX

### Added

- **Items Management**
  - CRUD operations for inventory items
  - SKU, name, company, unit price tracking
  - Stock level and reorder level management
  - Search and filter functionality
- **Customers Management**
  - CRUD operations for customers
  - Contact details (name, phone, address)
  - Balance tracking (accounts receivable)
- **Invoice System**
  - Create multi-item invoices
  - Automatic invoice numbering
  - Stock deduction on invoice creation
  - Payment recording (full/partial)
  - Invoice search and history
- **Stock Management**
  - Manual stock adjustments
  - Reorder level alerts
  - Stock movement tracking
- **Reports**
  - Sales summary report
  - Low stock alerts report
  - Customer balance report
  - Change logs for audit trail
- **Data Management**
  - CSV export for items, customers, invoices
  - CSV import for bulk data
  - JSON database backup
  - Restore from backup files
- **Security**
  - PIN authentication system
  - SHA256 password hashing
  - Secure credential storage with flutter_secure_storage
- **Database**
  - SQLite local database (version 1)
  - Change log tracking for all operations
  - Sync-ready architecture
- **Core Features**
  - Offline-first architecture
  - Material Design 3 UI
  - Riverpod state management
  - Search and filtering across all screens

## [Unreleased]

### Planned Features

- Stock Valuation Report
- Enhanced Outstanding Balance Report with invoice details
- Top Selling Items Report
- Category Analysis Report
- Customer Insights Report
- Barcode Scanner Integration
- Advanced Charts & Analytics
- Expense Tracking System
- Cloud Sync with Backend
- Multi-User Support with Permissions
- SMS/Email Notifications
- Automated backup scheduling

---

## Release Notes Format

Each release includes:

- **Added**: New features
- **Changed**: Changes to existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements

## Version Numbering

- **Major** (X.0.0): Breaking changes or major new features
- **Minor** (1.X.0): New features, backward compatible
- **Patch** (1.0.X): Bug fixes, minor improvements
