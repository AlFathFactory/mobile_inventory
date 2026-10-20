import 'dart:async';
import 'dart:io';

import 'package:el_fateh/core/data/local/hive_cache_database.dart';
import 'package:el_fateh/core/data/local/cache_metadata.dart';
import 'package:el_fateh/core/data/repositories/data_result.dart';
import 'package:el_fateh/core/data/repositories/page.dart';
import 'package:el_fateh/features/inventory/data/local/inventory_local_data_source.dart';
import 'package:el_fateh/features/inventory/data/local/inventory_cache_record.dart';
import 'package:el_fateh/features/inventory/cubit/inventory_cubit.dart';
import 'package:el_fateh/features/inventory/data/models/inventory_query.dart';
import 'package:el_fateh/features/inventory/data/repositories/cached_inventory_repository.dart';
import 'package:el_fateh/features/inventory/data/services/inventory_remote_data_source.dart';
import 'package:el_fateh/features/inventory/data/services/inventory_sync_coordinator.dart';
import 'package:el_fateh/features/inventory/model/inventory_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory directory;
  late HiveCacheDatabase database;
  late HiveInventoryLocalDataSource local;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('inventory_hive_test_');
    Hive.init(directory.path);
    database = await HiveCacheDatabase.open();
    local = HiveInventoryLocalDataSource(database);
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'serializes a complete generation and preserves stable identity',
    () async {
      final item = _item(1, category: 'Paints', quantity: 3.5);

      await local.replaceSnapshot([item], DateTime.utc(2026, 10, 20));
      final snapshot = await local.readSnapshot();

      expect(snapshot?.metadata.isComplete, isTrue);
      expect(snapshot?.metadata.generation, 1);
      expect(snapshot?.items.single.routeId, item.routeId);
      expect(snapshot?.itemByRouteId(item.routeId)?.quantity, 3.5);
      expect(snapshot?.itemsForCategories({'Paints'}), hasLength(1));
    },
  );

  test(
    'failed and interrupted sync retain the last complete snapshot',
    () async {
      await local.replaceSnapshot([_item(1)], DateTime.utc(2026, 10, 20));
      await local.markSyncStarted();
      await local.recoverInterruptedSync();
      await local.markSyncFailed(StateError('offline'));

      final snapshot = await local.readSnapshot();
      expect(snapshot?.items, hasLength(1));
      expect(snapshot?.metadata.syncInProgress, isFalse);
      expect(snapshot?.metadata.lastFailure, 'StateError');
    },
  );

  test('invalidated schema is withheld until a replacement succeeds', () async {
    await local.replaceSnapshot([_item(1)], DateTime.utc(2026, 10, 20));
    await local.invalidate();

    expect(await local.readSnapshot(), isNull);

    await local.replaceSnapshot([_item(2)], DateTime.utc(2026, 10, 21));
    expect(
      (await local.readSnapshot())?.items.single.routeId,
      _item(2).routeId,
    );
  });

  test('an older cache schema is explicitly invalidated', () async {
    await local.replaceSnapshot([_item(1)], DateTime.utc(2026, 10, 20));
    await database.metadata.put(
      inventoryDatasetName,
      const CacheMetadata(
        dataset: inventoryDatasetName,
        schemaVersion: 0,
        generation: 1,
        isComplete: true,
        syncInProgress: false,
      ),
    );
    final reopened = HiveInventoryLocalDataSource(database);

    expect(await reopened.readSnapshot(), isNull);
    expect(database.metadata.get(inventoryDatasetName)?.isComplete, isFalse);
    expect(
      database.metadata.get(inventoryDatasetName)?.schemaVersion,
      inventoryCacheSchemaVersion,
    );
  });

  test('a new snapshot never reuses interrupted staging generation', () async {
    await local.replaceSnapshot([_item(1)], DateTime.utc(2026, 10, 20));
    await database.inventorySnapshots.put(
      '2::staged',
      InventoryCacheRecord.fromItem(_item(99), 2),
    );

    await local.replaceSnapshot([_item(2)], DateTime.utc(2026, 10, 21));
    final snapshot = await local.readSnapshot();

    expect(snapshot?.metadata.generation, 3);
    expect(snapshot?.items.map((item) => item.routeId), [_item(2).routeId]);
  });

  test(
    'restart recovery removes interrupted staging and keeps the good data',
    () async {
      await local.replaceSnapshot([_item(1)], DateTime.utc(2026, 10, 20));
      await local.markSyncStarted();
      await database.inventorySnapshots.put(
        '2::staged',
        InventoryCacheRecord.fromItem(_item(99), 2),
      );

      final restarted = HiveInventoryLocalDataSource(database);
      await restarted.recoverInterruptedSync();
      expect(
        (await restarted.readSnapshot())?.items.single.routeId,
        _item(1).routeId,
      );
      expect(database.inventorySnapshots.containsKey('2::staged'), isFalse);
    },
  );

  test('sync downloads every bounded page and prevents overlap', () async {
    final remote = _PagedRemoteSource(
      List.generate(205, (index) => _row(index)),
    );
    final coordinator = InventorySyncCoordinator(
      local: local,
      remote: remote,
      pageSize: 100,
      clock: () => DateTime.utc(2026, 10, 20),
    );

    final first = coordinator.syncIfStale();
    final second = coordinator.syncIfStale();
    await Future.wait([first, second]);

    expect(remote.requests, hasLength(3));
    expect((await local.readSnapshot())?.items, hasLength(205));
  });

  test(
    'cold first page returns before the complete snapshot is downloaded',
    () async {
      final remote = _DeferredSnapshotRemote(
        List.generate(25, (index) => _row(index)),
      );
      final coordinator = InventorySyncCoordinator(
        local: local,
        remote: remote,
      );
      final repository = CachedInventoryRepository(
        local: local,
        syncCoordinator: coordinator,
      );

      final result = await repository.fetchItems(const InventoryQuery());
      final page = (result as DataSuccess<PageResult<InventoryItem>>).value;
      expect(page.items, hasLength(20));
      expect(page.nextCursor, '20');
      expect(await local.readSnapshot(), isNull);

      final completed = repository.cacheEvents.first;
      remote.releaseSnapshot();
      expect((await completed).failure, isNull);
      expect((await local.readSnapshot())?.items, hasLength(25));
      expect(remote.requests.map((request) => request.offset), [0, 20]);
    },
  );

  test('forced synchronization replaces a fresh snapshot', () async {
    final now = DateTime.utc(2026, 10, 20);
    await local.replaceSnapshot([_item(99)], now);
    final remote = _PagedRemoteSource([_row(1)]);
    final coordinator = InventorySyncCoordinator(
      local: local,
      remote: remote,
      clock: () => now,
    );
    expect((await coordinator.syncIfStale()).didSync, isFalse);
    expect(remote.requests, isEmpty);
    expect((await coordinator.syncIfStale(force: true)).isSuccess, isTrue);
    expect(remote.requests, hasLength(1));
    expect(
      (await local.readSnapshot())?.items.single.routeId,
      InventoryItem.fromInventorySummaryRow(_row(1)).routeId,
    );
  });

  test(
    'repository manual refresh forces a fresh cache and reports failure',
    () async {
      final now = DateTime.utc(2026, 10, 20);
      await local.replaceSnapshot([_item(99)], now);
      final remote = _ToggleRemote(_row(1));
      final repository = CachedInventoryRepository(
        local: local,
        syncCoordinator: InventorySyncCoordinator(
          local: local,
          remote: remote,
          clock: () => now,
        ),
      );

      await expectLater(
        repository.refreshCache(),
        throwsA(isA<SocketException>()),
      );
      expect(
        (await local.readSnapshot())?.items.single.routeId,
        _item(99).routeId,
      );
      remote.available = true;
      await repository.refreshCache();
      expect(
        (await local.readSnapshot())?.items.single.routeId,
        InventoryItem.fromInventorySummaryRow(_row(1)).routeId,
      );
    },
  );

  test('a failed later page cannot replace the committed snapshot', () async {
    await local.replaceSnapshot([_item(99)], DateTime.utc(2026, 10, 19));
    final remote = _FailingLaterPageRemote(
      List.generate(105, (index) => _row(index)),
    );
    final coordinator = InventorySyncCoordinator(local: local, remote: remote);

    final result = await coordinator.syncIfStale(force: true);
    expect(result.isSuccess, isFalse);
    expect(
      (await local.readSnapshot())?.items.single.routeId,
      _item(99).routeId,
    );
    expect((await local.readSnapshot())?.metadata.isComplete, isTrue);
  });

  test(
    'saved snapshots survive a new local data source and can be empty',
    () async {
      await local.replaceSnapshot([_item(1)], DateTime.utc(2026, 10, 20));
      final reopened = HiveInventoryLocalDataSource(database);
      expect(
        (await reopened.readSnapshot())?.items.single.routeId,
        _item(1).routeId,
      );

      await reopened.replaceSnapshot(const [], DateTime.utc(2026, 10, 21));
      final empty = await HiveInventoryLocalDataSource(database).readSnapshot();
      expect(empty, isNotNull);
      expect(empty!.items, isEmpty);
    },
  );

  test('first-page failure is retryable without restarting', () async {
    final remote = _ToggleRemote(_row(1));
    final repository = CachedInventoryRepository(
      local: local,
      syncCoordinator: InventorySyncCoordinator(local: local, remote: remote),
    );
    expect(
      await repository.fetchItems(const InventoryQuery()),
      isA<DataError>(),
    );
    remote.available = true;
    final result = await repository.fetchItems(const InventoryQuery());
    expect(
      (result as DataSuccess<PageResult<InventoryItem>>).value.items,
      hasLength(1),
    );
  });

  test(
    'cached page remains visible while a background refresh fails',
    () async {
      await local.replaceSnapshot([_item(99)], DateTime.utc(2026, 10, 19));
      final remote = _DeferredFailureRemote();
      final repository = CachedInventoryRepository(
        local: local,
        syncCoordinator: InventorySyncCoordinator(local: local, remote: remote),
      );
      final event = repository.cacheEvents.first;

      final page = await repository.fetchItems(const InventoryQuery());
      expect(
        (page as DataSuccess<PageResult<InventoryItem>>)
            .value
            .items
            .single
            .routeId,
        _item(99).routeId,
      );
      expect(await local.readSnapshot(), isNotNull);
      remote.fail();
      expect((await event).failure, isNotNull);
      expect(
        (await local.readSnapshot())?.items.single.routeId,
        _item(99).routeId,
      );
    },
  );

  test('successful background sync updates the visible first page', () async {
    await local.replaceSnapshot([_item(99)], DateTime.utc(2026, 10, 19));
    final repository = CachedInventoryRepository(
      local: local,
      syncCoordinator: InventorySyncCoordinator(
        local: local,
        remote: _PagedRemoteSource([_row(1)]),
        clock: () => DateTime.utc(2026, 10, 20),
      ),
    );
    final cubit = InventoryCubit(
      repository: repository,
      serverBacked: true,
      initiallyLoading: false,
    );
    addTearDown(cubit.close);
    final completed = repository.cacheEvents.first;
    await cubit.reload();
    await completed;
    await Future<void>.delayed(Duration.zero);
    expect(
      cubit.state.items.single.routeId,
      InventoryItem.fromInventorySummaryRow(_row(1)).routeId,
    );
  });

  test(
    'offline local pages apply Arabic search, filters, sorting and cursors',
    () async {
      final remote = _PagedRemoteSource(const []);
      final coordinator = InventorySyncCoordinator(
        local: local,
        remote: remote,
        clock: () => DateTime.utc(2026, 10, 20),
      );
      await local.replaceSnapshot([
        _item(
          1,
          name: 'عبوة دهان',
          category: 'Paints',
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
        _item(
          2,
          name: 'عبوة دهان',
          category: 'Paints',
          quantity: 0,
          updatedAt: DateTime.utc(2026, 2, 1),
        ),
        _item(
          3,
          name: 'Screws',
          category: 'Hardware',
          updatedAt: DateTime.utc(2026, 3, 1),
        ),
      ], DateTime.utc(2026, 10, 20));
      final repository = CachedInventoryRepository(
        local: local,
        syncCoordinator: coordinator,
      );

      final result = await repository.fetchItems(
        const InventoryQuery(
          page: PageRequest(limit: 1),
          search: 'عبوه دهان',
          categories: {'Paints'},
        ),
      );
      final page = (result as DataSuccess<PageResult<InventoryItem>>).value;

      expect(page.items.single.routeId, _item(2).routeId);
      expect(page.nextCursor, '1');
      final next = await repository.fetchItems(
        InventoryQuery(
          page: PageRequest(limit: 1, cursor: page.nextCursor),
          search: 'عبوه دهان',
          categories: const {'Paints'},
        ),
      );
      expect(
        (next as DataSuccess<PageResult<InventoryItem>>)
            .value
            .items
            .single
            .routeId,
        _item(1).routeId,
      );
    },
  );

  test(
    'empty cache reports a failed remote snapshot without fake preview data',
    () async {
      final coordinator = InventorySyncCoordinator(
        local: local,
        remote: _PagedRemoteSource(
          const [],
          error: const SocketException('offline'),
        ),
      );
      final repository = CachedInventoryRepository(
        local: local,
        syncCoordinator: coordinator,
      );

      expect(
        await repository.fetchItems(const InventoryQuery()),
        isA<DataError>(),
      );
      expect(await local.readSnapshot(), isNull);
    },
  );
}

class _PagedRemoteSource implements InventoryRemoteDataSource {
  _PagedRemoteSource(this.rows, {this.error});

  final List<Map<String, dynamic>> rows;
  final Object? error;
  final List<InventoryRemoteQuery> requests = [];

  @override
  Future<List<Map<String, dynamic>>> fetchItems(
    InventoryRemoteQuery query,
  ) async {
    requests.add(query);
    if (error case final value?) throw value;
    final start = query.offset;
    final end = (start + query.fetchLimit).clamp(0, rows.length).toInt();
    return rows.sublist(start, end);
  }

  @override
  Future<List<String>> fetchCategories() async => const [];
}

class _DeferredSnapshotRemote implements InventoryRemoteDataSource {
  _DeferredSnapshotRemote(this.rows);

  final List<Map<String, dynamic>> rows;
  final List<InventoryRemoteQuery> requests = [];
  final Completer<void> _release = Completer<void>();

  void releaseSnapshot() => _release.complete();

  @override
  Future<List<Map<String, dynamic>>> fetchItems(
    InventoryRemoteQuery query,
  ) async {
    requests.add(query);
    if (query.offset > 0) await _release.future;
    final end = (query.offset + query.fetchLimit).clamp(0, rows.length);
    return rows.sublist(query.offset, end);
  }

  @override
  Future<List<String>> fetchCategories() async => const [];
}

class _FailingLaterPageRemote implements InventoryRemoteDataSource {
  _FailingLaterPageRemote(this.rows);

  final List<Map<String, dynamic>> rows;

  @override
  Future<List<Map<String, dynamic>>> fetchItems(
    InventoryRemoteQuery query,
  ) async {
    if (query.offset > 0) throw const SocketException('lost connection');
    return rows.take(query.fetchLimit).toList();
  }

  @override
  Future<List<String>> fetchCategories() async => const [];
}

class _ToggleRemote implements InventoryRemoteDataSource {
  _ToggleRemote(this.row);

  final Map<String, dynamic> row;
  bool available = false;

  @override
  Future<List<Map<String, dynamic>>> fetchItems(
    InventoryRemoteQuery query,
  ) async {
    if (!available) throw const SocketException('offline');
    return query.offset == 0 ? [row] : const [];
  }

  @override
  Future<List<String>> fetchCategories() async => const [];
}

class _DeferredFailureRemote implements InventoryRemoteDataSource {
  final Completer<void> _release = Completer<void>();

  void fail() => _release.complete();

  @override
  Future<List<Map<String, dynamic>>> fetchItems(
    InventoryRemoteQuery query,
  ) async {
    await _release.future;
    throw const SocketException('offline');
  }

  @override
  Future<List<String>> fetchCategories() async => const [];
}

InventoryItem _item(
  int id, {
  String name = 'Item',
  String category = 'General',
  num quantity = 2,
  DateTime? updatedAt,
}) => InventoryItem(
  code: 'CODE-$id',
  name: name,
  category: category,
  project: 'Project',
  quantity: quantity,
  minimum: 1,
  tableName: 'inventory_items',
  itemId: '00000000-0000-0000-0000-${id.toString().padLeft(12, '0')}',
  updatedAt: updatedAt,
);

Map<String, dynamic> _row(int index) => {
  'table_name': 'inventory_items',
  'category_name': 'consumables',
  'item_id': '00000000-0000-0000-0000-${index.toString().padLeft(12, '0')}',
  'item_key': 'item-$index',
  'project_name': 'Project',
  'item_name': 'Item $index',
  'stock_balance': 3,
  'min_quantity': 1,
  'status': 'آمن',
  'supplier_name': null,
  'expire_date': null,
  'notes': null,
  'updated_at': '2026-10-20T10:00:00Z',
  'code_number': null,
  'internal_code': 'CODE-$index',
  'din': null,
};
