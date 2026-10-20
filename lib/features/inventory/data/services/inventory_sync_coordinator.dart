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

  Future<InventorySyncResult> syncIfStale({bool force = false}) {
    final running = _inFlight;
    if (running != null) return running;
    final job = _sync(force: force);
    _inFlight = job;
    return job.whenComplete(() {
      if (identical(_inFlight, job)) _inFlight = null;
    });
  }

  Future<InventorySyncResult> _sync({required bool force}) async {
    if (!_recovered) {
      await _local.recoverInterruptedSync();
      _recovered = true;
    }
    final snapshot = await _local.readSnapshot();
    if (!force && snapshot?.metadata.isFresh(maxCacheAge, _clock()) == true) {
      return const InventorySyncResult.success(didSync: false);
    }

    try {
      await _local.markSyncStarted();
      final items = <InventoryItem>[];
      var offset = 0;
      while (true) {
        final remoteQuery = InventoryRemoteQuery.fromInventoryQuery(
          InventoryQuery(
            page: PageRequest(limit: pageSize, cursor: '$offset'),
          ),
        );
        final rows = await _remote.fetchItems(remoteQuery);
        final page = rows.take(pageSize);
        items.addAll(page.map(InventoryItem.fromInventorySummaryRow));
        if (rows.length <= pageSize) break;
        offset += pageSize;
      }
      await _local.replaceSnapshot(items, _clock());
      return const InventorySyncResult.success(didSync: true);
    } on Object catch (error) {
      await _local.markSyncFailed(error);
      return InventorySyncResult.failure(error);
    }
  }
}
