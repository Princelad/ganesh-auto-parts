import 'dart:convert';

/// Represents an inventory item in the ERP system
class Item {
  final int? id;
  final String sku;
  final String name;
  final String? company;
  final double unitPrice;
  final int stock;
  final int reorderLevel;
  final int createdAt;
  final int updatedAt;

  Item({
    this.id,
    required this.sku,
    required this.name,
    this.company,
    required this.unitPrice,
    required this.stock,
    required this.reorderLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert Item to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'company': company,
      'unitPrice': unitPrice,
      'stock': stock,
      'reorderLevel': reorderLevel,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create Item from Map (database row)
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as int?,
      sku: map['sku'] as String,
      name: map['name'] as String,
      company: map['company'] as String?,
      unitPrice: (map['unitPrice'] as num).toDouble(),
      stock: map['stock'] as int,
      reorderLevel: map['reorderLevel'] as int,
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int,
    );
  }

  /// Convert to JSON string
  String toJson() => jsonEncode(toMap());

  /// Create Item from JSON string
  factory Item.fromJson(String source) =>
      Item.fromMap(jsonDecode(source) as Map<String, dynamic>);

  /// Create a copy with modified fields
  Item copyWith({
    int? id,
    String? sku,
    String? name,
    String? company,
    double? unitPrice,
    int? stock,
    int? reorderLevel,
    int? createdAt,
    int? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      company: company ?? this.company,
      unitPrice: unitPrice ?? this.unitPrice,
      stock: stock ?? this.stock,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Item &&
        other.id == id &&
        other.sku == sku &&
        other.name == name &&
        other.company == company &&
        other.unitPrice == unitPrice &&
        other.stock == stock &&
        other.reorderLevel == reorderLevel &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        sku.hashCode ^
        name.hashCode ^
        company.hashCode ^
        unitPrice.hashCode ^
        stock.hashCode ^
        reorderLevel.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'Item(id: $id, sku: $sku, name: $name, company: $company, unitPrice: $unitPrice, stock: $stock, reorderLevel: $reorderLevel, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
