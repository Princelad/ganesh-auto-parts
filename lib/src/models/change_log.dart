import 'dart:convert';

/// Represents a change log entry for future sync functionality
/// Tracks all CRUD operations for offline-first data sync
class ChangeLog {
  final int? id;
  final String entity;
  final int entityId;
  final String action; // 'create', 'update', 'delete'
  final String payload; // JSON string of the entity data
  final int timestamp;
  final int synced;

  ChangeLog({
    this.id,
    required this.entity,
    required this.entityId,
    required this.action,
    required this.payload,
    required this.timestamp,
    this.synced = 0,
  });

  /// Convert ChangeLog to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity': entity,
      'entityId': entityId,
      'action': action,
      'payload': payload,
      'timestamp': timestamp,
      'synced': synced,
    };
  }

  /// Create ChangeLog from Map (database row)
  factory ChangeLog.fromMap(Map<String, dynamic> map) {
    return ChangeLog(
      id: map['id'] as int?,
      entity: map['entity'] as String,
      entityId: map['entityId'] as int,
      action: map['action'] as String,
      payload: map['payload'] as String,
      timestamp: map['timestamp'] as int,
      synced: map['synced'] as int? ?? 0,
    );
  }

  /// Convert to JSON string
  String toJson() => jsonEncode(toMap());

  /// Create ChangeLog from JSON string
  factory ChangeLog.fromJson(String source) =>
      ChangeLog.fromMap(jsonDecode(source) as Map<String, dynamic>);

  /// Create a copy with modified fields
  ChangeLog copyWith({
    int? id,
    String? entity,
    int? entityId,
    String? action,
    String? payload,
    int? timestamp,
    int? synced,
  }) {
    return ChangeLog(
      id: id ?? this.id,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      synced: synced ?? this.synced,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChangeLog &&
        other.id == id &&
        other.entity == entity &&
        other.entityId == entityId &&
        other.action == action &&
        other.payload == payload &&
        other.timestamp == timestamp &&
        other.synced == synced;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        entity.hashCode ^
        entityId.hashCode ^
        action.hashCode ^
        payload.hashCode ^
        timestamp.hashCode ^
        synced.hashCode;
  }

  @override
  String toString() {
    return 'ChangeLog(id: $id, entity: $entity, entityId: $entityId, action: $action, timestamp: $timestamp, synced: $synced)';
  }
}
