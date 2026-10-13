import 'package:flutter/foundation.dart';

import '../../../core/data/json_map_reader.dart';

enum MovementType { addition, issue, returned, adjustment }

extension MovementTypeDataValue on MovementType {
  String get dataValue => switch (this) {
    MovementType.addition => 'addition',
    MovementType.issue => 'issue',
    MovementType.returned => 'returned',
    MovementType.adjustment => 'adjustment',
  };
}

MovementType movementTypeFromDataValue(String value) {
  return MovementType.values.firstWhere(
    (type) => type.dataValue == value,
    orElse: () => throw FormatException('Unknown movement type "$value".'),
  );
}

MovementType? movementTypeFromOperationValue(String value) {
  return switch (value) {
    'add' => MovementType.addition,
    'issue' => MovementType.issue,
    'return' => MovementType.returned,
    'adjust' => MovementType.adjustment,
    _ => null,
  };
}

@immutable
class InventoryMovement {
  const InventoryMovement({
    required this.id,
    required this.itemCode,
    required this.itemName,
    required this.category,
    required this.type,
    required this.quantity,
    required this.before,
    required this.after,
    required this.date,
    required this.project,
    this.tableName,
    this.itemId,
    this.categoryId,
    this.partyLabel,
    this.partyName,
    this.purchaseOrder,
    this.note,
    this.createdAt,
  });

  factory InventoryMovement.fromJson(Map<String, dynamic> json) {
    return InventoryMovement(
      id: JsonMapReader.string(json, 'id'),
      itemCode: JsonMapReader.string(json, 'item_code'),
      itemName: JsonMapReader.string(json, 'item_name'),
      category: JsonMapReader.string(json, 'category'),
      categoryId: JsonMapReader.nullableString(json, 'category_id'),
      type: movementTypeFromDataValue(JsonMapReader.string(json, 'type')),
      quantity: JsonMapReader.number(json, 'quantity'),
      before: JsonMapReader.number(json, 'before'),
      after: JsonMapReader.number(json, 'after'),
      date: JsonMapReader.dateTime(json, 'date'),
      project: JsonMapReader.string(json, 'project'),
      partyLabel: JsonMapReader.nullableString(json, 'party_label'),
      partyName: JsonMapReader.nullableString(json, 'party_name'),
      purchaseOrder: JsonMapReader.nullableString(json, 'purchase_order'),
      note: JsonMapReader.nullableString(json, 'note'),
    );
  }

  /// Maps the read-only projection from
  /// `public.inventory_item_movements_view`.
  ///
  /// Unknown backend operation types are skipped by returning `null` rather
  /// than allowing an unexpected value to crash the history screen.
  static InventoryMovement? tryFromMovementViewRow(Map<String, dynamic> json) {
    final operationValue = JsonMapReader.string(json, 'operation_type');
    final type = movementTypeFromOperationValue(operationValue);
    if (type == null) return null;

    final tableName = JsonMapReader.string(json, 'table_name');
    final itemId = JsonMapReader.string(json, 'item_id');
    final itemName =
        JsonMapReader.nullableString(json, 'item_name') ??
        JsonMapReader.string(json, 'item_label');
    final category =
        JsonMapReader.nullableString(json, 'category_name') ??
        JsonMapReader.string(json, 'category_label');
    final internalCode = JsonMapReader.nullableString(json, 'internal_code');
    final codeNumber = JsonMapReader.nullableString(json, 'code_number');
    final itemCode = JsonMapReader.nullableString(json, 'item_code');
    final before = JsonMapReader.number(json, 'previous_balance');
    final after = JsonMapReader.number(json, 'new_balance');
    final rawQuantity = JsonMapReader.number(json, 'quantity');

    final (partyLabel, partyName) = switch (type) {
      MovementType.addition => (
        'المورد',
        JsonMapReader.nullableString(json, 'supplier_name'),
      ),
      MovementType.issue => (
        'المستلم',
        JsonMapReader.nullableString(json, 'issued_to') ??
            JsonMapReader.nullableString(json, 'received_by'),
      ),
      MovementType.returned => (
        'المستلم',
        JsonMapReader.nullableString(json, 'received_by') ??
            JsonMapReader.nullableString(json, 'issued_to'),
      ),
      MovementType.adjustment => (null, null),
    };

    return InventoryMovement(
      id: JsonMapReader.string(json, 'id'),
      tableName: tableName,
      itemId: itemId,
      itemCode: internalCode ?? codeNumber ?? itemCode ?? '$tableName:$itemId',
      itemName: itemName,
      category: category,
      type: type,
      // Adjustment rows store an unsigned operation quantity, while the
      // balance delta carries the direction expected by the existing UI.
      quantity: type == MovementType.adjustment ? after - before : rawQuantity,
      before: before,
      after: after,
      date: JsonMapReader.dateTime(json, 'operation_date'),
      createdAt: JsonMapReader.nullableDateTime(json, 'created_at'),
      project:
          JsonMapReader.nullableString(json, 'project_name') ??
          JsonMapReader.nullableString(json, 'project') ??
          '',
      partyLabel: partyName == null ? null : partyLabel,
      partyName: partyName,
      purchaseOrder: JsonMapReader.nullableString(
        json,
        'purchase_order_number',
      ),
      note: JsonMapReader.nullableString(json, 'notes'),
    );
  }

  final String id;
  final String itemCode;
  final String itemName;
  final String category;
  final String? tableName;
  final String? itemId;
  final String? categoryId;
  final MovementType type;
  final num quantity;
  final num before;
  final num after;
  final DateTime date;
  final DateTime? createdAt;
  final String project;
  final String? partyLabel;
  final String? partyName;
  final String? purchaseOrder;
  final String? note;
}
