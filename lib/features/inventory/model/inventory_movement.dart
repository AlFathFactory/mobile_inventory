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
    this.categoryId,
    this.partyLabel,
    this.partyName,
    this.purchaseOrder,
    this.note,
  });

  factory InventoryMovement.fromJson(Map<String, dynamic> json) {
    return InventoryMovement(
      id: JsonMapReader.string(json, 'id'),
      itemCode: JsonMapReader.string(json, 'item_code'),
      itemName: JsonMapReader.string(json, 'item_name'),
      category: JsonMapReader.string(json, 'category'),
      categoryId: JsonMapReader.nullableString(json, 'category_id'),
      type: movementTypeFromDataValue(JsonMapReader.string(json, 'type')),
      quantity: JsonMapReader.integer(json, 'quantity'),
      before: JsonMapReader.integer(json, 'before'),
      after: JsonMapReader.integer(json, 'after'),
      date: JsonMapReader.dateTime(json, 'date'),
      project: JsonMapReader.string(json, 'project'),
      partyLabel: JsonMapReader.nullableString(json, 'party_label'),
      partyName: JsonMapReader.nullableString(json, 'party_name'),
      purchaseOrder: JsonMapReader.nullableString(json, 'purchase_order'),
      note: JsonMapReader.nullableString(json, 'note'),
    );
  }

  final String id;
  final String itemCode;
  final String itemName;
  final String category;
  final String? categoryId;
  final MovementType type;
  final int quantity;
  final int before;
  final int after;
  final DateTime date;
  final String project;
  final String? partyLabel;
  final String? partyName;
  final String? purchaseOrder;
  final String? note;
}
