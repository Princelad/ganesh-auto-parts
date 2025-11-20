# Changelog

All notable changes to Ganesh Auto Parts ERP will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
