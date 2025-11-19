# Ganesh Auto Parts v1.0.1 - Hotfix Release

**Release Date:** November 19, 2025  
**Build Type:** Hotfix Release  
**Version Code:** 2

## Build Information

- **APK Size:** 54.1 MB
- **AAB Size:** 44.6 MB
- **Flutter Version:** 3.27.1
- **Dart Version:** 3.9.2
- **Target SDK:** Android 5.0+ (API 21+)

## What's Fixed in This Release

This is a hotfix release that addresses critical runtime errors discovered in v1.0.0:

### Bug Fixes

1. **LateInitializationError Fixed**

   - Fixed crash where provider repository fields were being initialized multiple times
   - Changed from `late final` fields to getter pattern in ItemNotifier, CustomerNotifier, and InvoiceNotifier
   - Prevents "Field '\_repository@60095520' has already been initialized" error

2. **Invoice Screen Type Error Fixed**

   - Fixed type mismatch in customer lookup within invoice list
   - Changed from `firstWhere` with incorrect `orElse` callback to try-catch pattern
   - Now properly handles missing customer IDs with "Unknown Customer" fallback
   - Prevents "type '() => Null' is not a subtype of type '(() => Customer)?'" error

3. **Improved Error Handling**
   - Better null-safety in customer name display
   - Graceful handling of orphaned invoice records (invoices with deleted customers)

## Files Included

- `GaneshAutoParts-v1.0.1-release.apk` - Installable APK file
- `GaneshAutoParts-v1.0.1-release.aab` - App Bundle for Play Store

## Installation

### APK Installation

```bash
adb install GaneshAutoParts-v1.0.1-release.apk
```

### Upgrading from v1.0.0

This hotfix can be installed directly over v1.0.0 without losing data. All database records, settings, and PIN codes will be preserved.

## Technical Changes

### Modified Files

- `lib/src/providers/item_provider.dart`
- `lib/src/providers/customer_provider.dart`
- `lib/src/providers/invoice_provider.dart`
- `lib/src/screens/invoices_list_screen.dart`

### Provider Pattern Change

```dart
// Before (v1.0.0)
class CustomerNotifier extends Notifier<AsyncValue<List<Customer>>> {
  late final CustomerRepository _repository;

  @override
  AsyncValue<List<Customer>> build() {
    _repository = ref.read(customerRepositoryProvider); // Error: can be called multiple times
    _loadInitialCustomers();
    return const AsyncValue.loading();
  }
}

// After (v1.0.1)
class CustomerNotifier extends Notifier<AsyncValue<List<Customer>>> {
  CustomerRepository get _repository => ref.read(customerRepositoryProvider);

  @override
  AsyncValue<List<Customer>> build() {
    _loadInitialCustomers();
    return const AsyncValue.loading();
  }
}
```

### Customer Lookup Change

```dart
// Before (v1.0.0)
final customer = customers.firstWhere(
  (c) => c.id == invoice.customerId,
  orElse: () => null, // Error: type mismatch
);

// After (v1.0.1)
try {
  final customer = customers.firstWhere(
    (c) => c.id == invoice.customerId,
  );
  return customer.name;
} catch (e) {
  return 'Unknown Customer';
}
```

## Verification

After installation, verify the fix by:

1. Opening the app and entering your PIN
2. Navigate to Customers screen - should load without errors
3. Navigate to Invoices screen - should load without errors
4. Create a test invoice - should work normally
5. Navigate back and forth between screens - no crashes

## Known Issues

None reported for this version.

## Support

For issues or questions, please create an issue on GitHub.

---

**Git Tag:** v1.0.1  
**Commit:** b78ab1eac685f4db16cea48e430d8e2d3521de86  
**GitHub:** https://github.com/Princelad/ganesh-auto-parts/releases/tag/v1.0.1
