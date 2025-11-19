/// Input validation utilities
class Validators {
  /// Validate phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.length < 10) {
      return 'Phone number must be at least 10 digits';
    }

    if (cleaned.length > 15) {
      return 'Phone number is too long';
    }

    return null;
  }

  /// Validate name (customer or item name)
  static String? validateName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }

    if (value.length > 100) {
      return '$fieldName is too long';
    }

    return null;
  }

  /// Validate SKU
  static String? validateSku(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'SKU is required';
    }

    if (value.length > 50) {
      return 'SKU is too long';
    }

    // Allow alphanumeric and common special characters
    if (!RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(value)) {
      return 'SKU can only contain letters, numbers, hyphens, and underscores';
    }

    return null;
  }

  /// Validate price/amount
  static String? validatePrice(String? value, {String fieldName = 'Price'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    final amount = double.tryParse(value.replaceAll(',', ''));

    if (amount == null) {
      return 'Please enter a valid number';
    }

    if (amount < 0) {
      return '$fieldName cannot be negative';
    }

    if (amount == 0) {
      return '$fieldName must be greater than zero';
    }

    if (amount > 999999.99) {
      return '$fieldName is too large';
    }

    return null;
  }

  /// Validate quantity
  static String? validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Quantity is required';
    }

    final qty = int.tryParse(value);

    if (qty == null) {
      return 'Please enter a valid number';
    }

    if (qty <= 0) {
      return 'Quantity must be greater than zero';
    }

    if (qty > 999999) {
      return 'Quantity is too large';
    }

    return null;
  }

  /// Validate stock level
  static String? validateStock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Stock is required';
    }

    final stock = int.tryParse(value);

    if (stock == null) {
      return 'Please enter a valid number';
    }

    if (stock < 0) {
      return 'Stock cannot be negative';
    }

    return null;
  }

  /// Validate invoice number
  static String? validateInvoiceNo(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Invoice number is required';
    }

    if (value.length > 50) {
      return 'Invoice number is too long';
    }

    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Check if string is empty
  static bool isEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  /// Clean phone number (remove non-digits)
  static String cleanPhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }

  /// Clean price (remove currency symbols and commas)
  static String cleanPrice(String price) {
    return price.replaceAll(RegExp(r'[₹,\s]'), '');
  }
}
