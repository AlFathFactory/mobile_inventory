import 'package:hive_ce/hive.dart';

import 'inventory_cache_record.dart';

class InventoryCacheRecordAdapter extends TypeAdapter<InventoryCacheRecord> {
  @override
  final int typeId = 42;

  @override
  InventoryCacheRecord read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var index = 0; index < fieldCount; index++)
        reader.readByte(): reader.read(),
    };
    return InventoryCacheRecord(
      generation: fields[0] as int,
      routeId: fields[1] as String,
      code: fields[2] as String,
      name: fields[3] as String,
      category: fields[4] as String,
      project: fields[5] as String,
      quantity: fields[6] as double,
      minimum: fields[7] as double,
      tableName: fields[8] as String?,
      itemId: fields[9] as String?,
      itemKey: fields[10] as String?,
      categoryId: fields[11] as String?,
      supplier: fields[12] as String?,
      expiry: fields[13] as String?,
      productionDate: fields[14] as String?,
      din: fields[15] as String?,
      codeNumber: fields[16] as String?,
      weight: fields[17] as String?,
      length: fields[18] as String?,
      width: fields[19] as String?,
      thickness: fields[20] as String?,
      materialSource: fields[21] as String?,
      dimensionText: fields[22] as String?,
      notes: fields[23] as String?,
      updatedAt: fields[24] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, InventoryCacheRecord value) {
    writer
      ..writeByte(25)
      ..writeByte(0)
      ..write(value.generation)
      ..writeByte(1)
      ..write(value.routeId)
      ..writeByte(2)
      ..write(value.code)
      ..writeByte(3)
      ..write(value.name)
      ..writeByte(4)
      ..write(value.category)
      ..writeByte(5)
      ..write(value.project)
      ..writeByte(6)
      ..write(value.quantity)
      ..writeByte(7)
      ..write(value.minimum)
      ..writeByte(8)
      ..write(value.tableName)
      ..writeByte(9)
      ..write(value.itemId)
      ..writeByte(10)
      ..write(value.itemKey)
      ..writeByte(11)
      ..write(value.categoryId)
      ..writeByte(12)
      ..write(value.supplier)
      ..writeByte(13)
      ..write(value.expiry)
      ..writeByte(14)
      ..write(value.productionDate)
      ..writeByte(15)
      ..write(value.din)
      ..writeByte(16)
      ..write(value.codeNumber)
      ..writeByte(17)
      ..write(value.weight)
      ..writeByte(18)
      ..write(value.length)
      ..writeByte(19)
      ..write(value.width)
      ..writeByte(20)
      ..write(value.thickness)
      ..writeByte(21)
      ..write(value.materialSource)
      ..writeByte(22)
      ..write(value.dimensionText)
      ..writeByte(23)
      ..write(value.notes)
      ..writeByte(24)
      ..write(value.updatedAt);
  }
}
