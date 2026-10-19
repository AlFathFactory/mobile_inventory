import 'package:flutter/foundation.dart';

import 'inventory_remote_data_source.dart';

@immutable
class ItemDetailsRemoteQuery {
  const ItemDetailsRemoteQuery({required this.tableName, required this.itemId});

  static const viewName = InventoryRemoteQuery.viewName;

  /// Exact fields consumed by [InventoryItem.fromInventorySummaryRow].
  static const selectedColumns = <String>[
    'table_name',
    'category_name',
    'item_id',
    'item_key',
    'project_name',
    'item_name',
    'stock_balance',
    'min_quantity',
    'supplier_name',
    'expire_date',
    'weight',
    'length',
    'width',
    'th',
    'material_source',
    'din',
    'notes',
    'updated_at',
    'code_number',
    'internal_code',
  ];

  final String tableName;
  final String itemId;
}

abstract interface class ItemDetailsRemoteDataSource {
  Future<Map<String, dynamic>?> fetchItem(ItemDetailsRemoteQuery query);

  /// The unified view intentionally does not expose this paint-only field.
  /// Keeping it here confines the supplemental bounded read to the data layer.
  Future<String?> fetchPaintProductionDate(String itemId);
}
