# Ganesh Auto Parts - ERP Application

<div align="center">
  
![Version](https://img.shields.io/badge/version-1.4.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-Android-green.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.27.1-02569B?logo=flutter)
![License](https://img.shields.io/badge/license-Private-red.svg)
![Build](https://img.shields.io/github/actions/workflow/status/Princelad/ganesh-auto-parts/release.yml?branch=master&label=build)
![Release](https://img.shields.io/github/v/release/Princelad/ganesh-auto-parts)

**Complete offline-first ERP solution for auto parts businesses**

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Documentation](#-documentation) • [Releases](https://github.com/Princelad/ganesh-auto-parts/releases)

</div>

## 📱 Overview

Ganesh Auto Parts is a comprehensive Android ERP application designed specifically for auto parts businesses. Built with Flutter and SQLite, it provides complete inventory management, customer tracking, invoicing, and business analytics - all working offline without any internet dependency.

## ✨ Features

### 📦 Inventory Management

- Complete items database with SKU tracking
- Stock level monitoring with reorder alerts
- Company/brand organization
- Real-time stock updates
- Search and filter capabilities

### 👥 Customer Management

- Customer database with contact details
- Balance tracking (accounts receivable)
- Transaction history
- Customer reports

### 🧾 Invoicing

- Create multi-item invoices
- Automatic invoice numbering
- Stock deduction on invoice creation
- Payment recording (full/partial)
- Payment status tracking
- Invoice search and filtering
- **PDF invoice generation**
- Share invoices as PDF (email, WhatsApp, etc.)

### 📊 Reports & Analytics

- **Comprehensive Reports Suite** (v1.3.0)
  - **Stock Valuation Report** - Total inventory value with company breakdown
  - **Top Selling Items Report** - Ranked products by quantity sold
  - **Sales by Period Report** - Daily, weekly, monthly sales analysis
  - **Customer Insights Report** - Top customers and buying patterns
- Sales summary reports
- Low stock alerts
- Customer balance reports
- **GST/Tax collection reports**

### 🎨 UI/UX Enhancements (NEW in v1.4.0)

- **Global Search** - Unified search across items, customers, and invoices
- **Dashboard Quick Stats** - Today's and week's revenue at a glance
- **Enhanced Empty States** - Helpful CTAs for first-time users
- **Comprehensive About Page** - App info, features, tech stack, and credits
  - Tax collection by period
  - Breakdown by tax rate
  - Monthly trends
  - Date range filtering
- Inventory overview

### 💾 Data Management

- CSV export/import for items, customers, invoices
- Full database backup to JSON
- Restore from backup files
- Share backups via email/cloud

### 🔐 Security

- PIN authentication (4-6 digits)
- SHA256 encryption
- App startup protection
- Secure credential storage

### ☁️ Sync Ready

- Change log tracking
- Foundation for cloud sync
- Multi-device ready architecture

## 🚀 Installation

### Prerequisites

- Android device running Android 5.0 (API 21) or higher
- ~100 MB free storage space

### Install from APK

1. Download `GaneshAutoParts-v1.0.0-release.apk` from the `releases/` folder
2. Transfer to your Android device
3. Enable "Install from Unknown Sources" in Settings
4. Tap the APK file to install
5. Open "Ganesh Auto Parts" from your app drawer

### Build from Source

```bash
# Clone the repository
git clone https://github.com/Princelad/ganesh-auto-parts.git
cd ganesh-auto-parts

# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Build release APK
flutter build apk --release

# Build release App Bundle
flutter build appbundle --release
```

## 📖 Usage

### First Launch

1. Open the app
2. No PIN is set by default - go to Security to set up
3. Start by adding items to your inventory
4. Add customers (optional)
5. Create invoices to record sales

### Creating an Invoice

1. Tap **Invoices** on home screen
2. Tap the **+** button
3. Select customer (optional)
4. Add items with quantities
5. System auto-calculates totals
6. Enter payment received
7. Save invoice

### Taking Backups

1. Tap **Backup & Restore** on home screen
2. Tap **Create Backup** or **Create & Share**
3. Backups saved to device storage
4. Share to cloud storage for safety

### Setting PIN Security

1. Tap **Security** on home screen
2. Toggle PIN switch ON
3. Enter 4-6 digit PIN
4. Confirm PIN
5. PIN required on every app launch

## 🏗️ Technology Stack

- **Framework**: Flutter (Dart)
- **Database**: SQLite (sqflite)
- **State Management**: Riverpod 3.0.3
- **Architecture**: Offline-first, Repository pattern
- **Platform**: Android only

## 📂 Project Structure

```
lib/
├── main.dart                    # App entry point
└── src/
    ├── db/                      # Database layer
    │   ├── database_helper.dart
    │   ├── item_repository.dart
    │   ├── customer_repository.dart
    │   └── invoice_repository.dart
    ├── models/                  # Data models
    │   ├── item.dart
    │   ├── customer.dart
    │   ├── invoice.dart
    │   └── invoice_item.dart
    ├── providers/               # Riverpod providers
    │   ├── item_provider.dart
    │   ├── customer_provider.dart
    │   └── invoice_provider.dart
    ├── screens/                 # UI screens
    │   ├── home_page.dart
    │   ├── items_list_screen.dart
    │   ├── invoice_form_screen.dart
    │   └── ...
    ├── services/                # Business logic
    │   ├── csv_service.dart
    │   ├── backup_service.dart
    │   └── auth_service.dart
    └── widgets/                 # Reusable widgets
        └── dashboard_stats_widget.dart
```

## 🔧 Configuration

### Database

- Location: `/data/data/com.example.ganesh_auto_parts/databases/erp_db.sqlite`
- Auto-created on first launch
- No manual setup required

### Backups

- Location: `/storage/emulated/0/Android/data/.../files/Documents/`
- Format: JSON
- Naming: `gap_backup_<timestamp>.json`
- Auto-cleanup: Keeps last 5 backups

## 📊 Database Schema

### Items

```sql
id, sku, name, company, unitPrice, stock, reorderLevel, createdAt, updatedAt
```

### Customers

```sql
id, name, phone, address, balance, createdAt, updatedAt
```

### Invoices

```sql
id, invoiceNo, customerId, total, paid, date, createdAt, synced
```

### Invoice Items

```sql
id, invoiceId, itemId, qty, unitPrice, lineTotal
```

## 🤝 Contributing

This is a private project. For questions or suggestions, please contact the development team.

## 📄 License

This project is proprietary software. All rights reserved.

## 👨‍💻 Development

### Running Tests

```bash
flutter test
```

### Code Generation

```bash
flutter pub run build_runner build
```

### Clean Build

```bash
flutter clean
flutter pub get
flutter run
```

## � Continuous Integration & Releases

This project uses **GitHub Actions** for automated builds and releases.

### Automated Release Process

When you push a version tag, the CI automatically:

1. ✅ Builds APK and AAB files
2. ✅ Extracts changelog from CHANGELOG.md
3. ✅ Creates GitHub Release
4. ✅ Uploads release artifacts
5. ✅ Adds build information

**To create a release:**

```bash
# 1. Update version in pubspec.yaml
version: 1.0.2+3

# 2. Update CHANGELOG.md
## [1.0.2] - 2025-11-20
### Added
- New feature

# 3. Commit changes
git add .
git commit -m "chore: Bump version to 1.0.2"

# 4. Create and push tag
git tag -a v1.0.2 -m "Release v1.0.2"
git push origin master
git push origin v1.0.2

# GitHub Actions will automatically build and create the release!
```

### Continuous Integration

Every push and pull request automatically:

- ✅ Runs code formatting checks
- ✅ Runs static analysis
- ✅ Runs all tests
- ✅ Builds debug and release APKs
- ✅ Comments build status on PRs

**View workflows:** [GitHub Actions](https://github.com/Princelad/ganesh-auto-parts/actions)

**Download releases:** [Releases Page](https://github.com/Princelad/ganesh-auto-parts/releases)

For more details, see [`.github/workflows/README.md`](.github/workflows/README.md)

## �📞 Support

For support or queries:

- Check the in-app **About** page
- Review `PROJECT_DOCUMENTATION.md` for detailed information
- Check `BUILD_INFO.txt` in releases folder

## 🎯 Roadmap

### Upcoming Features

- [ ] Barcode scanner for quick item lookup
- [ ] Advanced charts and analytics
- [ ] Tax/GST support
- [ ] Expense tracking
- [ ] Cloud sync with server
- [ ] Multi-user support
- [ ] SMS/Email notifications

## 📈 Version History

### v1.4.0 (January 21, 2025)

- ✅ Enhanced About Page with comprehensive information and GitHub link
- ✅ Dashboard quick stats (today's and week's revenue)
- ✅ Global search across items, customers, and invoices
- ✅ Enhanced empty states with call-to-action buttons
- ✅ Improved search text visibility
- ✅ Better first-user experience

### v1.3.0 (January 20, 2025)

- ✅ Stock Valuation Report with company breakdown
- ✅ Top Selling Items Report with date filtering
- ✅ Sales by Period Report (daily/weekly/monthly)
- ✅ Customer Insights Report with buying patterns
- ✅ Complete reports suite implementation

### v1.2.0 (November 20, 2025)

- ✅ GST/Tax Reports with rate breakdown
- ✅ Monthly GST trend analysis
- ✅ Tax collection summary with date filtering
- ✅ Complete tax reporting system

### v1.1.0 (November 20, 2025)

- ✅ GST/Tax system implementation
- ✅ Tax configuration in settings
- ✅ Rate-based tax calculation
- ✅ Tax amounts on invoices

### v1.0.2 (November 20, 2025)

- ✅ PDF invoice generation
- ✅ Share invoices as PDF
- ✅ Professional invoice layout with company branding
- ✅ GitHub Actions for automated releases

### v1.0.1 (November 19, 2025)

- ✅ Fixed LateInitializationError in providers
- ✅ Fixed type error in invoice screen
- ✅ Improved error handling

### v1.0.0 (November 19, 2025)

- ✅ Initial release
- ✅ Complete inventory management
- ✅ Customer management
- ✅ Invoice management with stock deduction
- ✅ Stock adjustment
- ✅ Reports & analytics (4 types)
- ✅ CSV export/import
- ✅ Database backup/restore
- ✅ PIN security
- ✅ Sync foundation
- ✅ Custom branding with logo

---

<div align="center">

**Built with ❤️ using Flutter**

_Making business management simple and efficient_

</div>
