import 'dart:convert';

/// Represents a customer in the ERP system
class Customer {
  final int? id;
  final String name;
  final String phone;
  final String? address;
  final double balance;
  final int createdAt;
  final int updatedAt;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    this.address,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert Customer to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'balance': balance,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create Customer from Map (database row)
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String?,
      balance: (map['balance'] as num).toDouble(),
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int,
    );
  }

  /// Convert to JSON string
  String toJson() => jsonEncode(toMap());

  /// Create Customer from JSON string
  factory Customer.fromJson(String source) =>
      Customer.fromMap(jsonDecode(source) as Map<String, dynamic>);

  /// Create a copy with modified fields
  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    double? balance,
    int? createdAt,
    int? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Customer &&
        other.id == id &&
        other.name == name &&
        other.phone == phone &&
        other.address == address &&
        other.balance == balance &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        phone.hashCode ^
        address.hashCode ^
        balance.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, phone: $phone, address: $address, balance: $balance, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
