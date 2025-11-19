import 'dart:convert';

/// Represents an invoice (sales transaction) in the ERP system
class Invoice {
  final int? id;
  final String invoiceNo;
  final int? customerId;
  final double total;
  final double paid;
  final int date;
  final int createdAt;
  final int synced;

  Invoice({
    this.id,
    required this.invoiceNo,
    this.customerId,
    required this.total,
    required this.paid,
    required this.date,
    required this.createdAt,
    this.synced = 0,
  });

  /// Convert Invoice to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNo': invoiceNo,
      'customerId': customerId,
      'total': total,
      'paid': paid,
      'date': date,
      'createdAt': createdAt,
      'synced': synced,
    };
  }

  /// Create Invoice from Map (database row)
  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as int?,
      invoiceNo: map['invoiceNo'] as String,
      customerId: map['customerId'] as int?,
      total: (map['total'] as num).toDouble(),
      paid: (map['paid'] as num).toDouble(),
      date: map['date'] as int,
      createdAt: map['createdAt'] as int,
      synced: map['synced'] as int? ?? 0,
    );
  }

  /// Convert to JSON string
  String toJson() => jsonEncode(toMap());

  /// Create Invoice from JSON string
  factory Invoice.fromJson(String source) =>
      Invoice.fromMap(jsonDecode(source) as Map<String, dynamic>);

  /// Create a copy with modified fields
  Invoice copyWith({
    int? id,
    String? invoiceNo,
    int? customerId,
    double? total,
    double? paid,
    int? date,
    int? createdAt,
    int? synced,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      customerId: customerId ?? this.customerId,
      total: total ?? this.total,
      paid: paid ?? this.paid,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }

  /// Get the balance due (total - paid)
  double get balance => total - paid;

  /// Check if invoice is fully paid
  bool get isFullyPaid => paid >= total;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Invoice &&
        other.id == id &&
        other.invoiceNo == invoiceNo &&
        other.customerId == customerId &&
        other.total == total &&
        other.paid == paid &&
        other.date == date &&
        other.createdAt == createdAt &&
        other.synced == synced;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        invoiceNo.hashCode ^
        customerId.hashCode ^
        total.hashCode ^
        paid.hashCode ^
        date.hashCode ^
        createdAt.hashCode ^
        synced.hashCode;
  }

  @override
  String toString() {
    return 'Invoice(id: $id, invoiceNo: $invoiceNo, customerId: $customerId, total: $total, paid: $paid, date: $date, createdAt: $createdAt, synced: $synced)';
  }
}
