import '../../model/inventory_item.dart';

class InventoryCacheRecord {
  const InventoryCacheRecord({
    required this.generation,
    required this.routeId,
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

  factory InventoryCacheRecord.fromItem(InventoryItem item, int generation) =>
      InventoryCacheRecord(
        generation: generation,
        routeId: item.routeId,
        code: item.code,
        name: item.name,
        category: item.category,
        project: item.project,
        quantity: item.quantity.toDouble(),
        minimum: item.minimum.toDouble(),
        tableName: item.tableName,
        itemId: item.itemId,
        itemKey: item.itemKey,
        categoryId: item.categoryId,
        supplier: item.supplier,
        expiry: item.expiry,
        productionDate: item.productionDate,
        din: item.din,
        codeNumber: item.codeNumber,
        weight: item.weight,
        length: item.length,
        width: item.width,
        thickness: item.thickness,
        materialSource: item.materialSource,
        dimensionText: item.dimensionText,
        notes: item.notes,
        updatedAt: item.updatedAt,
      );

  final int generation;
  final String routeId;
  final String code;
  final String name;
  final String category;
  final String project;
  final double quantity;
  final double minimum;
  final String? tableName;
  final String? itemId;
  final String? itemKey;
  final String? categoryId;
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

  InventoryItem toItem() => InventoryItem(
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
    productionDate: productionDate,
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
}
