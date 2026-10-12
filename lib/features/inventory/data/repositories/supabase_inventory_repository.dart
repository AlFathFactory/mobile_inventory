import '../../../../core/data/repositories/data_result.dart';
import '../../../../core/data/repositories/page.dart';
import '../../../../core/data/services/supabase_failure_mapper.dart';
import '../../model/inventory_item.dart';
import '../models/inventory_query.dart';
import '../services/inventory_remote_data_source.dart';
import 'inventory_repository.dart';

class SupabaseInventoryRepository implements InventoryRepository {
  const SupabaseInventoryRepository(this._dataSource);

  final InventoryRemoteDataSource _dataSource;

  @override
  Future<DataResult<PageResult<InventoryItem>>> fetchItems(
    InventoryQuery query,
  ) async {
    try {
      final remoteQuery = InventoryRemoteQuery.fromInventoryQuery(query);
      final rows = await _dataSource.fetchItems(remoteQuery);
      final hasMore = rows.length > remoteQuery.pageSize;
      final pageRows = hasMore ? rows.take(remoteQuery.pageSize) : rows;
      final items = pageRows
          .map(InventoryItem.fromInventorySummaryRow)
          .toList(growable: false);

      return DataSuccess(
        PageResult(
          items: items,
          nextCursor: hasMore
              ? '${remoteQuery.offset + remoteQuery.pageSize}'
              : null,
        ),
      );
    } on Object catch (error) {
      return DataError(SupabaseFailureMapper.from(error));
    }
  }
}
