import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../features/inventory/data/local/inventory_cache_record.dart';
import '../../../features/inventory/data/local/inventory_cache_record_adapter.dart';
import 'cache_metadata.dart';
import 'cache_metadata_adapter.dart';

/// Owns the Hive CE setup shared by local read-only cache data sources.
class HiveCacheDatabase {
  HiveCacheDatabase._(this.metadata, this.inventorySnapshots);

  static const metadataBoxName = 'cache_metadata_v1';
  static const inventorySnapshotsBoxName = 'inventory_snapshots_v1';

  final Box<CacheMetadata> metadata;
  final Box<InventoryCacheRecord> inventorySnapshots;

  static Future<HiveCacheDatabase> initializeFlutter() async {
    await Hive.initFlutter();
    return open();
  }

  static Future<HiveCacheDatabase> open() async {
    _registerAdapters();
    final metadata = Hive.isBoxOpen(metadataBoxName)
        ? Hive.box<CacheMetadata>(metadataBoxName)
        : await Hive.openBox<CacheMetadata>(metadataBoxName);
    final inventorySnapshots = Hive.isBoxOpen(inventorySnapshotsBoxName)
        ? Hive.box<InventoryCacheRecord>(inventorySnapshotsBoxName)
        : await Hive.openBox<InventoryCacheRecord>(inventorySnapshotsBoxName);
    return HiveCacheDatabase._(metadata, inventorySnapshots);
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(41)) {
      Hive.registerAdapter(CacheMetadataAdapter());
    }
    if (!Hive.isAdapterRegistered(42)) {
      Hive.registerAdapter(InventoryCacheRecordAdapter());
    }
  }
}
