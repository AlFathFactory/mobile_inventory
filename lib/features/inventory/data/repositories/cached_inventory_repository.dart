import '../../../../core/data/repositories/data_result.dart';
import '../../../../core/data/repositories/page.dart';
import '../../../../core/data/services/supabase_failure_mapper.dart';
import '../../../../core/utils/search_normalizer.dart';
import '../../model/inventory_item.dart';
import '../local/inventory_local_data_source.dart';
import '../models/inventory_query.dart';
import '../services/inventory_sync_coordinator.dart';
import 'inventory_repository.dart';

/// Online pages are fetched from Supabase and saved as they are viewed.
/// Offline queries search only those saved items.
class CachedInventoryRepository
    implements InventoryRepository, InventoryCacheReadable {
  CachedInventoryRepository({
    required InventoryLocalDataSource local,
    required InventorySyncCoordinator syncCoordinator,
  }) : _local = local,
       _syncCoordinator = syncCoordinator;

  final InventoryLocalDataSource _local;
  final InventorySyncCoordinator _syncCoordinator;
  static const _cachedCursorPrefix = 'cached:';

  @override
  Future<DateTime?> lastSuccessfulSync() async =>
      (await _local.readSnapshot())?.metadata.lastSuccessfulSync;

  @override
  Future<DataResult<List<String>>> fetchCategories() async {
    final snapshot = await _local.readSnapshot();
    try {
      return DataSuccess(await _syncCoordinator.fetchCategories());
    } on Object catch (error) {
      if (snapshot != null) return DataSuccess(_categories(snapshot.items));
      return DataError(SupabaseFailureMapper.from(error));
    }
  }

  @override
  Future<DataResult<PageResult<InventoryItem>>> fetchItems(
    InventoryQuery query,
  ) async {
    if (query.page.cursor?.startsWith(_cachedCursorPrefix) == true) {
      final snapshot = await _local.readSnapshot();
      return snapshot == null
          ? const DataError(
              DataFailure(
                kind: DataFailureKind.offline,
                message: 'No saved inventory page is available.',
              ),
            )
          : DataSuccess(_page(snapshot, query));
    }
    try {
      final page = await _syncCoordinator.fetchPage(query);
      try {
        await _local.cacheViewedPage(
          page.items,
          DateTime.now(),
          replace:
              query.forceRefresh &&
              query.page.cursor == null &&
              query.search.isEmpty &&
              query.categories.isEmpty &&
              query.projects.isEmpty &&
              query.statuses.isEmpty,
        );
      } on Object {
        // A storage failure must not hide a successfully fetched live page.
      }
      return DataSuccess(page);
    } on Object catch (error) {
      final snapshot = await _local.readSnapshot();
      if (snapshot != null) return DataSuccess(_page(snapshot, query));
      return DataError(SupabaseFailureMapper.from(error));
    }
  }

  Future<void> refreshCache() async {
    final page = await _syncCoordinator.fetchPage(
      const InventoryQuery(forceRefresh: true),
    );
    await _local.cacheViewedPage(page.items, DateTime.now(), replace: true);
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
    final cursor = query.page.cursor;
    final localPage = paginatePreview(
      filtered,
      PageRequest(
        limit: query.page.limit,
        cursor: cursor?.startsWith(_cachedCursorPrefix) == true
            ? cursor!.substring(_cachedCursorPrefix.length)
            : cursor,
      ),
    );
    return PageResult(
      items: localPage.items,
      nextCursor: localPage.nextCursor == null
          ? null
          : '$_cachedCursorPrefix${localPage.nextCursor}',
      fromCache: true,
    );
  }

  int _compareItems(InventoryItem left, InventoryItem right) {
    final updated = (right.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
        .compareTo(left.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0));
    if (updated != 0) return updated;
    final table = (left.tableName ?? '').compareTo(right.tableName ?? '');
    return table != 0 ? table : left.routeId.compareTo(right.routeId);
  }
}
