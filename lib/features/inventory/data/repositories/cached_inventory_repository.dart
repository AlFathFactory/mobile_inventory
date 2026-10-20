import 'dart:async';

import '../../../../core/data/repositories/data_result.dart';
import '../../../../core/data/repositories/page.dart';
import '../../../../core/data/services/supabase_failure_mapper.dart';
import '../../../../core/utils/search_normalizer.dart';
import '../../model/inventory_item.dart';
import '../local/inventory_local_data_source.dart';
import '../models/inventory_query.dart';
import '../services/inventory_sync_coordinator.dart';
import 'inventory_repository.dart';

/// Read-through inventory repository for the production Supabase mode.
class CachedInventoryRepository
    implements InventoryRepository, InventoryCacheRefreshable {
  CachedInventoryRepository({
    required InventoryLocalDataSource local,
    required InventorySyncCoordinator syncCoordinator,
  }) : _local = local,
       _syncCoordinator = syncCoordinator;

  final InventoryLocalDataSource _local;
  final InventorySyncCoordinator _syncCoordinator;

  @override
  Future<DataResult<List<String>>> fetchCategories() async {
    final snapshot = await _local.readSnapshot();
    if (snapshot != null) {
      _startBackgroundSync();
      return DataSuccess(_categories(snapshot.items));
    }
    final result = await _syncCoordinator.syncIfStale();
    if (!result.isSuccess) {
      return DataError(SupabaseFailureMapper.from(result.error!));
    }
    final refreshed = await _local.readSnapshot();
    return DataSuccess(_categories(refreshed?.items ?? const []));
  }

  @override
  Future<DataResult<PageResult<InventoryItem>>> fetchItems(
    InventoryQuery query,
  ) async {
    var snapshot = await _local.readSnapshot();
    if (snapshot == null) {
      final result = await _syncCoordinator.syncIfStale();
      if (!result.isSuccess) {
        return DataError(SupabaseFailureMapper.from(result.error!));
      }
      snapshot = await _local.readSnapshot();
    } else {
      _startBackgroundSync();
    }
    return DataSuccess(_page(snapshot, query));
  }

  @override
  Future<void> refreshCache() async {
    await _syncCoordinator.syncIfStale(force: true);
  }

  void _startBackgroundSync() {
    // Deliberately not awaited: valid cached content remains available while
    // a stale snapshot refreshes.
    unawaited(_syncCoordinator.syncIfStale());
  }

  List<String> _categories(List<InventoryItem> items) =>
      (items.map((item) => item.category).toSet().toList()..sort());

  PageResult<InventoryItem> _page(
    InventoryCacheSnapshot? snapshot,
    InventoryQuery query,
  ) {
    final search = normalizeSearchTerm(query.search);
    final candidates =
        snapshot?.itemsForCategories(query.categories) ??
        const <InventoryItem>[];
    final filtered = candidates.where((item) {
      return matchesAnySearchValue([
            item.name,
            item.code,
            item.codeNumber,
            item.itemKey,
            item.supplier,
            item.project,
            item.category,
            item.din,
          ], search) &&
          (query.statuses.isEmpty || query.statuses.contains(item.status)) &&
          (query.projects.isEmpty || query.projects.contains(item.project));
    }).toList()..sort(_compareItems);
    return paginatePreview(filtered, query.page);
  }

  int _compareItems(InventoryItem left, InventoryItem right) {
    final updated = (right.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
        .compareTo(left.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0));
    if (updated != 0) return updated;
    final table = (left.tableName ?? '').compareTo(right.tableName ?? '');
    return table != 0 ? table : left.routeId.compareTo(right.routeId);
  }
}
