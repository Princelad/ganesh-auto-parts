import 'dart:convert';

/// Represents a line item in an invoice
class InvoiceItem {
  final int? id;
  final int invoiceId;
  final int itemId;
  final int qty;
  final double unitPrice;
  final double lineTotal;

  InvoiceItem({
    this.id,
    required this.invoiceId,
    required this.itemId,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
  });

  /// Convert InvoiceItem to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'itemId': itemId,
      'qty': qty,
      'unitPrice': unitPrice,
      'lineTotal': lineTotal,
    };
  }

  /// Create InvoiceItem from Map (database row)
  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] as int?,
      invoiceId: map['invoiceId'] as int,
      itemId: map['itemId'] as int,
      qty: map['qty'] as int,
      unitPrice: (map['unitPrice'] as num).toDouble(),
      lineTotal: (map['lineTotal'] as num).toDouble(),
    );
  }

  /// Convert to JSON string
  String toJson() => jsonEncode(toMap());

  /// Create InvoiceItem from JSON string
  factory InvoiceItem.fromJson(String source) =>
      InvoiceItem.fromMap(jsonDecode(source) as Map<String, dynamic>);

  /// Create a copy with modified fields
  InvoiceItem copyWith({
    int? id,
    int? invoiceId,
    int? itemId,
    int? qty,
    double? unitPrice,
    double? lineTotal,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      itemId: itemId ?? this.itemId,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      lineTotal: lineTotal ?? this.lineTotal,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is InvoiceItem &&
        other.id == id &&
        other.invoiceId == invoiceId &&
        other.itemId == itemId &&
        other.qty == qty &&
        other.unitPrice == unitPrice &&
        other.lineTotal == lineTotal;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        invoiceId.hashCode ^
        itemId.hashCode ^
        qty.hashCode ^
        unitPrice.hashCode ^
        lineTotal.hashCode;
  }

  @override
  String toString() {
    return 'InvoiceItem(id: $id, invoiceId: $invoiceId, itemId: $itemId, qty: $qty, unitPrice: $unitPrice, lineTotal: $lineTotal)';
  }
}
