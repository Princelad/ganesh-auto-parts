import 'package:intl/intl.dart';

/// Utility functions for currency formatting
class CurrencyHelper {
  static final _currencyFormat = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 2,
  );

  static final _compactFormat = NumberFormat.compact();

  /// Format amount as currency (e.g., ₹1,234.56)
  static String format(double amount) {
    return _currencyFormat.format(amount);
  }

  /// Format amount without symbol (e.g., 1,234.56)
  static String formatWithoutSymbol(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  /// Format amount in compact form (e.g., ₹1.2K)
  static String formatCompact(double amount) {
    return '₹${_compactFormat.format(amount)}';
  }

  /// Parse string to double
  static double parse(String value) {
    try {
      // Remove currency symbols and commas
      final cleaned = value.replaceAll(RegExp(r'[₹,\s]'), '');
      return double.parse(cleaned);
    } catch (e) {
      return 0.0;
    }
  }

  /// Validate currency input
  static bool isValidAmount(String value) {
    try {
      final amount = parse(value);
      return amount >= 0;
    } catch (e) {
      return false;
    }
  }

  /// Round to 2 decimal places
  static double round(double amount) {
    return (amount * 100).round() / 100;
  }
}
