import '../local/inventory_local_data_source.dart';
import '../models/inventory_query.dart';
import 'inventory_remote_data_source.dart';
import '../../model/inventory_item.dart';
import '../../../../core/data/repositories/page.dart';

class InventorySyncResult {
  const InventorySyncResult._({this.error, required this.didSync});

  const InventorySyncResult.success({required bool didSync})
    : this._(didSync: didSync);

  const InventorySyncResult.failure(Object error)
    : this._(error: error, didSync: true);

  final Object? error;
  final bool didSync;

  bool get isSuccess => error == null;
}

/// Coordinates one complete inventory download at a time. Connectivity is not
/// consulted: a successful paginated request is the only proof of availability.
class InventorySyncCoordinator {
  InventorySyncCoordinator({
    required InventoryLocalDataSource local,
    required InventoryRemoteDataSource remote,
    DateTime Function()? clock,
    this.pageSize = 100,
    this.maxCacheAge = const Duration(minutes: 15),
  }) : _local = local,
       _remote = remote,
       _clock = clock ?? DateTime.now,
       assert(pageSize > 0 && pageSize <= 100);

  final InventoryLocalDataSource _local;
  final InventoryRemoteDataSource _remote;
  final DateTime Function() _clock;
  final int pageSize;
  final Duration maxCacheAge;
  Future<InventorySyncResult>? _inFlight;
  bool _recovered = false;
  _InventoryFirstPage? _firstPage;

  Future<PageResult<InventoryItem>> fetchPage(InventoryQuery query) async {
    final remoteQuery = InventoryRemoteQuery.fromInventoryQuery(query);
    final rows = await _remote
        .fetchItems(remoteQuery)
        .timeout(const Duration(seconds: 12));
    final hasMore = rows.length > remoteQuery.pageSize;
    final page = PageResult<InventoryItem>(
      items: rows
          .take(remoteQuery.pageSize)
          .map(InventoryItem.fromInventorySummaryRow)
          .toList(growable: false),
      nextCursor: hasMore
          ? '${remoteQuery.offset + remoteQuery.pageSize}'
          : null,
    );
    if (remoteQuery.offset == 0 &&
        query.search.isEmpty &&
        query.categories.isEmpty &&
        query.projects.isEmpty &&
        query.statuses.isEmpty) {
      _firstPage = _InventoryFirstPage(page.items, hasMore);
    }
    return page;
  }

  Future<InventorySyncResult> syncIfStale({bool force = false}) {
    final running = _inFlight;
    if (running != null) {
      if (!force) return running;
      return running.then(
        (result) => result.isSuccess && result.didSync
            ? result
            : syncIfStale(force: true),
      );
    }
    final job = _sync(force: force);
    _inFlight = job;
    return job.whenComplete(() {
      if (identical(_inFlight, job)) _inFlight = null;
    });
  }

  Future<InventorySyncResult> _sync({required bool force}) async {
    try {
      if (!_recovered) {
        await _local.recoverInterruptedSync();
        _recovered = true;
      }
      final snapshot = await _local.readSnapshot();
      if (!force && snapshot?.metadata.isFresh(maxCacheAge, _clock()) == true) {
        return const InventorySyncResult.success(didSync: false);
      }
      await _local.markSyncStarted();
      final items = <InventoryItem>[];
      var offset = 0;
      final firstPage = snapshot == null ? _firstPage : null;
      _firstPage = null;
      if (firstPage != null) {
        items.addAll(firstPage.items);
        offset = firstPage.items.length;
      }
      var hasMore = firstPage?.hasMore ?? true;
      while (hasMore) {
        final remoteQuery = InventoryRemoteQuery.fromInventoryQuery(
          InventoryQuery(
            page: PageRequest(limit: pageSize, cursor: '$offset'),
          ),
        );
        final rows = await _remote
            .fetchItems(remoteQuery)
            .timeout(const Duration(seconds: 12));
        final page = rows.take(pageSize);
        items.addAll(page.map(InventoryItem.fromInventorySummaryRow));
        hasMore = rows.length > pageSize;
        offset += page.length;
      }
      await _local.replaceSnapshot(items, _clock());
      return const InventorySyncResult.success(didSync: true);
    } on Object catch (error) {
      try {
        await _local.markSyncFailed(error);
      } on Object {
        // Preserve the request failure; the committed generation is intact.
      }
      return InventorySyncResult.failure(error);
    }
  }
}

class _InventoryFirstPage {
  const _InventoryFirstPage(this.items, this.hasMore);

  final List<InventoryItem> items;
  final bool hasMore;
}
