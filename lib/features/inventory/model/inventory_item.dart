import 'package:flutter/foundation.dart';

import '../../../core/data/inventory_category_names.dart';
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
    this.tableName,
    this.itemId,
    this.itemKey,
    this.categoryId,
    this.supplier,
    this.expiry,
    this.notes,
    this.updatedAt,
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

  /// Maps the exact projection exposed by
  /// `public.inventory_category_items_summary_view`.
  factory InventoryItem.fromInventorySummaryRow(Map<String, dynamic> json) {
    final tableName = JsonMapReader.string(json, 'table_name');
    final itemId = JsonMapReader.string(json, 'item_id');
    final itemKey = JsonMapReader.nullableString(json, 'item_key');
    final internalCode = JsonMapReader.nullableString(json, 'internal_code');
    final codeNumber = JsonMapReader.nullableString(json, 'code_number');

    return InventoryItem(
      code: internalCode ?? codeNumber ?? itemKey ?? '$tableName:$itemId',
      name: JsonMapReader.string(json, 'item_name'),
      category: InventoryCategoryNames.displayNameFor(
        JsonMapReader.string(json, 'category_name'),
      ),
      // The unified view does not currently expose category_id.
      categoryId: null,
      project: JsonMapReader.nullableString(json, 'project_name') ?? '',
      quantity: JsonMapReader.number(json, 'stock_balance'),
      minimum: JsonMapReader.number(json, 'min_quantity'),
      tableName: tableName,
      itemId: itemId,
      itemKey: itemKey,
      supplier: JsonMapReader.nullableString(json, 'supplier_name'),
      expiry: JsonMapReader.nullableString(json, 'expire_date'),
      notes: JsonMapReader.nullableString(json, 'notes'),
      updatedAt: JsonMapReader.nullableDateTime(json, 'updated_at'),
    );
  }

  final String code;
  final String name;
  final String category;
  final String? tableName;
  final String? itemId;
  final String? itemKey;
  final String? categoryId;
  final String project;
  final num quantity;
  final num minimum;
  final String? supplier;
  final String? expiry;
  final String? notes;
  final DateTime? updatedAt;

  bool get hasBackendIdentity => tableName != null && itemId != null;

  /// Preview rows keep their existing code routes. Live rows use source table
  /// plus UUID so duplicate display codes cannot open the wrong item.
  String get routeId => hasBackendIdentity ? '$tableName::$itemId' : code;

  StockStatus get status {
    if (quantity <= 0) return StockStatus.outOfStock;
    if (quantity <= minimum) return StockStatus.low;
    return StockStatus.safe;
  }
}
