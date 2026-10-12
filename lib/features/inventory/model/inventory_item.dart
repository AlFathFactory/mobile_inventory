import 'package:flutter/foundation.dart';

import '../../../core/data/json_map_reader.dart';

enum StockStatus { safe, low, outOfStock }

extension StockStatusDataValue on StockStatus {
  String get dataValue => switch (this) {
    StockStatus.safe => 'safe',
    StockStatus.low => 'low',
    StockStatus.outOfStock => 'out_of_stock',
  };
}

@immutable
class InventoryItem {
  const InventoryItem({
    required this.code,
    required this.name,
    required this.category,
    required this.project,
    required this.quantity,
    required this.minimum,
    this.categoryId,
    this.supplier,
    this.expiry,
    this.notes,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      code: JsonMapReader.string(json, 'code'),
      name: JsonMapReader.string(json, 'name'),
      category: JsonMapReader.string(json, 'category'),
      categoryId: JsonMapReader.nullableString(json, 'category_id'),
      project: JsonMapReader.string(json, 'project'),
      quantity: JsonMapReader.integer(json, 'quantity'),
      minimum: JsonMapReader.integer(json, 'minimum'),
      supplier: JsonMapReader.nullableString(json, 'supplier'),
      expiry: JsonMapReader.nullableString(json, 'expiry'),
      notes: JsonMapReader.nullableString(json, 'notes'),
    );
  }

  final String code;
  final String name;
  final String category;
  final String? categoryId;
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
