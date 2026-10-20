import 'package:hive_ce/hive.dart';

import 'cache_metadata.dart';

class CacheMetadataAdapter extends TypeAdapter<CacheMetadata> {
  @override
  final int typeId = 41;

  @override
  CacheMetadata read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (var index = 0; index < reader.readByte(); index++)
        reader.readByte(): reader.read(),
    };
    return CacheMetadata(
      dataset: fields[0] as String,
      schemaVersion: fields[1] as int,
      generation: fields[2] as int,
      isComplete: fields[3] as bool,
      syncInProgress: fields[4] as bool,
      lastSuccessfulSync: fields[5] as DateTime?,
      lastFailure: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CacheMetadata value) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(value.dataset)
      ..writeByte(1)
      ..write(value.schemaVersion)
      ..writeByte(2)
      ..write(value.generation)
      ..writeByte(3)
      ..write(value.isComplete)
      ..writeByte(4)
      ..write(value.syncInProgress)
      ..writeByte(5)
      ..write(value.lastSuccessfulSync)
      ..writeByte(6)
      ..write(value.lastFailure);
  }
}
