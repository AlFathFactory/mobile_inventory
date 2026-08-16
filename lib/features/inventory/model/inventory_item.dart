import 'package:flutter/foundation.dart';

enum StockStatus { safe, low, outOfStock }

@immutable
class InventoryItem {
  const InventoryItem({
    required this.code,
    required this.name,
    required this.category,
    required this.project,
    required this.quantity,
    required this.minimum,
    this.supplier,
    this.expiry,
    this.notes,
  });

  final String code;
  final String name;
  final String category;
  final String project;
  final int quantity;
  final int minimum;
  final String? supplier;
  final String? expiry;
  final String? notes;

  StockStatus get status {
    if (quantity <= 0) return StockStatus.outOfStock;
    if (quantity < minimum) return StockStatus.low;
    return StockStatus.safe;
  }
}
