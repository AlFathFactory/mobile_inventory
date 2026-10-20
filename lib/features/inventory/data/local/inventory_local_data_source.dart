import '../../../../core/data/local/cache_metadata.dart';
import '../../../../core/data/local/hive_cache_database.dart';
import '../../model/inventory_item.dart';
import 'inventory_cache_record.dart';

const inventoryDatasetName = 'inventory';
const inventoryCacheSchemaVersion = 1;

class InventoryCacheSnapshot {
  InventoryCacheSnapshot({
    required this.metadata,
    required List<InventoryItem> items,
  }) : items = List.unmodifiable(items),
       _byRouteId = {for (final item in items) item.routeId: item},
       _byCategory = _indexByCategory(items);

  final CacheMetadata metadata;
  final List<InventoryItem> items;
  final Map<String, InventoryItem> _byRouteId;
  final Map<String, List<InventoryItem>> _byCategory;

  InventoryItem? itemByRouteId(String routeId) => _byRouteId[routeId];

  List<InventoryItem> itemsForCategories(Set<String> categories) {
    if (categories.isEmpty) return items;
    return [for (final category in categories) ...?_byCategory[category]];
  }

  static Map<String, List<InventoryItem>> _indexByCategory(
    List<InventoryItem> items,
  ) {
    final result = <String, List<InventoryItem>>{};
    for (final item in items) {
      (result[item.category] ??= []).add(item);
    }
    return Map<String, List<InventoryItem>>.unmodifiable({
      for (final entry in result.entries)
        entry.key: List<InventoryItem>.unmodifiable(entry.value),
    });
  }
}

abstract interface class InventoryLocalDataSource {
  Future<InventoryCacheSnapshot?> readSnapshot();
  Future<void> markSyncStarted();
  Future<void> replaceSnapshot(
    List<InventoryItem> items,
    DateTime synchronizedAt,
  );
  Future<void> markSyncFailed(Object error);
  Future<void> recoverInterruptedSync();
  Future<void> invalidate();
}

/// Versioned Hive snapshots. A new generation becomes visible only once every
/// record has been written and its metadata is committed.
class HiveInventoryLocalDataSource implements InventoryLocalDataSource {
  HiveInventoryLocalDataSource(this._database);

  final HiveCacheDatabase _database;
  InventoryCacheSnapshot? _inMemorySnapshot;

  @override
  Future<InventoryCacheSnapshot?> readSnapshot() async {
    final cached = _inMemorySnapshot;
    if (cached != null) return cached;
    final metadata = _metadata;
    if (metadata == null ||
        !metadata.isComplete ||
        metadata.schemaVersion != inventoryCacheSchemaVersion) {
      if (metadata != null &&
          metadata.schemaVersion != inventoryCacheSchemaVersion) {
        await invalidate();
      }
      return null;
    }

    final records = _database.inventorySnapshots.values
        .where((record) => record.generation == metadata.generation)
        .toList(growable: false);
    final snapshot = InventoryCacheSnapshot(
      metadata: metadata,
      items: records.map((record) => record.toItem()).toList(growable: false),
    );
    _inMemorySnapshot = snapshot;
    return snapshot;
  }

  @override
  Future<void> markSyncStarted() async {
    final metadata = _metadata ?? _emptyMetadata();
    final updated = metadata.copyWith(
      syncInProgress: true,
      clearLastFailure: true,
    );
    await _writeMetadata(updated);
    _updateInMemoryMetadata(updated);
  }

  @override
  Future<void> replaceSnapshot(
    List<InventoryItem> items,
    DateTime synchronizedAt,
  ) async {
    final previous = _metadata ?? _emptyMetadata();
    // A failed or interrupted attempt may have left staged records behind.
    // Never reuse its generation, otherwise those rows could become visible
    // in a later, smaller successful snapshot.
    var latestStoredGeneration = previous.generation;
    for (final record in _database.inventorySnapshots.values) {
      if (record.generation > latestStoredGeneration) {
        latestStoredGeneration = record.generation;
      }
    }
    final nextGeneration = latestStoredGeneration + 1;
    final records = <String, InventoryCacheRecord>{};
    for (final item in items) {
      final key = _recordKey(nextGeneration, item.routeId);
      if (records.containsKey(key)) {
        throw FormatException('Duplicate inventory identity: ${item.routeId}');
      }
      records[key] = InventoryCacheRecord.fromItem(item, nextGeneration);
    }

    // Staged records cannot be reached until the complete metadata commit.
    await _database.inventorySnapshots.putAll(records);
    final completed = CacheMetadata(
      dataset: inventoryDatasetName,
      schemaVersion: inventoryCacheSchemaVersion,
      generation: nextGeneration,
      isComplete: true,
      syncInProgress: false,
      lastSuccessfulSync: synchronizedAt.toUtc(),
    );
    await _writeMetadata(completed);
    _inMemorySnapshot = InventoryCacheSnapshot(
      metadata: completed,
      items: items,
    );

    // Cleanup happens after the commit. Its failure cannot lose the new or
    // previous committed snapshot and stale records remain unreachable.
    final oldKeys = _database.inventorySnapshots.keys
        .whereType<String>()
        .where((key) => !key.startsWith('$nextGeneration::'))
        .toList(growable: false);
    if (oldKeys.isNotEmpty) {
      try {
        await _database.inventorySnapshots.deleteAll(oldKeys);
      } on Object {
        // The next successful replacement will retry this non-critical cleanup.
      }
    }
  }

  @override
  Future<void> markSyncFailed(Object error) async {
    final metadata = _metadata ?? _emptyMetadata();
    final updated = metadata.copyWith(
      syncInProgress: false,
      lastFailure: error.runtimeType.toString(),
    );
    await _writeMetadata(updated);
    _updateInMemoryMetadata(updated);
  }

  @override
  Future<void> recoverInterruptedSync() async {
    final metadata = _metadata;
    if (metadata?.syncInProgress == true) {
      final updated = metadata!.copyWith(
        syncInProgress: false,
        lastFailure: 'interrupted',
      );
      await _writeMetadata(updated);
      _updateInMemoryMetadata(updated);
    }
    // Interrupted writes may leave unreachable rows. Keep only the committed
    // generation; cleanup failure cannot invalidate it.
    final committed = metadata?.isComplete == true
        ? metadata!.generation
        : null;
    final staleKeys = _database.inventorySnapshots.keys
        .whereType<String>()
        .where((key) => committed == null || !key.startsWith('$committed::'))
        .toList(growable: false);
    if (staleKeys.isNotEmpty) {
      try {
        await _database.inventorySnapshots.deleteAll(staleKeys);
      } on Object {
        // A later startup or successful replacement can retry cleanup.
      }
    }
  }

  @override
  Future<void> invalidate() async {
    final metadata = _metadata ?? _emptyMetadata();
    _inMemorySnapshot = null;
    await _writeMetadata(
      metadata.copyWith(
        schemaVersion: inventoryCacheSchemaVersion,
        isComplete: false,
        syncInProgress: false,
        lastFailure: 'invalidated',
      ),
    );
  }

  CacheMetadata? get _metadata => _database.metadata.get(inventoryDatasetName);

  CacheMetadata _emptyMetadata() => const CacheMetadata(
    dataset: inventoryDatasetName,
    schemaVersion: inventoryCacheSchemaVersion,
    generation: 0,
    isComplete: false,
    syncInProgress: false,
  );

  Future<void> _writeMetadata(CacheMetadata value) =>
      _database.metadata.put(inventoryDatasetName, value);

  void _updateInMemoryMetadata(CacheMetadata metadata) {
    final snapshot = _inMemorySnapshot;
    if (snapshot == null) return;
    _inMemorySnapshot = InventoryCacheSnapshot(
      metadata: metadata,
      items: snapshot.items,
    );
  }

  String _recordKey(int generation, String routeId) => '$generation::$routeId';
}
