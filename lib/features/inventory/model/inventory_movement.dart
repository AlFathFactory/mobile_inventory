import 'package:flutter/foundation.dart';

enum MovementType { addition, issue, returned, adjustment }

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
    this.partyLabel,
    this.partyName,
    this.purchaseOrder,
    this.note,
  });

  final String id;
  final String itemCode;
  final String itemName;
  final String category;
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
