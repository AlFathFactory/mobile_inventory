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
    this.productionDate,
    this.din,
    this.codeNumber,
    this.weight,
    this.length,
    this.width,
    this.thickness,
    this.materialSource,
    this.dimensionText,
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
      productionDate: JsonMapReader.nullableString(json, 'production_date'),
      din: JsonMapReader.nullableString(json, 'din'),
      codeNumber: JsonMapReader.nullableString(json, 'code_number'),
      weight: JsonMapReader.nullableString(json, 'weight'),
      length: JsonMapReader.nullableString(json, 'length'),
      width: JsonMapReader.nullableString(json, 'width'),
      thickness: JsonMapReader.nullableString(json, 'th'),
      materialSource: JsonMapReader.nullableString(json, 'material_source'),
      dimensionText: JsonMapReader.nullableString(json, 'dimension_text'),
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
      din: JsonMapReader.nullableString(json, 'din'),
      codeNumber: codeNumber,
      weight: JsonMapReader.nullableString(json, 'weight'),
      length: JsonMapReader.nullableString(json, 'length'),
      width: JsonMapReader.nullableString(json, 'width'),
      thickness: JsonMapReader.nullableString(json, 'th'),
      materialSource: JsonMapReader.nullableString(json, 'material_source'),
      dimensionText: JsonMapReader.nullableString(json, 'dimension_text'),
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
  final String? productionDate;
  final String? din;
  final String? codeNumber;
  final String? weight;
  final String? length;
  final String? width;
  final String? thickness;
  final String? materialSource;
  final String? dimensionText;
  final String? notes;
  final DateTime? updatedAt;

  bool get hasBackendIdentity => tableName != null && itemId != null;

  /// Preview rows keep their existing code routes. Live rows use source table
  /// plus UUID so duplicate display codes cannot open the wrong item.
  String get routeId => hasBackendIdentity ? '$tableName::$itemId' : code;

  InventoryItem withProductionDate(String? value) => InventoryItem(
    code: code,
    name: name,
    category: category,
    project: project,
    quantity: quantity,
    minimum: minimum,
    tableName: tableName,
    itemId: itemId,
    itemKey: itemKey,
    categoryId: categoryId,
    supplier: supplier,
    expiry: expiry,
    productionDate: value,
    din: din,
    codeNumber: codeNumber,
    weight: weight,
    length: length,
    width: width,
    thickness: thickness,
    materialSource: materialSource,
    dimensionText: dimensionText,
    notes: notes,
    updatedAt: updatedAt,
  );

  List<InventoryItemAttribute> get categorySpecificAttributes =>
      switch (tableName) {
        'paints' => _attributes([
          ('تاريخ الإنتاج', productionDate),
          ('تاريخ الصلاحية', expiry),
        ]),
        'screws' || 'stock_screws' => _attributes([
          ('DIN', din),
          ('رقم الكود', codeNumber),
        ]),
        'raw_materials' => _attributes([
          ('الوزن', weight),
          ('الطول', length),
          ('العرض', width),
          ('السمك', thickness),
          ('مصدر الخامة', materialSource),
          ('رقم الكود', codeNumber),
          ('الأبعاد', dimensionText),
          ('DIN', din),
        ]),
        _ => const [],
      };

  static List<InventoryItemAttribute> _attributes(
    List<(String, String?)> values,
  ) => [
    for (final (label, value) in values)
      if (value?.trim().isNotEmpty ?? false)
        InventoryItemAttribute(label, value!),
  ];

  StockStatus get status {
    if (quantity <= 0) return StockStatus.outOfStock;
    if (quantity <= minimum) return StockStatus.low;
    return StockStatus.safe;
  }
}

@immutable
class InventoryItemAttribute {
  const InventoryItemAttribute(this.label, this.value);

  final String label;
  final String value;
}
